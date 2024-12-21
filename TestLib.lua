local MyLibrary = {}

-- Tạo giao diện Hub chính
function MyLibrary:CreateHub(hubTitle)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MyLibraryGui"
    screenGui.Parent = PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Text = hubTitle
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.Parent = mainFrame

    return mainFrame
end

-- Tạo Tab trong Hub
function MyLibrary:CreateTab(parent, tabName)
    local tab = Instance.new("Frame")
    tab.Size = UDim2.new(1, 0, 0, 30)
    tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tab.Parent = parent

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size = UDim2.new(1, -10, 1, 0)
    tabLabel.Text = tabName
    tabLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabLabel.Font = Enum.Font.Gotham
    tabLabel.TextSize = 16
    tabLabel.Parent = tab

    return tab
end

-- Tạo Button
function MyLibrary:CreateButton(parent, buttonText, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Text = buttonText
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Font = Enum.Font.Gotham
    button.TextSize = 16
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)
    return button
end

-- Tạo Slider
function MyLibrary:CreateSlider(parent, sliderText, min, max, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.Text = sliderText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.9, 0, 0.3, 0)
    slider.Position = UDim2.new(0.05, 0, 0.6, 0)
    slider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    slider.Parent = frame

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 1, 0)
    knob.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    knob.Parent = slider

    local value = min
    knob.Position = UDim2.new(0, 0, 0, 0)

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mouse = game.Players.LocalPlayer:GetMouse()
                    local percent = math.clamp((mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                    knob.Position = UDim2.new(percent, 0, 0, 0)
                    value = math.floor(min + (max - min) * percent)
                    callback(value)
                end
            end)

            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)

    return frame
end

-- Tạo Dropdown
function MyLibrary:CreateDropdown(parent, dropdownText, options, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Text = dropdownText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.4, 0, 1, 0)
    button.Position = UDim2.new(0.6, 0, 0, 0)
    button.Text = "Select"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = frame

    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0.4, 0, 0, 0)
    dropdownFrame.Position = UDim2.new(0.6, 0, 1, 0)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdownFrame.ClipsDescendants = true
    dropdownFrame.Parent = frame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = dropdownFrame

    button.MouseButton1Click:Connect(function()
        dropdownFrame.Size = dropdownFrame.Size == UDim2.new(0.4, 0, 0, 0) and UDim2.new(0.4, 0, 0, #options * 30) or UDim2.new(0.4, 0, 0, 0)
    end)

    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 14
        optionButton.Parent = dropdownFrame

        optionButton.MouseButton1Click:Connect(function()
            button.Text = option
            dropdownFrame.Size = UDim2.new(0.4, 0, 0, 0)
            callback(option)
        end)
    end

    return frame
end

return MyLibrary
