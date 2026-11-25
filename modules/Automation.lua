-- ═══ Automation.lua ═══ Auto flag / unflag, smooth auto move, mine avoidance, ClickDetector flags
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local Bind, GREEN_KEYS, GameRunning, GridKey, HasFlag, Players = SV.Bind, SV.GREEN_KEYS, SV.GameRunning, SV.GridKey, SV.HasFlag, SV.Players
local RGBKey, RS, RunService, S, TileGridPos, UserInputService = SV.RGBKey, SV.RS, SV.RunService, SV.S, SV.TileGridPos, SV.UserInputService

-- ─── AUTOMATION (auto flag · smooth auto move · mine avoidance) ──
local GuiService = game:GetService("GuiService")
local Auto  = { move = "Off", flag = "Off", flags = 0, unflags = 0, steps = 0, method = "—", unmethod = "—" }
local D4    = { {1,0}, {-1,0}, {0,1}, {0,-1} }
local IsTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local function PosToGrid(p)
    local step = SV.TileStep or (SV.GridStep and SV.GridStep.X)
    if not step then return nil end
    return math.round(p.X / step), math.round(p.Z / (SV.TileStep or SV.GridStep.Z))
end
local function TileAt(p)
    local gx, gz = PosToGrid(p)
    return gx and SV.Grid[GridKey(gx, gz)]
end
local function GetChar()
    local c   = Players.LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 then return hum, hrp end
end
-- Walk-speed governor: eases the speed down next to unsafe tiles and back up
-- afterwards (no more sudden 16 → 9 snaps), and restores the game's own speed.
local Gov = { base = nil, last = nil }
local function GovSet(hum, want, dt, snap)
    local cur = hum.WalkSpeed
    if Gov.last == nil then Gov.base = cur
    elseif math.abs(cur - Gov.last) > 0.05 then Gov.base = cur end      -- the game changed it: adopt that as the base
    local tgt = math.min(want, Gov.base)
    local step = (dt or 0.016)
    local nv = snap and tgt or (cur + math.clamp(tgt - cur, -step * 70, step * 40))
    hum.WalkSpeed = nv
    Gov.last = nv
end
local function GovRestore(hum)
    if Gov.last ~= nil then
        hum.WalkSpeed = Gov.base
        Gov.last = nil
    end
end
-- Temporary jump boost for hops (restored on landing / when walking stops)
local Boost = nil   -- { hum, up, orig }
local function ApplyBoost(hum, jp)
    if Boost or not jp or jp.boost <= 1.001 then return end
    local up = hum.UseJumpPower
    Boost = { hum = hum, up = up, orig = up and hum.JumpPower or hum.JumpHeight }
    if up then hum.JumpPower = Boost.orig * jp.boost
    else hum.JumpHeight = Boost.orig * jp.boost * jp.boost end
end
local function RestoreBoost()
    if not Boost then return end
    local b = Boost; Boost = nil
    pcall(function()
        if b.up then b.hum.JumpPower = b.orig else b.hum.JumpHeight = b.orig end
    end)
end
local function StopWalking()
    RestoreBoost()
    local hum, hrp = GetChar()
    if hum then
        GovRestore(hum)
        pcall(function() hum:MoveTo(hrp.Position) end)
    end
end
SV.CleanupAuto = function() StopWalking() end

-- ══ Walkability rules ══════════════════════════════════════
-- walk(t)   : tile we are allowed to stand on
-- goalOK(t) : tile we may deliberately step on to reveal it
local function MakeRules(R)
    local state, beige, weak = R.state, R.beige, R.weak or {}
    local strict = S.StrictSafe
    local function nextToNumber(t)
        local adj = SV.Adjacency[t]
        if adj then for _, nb in ipairs(adj) do if beige[nb] then return true end end end
        return false
    end
    local function goalOK(t)
        if state[t] ~= 1 or not SV.Adjacency[t] then return false end
        -- never walk on a tile that is only PREDICTED safe: it must be proven
        if not (R.pure and R.pure[t] == 1) then return false end
        if strict and (weak[t] or not nextToNumber(t)) then return false end
        return true
    end
    local cache = {}
    local function walk(t)
        local c = cache[t]
        if c ~= nil then return c end
        local v = false
        if beige[t] then v = true
        elseif state[t] == 1 then v = goalOK(t)
        -- Only a flag that exists RIGHT NOW protects us. The solver snapshot can be
        -- older than the flag (placed late, removed, or never confirmed by the server).
        elseif state[t] == 2 and S.WalkFlags and HasFlag(t) then v = true end
        cache[t] = v
        return v
    end
    return walk, goalOK
