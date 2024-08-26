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
    Size = Vector3.new(200, 200, 200),  -- Tăng phạm vi kill aura để chém xa hơn và giết tất cả người chơi
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

-- God Mode tối đa và Auto-Heal
local function EnableMaxGodMode()
    local humanoid = gethumanoid(lp)
    if humanoid then
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        humanoid.Health = humanoid.MaxHealth
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end

-- Xử lý các lệnh Method bất thường
local function advancedAntiBan()
    local OldNameCall
    OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
        local Method = getnamecallmethod()
        local args = {...}
        
        -- Ngăn chặn các lệnh "Kick" hoặc các phương thức khác
        if Method == "Kick" or string.find(Method, "Ban") or string.find(Method, "kick") then
            return nil
        end
        
        -- Xử lý các lệnh Method bất thường
        if Method == "FireServer" and self.Name == "RemoteEventName" then
            return nil
        end
        
        return OldNameCall(self, unpack(args))
    end)
end

advancedAntiBan()
EnableMaxGodMode()

table.insert(getgenv().configs.connections, Disable.Event:Connect(function()
    Run = false
end))

-- Thông báo GUI khi script được thực thi với hiệu ứng nâng cao
local function createAdvancedNotification(version)
    local PlayerGui = lp:WaitForChild("PlayerGui")

    -- Tạo màn hình GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdvancedNotificationGui"
    screenGui.Parent = PlayerGui

    -- Tạo khung chứa thông báo
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(0.05, 0, 0.95, -50)  -- Vị trí ở góc trái dưới màn hình
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui

    -- Tạo góc bo tròn cho khung
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Hiệu ứng xuất hiện nâng cao
    frame:TweenSizeAndPosition(UDim2.new(0, 250, 0, 100), UDim2.new(0.05, 0, 0.95, -50), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.6, true)

    -- Tạo thông báo text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0.6, -10)
    textLabel.Position = UDim2.new(0, 10, 0, 5)
    textLabel.Text = "🚀 Kill Aura Crack | By Tú TM 🚀"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBlack
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.Parent = frame

    -- Thêm nhãn hiển thị phiên bản script
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -20, 0.3, -5)
    versionLabel.Position = UDim2.new(0, 10, 0.6, 0)
    versionLabel.Text = "Phiên bản: " .. version
    versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 14
    versionLabel.TextWrapped = true
    versionLabel.Parent = frame

    -- Tự động tắt thông báo sau 10 giây với hiệu ứng nâng cao
    delay(10, function()
        frame:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(0.05, 0, 0.95, -50), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.5, true, function()
            screenGui:Destroy()
        end)
    end)
end

-- Gọi hàm để hiển thị thông báo version script
createAdvancedNotification("v13.78 (Premium)")

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

                if table.find(Characters, Character) then
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
