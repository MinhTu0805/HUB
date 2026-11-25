-- ═══ Config.lua ═══ Services, version, engine CFG, saved user settings
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...

-- ╔══════════════════════════════════════════════════════════════╗
-- ║        BLOCKERMAN MINESWEEPER SOLVER  ·  v4.2                ║
-- ║  ClickDetector flags · safer hops · flat new UI              ║
-- ╚══════════════════════════════════════════════════════════════╝

local RS               = game:GetService("ReplicatedStorage")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local VERSION   = "4.2"
local SAVE_FILE = "BlockermanSolver.json"

-- ─── CONFIG (engine) ────────────────────────────────────
local CFG = {
    TrustFlags          = true,
    MaxBruteForce       = 1000,
    MaxSolutions        = math.huge,
    MaxNodes            = 500_000_000,
    MonteCarloSamples   = 100_000,
    MaxSolveTime        = 2.0,
    MaxDPOps            = 10_000_000,
    MaxCascade          = 12,
    Debounce            = 0.02,
    MinesValueIsRemaining = false,
}

-- ─── USER SETTINGS (saved to file when the executor allows) ─
local S = {
    Enabled     = true,
    ShowSafe    = true,
    ShowMines   = true,
    ShowGuess   = true,
    ShowBest    = true,
    ShowFlagged = false,
    ShowPercent = true,
    Style       = "Soft",      -- Soft | Outline | Dot
    Opacity     = 0.40,
    AlwaysOnTop = false,
    Animations  = true,
    PulseBest   = true,
    UIScale     = 1,
    Language    = "English",   -- English | Tiếng Việt
    TrustFlags  = true,
    Accuracy    = "Balanced",  -- Fast | Balanced | Max
    AutoFlag    = false,
    AutoMove    = false,
    AutoGuess   = false,
    MaxGuessRisk= 0.25,
    FlagMethod  = "Click",     -- Click (ClickDetector, works from anywhere) | Mouse
    WalkFlags   = true,
    StrictSafe  = true,
    JumpOver    = true,           -- hop over ONE blocked tile when it saves a detour
    JumpBoost   = true,           -- higher arc while hopping = safer landing on the far tile
    SafetyMargin= 0.34,
    CautionSpeed= 9,           -- walk speed used next to unsafe tiles
    AutoUnflag  = false,       -- remove flags that the solver proves are on SAFE tiles
    FlagBatch   = 4,           -- flags / unflags handled per pass
    FlagDelay   = 0.10,
}

local ACCURACY = {
    Fast     = { samples = 20_000,  time = 1.0 },
    Balanced = { samples = 100_000, time = 2.0 },
    Max      = { samples = 300_000, time = 4.0 },
}

local function ApplyCfg()
    local a = ACCURACY[S.Accuracy] or ACCURACY.Balanced
    CFG.TrustFlags        = S.TrustFlags
    CFG.MonteCarloSamples = a.samples
    CFG.MaxSolveTime      = a.time
end

do
    local ok, data = pcall(function()
        if isfile and readfile and isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
    end)
    if ok and type(data) == "table" then
        for k, v in next, data do
            if S[k] ~= nil and typeof(v) == typeof(S[k]) then S[k] = v end
        end
    end
    if not ACCURACY[S.Accuracy] then S.Accuracy = "Balanced" end
    if S.Language ~= "English" and S.Language ~= "Tiếng Việt" then S.Language = "English" end
    S.UIScale = math.clamp(S.UIScale, 0.6, 1.5)
    if S.Style ~= "Soft" and S.Style ~= "Outline" and S.Style ~= "Dot" then S.Style = "Soft" end
    S.AutoFlag, S.AutoMove, S.AutoGuess, S.AutoUnflag = false, false, false, false   -- automation always starts OFF
    if S.SafetyMargin < 0.34 then S.SafetyMargin = 0.34 end   -- older saves used a too-thin margin
    if not ({ Click = 1, Mouse = 1 })[S.FlagMethod] then S.FlagMethod = "Click" end
    S.FlagBatch = math.clamp(math.floor(S.FlagBatch + 0.5), 1, 10)
    ApplyCfg()
end

local SavePending = false
local function SaveSettings()
    if SavePending then return end
    SavePending = true
    task.delay(0.6, function()
        SavePending = false
        pcall(function()
            if writefile then writefile(SAVE_FILE, HttpService:JSONEncode(S)) end
        end)
    end)
end

-- ─── exports ───
SV.ApplyCfg = ApplyCfg
SV.CFG = CFG
SV.Lighting = Lighting
SV.Players = Players
SV.RS = RS
SV.RunService = RunService
SV.S = S
SV.SaveSettings = SaveSettings
SV.TweenService = TweenService
SV.UserInputService = UserInputService
SV.VERSION = VERSION
