-- ═══ UIBase.lua ═══ Theme, UI helpers, ScreenGui, toasts, Lucide icons
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local Players, Tr, TweenService = SV.Players, SV.Tr, SV.TweenService

-- ─── LUCIDE ICONS ───────────────────────────────────────
-- Loaded from latte-soft/lucide-roblox (Lucide icon set as Roblox spritesheets).
-- If the download fails the UI simply shows tabs without icons.
local Lucide = nil
local function LoadLucide()
    local done = false
    task.spawn(function()
        local ok, lib = pcall(function()
            local src = game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau")
            return loadstring(src)()
        end)
        if ok and type(lib) == "table" and type(lib.GetAsset) == "function" then Lucide = lib end
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < 6 do task.wait(0.05) end
end

-- Returns the first icon name that exists (names may differ between Lucide versions)
local function IconAsset(names)
    if not Lucide then return nil end
    for _, n in ipairs(names) do
        local ok, a = pcall(Lucide.GetAsset, n, 48)
        if ok and type(a) == "table" and a.Id then return a end
    end
    return nil
end

-- ─── SMALL UI HELPERS ───────────────────────────────────
SV.Alive   = true
SV.UIConns = {}
local function Bind(c) SV.UIConns[#SV.UIConns + 1] = c; return c end

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in next, props do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Tw(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- Dark glass: deep blue-black surfaces, one indigo→sky accent for interaction,
-- green / red / blue / amber reserved for meaning (safe / mine / best / caution).
local TH = {
    Bg      = Color3.fromRGB(11, 12, 17),
    Bg2     = Color3.fromRGB(21, 23, 33),     -- top of the window gradient
    Panel   = Color3.fromRGB(21, 23, 31),
    Panel2  = Color3.fromRGB(33, 36, 48),
    Line    = Color3.fromRGB(46, 50, 66),
    Text    = Color3.fromRGB(238, 240, 247),
    Sub     = Color3.fromRGB(152, 158, 176),
    Dim     = Color3.fromRGB(98, 104, 122),
    Accent  = Color3.fromRGB(132, 146, 255),  -- indigo
    Accent2 = Color3.fromRGB(94, 196, 255),   -- sky (gradient partner)
    Good    = Color3.fromRGB(86, 222, 142),
    Bad     = Color3.fromRGB(246, 98, 108),
    Info    = Color3.fromRGB(98, 150, 255),
    Warn    = Color3.fromRGB(250, 192, 92),
}

-- ─── Look helpers (shared by every UI module) ───────────
local function Corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function Round(o) return New("UICorner", { CornerRadius = UDim.new(1, 0) }, o) end
local function Stroke(o, col, transp, thick)
    return New("UIStroke", { Color = col or TH.Line, Transparency = transp or 0, Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
-- two-colour gradient (rot: 0 = left→right, 90 = top→bottom)
local function Grad(o, c0, c1, rot)
    return New("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rot or 0 }, o)
end
-- accent gradient used by switches, sliders, primary buttons
local function AccentGrad(o, rot) return Grad(o, TH.Accent, TH.Accent2, rot or 0) end
-- Press feel: squash on press, springy release (the content stays centred because only UIScale changes)
local function Press(btn, down)
    local sc = btn:FindFirstChildOfClass("UIScale") or New("UIScale", { Scale = 1 }, btn)
    btn.MouseButton1Down:Connect(function() Tw(sc, 0.08, { Scale = down or 0.96 }) end)
    btn.MouseButton1Up:Connect(function() Tw(sc, 0.38, { Scale = 1 }, Enum.EasingStyle.Back) end)
    btn.MouseLeave:Connect(function() Tw(sc, 0.2, { Scale = 1 }) end)
    return sc
end
local FONT = {
    Text = Enum.Font.BuilderSansMedium,
    Bold = Enum.Font.BuilderSansBold,
    Reg  = Enum.Font.BuilderSans,
    Mono = Enum.Font.RobotoMono,
}

local Gui = New("ScreenGui", {
    Name = "BlockermanSolverUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
do
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)
    local parent
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then parent = h end
    if not parent then
        ok, h = pcall(function() return game:GetService("CoreGui") end)
        if ok and h then parent = h end
    end
    local placed = parent and pcall(function() Gui.Parent = parent end)
    if not placed or not Gui.Parent then
        Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- ─── TOASTS (stacked, with a draining life bar) ─────────
local ToastHost = New("Frame", {
    Name = "Toasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18),
    Size = UDim2.fromOffset(360, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, ZIndex = 200,
}, Gui)
New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ToastHost)

local ToastSeq = 0
local function Toast(text, color)
    if not SV.Alive then return end
    ToastSeq += 1
    local col = color or TH.Accent
    local live = {}
    for _, c in ipairs(ToastHost:GetChildren()) do
        if c:IsA("CanvasGroup") then live[#live + 1] = c end
    end
    if #live >= 4 then table.sort(live, function(a, b) return a.LayoutOrder < b.LayoutOrder end); live[1]:Destroy() end

    local t = New("CanvasGroup", {
        Name = "Toast", LayoutOrder = ToastSeq, Size = UDim2.fromOffset(0, 38),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = TH.Panel, BorderSizePixel = 0,
        GroupTransparency = 1, ZIndex = 200,
    }, ToastHost)
    Round(t)
    Stroke(t, col, 0.6)
    New("UIPadding", { PaddingLeft = UDim.new(0, 34), PaddingRight = UDim.new(0, 18) }, t)
    local sc = New("UIScale", { Scale = 0.9 }, t)
    -- status dot (pulses once on entry)
    local dot = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -20, 0.5, 0),
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = col, BorderSizePixel = 0 }, t)
    Round(dot)
    local ring = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1 }, dot)
    Round(ring)
    local rs = Stroke(ring, col, 0.2, 1.5)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), Text = Tr(text), Font = FONT.Text, TextSize = 14,
        TextColor3 = TH.Text }, t)
    -- life bar: thin rounded line along the bottom that drains
    local life = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, -34, 1, 0),
        Size = UDim2.new(1, 52, 0, 2), BackgroundColor3 = col, BackgroundTransparency = 0.45,
        BorderSizePixel = 0 }, t)

    Tw(ring, 0.7, { Size = UDim2.fromOffset(22, 22) })
    Tw(rs, 0.7, { Transparency = 1 })
    Tw(t, 0.28, { GroupTransparency = 0 })
    Tw(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
    Tw(life, 2.6, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(2.6, function()
        if t.Parent then
            Tw(t, 0.25, { GroupTransparency = 1 })
            Tw(sc, 0.25, { Scale = 0.96 })
            task.delay(0.3, function() if t.Parent then t:Destroy() end end)
        end
    end)
end

-- ─── exports ───
SV.AccentGrad = AccentGrad
SV.Bind = Bind
SV.Corner = Corner
SV.FONT = FONT
SV.Gui = Gui
SV.IconAsset = IconAsset
SV.LoadLucide = LoadLucide
SV.Grad = Grad
SV.New = New
SV.Press = Press
SV.Round = Round
SV.Stroke = Stroke
SV.TH = TH
SV.Toast = Toast
SV.Tw = Tw
