-- Khởi tạo biến và dịch vụ cần thiết
local connections = getgenv().configs and getgenv().configs.connection
if connections then
    local Disable = configs.Disable
    for i, v in pairs(connections) do
        v:Disconnect() 
    end
    Disable:Fire()
    Disable:Destroy()
    table.clear(configs)
end

local Disable = Instance.new("BindableEvent")
getgenv().configs = {
    connections = {},
    Disable = Disable,
    Size = Vector3.new(14, 14, 14),  -- Tăng phạm vi kill aura
    DeathCheck = true
}

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local lp = Players.LocalPlayer
local Run = true
local Ignorelist = OverlapParams.new()
Ignorelist.FilterType = Enum.RaycastFilterType.Include

local function getchar(plr)
    local plr = plr or lp
    return plr.Character
end

local function gethumanoid(plr)
    local char = plr:IsA("Model") and plr or getchar(plr)
    if char then
        return char:FindFirstChildWhichIsA("Humanoid")
    end
end

local function IsAlive(Humanoid)
    return Humanoid and Humanoid.Health > 0
end

local function GetTouchInterest(Tool)
    return Tool and Tool:FindFirstChildWhichIsA("TouchTransmitter", true)
end

local function GetCharacters(LocalPlayerChar)
    local Characters = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lp then
            table.insert(Characters, getchar(v))
        end
    end
    return Characters
end

local function Attack(Tool, TouchPart, ToTouch)
    if Tool:IsDescendantOf(workspace) then
        Tool:Activate()
        firetouchinterest(TouchPart, ToTouch, 1)
        firetouchinterest(TouchPart, ToTouch, 0)
    end
end

local function EnableGodMode()
    local humanoid = gethumanoid(lp)
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
end

-- Anti-Kick và Anti-AFK
local vu = game:GetService("VirtualUser")
lp.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

-- AntiBan Nâng cao
local function advancedAntiBan()
    local OldNameCall
    OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
        local Method = getnamecallmethod()
        if Method == "Kick" or Method == "ban" then
            return nil
        end
        return OldNameCall(self, ...)
    end)
end

advancedAntiBan()
EnableGodMode()

table.insert(getgenv().configs.connections, Disable.Event:Connect(function()
    Run = false
end))

-- Thông báo GUI khi script được thực thi với hiệu ứng
local function createNotification()
    local PlayerGui = lp:WaitForChild("PlayerGui")

    -- Tạo màn hình GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationGui"
    screenGui.Parent = PlayerGui

    -- Tạo khung chứa thông báo
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.15
    frame.Parent = screenGui

    -- Tạo góc bo tròn cho khung
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Hiệu ứng xuất hiện
    frame:TweenSizeAndPosition(UDim2.new(0, 350, 0, 150), UDim2.new(0.5, -175, 0.5, -75), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)

    -- Tạo thông báo text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 0.6, -20)
    textLabel.Position = UDim2.new(0, 20, 0, 10)
    textLabel.Text = "✨ Advanced Script is now running! ✨"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.Parent = frame

    -- Thêm nhãn hiển thị phiên bản script
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -40, 0.2, -10)
    versionLabel.Position = UDim2.new(0, 20, 0.7, 0)
    versionLabel.Text = "Version: 3.4.0"
    versionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 14
    versionLabel.TextWrapped = true
    versionLabel.Parent = frame

    -- Tạo nút đóng thông báo với nút "X"
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.AutoButtonColor = false
    closeButton.Parent = frame

    -- Tạo góc bo tròn cho nút
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = closeButton

    -- Thêm sự kiện để đóng thông báo
    closeButton.MouseButton1Click:Connect(function()
        frame:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
            screenGui:Destroy()
        end)
    end)

    -- Tự động tắt thông báo sau 10 giây với hiệu ứng
    delay(10, function()
        frame:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
            screenGui:Destroy()
        end)
    end)
end

-- Gọi hàm tạo thông báo
createNotification()

-- Vòng lặp chính của script
while Run do
    local char = getchar()
    if IsAlive(gethumanoid(char)) then
        local Tool = char and char:FindFirstChildWhichIsA("Tool")
        local TouchInterest = Tool and GetTouchInterest(Tool)

        if TouchInterest then
            local TouchPart = TouchInterest.Parent
            local Characters = GetCharacters(char)
            Ignorelist.FilterDescendantsInstances = Characters
            local InstancesInBox = workspace:GetPartBoundsInBox(TouchPart.CFrame, TouchPart.Size + getgenv().configs.Size, Ignorelist)

            for _, v in ipairs(InstancesInBox) do
                local Character = v:FindFirstAncestorWhichIsA("Model")

                if Character and table.find(Characters, Character) then
                    if getgenv().configs.DeathCheck then                    
                        if IsAlive(gethumanoid(Character)) then
                            Attack(Tool, TouchPart, v)
                        end
                    else
                        Attack(Tool, TouchPart, v)
                    end
                end
            end
        end
    end
    RunService.Heartbeat:Wait()
end
