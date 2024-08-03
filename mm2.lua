-- Bắt đầu script
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Tạo ScreenGui
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "CrazyGameEditorHackGui"
screenGui.ResetOnSpawn = false

-- Tạo Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 400, 0, 600)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Điều chỉnh vị trí để hub nằm ở giữa
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Đặt anchor point để hub nằm chính giữa
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true

-- Bo tròn các góc
local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- Thêm hiệu ứng mở/đóng hub
local openCloseButton = Instance.new("ImageButton", screenGui)
openCloseButton.Size = UDim2.new(0, 30, 0, 30)
openCloseButton.Position = UDim2.new(0, 10, 0, 10)
openCloseButton.Image = "rbxassetid://6031097225" -- ID của icon mặt trăng
openCloseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openCloseButton.BorderSizePixel = 0

local uiCornerButton = Instance.new("UICorner", openCloseButton)
uiCornerButton.CornerRadius = UDim.new(0, 10)

openCloseButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Làm cho nút đóng/mở có thể di chuyển
local isDragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    openCloseButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

openCloseButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = openCloseButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

openCloseButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        update(input)
    end
end)

-- Tạo tiêu đề
local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Text = "CrazyGameEditorHack"
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BorderSizePixel = 0

-- Thêm nút chức năng
local function createButton(parent, size, position, text)
    local button = Instance.new("TextButton", parent)
    button.Size = size
    button.Position = position
    button.Text = text
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    local uiCornerButton = Instance.new("UICorner", button)
    uiCornerButton.CornerRadius = UDim.new(0, 10)
    return button
end

local function createToggleButton(parent, size, position, text, toggleFunc)
    local button = createButton(parent, size, position, text)
    local isOn = false
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        button.BackgroundColor3 = isOn and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        toggleFunc(isOn)
    end)
    return button
end

-- Thêm ô nhập để nhập tên người chơi
local targetPlayerInput = Instance.new("TextBox", mainFrame)
targetPlayerInput.Size = UDim2.new(0, 200, 0, 50)
targetPlayerInput.Position = UDim2.new(0, 100, 0, 200)
targetPlayerInput.PlaceholderText = "Nhập tên người chơi"
targetPlayerInput.Text = ""
targetPlayerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
targetPlayerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
targetPlayerInput.BorderSizePixel = 0
local uiCornerInput = Instance.new("UICorner", targetPlayerInput)
uiCornerInput.CornerRadius = UDim.new(0, 10)

-- Thêm nút teleport
local teleportButton = createButton(mainFrame, UDim2.new(0, 200, 0, 50), UDim2.new(0, 100, 0, 300), "Teleport")

teleportButton.MouseButton1Click:Connect(function()
    local targetPlayerName = targetPlayerInput.Text
    local targetPlayer = game.Players:FindFirstChild(targetPlayerName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        game.Players.LocalPlayer.Character:MoveTo(targetPlayer.Character.HumanoidRootPart.Position)
    else
        warn("Player not found or not valid")
    end
end)

-- Chức năng ESP
local function espPlayer(player, color)
    local character = player.Character
    if character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local highlight = Instance.new("BoxHandleAdornment", part)
                highlight.Adornee = part
                highlight.Size = part.Size
                highlight.AlwaysOnTop = true
                highlight.ZIndex = 10
                highlight.Color3 = color
                highlight.Transparency = 0.5
            end
        end
    end
end

local function toggleESP(isOn)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if isOn then
                if player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
                    espPlayer(player, Color3.fromRGB(255, 0, 0)) -- Murderer (Red)
                elseif player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun") then
                    espPlayer(player, Color3.fromRGB(0, 0, 255)) -- Sheriff (Blue)
                elseif player.Backpack:FindFirstChild("Hero") or player.Character:FindFirstChild("Hero") then
                    espPlayer(player, Color3.fromRGB(255, 255, 0)) -- Hero (Yellow)
                else
                    espPlayer(player, Color3.fromRGB(0, 255, 0)) -- Innocents (Green)
                end
            else
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        for _, adornment in pairs(part:GetChildren()) do
                            if adornment:IsA("BoxHandleAdornment") then
                                adornment:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end
end

local espEnabled = false

local espButton = createToggleButton(mainFrame, UDim2.new(0, 200, 0, 50), UDim2.new(0, 100, 0, 400), "ESP", function(isOn)
    espEnabled = isOn
    toggleESP(isOn)
end)

-- Chức năng Silent Aim
local silentAimEnabled = false

local function toggleSilentAim(isOn)
    silentAimEnabled = isOn
end

local silentAimButton = createToggleButton(mainFrame, UDim2.new(0, 200, 0, 50), UDim2.new(0, 100, 0, 500), "Silent Aim", toggleSilentAim)

game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and silentAimEnabled then
        local target = nil
        for _, player in pairs(game.Players:GetPlayers
