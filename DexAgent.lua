-- ======================= 1. Load Dex++ ==========================
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-PlusPlus-Decompiler-Fix-206651"))()

-- ======================= 2. AI Agent Script ======================
--[[
    Dex++ AI Agent v3.0 - Tích hợp hoàn toàn vào giao diện Dex++ (không tạo GUI mới)
]]

-- ======================= CẤU HÌNH ==========================
local CONFIG = {
    PROVIDER = "openai",
    API_URL = "https://api.openai.com/v1/chat/completions",
    API_KEY = "sk-...",             -- thay key của bạn
    MODEL = "gpt-3.5-turbo",
    MAX_TOKENS = 800,
    TEMPERATURE = 0.7,
    AUTO_APPROVE = false,
}
-- ================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local THEME = {
    Win  = Color3.fromRGB(37, 47, 57),
    Panel = Color3.fromRGB(47, 57, 67),
    Btn   = Color3.fromRGB(57, 67, 77),
    Text  = Color3.fromRGB(230, 230, 230),
    Dim   = Color3.fromRGB(170, 170, 170),
    Accent = Color3.fromRGB(120, 180, 255),
    AccentHi = Color3.fromRGB(150, 210, 255),
    Err   = Color3.fromRGB(255, 120, 120),
    Warn  = Color3.fromRGB(255, 200, 100),
    UIFont = Enum.Font.SourceSans,
    UIBold = Enum.Font.SourceSansBold,
}

-- ======================= TIỆN ÍCH UI ==========================
local function new(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = obj
end

local function stroke(obj, w, col)
    local s = Instance.new("UIStroke")
    s.Thickness = w or 0.5
    s.Color = col or Color3.fromRGB(60, 60, 60)
    s.Parent = obj
end

local function hoverFx(btn, bg, hover)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hover or THEME.Btn end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = bg or THEME.Panel end)
end

local function trim(s) return tostring(s):gsub("^%s+", ""):gsub("%s+$", "") end
local function cut(s, n) return #s > n and s:sub(1, n) .. "…" or s end

