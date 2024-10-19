local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local roles

function CreateHighlight() -- make any new highlights for new players
	for i, v in pairs(Players:GetChildren()) do
		if v ~= LP and v.Character and not v.Character:FindFirstChild("Highlight") then
			Instance.new("Highlight", v.Character)           
		end
	end
end

function UpdateHighlights() -- Get Current Role Colors (messy)
	for _, v in pairs(Players:GetChildren()) do
		if v ~= LP and v.Character and v.Character:FindFirstChild("Highlight") then
			Highlight = v.Character:FindFirstChild("Highlight")
			if v.Name == Sheriff and IsAlive(v) then
				Highlight.FillColor = Color3.fromRGB(0, 0, 225)
			elseif v.Name == Murder and IsAlive(v) then
				Highlight.FillColor = Color3.fromRGB(225, 0, 0)
			elseif v.Name == Hero and IsAlive(v) and not IsAlive(game.Players[Sheriff]) then
				Highlight.FillColor = Color3.fromRGB(255, 250, 0)
			else
				Highlight.FillColor = Color3.fromRGB(0, 225, 0)
			end
		end
	end
end	

function IsAlive(Player) -- Simple sexy function
	for i, v in pairs(roles) do
		if Player.Name == i then
			if not v.Killed and not v.Dead then
				return true
			else
				return false
			end
		end
	end
end

RunService.RenderStepped:connect(function()
	roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
	for i, v in pairs(roles) do
		if v.Role == "Murderer" then
			Murder = i
		elseif v.Role == 'Sheriff'then

-->Old Script Hightlight<--
--[[-- Bắt đầu script
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Màu sắc cho ESP
local murdererColor = Color3.fromRGB(255, 0, 0) -- Màu đỏ cho Murderer
local sheriffColor = Color3.fromRGB(0, 0, 255) -- Màu xanh dương cho Sheriff
local innocentColor = Color3.fromRGB(0, 255, 0) -- Màu xanh lá cho Innocents
local gunDroppedColor = Color3.fromRGB(255, 255, 0) -- Màu vàng cho súng rơi

-- Hàm tạo ESP cho đối tượng (người chơi hoặc vật phẩm)
local function espObject(object, color)
    for _, part in pairs(object:GetChildren()) do
        if part:IsA("BasePart") then
            -- Xóa ESP cũ trước khi tạo mới
            for _, adornment in pairs(part:GetChildren()) do
                if adornment:IsA("BoxHandleAdornment") then
                    adornment:Destroy()
                end
            end

            -- Tạo ESP mới
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

-- Hàm cập nhật ESP cho tất cả người chơi
local function updateESP()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            if player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
                espObject(player.Character, murdererColor) -- Murderer (Màu đỏ)
            elseif player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun") then
                espObject(player.Character, sheriffColor) -- Sheriff (Màu xanh dương)
            else
                espObject(player.Character, innocentColor) -- Innocents (Màu xanh lá)
            end
        end
    end
end

-- Hàm kiểm tra và highlight súng rơi
local function updateGunESP()
    for _, object in pairs(workspace:GetChildren()) do
        if object:IsA("Tool") and object.Name == "Gun" then
            espObject(object, gunDroppedColor) -- Màu vàng cho súng rơi
        end
    end
end

-- Cập nhật ESP mỗi giây
while true do
    updateESP() -- Cập nhật ESP cho người chơi
    updateGunESP() -- Cập nhật ESP cho súng rơi
    wait(1) -- Cập nhật mỗi giây
end

-- Theo dõi sự kiện khi có người chơi mới tham gia
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        updateESP()
    end)
end)
]]
