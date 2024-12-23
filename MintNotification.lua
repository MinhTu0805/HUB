-- Hàm tạo thông báo nhỏ gọn với hiệu ứng trượt
local function createCompactNotification(text, title, duration)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Tạo GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CompactNotificationGui"
    screenGui.Parent = PlayerGui

    -- Tạo khung chứa thông báo
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 60) -- Kích thước nhỏ gọn
    frame.Position = UDim2.new(1, 0, 1, -150) -- Bắt đầu ngoài màn hình (bên phải)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui

    -- Tạo góc bo tròn
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Tạo nhãn văn bản chính (in đậm)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10, 0.6, -5)
    textLabel.Position = UDim2.new(0, 5, 0, 5)
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold -- In đậm
    textLabel.TextSize = 16
    textLabel.TextWrapped = true
    textLabel.Parent = frame

    -- Tạo nhãn hiển thị phiên bản
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0.3, -5)
    titleLabel.Position = UDim2.new(0, 5, 0.65, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 14
    titleLabel.TextWrapped = true
    titleLabel.Parent = frame

    -- Hiệu ứng trượt vào từ bên phải
    frame:TweenPosition(
        UDim2.new(1, -260, 1, -150), -- Đích đến trong màn hình
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Sine,
        0.5, -- Thời gian hiệu ứng
        true
    )

    -- Chờ trong `duration` giây, sau đó trượt ra
    delay(duration, function()
        frame:TweenPosition(
            UDim2.new(1, 0, 1, -150), -- Quay về ngoài màn hình
            Enum.EasingDirection.In,
            Enum.EasingStyle.Sine,
            0.5, -- Thời gian hiệu ứng
            true,
            function()
                screenGui:Destroy()
            end
        )
    end)
end
