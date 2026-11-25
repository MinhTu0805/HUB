-- ═══ Board.lua ═══ Grid indexing, tile metadata, solve queue and render
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local CFG, COLOR, ClearAll, Draw, GameRunning, Overlays = SV.CFG, SV.COLOR, SV.ClearAll, SV.Draw, SV.GameRunning, SV.Overlays
local ProbColor, S, Stats, Undraw = SV.ProbColor, SV.S, SV.Stats, SV.Undraw

-- ─── GRID INFRASTRUCTURE ────────────────────────────────
-- Compact grid key that avoids string alloc
local function GridKey(gx, gz) return (gx + 1000000) * 2000003 + (gz + 1000000) end

SV.GridStep   = nil    -- inferred tile spacing when TileStep unknown
SV.Grid       = {}     -- GridKey → tile
SV.Adjacency  = {}     -- tile → {neighbor, ...}
SV.TileIndex  = {}     -- tile → integer id (1-based)
SV.TileCount  = 0
SV.BoundsDirty= true
SV.BoardBounds= nil
SV.LastSig    = nil

local OFFSETS = { {-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1} }

local function TileGridPos(t)
    local step = SV.TileStep or (SV.GridStep and SV.GridStep.X)
    if not step then return nil, nil end
    return math.round(t.Position.X / step),
           math.round(t.Position.Z / (SV.TileStep or SV.GridStep.Z))
end

local function IsEdge(gx, gz)
    return SV.GridW and SV.GridH
       and (gx <= 1 or gx >= SV.GridW or gz <= 1 or gz >= SV.GridH)
end

local function IsCorner(gx, gz)
    return SV.GridW and SV.GridH
       and (gx <= 1 or gx >= SV.GridW) and (gz <= 1 or gz >= SV.GridH)
end

local function RefreshBounds()
    SV.BoundsDirty = false
    if SV.GridW and SV.GridH then
        SV.BoardBounds = { MinX=1, MinZ=1, W=SV.GridW, H=SV.GridH }
        return
    end
    local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
    for t in next, SV.Adjacency do
        local gx, gz = TileGridPos(t)
        if gx then
            if gx < minX then minX = gx end
            if gx > maxX then maxX = gx end
            if gz < minZ then minZ = gz end
            if gz > maxZ then maxZ = gz end
        end
    end
    SV.BoardBounds = (minX < math.huge)
        and { MinX=minX, MinZ=minZ, W=maxX-minX+1, H=maxZ-minZ+1 }
        or  nil
end

-- ─── TILE METADATA ──────────────────────────────────────
SV.FlagModelNames = {}

local function RebuildFlagNames()
    local t = {}
    for _, sub in ipairs(SV.FlagsRoot:GetChildren()) do
        if sub:IsA("Folder") then
            for _, m in ipairs(sub:GetChildren()) do t[m.Name] = true end
        end
    end
    SV.FlagModelNames = t
end
RebuildFlagNames()

local function HasFlag(tile)
    for _, c in ipairs(tile:GetChildren()) do
        if c:IsA("Model") and SV.FlagModelNames[c.Name] then return true end
    end
    return false
end

local function GetNumber(tile)
    local g = tile:FindFirstChild("NumberGui")
    local l = g and g:FindFirstChild("TextLabel")
    return (l and tonumber(l.Text)) or 0
end

-- ─── CONNECTION BOOKKEEPING ─────────────────────────────
SV.ConnColor = {}   -- tile → RBXScriptConnection
SV.ConnDesc  = {}   -- tile → RBXScriptConnection
SV.ConnText  = {}   -- descendant → RBXScriptConnection
SV.ConnFlag  = {}   -- tile → {conn, conn}
SV.ConnTop   = {}   -- top-level connections

-- ─── SOLVE QUEUE + RENDER ───────────────────────────────
-- shared via SV: Solve
SV.PrevBest = nil       -- last best guess: kept while it is still (nearly) the best, so it never flips between equal tiles
SV.LastRender = nil     -- cached solver output so settings can re-render instantly
SV.Solving = false
local Pending = false

