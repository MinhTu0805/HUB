-- Notification Library
local NotificationLib = {}

-- Hàm tạo thông báo nhỏ gọn với hiệu ứng trượt
function NotificationLib.createCompactNotification(text, version, duration, customText)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Tạo GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CompactNotificationGui"
    screenGui.Parent = PlayerGui

    -- Tạo khung chứa thông báo
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.Position = UDim2.new(1, 0, 1, -150)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui

    -- Tạo góc bo tròn
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Kiểm tra xem text có chứa "rbxassetid://" không
    local textLabel, icon
    if string.find(text, "rbxassetid://") then
        -- Tạo ImageLabel cho icon
        icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 5, 0, 10)
        icon.BackgroundTransparency = 1
        icon.Image = text
        icon.Parent = frame

        -- Tạo nhãn văn bản chính (in đậm)
        textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -50, 0.6, -5)
        textLabel.Position = UDim2.new(0, 50, 0, 5)
        textLabel.Text = customText or "Thông báo"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 16
        textLabel.TextWrapped = true
        textLabel.Parent = frame
    else
        -- Tạo nhãn văn bản chính (in đậm) như bình thường
        textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -10, 0.6, -5)
        textLabel.Position = UDim2.new(0, 5, 0, 5)
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 16
        textLabel.TextWrapped = true
        textLabel.Parent = frame
    end

    -- Tạo nhãn hiển thị phiên bản
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -10, 0.3, -5)
    versionLabel.Position = UDim2.new(0, 5, 0.65, 0)
    versionLabel.Text = version
    versionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 14
    versionLabel.TextWrapped = true
    versionLabel.Parent = frame

    -- Hiệu ứng trượt vào từ bên phải
    frame:TweenPosition(
        UDim2.new(1, -260, 1, -150),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Sine,
        0.5,
        true
    )

    -- Chờ trong `duration` giây, sau đó trượt ra
    delay(duration, function()
        frame:TweenPosition(
            UDim2.new(1, 0, 1, -150),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Sine,
            0.5,
            true,
            function()
                screenGui:Destroy()
            end
        )
    end)
end

return NotificationLib
