-- Tạo tham chiếu đến các phần tử GUI
local screenGui = script.Parent
local mainFrame = screenGui:WaitForChild("MainFrame")
local tabsFrame = mainFrame:WaitForChild("TabsFrame")
local aimShootFrame = mainFrame:WaitForChild("AimShootFrame")
local espFrame = mainFrame:WaitForChild("ESPFrame")
local teleportFrame = mainFrame:WaitForChild("TeleportFrame")
local flingFrame = mainFrame:WaitForChild("FlingFrame")
local emoteFrame = mainFrame:WaitForChild("EmoteFrame")
local doubleGunFrame = mainFrame:WaitForChild("DoubleGunFrame")
local doubleKnifeFrame = mainFrame:WaitForChild("DoubleKnifeFrame")

-- Các nút điều khiển tab
local aimShootButton = tabsFrame:WaitForChild("AimShootButton")
local espButton = tabsFrame:WaitForChild("ESPButton")
local teleportButton = tabsFrame:WaitForChild("TeleportButton")
local flingButton = tabsFrame:WaitForChild("FlingButton")
local emoteButton = tabsFrame:WaitForChild("EmoteButton")
local doubleGunButton = tabsFrame:WaitForChild("DoubleGunButton")
local doubleKnifeButton = tabsFrame:WaitForChild("DoubleKnifeButton")

-- Hàm để hiển thị frame tương ứng
local function showFrame(frameToShow)
    aimShootFrame.Visible = (frameToShow == aimShootFrame)
    espFrame.Visible = (frameToShow == espFrame)
    teleportFrame.Visible = (frameToShow == teleportFrame)
    flingFrame.Visible = (frameToShow == flingFrame)
    emoteFrame.Visible = (frameToShow == emoteFrame)
    doubleGunFrame.Visible = (frameToShow == doubleGunFrame)
    doubleKnifeFrame.Visible = (frameToShow == doubleKnifeFrame)
end

-- Chuyển tab
aimShootButton.MouseButton1Click:Connect(function() showFrame(aimShootFrame) end)
espButton.MouseButton1Click:Connect(function() showFrame(espFrame) end)
teleportButton.MouseButton1Click:Connect(function() showFrame(teleportFrame) end)
flingButton.MouseButton1Click:Connect(function() showFrame(flingFrame) end)
emoteButton.MouseButton1Click:Connect(function() showFrame(emoteFrame) end)
doubleGunButton.MouseButton1Click:Connect(function() showFrame(doubleGunFrame) end)
doubleKnifeButton.MouseButton1Click:Connect(function() showFrame(doubleKnifeFrame) end)

-- Mặc định hiển thị tab đầu tiên
showFrame(aimShootFrame)

-- Aim Shoot Functionality
local aimShootButton = aimShootFrame:WaitForChild("AimShootButton")
aimShootButton.MouseButton1Click:Connect(function()
    print("Aim Shoot Activated")
end)

-- ESP Functionality
local players = game:GetService("Players")

local function updateESP()
    for _, player in ipairs(players:GetPlayers()) do
        if player == players.LocalPlayer then continue end
        local character = player.Character
        if character then
            local espTag = character:FindFirstChild("ESPTag")
            if not espTag then
                espTag = Instance.new("BillboardGui")
                espTag.Name = "ESPTag"
                espTag.Size = UDim2.new(0, 200, 0, 50)
                espTag.Adornee = character:FindFirstChild("Head")
                espTag.Parent = character
            end
            local color = Color3.new(1, 1, 1)
            if player.Team and player.Team.Name == "Murderer" then
                color = Color3.fromRGB(255, 0, 0)
            elseif player.Team and player.Team.Name == "Innocents" then
                color = Color3.fromRGB(0, 255, 0)
            elseif player.Team and player.Team.Name == "Sheriff" then
                color = Color3.fromRGB(0, 0, 255)
            end
            espTag.TextLabel.TextColor3 = color
        end
    end
end

players.PlayerAdded:Connect(updateESP)
players.PlayerRemoving:Connect(updateESP)

-- Teleport Player Functionality
local teleportButton = teleportFrame:WaitForChild("TeleportButton")
local playerNameBox = teleportFrame:WaitForChild("PlayerNameBox")

teleportButton.MouseButton1Click:Connect(function()
    local playerName = playerNameBox.Text
    local playerToTeleport = players:FindFirstChild(playerName)
    if playerToTeleport and playerToTeleport.Character then
        playerToTeleport.Character:SetPrimaryPartCFrame(players.LocalPlayer.Character.HumanoidRootPart.CFrame)
    end
end)

-- Fling Player Functionality
local flingButton = flingFrame:WaitForChild("FlingButton")
local playerNameBoxFling = flingFrame:WaitForChild("PlayerNameBox")

flingButton.MouseButton1Click:Connect(function()
    local playerName = playerNameBoxFling.Text
    local playerToFling = players:FindFirstChild(playerName)
    if playerToFling and playerToFling.Character then
        local character = playerToFling.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 100, 0)
            bodyVelocity.Parent = character.PrimaryPart
            game:GetService("Debris"):AddItem(bodyVelocity, 1)
        end
    end
end)

-- Emote MM2 Functionality
local emoteButton = emoteFrame:WaitForChild("EmoteButton")

emoteButton.MouseButton1Click:Connect(function()
    local character = game.Players.LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local emote = Instance.new("Animation")
            emote.AnimationId = "rbxassetid://YOUR_EMOTE_ANIMATION_ID"
            local animTrack = humanoid:LoadAnimation(emote)
            animTrack:Play()
        end
    end
end)

-- Double Gun Functionality
local doubleGunButton = doubleGunFrame:WaitForChild("DoubleGunButton")

doubleGunButton.MouseButton1Click:Connect(function()
    local character = game.Players.LocalPlayer.Character
    if character then
        print("Double Gun Activated")
        -- Implement double gun logic here
    end
end)

-- Double Knife Functionality
local doubleKnifeButton = doubleKnifeFrame:WaitForChild("DoubleKnifeButton")

doubleKnifeButton.MouseButton1Click:Connect(function()
    local character = game.Players.LocalPlayer.Character
    if character then
        print("Double Knife Activated")
        -- Implement double knife logic here
    end
end)
