-- Đặt LocalScript trong Frame của GUI
local knifeFakeButton = script.Parent:WaitForChild("KnifeFakeButton")
local gunFakeButton = script.Parent:WaitForChild("GunFakeButton")
local teleportVoidButton = script.Parent:WaitForChild("TeleportVoidButton")
local teleportMapVoteButton = script.Parent:WaitForChild("TeleportMapVoteButton")
local teleportLobbyButton = script.Parent:WaitForChild("TeleportLobbyButton")
local teleportMurdererButton = script.Parent:WaitForChild("TeleportMurdererButton")
local teleportSheriffButton = script.Parent:WaitForChild("TeleportSheriffButton")
local targetPlayerButton = script.Parent:WaitForChild("TargetPlayerButton")
local playerNameInput = script.Parent:WaitForChild("PlayerNameInput") -- TextBox để nhập tên người chơi
local hubFrame = script.Parent -- Toàn bộ hub hoặc phần tử chứa các nút
local hubNameLabel = script.Parent:WaitForChild("HubNameLabel")

-- Thiết lập nền galaxy
hubFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 40) -- Màu nền tối để tạo cảm giác không gian
hubFrame.BackgroundTransparency = 0.3 -- Độ trong suốt của nền

-- Tạo gradient cho nền
local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 40)), -- Màu tối
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 60))  -- Màu sáng hơn để tạo hiệu ứng ánh sáng
}
uiGradient.Rotation = 45 -- Góc gradient
uiGradient.Parent = hubFrame

-- Thêm góc bo tròn cho hub
local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 20) -- Bo tròn góc với bán kính 20
uicorner.Parent = hubFrame

-- Thiết lập tên cho hub
hubNameLabel.Text = "CrazyGameEditorHack"
hubNameLabel.TextSize = 36
hubNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu trắng
hubNameLabel.BackgroundTransparency = 1 -- Trong suốt, không có nền
hubNameLabel.Position = UDim2.new(0.5, -hubNameLabel.TextBounds.X/2, 0, 10) -- Canh giữa ở trên cùng

-- Thiết lập các nút
local function setButtonStyle(button)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Màu nền nút
    button.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
    button.TextSize = 24
    button.Font = Enum.Font.Gotham -- Chọn font phù hợp
    button.BorderSizePixel = 0 -- Không có viền
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 15) -- Bo tròn góc nút
    uicorner.Parent = button
end

-- Áp dụng kiểu dáng cho các nút
local buttons = {
    autoFarmButton, beachballsButton, coinsButton, bothButton, 
    twoLivesButton, exposeRolesButton, autoExposeRolesButton, 
    exposeMurdererPerkButton, autoExposeMurdererPerkButton, 
    outlineEveryoneButton, outlineDroppedGunButton, tracerDroppedGunButton, 
    dualKnifeEffectsButton, optimizeCoinsButton, disableBankScannerButton, 
    gunSilentAimButton, showRoundTimerButton, teleportVoidButton, 
    teleportMapVoteButton, teleportLobbyButton, teleportMurdererButton, 
    teleportSheriffButton, targetPlayerButton, knifeFakeButton, gunFakeButton
}

for _, button in pairs(buttons) do
    setButtonStyle(button)
end