-- ======================= ICON (HÌNH TRÒN "AI") ==========================
local function makeAIIcon(parent, px, color)
    color = color or THEME.AccentHi
    px = math.max(12, px or 16)
    local holder = new("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(0, px, 0, px),
    })
    local bg = new("Frame", {
        Parent = holder, BackgroundColor3 = color, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(bg, px / 2)
    new("TextLabel", {
        Parent = holder, BackgroundTransparency = 1, Text = "AI",
        Font = Enum.Font.GothamBold, TextSize = math.floor(px * 0.6),
        TextColor3 = Color3.fromRGB(20, 20, 30), TextScaled = false,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    return holder
end

-- ======================= DÒ UI DEX++ ==========================
local Dex = { Gui = nil, SearchBox = nil, TabContainer = nil, ContentContainer = nil }

local function scanRoots()
    local roots = {}
    if gethui then roots[#roots + 1] = gethui() end
    pcall(function() if CoreGui.Name then roots[#roots + 1] = CoreGui end end)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then roots[#roots + 1] = pg end
    return roots
end

-- Tìm ô Search
local function findSearchBox()
    for _, root in ipairs(scanRoots()) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, o in ipairs(desc) do
                if o:IsA("TextBox") then
                    local ph = o.PlaceholderText or ""
                    if ph:lower():find("search") and (o.Name == "SearchBox" or ph:lower():find("workspace")) then
                        return o
                    end
                end
            end
        end
    end
end

-- Tìm thanh tab và vùng nội dung
local function findTabAndContent()
    if not Dex.Gui then return end
    local ok, desc = pcall(function() return Dex.Gui:GetDescendants() end)
    if not ok then return end
    local tabContainer, contentContainer
    for _, d in ipairs(desc) do
        -- Tìm container chứa các tab (có UIListLayout và các nút tab)
        if d:IsA("Frame") and d:FindFirstChildWhichIsA("UIListLayout") then
            local tabs = {}
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("TextLabel") then
                    local txt = trim(c.Text or "")
                    if txt == "Explorer" or txt == "Properties" or txt == "Console" or txt == "Notebook" then
                        tabs[#tabs + 1] = c
                    end
                end
            end
            if #tabs >= 2 then
                tabContainer = d
                break
            end
        end
    end
    if not tabContainer then return end

    -- Tìm vùng nội dung: thường là một Frame kế bên hoặc ở dưới thanh tab
    -- Cách đơn giản: tìm Frame lớn nhất trong Dex.Gui (trừ các frame nhỏ)
    local maxArea = 0
    for _, d in ipairs(desc) do
        if d:IsA("Frame") and d.Visible and d ~= tabContainer then
            local s = d.AbsoluteSize
            local area = s.X * s.Y
            if area > maxArea and area > 10000 then
                maxArea = area
                contentContainer = d
            end
        end
    end
    return tabContainer, contentContainer
end

local function waitForDex(timeout)
    local t0 = tick()
    repeat
        local box = findSearchBox()
        if box then
            Dex.SearchBox = box
            Dex.Gui = dexRootOf(box)
            local tc, cc = findTabAndContent()
            if tc and cc then
                Dex.TabContainer = tc
                Dex.ContentContainer = cc
                return true
            end
        end
        task.wait(0.4)
    until tick() - t0 > (timeout or 30)
    return false
end

local function dexRootOf(inst)
    local n = inst
    while n and n.Parent do
        if n:IsA("ScreenGui") or n:IsA("Folder") then return n end
        n = n.Parent
    end
    return inst
end

-- ======================= TẠO TAB "AI AGENT" VÀ KHUNG CHAT ==========================
local W = {} -- lưu các thành phần chat
local streamCancel = false
local streamTimer = nil

local function typewriterEffect(label, text, speed, callback)
    speed = speed or 0.02
    local idx = 0
    streamCancel = false
    if streamTimer then task.cancel(streamTimer) end
    local function typeStep()
        if streamCancel then
            label.Text = text
            if callback then callback() end
            return
        end
        idx = idx + 1
        label.Text = text:sub(1, idx)
        if idx < #text then
            streamTimer = task.delay(speed, typeStep)
        else
            if callback then callback() end
        end
    end
    typeStep()
end

local function setupAITab()
    if not Dex.TabContainer or not Dex.ContentContainer then
        print("[AI Agent] Không tìm thấy thanh tab hoặc vùng nội dung của Dex++")
        return
    end

    -- Kiểm tra nếu đã có tab AI Agent
    for _, c in ipairs(Dex.TabContainer:GetChildren()) do
        if c:IsA("TextButton") and trim(c.Text) == "AI Agent" then
            return -- đã tồn tại
        end
    end

    -- Tìm tab mẫu (ưu tiên "Notebook")
    local templateTab
    for _, c in ipairs(Dex.TabContainer:GetChildren()) do
        if c:IsA("TextButton") and trim(c.Text) == "Notebook" then
            templateTab = c
            break
        end
    end
    if not templateTab then
        -- fallback: lấy tab đầu tiên
        for _, c in ipairs(Dex.TabContainer:GetChildren()) do
            if c:IsA("TextButton") then
                templateTab = c
                break
            end
        end
    end
    if not templateTab then return end

    -- Clone tab
    local newTab = templateTab:Clone()
    newTab.Text = "AI Agent"
    newTab.Name = "AIAgentTab"
    newTab.BackgroundColor3 = THEME.Panel
    newTab.TextColor3 = THEME.Text
    -- Xoá icon cũ (nếu có)
    for _, d in ipairs(newTab:GetDescendants()) do
        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
            d.Image = ""
            d.ImageTransparency = 1
        end
    end
    -- Gắn icon mới
    local icon = makeAIIcon(newTab, 14)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 4, 0.5, 0)

    -- Đặt LayoutOrder để tab xuất hiện cuối cùng
    local maxOrder = 0
    for _, c in ipairs(Dex.TabContainer:GetChildren()) do
        if c:IsA("TextButton") and c.LayoutOrder > maxOrder then
            maxOrder = c.LayoutOrder
        end
    end
    newTab.LayoutOrder = maxOrder + 1
    newTab.Parent = Dex.TabContainer

    -- Tạo khung chat trong vùng nội dung
    local chatFrame = new("Frame", {
        Parent = Dex.ContentContainer,
        Name = "AIAgentChat",
        BackgroundColor3 = THEME.Win,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false, -- sẽ hiển thị khi click tab
        ZIndex = 10,
    })
    W.ChatFrame = chatFrame

    -- Khung hiển thị tin nhắn (ScrollingFrame)
    local messageFrame = new("ScrollingFrame", {
        Parent = chatFrame,
        BackgroundColor3 = THEME.Win,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 10, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = THEME.Dim,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    W.MessageFrame = messageFrame

    new("UIListLayout", {
        Parent = messageFrame,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })

    -- Thanh nhập
    local inputFrame = new("Frame", {
        Parent = chatFrame,
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 1, -34),
    })

    local inputBox = new("TextBox", {
        Parent = inputFrame,
        BackgroundColor3 = THEME.Btn,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -50, 1, -6),
        Position = UDim2.new(0, 3, 0, 3),
        Font = THEME.UIFont,
        TextSize = 13,
        TextColor3 = THEME.Text,
        PlaceholderText = "Nhập lệnh / câu hỏi...",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    corner(inputBox, 3)

    local sendBtn = new("TextButton", {
        Parent = inputFrame,
        Text = "➤",
        Font = THEME.UIBold,
        TextSize = 18,
        TextColor3 = THEME.Accent,
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 34, 1, -6),
        Position = UDim2.new(1, -37, 0, 3),
    })
    corner(sendBtn, 3)
    hoverFx(sendBtn, THEME.Panel, THEME.Btn)

    W.InputBox = inputBox
    W.SendBtn = sendBtn

    -- Hàm thêm tin nhắn
    local function addMessage(role, content)
        local msg = new("Frame", {
            Parent = messageFrame,
            BackgroundColor3 = (role == "user") and THEME.Btn or THEME.Panel,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = messageFrame:GetChildren().Length + 1,
        })
        corner(msg, 4)
        new("UIListLayout", { Parent = msg, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2) })
        local label = new("TextLabel", {
            Parent = msg,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = THEME.UIFont,
            TextSize = 13,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            RichText = true,
            Text = "",
        })
        new("UIPadding", {
            Parent = msg,
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
        })
        return label, msg
    end

    local function displayMessage(role, content, speed)
        if streamCancel then streamCancel = false end
        if streamTimer then task.cancel(streamTimer) end
        local label, msg = addMessage(role, content)
        typewriterEffect(label, content, speed or 0.025, function()
            task.wait(0.05)
            messageFrame.CanvasPosition = Vector2.new(0, messageFrame.CanvasSize.Y.Offset)
        end)
        return label
    end

    W.addMessage = addMessage
    W.displayMessage = displayMessage

    -- Gửi tin nhắn
    local function sendUserMessage(text)
        text = trim(text)
        if text == "" then return end
        displayMessage("user", text, 0)
        inputBox.Text = ""
        task.spawn(function() runAgent(text) end)
    end

    inputBox.FocusLost:Connect(function(enter)
        if enter then sendUserMessage(inputBox.Text) end
    end)
    sendBtn.MouseButton1Click:Connect(function()
        sendUserMessage(inputBox.Text)
    end)

    -- Xử lý click tab: ẩn các nội dung khác, hiện chatFrame
    local oldClick = newTab.MouseButton1Click
    newTab.MouseButton1Click:Connect(function()
        -- Ẩn tất cả các frame con của ContentContainer (trừ chatFrame và các frame khác không phải nội dung)
        for _, child in ipairs(Dex.ContentContainer:GetChildren()) do
            if child:IsA("Frame") and child ~= chatFrame and child.Name ~= "AIAgentChat" then
                child.Visible = false
            end
        end
        chatFrame.Visible = true
        -- Focus vào input
        task.wait(0.1)
        inputBox:CaptureFocus()
    end)

    -- Hiển thị tin nhắn chào
    displayMessage("agent", "👋 **AI Agent** sẵn sàng. Tôi có thể tìm kiếm, đọc/ghi property, gọi method, chạy code...\nGõ **giúp tôi** để xem danh sách tool.", 0.015)

    print("[AI Agent] Đã tạo tab AI Agent trong Dex++")
end

-- ======================= MENU "AI Agent" TRONG NÚT DEX ==========================
local function ensureMenuEntry()
    if not Dex.Gui then return end
    -- Tìm container menu (đã có sẵn hàm findMenuTemplate từ script cũ)
    local tpl = findMenuTemplate()
    if not tpl then return end
    local container = tpl.container
    if container:FindFirstChild("AI Agent") then return end

    local clone = tpl.clone:Clone()
    clone.Name = "AI Agent"
    clone.Text = "AI Agent"
    clone.BackgroundColor3 = THEME.Panel
    clone.TextColor3 = THEME.Text

    for _, c in ipairs(clone:GetDescendants()) do
        if c:IsA("ImageLabel") or c:IsA("ImageButton") then
            c.Image = ""
            c.ImageTransparency = 1
        end
    end
    local icon = makeAIIcon(clone, 16)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 4, 0.5, 0)

    local hit = new("TextButton", {
        Parent = clone, Name = "__AIHit", BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, AutoButtonColor = false,
    })
    hit.MouseButton1Click:Connect(function()
        -- Kích hoạt tab AI Agent
        for _, tab in ipairs(Dex.TabContainer:GetChildren()) do
            if tab:IsA("TextButton") and trim(tab.Text) == "AI Agent" then
                tab.MouseButton1Click:Fire()
                break
            end
        end
    end)

    clone.LayoutOrder = 999
    clone.Parent = container
end

local function addSearchAIButton()
    local box = Dex.SearchBox
    if not box or not box.Parent then return end
    if box.Parent:FindFirstChild("__AISearchBtn") then return end

    local btn = new("TextButton", {
        Parent = box.Parent, Name = "__AISearchBtn", Text = "", AutoButtonColor = false,
        BackgroundColor3 = THEME.Btn, BorderSizePixel = 0, ZIndex = 20,
        Size = UDim2.new(0, 22, 0, 16), Position = UDim2.new(1, -46, 0, 2),
    })
    corner(btn, 2)
    stroke(btn, 0.5, Color3.fromRGB(42, 42, 42))
    local ic = makeAIIcon(btn, 12)
    ic.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Position = UDim2.new(0.5, 0, 0.5, 0)
    hoverFx(btn, THEME.Btn, THEME.Accent)
    btn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Dex.TabContainer:GetChildren()) do
            if tab:IsA("TextButton") and trim(tab.Text) == "AI Agent" then
                tab.MouseButton1Click:Fire()
                break
            end
        end
    end)
end

-- ======================= HÀM TÌM MENU TEMPLATE (giữ nguyên) ==========================
local function findMenuTemplate()
    if not Dex.Gui then return end
    local ok, desc = pcall(function() return Dex.Gui:GetDescendants() end)
    if not ok then return end
    local best
    for _, d in ipairs(desc) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            local txt = trim(d.Text)
            local wants = { "Remote Spy", "Script Viewer", "Explorer", "Console", "Notebook", "Properties" }
            for rank, want in ipairs(wants) do
                if txt == want then
                    local node = d
                    for _ = 1, 6 do
                        local p = node.Parent
                        if not p then break end
                        if p:FindFirstChildWhichIsA("UIListLayout") or p:FindFirstChildWhichIsA("UIGridLayout") then
                            if (not best) or rank < best.rank then
                                best = { container = p, clone = node, rank = rank }
                            end
                            break
                        end
                        node = p
                    end
                end
            end
        end
    end
    return best
end

-- ======================= (CÁC HÀM TOOL, AGENT LOOP, CALL LLM... GIỮ NGUYÊN) ==========================
-- Ở đây bạn giữ nguyên toàn bộ phần TOOLS, resolvePath, callLLM, runAgent, v.v. từ script cũ
-- Tôi sẽ không viết lại để tiết kiệm, nhưng bạn phải chèn vào đây.
-- Lưu ý: trong runAgent, khi cần hiển thị tin nhắn từ agent, dùng W.displayMessage thay vì addBubble.

-- Ví dụ khung:
local TOOLS = {}
-- ... (định nghĩa tools như cũ)

local function resolvePath(path) ... end
local function callLLM(history, systemPrompt) ... end
local function runAgent(query) ... end
local function buildSystemPrompt() ... end

-- ======================= KHỞI ĐỘNG ==========================
local function boot()
    if not waitForDex(10) then
        print("[AI Agent] Không tìm thấy Dex++, tab AI Agent sẽ không hoạt động.")
    end

    -- Tạo tab và chat
    setupAITab()

    -- Chèn menu và nút search
    task.spawn(function()
        while W.ChatFrame and W.ChatFrame.Parent do
            pcall(ensureMenuEntry)
            pcall(addSearchAIButton)
            task.wait(1)
        end
    end)

    -- Nếu chưa có API key, thông báo
    if CONFIG.API_URL == "" or CONFIG.API_KEY == "" then
        W.displayMessage("agent", "⚠️ **Chưa cấu hình API.** Vui lòng điền `API_KEY` và `API_URL` trong script.", 0.01)
    end
end

boot()
