--//Notfitication \--
game:GetService("StarterGui"):SetCore("SendNotification",{
Title = "Script Executed",
Text = "thanks for using this script",
Icon = "rbxassetid://79958200710618",

Button1 = "Ok",
Button2 = "Cancel",
Duration = 2
})

--// Library Setup \--
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Kill Aura | MintHub | Premuim V1.5.7 (+ FIX AND UPDATE)",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "Powered by MintXX",
    Theme = "Serenity", -- Bạn có thể thay đổi giao diện tại đây
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KillAuraConfig",
        FileName = "KillAura"
    },
    Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = " y8ZDZuFm5F", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = false -- Set this to false to make them join the discord every time they load it up
   },
    KeySystem = true, -- Bật hệ thống key
    KeySettings = {
        Title = "Kill Aura Key System",
        Subtitle = "Enter your key to access",
        Note = "Join My Discord Server to get Key!",
        FileName = "MintHub Key",
        SaveKey = true,
        GrabKeyFromSite = false, -- Nếu bạn có URL key, bật thành true
        Key = {"MintPremuim947YxO053" , "MintPremuim73Om89479" , "MintPremuim362nmO035" ,} -- Danh sách các key hợp lệ
    }
})

-- Tạo Tabs
local mainTab = Window:CreateTab("Main", 7733749837) -- Tab chính với icon
local settingsTab = Window:CreateTab("Settings", 7734053495) -- Tab cài đặt
local extraTab = Window:CreateTab("Extra", 7743866529) -- Tab Extra đã được bật

--// Variables \--
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local killAuraEnabled = false
local facePlayerEnabled = false 
local lastAttackTime = 0
local targets = {}
local antiAFKEnabled = false
local range = math.huge
local attackInterval = 0.1
local maxTargets = 100
local swordHitboxEnabled = false
local hitboxColor = Color3.fromRGB(255, 0, 0) -- Mặc định màu đỏ
local rainbowHitbox = false
local hitboxParts = {}

-- Tấn công mục tiêu
local function attack(target)
    local character = player.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not (tool and tool:FindFirstChild("Handle")) then return end

    -- Kích hoạt công cụ
    tool:Activate()

    -- Gửi tín hiệu sát thương
    for _, part in ipairs(target:GetChildren()) do
        if part:IsA("BasePart") then
            firetouchinterest(tool.Handle, part, 0)
            firetouchinterest(tool.Handle, part, 1)
        end
    end
end

-- Cập nhật danh sách mục tiêu
local function updateTargets()
    local players = game:GetService("Players"):GetPlayers()
    targets = {}

    for _, otherPlayer in ipairs(players) do
        if otherPlayer ~= player then
            local character = otherPlayer.Character
            if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart and (player:DistanceFromCharacter(humanoidRootPart.Position) <= range) then
                    table.insert(targets, character)
                end
            end
        end
    end
end

-- Main Kill Aura Logic
local function killAura()
    runService.RenderStepped:Connect(function()
        if killAuraEnabled then
            local currentTime = tick()

            if currentTime - lastAttackTime >= attackInterval then
                updateTargets()

                for i = 1, math.min(#targets, maxTargets) do
                    attack(targets[i])
                end

                lastAttackTime = currentTime
            end
        end
    end)
end

-- Anti-AFK Function
local function preventAFK()
    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        if antiAFKEnabled then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end

-- Anti-Kick Script
local function setupAntiKick()
    if getgenv().ED_AntiKick then return end -- Đã chạy Anti-Kick, không cần cài lại.

    getgenv().ED_AntiKick = {
        Enabled = true,
        SendNotifications = true,
        CheckCaller = true
    }

    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local self, message = ...
        local method = getnamecallmethod()

        if getgenv().ED_AntiKick.Enabled and method == "Kick" and not checkcaller() then
            if getgenv().ED_AntiKick.SendNotifications then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Anti-Kick",
                    Text = "Intercepted attempted kick!",
                    Icon = "rbxassetid://79958200710618",
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
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Anti-Kick",
                    Text = "Intercepted attempted kick!",
                    Icon = "rbxassetid://79958200710618",
                    Duration = 2
                })
            end
            return
        end
    end)
end