-- Thiết lập các thuộc tính của các nút và nhãn
autoFarmButton.Text = "Toggle Auto Farm"
beachballsButton.Text = "Farm Beachballs"
coinsButton.Text = "Farm Coins"
bothButton.Text = "Farm Coins & Beachballs"
twoLivesButton.Text = "Toggle Two Lives"
exposeRolesButton.Text = "Expose Roles"
autoExposeRolesButton.Text = "Auto Expose Roles"
exposeMurdererPerkButton.Text = "Expose Murderer's Perk"
autoExposeMurdererPerkButton.Text = "Auto Expose Murderer's Perk"
outlineEveryoneButton.Text = "Outline Everyone"
outlineDroppedGunButton.Text = "Outline Dropped Gun"
tracerDroppedGunButton.Text = "Tracer Dropped Gun"
dualKnifeEffectsButton.Text = "Dual Knife Effects"
optimizeCoinsButton.Text = "Optimize Coins"
disableBankScannerButton.Text = "Disable Bank Scanner"
gunSilentAimButton.Text = "Gun Silent Aim"
showRoundTimerButton.Text = "Show Round Timer"
teleportVoidButton.Text = "Teleport to Void"
teleportMapVoteButton.Text = "Teleport to Map Vote"
teleportLobbyButton.Text = "Teleport to Lobby"
teleportMurdererButton.Text = "Teleport to Murderer"
teleportSheriffButton.Text = "Teleport to Sheriff"
targetPlayerButton.Text = "Target Player"
knifeFakeButton.Text = "Fake Knife"
gunFakeButton.Text = "Fake Gun"
statusLabel.Text = "Status: Inactive"
toggleHubButton.Text = "Toggle Hub"

-- Biến để theo dõi trạng thái
local autoFarmActive = false
local farmMode = nil -- "Beachballs", "Coins", "Both"
local hubVisible = true -- Trạng thái hiển thị của hub
local twoLivesActive = false
local exposeRolesActive = false
local autoExposeRolesActive = false
local exposeMurdererPerkActive = false
local autoExposeMurdererPerkActive = false
local outlineEveryoneActive = false
local outlineDroppedGunActive = false
local tracerDroppedGunActive = false
local dualKnifeEffectsActive = false
local optimizeCoinsActive = false
local disableBankScannerActive = false
local gunSilentAimActive = false
local showRoundTimerActive = false
local knifeFakeActive = false
local gunFakeActive = false

-- Hàm để cập nhật trạng thái của nút
local function updateStatus()
    local status = "Status: Inactive"
    if autoFarmActive then
        if farmMode == "Beachballs" then
            status = "Status: Auto Farming Beachballs"
        elseif farmMode == "Coins" then
            status = "Status: Auto Farming Coins"
        elseif farmMode == "Both" then
            status = "Status: Auto Farming Coins & Beachballs"
        end
    elseif twoLivesActive then
        status = "Status: Two Lives Enabled"
    elseif exposeRolesActive then
        status = "Status: Expose Roles Enabled"
    elseif autoExposeRolesActive then
        status = "Status: Auto Expose Roles Enabled"
    elseif exposeMurdererPerkActive then
        status = "Status: Expose Murderer's Perk Enabled"
    elseif autoExposeMurdererPerkActive then
        status = "Status: Auto Expose Murderer's Perk Enabled"
    elseif outlineEveryoneActive then
        status = "Status: Outline Everyone Enabled"
    elseif outlineDroppedGunActive then
        status = "Status: Outline Dropped Gun Enabled"
    elseif tracerDroppedGunActive then
        status = "Status: Tracer Dropped Gun Enabled"
    elseif dualKnifeEffectsActive then
        status = "Status: Dual Knife Effects Enabled"
    elseif optimizeCoinsActive then
        status = "Status: Optimize Coins Enabled"
    elseif disableBankScannerActive then
        status = "Status: Disable Bank Scanner Enabled"
    elseif gunSilentAimActive then
        status = "Status: Gun Silent Aim Enabled"
    elseif showRoundTimerActive then
        status = "Status: Show Round Timer Enabled"
    elseif knifeFakeActive then
        status = "Status: Fake Knife Enabled"
    elseif gunFakeActive then
        status = "Status: Fake Gun Enabled"
    end
    statusLabel.Text = status
end

-- Hàm để hiển thị hoặc ẩn hub
local function toggleHub()
    hubVisible = not hubVisible
    hubFrame.Visible = hubVisible
end

-- Nút Đóng/Mở Hub
toggleHubButton.MouseButton1Click:Connect(function()
    toggleHub()
end)

-- Các nút chức năng
autoFarmButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    updateStatus()
    if autoFarmActive then
        startAutoFarm()
    else
        stopAutoFarm()
    end
