-- Tạo cấu trúc thư mục động (chỉ tạo một lần)
local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:FindFirstChild("TpSpawn") or Instance.new("ScreenGui")
screenGui.Name = "TpSpawn"
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false -- Ngăn reset giao diện khi respawn

-- Tạo nút chỉ nếu chưa tồn tại
local button = screenGui:FindFirstChild("TPToSpawn") or Instance.new("TextButton")
button.Name = "TPToSpawn"
button.Text = "Teleport To Spawn"
button.Size = UDim2.new(0.12, 0, 0.05, 0) -- Chiều rộng nhỏ, chiều cao giữ nguyên
button.Position = UDim2.new(0.5, 0, 0.1, 0) -- Thấp hơn, cách đỉnh 10%
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundColor3 = Color3.new(0, 0, 0)
button.BackgroundTransparency = 0.5
button.TextColor3 = Color3.new(0.360784, 0.639216, 1)
button.TextScaled = true
button.Font = Enum.Font.SourceSansBold
button.Parent = screenGui

-- Tạo UIStroke chỉ nếu chưa tồn tại
local uiStroke = button:FindFirstChild("UIStroke") or Instance.new("UIStroke")
uiStroke.Name = "UIStroke"
uiStroke.Color = Color3.new(0.360784, 0.639216, 1)
uiStroke.Thickness = 2
uiStroke.Parent = button