end

-- Shortest path over walkable tiles to the nearest goal. With jumpOK the search may
-- also hop over ONE blocked tile in a straight line (cost 6 ≈ a 5-tile detour: only worth the risk when it saves a lot).
-- Second result: set of tiles that are reached by a jump (path[i-1] → path[i]).
local JUMP_COST = 6
local function FindPath(start, goals, walk, jumpOK)
    local dist, prev, viaJump = { [start] = 0 }, { [start] = false }, {}
    local buckets, pending, cur = { [0] = { start } }, 1, 0
    local function add(t, d)
        local b = buckets[d]
        if not b then b = {}; buckets[d] = b end
        b[#b + 1] = t
        pending += 1
    end
    while pending > 0 and cur < 4000 do
        local b = buckets[cur]
        if b then
            local i = 1
            while i <= #b do
                local t = b[i]; i += 1; pending -= 1
                if dist[t] == cur then
                    if t ~= start and goals[t] then
                        local path, c = {}, t
                        while c do table.insert(path, 1, c); c = prev[c] end
                        return path, viaJump
                    end
                    if t == start or walk(t) then
                        local gx, gz = TileGridPos(t)
                        if gx then
                            for _, o in ipairs(D4) do
                                local nb = SV.Grid[GridKey(gx + o[1], gz + o[2])]
                                if nb then
                                    if walk(nb) or goals[nb] then
                                        local nd = cur + 1
                                        if dist[nb] == nil or nd < dist[nb] then
                                            dist[nb] = nd; prev[nb] = t; viaJump[nb] = nil; add(nb, nd)
                                        end
                                    elseif jumpOK then
                                        local lx = SV.Grid[GridKey(gx + o[1] * 2, gz + o[2] * 2)]
                                        if lx and (walk(lx) or goals[lx]) then
                                            local nd = cur + JUMP_COST
                                            if dist[lx] == nil or nd < dist[lx] then
                                                dist[lx] = nd; prev[lx] = t; viaJump[lx] = true; add(lx, nd)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            buckets[cur] = nil
        end
        cur += 1
    end
end

-- Straight-line check: the character's whole footprint (centre ± margin) must stay on allowed tiles
local function LineClear(P, Q, okTile)
    local sx = SV.TileStep or (SV.GridStep and SV.GridStep.X) or 4
    local sz = SV.TileStep or (SV.GridStep and SV.GridStep.Z) or 4
    local dx, dz = Q.X - P.X, Q.Z - P.Z
    local len = math.sqrt(dx * dx + dz * dz)
    if len < 1e-3 then return true end
    local ux, uz = dx / len, dz / len
    local m  = S.SafetyMargin * sx
    local px, pz = -uz * m, ux * m
    -- dense sweep: 0.1-tile steps along the line, 5 lateral samples across the body,
    -- so a thin corner of an unsafe tile can no longer slip between sample points
    local n = math.max(1, math.ceil(len / (sx * 0.1)))
    for i = 0, n do
        local x, z = P.X + dx * i / n, P.Z + dz * i / n
        for k = -2, 2 do
            local f = k * 0.5
            local t = SV.Grid[GridKey(math.round((x + px * f) / sx), math.round((z + pz * f) / sz))]
            if not (t and okTile(t)) then return false end
        end
    end
    return true
end

-- True when any tile around (gx,gz) (incl. diagonals) is NOT allowed to be stepped on
local function NearHazard(t, okTile)
    local gx, gz = TileGridPos(t)
    if not gx then return false end
    for dx = -1, 1 do
        for dz = -1, 1 do
            if dx ~= 0 or dz ~= 0 then
                local nb = SV.Grid[GridKey(gx + dx, gz + dz)]
                if nb and not okTile(nb) then return true end
            end
        end
    end
    return false
end

-- Can this character clear one tile? Uses the real jump physics (gravity, jump
-- power / height) and the speed it normally walks at. The jump is boosted a little
-- (longer air time) so the hop no longer needs almost full run speed to reach tile B.
local JUMP_BOOST = 1.35
local function JumpPhysics(hum, baseSpeed)
    local g = workspace.Gravity
    local up = hum.UseJumpPower
    local cur = up and hum.JumpPower or hum.JumpHeight
    if Boost then cur = Boost.orig end                 -- already boosted: read the real value
    local v0 = up and cur or math.sqrt(math.max(0, 2 * g * cur))
    if v0 < 12 then return nil end
    local boost    = S.JumpBoost and JUMP_BOOST or 1
    local tAir     = 2 * v0 * boost / g
    local st       = SV.TileStep or (SV.GridStep and SV.GridStep.X) or 4
    local takeoff  = st * 0.22                 -- take off just before the edge of our tile
    local minLand  = st * 1.5 + 1.0            -- body fully past the blocked tile
    if baseSpeed * tAir < (minLand - takeoff) + 0.6 then return nil end
    local need = (st * 2 - takeoff) / tAir     -- speed that lands us on the centre of B
    if need > baseSpeed * 0.9 then return nil end   -- not enough speed headroom: walk around instead
    return { tAir = tAir, takeoff = takeoff, st = st, boost = boost, need = need }
end


-- Decides where to steer right now.
-- Returns: target (Vector3) | nil, status text, caution(bool), jump (table | nil)
local function ComputeTarget(R, hrp, nav, jumpOK)
    local walk, goalOK = MakeRules(R)
    local goals, any, guessing = {}, false, false
    for _, t in ipairs(R.green) do
        if goalOK(t) then goals[t] = true; any = true end
    end
    if not any and S.AutoGuess and R.best and SV.Adjacency[R.best]
       and R.bestProb and R.bestProb <= S.MaxGuessRisk then
        goals[R.best] = true; any = true; guessing = true
    end
    local start = TileAt(hrp.Position)
    if not start then return nil, "Step onto the board" end
    if not any then
        return nil, S.AutoGuess and "No move under risk limit" or "No safe move (guess needed)"
    end
    -- Goal commitment: keep heading for the previous goal unless a clearly closer
    -- one appeared. Without this the character flips between equal-distance goals
    -- every time the board changes and zig-zags along unsafe edges.
    local path, via
    if nav and nav.goal and goals[nav.goal] and nav.goal ~= start then
        local p, v = FindPath(start, { [nav.goal] = true }, walk, jumpOK)
        if p and p[2] then path, via = p, v end
    end
    local near, nvia = FindPath(start, goals, walk, jumpOK)
    if not path then path, via = near, nvia
    elseif near and #near + 3 < #path then path, via = near, nvia end
    if not path or not path[2] then
        if nav then nav.goal = nil end
        return nil, "No safe path"
    end
    if nav then nav.goal = path[#path] end

    local P = hrp.Position
    local function okTile(t) return t == start or walk(t) or goals[t] end
    -- Slow down whenever an unsafe tile touches the tile we stand on or the next one
    local caution = NearHazard(start, okTile) or NearHazard(path[2], okTile)

    -- The very next step is a hop over a blocked tile
    if via and via[path[2]] then
        local ax, az = TileGridPos(path[1])
        local bx, bz = TileGridPos(path[2])
        if ax and bx then
            local sx, sz = math.sign(bx - ax), math.sign(bz - az)
            return nil, "Jumping", true, { S = path[1], B = path[2], dir = Vector3.new(sx, 0, sz) }
        end
    end

    -- String-pulling: aim at the farthest path tile we can reach in a straight, safe line,
    -- but steer at a point a few studs ahead on that line (a "carrot") so the walk is one
    -- smooth run instead of stop-and-go between tile centres.
    -- Next to hazards only look 3 tiles ahead so the body stays close to the tile centres.
    local reach = caution and 3 or 14
    for j = math.min(#path, reach), 2, -1 do
        if not (via and via[path[j]]) and LineClear(P, path[j].Position, okTile) then
            local q = path[j].Position
            local fx, fz = q.X - P.X, q.Z - P.Z
            local dist = math.sqrt(fx * fx + fz * fz)
            local look = caution and 4.5 or 9
            local aim
            if dist <= look * 1.15 then
                aim = Vector3.new(q.X, P.Y, q.Z)
            else
                aim = Vector3.new(P.X + fx / dist * look, P.Y, P.Z + fz / dist * look)
            end
            return aim, guessing and "Guessing" or "Walking", caution
        end
    end
    -- Footprint touches something unsafe: re-centre on our tile first
    local c = start.Position
    return Vector3.new(c.X, P.Y, c.Z), "Re-centring", true
end

do
    local nav = { t = 0, R = nil, target = nil, wasMoving = false, goal = nil, caution = false,
                  jump = nil, jp = nil, air = nil, run = false, lastPos = nil, lastCheck = 0, stuck = 0,
                  jumpBan = 0, jfail = 0, retreat = false }

    local function reset()
        nav.wasMoving, nav.target, nav.goal, nav.jump, nav.air, nav.run = false, nil, nil, nil, nil, false
        nav.retreat = false
        StopWalking()
    end

    Bind(RunService.Heartbeat:Connect(function(dt)
        if not SV.Alive then return end
        local R = SV.LastRender
        if not (S.AutoMove and S.Enabled and GameRunning.Value and R) then
            Auto.move = S.AutoMove and "Waiting for round" or "Off"
            if nav.wasMoving then reset() end
            return
        end
        local hum, hrp = GetChar()
        if not hum then Auto.move = "No character"; return end

        local now = os.clock()
        local P = hrp.Position

        -- ── airborne part of a jump: steer + trim speed so we land on the centre of B ──
        if nav.air then
            local a = nav.air
            local el = now - a.t0
            local grounded = hum.FloorMaterial ~= Enum.Material.Air
            if (el > 0.2 and grounded) or el > 1.4 then
                nav.air, nav.t = nil, 0
                RestoreBoost()           -- landed: plan the next step immediately
            else
                local along = (P.X - a.origin.X) * a.dir.X + (P.Z - a.origin.Z) * a.dir.Z
                local remain = a.landAlong - along
                local tRem = math.max(0.07, a.tAir - el)
                GovSet(hum, math.clamp(remain / tRem, 3, 60), dt, true)
                hum:MoveTo(Vector3.new(a.land.X, P.Y, a.land.Z))
                Auto.move = "Jumping"
                return
            end
        end

        if nav.R ~= R or now - nav.t >= 0.05 then
            nav.R, nav.t = R, now
            local base = Gov.last and Gov.base or hum.WalkSpeed
            nav.jp = (S.JumpOver and now >= nav.jumpBan) and JumpPhysics(hum, base) or nil
            local ok, tgt, msg, caution, jump = pcall(ComputeTarget, R, hrp, nav, nav.jp ~= nil)
            if ok then
                nav.target, Auto.move, nav.caution, nav.jump = tgt, msg, caution == true, jump
            else
                nav.target, Auto.move, nav.caution, nav.jump = nil, "Error", true, nil
            end
        end

        if nav.jump and nav.jp then
            -- ── hop over a blocked tile: align on the line, run up, take off EARLY, land on B ──
            nav.wasMoving = true
            local j, jp = nav.jump, nav.jp
            local st, sPos = jp.st, j.S.Position
            local rx, rz = P.X - sPos.X, P.Z - sPos.Z
            local along = rx * j.dir.X + rz * j.dir.Z
            local lx, lz = rx - j.dir.X * along, rz - j.dir.Z * along
            local lat = math.sqrt(lx * lx + lz * lz)
            local grounded = hum.FloorMaterial ~= Enum.Material.Air
            local vel = hrp.AssemblyLinearVelocity
            local vAlong = vel.X * j.dir.X + vel.Z * j.dir.Z
            -- the jump command takes a few frames to lift the feet: fire it a little BEFORE the
            -- take-off point so the feet are already in the air when they reach the blocked tile
            local lead = math.clamp(vAlong, 0, 40) * 0.06
            local need = math.clamp(jp.need, 6, 60)
            local back = Vector3.new(sPos.X - j.dir.X * st * 0.3, P.Y, sPos.Z - j.dir.Z * st * 0.3)

            if TileAt(P) ~= j.S then
                nav.retreat = false
                GovSet(hum, S.CautionSpeed, dt)
                hum:MoveTo(Vector3.new(sPos.X, P.Y, sPos.Z))
            elseif nav.retreat then
                GovSet(hum, S.CautionSpeed, dt)
                hum:MoveTo(back)
                if along <= -st * 0.2 and lat <= 0.5 then nav.retreat = false end
            else
                local aligned = lat <= (nav.run and 0.6 or 0.4) and along <= jp.takeoff + 0.45
                nav.run = aligned
                if not aligned then
                    GovSet(hum, S.CautionSpeed, dt)
                    hum:MoveTo(back)
                elseif along + lead >= jp.takeoff and grounded then
                    if vAlong >= need * 0.7 then
                        nav.air = { t0 = now, dir = j.dir, origin = sPos, land = j.B.Position,
                                    landAlong = st * 2, tAir = jp.tAir }
                        nav.run, nav.jfail = false, 0
                        ApplyBoost(hum, jp)
                        GovSet(hum, need, dt, true)
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        hum:MoveTo(Vector3.new(j.B.Position.X, P.Y, j.B.Position.Z))
                        Auto.move = "Jumping"
                    else
                        -- too slow to clear the tile safely: back up for a longer run-up
                        nav.retreat, nav.run = true, false
                        nav.jfail += 1
                        if nav.jfail >= 3 then
                            -- keeps failing: forget this hop for a while and walk around instead
                            nav.jfail, nav.retreat, nav.jump = 0, false, nil
                            nav.jumpBan, nav.t = now + 8, 0
                        end
                    end
                else
                    GovSet(hum, need, dt, true)
                    hum:MoveTo(Vector3.new(sPos.X + j.dir.X * st * 0.7, P.Y, sPos.Z + j.dir.Z * st * 0.7))
                end
            end
        elseif nav.target then
            nav.wasMoving = true
            nav.run = false
            GovSet(hum, nav.caution and S.CautionSpeed or 1e9, dt)
            hum:MoveTo(nav.target)
            -- stuck? re-plan from scratch
            if now - nav.lastCheck > 0.7 then
                if nav.lastPos and (P - nav.lastPos).Magnitude < 0.3 then
                    nav.stuck += 1
                    if nav.stuck >= 3 then nav.goal, nav.stuck, nav.t = nil, 0, 0 end
                else
                    nav.stuck = 0
                end
                nav.lastPos, nav.lastCheck = P, now
            end
        elseif nav.wasMoving then
            nav.wasMoving = false
            StopWalking()
        end
    end))
end

-- ══ Flags: ClickDetector (same trick as the classic script) ══════════════════════
-- Every tile has a ClickDetector. Firing it with distance 0 toggles the flag from
-- ANYWHERE on the board, so there is no range limit and nothing to "learn".
-- The variant that works is remembered for this session only.
local FlagRemote, RemoteScan = nil, 0
local function FindFlagRemote()
    if FlagRemote and FlagRemote.Parent then return FlagRemote end
    if os.clock() - RemoteScan < 5 then return nil end
    RemoteScan = os.clock()
    for _, d in ipairs(RS:GetDescendants()) do
        if d:IsA("RemoteEvent") and not d:IsDescendantOf(SV.FlagsRoot) then
            local n = d.Name:lower()
            if n:find("flag") or n:find("mark") then FlagRemote = d; break end
        end
    end
    return FlagRemote
end

local CDCache = setmetatable({}, { __mode = "k" })
local function GetCD(tile)
    local cd = CDCache[tile]
    if cd and cd.Parent then return cd end
    cd = tile:FindFirstChildOfClass("ClickDetector") or tile:FindFirstChildWhichIsA("ClickDetector", true)
    CDCache[tile] = cd
    return cd
end

-- still an unrevealed (green) tile, checked LIVE (the solver snapshot can be a moment old)
local function IsHidden(tile)
    return tile.Parent ~= nil and GREEN_KEYS[RGBKey(tile.Color)] == true
end

local function MouseFlag(tile)
    local cam = workspace.CurrentCamera
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if not (cam and ok and vim) then return end
    local v, on = cam:WorldToViewportPoint(tile.Position)
    if not on or v.Z <= 0 then return end
    local inset = GuiService:GetGuiInset()
    vim:SendMouseButtonEvent(v.X, v.Y + inset.Y, 1, true, game, 0)
    task.wait(0.03)
    vim:SendMouseButtonEvent(v.X, v.Y + inset.Y, 1, false, game, 0)
end

local function ClickVariants(tile)
    local list = {}
    if S.FlagMethod ~= "Mouse" then
        local cd = typeof(fireclickdetector) == "function" and GetCD(tile)
        if cd then
            list[#list + 1] = { "Click", function() fireclickdetector(cd, 0) end }
            list[#list + 1] = { "Right-click event", function() fireclickdetector(cd, 0, "RightMouseClick") end }
        else
            local r = FindFlagRemote()
            if r then
                list[#list + 1] = { "Remote(tile)",     function() r:FireServer(tile) end }
                list[#list + 1] = { "Remote(position)", function() r:FireServer(tile.Position) end }
            end
        end
    end
    if (S.FlagMethod == "Mouse" or #list == 0) and not IsTouch then
        list[#list + 1] = { "Mouse", function() MouseFlag(tile) end }
    end
    return list
end

local Working = { on = nil, off = nil }   -- variant that worked this session
local function PickVariant(list, ft, mode)
    local pref = Working[mode]
    if pref and ft.n <= 2 then
        for _, v in ipairs(list) do if v[1] == pref then return v end end
    end
    return list[((ft.n - 1) % #list) + 1]
end

-- One pass: remove wrong flags first (they poison the solver), then flag proven mines.
-- Closest tiles first, several per pass, no distance limit.
local function FlagStep(R)
    local _, hrp = GetChar()
    local origin = hrp and hrp.Position
    local now = os.clock()

    local function eligible(t, mode)
        local ft = SV.FlagTried[t]
        if ft and ft.mode ~= mode then SV.FlagTried[t] = nil; ft = nil end
        if not ft then return true end
        if ft.n >= 5 and now - ft.t > 6 then ft.n = 0 end
        -- 1.1s between tries: a flag that is only slow to replicate must not be toggled twice
        return ft.n < 5 and now - ft.t > 1.1
    end
    local function dist(t) return origin and (t.Position - origin).Magnitude or 0 end

    local jobs = {}
    if S.AutoUnflag and R.wrong then
        local list = {}
        for t in next, R.wrong do
            if SV.Adjacency[t] and IsHidden(t) and HasFlag(t) and eligible(t, "off") then list[#list + 1] = t end
        end
        table.sort(list, function(a, b) return dist(a) < dist(b) end)
        for _, t in ipairs(list) do jobs[#jobs + 1] = { t, "off" } end
    end
    if S.AutoFlag and R.pure then
        local list = {}
        for _, t in ipairs(R.green) do
            -- only PROVEN mines: a predicted mine flagged wrongly would later poison the solver
            if R.pure[t] == 2 and SV.Adjacency[t] and IsHidden(t) and not HasFlag(t) and eligible(t, "on") then
                list[#list + 1] = t
            end
        end
        table.sort(list, function(a, b) return dist(a) < dist(b) end)
        for _, t in ipairs(list) do jobs[#jobs + 1] = { t, "on" } end
    end

    if #jobs == 0 then
        Auto.flag = "Idle"
        return
    end

    for i = 1, math.min(#jobs, math.max(1, S.FlagBatch)) do
        local t, mode = jobs[i][1], jobs[i][2]
        local list = ClickVariants(t)
        if #list == 0 then Auto.flag = "No flag method available"; break end
        local ft = SV.FlagTried[t]
        if not ft then ft = { n = 0, t = 0, mode = mode, done = false }; SV.FlagTried[t] = ft end
        ft.n += 1; ft.t = now
        local v = PickVariant(list, ft, mode)
        Auto.flag = (mode == "on" and "Flagging · " or "Unflagging · ") .. v[1]
        pcall(v[2])
        task.delay(0.9, function()
            if not SV.Alive or not GameRunning.Value or not t.Parent then return end
            local has = HasFlag(t)
            if ((mode == "on" and has) or (mode == "off" and not has)) and not ft.done then
                ft.done = true
                Working[mode] = v[1]
                if mode == "on" then Auto.flags += 1; Auto.method = v[1]
                else Auto.unflags += 1; Auto.unmethod = v[1] end
            end
        end)
    end
end

-- The loop can no longer die: every pass is wrapped in pcall, a failure is logged and retried.
task.spawn(function()
    while SV.Alive do
        task.wait(math.max(0.05, S.FlagDelay))
        local R = SV.LastRender
        if not (S.AutoFlag or S.AutoUnflag) then
            Auto.flag = "Off"
        elseif not (S.Enabled and GameRunning.Value and R) then
            Auto.flag = "Waiting for round"
        else
            local ok, err = pcall(FlagStep, R)
            if not ok then
                Auto.flag = "Recovered from an error"
                warn("[Solver] flag loop: " .. tostring(err))
            end
        end
    end
end)

-- ─── exports ───
SV.Auto = Auto
SV.StopWalking = StopWalking
