-- ═══ Overlay.lua ═══ Overlay part pool + drawing of safe / mine / guess highlights
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local Loading, S, Tw, TweenService = SV.Loading, SV.S, SV.Tw, SV.TweenService

-- ─── VISUALISATION LAYER ────────────────────────────────
Loading.Set(0.64, "Building overlay layer")
local VizFolder = Instance.new("Folder")
VizFolder.Name   = "Solverstone"
VizFolder.Parent = workspace

-- Soft palette (no more neon)
local COLOR = {
    Safe    = Color3.fromRGB(72, 214, 130),
    Mine    = Color3.fromRGB(240, 84, 92),
    Best    = Color3.fromRGB(98, 150, 255),
    Unknown = Color3.fromRGB(255, 200, 80),
}
local RISK_LOW  = Color3.fromRGB(86, 204, 236)
local RISK_MID  = Color3.fromRGB(250, 204, 92)
local RISK_HIGH = Color3.fromRGB(246, 120, 82)

local function ProbColor(p)
    return p < 0.5
        and RISK_LOW:Lerp(RISK_MID, p * 2)
        or  RISK_MID:Lerp(RISK_HIGH, (p - 0.5) * 2)
end

-- Integer RGB key for O(1) palette lookup
local function RGBKey(c)
    return math.round(c.R * 255) * 65536
         + math.round(c.G * 255) * 256
         + math.round(c.B * 255)
end

local function MakeKey(r, g, b) return r * 65536 + g * 256 + b end
local GREEN_KEYS  = { [MakeKey(117,205,100)] = true, [MakeKey(103,180,88)] = true }
local BEIGE_KEYS  = { [MakeKey(255,255,125)] = true, [MakeKey(230,230,113)] = true }

-- ─── PART POOL ──────────────────────────────────────────
SV.Pool     = {}
local Overlays = {}   -- tile → part
SV.DrawKey  = {}   -- tile → state fingerprint
SV.DrawText = {}   -- tile → last text
SV.Pulse    = {}   -- part → looping tween
local Stats    = { solveMs = 0, solves = 0, safe = 0, mine = 0, guess = 0, bestProb = nil }

local function PoolAcquire(tile)
    local vp = table.remove(SV.Pool) or (function()
        local p = Instance.new("Part")
        p.Name       = "SolverViz"
        p.CastShadow = false
        p.Material   = Enum.Material.SmoothPlastic
        p.Transparency = 1
        p.CanCollide = false
        p.CanQuery   = false
        p.CanTouch   = false
        p.Anchored   = true
        local sg = Instance.new("SurfaceGui")
        sg.Name           = "SurfaceGui"
        sg.Face           = Enum.NormalId.Top
        sg.SizingMode     = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg.PixelsPerStud  = 25
        sg.LightInfluence = 0
        sg.Parent         = p

        local body = Instance.new("Frame")
        body.Name = "Body"
        body.AnchorPoint = Vector2.new(0.5, 0.5)
        body.Position    = UDim2.fromScale(0.5, 0.5)
        body.Size        = UDim2.fromScale(1, 1)
        body.BorderSizePixel = 0
        body.BackgroundColor3 = Color3.new(1, 1, 1)
        body.Visible     = false
        body.Parent      = sg
        local corner = Instance.new("UICorner"); corner.Name = "Corner"; corner.Parent = body
        local stroke = Instance.new("UIStroke"); stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = body

        -- best-guess ring (pulses)
        local ring = Instance.new("Frame")
        ring.Name = "Ring"; ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
        ring.Size = UDim2.fromScale(0.74, 0.74); ring.BackgroundTransparency = 1; ring.BorderSizePixel = 0
        ring.Visible = false; ring.Parent = body
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = ring
        local rs = Instance.new("UIStroke"); rs.Name = "RingStroke"; rs.Thickness = 2
        rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rs.Parent = ring

        -- proven-safe dot
        local mark = Instance.new("Frame")
        mark.Name = "Mark"; mark.AnchorPoint = Vector2.new(0.5, 0.5); mark.Position = UDim2.fromScale(0.5, 0.5)
        mark.Size = UDim2.fromScale(0.2, 0.2); mark.BackgroundColor3 = Color3.new(1, 1, 1)
        mark.BackgroundTransparency = 0.1; mark.BorderSizePixel = 0; mark.Visible = false; mark.Parent = body
        local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1, 0); mc.Parent = mark

        -- proven-mine cross
        for i, name in ipairs({ "XA", "XB" }) do
            local x = Instance.new("Frame")
            x.Name = name; x.AnchorPoint = Vector2.new(0.5, 0.5); x.Position = UDim2.fromScale(0.5, 0.5)
            x.Size = UDim2.fromScale(0.58, 0.1); x.Rotation = i == 1 and 45 or -45
            x.BackgroundColor3 = Color3.new(1, 1, 1); x.BackgroundTransparency = 0.08
            x.BorderSizePixel = 0; x.Visible = false; x.Parent = body
            local xc = Instance.new("UICorner"); xc.CornerRadius = UDim.new(1, 0); xc.Parent = x
        end

        local lb = Instance.new("TextLabel")
        lb.Name = "Label"
        lb.BackgroundTransparency = 1
        lb.BorderSizePixel = 0
        lb.Size = UDim2.fromScale(1, 1)
        lb.Font = Enum.Font.RobotoMono
        lb.TextColor3 = Color3.new(1, 1, 1)
        lb.TextSize = 30
        lb.Parent = body
        local ts = Instance.new("UIStroke")
        ts.Name = "TextStroke"; ts.Thickness = 1.5; ts.Color = Color3.fromRGB(10, 10, 14)
        ts.Transparency = 0.5; ts.Parent = lb
        return p
    end)()
    vp.Size     = tile.Size * 0.8
    vp.Position = tile.Position + Vector3.new(0, 1.5, 0)
    vp.Parent   = VizFolder
    return vp
