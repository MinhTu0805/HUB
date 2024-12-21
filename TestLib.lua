local MyLibrary = {}

-- Tạo Hub
function MyLibrary:CreateHub(title)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LibraryHub"
    screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 250)
    frame.Position = UDim2.new(0.5, -200, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 24
    titleLabel.Parent = frame

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = frame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 10)
    uiListLayout.Parent = contentFrame

    return {Hub = screenGui, Content = contentFrame}
end

-- Tạo Tab (giống các thành phần trong giao diện)
function MyLibrary:CreateTab(hub, tabName)
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 0, 40)
    tabFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tabFrame.Parent = hub.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tabFrame

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size = UDim2.new(1, -10, 1, 0)
    tabLabel.Position = UDim2.new(0, 5, 0, 0)
    tabLabel.Text = tabName
    tabLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Font = Enum.Font.GothamBold
    tabLabel.TextSize = 18
    tabLabel.Parent = tabFrame

    return tabFrame
end

-- Tạo Button
function MyLibrary:CreateButton(tab, buttonName, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    button.Text = buttonName
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.Parent = tab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

-- Tạo Slider
function MyLibrary:CreateSlider(tab, sliderName, min, max, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 60)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = tab

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0.5, 0)
    sliderLabel.Position = UDim2.new(0, 0, 0, 0)
    sliderLabel.Text = sliderName
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 16
    sliderLabel.Parent = sliderFrame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, 0, 0.5, -10)
    slider.Position = UDim2.new(0, 0, 0.5, 5)
    slider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    slider.Text = tostring(min)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Font = Enum.Font.Gotham
    slider.TextSize = 16
    slider.Parent = sliderFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = slider

    local currentValue = min

    slider.MouseButton1Click:Connect(function()
        currentValue = currentValue + 1
        if currentValue > max then
            currentValue = min
        end
        slider.Text = tostring(currentValue)
        pcall(callback, currentValue)
    end)
end

-- Tạo Dropdown
function MyLibrary:CreateDropdown(tab, dropdownName, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, 0, 0, 60)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = tab

    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Size = UDim2.new(1, 0, 0.5, 0)
    dropdownLabel.Position = UDim2.new(0, 0, 0, 0)
    dropdownLabel.Text = dropdownName
    dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.TextSize = 16
    dropdownLabel.Parent = dropdownFrame

    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(1, 0, 0.5, -10)
    dropdown.Position = UDim2.new(0, 0, 0.5, 5)
    dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dropdown.Text = options[1]
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextSize = 16
    dropdown.Parent = dropdownFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dropdown

    local currentIndex = 1

    dropdown.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then
            currentIndex = 1
        end
        dropdown.Text = options[currentIndex]
        pcall(callback, options[currentIndex])
    end)
end

return MyLibrary
