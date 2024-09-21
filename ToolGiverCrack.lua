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

-- Thuộc tính Frame
Frame.Parent = ScreenGui
Frame.Active = true
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 0, 80))
}
UIGradient.Rotation = 45
UIGradient.Parent = Frame

-- Thuộc tính ScrollingFrame
ScrollingFrame.Parent = Frame
ScrollingFrame.Active = true
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 1, 0)

-- Bố trí UIListLayout
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Mẫu TextButton
TextButton.Parent = ScrollingFrame
TextButton.BackgroundColor3 = Color3.fromRGB(70, 70, 150)
TextButton.BorderSizePixel = 0
TextButton.Size = UDim2.new(0, 200, 0, 35)
TextButton.Visible = false
TextButton.Font = Enum.Font.GothamBold
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 16
TextButton.TextStrokeTransparency = 0.75

-- Tự động cập nhật CanvasSize dựa trên nội dung thực tế
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

-- Thuộc tính TextLabel
TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1
TextLabel.Size = UDim2.new(1, 0, 0, 30)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "Tool Giver"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 18

-- Nút cập nhật danh sách
TextButton_2.Parent = Frame
TextButton_2.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
TextButton_2.BorderSizePixel = 0
TextButton_2.Position = UDim2.new(0.1, 0, 0.85, 0)
TextButton_2.Size = UDim2.new(0.8, 0, 0.1, 0)
TextButton_2.Font = Enum.Font.GothamBold
TextButton_2.Text = "Cập nhật danh sách"
TextButton_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton_2.TextSize = 16

-- Hàm cập nhật danh sách công cụ
local function updateList()
	for i, v in ScrollingFrame:GetChildren() do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	for i, tool in pairs(game:GetDescendants()) do
		if tool:IsA("Tool") and tool.Parent.Parent ~= game:GetService("Players").LocalPlayer then
			local cloneButton = TextButton:Clone()
			cloneButton.Parent = ScrollingFrame
			cloneButton.Visible = true
			cloneButton.Text = tool.Name
			cloneButton.MouseButton1Click:Connect(function()
				local clonedTool = tool:Clone()
				clonedTool.Parent = game:GetService("Players").LocalPlayer:WaitForChild("Backpack")
			end)
		end
	end
end

TextButton_2.MouseButton1Click:Connect(updateList)

-- Script di chuyển khung Frame
local function dragFrame(frame)
	local UIS = game:GetService('UserInputService')
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Đảm bảo ScrollingFrame không ngăn cản việc kéo thả Frame
Frame.Active = true
Frame.Draggable = true
dragFrame(Frame)