-- Tạo UIAspectRatioConstraint chỉ nếu chưa tồn tại
local uiAspectRatio = button:FindFirstChild("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
uiAspectRatio.Name = "UIAspectRatioConstraint"
uiAspectRatio.AspectRatio = 2.4 -- Tỷ lệ cho nút hẹp
uiAspectRatio.Parent = button

-- Tạo UISizeConstraint chỉ nếu chưa tồn tại
local uiSizeConstraint = button:FindFirstChild("UISizeConstraint") or Instance.new("UISizeConstraint")
uiSizeConstraint.Name = "UISizeConstraint"
uiSizeConstraint.MaxSize = Vector2.new(120, 40)
uiSizeConstraint.MinSize = Vector2.new(70, 25)
uiSizeConstraint.Parent = button

-- Script chính với tối ưu hóa tăng tốc teleport
local v_u_1 = game:GetService("TweenService")
local v_u_2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
local v_u_3 = game.Players.LocalPlayer
local v_u_4 = v_u_3:WaitForChild("TempValues"):WaitForChild("InSafeZone")
local v_u_5 = v_u_3:WaitForChild("DataValues"):WaitForChild("Time")
local v_u_6 = nil -- Humanoid sẽ được cập nhật sau
local v_u_7 = false -- Trạng thái hiển thị nút
local v_u_8 = nil
local v_u_9 = false -- Trạng thái teleport

-- Hàm cập nhật tham chiếu và trạng thái
local function updateCharacter()
	if v_u_3.Character then
		v_u_6 = v_u_3.Character:WaitForChild("Humanoid", 5)
		-- Khôi phục trạng thái nút nếu cần
		if v_u_4.Value == false and v_u_5.Value > 1000 and not v_u_7 then
			task.spawn(Appear)
		elseif v_u_7 and (v_u_4.Value == true or v_u_5.Value <= 1000) then
			task.spawn(DisAppear)
		end
	end
end

-- Khởi tạo ban đầu
updateCharacter()

-- Lắng nghe CharacterAdded để cập nhật Humanoid và trạng thái
v_u_3.CharacterAdded:Connect(updateCharacter)

function Appear()
	v_u_7 = true
	button.Visible = true
	local v10 = v_u_1:Create(button, v_u_2, { ["TextTransparency"] = 0 })
	local v11 = v_u_1:Create(button, v_u_2, { ["BackgroundTransparency"] = 0.5 })
	v10:Play()
	v11:Play()
end

function DisAppear()
	v_u_7 = false
	button.Visible = true
	local v12 = v_u_1:Create(button, v_u_2, { ["TextTransparency"] = 1 })
	local v13 = v_u_1:Create(button, v_u_2, { ["BackgroundTransparency"] = 1 })
	v12:Play()
	v13:Play()
	task.wait(0.2)
	button.Visible = false
end

-- Kết nối sự kiện chỉ một lần
if not button:FindFirstChild("InSafeZoneConnection") then
	local connection = v_u_4:GetPropertyChangedSignal("Value"):Connect(function()
		if v_u_4.Value == false and v_u_5.Value > 1000 then
			task.spawn(Appear)
		elseif v_u_7 == true then
			v_u_7 = false
			task.spawn(DisAppear)
		end
	end)
	local connInstance = Instance.new("IntValue")
	connInstance.Name = "InSafeZoneConnection"
	connInstance.Parent = button
end

if not button:FindFirstChild("TimeConnection") then
	local connection = v_u_5:GetPropertyChangedSignal("Value"):Connect(function()
		if v_u_4.Value == false and v_u_5.Value > 1000 then
			task.spawn(Appear)
		elseif v_u_7 == true then
			v_u_7 = false
			task.spawn(DisAppear)
		end
	end)
	local connInstance = Instance.new("IntValue")
	connInstance.Name = "TimeConnection"
	connInstance.Parent = button
end

function Text()
	button.Text = "Teleport To Spawn"
	v_u_1:Create(button, v_u_2, { ["TextColor3"] = Color3.new(0.360784, 0.639216, 1) }):Play()
	v_u_1:Create(button.UIStroke, v_u_2, { ["Color"] = Color3.new(0.360784, 0.639216, 1) }):Play()
end

function Moved()
	button.Text = "Please Dont Move!"
	v_u_1:Create(button, v_u_2, { ["TextColor3"] = Color3.new(1, 0.341176, 0.352941) }):Play()
	v_u_1:Create(button.UIStroke, v_u_2, { ["Color"] = Color3.new(1, 0.341176, 0.352941) }):Play()
	task.wait(0.5)
	if button then -- Kiểm tra nút tồn tại
		button.Text = "Teleport To Spawn"
		v_u_1:Create(button, v_u_2, { ["TextColor3"] = Color3.new(0.360784, 0.639216, 1) }):Play()
		v_u_1:Create(button.UIStroke, v_u_2, { ["Color"] = Color3.new(0.360784, 0.639216, 1) }):Play()
	end
end

function teleport()
	if not v_u_3.Character or not v_u_6 then return end
	v_u_8 = game.ReplicatedStorage.Objects.TpVisiual:Clone()
	v_u_8.Parent = workspace
	v_u_8.Position = v_u_3.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0)
	v_u_1:Create(button, v_u_2, { ["TextColor3"] = Color3.new(0.435294, 1, 0.333333) }):Play()
	v_u_1:Create(button.UIStroke, v_u_2, { ["Color"] = Color3.new(0.435294, 1, 0.333333) }):Play()
	local v14 = 3
	for _ = 1, 15 do
		if not v_u_3.Character or not v_u_6 or v_u_6.MoveDirection.Magnitude ~= 0 or v_u_3.TempValues.LuckyBlock.Value ~= false then
			if v_u_8 then
				v_u_8.Position = v_u_3.Character and v_u_3.Character.HumanoidRootPart and v_u_3.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0) or v_u_8.Position
				v_u_8:Destroy()
			end
			v_u_9 = false
			Moved()
			return
		end
		v_u_8.Position = v_u_3.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0)
		v14 = v14 - 0.2
		local v15 = button
		local v16 = v14 * 10
		v15.Text = math.floor(v16) / 10
		local v17 = v_u_8
		v17.Size = v17.Size * 0.97
		if v_u_3.DataValues.VIPTime.Value > 0 then
			task.wait(0.01) -- Nhanh: 0.15 giây
		else
			task.wait(0.04) -- Nhanh: 0.6 giây
		end
	end
	if v_u_8 then v_u_8:Destroy() end
	task.spawn(Text)
	game.ReplicatedStorage.Events.LoadLag:FireServer(0.6)
	game.ReplicatedStorage.Events.TeleportVal:FireServer()
	if v_u_3.Character then
		v_u_3.Character:MoveTo(game.Workspace.Map.BorderIdentifeirs.Center.Position)
	end
	task.wait(0.5)
	v_u_9 = false
end

-- Kết nối sự kiện click chỉ một lần
if not button:FindFirstChild("ClickConnection") then
	local connection = button.MouseButton1Click:Connect(function()
		game.Workspace.Sounds["UI Click 2"]:Play()
		if v_u_9 == false and v_u_3.Character and v_u_6 and (v_u_4.Value == false and (v_u_6.MoveDirection.Magnitude == 0 and v_u_3.TempValues.LuckyBlock.Value == false)) then
			task.spawn(teleport)
			v_u_9 = true
		end
	end)
	local connInstance = Instance.new("IntValue")
	connInstance.Name = "ClickConnection"
	connInstance.Parent = button
end