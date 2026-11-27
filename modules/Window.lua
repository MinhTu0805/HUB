-- ═══ Window.lua ═══ Settings window UI (tabs, toggles, floating button, drag)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local ApplyCfg, Auto, Bind, COLOR, Cleanup, ClearAll = SV.ApplyCfg, SV.Auto, SV.Bind, SV.COLOR, SV.Cleanup, SV.ClearAll
local FONT, GameRunning, Gui, IconAsset, New, QueueSolve = SV.FONT, SV.GameRunning, SV.Gui, SV.IconAsset, SV.New, SV.QueueSolve
local RISK_HIGH, RISK_LOW, RISK_MID, Refresh, S, SaveSettings = SV.RISK_HIGH, SV.RISK_LOW, SV.RISK_MID, SV.Refresh, SV.S, SV.SaveSettings
local Stats, StopWalking, TH, Toast, Tr, Tw = SV.Stats, SV.StopWalking, SV.TH, SV.Toast, SV.Tr, SV.Tw
local UserInputService, VERSION, VI, VIU = SV.UserInputService, SV.VERSION, SV.VI, SV.VIU
local OnLucide, Rainbow, RunService = SV.OnLucide, SV.Rainbow, SV.RunService
local BACK, QUINT = Enum.EasingStyle.Back, Enum.EasingStyle.Quint

