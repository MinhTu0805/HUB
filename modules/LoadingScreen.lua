-- ═══ LoadingScreen.lua ═══ Boot screen: a scan beam resolves a minefield as progress advances
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local FONT, Gui, Lighting, New, RunService, TH = SV.FONT, SV.Gui, SV.Lighting, SV.New, SV.RunService, SV.TH
local Tw, VERSION = SV.Tw, SV.VERSION

-- ─── LOADING SCREEN ─────────────────────────────────────
-- No card, no box: just typography on the dimmed game.
--   · a big mono percentage counter
--   · a 16×4 field of hidden tiles; a thin SCAN BEAM sweeps left→right with real progress and
--     every tile it passes flips over and resolves into a number, a mine marker or an empty tile
--   · text slides up out of clipping masks; a hairline draws itself under the header
--   · on finish the field sweeps green, the text slides away and the whole screen is pulled
--     upward like a shutter, with a bright edge leading it, revealing the game underneath.
local Loading = {}
do
    local COLS, ROWS, TILE, GAP = 16, 4, 16, 4
    local GW  = COLS * TILE + (COLS - 1) * GAP        -- 316
    local GH  = ROWS * TILE + (ROWS - 1) * GAP        -- 76
    local W   = GW
    local Y_RULE, Y_NUM, Y_GRID = 26, 38, 122
    local Y_BAR = Y_GRID + GH + 16
    local H   = Y_BAR + 2

    local HID, HID2 = Color3.fromRGB(33, 35, 41), Color3.fromRGB(66, 70, 79)
    local REV       = Color3.fromRGB(14, 15, 18)
    local NUMC      = { [1] = TH.Info, [2] = TH.Good, [3] = TH.Bad }

    -- ── backdrop (it is also the "shutter": it slides up on finish) ──
    local dim = New("Frame", {
        Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(9, 10, 12),
        BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 100,
    }, Gui)
    local edge = New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = TH.Text, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, dim)

    local cam = workspace.CurrentCamera
    local fit = cam and math.clamp(math.min(cam.ViewportSize.Y / (H + 90), cam.ViewportSize.X / (W + 56)), 0.55, 1.1) or 1
    local stage = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 101,
    }, dim)
    New("UIScale", { Scale = fit }, stage)

    -- a clipping window: whatever is inside can slide in from below it, or away through it
    local function Mask(x, y, w, h)
        return New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
            BackgroundTransparency = 1, ClipsDescendants = true }, stage)
    end
    local function Label(parent, props)
        props.BackgroundTransparency = 1
        return New("TextLabel", props, parent)
    end
    local SLIDE = 22   -- how far text starts below its mask

    -- ── header ──
    local mHead = Mask(0, 0, W, 18)
    local tHead = Label(mHead, { Position = UDim2.fromOffset(0, SLIDE), Size = UDim2.fromOffset(W * 0.7, 16),
        Text = 'BLOCKERMAN  <font color="rgb(92,95,102)">SOLVER</font>', RichText = true, Font = FONT.Bold,
        TextSize = 13, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left })
    local tVer = Label(mHead, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, SLIDE),
        Size = UDim2.fromOffset(80, 16), Text = "v" .. VERSION, Font = FONT.Mono, TextSize = 11,
        TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Right })
    local rule = New("Frame", { Position = UDim2.fromOffset(0, Y_RULE), Size = UDim2.fromOffset(0, 1),
        BackgroundColor3 = TH.Line, BorderSizePixel = 0 }, stage)

    -- ── big counter ──
    local mNum = Mask(0, Y_NUM, 150, 66)
    local tNum = Label(mNum, { Position = UDim2.fromOffset(0, 70), Size = UDim2.fromOffset(150, 66), Text = "0",
        RichText = true, Font = FONT.Mono, TextSize = 56, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left })
    local function setNum(n)
        tNum.Text = string.format('%d<font size="20" color="rgb(92,95,102)">%%</font>', n)
    end
    setNum(0)

    -- ── status (previous line above, current line below with a blinking caret) ──
    local SX = 166
    local mStat = Mask(SX, Y_NUM + 24, W - SX, 38)
    local tPrev = Label(mStat, { Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(W - SX, 16), Text = "",
        Font = FONT.Mono, TextSize = 11, TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd })
    local tCur = Label(mStat, { Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(W - SX, 16), Text = "",
        Font = FONT.Mono, TextSize = 12, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd })
    local curText, lastText, caretOn = "", "", true
    local statReady = false
    local function showCur() tCur.Text = curText .. (caretOn and "_" or " ") end
    local function push(text)
        if text == lastText then return end
        lastText = text
        Loading.Last = text
        tPrev.Text = curText
        curText = text
        showCur()
        if statReady then
            tPrev.Position = UDim2.fromOffset(0, 20)
            tCur.Position = UDim2.fromOffset(0, 40)
            Tw(tPrev, 0.35, { Position = UDim2.fromOffset(0, 2) })
            Tw(tCur, 0.35, { Position = UDim2.fromOffset(0, 20) })
        end
    end

    -- ── the minefield ──
    local gridF = New("Frame", { Position = UDim2.fromOffset(0, Y_GRID), Size = UDim2.fromOffset(GW, GH),
        BackgroundTransparency = 1 }, stage)
    local cells, byCol = {}, {}
    for c = 1, COLS do byCol[c] = {} end
    for r = 1, ROWS do
        for c = 1, COLS do
            local v = (c * 7 + r * 13 + c * r * 3) % 11
            local kind = (v == 0 and "mine") or (v <= 2 and 1) or (v == 3 and 2) or (v == 4 and 3) or "empty"
            local cx = (c - 1) * (TILE + GAP) + TILE / 2
            local f = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, (r - 1) * (TILE + GAP) + TILE / 2),
                Size = UDim2.fromOffset(0, 0), BackgroundColor3 = HID, BorderSizePixel = 0,
            }, gridF)
            New("UICorner", { CornerRadius = UDim.new(0, 3) }, f)
            local st = New("UIStroke", { Color = TH.Line, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
            local lb = Label(f, { Size = UDim2.fromScale(1, 1), Text = type(kind) == "number" and tostring(kind) or "",
                Font = FONT.Bold, TextSize = 12, TextColor3 = NUMC[kind] or TH.Text, TextTransparency = 1 })
            local dm
            if kind == "mine" then
                dm = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(6, 6), Rotation = 45, BackgroundColor3 = TH.Bad,
                    BackgroundTransparency = 1, BorderSizePixel = 0 }, f)
            end
            local cell = { f = f, st = st, lb = lb, dm = dm, kind = kind, c = c, r = r, cx = cx, flipped = false, intro = false }
            cells[#cells + 1] = cell
            byCol[c][#byCol[c] + 1] = cell
        end
    end

    -- the beam and its fading trail
    local beam = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(0, Y_GRID - 8),
        Size = UDim2.fromOffset(2, GH + 16), BackgroundColor3 = TH.Text, BackgroundTransparency = 1, BorderSizePixel = 0 }, stage)
    local trail = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.new(0, 90, 1, 0), BackgroundColor3 = TH.Text, BackgroundTransparency = 1, BorderSizePixel = 0 }, beam)
    New("UIGradient", { Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.86) }) }, trail)

    -- hairline progress under the field
    local track = New("Frame", { Position = UDim2.fromOffset(0, Y_BAR), Size = UDim2.fromOffset(GW, 2),
        BackgroundColor3 = TH.Line, BackgroundTransparency = 1, BorderSizePixel = 0 }, stage)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = TH.Text, BorderSizePixel = 0 }, track)

    local blur
    pcall(function() blur = New("BlurEffect", { Name = "BlockermanBlur", Size = 0 }, Lighting) end)

    -- flip one tile over (squash → swap face → spring back) and let it resolve
    local function flip(cell, delay)
        cell.flipped = true
        task.delay(delay, function()
            if not cell.f.Parent then return end
            Tw(cell.f, 0.09, { Size = UDim2.fromOffset(0, TILE) }, Enum.EasingStyle.Quad)
            task.delay(0.09, function()
                if not cell.f.Parent then return end
                cell.f.BackgroundColor3 = REV
                cell.st.Transparency = 0
                if cell.dm then cell.dm.BackgroundTransparency = 0 end
                cell.lb.TextTransparency = 0
                Tw(cell.f, 0.3, { Size = UDim2.fromOffset(TILE, TILE) }, Enum.EasingStyle.Back)
            end)
        end)
    end

    local target, shown, finishing, colDone, shownNum, t0 = 0, 0, false, 0, -1, os.clock()
    local beamX, blinkT = 0, 0
    local conn = RunService.RenderStepped:Connect(function(dt)
        shown += (target - shown) * math.min(1, dt * 4.5)
        if target >= 1 and shown > 0.996 then shown = 1 end
        local now = os.clock() - t0

        -- counter + hairline
        local n = math.floor(shown * 100 + 0.5)
        if n ~= shownNum then shownNum = n; setNum(n) end
        fill.Size = UDim2.fromScale(math.clamp(shown, 0, 1), 1)

        -- beam follows progress; flip the columns it has passed
        beamX = shown * GW
        beam.Position = UDim2.fromOffset(beamX, Y_GRID - 8)
        while colDone < COLS and (colDone * (TILE + GAP) + TILE / 2) <= beamX + 2 do
            colDone += 1
            for i, cell in ipairs(byCol[colDone]) do flip(cell, (i - 1) * 0.035) end
        end

        -- caret blink
        blinkT += dt
        if blinkT > 0.5 then blinkT = 0; caretOn = not caretOn; showCur() end

        if finishing then return end
        -- hidden tiles shimmer, and glow brighter as the beam approaches
        for _, cell in ipairs(cells) do
            if cell.intro and not cell.flipped then
                local k = (math.sin(now * 2.1 - (cell.c + cell.r) * 0.7) + 1) / 2 * 0.35
                local ahead = cell.cx - beamX
                if ahead > 0 and ahead < 80 then k += (1 - ahead / 80) * 0.65 end
                cell.f.BackgroundColor3 = HID:Lerp(HID2, math.min(k, 1))
            end
        end
    end)

    -- ── intro ──
    Tw(dim, 0.45, { BackgroundTransparency = 0.12 })
    if blur then Tw(blur, 0.5, { Size = 14 }) end
    Tw(rule, 0.8, { Size = UDim2.fromOffset(W, 1) }, Enum.EasingStyle.Quint)
    task.delay(0.08, function()
        Tw(tHead, 0.6, { Position = UDim2.fromOffset(0, 1) }, Enum.EasingStyle.Quint)
        Tw(tVer, 0.6, { Position = UDim2.new(1, 0, 0, 2) }, Enum.EasingStyle.Quint)
    end)
    task.delay(0.2, function() Tw(tNum, 0.7, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint) end)
    task.delay(0.35, function()
        statReady = true
        Tw(tCur, 0.5, { Position = UDim2.fromOffset(0, 20) }, Enum.EasingStyle.Quint)
        Tw(tPrev, 0.5, { Position = UDim2.fromOffset(0, 2) }, Enum.EasingStyle.Quint)
        Tw(track, 0.4, { BackgroundTransparency = 0 })
        Tw(beam, 0.4, { BackgroundTransparency = 0 })
        Tw(trail, 0.4, { BackgroundTransparency = 0 })
    end)
    for _, cell in ipairs(cells) do        -- tiles pop in on a diagonal wave
        task.delay(0.3 + (cell.c + cell.r) * 0.02, function()
            if not cell.f.Parent then return end
            cell.intro = true
            Tw(cell.f, 0.4, { Size = UDim2.fromOffset(TILE, TILE) }, Enum.EasingStyle.Back)
        end)
    end

    function Loading.Set(frac, text)
        target = frac
        if text then push(text) end
    end
    function Loading.Status(text)
        lastText = text
        curText = text
        showCur()
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
        while colDone < COLS and os.clock() - t1 < 2.5 do task.wait() end
        task.wait(0.4)
        finishing = true

        -- green sweep left → right
        for _, cell in ipairs(cells) do
            task.delay(cell.c * 0.028, function()
                if not cell.f.Parent then return end
                Tw(cell.st, 0.18, { Color = TH.Good })
                Tw(cell.f, 0.18, { BackgroundColor3 = Color3.fromRGB(15, 31, 22) })
            end)
        end
        Tw(fill, 0.5, { BackgroundColor3 = TH.Good })
        task.wait(0.75)

        -- text slides away through its masks, the rule retracts, tiles drop out
        Tw(tHead, 0.35, { Position = UDim2.fromOffset(0, SLIDE) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(tVer, 0.35, { Position = UDim2.new(1, 0, 0, SLIDE) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(tNum, 0.4, { Position = UDim2.fromOffset(0, 70) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(tCur, 0.35, { Position = UDim2.fromOffset(0, 40) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(tPrev, 0.35, { Position = UDim2.fromOffset(0, 40) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(rule, 0.45, { Size = UDim2.fromOffset(0, 1) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tw(track, 0.3, { BackgroundTransparency = 1 })
        Tw(fill, 0.3, { BackgroundTransparency = 1 })
        Tw(beam, 0.3, { BackgroundTransparency = 1 })
        Tw(trail, 0.3, { BackgroundTransparency = 1 })
        for _, cell in ipairs(cells) do
            task.delay((COLS - cell.c) * 0.012, function()
                if not cell.f.Parent then return end
                Tw(cell.f, 0.25, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                Tw(cell.st, 0.2, { Transparency = 1 })
            end)
        end
        task.wait(0.5)

        -- shutter: the whole screen is pulled upward, a bright edge leading
        Tw(edge, 0.12, { BackgroundTransparency = 0 })
        Tw(dim, 0.65, { Position = UDim2.new(0, 0, -1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
        if blur then Tw(blur, 0.65, { Size = 0 }) end
        task.wait(0.7)
        Loading.Destroy()
    end
end

-- ─── exports ───
SV.Loading = Loading
