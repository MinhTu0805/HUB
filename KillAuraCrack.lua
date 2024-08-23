-- Cấu hình ban đầu
getgenv().configs = {
    connections = {},
    Disable = Instance.new("BindableEvent"),
    Range = 15,
    DeathCheck = true,
    RandomizeDelay = true,
    MinDelay = 0.05,
    MaxDelay = 0.2,
    Executors = {"Fluxus", "Delta", "CubiX"}, -- Danh sách các executors tương thích
    Version = 1.0, -- Phiên bản hiện tại của script
}

-- Hàm kiểm tra môi trường executor
local function checkExecutor()
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    for _, exec in ipairs(getgenv().configs.Executors) do
        if exec == executor then
            print("Script hoạt động trên executor: " .. executor)
            return true
        end
    end
    warn("Executor không được hỗ trợ: " .. executor)
    return false
end

if not checkExecutor() then
    return
end

-- Thêm các phần của script như đã viết ở trên...
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Hàm thông báo mini
local function createNotification()
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local TextLabel = Instance.new("TextLabel")
    local CloseButton = Instance.new("TextButton")

    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = "MiniNotification"

    Frame.Size = UDim2.new(0, 200, 0, 100)
    Frame.Position = UDim2.new(0.5, -100, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.5
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    TextLabel.Size = UDim2.new(1, 0, 0.8, 0)
    TextLabel.Position = UDim2.new(0, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Text = "Script đã hoạt động!"
    TextLabel.Font = Enum.Font.SourceSans
    TextLabel.TextSize = 20
    TextLabel.Parent = Frame

    CloseButton.Size = UDim2.new(1, 0, 0.2, 0)
    CloseButton.Position = UDim2.new(0, 0, 0.8, 0)
    CloseButton.Text = "Đóng"
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.TextSize = 18
    CloseButton.Parent = Frame

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    delay(10, function() -- Tự động đóng thông báo sau 10 giây
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
end

-- Hiển thị thông báo khi script được thực thi
createNotification()

-- Hàm hỗ trợ lấy nhân vật và humanoid của người chơi
local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(humanoid)
    return humanoid and humanoid.Health > 0
end

-- Hàm tìm kiếm kẻ thù gần nhất
local function findClosestEnemy(range)
    local closestEnemy, closestDistance = nil, range
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = getCharacter(player)
            if character and isAlive(getHumanoid(character)) then
                local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestEnemy = character
                end
            end
        end
    end
    return closestEnemy
end

-- Hàm tấn công
local function attack(target)
    local tool = Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:IsDescendantOf(workspace) then
        tool:Activate()
        firetouchinterest(tool.Handle, target, 1)
        if getgenv().configs.RandomizeDelay then
            wait(math.random(getgenv().configs.MinDelay, getgenv().configs.MaxDelay))
        else
            wait(0.1)
        end
        firetouchinterest(tool.Handle, target, 0)
    end
end

-- Chức năng antiban nâng cao ByfronScript
local function ByfronScript()
    local initialPlaceId = game.PlaceId
    local run = true

    -- Kiểm tra lỗi dịch chuyển và dừng script
    Players.LocalPlayer.OnTeleport:Connect(function(status)
        if status == Enum.TeleportState.Failed then
            run = false
            warn("Teleport failed, possible detection.")
        end
    end)

    -- Giám sát kết nối mạng
    game:GetService("NetworkClient").ChildRemoved:Connect(function(child)
        if child:IsA("Player") and game.PlaceId == initialPlaceId then
            run = false
            warn("Network instability detected, stopping script.")
        end
    end)

    -- Theo dõi các thay đổi trong PlaceId
    game:GetService("Workspace").ChildAdded:Connect(function()
        if game.PlaceId ~= initialPlaceId then
            run = false
            warn("Detected place change, stopping script.")
        end
    end)

    return run
end

-- Khởi động chức năng Kill Aura
local function killAura()
    local run = ByfronScript()
    while run do
        local target = findClosestEnemy(getgenv().configs.Range)
        if target then
            attack(target)
        end
        RunService.Heartbeat:Wait()
    end
end

-- Khởi chạy script Kill Aura
spawn(killAura)

-- Khởi động tính năng tự học
local function autoImprove()
    -- Ví dụ: Điều chỉnh phạm vi tấn công dựa trên số lần thành công hoặc thất bại
    local successCount, failCount = 0, 0
    while true do
        RunService.Heartbeat:Wait()
        if successCount > 10 then
            getgenv().configs.Range = getgenv().configs.Range + 1
            successCount = 0
            print("Tăng phạm vi tấn công: ", getgenv().configs.Range)
        elseif failCount > 5 then
            getgenv().configs.Range = getgenv().configs.Range - 1
            failCount = 0
            print("Giảm phạm vi tấn công: ", getgenv().configs.Range)
        end
    end
end

-- Khởi chạy auto-improve để script tự học
spawn(autoImprove)

-- Kết nối sự kiện Disable
table.insert(getgenv().configs.connections, getgenv().configs.Disable.Event:Connect(function()
    run = false
end))