-- ─── SETTINGS WINDOW ─────────────────────────────────────
-- Layout: title bar · stat strip · side rail (tabs) · content as cards of rows.
-- Graphite surfaces, 1px borders, one "on" colour; motion is short and eased (no bounce).
local function BuildWindow()
    local cam       = workspace.CurrentCamera
    -- Landscape window, compact. Scaled to fit both PC and small phone screens.
    local W, H      = 560, 300
    -- 1.00x in the slider = this auto size: at most 85% of the design size on big screens,
    -- and never more than ~64% of the screen height / 80% of the width (phones included).
    local autoScale = cam and math.clamp(math.min(cam.ViewportSize.Y * 0.64 / H, cam.ViewportSize.X * 0.8 / W, 0.85), 0.45, 0.85) or 0.8
    local RAIL      = 104
    local TOP       = 88          -- title bar (36) + stat strip (38) + gaps
    local BOT       = 8
    local Ord       = 0
    local Repaints  = {}
    local ON        = TH.Good     -- the only colour controls ever use: "on"
    local SEG       = Color3.fromRGB(54, 55, 63)
    local function nextOrder() Ord += 1; return Ord end
    local function Corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
    local function Stroke(o, col, tr)
        return New("UIStroke", { Color = col or TH.Line, Transparency = tr or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
    end
    local function Hair(parent, props)
        props.BackgroundColor3 = TH.Line; props.BorderSizePixel = 0
        return New("Frame", props, parent)
    end

    local win = New("CanvasGroup", {
        Name = "Window", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(W, H), BackgroundColor3 = TH.Bg, BorderSizePixel = 0,
        GroupTransparency = 1, Visible = false,
    }, Gui)
    Corner(win, 10)
    Stroke(win)
    local uiScale = New("UIScale", { Scale = autoScale * S.UIScale }, win)

    -- Aurora hairline along the top edge (same pastel rainbow as the boot screen); brighter while a round is live
    local aurora = New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 10 }, win)
    local auroraG = New("UIGradient", { Color = Rainbow(0), Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.18, 0),
        NumberSequenceKeypoint.new(0.82, 0), NumberSequenceKeypoint.new(1, 1) }) }, aurora)

    -- ── Title bar: logo (centre tile = live state) · name · state text · close ──
    local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, win)
    local logo = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, bar)
    local led
    local logoCells = {}
    for r = 0, 2 do
        for c = 0, 2 do
            local t = New("Frame", { Position = UDim2.fromOffset(c * 5, r * 5), Size = UDim2.fromOffset(4, 4),
                BackgroundColor3 = TH.Dim, BorderSizePixel = 0 }, logo)
            Corner(t, 1)
            logoCells[#logoCells + 1] = { f = t, r = r, c = c }
            if r == 1 and c == 1 then led = t end
        end
    end
    local function LogoWave()      -- ripples out from the centre tile every time the window opens
        for _, cell in ipairs(logoCells) do
            local dist = math.abs(cell.r - 1) + math.abs(cell.c - 1)
            if dist > 0 then
                task.delay(dist * 0.07, function()
                    if not cell.f.Parent then return end
                    cell.f.BackgroundColor3 = TH.Text
                    Tw(cell.f, 0.5, { BackgroundColor3 = TH.Dim })
                end)
            end
        end
    end
    local ttl = New("Frame", { Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -160, 1, 0), BackgroundTransparency = 1 }, bar)
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center }, ttl)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36),
        Text = "BLOCKERMAN", Font = FONT.Bold, TextSize = 13, TextColor3 = TH.Text }, ttl)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36),
        Text = "SOLVER  v" .. VERSION, Font = FONT.Mono, TextSize = 10, TextColor3 = TH.Dim }, ttl)
    local dragHandle = New("Frame", { Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1 }, bar)
    local footState = New("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0),
        Size = UDim2.fromOffset(100, 14), BackgroundTransparency = 1, Text = "IDLE", Font = FONT.Mono, TextSize = 10,
        TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Right }, bar)
    local closeBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(24, 24), BackgroundColor3 = TH.Panel2, BackgroundTransparency = 1, Text = "×",
        Font = FONT.Text, TextSize = 18, TextColor3 = TH.Sub, AutoButtonColor = false, BorderSizePixel = 0 }, bar)
    Corner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function() Tw(closeBtn, 0.12, { BackgroundTransparency = 0, TextColor3 = TH.Text }) end)
    closeBtn.MouseLeave:Connect(function() Tw(closeBtn, 0.18, { BackgroundTransparency = 1, TextColor3 = TH.Sub }) end)
    Hair(win, { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 1) })

    -- ── Stat strip: one bordered bar, four cells ──
    local strip = New("Frame", { Position = UDim2.fromOffset(12, 45), Size = UDim2.new(1, -24, 0, 38),
        BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, win)
    Corner(strip, 8)
    Stroke(strip)
    local function Readout(idx, label, col)
        local c = New("Frame", { Position = UDim2.new((idx - 1) / 4, 0, 0, 0), Size = UDim2.new(0.25, 0, 1, 0),
            BackgroundTransparency = 1 }, strip)
        if idx < 4 then
            Hair(c, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 1, 1, -14) })
        end
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -12, 0, 11),
            Text = label, Font = FONT.Text, TextSize = 10, TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left }, c)
        local clip = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 16),
            Size = UDim2.new(1, -12, 0, 18), ClipsDescendants = true }, c)
        local function mk()
            return New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "—",
                Font = FONT.Mono, TextSize = 15, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Left }, clip)
        end
        local front, back = mk(), mk()
        back.Position = UDim2.fromOffset(0, 20); back.TextTransparency = 1
        local cur = "—"
        return function(text)
            if text == cur then return end
            cur = text
            local old = front
            front, back = back, old
            front.Text = text
            front.TextColor3 = TH.Text; front.TextTransparency = 0
            front.Position = UDim2.fromOffset(0, 20)
            Tw(front, 0.4, { Position = UDim2.fromOffset(0, 0), TextColor3 = col })
            Tw(old, 0.3, { Position = UDim2.fromOffset(0, -20), TextTransparency = 1 }, QUINT, Enum.EasingDirection.In)
        end
    end
    local rSafe = Readout(1, "SAFE", TH.Good)
    local rMine = Readout(2, "MINES", TH.Bad)
    local rBest = Readout(3, "BEST RISK", TH.Info)
    local rMs   = Readout(4, "SOLVE", TH.Sub)

    -- ── Rail + content ──
    local rail = New("Frame", { Position = UDim2.fromOffset(0, TOP), Size = UDim2.new(0, RAIL, 1, -TOP - BOT),
        BackgroundTransparency = 1 }, win)
    local area = New("Frame", { Position = UDim2.fromOffset(RAIL, TOP), Size = UDim2.new(1, -RAIL, 1, -TOP - BOT),
        BackgroundTransparency = 1, ClipsDescendants = true }, win)

    -- selection pill that glides between tabs
    local indicator = New("Frame", { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(RAIL - 16, 30),
        BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, rail)
    Corner(indicator, 7)
    local indBar = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 0), BackgroundColor3 = TH.Text, BorderSizePixel = 0 }, indicator)
    Corner(indBar, 1)
    local pages = {}

    local SelectTab, ApplyLang
    local holders, tabBtns, tabY, current = {}, {}, {}, nil
    local tabIcons = {}
    local tabCount = 0

    -- ── Built-in glyphs (16×16, drawn with frames): shown instantly, so a tab never has a blank icon.
    -- They are swapped for the real Lucide icon as soon as that library has finished downloading.
    local function Box(parent, x, y, w, h, r, outline, col)
        local f = New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col,
            BackgroundTransparency = outline and 1 or 0, BorderSizePixel = 0 }, parent)
        if r > 0 then New("UICorner", { CornerRadius = UDim.new(0, r) }, f) end
        if outline then New("UIStroke", { Color = col, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f) end
    end
    local GLYPH = {
        Display = function(p, c) Box(p, 1, 3, 14, 10, 5, true, c); Box(p, 6, 6, 4, 4, 2, false, c) end,
        Solver = function(p, c)
            Box(p, 3, 3, 10, 10, 2, true, c); Box(p, 6, 6, 4, 4, 1, false, c)
            for _, v in ipairs({ 4, 7, 10 }) do Box(p, v, 0, 1, 2, 0, false, c); Box(p, v, 14, 1, 2, 0, false, c) end
        end,
        Auto = function(p, c)
            Box(p, 2, 5, 12, 9, 3, true, c); Box(p, 5, 8, 2, 2, 1, false, c); Box(p, 9, 8, 2, 2, 1, false, c)
            Box(p, 7, 1, 2, 3, 0, false, c)
        end,
        Stats = function(p, c) Box(p, 2, 8, 3, 6, 1, false, c); Box(p, 6, 2, 3, 12, 1, false, c); Box(p, 11, 5, 3, 9, 1, false, c) end,
        Settings = function(p, c)
            Box(p, 3, 3, 10, 10, 5, true, c); Box(p, 7, 7, 2, 2, 1, false, c)
            Box(p, 7, 0, 2, 3, 0, false, c); Box(p, 7, 13, 2, 3, 0, false, c)
            Box(p, 0, 7, 3, 2, 0, false, c); Box(p, 13, 7, 3, 2, 0, false, c)
        end,
        About = function(p, c) Box(p, 1, 1, 14, 14, 7, true, c); Box(p, 7, 4, 2, 2, 1, false, c); Box(p, 7, 7, 2, 5, 0, false, c) end,
    }
    -- tint a tab icon (a Lucide image or a frame glyph)
    local function IconTint(icon, col, t)
        if icon:IsA("ImageLabel") then
            Tw(icon, t, { ImageColor3 = col })
        else
            for _, d in ipairs(icon:GetDescendants()) do
                if d:IsA("UIStroke") then Tw(d, t, { Color = col })
                elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then Tw(d, t, { BackgroundColor3 = col }) end
            end
        end
    end
    local function TabTint(name, col, t)
        Tw(tabBtns[name], t, { TextColor3 = col })
        if tabIcons[name] then IconTint(tabIcons[name], col, t) end
    end
    local function MakePage(name, label, iconNames)
        tabCount += 1
        local y = (tabCount - 1) * 32
        tabY[name] = y

        local b = New("TextButton", { Position = UDim2.fromOffset(8, y), Size = UDim2.fromOffset(RAIL - 16, 30),
            BackgroundTransparency = 1, Text = label, Font = FONT.Text, TextSize = 13, TextColor3 = TH.Sub,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, rail)
        -- 34px left padding; icon at x = -24 sits 10px from the pill edge
        New("UIPadding", { PaddingLeft = UDim.new(0, 34) }, b)
        local function place(icon)
            if tabIcons[name] then tabIcons[name]:Destroy() end
            tabIcons[name] = icon
            icon.Parent = b
            local c = (current == name) and TH.Text or TH.Sub
            if icon:IsA("ImageLabel") then icon.ImageColor3 = c else IconTint(icon, c, 0) end
        end
        local glyph = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0),
            Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 })
        if GLYPH[name] then GLYPH[name](glyph, TH.Sub) end
        place(glyph)
        if iconNames then
            OnLucide(function()
                local asset = IconAsset(iconNames)
                if not asset or not b.Parent then return end
                place(New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
                    Image = asset.Url or ("rbxassetid://" .. tostring(asset.Id)),
                    ImageRectSize = asset.ImageRectSize, ImageRectOffset = asset.ImageRectOffset,
                    ImageColor3 = TH.Sub,
                }))
            end)
        end
        b.MouseEnter:Connect(function() if current ~= name then TabTint(name, TH.Text, 0.1) end end)
        b.MouseLeave:Connect(function() if current ~= name then TabTint(name, TH.Sub, 0.18) end end)
        tabBtns[name] = b

        local holder = New("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            GroupTransparency = 1, Visible = false }, area)
        local p = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = TH.Dim, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y }, holder)
        New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 0),
            PaddingBottom = UDim.new(0, 12) }, p)
        New("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, p)
        holders[name] = holder
        pages[name] = p
        b.Activated:Connect(function() if current ~= name then SelectTab(name) end end)
        return p
    end
    -- cards / sections / buttons of a page fade in one after another
    local function Stagger(name)
        local i = 0
        for _, ch in ipairs(pages[name]:GetChildren()) do
            if ch:IsA("CanvasGroup") then
                ch.GroupTransparency = 1
                task.delay(i * 0.035, function()
                    if ch.Parent then Tw(ch, 0.38, { GroupTransparency = 0 }) end
                end)
                i += 1
            end
        end
        pages[name].CanvasPosition = Vector2.new(0, 0)
    end
    function SelectTab(name, instant)
        local old = current
        current = name
        if old then
            local oh = holders[old]
            Tw(oh, 0.12, { GroupTransparency = 1 })
            TabTint(old, TH.Sub, 0.15)
            task.delay(0.13, function() if current ~= old then oh.Visible = false end end)
        end
        local h = holders[name]
        h.Visible = true
        TabTint(name, TH.Text, 0.15)
        if instant then
            h.GroupTransparency, h.Position = 0, UDim2.fromOffset(0, 0)
            indicator.Position = UDim2.fromOffset(8, tabY[name])
            indBar.Size = UDim2.fromOffset(2, 14)
        else
            h.GroupTransparency, h.Position = 1, UDim2.fromOffset(0, 10)
            Tw(h, 0.3, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
            Tw(indicator, 0.34, { Position = UDim2.fromOffset(8, tabY[name]) }, BACK)
            indBar.Size = UDim2.fromOffset(2, 4)
            Tw(indBar, 0.4, { Size = UDim2.fromOffset(2, 14) }, BACK)
            Stagger(name)
        end
    end

    -- ── Components ──
    -- A page is a vertical list of  [section label]  +  [card of rows]. Rows are added to the
    -- current card; a Section (or a Button) closes it so the next row opens a new card.
    local groups = {}
    local function Card(page)
        local card = groups[page]
        if card then return card end
        card = New("CanvasGroup", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = TH.Panel, BorderSizePixel = 0, LayoutOrder = nextOrder() }, page)
        Corner(card, 8)
        Stroke(card)
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
        card:SetAttribute("n", 0)
        groups[page] = card
        return card
    end
    local function Row(page, h)
        local card = Card(page)
        local n = card:GetAttribute("n") + 1
        card:SetAttribute("n", n)
        if n > 1 then   -- divider between rows (a sibling, so row padding never shifts it)
            Hair(card, { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = n * 2 - 1 })
        end
        return New("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = TH.Panel2, BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = n * 2 }, card)
    end
    local function Section(page, text)
        groups[page] = nil
        local f = New("CanvasGroup", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, BorderSizePixel = 0,
            LayoutOrder = nextOrder() }, page)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 10), Size = UDim2.new(1, -4, 0, 14),
            Text = string.upper(text), Font = FONT.Mono, TextSize = 10, TextColor3 = TH.Dim,
            TextXAlignment = Enum.TextXAlignment.Left }, f)
    end
    local function RowLabel(row, text, sub)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, sub and 6 or 0),
            Size = UDim2.new(1, -80, 0, sub and 18 or 36), Text = text, Font = FONT.Text, TextSize = 13,
            TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
        if sub then
            New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 24),
                Size = UDim2.new(1, -80, 0, 14), Text = sub, Font = FONT.Reg, TextSize = 11,
                TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
        end
    end

    local function Toggle(page, label, key, cb, sub)
        local row = Row(page, sub and 46 or 36)
        RowLabel(row, label, sub)
        local track = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(32, 18), BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, row)
        Corner(track, 9)
        local ts = Stroke(track, TH.Line)
        local knob = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(12, 12), BackgroundColor3 = TH.Sub, BorderSizePixel = 0 }, track)
        Corner(knob, 6)
        -- the knob stretches while pressed and springs into place (Back easing)
        local function paint(anim, pressed)
            local on  = S[key]
            local w   = pressed and 17 or 12
            local tc  = on and ON or TH.Panel2
            local sc  = on and ON or TH.Line
            local pos = on and UDim2.new(1, -(3 + w), 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            local kc  = on and Color3.fromRGB(255, 255, 255) or TH.Sub
            if anim then
                Tw(track, 0.2, { BackgroundColor3 = tc }); Tw(ts, 0.2, { Color = sc })
                Tw(knob, 0.32, { Position = pos, Size = UDim2.fromOffset(w, 12) }, BACK)
                Tw(knob, 0.2, { BackgroundColor3 = kc })
            else
                track.BackgroundColor3 = tc; ts.Color = sc
                knob.Position = pos; knob.Size = UDim2.fromOffset(w, 12); knob.BackgroundColor3 = kc
            end
        end
        Repaints[#Repaints + 1] = function() paint(true) end
        local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
            ZIndex = 5 }, row)
        hit.MouseEnter:Connect(function() Tw(row, 0.15, { BackgroundTransparency = 0.55 }) end)
        hit.MouseLeave:Connect(function() Tw(row, 0.22, { BackgroundTransparency = 1 }); paint(true) end)
        hit.MouseButton1Down:Connect(function() paint(true, true) end)
        hit.MouseButton1Up:Connect(function() paint(true) end)
        hit.Activated:Connect(function()
            S[key] = not S[key]
            paint(true); SaveSettings()
            if cb then cb(S[key]) end
        end)
        paint(false)
    end

    local function Slider(page, label, key, min, max, step, fmt, cb)
        local row = Row(page, 52)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 7), Size = UDim2.new(0.6, 0, 0, 18),
            Text = label, Font = FONT.Text, TextSize = 13, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local val = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0.4, 0, 0, 16), Text = "", Font = FONT.Mono,
            TextSize = 11, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Right }, row)
        local track = New("Frame", { Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 3),
            BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, row)
        Corner(track, 2)
        local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = TH.Text, BorderSizePixel = 0 }, track)
        Corner(fill, 2)
        local knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, track)
        Corner(knob, 6)
        local ring = New("UIStroke", { Color = TH.Text, Transparency = 1, Thickness = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, knob)
        local hit = New("TextButton", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1, Text = "", ZIndex = 5 }, row)

        local function paint(smooth)
            local a = (S[key] - min) / (max - min)
            if smooth then
                Tw(fill, 0.09, { Size = UDim2.fromScale(a, 1) }, Enum.EasingStyle.Quad)
                Tw(knob, 0.09, { Position = UDim2.fromScale(a, 0.5) }, Enum.EasingStyle.Quad)
            else
                fill.Size = UDim2.fromScale(a, 1)
                knob.Position = UDim2.fromScale(a, 0.5)
            end
            val.Text = fmt(S[key])
        end
        local lastFire, dragging = 0, false
        local function setX(x)
            local a = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            local v = math.clamp(math.floor((min + a * (max - min)) / step + 0.5) * step, min, max)
            v = tonumber(string.format("%.3f", v))
            if v ~= S[key] then
                S[key] = v; paint(true); SaveSettings()
                if cb and os.clock() - lastFire > 0.06 then lastFire = os.clock(); cb(v) end
            end
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local sf = hit:FindFirstAncestorOfClass("ScrollingFrame")
                if sf then sf.ScrollingEnabled = false end
                Tw(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }, BACK)
                Tw(ring, 0.2, { Transparency = 0.78, Thickness = 6 })
                Tw(val, 0.15, { TextColor3 = TH.Text })
                setX(i.Position.X)
            end
        end)
        Bind(UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                setX(i.Position.X)
            end
        end))
        Bind(UserInputService.InputEnded:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                local sf = hit:FindFirstAncestorOfClass("ScrollingFrame")
                if sf then sf.ScrollingEnabled = true end
                Tw(knob, 0.3, { Size = UDim2.fromOffset(12, 12) }, BACK)
                Tw(ring, 0.3, { Transparency = 1, Thickness = 0 })
                Tw(val, 0.25, { TextColor3 = TH.Sub })
                if cb then cb(S[key]) end
            end
        end))
        paint()
        return paint
    end

    local function Segmented(page, label, key, options, cb)
        local row = Row(page, 58)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 18),
            Text = label, Font = FONT.Text, TextSize = 13, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local strip = New("Frame", { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 22),
            BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, row)
        Corner(strip, 6)
        local n = #options
        local hl = New("Frame", { Size = UDim2.new(1 / n, -4, 1, -4), BackgroundColor3 = SEG, BorderSizePixel = 0 }, strip)
        Corner(hl, 4)
        local btns = {}
        local function paint(anim)
            local idx = 1
            for i, o in ipairs(options) do if o == S[key] then idx = i end end
            local pos = UDim2.new((idx - 1) / n, 2, 0, 2)
            if anim then Tw(hl, 0.32, { Position = pos }, BACK) else hl.Position = pos end
            for opt, b in next, btns do
                local c = S[key] == opt and TH.Text or TH.Sub
                if anim then Tw(b, 0.18, { TextColor3 = c }) else b.TextColor3 = c end
            end
        end
        for i, opt in ipairs(options) do
            local b = New("TextButton", { Position = UDim2.new((i - 1) / n, 0, 0, 0), Size = UDim2.new(1 / n, 0, 1, 0),
                BackgroundTransparency = 1, Text = opt, Font = FONT.Text, TextSize = 12, TextColor3 = TH.Sub,
                AutoButtonColor = false }, strip)
            b.Activated:Connect(function()
                if S[key] == opt then return end
                S[key] = opt; paint(true); SaveSettings()
                if cb then cb(opt) end
            end)
            btns[opt] = b
        end
        paint(false)
    end

    -- kind: nil (outline) | "primary" | "danger"
    local function Button(page, text, cb, kind)
        groups[page] = nil
        local wrap = New("CanvasGroup", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, BorderSizePixel = 0,
            LayoutOrder = nextOrder() }, page)
        local primary, danger = kind == "primary", kind == "danger"
        local rest  = primary and TH.Text or TH.Panel
        local hover = primary and Color3.fromRGB(208, 208, 214) or TH.Panel2
        local b = New("TextButton", { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = rest, Text = text, Font = FONT.Text, TextSize = 12,
            TextColor3 = primary and TH.Bg or (danger and TH.Bad or TH.Text), AutoButtonColor = false,
            BorderSizePixel = 0, ClipsDescendants = true }, wrap)
        Corner(b, 7)
        local st = Stroke(b, danger and TH.Bad or TH.Line, primary and 1 or (danger and 0.6 or 0))
        local sc = New("UIScale", { Scale = 1 }, b)
        -- a soft vertical wipe grows out from the point you clicked
        local function wipe(x)
            local frac = 0.5
            if x and b.AbsoluteSize.X > 0 then frac = math.clamp((x - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1) end
            local r = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(frac, 0.5),
                Size = UDim2.fromScale(0, 1), BackgroundColor3 = primary and TH.Bg or (danger and TH.Bad or TH.Text),
                BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 0 }, b)
            Corner(r, 7)
            Tw(r, 0.5, { Size = UDim2.fromScale(2.4, 1), BackgroundTransparency = 1 })
            task.delay(0.55, function() if r.Parent then r:Destroy() end end)
        end
        b.MouseEnter:Connect(function()
            Tw(b, 0.12, { BackgroundColor3 = hover })
            if not primary then Tw(st, 0.12, { Color = danger and TH.Bad or TH.Dim }) end
        end)
        b.MouseLeave:Connect(function()
            Tw(b, 0.2, { BackgroundColor3 = rest }); Tw(sc, 0.2, { Scale = 1 })
            if not primary then Tw(st, 0.2, { Color = danger and TH.Bad or TH.Line }) end
        end)
        b.MouseButton1Down:Connect(function() Tw(sc, 0.08, { Scale = 0.97 }) end)
        b.MouseButton1Up:Connect(function() Tw(sc, 0.35, { Scale = 1 }, BACK) end)
        b.Activated:Connect(function(input)
            wipe(input and input.Position and input.Position.X)
            cb()
        end)
    end

    local function Legend(page)
        local row = Row(page, 36)
        local function item(i, text, col, grad)
            local x = (i - 1) * 0.25
            local sq = New("Frame", { Position = UDim2.new(x, 12, 0.5, -4), Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = col or Color3.new(1, 1, 1), BorderSizePixel = 0 }, row)
            Corner(sq, 2)
            if grad then
                New("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, RISK_LOW),
                    ColorSequenceKeypoint.new(0.5, RISK_MID), ColorSequenceKeypoint.new(1, RISK_HIGH) }) }, sq)
            end
            New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(x, 26, 0, 0), Size = UDim2.new(0.25, -26, 1, 0),
                Text = text, Font = FONT.Text, TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Left }, row)
        end
        item(1, "Safe", COLOR.Safe); item(2, "Mine", COLOR.Mine); item(3, "Best", COLOR.Best); item(4, "Risk", nil, true)
    end

    local function StatRow(page, label)
        local row = Row(page, 30)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0),
            Text = label, Font = FONT.Reg, TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local v = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.6, -12, 1, 0), Text = "—", Font = FONT.Mono,
            TextSize = 12, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd }, row)
        return function(t) if v.Text ~= t then v.Text = t end end
    end

    -- ── Pages ──
    local d  = MakePage("Display", "Display",  { "eye" })
    local sv = MakePage("Solver",  "Solver",   { "cpu", "brain" })
    local au = MakePage("Auto",    "Auto",     { "bot", "zap" })
    local st = MakePage("Stats",   "Stats",    { "chart-column", "bar-chart-3", "bar-chart" })
    local se = MakePage("Settings", "Settings", { "settings", "sliders-horizontal" })
    local ab = MakePage("About",   "About",    { "info" })

    Legend(d)
    Section(d, "Overlay")
    Toggle(d, "Solver active", "Enabled", function(v)
        if v then SV.LastSig = nil; QueueSolve() else ClearAll() end
    end, "Turn everything off without unloading")
    Toggle(d, "Safe tiles", "ShowSafe", Refresh)
    Toggle(d, "Mines", "ShowMines", Refresh)
    Toggle(d, "Guess probabilities", "ShowGuess", Refresh)
    Toggle(d, "Best guess", "ShowBest", Refresh)
    Toggle(d, "Flagged mines", "ShowFlagged", Refresh, "Keep the overlay on tiles you flagged")
    Section(d, "Style")
    Segmented(d, "Overlay style", "Style", { "Soft", "Outline", "Dot" }, Refresh)
    Slider(d, "Fill opacity", "Opacity", 0.1, 0.9, 0.05, function(v) return math.floor(v * 100 + 0.5) .. "%" end, Refresh)
    Toggle(d, "Show % on guesses", "ShowPercent", Refresh, "Mine chance instead of “?”")
    Toggle(d, "See through walls", "AlwaysOnTop", Refresh)
    Section(d, "Effects")
    Toggle(d, "Animations", "Animations", Refresh, "Pop-in and colour fades")
    Toggle(d, "Pulse best guess", "PulseBest", Refresh)

    Section(sv, "Engine")
    Segmented(sv, "Accuracy", "Accuracy", { "Fast", "Balanced", "Max" }, function()
        ApplyCfg(); SV.LastSig = nil; QueueSolve()
    end)
    Toggle(sv, "Trust my flags", "TrustFlags", function()
        ApplyCfg(); SV.LastSig = nil; QueueSolve()
    end, "Treat flagged tiles as mines")
    Section(sv, "Actions")
    Button(sv, "Re-solve now", function()
        SV.LastSig = nil; QueueSolve(); Toast("Re-solving…", TH.Info)
    end, "primary")
    Button(sv, "Clear overlays", function() ClearAll(); SV.LastSig = nil end)

    Section(au, "Autopilot  ·  starts OFF every time")
    Toggle(au, "Auto flag mines", "AutoFlag", nil, "Flags every mine the solver proves")
    Toggle(au, "Auto remove wrong flags", "AutoUnflag", nil, "Takes flags off tiles proven safe")
    Toggle(au, "Auto move", "AutoMove", function(v) if not v then StopWalking() end end,
        "Walks only over revealed / proven-safe tiles")
    Toggle(au, "Auto guess when stuck", "AutoGuess", nil, "Steps on the best guess if risk is low enough")
    Slider(au, "Max guess risk", "MaxGuessRisk", 0.02, 0.5, 0.01, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
    Section(au, "Movement")
    Toggle(au, "Jump over hazards", "JumpOver", nil, "Hops one blocked tile when it saves a long detour")
    Toggle(au, "Boost jump on hops", "JumpBoost", nil, "Higher arc: lands on the far tile with speed to spare")
    Toggle(au, "Walk over flagged tiles", "WalkFlags", nil, "Flagged mines count as walkable")
    Toggle(au, "Strict safety", "StrictSafe", nil, "Only tiles proven by local logic, not by mine count")
    Slider(au, "Safety margin", "SafetyMargin", 0.15, 0.45, 0.01, function(v) return math.floor(v * 100 + 0.5) .. "% tile" end)
    Slider(au, "Caution speed", "CautionSpeed", 4, 16, 1, function(v) return v .. " studs/s" end)
    Section(au, "Flagging")
    Segmented(au, "Flag method", "FlagMethod", { "Click", "Mouse" })
    Slider(au, "Flags per pass", "FlagBatch", 1, 10, 1, function(v) return tostring(v) end)
    Slider(au, "Flag delay", "FlagDelay", 0.05, 0.6, 0.05, function(v) return string.format("%.2fs", v) end)
    Section(au, "Status")
    local aMove = StatRow(au, "Move")
    local aFlag = StatRow(au, "Flag")
    local aCnt  = StatRow(au, "Flags placed")
    local aMeth = StatRow(au, "Flag method")
    local aUnc  = StatRow(au, "Flags removed")
    local aUnm  = StatRow(au, "Unflag method")
    Button(au, "Stop all automation", function()
        S.AutoFlag, S.AutoMove, S.AutoGuess, S.AutoUnflag = false, false, false, false
        StopWalking(); SaveSettings()
        for _, f in ipairs(Repaints) do f() end
        Toast("Automation stopped", TH.Bad)
    end, "danger")

    Section(st, "Board")
    local sGame  = StatRow(st, "Game")
    local sGrid  = StatRow(st, "Grid")
    local sMines = StatRow(st, "Mines")
    local sTiles = StatRow(st, "Tiles tracked")
    Section(st, "Solver")
    local sSafe  = StatRow(st, "Safe tiles")
    local sMine  = StatRow(st, "Mines found")
    local sBest  = StatRow(st, "Best guess risk")
    local sMs    = StatRow(st, "Last solve")
    local sCnt   = StatRow(st, "Solves")
    Section(st, "Script")
    Button(st, "Unload script", function()
        Toast("Unloading…", TH.Bad)
        task.delay(0.3, Cleanup)
    end, "danger")


    -- ── Settings page: window size + language ──
    local uiSlider
    Section(se, "Window")
    uiSlider = Slider(se, "UI scale", "UIScale", 0.6, 1.5, 0.05, function(v) return string.format("%.2fx", v) end, function(v)
        uiScale.Scale = autoScale * v
    end)
    Button(se, "Reset UI size", function()
        S.UIScale = 1; SaveSettings()
        uiScale.Scale = autoScale
        if uiSlider then uiSlider() end
        Toast("UI size reset", TH.Info)
    end)
    Section(se, "Language")
    Segmented(se, "Language", "Language", { "English", "Tiếng Việt" }, function()
        ApplyLang()
        Toast("Language changed", TH.Info)
    end)

    -- ── About page ──
    local function Paragraph(page, text)
        local row = Row(page, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, row)
        New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Text = text, Font = FONT.Reg, TextSize = 12, TextColor3 = TH.Sub, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, row)
    end
    Section(ab, "About")
    StatRow(ab, "Name")("BLOCKERMAN SOLVER")
    StatRow(ab, "Version")("v" .. VERSION)
    StatRow(ab, "Made for")("Blockerman (Roblox minesweeper)")
    Section(ab, "How it works")
    Paragraph(ab, "The solver reads the board, works out which tiles are provably safe or mines, and estimates the mine chance for the rest. Green = safe, red = mine, blue = best guess.")
    Paragraph(ab, "Autopilot can flag mines, walk and guess for you. It always starts OFF and only walks over tiles it has proven safe.")
    Section(ab, "Controls")
    StatRow(ab, "Toggle window")("RightShift")
    StatRow(ab, "Move window")("Drag the title bar")
    StatRow(ab, "Floating button")("Tap to open / close")
    Section(ab, "Tips")
    Paragraph(ab, "If a guess is unavoidable, pick the tile with the lowest risk. Use “Strict safety” for the safest autopilot.")
    Paragraph(ab, "Your settings are saved automatically when your executor supports file writing.")

    -- ── Apply language: walks every label once, remembers the English source text ──
    local VI_FONT = {
        [Enum.Font.BuilderSansMedium] = Enum.Font.SourceSansSemibold,
        [Enum.Font.BuilderSansBold]   = Enum.Font.SourceSansBold,
        [Enum.Font.BuilderSans]       = Enum.Font.SourceSans,
    }
    function ApplyLang()
        local vi = S.Language == "Tiếng Việt"
        for _, o in ipairs(win:GetDescendants()) do
            if o:IsA("TextLabel") or o:IsA("TextButton") then
                local en = o:GetAttribute("_en")
                if not en and (VI[o.Text] or VIU[o.Text]) then en = o.Text; o:SetAttribute("_en", en) end
                if en then o.Text = Tr(en) end
                -- Builder Sans lacks some Vietnamese marks: use Source Sans while Vietnamese is selected
                local f0 = o:GetAttribute("_f")
                if not f0 then f0 = o.Font.Name; o:SetAttribute("_f", f0); o:SetAttribute("_s", o.TextSize) end
                local base = Enum.Font[f0]
                if vi and VI_FONT[base] then
                    o.Font = VI_FONT[base]; o.TextSize = o:GetAttribute("_s") + 1
                else
                    o.Font = base; o.TextSize = o:GetAttribute("_s")
                end
            end
        end
    end

    -- ── Dragging (title bar + floating button) ──
    local function MakeDraggable(handle, target, onClick, onMove)
        local dragging, startIn, startPos, moved = false, nil, nil, 0
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, moved, startIn, startPos = true, 0, i.Position, target.Position
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if onClick and moved < 6 then onClick(i.Position) end
                    end
                end)
            end
        end)
        Bind(UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - startIn
                moved = math.max(moved, delta.Magnitude)
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                if onMove then onMove(target.Position) end
            end
        end))
    end

    -- ── Floating button: a tiny 3×3 board, the centre tile shows the game state ──
    local fab = New("TextButton", { Name = "Toggle", Position = UDim2.new(0, 14, 0.5, -17), Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = TH.Panel, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, Gui)
    Corner(fab, 9)
    local fabStroke = New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, fab)
    local fabRing = New("UIGradient", { Color = Rainbow(0) }, fabStroke)   -- shows only while a round is live
    local fabScale = New("UIScale", { Scale = 1 }, fab)
    local fabCells = {}
    for r = 0, 2 do
        for c = 0, 2 do
            local f = New("Frame", { Position = UDim2.fromOffset(5 + c * 9, 5 + r * 9), Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = TH.Dim, BorderSizePixel = 0 }, fab)
            Corner(f, 2)
            fabCells[#fabCells + 1] = { f = f, r = r, c = c }
        end
    end
    local fabCore = fabCells[5].f
    local function Ripple(from)
        for _, cell in ipairs(fabCells) do
            local dist = math.abs(cell.r - from.r) + math.abs(cell.c - from.c)
            task.delay(dist * 0.045, function()
                if not cell.f.Parent then return end
                cell.f.BackgroundColor3 = TH.Accent
                Tw(cell.f, 0.35, { BackgroundColor3 = cell.f == fabCore and fabCore.BackgroundColor3 or TH.Dim })
            end)
        end
    end
    fab.MouseEnter:Connect(function() Tw(fabScale, 0.3, { Scale = 1.1 }, BACK); Tw(fabStroke, 0.15, { Thickness = 1.6 }) end)
    fab.MouseLeave:Connect(function() Tw(fabScale, 0.3, { Scale = 1 }, BACK); Tw(fabStroke, 0.2, { Thickness = 1 }) end)
    fab.MouseButton1Down:Connect(function() Tw(fabScale, 0.08, { Scale = 0.9 }) end)
    fab.MouseButton1Up:Connect(function() Tw(fabScale, 0.35, { Scale = 1.1 }, BACK) end)

    -- ── Open / close ──
    local open = false
    local restPos = win.Position      -- only ever changed by dragging, never captured mid-tween
    local posTw, scaleTw
    local function SetOpen(v)
        open = v
        local full = autoScale * S.UIScale
        if posTw then posTw:Cancel() end
        if scaleTw then scaleTw:Cancel() end
        if v then
            if not win.Visible then
                win.Position = restPos + UDim2.fromOffset(0, 16)
                uiScale.Scale = full * 0.93
                win.GroupTransparency = 1
                Stagger(current)
                LogoWave()
            end
            win.Visible = true
            posTw = Tw(win, 0.36, { GroupTransparency = 0, Position = restPos })
            scaleTw = Tw(uiScale, 0.45, { Scale = full }, BACK)
        else
            scaleTw = Tw(uiScale, 0.2, { Scale = full * 0.96 }, QUINT, Enum.EasingDirection.In)
            posTw = Tw(win, 0.2, { GroupTransparency = 1, Position = restPos + UDim2.fromOffset(0, 10) }, QUINT, Enum.EasingDirection.In)
            task.delay(0.26, function()
                if not open then win.Visible = false; win.Position = restPos end
            end)
        end
    end

    MakeDraggable(dragHandle, win, nil, function(p) restPos = p end)
    MakeDraggable(fab, fab, function() Ripple(fabCells[5]); SetOpen(not open) end)
    closeBtn.Activated:Connect(function() SetOpen(false) end)
    Bind(UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightShift then SetOpen(not open) end
    end))

    -- ── Aurora: hairline + floating-button ring drift while visible (~20 fps, nothing when hidden) ──
    local lastRun, lastTick = nil, 0
    Bind(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastTick < 0.05 then return end
        lastTick = now
        if win.Visible then auroraG.Color = Rainbow((now * 0.05) % 1) end
        if lastRun then
            fabRing.Rotation = (now * 70) % 360
            fabRing.Color = Rainbow((now * 0.05) % 1)
        end
    end))

    -- ── Live refresh ──
    task.spawn(function()
        local lastCol, lastLabel
        while SV.Alive do
            local running = GameRunning.Value
            local col = running and (SV.Solving and TH.Warn or TH.Good) or TH.Dim
            if running ~= lastRun then
                lastRun = running
                Tw(aurora, 0.7, { BackgroundTransparency = running and 0.2 or 0.7 })
                Tw(fabStroke, 0.5, { Color = running and Color3.new(1, 1, 1) or TH.Line })
            end
            if col ~= lastCol then lastCol = col; Tw(led, 0.25, { BackgroundColor3 = col }) end
            fabCore.BackgroundColor3 = running and TH.Good or TH.Sub
            local label = Tr(running and "ROUND LIVE" or "IDLE")
            if label ~= lastLabel then
                lastLabel = label
                footState.Text = label
                Tw(footState, 0.4, { TextColor3 = running and TH.Good or TH.Dim })
            end

            rSafe(tostring(Stats.safe))
            rMine(tostring(Stats.mine))
            rBest(Stats.bestProb and string.format("%d%%", math.floor(Stats.bestProb * 100 + 0.5)) or "—")
            rMs(string.format("%.0fms", Stats.solveMs))

            sGame(Tr(running and "In progress" or "Idle"))
            sGrid(SV.GridW and SV.GridH and (SV.GridW .. " × " .. SV.GridH) or Tr("Auto"))
            sMines(tostring(SV.TotalMines))
            sTiles(tostring(SV.TileCount))
            sSafe(tostring(Stats.safe))
            sMine(tostring(Stats.mine))
            sBest(Stats.bestProb and string.format("%.1f%%", Stats.bestProb * 100) or "—")
            sMs(string.format("%.1f ms", Stats.solveMs))
            sCnt(tostring(Stats.solves))
            aMove(Tr(Auto.move)); aFlag(Tr(Auto.flag)); aCnt(tostring(Auto.flags))
            aMeth(Auto.method)
            aUnc(tostring(Auto.unflags))
            aUnm(Auto.unmethod)
            task.wait(0.25)
        end
    end)

    ApplyLang()
    SelectTab("Display", true)
    return { SetOpen = SetOpen }
end

-- ─── exports ───
SV.BuildWindow = BuildWindow
