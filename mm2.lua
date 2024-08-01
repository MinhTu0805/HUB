local VIP_USERNAMES = {
    ["YourUsername"] = true, -- Thêm nhiều tên người dùng VIP nếu cần
}

-- Hàm phụ để kiểm tra xem người chơi có phải là VIP không
local function isVIP(player)
    return VIP_USERNAMES[player.Name] == true
end

-- Hàm phụ để lấy người chơi là kẻ sát nhân
local function getMurderer()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player:FindFirstChild("IsMurderer") and player.IsMurderer.Value then
            return player
        end
    end
    return nil
end

-- Chế độ bất tử
local function toggleGodMode(enabled)
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if enabled then
                humanoid.MaxHealth = math.huge
                humanoid.Health = humanoid.MaxHealth
                humanoid.Died:Connect(function()
                    humanoid.Health = humanoid.MaxHealth
                    player:LoadCharacter()
                end)
                character.HumanoidRootPart.Anchored = true
            else
                humanoid.MaxHealth = 100
                humanoid.Health = 100
                character.HumanoidRootPart.Anchored = false
            end
        end
    end
end

-- ESP
local function toggleESP(enabled)
    if isVIP(game.Players.LocalPlayer) then
        -- Triển khai chức năng ESP ở đây
        -- Sử dụng tham số 'enabled' để bật/tắt
    end
end

-- Hỗ trợ ngắm
local aimAssistConnection

local function aimAssist(enabled)
    local player = game.Players.LocalPlayer
    if isVIP(player) then
        if enabled then
            local murderer = getMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
                local murdererHead = murderer.Character.Head
                aimAssistConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position, murdererHead.Position)
                    end
                end)
            end
        elseif aimAssistConnection then
            aimAssistConnection:Disconnect()
            aimAssistConnection = nil
        end
    end
end

-- Dịch chuyển
local function teleportTo(playerName, position)
    local player = game.Players:FindFirstChild(playerName)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

-- Tích hợp GUI mẫu
local function setupGUI()
    local player = game.Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui", player.PlayerGui)
    
    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 200, 0, 300)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.3

    local uiCorner = Instance.new("UICorner", frame)
    uiCorner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Bảng điều khiển"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.BorderSizePixel = 0
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24

    local godModeButton = Instance.new("TextButton", frame)
    godModeButton.Size = UDim2.new(1, 0, 0, 50)
    godModeButton.Position = UDim2.new(0, 0, 0, 60)
    godModeButton.Text = "Bật/Tắt chế độ bất tử"
    godModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    godModeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    godModeButton.BorderSizePixel = 0
    godModeButton.Font = Enum.Font.SourceSansBold
    godModeButton.TextSize = 18
    local godModeEnabled = false
    godModeButton.MouseButton1Click:Connect(function()
        godModeEnabled = not godModeEnabled
        toggleGodMode(godModeEnabled)
        godModeButton.Text = godModeEnabled and "Tắt chế độ bất tử" or "Bật chế độ bất tử"
    end)

    local espButton = Instance.new("TextButton", frame)
    espButton.Size = UDim2.new(1, 0, 0, 50)
    espButton.Position = UDim2.new(0, 0, 0, 120)
    espButton.Text = "Bật/Tắt ESP"
    espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    espButton.BorderSizePixel = 0
    espButton.Font = Enum.Font.SourceSansBold
    espButton.TextSize = 18
    local espEnabled = false
    espButton.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        toggleESP(espEnabled)
        espButton.Text = espEnabled and "Tắt ESP" or "Bật ESP"
    end)

    local aimAssistButton = Instance.new("TextButton", frame)
    aimAssistButton.Size = UDim2.new(1, 0, 0, 50)
    aimAssistButton.Position = UDim2.new(0, 0, 0, 180)
    aimAssistButton.Text = "Bật/Tắt hỗ trợ ngắm"
    aimAssistButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimAssistButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    aimAssistButton.BorderSizePixel = 0
    aimAssistButton.Font = Enum.Font.SourceSansBold
    aimAssistButton.TextSize = 18
    local aimAssistEnabled = false
    aimAssistButton.MouseButton1Click:Connect(function()
        aimAssistEnabled = not aimAssistEnabled
        aimAssist(aimAssistEnabled)
        aimAssistButton.Text = aimAssistEnabled and "Tắt hỗ trợ ngắm" or "Bật hỗ trợ ngắm"
    end)

    local teleportButton = Instance.new("TextButton", frame)
    teleportButton.Size = UDim2.new(1, 0, 0, 50)
    teleportButton.Position = UDim2.new(0, 0, 0, 240)
    teleportButton.Text = "Dịch chuyển"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    teleportButton.BorderSizePixel = 0
    teleportButton.Font = Enum.Font.SourceSansBold
    teleportButton.TextSize = 18
    teleportButton.MouseButton1Click:Connect(function()
        local playerName = "TênNgườiChơi" -- Thay bằng tên người chơi thực tế hoặc đầu vào
        local position = Vector3.new(0, 0, 0) -- Thay bằng vị trí thực tế
        teleportTo(playerName, position)
    end)
end

setupGUI()
