print("Script is in Beta mode")

-- Phần 1: Thiết lập GUI cơ bản
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrazyGameEditorHack"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 500, 0, 600)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.5
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.Parent = MainFrame
UICorner.CornerRadius = UDim.new(0, 12)

-- Thêm nút đóng/mở hub
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.Text = "Open/Close Hub"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Phần 2: Tạo các nút chức năng
local function createButton(parent, name, position, size, text)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Parent = parent
    Button.Size = size
    Button.Position = position
    Button.Text = text
    Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.BorderSizePixel = 0
    local UICornerButton = Instance.new("UICorner")
    UICornerButton.Parent = Button
    UICornerButton.CornerRadius = UDim.new(0, 6)
    return Button
end

local KnifeFakeButton = createButton(MainFrame, "KnifeFakeButton", UDim2.new(0, 20, 0, 20), UDim2.new(0, 220, 0, 50), "Knife Fake (On/Off)")
local GunFakeButton = createButton(MainFrame, "GunFakeButton", UDim2.new(0, 260, 0, 20), UDim2.new(0, 220, 0, 50), "Gun Fake (On/Off)")
local TeleportVoidButton = createButton(MainFrame, "TeleportVoidButton", UDim2.new(0, 20, 0, 90), UDim2.new(0, 220, 0, 50), "Teleport to Void")
local TeleportMapVoteButton = createButton(MainFrame, "TeleportMapVoteButton", UDim2.new(0, 260, 0, 90), UDim2.new(0, 220, 0, 50), "Teleport to Map Vote")
local TeleportLobbyButton = createButton(MainFrame, "TeleportLobbyButton", UDim2.new(0, 20, 0, 160), UDim2.new(0, 220, 0, 50), "Teleport to Lobby")
local TeleportMurdererButton = createButton(MainFrame, "TeleportMurdererButton", UDim2.new(0, 260, 0, 160), UDim2.new(0, 220, 0, 50), "Teleport to Murderer")
local TeleportSheriffButton = createButton(MainFrame, "TeleportSheriffButton", UDim2.new(0, 20, 0, 230), UDim2.new(0, 220, 0, 50), "Teleport to Sheriff")
local TargetPlayerButton = createButton(MainFrame, "TargetPlayerButton", UDim2.new(0, 260, 0, 230), UDim2.new(0, 220, 0, 50), "Target Player")
local PlayerNameInput = Instance.new("TextBox")
PlayerNameInput.Parent = MainFrame
PlayerNameInput.Size = UDim2.new(0, 460, 0, 30)
PlayerNameInput.Position = UDim2.new(0, 20, 0, 300)
PlayerNameInput.PlaceholderText = "Enter Player's Username"
PlayerNameInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
PlayerNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerNameInput.BorderSizePixel = 0
local UICornerInput = Instance.new("UICorner")
UICornerInput.Parent = PlayerNameInput
UICornerInput.CornerRadius = UDim.new(0, 6)

-- Phần 3: Thêm chức năng cho các nút
local function fakeKnife(on)
    if on then
        -- Mã để bật Knife giả
    else
        -- Mã để tắt Knife giả
    end
end

KnifeFakeButton.MouseButton1Click:Connect(function()
    fakeKnife(not KnifeFakeOn)
    KnifeFakeOn = not KnifeFakeOn
end)

GunFakeButton.MouseButton1Click:Connect(function()
    -- Thêm mã để bật/tắt Gun giả
end)

TeleportVoidButton.MouseButton1Click:Connect(function()
    -- Thêm mã để teleport đến Void
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1000, -1000, 1000)
end)

TeleportMapVoteButton.MouseButton1Click:Connect(function()
    -- Thêm mã để teleport đến Map Vote
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(200, 200, 200)
end)

TeleportLobbyButton.MouseButton1Click:Connect(function()
    -- Thêm mã để teleport đến Lobby
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 0, 0)
end)

TeleportMurdererButton.MouseButton1Click:Connect(function()
    -- Thêm mã để teleport đến Murderer
    local murderer = nil
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player:FindFirstChild("Role") and player.Role.Value == "Murderer" then
            murderer = player
            break
        end
    end
    if murderer then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame
    end
end)

TeleportSheriffButton.MouseButton1Click:Connect(function()
    -- Thêm mã để teleport đến Sheriff
    local sheriff = nil
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player:FindFirstChild("Role") and player.Role.Value == "Sheriff" then
            sheriff = player
            break
        end
    end
    if sheriff then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame
    end
end)

TargetPlayerButton.MouseButton1Click:Connect(function()
    local targetPlayerName = PlayerNameInput.Text
    local targetPlayer = game.Players:FindFirstChild(targetPlayerName)
    if targetPlayer then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end)

-- Phần 4: Thêm chức năng nâng cao và hiệu ứng
local function createEffect(parent)
    local Effect = Instance.new("ParticleEmitter")
    Effect.Parent = parent
    Effect.Texture = "rbxassetid://241594419" -- Hiệu ứng galaxy
    Effect.Rate = 10
    Effect.Lifetime = NumberRange.new(1, 2)
    Effect.Speed = NumberRange.new(1, 2)
    Effect.RotSpeed = NumberRange.new(100, 200)
    Effect.SpreadAngle = Vector2.new(360, 360)
    Effect.Acceleration = Vector3.new(0, 5, 0)
    return Effect
end

local function applyEffectToButtons(buttons)
    for _, button in ipairs(buttons) do
        createEffect(button)
    end
end

applyEffectToButtons({KnifeFakeButton, GunFakeButton, TeleportVoidButton, TeleportMapVoteButton, TeleportLobbyButton, TeleportMurdererButton, TeleportSheriffButton, TargetPlayerButton})

-- Thêm chức năng nâng cao
local function teleportToRandomPlayer()
    local players = game.Players:GetPlayers()
    if #players > 1 then
        local randomPlayer
        repeat
            randomPlayer = players[math.random(#players)]
        until randomPlayer ~= LocalPlayer
        LocalPlayer.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
    end
end

local RandomTeleportButton = createButton(MainFrame, "RandomTeleportButton", UDim2.new(0, 20, 0, 370), UDim2.new(0, 460, 0, 50), "Random Teleport")
RandomTeleportButton.MouseButton1Click:Connect(teleportToRandomPlayer)

-- Phần 5: Kiểm tra và tối ưu hóa script cho các executor
local function isExecutorSupported()
    local executors = {"Synapse X", "Krnl", "Sentinel", "Fluxus", "Oxygen U", "Delta", "CubiX", "Solara", "Arceus X"}
    for _, executor in ipairs(executors) do
        if identifyexecutor and identifyexecutor() == executor then
            return true
        end
    end
    return false
end

if isExecutorSupported() then
    print("Executor is supported!")
else
    warn("Executor is not supported! Some functions may not work correctly.")
end

print("CrazyGameEditorHack script loaded successfully!")

-- Lưu ý: Đảm bảo script này được cập nhật thường xuyên để hoạt động tốt trên tất cả các executor.
