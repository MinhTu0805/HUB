-- ═══ LoadingScreen.lua ═══ Aurora boot screen (odometer · ruler · rainbow bar · seam split)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local Gui, Lighting, New, RunService = SV.Gui, SV.Lighting, SV.New, SV.RunService
local Tw, VERSION, TextService = SV.Tw, SV.VERSION, game:GetService("TextService")

-- ─── LOADING SCREEN ─────────────────────────────────────
--   · soft rainbow light on the screen edges, stronger as progress grows
--   · wordmark letters slide up one by one
--   · odometer percentage: every digit rolls like a mechanical counter
--   · 81-tick ruler: ticks near the progress head swell (gaussian bump)
--   · rainbow progress bar with a thin glow + spark head
--   · finish: light wave sweeps the ruler, text retracts, a thin seam is drawn across the
--     screen and the two halves slide apart to reveal the game.
local Loading = {}
do
    local CFG = { TITLE = "BLOCKERMAN", SUBTITLE = "SOLVER", TAGLINE = "Initializing",
        BLUR = true, EDGE_GLOW = true, PARTICLES = true, SPEED = 0.04 }

    local C = {
        Text = Color3.fromRGB(240, 241, 246), Lit = Color3.fromRGB(176, 180, 190),
        Dim = Color3.fromRGB(116, 120, 132), Line = Color3.fromRGB(44, 47, 56),
        Back = Color3.fromRGB(8, 9, 12), White = Color3.new(1, 1, 1),
    }
    local F_BOLD, F_MED, F_MONO = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Code
    local QUINT, QIN, QIO = Enum.EasingStyle.Quint, Enum.EasingDirection.In, Enum.EasingDirection.InOut

    local function measure(txt, size, font)
        local ok, v = pcall(function() return TextService:GetTextSize(txt, size, font, Vector2.new(1000, 100)) end)
        return (ok and v and v.X) or size * 0.62
    end
    -- closed-loop rainbow (first = last) so shifting the phase flows seamlessly
    local function rainbow(phase, sat, val)
        local k = {}
        for i = 0, 8 do k[#k + 1] = ColorSequenceKeypoint.new(i / 8, Color3.fromHSV((phase + i / 8) % 1, sat, val)) end
        return ColorSequence.new(k)
    end

    -- layout (px inside the stage; UIScale fits it to the screen)
    local W, NT = 380, 80
    local STEP = W / NT
    local Y_RULE, Y_NUM, LH, DW = 40, 56, 72, 42
    local Y_STAT = Y_NUM + LH + 2
    local BASE_T, Y_BAR, Y_FOOT, H, SLIDE = 184, 196, 218, 236, 32

    -- ── backdrop halves (they slide apart at the end) ──
    local root = New("Frame", { Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, Active = true, ZIndex = 100 }, Gui)
    local topH = New("Frame", { Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = C.Back,
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, root)
    local botH = New("Frame", { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5),
        BackgroundColor3 = C.Back, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, root)

    -- ── rainbow edge light: thin strips, opacity falling off inward ──
    local edgeFx = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, root)
    local gradH, gradV, gradBar, edgeStrips = {}, {}, {}, {}
    if CFG.EDGE_GLOW then
        local NS, SS = 14, 6
        local function strip(props, rot, list, k)
            props.BackgroundColor3 = C.White; props.BackgroundTransparency = 1; props.BorderSizePixel = 0
            local f = New("Frame", props, edgeFx)
            list[#list + 1] = New("UIGradient", { Rotation = rot }, f)
            edgeStrips[#edgeStrips + 1] = { f = f, k = k }
        end
        for i = 1, NS do
            local o, k = (i - 1) * SS, (1 - (i - 1) / NS) ^ 2.2
            strip({ Position = UDim2.new(0, 0, 0, o), Size = UDim2.new(1, 0, 0, SS) }, 0, gradH, k)
            strip({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -o), Size = UDim2.new(1, 0, 0, SS) }, 0, gradH, k)
            strip({ Position = UDim2.new(0, o, 0, 0), Size = UDim2.new(0, SS, 1, 0) }, 90, gradV, k)
            strip({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -o, 0, 0), Size = UDim2.new(0, SS, 1, 0) }, 90, gradV, k)
        end
    end

    -- ── drifting dust ──
    local fxParts = {}
    if CFG.PARTICLES then
        local rng = Random.new(7)
        for i = 1, 10 do
            local s = rng:NextInteger(2, 3)
            local f = New("Frame", { Size = UDim2.fromOffset(s, s), BackgroundColor3 = C.White,
                BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, root)
            New("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
            fxParts[i] = { f = f, x = rng:NextNumber(), sp = rng:NextNumber(0.018, 0.055), off = rng:NextNumber(), ph = rng:NextNumber(0, 6.28) }
        end
    end

    -- ── stage ──
    local cam = workspace.CurrentCamera
    local fit = cam and math.clamp(math.min(cam.ViewportSize.Y / (H + 130), cam.ViewportSize.X / (W + 170)), 0.55, 1.5) or 1
    local stage = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 4 }, root)
    New("UIScale", { Scale = fit }, stage)

    local seam = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 1), BackgroundColor3 = C.White, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5 }, root)
    gradBar[#gradBar + 1] = New("UIGradient", { Rotation = 0 }, seam)

    local function Mask(parent, x, y, w, h)
        return New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
            BackgroundTransparency = 1, ClipsDescendants = true }, parent)
    end
    local function Label(parent, props)
        props.BackgroundTransparency = 1; props.BorderSizePixel = 0
        return New("TextLabel", props, parent)
    end

    -- ── wordmark, letter by letter ──
    local mHead = Mask(stage, 0, 0, W, 32)
    local letters = {}
    do
        local chars, total = {}, 0
        local function collect(txt, font, size, isTitle)
            for _, cp in utf8.codes(txt) do
                local ch = utf8.char(cp)
                chars[#chars + 1] = { ch = ch, w = measure(ch, size, font), font = font, size = size, title = isTitle }
            end
        end
        collect(string.upper(CFG.TITLE), F_BOLD, 22, true)
        chars[#chars + 1] = { ch = "", w = 12, gap = true }
        collect(string.upper(CFG.SUBTITLE), F_MED, 22, false)
        for _, c in ipairs(chars) do total += c.w + 2.5 end
        total -= 2.5
        local x = (W - total) / 2
        for _, c in ipairs(chars) do
            if not c.gap then
                local l = Label(mHead, { Position = UDim2.fromOffset(x, SLIDE), Size = UDim2.fromOffset(c.w + 2, 28),
                    Text = c.ch, Font = c.font, TextSize = c.size, TextColor3 = c.title and C.Text or C.Dim,
                    TextXAlignment = Enum.TextXAlignment.Left })
                l:SetAttribute("x", x)
                letters[#letters + 1] = l
            end
            x += c.w + 2.5
        end
    end

    local rule = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, Y_RULE),
        Size = UDim2.fromOffset(0, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0.55, BorderSizePixel = 0 }, stage)
    gradBar[#gradBar + 1] = New("UIGradient", { Rotation = 0 }, rule)

    -- ── odometer ──
    local counter = New("Frame", { Position = UDim2.fromOffset(0, Y_NUM), Size = UDim2.fromOffset(W, LH), BackgroundTransparency = 1 }, stage)
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center }, counter)
    local lifts = {}
    local function makeSlot(order, labels, width, wrap)
        local mask = New("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(width, LH), BackgroundTransparency = 1, ClipsDescendants = true }, counter)
        local lift = New("Frame", { Position = UDim2.fromOffset(0, LH + 8), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, mask)
        local strip = New("Frame", { Size = UDim2.fromOffset(DW, LH * #labels), BackgroundTransparency = 1 }, lift)
        for i, t in ipairs(labels) do
            Label(strip, { Position = UDim2.fromOffset(0, (i - 1) * LH), Size = UDim2.fromOffset(DW, LH), Text = t,
                Font = F_MED, TextSize = 64, TextColor3 = C.Text })
        end
        lifts[#lifts + 1] = lift
        return { mask = mask, strip = strip, d = 0, wrap = wrap }
    end
    local D10 = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
    local sHund = makeSlot(1, { "", "1" }, 0, false)
    local sTens = makeSlot(2, D10, DW, true)
    local sOnes = makeSlot(3, D10, DW, true)
    local pctMask = New("Frame", { LayoutOrder = 4, Size = UDim2.fromOffset(34, LH), BackgroundTransparency = 1, ClipsDescendants = true }, counter)
    local pctLift = New("Frame", { Position = UDim2.fromOffset(0, LH + 8), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, pctMask)
    Label(pctLift, { Position = UDim2.fromOffset(5, -12), Size = UDim2.fromScale(1, 1), Text = "%", Font = F_MED, TextSize = 24,
        TextColor3 = C.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom })
    lifts[#lifts + 1] = pctLift

    local function roll(slot, d)
        if slot.d == d then return end
        local goal = d
        if slot.wrap and d < slot.d then goal = 10 end
        slot.d = d
        local tw = Tw(slot.strip, 0.28, { Position = UDim2.fromOffset(0, -goal * LH) }, QUINT)
        if goal == 10 then
            tw.Completed:Connect(function() if slot.d == d then slot.strip.Position = UDim2.fromOffset(0, -d * LH) end end)
        end
    end
    local hundOpen = false
    local function setNum(n)
        if n >= 100 and not hundOpen then
            hundOpen = true
            Tw(sHund.mask, 0.4, { Size = UDim2.fromOffset(DW, LH) }, QUINT)
        end
        roll(sHund, n >= 100 and 1 or 0)
        roll(sTens, math.floor(n / 10) % 10)
        roll(sOnes, n % 10)
    end

    -- ── status line (cross-slide) ──
    local mStat = Mask(stage, 0, Y_STAT, W, 22)
    local function statLabel()
        return Label(mStat, { Position = UDim2.fromOffset(0, 24), Size = UDim2.fromOffset(W, 20), Text = "", Font = F_MED,
            TextSize = 14, TextColor3 = C.Lit, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd })
    end
    local stA, stB = statLabel(), statLabel()
    local front, lastText = stB, ""
    local function swap(text, animate)
        local new, old = (front == stA) and stB or stA, front
        front = new
        new.Text = text
        if animate then
            new.Position = UDim2.fromOffset(0, 24); new.TextTransparency = 1
            Tw(new, 0.5, { Position = UDim2.fromOffset(0, 1), TextTransparency = 0 }, QUINT)
            Tw(old, 0.4, { Position = UDim2.fromOffset(0, -24), TextTransparency = 1 }, QUINT)
        else
            new.Position = UDim2.fromOffset(0, 1); new.TextTransparency = 0; old.TextTransparency = 1
        end
    end
    local function push(text)
        if text == lastText then return end
        lastText = text
        Loading.Last = text
        swap(text, true)
    end

    -- ── ruler ──
    local ticks = {}
    for i = 0, NT do
        local f = New("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(i * STEP, BASE_T),
            Size = UDim2.fromOffset(1, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, stage)
        ticks[i] = { f = f, x = i * STEP, major = (i % 10 == 0) }
    end

    -- ── rainbow bar + glow ──
    local barParts = {}
    local function part(inst, base)
        inst.BackgroundTransparency = 1
        barParts[#barParts + 1] = { inst, base }
        return inst
    end
    local track = part(New("Frame", { Position = UDim2.fromOffset(0, Y_BAR), Size = UDim2.fromOffset(W, 4), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, stage), 0)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fillMask = New("Frame", { Position = UDim2.fromOffset(0, Y_BAR - 18), Size = UDim2.fromOffset(0, 40), BackgroundTransparency = 1, ClipsDescendants = true }, stage)
    for _, g in ipairs({ { 14, 0.96 }, { 6, 0.9 } }) do
        local f = part(New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(0, 20),
            Size = UDim2.fromOffset(W, 4 + g[1]), BackgroundColor3 = C.White, BorderSizePixel = 0 }, fillMask), g[2])
        New("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        gradBar[#gradBar + 1] = New("UIGradient", { Rotation = 0 }, f)
    end
    local fill = part(New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(0, 20),
        Size = UDim2.fromOffset(W, 4), BackgroundColor3 = C.White, BorderSizePixel = 0 }, fillMask), 0)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    gradBar[#gradBar + 1] = New("UIGradient", { Rotation = 0 }, fill)
    local halos = {}
    for _, s in ipairs({ { 36, 0.97 }, { 18, 0.9 } }) do
        local f = part(New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, Y_BAR + 2),
            Size = UDim2.fromOffset(s[1], s[1]), BackgroundColor3 = C.White, BorderSizePixel = 0 }, stage), s[2])
        New("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        halos[#halos + 1] = f
    end
    local spark = part(New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, Y_BAR + 2),
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.White, BorderSizePixel = 0 }, stage), 0)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, spark)

    -- ── footer: tagline · version · clock ──
    local tTag = Label(stage, { Position = UDim2.fromOffset(0, Y_FOOT), Size = UDim2.fromOffset(140, 14), Text = string.upper(CFG.TAGLINE),
        Font = F_MONO, TextSize = 10, TextColor3 = C.Dim, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    local tVer = Label(stage, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, Y_FOOT), Size = UDim2.fromOffset(100, 14),
        Text = "v" .. VERSION, Font = F_MONO, TextSize = 10, TextColor3 = C.Dim, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })
    local tClock = Label(stage, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W, Y_FOOT), Size = UDim2.fromOffset(140, 14),
        Text = "00:00.0", Font = F_MONO, TextSize = 10, TextColor3 = C.Dim, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    local fades = { tTag, tVer, tClock }

    local marks = {}
    do
        local PX, PY, L = 46, 40, 10
        local function corner(cx, cy, sx, sy)
            local hx = (sx > 0) and cx or (cx - L)
            local vy = (sy > 0) and cy or (cy - L)
            local hy = (sy > 0) and cy or (cy - 1)
            local vx = (sx > 0) and cx or (cx - 1)
            marks[#marks + 1] = New("Frame", { Position = UDim2.fromOffset(hx, hy), Size = UDim2.fromOffset(L, 1), BackgroundColor3 = C.Dim, BackgroundTransparency = 1, BorderSizePixel = 0 }, stage)
            marks[#marks + 1] = New("Frame", { Position = UDim2.fromOffset(vx, vy), Size = UDim2.fromOffset(1, L), BackgroundColor3 = C.Dim, BackgroundTransparency = 1, BorderSizePixel = 0 }, stage)
        end
        corner(-PX, -PY, 1, 1); corner(W + PX, -PY, -1, 1); corner(-PX, H + PY, 1, -1); corner(W + PX, H + PY, -1, -1)
    end

    local blur
    if CFG.BLUR then pcall(function() blur = New("BlurEffect", { Name = "BlockermanBlur", Size = 0 }, Lighting) end) end

    -- ── per-frame loop ──
    local t0 = os.clock()
    local function clock() return os.clock() - t0 end
    local target, shown, finishing, shownNum = 0, 0, false, -1
    local sweepT, collapseT, fadeOutT, clockTxt, accT = nil, nil, nil, "", 1
    local SIG2 = 2 * 14 * 14

    local conn = RunService.RenderStepped:Connect(function(dt)
        shown += (target - shown) * math.min(1, dt * 4.2)
        if target >= 1 and shown > 0.997 then shown = 1 end
        local now = clock()
        local ph = (now * CFG.SPEED) % 1

        local n = math.floor(shown * 100 + 0.5)
        if n ~= shownNum then shownNum = n; setNum(n) end

        local headX = shown * W
        fillMask.Size = UDim2.fromOffset(headX, 40)
        spark.Position = UDim2.fromOffset(headX, Y_BAR + 2)
        for _, hf in ipairs(halos) do hf.Position = UDim2.fromOffset(headX, Y_BAR + 2) end

        local waveX = sweepT and ((now - sweepT) * 950 - 40) or nil
        local half = NT / 2
        for i = 0, NT do
            local t = ticks[i]
            local a = math.clamp((now - 0.4 - i * 0.008) / 0.45, 0, 1)
            a = 1 - (1 - a) ^ 3
            local d = t.x - headX
            local bumpH = 11 * math.exp(-(d * d) / SIG2)
            local bumpW = 0
            if waveX then local dw = t.x - waveX; bumpW = 10 * math.exp(-(dw * dw) / (2 * 22 * 22)) end
            local h = ((t.major and 7 or 4) + math.max(bumpH, bumpW)) * a
            if collapseT then h *= 1 - math.clamp((now - collapseT - math.abs(i - half) * 0.01) / 0.25, 0, 1) end
            t.f.Size = UDim2.fromOffset(1, math.max(h, 0))
            local acc = math.clamp(math.max(bumpH / 11, bumpW / 10), 0, 1)
            if t.x <= headX + 0.5 then
                t.f.BackgroundColor3 = (t.major and C.Text or C.Lit):Lerp(C.White, acc * 0.85)
            else
                t.f.BackgroundColor3 = C.Line:Lerp(C.Lit, acc)
            end
        end

        local fxA = math.clamp((now - 0.6) / 1.0, 0, 1)
        if fadeOutT then fxA *= 1 - math.clamp((now - fadeOutT) / 0.6, 0, 1) end
        for _, p in ipairs(fxParts) do
            local yf = (p.off - now * p.sp) % 1
            p.f.Position = UDim2.fromScale(p.x + 0.012 * math.sin(now * 0.7 + p.ph), yf)
            p.f.BackgroundTransparency = 1 - fxA * 0.28 * math.sin(math.pi * yf)
        end

        accT += dt
        if accT >= 1 / 30 then
            accT = 0
            local seqA, seqB = rainbow(ph, 0.36, 0.96), rainbow((ph + 0.33) % 1, 0.36, 0.96)
            for _, g in ipairs(gradH) do g.Color = seqA end
            for _, g in ipairs(gradV) do g.Color = seqB end
            for _, g in ipairs(gradBar) do g.Color = seqA end
            local A = math.clamp((now - 0.2) / 1.0, 0, 1) * (0.55 + 0.45 * shown) * (0.9 + 0.1 * math.sin(now * 1.7))
            if sweepT then local dtw = now - sweepT - 0.3; A *= 1 + 0.5 * math.exp(-(dtw * dtw) / 0.1) end
            if fadeOutT then A *= 1 - math.clamp((now - fadeOutT) / 0.7, 0, 1) end
            for _, s in ipairs(edgeStrips) do s.f.BackgroundTransparency = 1 - math.clamp(A * 0.2 * s.k, 0, 1) end
            if not finishing and now > 0.5 then
                local tenth = math.floor((now - 0.5) * 10)
                local txt = string.format("%02d:%02d.%d", math.floor(tenth / 600), math.floor(tenth / 10) % 60, tenth % 10)
                if txt ~= clockTxt then clockTxt = txt; tClock.Text = txt end
            end
        end
    end)

    -- ── intro ──
    Tw(topH, 0.5, { BackgroundTransparency = 0.1 }); Tw(botH, 0.5, { BackgroundTransparency = 0.1 })
    if blur then Tw(blur, 0.7, { Size = 18 }) end
    Tw(rule, 1.0, { Size = UDim2.fromOffset(W, 1) }, QUINT)
    for i, l in ipairs(letters) do
        task.delay(0.12 + i * 0.035, function() Tw(l, 0.7, { Position = UDim2.fromOffset(l:GetAttribute("x"), 2) }, QUINT) end)
    end
    for i, lf in ipairs(lifts) do
        task.delay(0.3 + i * 0.06, function() Tw(lf, 0.8, { Position = UDim2.fromOffset(0, 0) }, QUINT) end)
    end
    task.delay(0.5, function() for _, p in ipairs(barParts) do Tw(p[1], 0.6, { BackgroundTransparency = p[2] }) end end)
    task.delay(0.6, function()
        for _, f in ipairs(fades) do Tw(f, 0.6, { TextTransparency = 0 }) end
        for _, m in ipairs(marks) do Tw(m, 0.6, { BackgroundTransparency = 0.55 }) end
    end)

    -- ── API (same surface as before) ──
    function Loading.Set(frac, text)
        target = math.clamp(frac, 0, 1)
        if text then push(text) end
    end
    function Loading.Status(text)          -- silent status change (watchdog messages)
        lastText = text
        Loading.Last = text
        swap(text, false)
    end
    function Loading.Release()
        root.Active = false
        root.Visible = false
        if blur and blur.Parent then blur.Size = 0 end
    end
    function Loading.Destroy()
        pcall(function() conn:Disconnect() end)
        if root.Parent then root:Destroy() end
        if blur and blur.Parent then blur:Destroy() end
    end
    function Loading.Finish()
        target = 1
        push("Ready")
        local t1 = os.clock()
        while shown < 0.999 and os.clock() - t1 < 3 do task.wait() end
        task.wait(0.35)
        finishing = true

        sweepT = clock()                    -- light wave across the ruler + edge flash
        task.wait(0.95)

        for i, l in ipairs(letters) do
            task.delay(i * 0.014, function() Tw(l, 0.4, { Position = UDim2.fromOffset(l:GetAttribute("x"), SLIDE) }, QUINT, QIN) end)
        end
        for i, lf in ipairs(lifts) do
            task.delay(i * 0.03, function() Tw(lf, 0.45, { Position = UDim2.fromOffset(0, LH + 8) }, QUINT, QIN) end)
        end
        Tw(front, 0.35, { Position = UDim2.fromOffset(0, -24), TextTransparency = 1 }, QUINT, QIN)
        for _, f in ipairs(fades) do Tw(f, 0.3, { TextTransparency = 1 }) end
        for _, m in ipairs(marks) do Tw(m, 0.3, { BackgroundTransparency = 1 }) end
        for _, p in ipairs(barParts) do Tw(p[1], 0.35, { BackgroundTransparency = 1 }) end
        Tw(rule, 0.5, { Size = UDim2.fromOffset(0, 1) }, QUINT, QIN)
        collapseT = clock()
        task.wait(0.75)

        seam.BackgroundTransparency = 0     -- thin rainbow seam, then the halves split
        Tw(seam, 0.45, { Size = UDim2.new(1, 0, 0, 1) }, QUINT, QIO)
        task.wait(0.45)
        fadeOutT = clock()
        Tw(topH, 0.8, { Position = UDim2.fromScale(0, -0.5) }, QUINT, QIO)
        Tw(botH, 0.8, { Position = UDim2.fromScale(0, 1) }, QUINT, QIO)
        Tw(seam, 0.35, { BackgroundTransparency = 1 })
        if blur then Tw(blur, 0.8, { Size = 0 }) end
        task.wait(0.85)
        Loading.Destroy()
    end
end

-- ─── exports ───
SV.Loading = Loading
