--[[
      __  __               _             __  __           _                    ____  
     |  \/  |_   _ _ __ __| | ___ _ __  |  \/  |_   _ ___| |_ ___ _ __ _   _  |___ \ 
     | |\/| | | | | '__/ _` |/ _ \ '__| | |\/| | | | / __| __/ _ \ '__| | | |   __) |
     | |  | | |_| | | | (_| |  __/ |    | |  | | |_| \__ \ ||  __/ |  | |_| |  / __/ 
     |_|  |_|\__,_|_|  \__,_|\___|_|    |_|  |_|\__, |___/\__\___|_|   \__, | |_____|
                                                |___/                  |___/         
]]--
-- LocalScript đặt trong MM2HubGui

-- Xác định các đối tượng cần thiết
local screenGui = script.Parent
local mainFrame = screenGui:WaitForChild("Frame")

-- Nút và các thành phần giao diện
local mdgButton = screenGui:WaitForChild("MDGButton")
local mainButton = mainFrame:WaitForChild("MainButton")
local visualsButton = mainFrame:WaitForChild("VisualsButton")
local emotesButton = mainFrame:WaitForChild("EmotesButton")
local economyButton = mainFrame:WaitForChild("EconomyButton")
local premiumButton = mainFrame:WaitForChild("PremiumButton")

local userInfoFrame = mainFrame:WaitForChild("UserInfoFrame")
local fpsLabel = userInfoFrame:WaitForChild("FPSLabel")
local pingLabel = userInfoFrame:WaitForChild("PingLabel")

-- Tạo hoặc cập nhật TextLabel cho tiêu đề
local titleLabel = mainFrame:FindFirstChild("TitleLabel")
if not titleLabel then
    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = mainFrame
end

-- Cài đặt thuộc tính cho TextLabel
titleLabel.Text = "MderTerDer G [v0.1] - Murder Mystery 2"
titleLabel.Size = UDim2.new(0, 400, 0, 50)
titleLabel.Position = UDim2.new(0.5, -200, 0, 0)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.BackgroundTransparency = 1

-- Biến theo dõi trạng thái mở/đóng của hub
local hubVisible = true

-- Hàm để đóng/mở hub
local function toggleHub()
    hubVisible = not hubVisible
    mainFrame.Visible = hubVisible
end

-- Kết nối sự kiện nhấn nút với hàm đóng/mở
mdgButton.MouseButton1Click:Connect(toggleHub)

-- Hàm xử lý khi nhấn nút "Main"
local function onMainButtonClick()
    userInfoFrame.Visible = true
    -- Ẩn các phần khác nếu cần
end

-- Hàm xử lý khi nhấn nút "Visuals"
local function onVisualsButtonClick()
    userInfoFrame.Visible = false
    -- Hiển thị các phần khác nếu cần
end

-- Hàm xử lý khi nhấn nút "Emotes"
local function onEmotesButtonClick()
    userInfoFrame.Visible = false
    -- Hiển thị các phần khác nếu cần
end

-- Hàm xử lý khi nhấn nút "Economy"
local function onEconomyButtonClick()
    userInfoFrame.Visible = false
    -- Hiển thị các phần khác nếu cần
end

-- Hàm xử lý khi nhấn nút "Premium"
local function onPremiumButtonClick()
    userInfoFrame.Visible = false
    -- Hiển thị các phần khác nếu cần
end

-- Kết nối các nút với các hàm tương ứng
mainButton.MouseButton1Click:Connect(onMainButtonClick)
visualsButton.MouseButton1Click:Connect(onVisualsButtonClick)
emotesButton.MouseButton1Click:Connect(onEmotesButtonClick)
economyButton.MouseButton1Click:Connect(onEconomyButtonClick)
premiumButton.MouseButton1Click:Connect(onPremiumButtonClick)

-- Hàm để cập nhật FPS và Ping
local function updateFPSAndPing()
    local fps, ping
    
    -- Cập nhật FPS
    local success, result = pcall(function()
        fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
    end)
    
    if not success then
        fps = "N/A"
    end

    -- Cập nhật Ping
    success, result = pcall(function()
        ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    
    if not success then
        ping = "N/A"
    end
    
    fpsLabel.Text = "FPS: " .. tostring(fps)
    pingLabel.Text = "Ping: " .. tostring(ping) .. " ms"
end

-- Liên tục cập nhật FPS và Ping
game:GetService("RunService").RenderStepped:Connect(updateFPSAndPing)

-- Hàm để làm mới UI hoặc xử lý sự kiện
local function refreshUI()
    -- Ví dụ: Cập nhật thông tin người dùng hoặc các thông tin khác trên UI
end

-- Thêm chức năng thêm cho các nút
local function setupAdditionalFeatures()
    -- Thêm các tính năng khác vào đây
end

-- Cập nhật và xử lý thông tin người dùng
local function updateUserInfo()
    -- Thêm mã để lấy và hiển thị thông tin người dùng
end

-- Hàm để xử lý các sự kiện từ server
local function handleServerEvents()
    -- Thêm mã để xử lý các sự kiện từ server
end

-- Thêm giao diện người dùng cho các tính năng bổ sung
local function setupAdditionalUI()
    local additionalFrame = Instance.new("Frame")
    additionalFrame.Name = "AdditionalFrame"
    additionalFrame.Size = UDim2.new(1, 0, 1, 0)
    additionalFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    additionalFrame.BackgroundTransparency = 0.5
    additionalFrame.Parent = mainFrame

    local additionalLabel = Instance.new("TextLabel")
    additionalLabel.Name = "AdditionalLabel"
    additionalLabel.Size = UDim2.new(1, 0, 0, 50)
    additionalLabel.Position = UDim2.new(0, 0, 0, 0)
    additionalLabel.Text = "Additional Features"
    additionalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    additionalLabel.TextScaled = true
    additionalLabel.Font = Enum.Font.SourceSansBold
    additionalLabel.BackgroundTransparency = 1
    additionalLabel.Parent = additionalFrame

    -- Thêm các nút và thành phần khác vào additionalFrame
end

-- Tạo các thành phần giao diện người dùng bổ sung
setupAdditionalUI()

-- Hàm để làm mới các phần tử giao diện
local function refreshUIElements()
    -- Làm mới các phần tử giao diện nếu cần
end

-- Cập nhật thông tin người dùng
updateUserInfo()

-- Xử lý sự kiện từ server
handleServerEvents()

-- Hàm bổ sung để làm việc với các thành phần UI
local function handleUIComponents()
    -- Thực hiện các thao tác với các thành phần UI
end

-- Thực hiện các thao tác bổ sung trên UI
handleUIComponents()

-- Thêm các chức năng khác vào đây nếu cần
local function additionalFunctionality()
    -- Ví dụ: Thực hiện các tác vụ bổ sung
end

-- Kết nối các sự kiện bổ sung nếu cần
local function setupEventConnections()
    -- Thêm mã để kết nối các sự kiện bổ sung
end

-- Thực hiện thiết lập kết nối sự kiện bổ sung
setupEventConnections()

-- Thực hiện các chức năng bổ sung
additionalFunctionality()

-- Hàm để cập nhật thông tin về người chơi
local function updatePlayerStats()
    local player = game.Players.LocalPlayer
    local leaderstats = player:FindFirstChild("leaderstats")
    
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            local statLabel = userInfoFrame:FindFirstChild(stat.Name .. "Label")
            if not statLabel then
                statLabel = Instance.new("TextLabel")
                statLabel.Name = stat.Name .. "Label"
                statLabel.Size = UDim2.new(0, 200, 0, 50)
                statLabel.Position = UDim2.new(0, 0, 0, 50 * _)
                statLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                statLabel.TextScaled = true
                statLabel.Font = Enum.Font.SourceSans
                statLabel.BackgroundTransparency = 1
                statLabel.Parent = userInfoFrame
            end
            statLabel.Text = stat.Name .. ": " .. stat.Value
        end
    end
end

-- Hàm để khởi tạo thông tin người chơi
local function initPlayerInfo()
    updatePlayerStats()
    
    game.Players.LocalPlayer:WaitForChild("leaderstats").ChildAdded:Connect(function()
        updatePlayerStats()
    end)
    
    game.Players.LocalPlayer:WaitForChild("leaderstats").ChildRemoved:Connect(function()
        updatePlayerStats()
    end)
end

-- Khởi tạo thông tin người chơi
initPlayerInfo()

-- Hàm để thêm các nút chức năng bổ sung vào giao diện
local function addAdditionalButtons()
    local buttons = {
        {Name = "TeleportButton", Text = "Teleport", Position = UDim2.new(0.1, 0, 0.8, 0)},
        {Name = "GodModeButton", Text = "God Mode", Position = UDim2.new(0.3, 0, 0.8, 0)},
        {Name = "FlyButton", Text = "Fly", Position = UDim2.new(0.5, 0, 0.8, 0)},
        {Name = "SpeedButton", Text = "Speed", Position = UDim2.new(0.7, 0, 0.8, 0)},
    }

    for _, buttonInfo in pairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonInfo.Name
        button.Text = buttonInfo.Text
        button.Size = UDim2.new(0, 100, 0, 50)
        button.Position = buttonInfo.Position
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        button.Parent = mainFrame
    end
end

-- Thêm các nút chức năng bổ sung
addAdditionalButtons()

-- Hàm để quản lý các nút chức năng bổ sung
local function manageAdditionalButtons()
    local teleportButton = mainFrame:FindFirstChild("TeleportButton")
    local godModeButton = mainFrame:FindFirstChild("GodModeButton")
    local flyButton = mainFrame:FindFirstChild("FlyButton")
    local speedButton = mainFrame:FindFirstChild("SpeedButton")

    -- Định nghĩa chức năng cho nút Teleport
    teleportButton.MouseButton1Click:Connect(function()
        local player = game.Players.LocalPlayer
        player.Character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 100, 0)))
    end)

    -- Định nghĩa chức năng cho nút God Mode
    godModeButton.MouseButton1Click:Connect(function()
        local player = game.Players.LocalPlayer
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end)

    -- Định nghĩa chức năng cho nút Fly
    flyButton.MouseButton1Click:Connect(function()
        local player = game.Players.LocalPlayer
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end)

    -- Định nghĩa chức năng cho nút Speed
    speedButton.MouseButton1Click:Connect(function()
        local player = game.Players.LocalPlayer
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 100
        end
    end)
end

-- Quản lý các nút chức năng bổ sung
manageAdditionalButtons()

-- Hàm để thực hiện các tác vụ khác trên GUI
local function otherTasksOnGUI()
    -- Thực hiện các tác vụ khác nếu cần
end

-- Thực hiện các tác vụ khác
otherTasksOnGUI()

-- Hàm để khởi động các tính năng mới
local function launchNewFeatures()
    -- Khởi động các tính năng mới nếu cần
end

-- Khởi động các tính năng mới
launchNewFeatures()

-- Kết thúc script
