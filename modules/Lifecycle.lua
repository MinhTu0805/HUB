-- ═══ Lifecycle.lua ═══ Tile registration, round setup/teardown, global API (_G.UltraSolver*)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local BEIGE_KEYS, ClearAll, FlagFolder, GREEN_KEYS, GameRunning, GridKey = SV.BEIGE_KEYS, SV.ClearAll, SV.FlagFolder, SV.GREEN_KEYS, SV.GameRunning, SV.GridKey
local Gui, Info, Loading, MinesVal, OFFSETS, Parts = SV.Gui, SV.Info, SV.Loading, SV.MinesVal, SV.OFFSETS, SV.Parts
local QueueSolve, RGBKey, ReadSettings, RebuildFlagNames, TH, Toast = SV.QueueSolve, SV.RGBKey, SV.ReadSettings, SV.RebuildFlagNames, SV.TH, SV.Toast
local Undraw, VERSION, VizFolder = SV.Undraw, SV.VERSION, SV.VizFolder

-- ─── TILE REGISTRATION ──────────────────────────────────
local function HookDescendant(d)
    if d:IsA("TextLabel") and not SV.ConnText[d] then
        SV.ConnText[d] = d:GetPropertyChangedSignal("Text"):Connect(QueueSolve)
    end
end

local OnFlagAdded   -- set by the automation module
local OnFlagRemoved -- set by the automation module
local function OnFlagEvent(child)
    if child:IsA("Model") then
        if not SV.FlagModelNames[child.Name] then RebuildFlagNames() end
        if SV.FlagModelNames[child.Name] then
            local tile = child.Parent
            if OnFlagAdded and tile then pcall(OnFlagAdded, tile) end
            QueueSolve()
        end
    end
end

