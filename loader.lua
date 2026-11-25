-- ╔══════════════════════════════════════════════════════════════╗
-- ║  BLOCKERMAN SOLVER · Loader                                  ║
-- ║  Run THIS file. It fetches and runs every module in order.   ║
-- ╚══════════════════════════════════════════════════════════════╝
--
-- Two ways to load the modules (pick one):
--   1) GitHub / any web host : set BASE_URL to the folder that contains "modules/"
--        e.g. "https://raw.githubusercontent.com/<user>/<repo>/main"
--   2) Local files           : leave BASE_URL = "" and copy the folder "BlockermanSolver"
--        (with its "modules" folder) into your executor's workspace folder.

local BASE_URL  = "https://raw.githubusercontent.com/MinhTu0805/HUB/refs/heads/main"                    -- "" = use local files
local LOCAL_DIR = "BlockermanSolver"    -- workspace folder used when BASE_URL is ""

-- Load order matters: each module may only use modules that come before it.
local MODULES = {
    "Config",         -- services, version, engine config, saved settings
    "Language",       -- English / Tiếng Việt
    "UIBase",         -- theme, helpers, ScreenGui, toasts, icons
    "LoadingScreen",  -- loading animation
    "Game",           -- game objects + board settings, start-up watchdog
    "Overlay",        -- highlight parts (safe / mine / guess)
    "Board",          -- grid, tile metadata, solve queue, render
    "Solver",         -- constraint engine
    "Lifecycle",      -- tile registration, setup / teardown, _G API
    "Automation",     -- auto flag, auto move, mine avoidance
    "Window",         -- settings window UI
    "Main",           -- start-up sequence
}

-- Unload the previous instance first (safe to re-execute)
if _G.CleanupUltraSolver then pcall(_G.CleanupUltraSolver) end

local function fetch(name)
    local path = "modules/" .. name .. ".lua"
    if BASE_URL ~= "" then
        return game:HttpGet(BASE_URL .. "/" .. path)
    end
    local full = LOCAL_DIR .. "/" .. path
    assert(isfile and readfile, "executor has no readfile/isfile - set BASE_URL instead")
    assert(isfile(full), "missing file: " .. full)
    return readfile(full)
end

local SV = {}   -- state shared between modules

local function fail(name, err)
    warn(("[Solver] module '%s' failed: %s"):format(name, tostring(err)))
    -- never leave a half-built UI / loading screen on the screen
    pcall(function() if SV.Loading and SV.Loading.Destroy then SV.Loading.Destroy() end end)
    pcall(function() if SV.Gui then SV.Gui:Destroy() end end)
    pcall(function() if SV.Alive ~= nil then SV.Alive = false end end)
end

for _, name in ipairs(MODULES) do
    local okFetch, src = pcall(fetch, name)
    if not okFetch then return fail(name, src) end
    local fn, cerr = loadstring(src, "=" .. name)
    if not fn then return fail(name, cerr) end
    local ok, err = xpcall(fn, function(e) return debug.traceback(tostring(e), 2) end, SV)
    if not ok then return fail(name, err) end
end
