-- Load thư viện UI Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Tạo cửa sổ Fluent
local Window = Fluent:CreateWindow({
    Title = "MintHub | MM2 Farm",
    SubTitle = "by Mint",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tạo các tab
local Tabs = {
    Main = Window:AddTab({ Title = "Main Options", Icon = "coins" }),
    Discord = Window:AddTab({ Title = "Discord Server", Icon = "link" })
}

local Options = Fluent.Options

-- Khởi tạo dịch vụ và biến
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid")
local teleportEnabled = false
local espEnabled = false
local avoidMurdererEnabled = false
local tweenSpeed = 16
local teleportDistanceThreshold = 50
local farmMode = "Default Farm"
local collectedCoins = 0
local executorSupportLevel = "Not Support"  -- Mặc định là Not Support
local roles, Murderer, Sheriff, Hero

-- Hàm đếm coin
local function collectCoin(coin)
    if coin and coin.Parent then
        collectedCoins = collectedCoins + 1
        coin:Destroy()
    end
end

-- Hàm tìm CoinContainer
local function findCoinContainer()
    for _, child in pairs(workspace:GetChildren()) do
        local coinContainer = child:FindFirstChild("CoinContainer")
        if coinContainer then
            return coinContainer
        end
    end
    return nil
end

-- Hàm kiểm tra trạng thái sống của player
local function isAlive(playerName)
    for i, v in pairs(roles) do
        if playerName == i then
            return not v.Killed and not v.Dead
        end
    end
    return false
end

-- Hàm kiểm tra khoảng cách đến Murderer
local function getMurdererDistance()
    if not Murderer or not Players:FindFirstChild(Murderer) then return math.huge end
    local murdererChar = Players[Murderer].Character
    if not murdererChar or not isAlive(Murderer) then return math.huge end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    return (hrp.Position - murdererChar.HumanoidRootPart.Position).Magnitude
end

-- Hàm né Murderer
local function avoidMurderer(coinPosition)
    if not Murderer or not Players:FindFirstChild(Murderer) or not avoidMurdererEnabled then return coinPosition end
    local murdererChar = Players[Murderer].Character
    if not murdererChar or not isAlive(Murderer) then return coinPosition end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return coinPosition end
    
    local murdererPos = murdererChar.HumanoidRootPart.Position
    local distanceToMurderer = (hrp.Position - murdererPos).Magnitude
    
    if distanceToMurderer < 30 then
        local direction = (hrp.Position - murdererPos).Unit
        return hrp.Position + (direction * 40)
    end
    return coinPosition
end

-- Hàm tìm coin gần nhất với tính năng né Murderer
local function findNearestCoin(maxRadius)
    local coinContainer = findCoinContainer()
    if not coinContainer then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearestCoin, nearestDistance = nil, maxRadius or math.huge
    for _, coin in pairs(coinContainer:GetChildren()) do
        if coin:IsA("BasePart") and coin:IsDescendantOf(workspace) then
            local adjustedPos = avoidMurderer(coin.Position)
            local dist = (adjustedPos - hrp.Position).Magnitude
            if dist < nearestDistance then
                nearestCoin = coin
                nearestDistance = dist
            end
        end
    end
    return nearestCoin, nearestDistance
end

-- Hàm teleport đến coin
local function teleportToCoin(coin)
    if not coin then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos = avoidMurderer(coin.Position)
    local targetCFrame = (farmMode == "Safe Farm (Beta)") 
        and CFrame.new(targetPos.X, targetPos.Y - 5, targetPos.Z)
        or CFrame.new(targetPos) + Vector3.new(0, 2.9, 0)
    
    local distance = (hrp.Position - targetPos).Magnitude
    if distance > 100 then
        humanoid.WalkSpeed = 100
        humanoid:MoveTo(targetPos)
        wait(distance / 100)
        humanoid.WalkSpeed = 16
    end
    hrp.CFrame = targetCFrame
    collectCoin(coin)
end

-- Hàm move bằng Tween đến coin
local function moveToCoin(coin)
    if not coin then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPosition = avoidMurderer((farmMode == "Safe Farm (Beta)") 
        and Vector3.new(coin.Position.X, coin.Position.Y - 5, coin.Position.Z)
        or coin.Position + Vector3.new(0, 2.9, 0))

    local distance = (targetPosition - hrp.Position).Magnitude
    local duration = distance / tweenSpeed

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    tween:Play()
    tween.Completed:Wait()
    collectCoin(coin)
end

-- Vòng lặp farm
local function farmCycle()
    if not teleportEnabled then return end
    
    -- Đảm bảo nhân vật và humanoid tồn tại
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or humanoid.Health <= 0 then return end

    local coin, distance = findNearestCoin(1e6)
    if not coin then return end

    if distance > teleportDistanceThreshold then
        teleportToCoin(coin)
    else
        moveToCoin(coin)
    end
end

-- ESP Functions
local function createHighlight()
    for _, v in pairs(Players:GetChildren()) do
        if v ~= player and v.Character and not v.Character:FindFirstChild("Highlight") then
            local highlight = Instance.new("Highlight", v.Character)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
        end
    end
end

local function updateHighlights()
    for _, v in pairs(Players:GetChildren()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Highlight") then
            local highlight = v.Character:FindFirstChild("Highlight")
            highlight.Enabled = espEnabled
            
            if not roles then return end
            
            if v.Name == Murderer and isAlive(v.Name) then
                highlight.FillColor = Color3.fromRGB(225, 0, 0)
            elseif v.Name == Sheriff and isAlive(v.Name) then
                highlight.FillColor = Color3.fromRGB(0, 0, 225)
            elseif v.Name == Hero and isAlive(v.Name) and not isAlive(Sheriff) then
                highlight.FillColor = Color3.fromRGB(255, 250, 0)
            else
                highlight.FillColor = Color3.fromRGB(0, 225, 0)
            end
        end
    end
end

-- Cập nhật roles
local function updateRoles()
    roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    for i, v in pairs(roles) do
        if v.Role == "Murderer" then Murderer = i
        elseif v.Role == "Sheriff" then Sheriff = i
        elseif v.Role == "Hero" then Hero = i
        end
    end
end

-- Kiểm tra mức độ hỗ trợ của executor với toàn bộ script
local function checkExecutorSupport()
    local executorName = identifyexecutor and identifyexecutor() or "Unknown Executor"
    local supportScore = 0
    
    -- Kiểm tra các hàm cơ bản cần thiết cho script
    if getrawmetatable and setreadonly then
        supportScore = supportScore + 1  -- Hỗ trợ cơ bản
    end
    
    -- Kiểm tra các hàm nâng cao cho Anti-Kick và Anti-Cheat
    if hookmetamethod and newcclosure and hookfunction then
        supportScore = supportScore + 1  -- Hỗ trợ nâng cao
    end
    
    -- Kiểm tra khả năng tương thích với TweenService và Instance.new (Teleport, ESP)
    if TweenService and Instance.new then
        supportScore = supportScore + 1
    end
    
    -- Kiểm tra khả năng chạy vòng lặp và spawn (cho farm loop)
    if spawn and wait then
        supportScore = supportScore + 1
    end

    -- Đặc biệt nhận diện Krnl
    if executorName == "Krnl" then
        -- Krnl hỗ trợ hầu hết các tính năng cần thiết
        supportScore = math.max(supportScore, 3)  -- Đảm bảo ít nhất là Normal Support
        if hookmetamethod then
            supportScore = 4  -- Nếu có hookmetamethod, nâng lên Best Support
        end
    end

    -- Phân loại mức hỗ trợ
    if supportScore >= 4 then
        executorSupportLevel = "Best Support"  -- Hỗ trợ đầy đủ mọi tính năng
    elseif supportScore >= 2 then
        executorSupportLevel = "Normal Support"  -- Hỗ trợ cơ bản, có thể thiếu một số tính năng nâng cao
    else
        executorSupportLevel = "Not Support"  -- Không hỗ trợ tốt, script có thể không chạy ổn định
    end
end

-- Gọi checkExecutorSupport trước khi tạo UI
checkExecutorSupport()

-- Tạo các thành phần UI với Fluent
do
    -- Thêm đoạn văn hiển thị thông tin executor
    local executorName = identifyexecutor and identifyexecutor() or "Unknown Executor"
    Tabs.Main:AddParagraph({
        Title = "Executor Information",
        Content = "Executor: " .. executorName .. "\nSupport Level: " .. executorSupportLevel
    })

    -- Textbox chỉnh tốc độ farm
    Tabs.Main:AddInput("Speed", {
        Title = "Speed (1 - 17)",
        Default = "16",
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                tweenSpeed = math.clamp(num, 1, 17)
            end
        end
    })

    -- Dropdown chọn chế độ farm
    Tabs.Main:AddDropdown("FarmMode", {
        Title = "Farm Mode",
        Values = {"Default Farm", "Safe Farm (Beta)"},
        Default = "Default Farm",
        Callback = function(selectedMode)
            farmMode = selectedMode
        end
    })

    -- Toggle Anti-AFK
    Tabs.Main:AddToggle("AntiAFK", {
        Title = "Anti-AFK",
        Default = false,
        Callback = function(value)
            if value then
                local vu = game:GetService("VirtualUser")
                player.Idled:Connect(function()
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    wait(1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end
            Fluent:Notify({
                Title = "Anti-AFK",
                Content = value and "Anti-AFK enabled." or "Anti-AFK disabled.",
                Duration = 3
            })
        end
    })

    -- Toggle ESP
    Tabs.Main:AddToggle("ESP", {
        Title = "ESP Highlights",
        Default = false,
        Callback = function(value)
            espEnabled = value
            Fluent:Notify({
                Title = "ESP Highlights",
                Content = value and "ESP enabled." or "ESP disabled.",
                Duration = 3
            })
        end
    })

    -- Toggle Avoid Murderer
    Tabs.Main:AddToggle("AvoidMurderer", {
        Title = "Avoid Murderer",
        Default = false,
        Callback = function(value)
            avoidMurdererEnabled = value
            Fluent:Notify({
                Title = "Avoid Murderer",
                Content = value and "Avoid Murderer enabled." or "Avoid Murderer disabled.",
                Duration = 3
            })
        end
    })

    -- Toggle Coin Farm
    Tabs.Main:AddToggle("CoinFarm", {
        Title = "Coin Farm",
        Default = false,
        Callback = function(value)
            teleportEnabled = value
            
            if executorSupportLevel == "Best Support" and getgenv().ED_AntiKick then
                getgenv().ED_AntiKick.Enabled = value
            elseif executorSupportLevel == "Normal Support" and getgenv().ED_BasicAntiKick then
                getgenv().ED_BasicAntiKick.Enabled = value
            end
            getgenv().ED_AntiCheatBypass.Enabled = value

            if value then
                Fluent:Notify({
                    Title = "Script Status",
                    Content = executorSupportLevel == "Best Support" and "Running with full features." or 
                             executorSupportLevel == "Normal Support" and "Running with basic features." or 
                             "Running with limited features.",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Script Status",
                    Content = "Script stopped.",
                    Duration = 3
                })
            end
        end
    })

    -- Button kiểm tra số coin
    Tabs.Main:AddButton({
        Title = "Check Coins Collected [Beta]",
        Callback = function()
            Fluent:Notify({
                Title = "Coin Tracker",
                Content = "Collected: " .. collectedCoins .. " coins.",
                Duration = 3
            })
        end
    })

    -- Button Discord
    Tabs.Discord:AddButton({
        Title = "Join Discord",
        Callback = function()
            local discordLink = "https://discord.gg/y8ZDZuFm5F"
            setclipboard(discordLink)
            Fluent:Notify({
                Title = "Discord",
                Content = "Link copied to clipboard!",
                Duration = 3
            })
        end
    })
end

-- Anti-Kick nâng cao (Best Support)
local function setupAdvancedAntiKick()
    if getgenv().ED_AntiKick then return end

    getgenv().ED_AntiKick = {
        Enabled = false,
        SendNotifications = true,
        CheckCaller = true
    }

    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local self, message = ...
        local method = getnamecallmethod()

        if getgenv().ED_AntiKick.Enabled and method == "Kick" and not checkcaller() then
            if getgenv().ED_AntiKick.SendNotifications then
                Fluent:Notify({
                    Title = "Anti-Kick",
                    Content = "Kick attempt blocked (Best Support).",
                    Duration = 2
                })
            end
            return
        end
        return OldNamecall(...)
    end))

    local OldFunction
    OldFunction = hookfunction(player.Kick, function(...)
        if getgenv().ED_AntiKick.Enabled then
            if getgenv().ED_AntiKick.SendNotifications then
                Fluent:Notify({
                    Title = "Anti-Kick",
                    Content = "Kick attempt blocked (Best Support).",
                    Duration = 2
                })
            end
            return
        end
    end)
end

-- Anti-Kick cơ bản (Normal Support)
local function setupBasicAntiKick()
    if getgenv().ED_BasicAntiKick then return end

    getgenv().ED_BasicAntiKick = {
        Enabled = false
    }

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if getgenv().ED_BasicAntiKick.Enabled and method == "Kick" then
            Fluent:Notify({
                Title = "Anti-Kick",
                Content = "Kick attempt blocked (Normal Support).",
                Duration = 2
            })
            return nil
        end
        return oldNamecall(self, ...)
    end

    setreadonly(mt, true)
end

-- Bypass Anti-Cheat cơ bản
local function setupAntiCheatBypass()
    if getgenv().ED_AntiCheatBypass then return end

    getgenv().ED_AntiCheatBypass = {
        Enabled = false
    }

    local oldIndex
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    oldIndex = mt.__index
    mt.__index = newcclosure(function(self, key)
        if getgenv().ED_AntiCheatBypass.Enabled and tostring(self) == "NetworkClient" and key == "ReplicationFocus" then
            return player.Character
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)

    spawn(function()
        while wait(0.5) do
            if getgenv().ED_AntiCheatBypass.Enabled and character and humanoid then
                humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed, 0, 16)
            end
        end
    end)
end

-- Khởi tạo Anti-Kick và Anti-Cheat Bypass
if executorSupportLevel == "Best Support" then
    setupAdvancedAntiKick()
elseif executorSupportLevel == "Normal Support" then
    setupBasicAntiKick()
end
setupAntiCheatBypass()

-- Xử lý respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid")
    wait(1)
end)

-- Khi nhân vật chết
if humanoid then
    humanoid.Died:Connect(function()
        wait(1)
    end)
end

-- Main loops
spawn(function()
    while true do
        if teleportEnabled then
            local success, err = pcall(farmCycle)
            if not success then
                warn("Farm cycle error: " .. err) -- In lỗi ra để debug
            end
        end
        wait(0.05) -- Giảm thời gian chờ để farm nhanh hơn
    end
end)

spawn(function()
    while true do
        pcall(function()
            updateRoles()
            createHighlight()
            updateHighlights()
        end)
        wait(0.1)
    end
end)

-- Chọn tab mặc định
Window:SelectTab(1)

-- Thông báo khi script chạy
Fluent:Notify({
    Title = "MintHub",
    Content = "Script loaded successfully.\nSupport Level: " .. executorSupportLevel,
    Duration = 5
})