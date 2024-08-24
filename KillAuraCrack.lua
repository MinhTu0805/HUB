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
    Size = Vector3.new(30, 30, 30),  -- Tăng phạm vi kill aura
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

local function GetEnemiesInRange(center, size)
    local enemies = {}
    local parts = workspace:FindPartsInRegion3(Region3.new(center - size/2, center + size/2), nil, math.huge)
    for _, part in ipairs(parts) do
        local character = part:FindFirstAncestorWhichIsA("Model")
        if character and character:FindFirstChildWhichIsA("Humanoid") then
            table.insert(enemies, character)
        end
    end
    return enemies
end

local function Attack(Tool, TouchPart, ToTouch)
    if Tool:IsDescendantOf(workspace) then
        Tool:Activate()
        wait(0.1) -- Thêm một chút thời gian để đảm bảo hành động được thực hiện
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

-- Quy trình kiểm tra trước khi chạy script
local function preCheck()
    local success, errorMessage = pcall(function()
        -- Kiểm tra hệ thống Kill Aura
        local testTool = Instance.new("Tool")
        testTool.Parent = lp.Backpack
        local testPart = Instance.new("Part", workspace)
        testPart.Size = Vector3.new(5, 5, 5)
        testPart.CFrame = CFrame.new(0, 10, 0)
        
        -- Kiểm tra TouchTransmitter
        local touchInterest = Instance.new("TouchTransmitter", testPart)
        local touchPart = testPart:FindFirstChildOfClass("TouchTransmitter")
        if not touchPart then
            error("TouchTransmitter not found. Ensure that the tool and touch part setup is correct.")
        end
        
        -- Kiểm tra các phần tử cần thiết khác
        if not lp.Character or not lp.Character:FindFirstChildWhichIsA("Humanoid") then
            error("Player's character or Humanoid is missing.")
        end

        -- Dọn dẹp các đối tượng thử nghiệm
        testPart:Destroy()
        testTool:Destroy()
    end)
    
    if not success then
        warn("Pre-check failed: " .. errorMessage)
        return false
    end
    return true
end

-- Gọi hàm kiểm tra trước khi chạy script
if preCheck() then
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
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0.3
        frame.Parent = screenGui

        -- Tạo góc bo tròn cho khung
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 20)
        corner.Parent = frame

        -- Hiệu ứng xuất hiện
        frame:TweenSizeAndPosition(UDim2.new(0, 400, 0, 200), UDim2.new(0.5, -200, 0.5, -100), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.7, true)

        -- Tạo hiệu ứng gradient cho khung
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 100, 255)})
        gradient.Rotation = 45
        gradient.Parent = frame

        -- Tạo thông báo text
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -40, 0.7, -30)
        textLabel.Position = UDim2.new(0, 20, 0, 20)
        textLabel.Text = "🚀 Advanced Script v13.43 is now running! 🚀"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 22
        textLabel.TextWrapped = true
        textLabel.Parent = frame

        -- Thêm nhãn hiển thị phiên bản script
        local versionLabel = Instance.new("TextLabel")
        versionLabel.Size = UDim2.new(1, -40, 0.2, -10)
        versionLabel.Position = UDim2.new(0, 20, 0.75, 0)
        versionLabel.Text = "Version: 13.43"
        versionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        versionLabel.BackgroundTransparency = 1
        versionLabel.Font = Enum.Font.Gotham
        versionLabel.TextSize = 18
        versionLabel.TextWrapped = true
        versionLabel.Parent = frame

        -- Tạo nút đóng thông báo với nút "X"
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 35, 0, 35)
        closeButton.Position = UDim2.new(1, -45, 0, 10)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 20
        closeButton.AutoButtonColor = false
        closeButton.Parent = frame

        -- Tạo góc bo tròn cho nút
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = closeButton

        -- Thêm sự kiện để đóng thông báo
        closeButton.MouseButton1Click:Connect(function()
            frame:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.7, true, function()
                screenGui:Destroy()
            end)
        end)

        -- Tự động tắt thông báo sau 10 giây với hiệu ứng
        delay(10, function()
            frame:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.7, true, function()
                screenGui:Destroy()
            end)
        end)
    end

    -- Gọi hàm tạo thông báo
    createNotification()

    -- Vòng lặp chính của script
    local lastUpdateTime = tick()
    local updateInterval = 0.1 -- Cập nhật mỗi 0.1 giây

    while Run do
        local currentTime = tick()
        if currentTime - lastUpdateTime >= updateInterval then
            lastUpdateTime = currentTime
            
            local char = getchar()
            if IsAlive(gethumanoid(char)) then
                local Tool = char and char:FindFirstChildWhichIsA("Tool")
                local TouchInterest = Tool and GetTouchInterest(Tool)

                if TouchInterest then
                    local TouchPart = TouchInterest.Parent
                    local enemies = GetEnemiesInRange(TouchPart.Position, getgenv().configs.Size)

                    for _, enemy in ipairs(enemies) do
                        if getgenv().configs.DeathCheck then
                            if IsAlive(gethumanoid(enemy)) then
                                Attack(Tool, TouchPart, enemy)
                            end
                        else
                            Attack(Tool, TouchPart, enemy)
                        end
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
else
    warn("Script cannot run due to pre-check failure.")
end