local function RiskLabel(pv, est)
    if S.ShowPercent and pv and pv <= 1 then
        return string.format(est and "~%d%%" or "%d%%", math.floor(pv * 100 + 0.5))
    end
    return "?"
end

local function Render(R)
    if not R then return end
    if not S.Enabled or not GameRunning.Value then ClearAll(); return end

    local drawn = {}
    local nSafe, nMine, nGuess = 0, 0, 0
    local state, beige, prob, best = R.state, R.beige, R.prob, R.best
    local pure = R.pure or {}   -- only PROVEN tiles may be drawn as definite Safe / Mine

    for _, t in ipairs(R.green) do
        local adj = SV.Adjacency[t]
        if adj then
            local s = state[t]
            local onBoundary = false
            for _, nb in ipairs(adj) do
                if beige[nb] then onBoundary = true; break end
            end

            if s == 2 and onBoundary and pure[t] == 2 then
                nMine += 1
                if S.ShowMines then
                    Draw(t, "mine", COLOR.Mine, "X", HasFlag(t) and not S.ShowFlagged)
                    drawn[t] = true
                end
            elseif s == 1 and onBoundary and pure[t] == 1 then
                nSafe += 1
                if S.ShowSafe then
                    Draw(t, "safe", COLOR.Safe, "", false)
                    drawn[t] = true
                end
            elseif s and (s == 0 or pure[t] ~= s) and (onBoundary or t == best)
               and not (s == 2 and HasFlag(t) and not S.ShowFlagged) then
                -- undecided OR only predicted (sampling / mine counter / trusted flags):
                -- shown with its probability so it is never mistaken for a sure tile
                if onBoundary then nGuess += 1 end
                local pv = prob[t]
                if not pv and s == 1 then pv = 0 elseif not pv and s == 2 then pv = 1 end
                if not pv and t == best and R.bestProb and R.bestProb <= 1 then pv = R.bestProb end
                if t == best and S.ShowBest then
                    Draw(t, "best", COLOR.Best, RiskLabel(pv, R.est and R.est[t]), false)
                    drawn[t] = true
                elseif S.ShowGuess and onBoundary then
                    Draw(t, "guess", pv and ProbColor(pv) or COLOR.Unknown, RiskLabel(pv, R.est and R.est[t]), false)
                    drawn[t] = true
                end
            end
        end
    end

    for t in next, Overlays do
        if not drawn[t] then Undraw(t) end
    end

    Stats.safe, Stats.mine, Stats.guess = nSafe, nMine, nGuess
    Stats.bestProb = (best and R.bestProb and R.bestProb <= 1) and R.bestProb or nil
end

-- Re-apply style to every overlay (used when a display setting changes)
local function Refresh()
    SV.DrawKey, SV.DrawText = {}, {}
    if SV.LastRender then pcall(Render, SV.LastRender) end
end

local function QueueSolve()
    if not GameRunning.Value then SV.LastSig = nil; ClearAll(); return end
    if not S.Enabled then return end
    if SV.Solving then Pending = true; return end
    SV.Solving = true
    task.delay(CFG.Debounce, function()
        SV.Solving = false
        local t0, prevSig = os.clock(), SV.LastSig
        local ok, err = pcall(SV.Solve)
        if not ok then warn("[UltraSolver] " .. tostring(err)) end
        if SV.LastSig ~= prevSig then
            Stats.solveMs = (os.clock() - t0) * 1000
            Stats.solves += 1
        end
        if Pending then Pending = false; QueueSolve() end
    end)
end

-- ─── exports ───
SV.GetNumber = GetNumber
SV.GridKey = GridKey
SV.HasFlag = HasFlag
SV.IsCorner = IsCorner
SV.IsEdge = IsEdge
SV.OFFSETS = OFFSETS
SV.QueueSolve = QueueSolve
SV.RebuildFlagNames = RebuildFlagNames
SV.Refresh = Refresh
SV.RefreshBounds = RefreshBounds
SV.Render = Render
SV.TileGridPos = TileGridPos
