-- ═══ LoadingScreen.lua ═══ Animated loading screen (7x7 minesweeper cascade)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local FONT, Gui, Lighting, New, RunService, TH = SV.FONT, SV.Gui, SV.Lighting, SV.New, SV.RunService, SV.TH
local Tw, VERSION = SV.Tw, SV.VERSION

-- ─── LOADING SCREEN ─────────────────────────────────────
-- A 7×7 minesweeper board that opens up like a real cascade: every tile that
-- flips is real progress. A three-line log scrolls underneath. On finish the
-- board collapses outward from the centre.
local Loading = {}
do
    local N, CELL, GAP = 7, 30, 4
    local BOARD = N * CELL + (N - 1) * GAP

    local dim = New("Frame", {
        Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(9, 10, 12),
        BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 100,
    }, Gui)
    local stage = New("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 14),
        Size = UDim2.fromOffset(BOARD, BOARD + 132), BackgroundTransparency = 1,
        BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 101,
    }, dim)
    local grid = New("Frame", { Size = UDim2.fromOffset(BOARD, BOARD), BackgroundTransparency = 1 }, stage)

    local HID1, HID2 = Color3.fromRGB(44, 47, 54), Color3.fromRGB(66, 70, 79)
    local REV        = Color3.fromRGB(21, 23, 27)
    local FLASH      = Color3.fromRGB(104, 109, 120)
    local NUMC       = { [1] = TH.Info, [2] = TH.Good, [3] = TH.Bad, [4] = TH.Warn }

    local cells = {}
    local mid = (N + 1) / 2
    for r = 1, N do
        for c = 1, N do
            local d = math.abs(c - mid) + math.abs(r - mid) + ((c * 31 + r * 17) % 7) * 0.07
            local num = d < 2.3 and 0 or (((c * 7 + r * 13 + c * r) % 4) + 1)
            local f = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset((c - 1) * (CELL + GAP) + CELL / 2, (r - 1) * (CELL + GAP) + CELL / 2),
                Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = HID1, BorderSizePixel = 0,
            }, grid)
            New("UICorner", { CornerRadius = UDim.new(0, 4) }, f)
            local lb = New("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Text = num > 0 and tostring(num) or "", Font = FONT.Mono, TextSize = 16,
                TextColor3 = NUMC[num] or TH.Text, TextTransparency = 1,
            }, f)
            cells[#cells + 1] = { f = f, lb = lb, d = d, on = false }
        end
    end
    table.sort(cells, function(a, b) return a.d < b.d end)   -- reveal order = outward from centre

    -- wordmark
    local title = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, BOARD + 18),
        Size = UDim2.fromOffset(BOARD, 26), Text = "BLOCKERMAN", Font = FONT.Bold, TextSize = 22,
        TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left }, stage)
    local tag = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, BOARD + 24),
        Size = UDim2.fromOffset(BOARD, 16), Text = "SOLVER  v" .. VERSION, Font = FONT.Mono, TextSize = 11,
        TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Right }, stage)

    -- three-line log
    local LOGY = BOARD + 54
    local logs = {}
    for i = 1, 3 do
        logs[i] = New("TextLabel", { BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, LOGY + (i - 1) * 16), Size = UDim2.fromOffset(BOARD, 16),
            Text = "", Font = FONT.Mono, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = (i == 3 and TH.Text) or (i == 2 and TH.Sub) or TH.Dim,
            TextTruncate = Enum.TextTruncate.AtEnd }, stage)
    end
    local lastText = ""
    local function push(text)
        if text == lastText then return end
        lastText = text
        Loading.Last = text
        logs[1].Text, logs[2].Text = logs[2].Text, logs[3].Text
        logs[3].Text = "› " .. text
        logs[3].TextTransparency = 1
        logs[3].Position = UDim2.fromOffset(0, LOGY + 38)
        Tw(logs[3], 0.22, { TextTransparency = 0, Position = UDim2.fromOffset(0, LOGY + 32) })
    end

    -- hairline progress + percent
    local track = New("Frame", { Position = UDim2.fromOffset(0, BOARD + 114), Size = UDim2.fromOffset(BOARD - 46, 2),
        BackgroundColor3 = TH.Line, BorderSizePixel = 0 }, stage)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = TH.Text, BorderSizePixel = 0 }, track)
    local pct = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromOffset(BOARD, BOARD + 115), Size = UDim2.fromOffset(40, 14), Text = "0%",
        Font = FONT.Mono, TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Right }, stage)

    local blur
    pcall(function() blur = New("BlurEffect", { Name = "BlockermanBlur", Size = 0 }, Lighting) end)

    local function reveal(cell)
        cell.on = true
        cell.f.BackgroundColor3 = FLASH
        cell.f.Size = UDim2.fromOffset(CELL * 0.72, CELL * 0.72)
        Tw(cell.f, 0.38, { Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = REV }, Enum.EasingStyle.Back)
        Tw(cell.lb, 0.3, { TextTransparency = 0 })
    end

    local target, shown, revealed, finishing, t0 = 0, 0, 0, false, os.clock()
    local conn = RunService.RenderStepped:Connect(function(dt)
        shown += (target - shown) * math.min(1, dt * 5)
        if target >= 1 and shown > 0.995 then shown = 1 end
        fill.Size = UDim2.fromScale(math.clamp(shown, 0, 1), 1)
        pct.Text = string.format("%d%%", math.floor(shown * 100 + 0.5))
        local want, per = math.floor(shown * N * N + 0.5), 0
        while revealed < want and per < 3 do
            revealed += 1; per += 1
            reveal(cells[revealed])
        end
        if finishing then return end
        local now = os.clock() - t0
        for _, cell in ipairs(cells) do
            if not cell.on then
                local k = (math.sin(now * 2.6 - cell.d * 0.9) + 1) / 2
                cell.f.BackgroundColor3 = HID1:Lerp(HID2, k * 0.6)
            end
        end
    end)

    Tw(dim, 0.4, { BackgroundTransparency = 0.1 })
    Tw(stage, 0.55, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
    if blur then Tw(blur, 0.5, { Size = 14 }) end

    function Loading.Set(frac, text)
        target = frac
        if text then push(text) end
    end
    function Loading.Status(text)
        lastText = text
        logs[3].Text = "› " .. text
    end
    function Loading.Release()
        dim.Active = false
        dim.Visible = false
        if blur and blur.Parent then blur.Size = 0 end
    end
    function Loading.Destroy()
        pcall(function() conn:Disconnect() end)
        if dim.Parent then dim:Destroy() end
        if blur and blur.Parent then blur:Destroy() end
    end
    function Loading.Finish()
        target = 1
        push("Ready")
        local t1 = os.clock()
        while revealed < N * N and os.clock() - t1 < 2.5 do task.wait() end
        task.wait(0.3)
        finishing = true
        for _, cell in ipairs(cells) do
            task.delay(cell.d * 0.03, function()
                if not cell.f.Parent then return end
                Tw(cell.f, 0.3, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 },
                    Enum.EasingStyle.Back, Enum.EasingDirection.In)
                Tw(cell.lb, 0.15, { TextTransparency = 1 })
            end)
        end
        task.wait(0.22)
        Tw(stage, 0.4, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -10) })
        Tw(dim, 0.5, { BackgroundTransparency = 1 })
        if blur then Tw(blur, 0.5, { Size = 0 }) end
        task.wait(0.55)
        Loading.Destroy()
    end
end

-- ─── exports ───
SV.Loading = Loading
