local circleSize = 20 
local showCircle = true

local function isInsideCircle(position)
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if localCharacter then
        local localPosition = localCharacter:WaitForChild("HumanoidRootPart").Position
        local distance = (position - localPosition).Magnitude
        return distance <= circleSize
    end
    return false
end

local function getClosestPlayerInCircle()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter then
        return nil
    end

    local localPosition = localCharacter:WaitForChild("HumanoidRootPart").Position
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local position = player.Character.HumanoidRootPart.Position
            local distance = (position - localPosition).Magnitude

            if isInsideCircle(position) and distance < closestDistance and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    return closestPlayer
end

local function displayCoolNotification(player)
    local notification = Instance.new("ScreenGui")
    notification.Parent = game.Players.LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.2, 0, 0.1, 0)
    frame.Position = UDim2.new(0.01, 0, 0.01, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = notification

    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = player.Name.." is dead."
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Parent = frame

    wait(3)

    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    local endPosition = UDim2.new(-1, 0, 0.01, 0)
    local uiPadding = Instance.new("UIPadding")
    uiPadding.Parent = frame

    local tweenGoal = {}
    tweenGoal.Position = endPosition

    local tween = tweenService:Create(frame, tweenInfo, tweenGoal)
    tween:Play()

    wait(2)
    notification:Destroy()
end

while true do
    local closestPlayer = getClosestPlayerInCircle()
    if closestPlayer then
        displayCoolNotification(closestPlayer)
    end

    for _, v in pairs(game:GetService('Players').LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") then
            for _, child in pairs(v.Handle:GetChildren()) do
                if child:IsA("SelectionSphere") then
                    child:Destroy()
                end
            end

            if showCircle then
                local newCircle = Instance.new("SelectionSphere", v.Handle)
                newCircle.Adornee = v.Handle
                v.Handle.Massless = true
                v.Handle.Transparency = 0
                v.Handle.Size = Vector3.new(circleSize, circleSize, circleSize)
            end
        end
    end

    wait()
end

getgenv().ToggleCircleVisibility = function()
    showCircle = not showCircle
end