-- Chức năng Face Players
local function facePlayers()
    local function updateFace()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        local LOCK_RANGE = 20
        local ROTATION_SPEED = 0.15 

        local function getNearestPlayer()
            local nearestPlayer = nil
            local shortestDistance = LOCK_RANGE

            for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if otherHRP then
                        local distance = (humanoidRootPart.Position - otherHRP.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestPlayer = otherPlayer
                        end
                    end
                end
            end

            return nearestPlayer
        end

        runService.RenderStepped:Connect(function(deltaTime)
            if facePlayerEnabled then
                local target = getNearestPlayer()
                if target and target.Character then
                    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        local rootPosition = humanoidRootPart.Position
                        local targetPosition = targetHRP.Position
                        local lookAtCFrame = CFrame.new(rootPosition, Vector3.new(targetPosition.X, rootPosition.Y, targetPosition.Z))
                        humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(lookAtCFrame, ROTATION_SPEED * deltaTime * 60)
                    end
                end
            end
        end)
    end

    -- Chạy liên tục, lắng nghe sự kiện respawn
    player.CharacterAdded:Connect(updateFace)
    
    -- Gọi hàm ngay khi lần đầu tiên
    updateFace()
end

-- Hàm cập nhật hitbox
local function updateHitbox()
    -- Xóa hitbox cũ trước khi tạo hitbox mới
    for _, part in pairs(hitboxParts) do
        if part then
            part:Destroy()
        end
    end
    hitboxParts = {}

    if not swordHitboxEnabled then return end

    local character = player.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild("Handle") then return end

    local handle = tool:FindFirstChild("Handle")

    -- Tạo một phần tử hitbox trong suốt
    local hitbox = Instance.new("Part")
    hitbox.Size = handle.Size + Vector3.new(0.5, 0.5, 0.5) -- Hitbox lớn hơn vật phẩm
    hitbox.Transparency = 0.5
    hitbox.Anchored = false
    hitbox.CanCollide = false
    hitbox.Color = hitboxColor
    hitbox.Material = Enum.Material.Neon
    hitbox.Parent = handle

    -- Gắn hitbox vào tay cầm
    local weld = Instance.new("Weld")
    weld.Part0 = handle
    weld.Part1 = hitbox
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = hitbox

    table.insert(hitboxParts, hitbox)
end

-- Hàm thay đổi màu hitbox theo rainbow
local function rainbowEffect()
    while rainbowHitbox do
        for hue = 0, 1, 0.01 do
            hitboxColor = Color3.fromHSV(hue, 1, 1)
            updateHitbox()
            task.wait(0.1)
        end
    end
end

-- Gọi các chức năng
preventAFK()
setupAntiKick()

-- GUI Elements

-- Main Tab
mainTab:CreateToggle({
    Name = "Kill Aura⚔️",
    CurrentValue = false,
    Callback = function(value)
        killAuraEnabled = value
        if value then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Kill Aura",
                Text = "Enabled!",
                Icon = "rbxassetid://79958200710618",
                Duration = 2
            })
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Kill Aura",
                Text = "Disabled!",
                Icon = "rbxassetid://79958200710618",
                Duration = 2
            })
        end
    end
})

-- Settings Tab
settingsTab:CreateInput({
    Name = "Range",
    PlaceholderText = tostring(range),
    RemoveTextAfterFocusLost = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            range = numValue
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Error",
                Text = "Invalid Range Value!",
                Icon = "rbxassetid://79958200710618",
                Duration = 1
            })
        end
    end
})

settingsTab:CreateInput({
    Name = "Attack Interval (Seconds)",
    PlaceholderText = tostring(attackInterval),
    RemoveTextAfterFocusLost = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue > 0 then
            attackInterval = numValue
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Error",
                Text = "Invalid Interval Value!",
                Icon = "rbxassetid://79958200710618",
                Duration = 1
            })
        end
    end
})

settingsTab:CreateInput({
    Name = "Max Targets",
    PlaceholderText = tostring(maxTargets),
    RemoveTextAfterFocusLost = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue > 0 then
            maxTargets = numValue
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Error",
                Text = "Invalid Max Targets Value!",
                Icon = "rbxassetid://79958200710618",
                Duration = 1
            })
        end
    end
})

-- Extra Tab
extraTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(value)
        antiAFKEnabled = value
        local status = value and "Enabled!" or "Disabled!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})

extraTab:CreateToggle({
    Name = "Anti-Kick",
    CurrentValue = true,
    Callback = function(value)
        getgenv().ED_AntiKick.Enabled = value
        local status = value and "Enabled!" or "Disabled!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Anti-Kick",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})

-- Thêm Toggle cho Face Players vào Extra Tab
extraTab:CreateToggle({
    Name = "Sword Aim",
    CurrentValue = false,
    Callback = function(value)
        facePlayerEnabled = value
        local status = value and "Enabled!" or "Disabled!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Sword Aim",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})

extraTab:CreateToggle({
    Name = "Sword Hitbox",
    CurrentValue = false,
    Callback = function(value)
        swordHitboxEnabled = value
        updateHitbox()

        local status = value and "Enabled!" or "Disabled!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Sword Hitbox",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})


extraTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = hitboxColor,
    Callback = function(value)
        hitboxColor = value
        updateHitbox()

        local status = "Hitbox color updated!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Hitbox Color",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})