end

local function PoolRelease(vp)
    local pt = SV.Pulse[vp]
    if pt then pt:Cancel(); SV.Pulse[vp] = nil end
    vp.SurfaceGui.Body.Visible = false
    vp.Parent = nil
    table.insert(SV.Pool, vp)
end

-- Applies the current style (Soft / Outline / Dot) to one overlay
local function ApplyStyle(vp, kind, col, text, hidden, isNew)
    local sg = vp.SurfaceGui
    sg.AlwaysOnTop = S.AlwaysOnTop
    local body   = sg.Body
    local stroke = body.Stroke
    local lb     = body.Label
    local ring   = body.Ring

    local pt = SV.Pulse[vp]
    if pt then pt:Cancel(); SV.Pulse[vp] = nil end
    body.Visible = not hidden

    local style = S.Style
    local isPct = text:sub(-1) == "%" or text:sub(1, 1) == "~"
    local fillT, strokeT, strokeW, scale, radius, tsize
    if style == "Outline" then
        fillT, strokeT, strokeW, scale, radius = 0.9, 0, 3, 0.92, UDim.new(0, 8)
        tsize = isPct and 24 or 38
    elseif style == "Dot" then
        fillT, strokeT, strokeW, scale, radius = 1 - math.min(1, S.Opacity + 0.3), 0.15, 2, 0.46, UDim.new(0.5, 0)
        tsize = isPct and 14 or 22
    else
        fillT, strokeT, strokeW, scale, radius = 1 - S.Opacity, 0.3, 2, 0.92, UDim.new(0, 8)
        tsize = isPct and 24 or 38
    end

    -- marks: only the one that belongs to this kind is visible
    body.XA.Visible, body.XB.Visible = kind == "mine", kind == "mine"
    body.Mark.Visible = kind == "safe"
    ring.Visible = kind == "best" and style ~= "Dot"
    ring.RingStroke.Color = col:Lerp(Color3.new(1, 1, 1), 0.35)
    ring.Size = UDim2.fromScale(0.74, 0.74)

    local strokeCol = col:Lerp(Color3.new(1, 1, 1), 0.3)
    local size = UDim2.fromScale(scale, scale)
    body.Corner.CornerRadius = radius
    lb.Text = (kind == "mine" or kind == "safe") and "" or text
    lb.TextSize = tsize
    stroke.Thickness = strokeW

    if isNew and S.Animations then
        body.BackgroundColor3 = col
        stroke.Color = strokeCol
        body.BackgroundTransparency = 1
        stroke.Transparency = 1
        lb.TextTransparency = 1
        body.Size = UDim2.fromScale(scale * 0.6, scale * 0.6)
        Tw(body, 0.26, { BackgroundTransparency = fillT, Size = size }, Enum.EasingStyle.Back)
        Tw(stroke, 0.26, { Transparency = strokeT })
        Tw(lb, 0.26, { TextTransparency = 0 })
    elseif S.Animations then
        Tw(body, 0.16, { BackgroundColor3 = col, BackgroundTransparency = fillT, Size = size })
        Tw(stroke, 0.16, { Color = strokeCol, Transparency = strokeT })
        lb.TextTransparency = 0
    else
        body.BackgroundColor3 = col
        body.BackgroundTransparency = fillT
        body.Size = size
        stroke.Color = strokeCol
        stroke.Transparency = strokeT
        lb.TextTransparency = 0
    end

    if kind == "best" and S.PulseBest and not hidden and ring.Visible then
        local tw = TweenService:Create(ring,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Size = UDim2.fromScale(0.97, 0.97) })
        tw:Play()
        SV.Pulse[vp] = tw
    end
end

local KIND = { mine = 1, safe = 2, guess = 3, best = 4 }

local function Draw(tile, kind, col, text, hidden)
    local key = RGBKey(col) * 16 + KIND[kind] * 2 + (hidden and 1 or 0)
    if SV.DrawKey[tile] == key and SV.DrawText[tile] == text then return end
    local vp    = Overlays[tile]
    local isNew = vp == nil
    if isNew then vp = PoolAcquire(tile); Overlays[tile] = vp end
    SV.DrawKey[tile], SV.DrawText[tile] = key, text
    ApplyStyle(vp, kind, col, text, hidden, isNew)
end

local function Undraw(tile)
    local vp = Overlays[tile]
    if not vp then return end
    PoolRelease(vp)
    Overlays[tile] = nil
    SV.DrawKey[tile]  = nil
    SV.DrawText[tile] = nil
end

local function ClearAll()
    for tile in next, Overlays do Undraw(tile) end
end

-- ─── exports ───
SV.BEIGE_KEYS = BEIGE_KEYS
SV.COLOR = COLOR
SV.ClearAll = ClearAll
SV.Draw = Draw
SV.GREEN_KEYS = GREEN_KEYS
SV.Overlays = Overlays
SV.ProbColor = ProbColor
SV.RGBKey = RGBKey
SV.RISK_HIGH = RISK_HIGH
SV.RISK_LOW = RISK_LOW
SV.RISK_MID = RISK_MID
SV.Stats = Stats
SV.Undraw = Undraw
SV.VizFolder = VizFolder
