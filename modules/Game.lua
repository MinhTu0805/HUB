-- ═══ Game.lua ═══ Finds the game objects (board, Info, flags) and reads board settings; start-up watchdog
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local Loading, RS, TH, Toast = SV.Loading, SV.RS, SV.TH, SV.Toast

-- Wait for an instance while showing live status on the loader
local function WaitFor(parent, name, label, maxWait)
    local o = parent:FindFirstChild(name)
    local waited = 0
    while not o do
        o = parent:WaitForChild(name, 2)
        if not o then
            waited += 2
            Loading.Status(("Waiting for %s… (%ds)"):format(label or name, waited))
            if maxWait and waited >= maxWait then return nil end
        end
    end
    return o
end

-- Watchdog: if start-up is still stuck after 15s, release the screen and say where it is stuck
SV.BootDone = false
task.delay(15, function()
    if SV.BootDone or not SV.Alive then return end
    pcall(Loading.Release)
    warn("[Solver] Still starting after 15s. Last step: " .. tostring(Loading.Last)
        .. "  (a 'Waiting for …' step means that object is missing from the game; join a round / check names)")
    pcall(Toast, "Still starting: " .. tostring(Loading.Last), TH.Warn)
end)

Loading.Set(0.06, "Checking environment")
task.wait(0.18)

-- ─── ROBLOX REFS ────────────────────────────────────────
Loading.Set(0.20, "Locating board")
local FlagFolder  = WaitFor(workspace, "Flag", "board")
local Parts       = WaitFor(FlagFolder, "Parts", "tiles")
task.wait(0.12)

Loading.Set(0.38, "Connecting to game")
local Info        = WaitFor(RS, "Info", "game info")
local GameRunning = WaitFor(Info, "GameRunning", "game state")
local MinesVal    = Info:FindFirstChild("Mines")
SV.FlagsRoot   = WaitFor(RS, "Flags", "flag models", 4)
if not SV.FlagsRoot then
    warn("[Solver] ReplicatedStorage.Flags not found - continuing without flag-model names")
    SV.FlagsRoot = Instance.new("Folder")
    SV.FlagsRoot.Name = "Flags"
end
task.wait(0.12)

-- ─── SETTINGS PARSE ─────────────────────────────────────
Loading.Set(0.52, "Reading board settings")
-- Real tile spacing measured from the board itself (used when TileSize is not provided)
local function InferStep()
    local xs, seen, n = {}, {}, 0
    for _, t in ipairs(Parts:GetChildren()) do
        if t:IsA("BasePart") then
            local x = math.floor(t.Position.X * 100 + 0.5)
            if not seen[x] then seen[x] = true; xs[#xs + 1] = x end
            n += 1
            if n >= 400 then break end
        end
    end
    if #xs < 2 then return nil end
    table.sort(xs)
    local best = math.huge
    for i = 2, #xs do
        local d = xs[i] - xs[i - 1]
        if d > 0 and d < best then best = d end
    end
    return best < math.huge and best / 100 or nil
end

local function ReadSettings()
    local s = Info:FindFirstChild("Settings")
    local gx = s and (s:GetAttribute("GridSizeX") or s:GetAttribute("GridSize"))
    local gz = s and s:GetAttribute("GridSizeZ") or gx
    local ts = s and s:GetAttribute("TileSize")
    if typeof(gx) == "Vector2" then gx, gz = gx.X, gx.Y
    elseif typeof(gx) == "Vector3" then gx, gz = gx.X, gx.Z end

    -- missing / zero / absurd grid size = no usable grid
    if type(gx) ~= "number" or type(gz) ~= "number"
       or gx <= 0 or gz <= 0 or gx * gz > 250000 then
        gx, gz = nil, nil
    end
    if type(ts) ~= "number" or ts <= 0 then
        ts = InferStep()          -- nil → RegisterTile falls back to the first tile's size
        if ts == nil then ts = 4 end
    end
    return gx, gz, ts, s
end

SV.GridW, SV.GridH, SV.TileStep, SV.SettingsObj = ReadSettings()
SV.TotalTiles  = SV.GridW and SV.GridH and SV.GridW * SV.GridH or nil
SV.TotalMines  = MinesVal and MinesVal.Value or 0
task.wait(0.1)

-- ─── exports ───
SV.FlagFolder = FlagFolder
SV.GameRunning = GameRunning
SV.Info = Info
SV.MinesVal = MinesVal
SV.Parts = Parts
SV.ReadSettings = ReadSettings
