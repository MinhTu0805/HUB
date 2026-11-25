-- ═══ LoadingScreen.lua ═══ Animated loading screen (glass card + minesweeper cascade)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local FONT, Gui, Lighting, New, RunService, TH = SV.FONT, SV.Gui, SV.Lighting, SV.New, SV.RunService, SV.TH
local Tw, VERSION = SV.Tw, SV.VERSION
local Corner, Round, Stroke, Grad, AccentGrad = SV.Corner, SV.Round, SV.Stroke, SV.Grad, SV.AccentGrad

-- ─── LOADING SCREEN ─────────────────────────────────────
-- A glass card over a softly lit, blurred backdrop. A 7×7 minesweeper board opens up
-- like a real cascade (every tile that flips is real progress), the wordmark types in
-- letter by letter, a shimmering bar tracks progress and a three-line log scrolls
-- underneath. On finish the board flashes green outward from the centre, collapses,
-- and the card lifts away.
local Loading = {}
do
    local N, CELL, GAP = 7, 32, 5
    local BOARD  = N * CELL + (N - 1) * GAP          -- 254
    local PAD    = 28
    local CARD_W = BOARD + PAD * 2
    local TITLE_Y, BAR_Y, LOG_Y = BOARD + PAD + 20, BOARD + PAD + 66, BOARD + PAD + 86
    local CARD_H = LOG_Y + 3 * 15 + 22

    -- palette
    local HID1, HID2 = Color3.fromRGB(46, 50, 66), Color3.fromRGB(70, 76, 98)
    local REV        = Color3.fromRGB(22, 24, 34)
    local NUMC       = { [1] = TH.Info, [2] = TH.Good, [3] = TH.Bad, [4] = TH.Warn }
    local WHITE      = Color3.fromRGB(255, 255, 255)
    local SHADE      = Color3.fromRGB(206, 208, 222)

    -- ── backdrop: dim + two ambient light washes ──
    local dim = New("Frame", {
        Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 7, 11),
        BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 100,
    }, Gui)
    local function Wash(col, rot)
        local f = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BackgroundTransparency = 1,
            BorderSizePixel = 0 }, dim)
        New("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.84), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1),
        }) }, f)
        return f
    end
    local washA, washB = Wash(TH.Accent, 35), Wash(TH.Accent2, 215)

    -- ── card ──
    local stage = New("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 22),
        Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundColor3 = TH.Bg,
        BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 101,
    }, dim)
    Corner(stage, 20)
    Stroke(stage, TH.Line, 0.1)
    local cam = workspace.CurrentCamera
    local fit = cam and math.clamp(math.min(cam.ViewportSize.Y / (CARD_H + 40), cam.ViewportSize.X / (CARD_W + 40)), 0.5, 1.15) or 1
    local cardScale = New("UIScale", { Scale = fit * 0.94 }, stage)

    local face = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, stage)
    Grad(face, TH.Bg2, TH.Bg, 90)
    -- thin lit edge along the top of the card
    local edge = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, -70, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, stage)
    New("UIGradient", { Color = ColorSequence.new(TH.Accent, TH.Accent2), Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
    }) }, edge)

    -- ── board ──
    local grid = New("Frame", { Position = UDim2.fromOffset(PAD, PAD), Size = UDim2.fromOffset(BOARD, BOARD),
        BackgroundTransparency = 1 }, stage)
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
            Corner(f, 8)
            local shade = Grad(f, WHITE, SHADE, 90)          -- subtle top-lit bevel on every tile
            local st = Stroke(f, WHITE, 0.93)
            local lb = New("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Text = num > 0 and tostring(num) or "", Font = FONT.Bold, TextSize = 17,
                TextColor3 = NUMC[num] or TH.Text, TextTransparency = 1,
            }, f)
            cells[#cells + 1] = { f = f, lb = lb, st = st, d = d, on = false }
        end
    end
    table.sort(cells, function(a, b) return a.d < b.d end)   -- reveal order = outward from centre

    -- ── wordmark: letters type in one by one, then a soft colour wave keeps running ──
    local WORD = "BLOCKERMAN"
    local word = New("Frame", { Position = UDim2.fromOffset(PAD, TITLE_Y), Size = UDim2.fromOffset(BOARD, 30),
        BackgroundTransparency = 1, ClipsDescendants = true }, stage)
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 1),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, word)
    local letters = {}
    for i = 1, #WORD do
        local holder = New("Frame", { LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 30), BackgroundTransparency = 1 }, word)
        letters[i] = New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(0, 30), Text = WORD:sub(i, i),
            Font = FONT.Bold, TextSize = 25, TextColor3 = TH.Text, TextTransparency = 1 }, holder)
    end
    local lettersOn = false

    -- version chip
    local chip = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(PAD + BOARD, TITLE_Y + 15),
        Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = TH.Panel2,
        BorderSizePixel = 0 }, stage)
    Round(chip)
    Stroke(chip, TH.Accent, 0.6)
    New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, chip)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22),
        Text = "SOLVER  ·  v" .. VERSION, Font = FONT.Mono, TextSize = 11, TextColor3 = TH.Sub }, chip)

    -- ── progress bar (rounded track, gradient fill, travelling shimmer) ──
    local TRACK_W = BOARD - 52
    local track = New("Frame", { Position = UDim2.fromOffset(PAD, BAR_Y), Size = UDim2.fromOffset(TRACK_W, 6),
        BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, stage)
    Round(track)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0,
        ClipsDescendants = true }, track)
    Round(fill)
    AccentGrad(fill, 0)
    local shine = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, fill)
    local shineG = New("UIGradient", { Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1),
    }) }, shine)
    local done = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH.Good, BackgroundTransparency = 1,
        BorderSizePixel = 0 }, track)
    Round(done)
    local pct = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromOffset(PAD + BOARD, BAR_Y + 3), Size = UDim2.fromOffset(44, 16), Text = "0%",
        Font = FONT.Mono, TextSize = 13, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Right }, stage)

    -- ── three-line log (newest line bright with a pulsing dot) ──
    local logs = {}
    for i = 1, 3 do
        logs[i] = New("TextLabel", { BackgroundTransparency = 1,
            Position = UDim2.fromOffset(PAD + 14, LOG_Y + (i - 1) * 15), Size = UDim2.fromOffset(BOARD - 14, 15),
            Text = "", Font = FONT.Mono, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = (i == 3 and TH.Text) or TH.Sub, TextTransparency = (i == 3 and 0) or (i == 2 and 0.55) or 0.8,
            TextTruncate = Enum.TextTruncate.AtEnd }, stage)
    end
    local liveDot = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(PAD + 2, LOG_Y + 37),
        Size = UDim2.fromOffset(6, 6), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, stage)
    Round(liveDot)

    local lastText = ""
    local function push(text)
        if text == lastText then return end
        lastText = text
        Loading.Last = text
        logs[1].Text, logs[2].Text = logs[2].Text, logs[3].Text
        logs[3].Text = text
        logs[3].TextTransparency = 1
        logs[3].Position = UDim2.fromOffset(PAD + 14, LOG_Y + 36)
        Tw(logs[3], 0.24, { TextTransparency = 0, Position = UDim2.fromOffset(PAD + 14, LOG_Y + 30) })
    end

    local blur
    pcall(function() blur = New("BlurEffect", { Name = "BlockermanBlur", Size = 0 }, Lighting) end)

    local function reveal(cell)
        cell.on = true
        cell.f.BackgroundColor3 = TH.Accent
        cell.f.Size = UDim2.fromOffset(CELL * 0.6, CELL * 0.6)
        Tw(cell.f, 0.45, { Size = UDim2.fromOffset(CELL, CELL) }, Enum.EasingStyle.Back)
        Tw(cell.f, 0.55, { BackgroundColor3 = REV })
        Tw(cell.st, 0.55, { Transparency = 0.8 })
        Tw(cell.lb, 0.35, { TextTransparency = 0 })
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
        local now = os.clock() - t0
        shineG.Offset = Vector2.new((now * 0.8) % 2 - 1, 0)
        liveDot.BackgroundTransparency = 0.5 - 0.5 * math.sin(now * 5)
        if lettersOn then
            for i, lb in ipairs(letters) do
                local k = (math.sin(now * 2.4 - i * 0.6) + 1) / 2
                lb.TextColor3 = TH.Text:Lerp(TH.Accent, k * k * 0.75)
            end
        end
        if finishing then return end
        for _, cell in ipairs(cells) do
            if not cell.on then
                local k = (math.sin(now * 2.2 - cell.d * 0.85) + 1) / 2
                cell.f.BackgroundColor3 = HID1:Lerp(HID2, k * 0.7)
            end
        end
    end)

    -- entrance
    Tw(dim, 0.45, { BackgroundTransparency = 0.18 })
    Tw(washA, 0.9, { BackgroundTransparency = 0 })
    Tw(washB, 0.9, { BackgroundTransparency = 0 })
    Tw(stage, 0.6, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
    Tw(cardScale, 0.7, { Scale = fit }, Enum.EasingStyle.Back)
    if blur then Tw(blur, 0.6, { Size = 16 }) end
    task.delay(0.25, function()
        for i, lb in ipairs(letters) do
            task.delay(i * 0.05, function()
                if not lb.Parent then return end
                Tw(lb, 0.4, { TextTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
            end)
        end
        task.delay(#letters * 0.05 + 0.4, function() lettersOn = true end)
    end)

    function Loading.Set(frac, text)
        target = frac
        if text then push(text) end
    end
    function Loading.Status(text)
        lastText = text
        logs[3].Text = text
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
        task.wait(0.25)
        finishing = true
        Tw(done, 0.35, { BackgroundTransparency = 0 })
        Tw(liveDot, 0.2, { BackgroundColor3 = TH.Good })
        -- green wave outward from the centre, then every tile pops away
        for _, cell in ipairs(cells) do
            task.delay(cell.d * 0.04, function()
                if not cell.f.Parent then return end
                Tw(cell.f, 0.12, { BackgroundColor3 = TH.Good })
                task.delay(0.16, function()
                    if not cell.f.Parent then return end
                    Tw(cell.f, 0.32, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 },
                        Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    Tw(cell.st, 0.2, { Transparency = 1 })
                    Tw(cell.lb, 0.12, { TextTransparency = 1 })
                end)
            end)
        end
        task.wait(0.9)
        Tw(cardScale, 0.45, { Scale = fit * 1.04 }, Enum.EasingStyle.Quint)
        Tw(stage, 0.45, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -14) })
        Tw(dim, 0.55, { BackgroundTransparency = 1 })
        Tw(washA, 0.5, { BackgroundTransparency = 1 })
        Tw(washB, 0.5, { BackgroundTransparency = 1 })
        if blur then Tw(blur, 0.55, { Size = 0 }) end
        task.wait(0.6)
        Loading.Destroy()
    end
end

-- ─── exports ───
SV.Loading = Loading