end)

beachballsButton.MouseButton1Click:Connect(function()
    farmMode = "Beachballs"
    updateStatus()
end)

coinsButton.MouseButton1Click:Connect(function()
    farmMode = "Coins"
    updateStatus()
end)

bothButton.MouseButton1Click:Connect(function()
    farmMode = "Both"
    updateStatus()
end)

twoLivesButton.MouseButton1Click:Connect(function()
    twoLivesActive = not twoLivesActive
    updateStatus()
end)

exposeRolesButton.MouseButton1Click:Connect(function()
    exposeRolesActive = not exposeRolesActive
    updateStatus()
end)

autoExposeRolesButton.MouseButton1Click:Connect(function()
    autoExposeRolesActive = not autoExposeRolesActive
    updateStatus()
end)

exposeMurdererPerkButton.MouseButton1Click:Connect(function()
    exposeMurdererPerkActive = not exposeMurdererPerkActive
    updateStatus()
end)

autoExposeMurdererPerkButton.MouseButton1Click:Connect(function()
    autoExposeMurdererPerkActive = not autoExposeMurdererPerkActive
    updateStatus()
end)

outlineEveryoneButton.MouseButton1Click:Connect(function()
    outlineEveryoneActive = not outlineEveryoneActive
    updateStatus()
end)

outlineDroppedGunButton.MouseButton1Click:Connect(function()
    outlineDroppedGunActive = not outlineDroppedGunActive
    updateStatus()
end)

tracerDroppedGunButton.MouseButton1Click:Connect(function()
    tracerDroppedGunActive = not tracerDroppedGunActive
    updateStatus()
end)

dualKnifeEffectsButton.MouseButton1Click:Connect(function()
    dualKnifeEffectsActive = not dualKnifeEffectsActive
    updateStatus()
end)

optimizeCoinsButton.MouseButton1Click:Connect(function()
    optimizeCoinsActive = not optimizeCoinsActive
    updateStatus()
end)

disableBankScannerButton.MouseButton1Click:Connect(function()
    disableBankScannerActive = not disableBankScannerActive
    updateStatus()
end)

gunSilentAimButton.MouseButton1Click:Connect(function()
    gunSilentAimActive = not gunSilentAimActive
    updateStatus()
end)

showRoundTimerButton.MouseButton1Click:Connect(function()
    showRoundTimerActive = not showRoundTimerActive
    updateStatus()
end)

teleportVoidButton.MouseButton1Click:Connect(function()
    -- Thay đổi chỗ này với mã teleport đến Void
end)

teleportMapVoteButton.MouseButton1Click:Connect(function()
    -- Thay đổi chỗ này với mã teleport đến Map Vote
end)

teleportLobbyButton.MouseButton1Click:Connect(function()
    -- Thay đổi chỗ này với mã teleport đến Lobby
end)

teleportMurdererButton.MouseButton1Click:Connect(function()
    -- Thay đổi chỗ này với mã teleport đến Murderer
end)

teleportSheriffButton.MouseButton1Click:Connect(function()
    -- Thay đổi chỗ này với mã teleport đến Sheriff
end)

targetPlayerButton.MouseButton1Click:Connect(function()
    local targetPlayerName = playerNameInput.Text
    -- Thay đổi chỗ này với mã để target người chơi với tên targetPlayerName
end)

knifeFakeButton.MouseButton1Click:Connect(function()
    knifeFakeActive = not knifeFakeActive
    updateStatus()
    if knifeFakeActive then
        -- Thay đổi chỗ này với mã để kích hoạt knife giả
    else
        -- Thay đổi chỗ này với mã để hủy kích hoạt knife giả
    end
end)

gunFakeButton.MouseButton1Click:Connect(function()
    gunFakeActive = not gunFakeActive
    updateStatus()
    if gunFakeActive then
        -- Thay đổi chỗ này với mã để kích hoạt gun giả
    else
        -- Thay đổi chỗ này với mã để hủy kích hoạt gun giả
    end
end)
