local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ScrollingFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local TextButton = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local TextButton_2 = Instance.new("TextButton")

-- Thuộc tính ScreenGui
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Thuộc tính Frame (khung chính)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  -- Nền tối
Frame.BorderSizePixel = 0  -- Không có viền
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)  -- Vị trí giữa màn hình hơn
Frame.Size = UDim2.new(0, 250, 0, 300)  -- Kích thước điều chỉnh
Frame.AnchorPoint = Vector2.new(0.5, 0.5)  -- Canh giữa

-- Thuộc tính ScrollingFrame (khung cuộn danh sách công cụ)
ScrollingFrame.Parent = Frame
ScrollingFrame.Active = true
ScrollingFrame.BackgroundTransparency = 1  -- Nền trong suốt
ScrollingFrame.BorderSizePixel = 0  -- Không có viền
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.2, 0)  -- Vị trí điều chỉnh
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.6, 0)  -- Kích thước lớn hơn
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 1, 0)  -- Kích thước canvas tự động mở rộng

-- Thuộc tính UIListLayout (bố trí danh sách nút bên trong ScrollingFrame)
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)  -- Khoảng cách giữa các nút

-- Mẫu TextButton (nút công cụ)
TextButton.Parent = ScrollingFrame
TextButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)  -- Màu sáng hơn để tương phản
TextButton.BorderSizePixel = 0  -- Không có viền
TextButton.Size = UDim2.new(0, 200, 0, 35)
TextButton.Visible = false
TextButton.Font = Enum.Font.GothamBold  -- Font hiện đại
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 16  -- Kích thước chữ gọn gàng hơn
TextButton.TextStrokeTransparency = 0.75  -- Đường viền chữ nhẹ nhàng

-- Thuộc tính TextLabel (Tiêu đề)
TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1  -- Nền trong suốt
TextLabel.Size = UDim2.new(1, 0, 0, 30)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "Tool Giver"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 18  -- Tiêu đề đậm, phong cách hiện đại

-- Nút Cập nhật danh sách (ở dưới cùng)
TextButton_2.Parent = Frame
TextButton_2.BackgroundColor3 = Color3.fromRGB(0, 170, 255)  -- Màu xanh nổi bật
TextButton_2.BorderSizePixel = 0  -- Không có viền
TextButton_2.Position = UDim2.new(0.1, 0, 0.85, 0)  -- Vị trí ở dưới cùng
TextButton_2.Size = UDim2.new(0.8, 0, 0.1, 0)  -- Nút lớn hơn
TextButton_2.Font = Enum.Font.GothamBold
TextButton_2.Text = "Cập nhật danh sách"
TextButton_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton_2.TextSize = 16

-- Hàm cập nhật danh sách công cụ
local function FNDR_fake_script() -- Frame.LocalScript 
	local script = Instance.new('LocalScript', Frame)

	local button = script.Parent.ScrollingFrame.TextButton
	button.Parent = nil
	button.Name = "slaves"
	local function updatelist()
		for i, v in script.Parent.ScrollingFrame:GetDescendants() do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
	
		local function cloneToBackpack(toolName)
			local clonedTool = toolName:Clone()
			clonedTool.Parent = game:GetService("Players").LocalPlayer:WaitForChild("Backpack")
		end
		for i, v in pairs(game:GetDescendants()) do
			if v:IsA("Tool") and v.Parent.Parent ~= game:GetService("Players").LocalPlayer then
				local clonebutton = button:Clone()
				clonebutton.Parent = script.Parent.ScrollingFrame
				clonebutton.Visible = true
				clonebutton.Text = v.Name
				clonebutton.MouseButton1Click:Connect(function()
					cloneToBackpack(v)
				end)
			end
		end
	end
	script.Parent.TextButton.MouseButton1Click:Connect(updatelist)
end
coroutine.wrap(FNDR_fake_script)()

-- Script kéo thả Frame
local function SGRWUDK_fake_script() -- Frame.DragScript 
	local script = Instance.new('LocalScript', Frame)

	local UIS = game:GetService('UserInputService')
	local frame = script.Parent
	local dragToggle = nil
	local dragSpeed = 0
	local dragStart = nil
	local startPos = nil
	
	local function updateInput(input)
		local delta = input.Position - dragStart
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		game:GetService('TweenService'):Create(frame, TweenInfo.new(dragSpeed), {
			Position = position
		}):Play()
	end
	
	frame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
			dragToggle = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false
				end
			end)
		end
	end)
	
	UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input)
			end
		end
	end)
	
end
coroutine.wrap(SGRWUDK_fake_script)()
