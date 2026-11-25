-- ═══ Main.lua ═══ Start-up sequence and lifecycle connections
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local BuildWindow, ClearAll, GameRunning, LoadLucide, Loading, MinesVal = SV.BuildWindow, SV.ClearAll, SV.GameRunning, SV.LoadLucide, SV.Loading, SV.MinesVal
local Parts, QueueSolve, RegisterTile, Setup, TH, Toast = SV.Parts, SV.QueueSolve, SV.RegisterTile, SV.Setup, SV.TH, SV.Toast
local UnregisterTile = SV.UnregisterTile

-- ─── START UP ────────────────────────────────────────────
Loading.Set(0.72, "Preparing automation")
task.wait(0.1)

Loading.Set(0.74, "Loading icons")
LoadLucide()

Loading.Set(0.78, "Building interface")
-- A UI error must never take the solver down with it: highlights, auto flag and auto move keep working
local okWin, Win = pcall(BuildWindow)
local WinErr = nil
if not okWin then
    WinErr = tostring(Win)
    warn("[Solver] UI error: " .. WinErr)
    Win = { SetOpen = function() end }
end
task.wait(0.12)

Loading.Set(0.88, "Indexing tiles")
-- ─── LIFECYCLE CONNECTIONS ───────────────────────────────
SV.ConnTop[#SV.ConnTop+1] = Parts.ChildAdded:Connect(function(c) RegisterTile(c, false) end)
SV.ConnTop[#SV.ConnTop+1] = Parts.ChildRemoved:Connect(UnregisterTile)
SV.ConnTop[#SV.ConnTop+1] = GameRunning:GetPropertyChangedSignal("Value"):Connect(function()
    if GameRunning.Value then Setup()
    else SV.LastSig = nil; SV.LastRender = nil; ClearAll() end
end)
if MinesVal then
    SV.ConnTop[#SV.ConnTop+1] = MinesVal:GetPropertyChangedSignal("Value"):Connect(QueueSolve)
end
if SV.SettingsObj then
    SV.ConnTop[#SV.ConnTop+1] = SV.SettingsObj.AttributeChanged:Connect(function(attr)
        if (attr == "GridSize" or attr == "GridSizeX" or
            attr == "GridSizeZ" or attr == "TileSize") and GameRunning.Value then
            Setup()
        end
    end)
end

-- If a round is already running when the script is executed, start right away
if GameRunning.Value then Setup(true) end

Loading.Set(0.96, "Warming up solver")
task.wait(0.3)
SV.BootDone = true
Loading.Finish()
Win.SetOpen(true)
Toast(GameRunning.Value and "Solver ready" or "Solver ready · waiting for next round", TH.Good)
if WinErr then Toast("UI error: " .. string.sub(WinErr, 1, 110), TH.Bad) end
