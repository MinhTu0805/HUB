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

-- Flat ink + paper. Colour is reserved for meaning (safe / mine / best), never decoration.
local TH = {
    Bg      = Color3.fromRGB(13, 14, 16),
    Panel   = Color3.fromRGB(19, 21, 24),
    Panel2  = Color3.fromRGB(28, 30, 34),
    Line    = Color3.fromRGB(42, 45, 51),
    Text    = Color3.fromRGB(233, 231, 226),
    Sub     = Color3.fromRGB(143, 146, 153),
    Dim     = Color3.fromRGB(92, 95, 102),
    Accent  = Color3.fromRGB(236, 233, 224),
    Accent2 = Color3.fromRGB(236, 233, 224),
    Good    = Color3.fromRGB(92, 214, 138),
    Bad     = Color3.fromRGB(240, 90, 90),
    Info    = Color3.fromRGB(98, 150, 255),
    Warn    = Color3.fromRGB(246, 190, 84),
}
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
        Name = "Toast", LayoutOrder = ToastSeq, Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = TH.Panel, BorderSizePixel = 0,
        GroupTransparency = 1, ZIndex = 200,
    }, ToastHost)
    New("UICorner", { CornerRadius = UDim.new(0, 5) }, t)
    New("UIStroke", { Color = TH.Line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, t)
    New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 14) }, t)
    local sc = New("UIScale", { Scale = 0.92 }, t)
    local stripe = New("Frame", { Position = UDim2.fromOffset(-16, 0), Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = col, BorderSizePixel = 0 }, t)
    New("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), Text = Tr(text), Font = FONT.Text, TextSize = 14,
        TextColor3 = TH.Text }, t)
    local life = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, -16, 1, 0),
        Size = UDim2.new(1, 30, 0, 2), BackgroundColor3 = col, BackgroundTransparency = 0.55,
        BorderSizePixel = 0 }, t)

    Tw(t, 0.28, { GroupTransparency = 0 })
    Tw(sc, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)
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
SV.Bind = Bind
SV.FONT = FONT
SV.Gui = Gui
SV.IconAsset = IconAsset
SV.LoadLucide = LoadLucide
SV.New = New
SV.TH = TH
SV.Toast = Toast
SV.Tw = Tw