extraTab:CreateToggle({
    Name = "Rainbow Hitbox",
    CurrentValue = false,
    Callback = function(value)
        rainbowHitbox = value
        if value then
            task.spawn(rainbowEffect)
        else
            updateHitbox()
        end

        local status = value and "Enabled!" or "Disabled!"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Rainbow Hitbox",
            Text = status,
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })
    end
})

-- Kiểm tra nếu game ID là 16696943761
if game.PlaceId == 16696943761 then
    extraTab:CreateButton({
        Name = "Fast Teleport",
        Callback = function()
            -- Gửi thông báo khi nút được nhấn
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Fast Teleport",
                Text = "Executing Fast Teleport script...",
                Icon = "rbxassetid://79958200710618",
                Duration = 2
            })
            -- Chạy script Fast Teleport
            loadstring(game:HttpGet("https://github.com/MinhTu0805/HUB/raw/refs/heads/main/FastTeleport.com"))("Only-place-16696943761")
        end
    })
end

-- Button for FPS Boost (Minimal Graphics Impact, Error Handled)
extraTab:CreateButton({
    Name = "Fps Boost (Beta)",
    Callback = function()
        -- Gửi thông báo khi nút được nhấn
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "FPS Boost",
            Text = "Applying FPS boost and latency optimizations...",
            Icon = "rbxassetid://79958200710618",
            Duration = 2
        })

        -- Biến để theo dõi lỗi
        local success, errorMessage

        -- FPS Boost: Optimize performance with minimal graphics impact
        local RunService = game:GetService("RunService")
        local NetworkSettings = game:GetService("NetworkSettings")
        local Lighting = game:GetService("Lighting")

        -- Attempt to set FPS cap to 120
        success, errorMessage = pcall(function()
            local UserGameSettings = UserSettings():GetService("UserGameSettings")
            UserGameSettings.MaxFps = 120 -- Set FPS cap to 120
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FPS Boost Warning",
                Text = "Failed to set FPS cap: " .. tostring(errorMessage),
                Icon = "rbxassetid://79958200710618",
                Duration = 3
            })
        end

        -- Disable minor post-processing effects (minimal visual impact)
        success, errorMessage = pcall(function()
            Lighting.EnvironmentDiffuseScale = 0.5 -- Reduce environment lighting load slightly
            Lighting.EnvironmentSpecularScale = 0.5 -- Reduce specular highlights slightly
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FPS Boost Warning",
                Text = "Failed to adjust lighting: " .. tostring(errorMessage),
                Icon = "rbxassetid://79958200710618",
                Duration = 3
            })
        end

        -- Optimize rendering (safe settings)
        success, errorMessage = pcall(function()
            settings().Rendering.EnableFRM = false -- Disable Frame Rate Manager
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FPS Boost Warning",
                Text = "Failed to adjust rendering: " .. tostring(errorMessage),
                Icon = "rbxassetid://79958200710618",
                Duration = 3
            })
        end

        -- Latency optimization: Minimize network overhead
        success, errorMessage = pcall(function()
            NetworkSettings.IncomingReplicationLag = 0 -- Avoid artificial network lag
            RunService:Set3dRenderingEnabled(true) -- Ensure optimized 3D rendering
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FPS Boost Warning",
                Text = "Failed to adjust network settings: " .. tostring(errorMessage),
                Icon = "rbxassetid://79958200710618",
                Duration = 3
            })
        end

        -- Optimize physics simulation
        success, errorMessage = pcall(function()
            settings().Physics.EnvironmentalPhysicsThrottle = Enum.EnvironmentalPhysicsThrottle.Disabled -- Fixed typo
            settings().Physics.AllowSleep = true -- Allow physics objects to sleep
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FPS Boost Warning",
                Text = "Failed to adjust physics: " .. tostring(errorMessage),
                Icon = "rbxassetid://79958200710618",
                Duration = 3
            })
        end

        -- Gửi thông báo hoàn tất
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "FPS Boost",
            Text = "Optimizations applied! FPS targeted at 120, latency minimized.",
            Icon = "rbxassetid://79958200710618",
            Duration = 3
        })
    end
})

extraTab:CreateButton({
    Name = "Chat Bypass Filter",
    Callback = function()
        -- Gửi thông báo khi script được thực thi
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Bypass...",
            Text = "Chat filter is bypassing ",
            Icon = "rbxassetid://79958200710618",
            Duration = 5
        })
        wait(5)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Bypassed",
            Text = "Chat filter is bypassed ",
            Icon = "rbxassetid://79958200710618",
            Button1 = "Ok",
            Button2 = "Cancel",
            Duration = 2
        })

        -- Chạy script Bypass Filter
        loadstring(game:HttpGet("https://gist.githubusercontent.com/lexsplorsex/b4b3b1243329327faec92f6953d4ed02/raw/a144202fc87db6493a109bf91a7cd14445e012ec/gistfile1.txt"))()
    end
})

killAura()
facePlayers()

-- Load Configuration
Rayfield:LoadConfiguration()