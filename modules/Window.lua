-- ═══ Window.lua ═══ Settings window UI (tabs, toggles, floating button, drag)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local ApplyCfg, Auto, Bind, COLOR, Cleanup, ClearAll = SV.ApplyCfg, SV.Auto, SV.Bind, SV.COLOR, SV.Cleanup, SV.ClearAll
local FONT, GameRunning, Gui, IconAsset, New, QueueSolve = SV.FONT, SV.GameRunning, SV.Gui, SV.IconAsset, SV.New, SV.QueueSolve
local RISK_HIGH, RISK_LOW, RISK_MID, Refresh, S, SaveSettings = SV.RISK_HIGH, SV.RISK_LOW, SV.RISK_MID, SV.Refresh, SV.S, SV.SaveSettings
local Stats, StopWalking, TH, Toast, Tr, Tw = SV.Stats, SV.StopWalking, SV.TH, SV.Toast, SV.Tr, SV.Tw
local UserInputService, VERSION, VI, VIU = SV.UserInputService, SV.VERSION, SV.VI, SV.VIU

-- ─── SETTINGS WINDOW ─────────────────────────────────────
-- Layout: title bar · live readout strip · side rail (tabs) · content · footer.
-- Flat surfaces, 1px lines, paper-coloured controls; colour only where it carries meaning.
local function BuildWindow()
    local cam       = workspace.CurrentCamera
    -- Landscape window (wider than tall). Scale so BOTH sides fit on small phone screens.
    local W, H      = 660, 330
    local autoScale = cam and math.clamp(math.min(cam.ViewportSize.Y / (H + 24), cam.ViewportSize.X / (W + 24)), 0.5, 1) or 1
    local RAIL      = 112
    local TOP       = 82          -- title (36) + readout (44) + 2 hairlines
    local FOOT      = 22
    local Ord       = 0
    local Repaints  = {}
    local function nextOrder() Ord += 1; return Ord end
    local function Corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
    local function Hair(parent, props)
        props.BackgroundColor3 = TH.Line; props.BorderSizePixel = 0
        return New("Frame", props, parent)
    end

    local win = New("CanvasGroup", {
        Name = "Window", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(W, H), BackgroundColor3 = TH.Bg, BorderSizePixel = 0,
        GroupTransparency = 1, Visible = false,
    }, Gui)
    Corner(win, 8)
    New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, win)
    local uiScale = New("UIScale", { Scale = autoScale * S.UIScale }, win)

    -- ── Title bar ──
    local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, win)
    local led = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = TH.Dim, BorderSizePixel = 0 }, bar)
    Corner(led, 2)
    local ttl = New("Frame", { Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1 }, bar)
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center }, ttl)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36),
        Text = "BLOCKERMAN", Font = FONT.Bold, TextSize = 14, TextColor3 = TH.Text }, ttl)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36),
        Text = "v" .. VERSION, Font = FONT.Mono, TextSize = 11, TextColor3 = TH.Dim }, ttl)
    local dragHandle = New("Frame", { Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1 }, bar)
    local closeBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(42, 36), BackgroundTransparency = 1, Text = "×", Font = FONT.Text,
        TextSize = 22, TextColor3 = TH.Sub, AutoButtonColor = false }, bar)
    closeBtn.MouseEnter:Connect(function() Tw(closeBtn, 0.12, { TextColor3 = TH.Bad }) end)
    closeBtn.MouseLeave:Connect(function() Tw(closeBtn, 0.18, { TextColor3 = TH.Sub }) end)
    Hair(win, { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 1) })

    -- ── Live readout strip ──
    local strip = New("Frame", { Position = UDim2.fromOffset(0, 37), Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1 }, win)
    local function Readout(idx, label, col)
        local c = New("Frame", { Position = UDim2.new((idx - 1) / 4, 0, 0, 0), Size = UDim2.new(0.25, 0, 1, 0),
            BackgroundTransparency = 1 }, strip)
        if idx < 4 then Hair(c, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.new(0, 1, 1, -16) }) end
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 5), Size = UDim2.new(1, -14, 0, 12),
            Text = label, Font = FONT.Text, TextSize = 10, TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left }, c)
        local v = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 17), Size = UDim2.new(1, -14, 0, 22),
            Text = "—", Font = FONT.Mono, TextSize = 18, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Left }, c)
        local cur = "—"
        return function(text)
            if text == cur then return end
            cur = text
            v.Text = text
            v.TextColor3 = TH.Accent
            v.Position = UDim2.fromOffset(14, 21)
            Tw(v, 0.4, { TextColor3 = col, Position = UDim2.fromOffset(14, 17) })
        end
    end
    local rSafe = Readout(1, "SAFE", TH.Good)
    local rMine = Readout(2, "MINES", TH.Bad)
    local rBest = Readout(3, "BEST RISK", TH.Info)
    local rMs   = Readout(4, "SOLVE", TH.Sub)
    Hair(win, { Position = UDim2.fromOffset(0, 81), Size = UDim2.new(1, 0, 0, 1) })

    -- ── Rail + content ──
    local rail = New("Frame", { Position = UDim2.fromOffset(0, TOP), Size = UDim2.new(0, RAIL, 1, -TOP - FOOT),
        BackgroundTransparency = 1 }, win)
    Hair(win, { Position = UDim2.fromOffset(RAIL, TOP), Size = UDim2.new(0, 1, 1, -TOP - FOOT) })
    local area = New("Frame", { Position = UDim2.fromOffset(RAIL + 1, TOP), Size = UDim2.new(1, -RAIL - 1, 1, -TOP - FOOT),
        BackgroundTransparency = 1, ClipsDescendants = true }, win)

    Hair(win, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -FOOT), Size = UDim2.new(1, 0, 0, 1) })
    New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, 0), Size = UDim2.new(0.6, 0, 0, FOOT),
        BackgroundTransparency = 1, Text = "RightShift  show / hide   ·   drag the title bar", Font = FONT.Reg, TextSize = 11,
        TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left }, win)
    local footState = New("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, 0),
        Size = UDim2.new(0.35, 0, 0, FOOT), BackgroundTransparency = 1, Text = "IDLE", Font = FONT.Mono, TextSize = 11,
        TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Right }, win)

    local indicator = New("Frame", { Position = UDim2.fromOffset(0, 15), Size = UDim2.fromOffset(2, 16),
        BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, rail)

    local SelectTab, ApplyLang
    local holders, tabBtns, tabY, current = {}, {}, {}, nil
    local tabIcons = {}
    local tabCount = 0
    -- tint the tab label and its icon together
    local function TabTint(name, col, t)
        Tw(tabBtns[name], t, { TextColor3 = col })
        if tabIcons[name] then Tw(tabIcons[name], t, { ImageColor3 = col }) end
    end
    local function MakePage(name, label, iconNames)
        tabCount += 1
        local y = 6 + (tabCount - 1) * 34
        tabY[name] = y + 9

        local b = New("TextButton", { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1, Text = label, Font = FONT.Text, TextSize = 13, TextColor3 = TH.Sub,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, rail)
        local asset = iconNames and IconAsset(iconNames)
        New("UIPadding", { PaddingLeft = UDim.new(0, asset and 40 or 16) }, b)
        if asset then
            -- the button has 40px left padding, so x = -24 puts the icon at 16px from the rail edge
            tabIcons[name] = New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0),
                Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
                Image = asset.Url or ("rbxassetid://" .. tostring(asset.Id)),
                ImageRectSize = asset.ImageRectSize, ImageRectOffset = asset.ImageRectOffset,
                ImageColor3 = TH.Sub,
            }, b)
        end
        b.MouseEnter:Connect(function() if current ~= name then TabTint(name, TH.Text, 0.1) end end)
        b.MouseLeave:Connect(function() if current ~= name then TabTint(name, TH.Sub, 0.18) end end)
        tabBtns[name] = b

        local holder = New("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            GroupTransparency = 1, Visible = false }, area)
        local p = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = TH.Dim, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y }, holder)
        New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 12) }, p)
        New("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, p)
        holders[name] = holder
        b.Activated:Connect(function() if current ~= name then SelectTab(name) end end)
        return p
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
            indicator.Position = UDim2.fromOffset(0, tabY[name])
        else
            h.GroupTransparency, h.Position = 1, UDim2.fromOffset(12, 0)
            Tw(h, 0.28, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
            Tw(indicator, 0.3, { Position = UDim2.fromOffset(0, tabY[name]) })
        end
    end

    -- ── Components ──
    local function Row(page, h)
        local r = New("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = TH.Panel, BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = nextOrder() }, page)
        Hair(r, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1),
            BackgroundTransparency = 0.45 })
        r.MouseEnter:Connect(function() Tw(r, 0.12, { BackgroundTransparency = 0.35 }) end)
        r.MouseLeave:Connect(function() Tw(r, 0.2, { BackgroundTransparency = 1 }) end)
        return r
    end
    local function Section(page, text)
        local f = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, page)
        Hair(f, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 5), Size = UDim2.new(1, 0, 0, 1), ZIndex = 1 })
        local l = New("TextLabel", { Position = UDim2.fromOffset(0, 9), AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 14), BackgroundColor3 = TH.Bg, BorderSizePixel = 0, Text = string.upper(text),
            Font = FONT.Mono, TextSize = 10, TextColor3 = TH.Dim, ZIndex = 2 }, f)
        New("UIPadding", { PaddingRight = UDim.new(0, 8) }, l)
    end
    local function RowLabel(row, text, sub)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, sub and 7 or 0),
            Size = UDim2.new(1, -70, 0, sub and 20 or 38), Text = text, Font = FONT.Text, TextSize = 14,
            TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
        if sub then
            New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 27),
                Size = UDim2.new(1, -70, 0, 16), Text = sub, Font = FONT.Reg, TextSize = 11,
                TextColor3 = TH.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
        end
    end

    local function Toggle(page, label, key, cb, sub)
        local row = Row(page, sub and 50 or 38)
        RowLabel(row, label, sub)
        local track = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(34, 18), BackgroundColor3 = TH.Panel2, BorderSizePixel = 0 }, row)
        Corner(track, 4)
        local ts = New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)
        local knob = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(12, 12), BackgroundColor3 = TH.Sub, BorderSizePixel = 0 }, track)
        Corner(knob, 2)
        local function paint(anim)
            local on = S[key]
            local props = on and { BackgroundColor3 = TH.Accent } or { BackgroundColor3 = TH.Panel2 }
            local pos   = on and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            local kc    = on and TH.Bg or TH.Sub
            local sc    = on and TH.Accent or TH.Line
            if anim then
                Tw(track, 0.2, props); Tw(ts, 0.2, { Color = sc })
                Tw(knob, 0.08, { Size = UDim2.fromOffset(17, 12) })
                task.delay(0.08, function()
                    Tw(knob, 0.28, { Position = pos, Size = UDim2.fromOffset(12, 12), BackgroundColor3 = kc }, Enum.EasingStyle.Back)
                end)
            else
                track.BackgroundColor3 = props.BackgroundColor3; ts.Color = sc
                knob.Position = pos; knob.BackgroundColor3 = kc
            end
        end
        Repaints[#Repaints + 1] = function() paint(true) end
        local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
            ZIndex = 5 }, row)
        hit.Activated:Connect(function()
            S[key] = not S[key]
            paint(true); SaveSettings()
            if cb then cb(S[key]) end
        end)
        paint(false)
    end

    local function Slider(page, label, key, min, max, step, fmt, cb)
        local row = Row(page, 56)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 7), Size = UDim2.new(0.6, 0, 0, 18),
            Text = label, Font = FONT.Text, TextSize = 14, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local val = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 8), Size = UDim2.new(0.4, 0, 0, 16), Text = "", Font = FONT.Mono,
            TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Right }, row)
        local track = New("Frame", { Position = UDim2.fromOffset(8, 40), Size = UDim2.new(1, -16, 0, 2),
            BackgroundColor3 = TH.Line, BorderSizePixel = 0 }, row)
        local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, track)
        local knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 16),
            BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, track)
        Corner(knob, 2)
        local hit = New("TextButton", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1, Text = "", ZIndex = 5 }, row)

        local function paint()
            local a = (S[key] - min) / (max - min)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.fromScale(a, 0.5)
            val.Text = fmt(S[key])
        end
        local lastFire, dragging = 0, false
        local function setX(x)
            local a = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            local v = math.clamp(math.floor((min + a * (max - min)) / step + 0.5) * step, min, max)
            v = tonumber(string.format("%.3f", v))
            if v ~= S[key] then
                S[key] = v; paint(); SaveSettings()
                if cb and os.clock() - lastFire > 0.06 then lastFire = os.clock(); cb(v) end
            end
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local sf = hit:FindFirstAncestorOfClass("ScrollingFrame")
                if sf then sf.ScrollingEnabled = false end
                Tw(knob, 0.15, { Size = UDim2.fromOffset(10, 22) }, Enum.EasingStyle.Back)
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
                Tw(knob, 0.2, { Size = UDim2.fromOffset(8, 16) })
                Tw(val, 0.25, { TextColor3 = TH.Sub })
                if cb then cb(S[key]) end
            end
        end))
        paint()
        return paint
    end

    local function Segmented(page, label, key, options, cb)
        local row = Row(page, 62)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 18),
            Text = label, Font = FONT.Text, TextSize = 14, TextColor3 = TH.Text, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local strip = New("Frame", { Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 24),
            BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, row)
        Corner(strip, 4)
        New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, strip)
        local n = #options
        local hl = New("Frame", { Size = UDim2.new(1 / n, -4, 1, -4), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, strip)
        Corner(hl, 3)
        local btns = {}
        local function paint(anim)
            local idx = 1
            for i, o in ipairs(options) do if o == S[key] then idx = i end end
            local pos = UDim2.new((idx - 1) / n, 2, 0, 2)
            if anim then Tw(hl, 0.28, { Position = pos }, Enum.EasingStyle.Quint) else hl.Position = pos end
            for opt, b in next, btns do
                local c = S[key] == opt and TH.Bg or TH.Sub
                if anim then Tw(b, 0.18, { TextColor3 = c }) else b.TextColor3 = c end
            end
        end
        for i, opt in ipairs(options) do
            local b = New("TextButton", { Position = UDim2.new((i - 1) / n, 0, 0, 0), Size = UDim2.new(1 / n, 0, 1, 0),
                BackgroundTransparency = 1, Text = opt, Font = FONT.Bold, TextSize = 12, TextColor3 = TH.Sub,
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
        local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, page)
        local primary, danger = kind == "primary", kind == "danger"
        local b = New("TextButton", { Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = primary and TH.Accent or TH.Panel, Text = text, Font = FONT.Bold, TextSize = 12,
            TextColor3 = primary and TH.Bg or (danger and TH.Bad or TH.Text), AutoButtonColor = false,
            BorderSizePixel = 0 }, wrap)
        Corner(b, 4)
        local st = New("UIStroke", { Color = danger and TH.Bad or TH.Line, Transparency = danger and 0.55 or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
        local sc = New("UIScale", { Scale = 1 }, b)
        local rest = primary and TH.Accent or TH.Panel
        local hover = primary and TH.Text or TH.Panel2
        b.MouseEnter:Connect(function() Tw(b, 0.12, { BackgroundColor3 = hover }); if not primary then Tw(st, 0.12, { Color = danger and TH.Bad or TH.Dim }) end end)
        b.MouseLeave:Connect(function() Tw(b, 0.2, { BackgroundColor3 = rest }); Tw(sc, 0.2, { Scale = 1 }); if not primary then Tw(st, 0.2, { Color = danger and TH.Bad or TH.Line }) end end)
        b.MouseButton1Down:Connect(function() Tw(sc, 0.07, { Scale = 0.97 }) end)
        b.MouseButton1Up:Connect(function() Tw(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end)
        b.Activated:Connect(cb)
    end

    local function Legend(page)
        local row = Row(page, 38)
        local function item(i, text, col, grad)
            local x = (i - 1) * 0.25
            local sq = New("Frame", { Position = UDim2.new(x, 8, 0.5, -5), Size = UDim2.fromOffset(10, 10),
                BackgroundColor3 = col or Color3.new(1, 1, 1), BorderSizePixel = 0 }, row)
            Corner(sq, 2)
            if grad then
                New("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, RISK_LOW),
                    ColorSequenceKeypoint.new(0.5, RISK_MID), ColorSequenceKeypoint.new(1, RISK_HIGH) }) }, sq)
            end
            New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(x, 24, 0, 0), Size = UDim2.new(0.25, -24, 1, 0),
                Text = text, Font = FONT.Text, TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Left }, row)
        end
        item(1, "Safe", COLOR.Safe); item(2, "Mine", COLOR.Mine); item(3, "Best", COLOR.Best); item(4, "Risk", nil, true)
    end

    local function StatRow(page, label)
        local row = Row(page, 30)
        New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0.4, 0, 1, 0),
            Text = label, Font = FONT.Reg, TextSize = 12, TextColor3 = TH.Sub, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local v = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.6, -8, 1, 0), Text = "—", Font = FONT.Mono,
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
        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = nextOrder() }, page)
        New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, row)
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
    local fab = New("TextButton", { Name = "Toggle", Position = UDim2.new(0, 14, 0.5, -18), Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = TH.Panel, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, Gui)
    Corner(fab, 8)
    local fabStroke = New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, fab)
    local fabCells = {}
    for r = 0, 2 do
        for c = 0, 2 do
            local f = New("Frame", { Position = UDim2.fromOffset(7 + c * 8, 7 + r * 8), Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = TH.Dim, BorderSizePixel = 0 }, fab)
            Corner(f, 1)
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
    fab.MouseEnter:Connect(function() Tw(fabStroke, 0.12, { Color = TH.Sub }) end)
    fab.MouseLeave:Connect(function() Tw(fabStroke, 0.2, { Color = TH.Line }) end)

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
                win.Position = restPos + UDim2.fromOffset(18, 0)
                uiScale.Scale = full * 0.97
            end
            win.Visible = true
            posTw = Tw(win, 0.3, { GroupTransparency = 0, Position = restPos })
            scaleTw = Tw(uiScale, 0.4, { Scale = full }, Enum.EasingStyle.Back)
        else
            scaleTw = Tw(uiScale, 0.2, { Scale = full * 0.98 })
            posTw = Tw(win, 0.2, { GroupTransparency = 1, Position = restPos + UDim2.fromOffset(14, 0) })
            task.delay(0.22, function()
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

    -- ── Live refresh ──
    task.spawn(function()
        while SV.Alive do
            local running = GameRunning.Value
            local col = running and (SV.Solving and TH.Warn or TH.Good) or TH.Dim
            led.BackgroundColor3 = col
            fabCore.BackgroundColor3 = running and TH.Good or TH.Sub
            footState.Text = Tr(running and "ROUND LIVE" or "IDLE")
            footState.TextColor3 = running and TH.Good or TH.Dim

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