local function RegisterTile(tile, skipQueue)
    if not tile:IsA("BasePart") or SV.Adjacency[tile] then return end
    SV.Adjacency[tile] = {}
    SV.TileCount += 1
    SV.TileIndex[tile] = SV.TileCount

    local gx, gz
    if SV.TileStep then
        gx = math.round(tile.Position.X / SV.TileStep)
        gz = math.round(tile.Position.Z / SV.TileStep)
    else
        if not SV.GridStep then SV.GridStep = { X = tile.Size.X, Z = tile.Size.Z } end
        gx = math.round(tile.Position.X / SV.GridStep.X)
        gz = math.round(tile.Position.Z / SV.GridStep.Z)
    end

    for _, off in ipairs(OFFSETS) do
        local neighbor = SV.Grid[GridKey(gx + off[1], gz + off[2])]
        if neighbor then
            local an = SV.Adjacency[neighbor]
            SV.Adjacency[tile][#SV.Adjacency[tile]+1] = neighbor
            an[#an+1] = tile
        end
    end
    SV.Grid[GridKey(gx, gz)] = tile
    SV.BoundsDirty = true

    SV.ConnColor[tile] = tile:GetPropertyChangedSignal("Color"):Connect(QueueSolve)
    for _, d in ipairs(tile:GetDescendants()) do HookDescendant(d) end
    SV.ConnDesc[tile] = tile.DescendantAdded:Connect(HookDescendant)
    SV.ConnFlag[tile] = {
        tile.ChildAdded:Connect(OnFlagEvent),
        tile.ChildRemoved:Connect(function(child)
            OnFlagEvent(child)
            if OnFlagRemoved and child:IsA("Model") and SV.FlagModelNames[child.Name] then
                pcall(OnFlagRemoved, tile)
            end
        end),
    }
    if not skipQueue then QueueSolve() end
end

local function SwapRemove(tbl, target)
    for i, v in ipairs(tbl) do
        if v == target then
            tbl[i] = tbl[#tbl]
            tbl[#tbl] = nil
            return
        end
    end
end

local function UnregisterTile(tile)
    Undraw(tile)
    if SV.ConnColor[tile] then SV.ConnColor[tile]:Disconnect(); SV.ConnColor[tile] = nil end
    if SV.ConnDesc[tile]  then SV.ConnDesc[tile]:Disconnect();  SV.ConnDesc[tile]  = nil end
    if SV.ConnFlag[tile]  then
        for _, c in ipairs(SV.ConnFlag[tile]) do c:Disconnect() end
        SV.ConnFlag[tile] = nil
    end
    for _, d in ipairs(tile:GetDescendants()) do
        if SV.ConnText[d] then SV.ConnText[d]:Disconnect(); SV.ConnText[d] = nil end
    end

    local step = SV.TileStep or (SV.GridStep and SV.GridStep.X)
    if step then
        local gx = math.round(tile.Position.X / step)
        local gz = math.round(tile.Position.Z / (SV.TileStep or SV.GridStep.Z))
        local k  = GridKey(gx, gz)
        if SV.Grid[k] == tile then SV.Grid[k] = nil end
    end

    if SV.Adjacency[tile] then
        for _, nb in ipairs(SV.Adjacency[tile]) do
            if SV.Adjacency[nb] then SwapRemove(SV.Adjacency[nb], tile) end
        end
        SV.Adjacency[tile] = nil
    end
    SV.TileIndex[tile] = nil
    SV.TileCount -= 1
    SV.BoundsDirty = true
end

-- ─── SETUP / TEARDOWN ────────────────────────────────────
SV.FlagTried = {}   -- tile → { n = attempts, t = last time }
local function DisconnectAll()
    for _, c in next, SV.ConnColor do c:Disconnect() end
    for _, c in next, SV.ConnDesc  do c:Disconnect() end
    for _, c in next, SV.ConnText  do c:Disconnect() end
    for _, cs in next, SV.ConnFlag do for _, c in ipairs(cs) do c:Disconnect() end end
    SV.ConnColor, SV.ConnDesc, SV.ConnText, SV.ConnFlag = {}, {}, {}, {}
end

local function Setup(silent)
    DisconnectAll()
    SV.Adjacency, SV.TileIndex, SV.Grid = {}, {}, {}
    SV.TileCount, SV.LastSig, SV.BoardBounds, SV.BoundsDirty = 0, nil, nil, true
    SV.LastRender = nil
    SV.PrevBest = nil
    SV.FlagTried = {}

    SV.GridW, SV.GridH, SV.TileStep, SV.SettingsObj = ReadSettings()
    SV.TotalTiles = SV.GridW and SV.GridH and SV.GridW * SV.GridH or nil
    if MinesVal then SV.TotalMines = MinesVal.Value end

    ClearAll()
    for _, t in ipairs(Parts:GetChildren()) do RegisterTile(t, true) end
    QueueSolve()
    if not silent then
        Toast(("New round · %d tiles"):format(SV.TileCount), TH.Accent)
    end
end

-- shared via SV: CleanupAuto
local function Cleanup()
    SV.Alive = false
    if SV.CleanupAuto then pcall(SV.CleanupAuto) end
    ClearAll()
    DisconnectAll()
    for _, c in ipairs(SV.ConnTop) do c:Disconnect() end
    SV.ConnTop = {}
    for _, c in ipairs(SV.UIConns) do pcall(function() c:Disconnect() end) end
    SV.UIConns = {}
    for _, tw in next, SV.Pulse do pcall(function() tw:Cancel() end) end
    SV.Pulse = {}
    for _, p in ipairs(SV.Pool) do p:Destroy() end
    SV.Pool = {}
    SV.Adjacency, SV.TileIndex, SV.Grid = {}, {}, {}
    SV.BoardBounds, SV.LastSig, SV.LastRender = nil, nil, nil
    Loading.Destroy()
    if Gui.Parent then Gui:Destroy() end
    if VizFolder.Parent then VizFolder:Destroy() end
    _G.CleanupUltraSolver = nil
    _G.UltraSolverInfo    = nil
    _G.UltraSolverDump    = nil
end

-- ─── GLOBAL API ──────────────────────────────────────────
_G.CleanupUltraSolver = Cleanup

-- Diagnostics: run  _G.UltraSolverDump()  in the executor and paste the output if something is off
_G.UltraSolverDump = function()
    local out = {}
    local function add(s) out[#out + 1] = s end
    add(("== Solver %s dump =="):format(VERSION))
    add(("GameRunning=%s  Tiles=%d  GridW=%s GridH=%s TileStep=%s GridStep=%s")
        :format(tostring(GameRunning.Value), SV.TileCount, tostring(SV.GridW), tostring(SV.GridH),
            tostring(SV.TileStep), SV.GridStep and tostring(SV.GridStep.X) or "nil"))
    add("-- ReplicatedStorage.Info children:")
    for _, c in ipairs(Info:GetChildren()) do
        local ok, v = pcall(function() return c.Value end)
        add(("  %s [%s] = %s"):format(c.Name, c.ClassName, ok and tostring(v) or "-"))
        for k, av in next, c:GetAttributes() do add(("      @%s = %s"):format(k, tostring(av))) end
    end
    for k, av in next, Info:GetAttributes() do add(("  @%s = %s"):format(k, tostring(av))) end
    add("-- workspace.Flag children:")
    for _, c in ipairs(FlagFolder:GetChildren()) do
        add(("  %s [%s] (%d children)"):format(c.Name, c.ClassName, #c:GetChildren()))
    end
    local nBeige, nGreen, nOther, other = 0, 0, 0, {}
    for t in next, SV.Adjacency do
        local k = RGBKey(t.Color)
        if BEIGE_KEYS[k] then nBeige += 1 elseif GREEN_KEYS[k] then nGreen += 1
        else
            nOther += 1
            local c = t.Color
            local key = ("%d,%d,%d"):format(math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
            other[key] = (other[key] or 0) + 1
        end
    end
    add(("Tiles by colour: unrevealed(green)=%d  revealed(beige)=%d  UNKNOWN colour=%d"):format(nGreen, nBeige, nOther))
    for key, n in next, other do add(("  unknown colour %s x%d"):format(key, n)) end
    local text = table.concat(out, "\n")
    print(text)
    pcall(function() if setclipboard then setclipboard(text) end end)
    return text
end

_G.UltraSolverInfo = function()
    return {
        GridSize          = SV.GridW and SV.GridH and { X=SV.GridW, Z=SV.GridH } or nil,
        TileSize          = SV.TileStep,
        TotalExpectedTiles= SV.TotalTiles,
        Density           = SV.TotalTiles and (SV.TotalMines / SV.TotalTiles) or nil,
        TileCount         = SV.TileCount,
    }
end

-- ─── exports ───
SV.Cleanup = Cleanup
SV.RegisterTile = RegisterTile
SV.Setup = Setup
SV.UnregisterTile = UnregisterTile
