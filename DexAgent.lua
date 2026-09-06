--[[
	Dex++ AI Agent  v2.0  (plugin-style, KHÔNG tạo GUI mới)
	==========================================================================
	- Dùng CỬA SỔ của chính Dex++: Lib.Window.new() nếu dò được, nếu không thì
	  CLONE một window có sẵn của Dex (Explorer/Remote Spy/...) -> giữ 100%
	  khung, theme, viền, bo góc của Dex, rồi dựng lại nội dung bên trong.
	- Đổi mục menu "AI Search" -> "AI Agent" (rename tại chỗ, không thêm mục
	  trùng). Icon = glyph vector "✦" tự vẽ => KHÔNG trùng icon Remote Spy.
	- Markdown đầy đủ: heading, bold/italic/strike, inline code, code block +
	  copy, list (bullet/số), quote, hr, link, table (monospace).
	- Stream: bật stream ở API, bóc chunk SSE và phát lại theo nhịp + typewriter.
	- Layout nhỏ gọn, tự co cho mobile & PC.
	- Agent có tool: search Dex, dò cây, đọc/ghi property, gọi method, remote,
	  run Luau, highlight, teleport... ghi/nguy hiểm phải xác nhận.
]]

----------------------------------------------------------------------
-- 0. CONFIG
----------------------------------------------------------------------
local CONFIG = {
	PROVIDER    = "gemini", -- "openai" | "anthropic" | "gemini" | "custom"
	API_URL     = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
	API_KEY     = "",
	MODEL       = "gemini-2.0-flash",
	MAX_TOKENS  = 2048,
	TEMPERATURE = 0.6,
	STREAM      = true,   -- bóc chunk + phát lại theo nhịp
	STREAM_DELAY= 0.012,  -- nhịp typewriter (giây/lần vẽ)
	AUTO_APPROVE= false,  -- true = không hỏi xác nhận khi ghi
	MAX_STEPS   = 8,      -- số bước tool tối đa mỗi yêu cầu
	ICON_ASSET  = "",     -- muốn icon ảnh riêng thì dán "rbxassetid://..." vào đây
	ICON_GLYPH  = "✦",
	SAVE_FILE   = "DexAIAgent.json",
}

----------------------------------------------------------------------
-- 1. SERVICES / UTILS
----------------------------------------------------------------------
local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local HttpService  = game:GetService("HttpService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

local THEME = {
	Win   = Color3.fromRGB(37, 37, 37),
	Panel = Color3.fromRGB(47, 47, 47),
	Btn   = Color3.fromRGB(57, 57, 57),
	Line  = Color3.fromRGB(70, 70, 70),
	Text  = Color3.fromRGB(235, 235, 235),
	Dim   = Color3.fromRGB(160, 160, 160),
	Accent= Color3.fromRGB(70, 100, 170),
	AccentHi = Color3.fromRGB(120, 170, 255),
	Ok    = Color3.fromRGB(120, 200, 130),
	Warn  = Color3.fromRGB(230, 190, 100),
	Err   = Color3.fromRGB(235, 110, 110),
	Code  = Color3.fromRGB(28, 28, 28),
	UI    = Enum.Font.Inconsolata,
	UIBold= Enum.Font.Code,
}

local function new(cls, props)
	local o = Instance.new(cls)
	local par = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do o[k] = v end
	if par then o.Parent = par end
	return o
end
local function corner(o, r) return new("UICorner", { Parent = o, CornerRadius = UDim.new(0, r or 4) }) end
local function stroke(o, t, c)
	return new("UIStroke", { Parent = o, Thickness = t or 1.25, Color = c or THEME.Line,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(o, n)
	return new("UIPadding", { Parent = o, PaddingLeft = UDim.new(0, n), PaddingRight = UDim.new(0, n),
		PaddingTop = UDim.new(0, n), PaddingBottom = UDim.new(0, n) })
end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function cut(s, n)
	s = tostring(s or "")
	return #s > n and (s:sub(1, n) .. "...[cắt]") or s
end
local function hoverFx(b, a, h)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = h }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = a }):Play() end)
end
local function isMobile()
	local cam = workspace.CurrentCamera
	local w = cam and cam.ViewportSize.X or 1280
	return UIS.TouchEnabled and not UIS.MouseEnabled or w < 700
end
local M = isMobile()
local SZ = {
	Text   = M and 14 or 13,
	Small  = M and 12 or 11,
	Row    = M and 30 or 24,
	Bar    = M and 30 or 24,
	Btn    = M and 30 or 22,
}

local function guiParent()
	if gethui then return gethui() end
	local ok = pcall(function() return CoreGui.Name end)
	if ok then return CoreGui end
	return LP:WaitForChild("PlayerGui")
end

local function makeDraggable(handle, target)
	local dragging, startPos, startAbs
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startAbs = true, target.Position, i.Position
			local conn
			conn = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false; conn:Disconnect() end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startAbs
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

----------------------------------------------------------------------
-- 2. ICON RIÊNG (glyph, không lấy từ spritesheet Dex -> không trùng)
----------------------------------------------------------------------
local function makeIcon(parent, px)
	local holder = new("Frame", {
		Parent = parent, Name = "AIAgentIcon", BackgroundTransparency = 1,
		Size = UDim2.new(0, px, 0, px), ZIndex = 60,
	})
	if CONFIG.ICON_ASSET ~= "" then
		new("ImageLabel", {
			Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
			Image = CONFIG.ICON_ASSET, ImageColor3 = THEME.AccentHi, ZIndex = 61,
		})
	else
		new("TextLabel", {
			Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.GothamBold, Text = CONFIG.ICON_GLYPH, TextScaled = true,
			TextColor3 = THEME.AccentHi, ZIndex = 61,
		})
	end
	return holder
end

----------------------------------------------------------------------
-- 3. DÒ DEX++ (Lib + UI + SearchBox)
----------------------------------------------------------------------
local Dex = { Gui = nil, SearchBox = nil, Lib = nil }

local function scanRoots()
	local roots = {}
	if gethui then roots[#roots + 1] = gethui() end
	pcall(function() if CoreGui.Name then roots[#roots + 1] = CoreGui end end)
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if pg then roots[#roots + 1] = pg end
	return roots
end

-- tìm Lib của Dex trong global env (Dex++ thường expose qua getgenv)
local function findDexLib()
	local g = (getgenv and getgenv()) or {}
	local function valid(t)
		return type(t) == "table" and type(t.Window) == "table" and type(t.Window.new) == "function"
	end
	if valid(g.Lib) then return g.Lib end
	for _, v in pairs(g) do
		if type(v) == "table" then
			if valid(v) then return v end
			if valid(rawget(v, "Lib")) then return v.Lib end
		end
	end
	if type(shared) == "table" then
		for _, v in pairs(shared) do
			if type(v) == "table" then
				if valid(v) then return v end
				if valid(rawget(v, "Lib")) then return v.Lib end
			end
		end
	end
	return nil
end

local function findSearchBox()
	for _, root in ipairs(scanRoots()) do
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if ok then
			for _, o in ipairs(desc) do
				if o:IsA("TextBox") then
					local ph = (o.PlaceholderText or ""):lower()
					if ph:find("search") and (o.Name == "SearchBox" or ph:find("workspace") or ph:find("filter")) then
						return o
					end
				end
			end
		end
	end
end

local function dexRootOf(inst)
	local n = inst
	while n and n.Parent do
		if n:IsA("ScreenGui") or (n:IsA("Folder") and n.Parent:IsA("ScreenGui") == false) then return n end
		n = n.Parent
	end
	return inst
end

local function waitForDex(timeout)
	local t0 = tick()
	repeat
		local box = findSearchBox()
		if box then
			Dex.SearchBox = box
			Dex.Gui = dexRootOf(box)
			Dex.Lib = Dex.Lib or findDexLib()
			return true
		end
		task.wait(0.35)
	until tick() - t0 > (timeout or 20)
	Dex.Lib = Dex.Lib or findDexLib()
	return Dex.Gui ~= nil
end

----------------------------------------------------------------------
-- 4. LẤY CỬA SỔ TỪ DEX (Lib.Window.new -> clone -> fallback tối thiểu)
----------------------------------------------------------------------
local WIN_TITLES = { "Remote Spy", "Script Viewer", "Explorer", "Properties", "Console", "Notebook", "Settings" }

local function findDexWindowFrame()
	if not Dex.Gui then return end
	local ok, desc = pcall(function() return Dex.Gui:GetDescendants() end)
	if not ok then return end
	local best, bestScore
	for _, d in ipairs(desc) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
			local txt = trim(d.Text)
			for rank, want in ipairs(WIN_TITLES) do
				if txt == want then
					-- leo lên tìm frame cỡ cửa sổ
					local node = d
					for _ = 1, 8 do
						node = node.Parent
						if not node or not node:IsA("GuiObject") then break end
						if node.AbsoluteSize.X > 200 and node.AbsoluteSize.Y > 120 then
							if (not bestScore) or rank < bestScore then best, bestScore = node, rank end
							break
						end
					end
				end
			end
		end
	end
	return best
end

-- Tạo shell cửa sổ: trả về {Root, Content, SetTitle, Show, Hide, Toggle, Bar}
local function acquireWindow()
	-- (a) API chính chủ của Dex
	if Dex.Lib and Dex.Lib.Window then
		local ok, w = pcall(function() return Dex.Lib.Window.new() end)
		if ok and type(w) == "table" then
			local content
			pcall(function() content = w.GuiElems and (w.GuiElems.Content or w.GuiElems.Main) end)
			if not content then pcall(function() content = w.Main end) end
			if typeof(content) == "Instance" and content:IsA("GuiObject") then
				pcall(function() w:SetTitle("AI Agent") end)
				pcall(function() w:Resize(M and 340 or 520, M and 400 or 400) end)
				for _, c in ipairs(content:GetChildren()) do
					if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
						c:Destroy()
					end
				end
				return {
					Kind = "lib", Root = content, Content = content, Handle = w,
					Show = function() pcall(function() w:Show() end) end,
					Hide = function() pcall(function() w:Hide() end) end,
					Toggle = function()
						local vis = content.Visible
						if vis then pcall(function() w:Hide() end) else pcall(function() w:Show() end) end
					end,
				}
			end
		end
	end

	-- (b) clone cửa sổ Dex có sẵn -> giữ nguyên khung/theme
	local src = findDexWindowFrame()
	if src then
		local ok, clone = pcall(function() return src:Clone() end)
		if ok and clone then
			clone.Name = "AIAgentWindow"
			clone.Visible = true
			clone.ZIndex = 500
			-- xác định thanh tiêu đề (child cao <= 34 nằm trên cùng)
			local bar
			for _, c in ipairs(clone:GetChildren()) do
				if c:IsA("GuiObject") and c.Size.Y.Offset > 0 and c.Size.Y.Offset <= 34 and c.Position.Y.Scale == 0 then
					bar = c; break
				end
			end
			-- dọn ruột, giữ bar + UI modifiers
			for _, c in ipairs(clone:GetChildren()) do
				if c ~= bar and not (c:IsA("UICorner") or c:IsA("UIStroke") or c:IsA("UIPadding")) then
					c:Destroy()
				end
			end
			local barH = bar and bar.AbsoluteSize.Y or 0
			if bar then
				-- dọn ruột bar, dựng lại tiêu đề của mình
				for _, c in ipairs(bar:GetDescendants()) do
					if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("ImageLabel") or c:IsA("ImageButton") then
						pcall(function() c:Destroy() end)
					end
				end
				barH = math.max(barH, SZ.Bar)
				bar.Size = UDim2.new(1, 0, 0, barH)
				makeDraggable(bar, clone)
			else
				bar = new("Frame", {
					Parent = clone, Name = "TitleBar", BackgroundColor3 = THEME.Panel,
					BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, SZ.Bar), ZIndex = 5,
				})
				barH = SZ.Bar
				makeDraggable(bar, clone)
			end
			clone.ClipsDescendants = true
			clone.Size = UDim2.new(0, M and 340 or 520, 0, 400)
			clone.Position = UDim2.new(0.5, M and -170 or -260, 0.5, -200)
			clone.Parent = src.Parent

			local content = new("Frame", {
				Parent = clone, Name = "Body", BackgroundColor3 = THEME.Win, BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, barH), Size = UDim2.new(1, 0, 1, -barH), ZIndex = 2,
			})
			return {
				Kind = "clone", Root = clone, Content = content, Bar = bar,
				Show = function() clone.Visible = true end,
				Hide = function() clone.Visible = false end,
				Toggle = function() clone.Visible = not clone.Visible end,
			}
		end
	end

	-- (c) fallback tối thiểu (chỉ khi Dex chưa mở window nào)
	local sg = guiParent():FindFirstChild("DexAIAgentHost") or new("ScreenGui", {
		Name = "DexAIAgentHost", ResetOnSpawn = false, DisplayOrder = 99999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent(),
	})
	local main = new("Frame", {
		Parent = sg, Name = "AIAgentWindow", BackgroundColor3 = THEME.Win, BorderSizePixel = 0,
		Size = UDim2.new(0, M and 340 or 520, 0, 400),
		Position = UDim2.new(0.5, M and -170 or -260, 0.5, -200), ClipsDescendants = true,
	})
	corner(main, 5); stroke(main, 1.25)
	local bar = new("Frame", {
		Parent = main, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, SZ.Bar),
	})
	makeDraggable(bar, main)
	local content = new("Frame", {
		Parent = main, Name = "Body", BackgroundColor3 = THEME.Win, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, SZ.Bar), Size = UDim2.new(1, 0, 1, -SZ.Bar),
	})
	return {
		Kind = "fallback", Root = main, Content = content, Bar = bar,
		Show = function() main.Visible = true end,
		Hide = function() main.Visible = false end,
		Toggle = function() main.Visible = not main.Visible end,
	}
end

----------------------------------------------------------------------
-- 5. MARKDOWN RENDERER (RichText)
----------------------------------------------------------------------
local MD = {}

local function escXml(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function MD.inline(s)
	s = tostring(s or "")
	-- bảo vệ inline code trước
	local slots = {}
	s = s:gsub("`([^`\n]+)`", function(c)
		slots[#slots + 1] = c
		return "\1" .. #slots .. "\1"
	end)
	s = escXml(s)
	s = s:gsub("%[([^%]]+)%]%(([^%)]+)%)", '<u><font color="#7aaaff">%1</font></u>')
	s = s:gsub("%*%*%*(.-)%*%*%*", "<b><i>%1</i></b>")
	s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	s = s:gsub("__(.-)__", "<b>%1</b>")
	s = s:gsub("%*([^%*\n]+)%*", "<i>%1</i>")
	s = s:gsub("_([^_\n]+)_", "<i>%1</i>")
	s = s:gsub("~~(.-)~~", "<s>%1</s>")
	s = s:gsub("\1(%d+)\1", function(i)
		return '<font color="#f0c674" face="RobotoMono">' .. escXml(slots[tonumber(i)]) .. "</font>"
	end)
	return s
end

local function mdLabel(parent, rich, size, color, indent, bold)
	return new("TextLabel", {
		Parent = parent, BackgroundTransparency = 1, RichText = true,
		Font = bold and THEME.UIBold or THEME.UI, TextSize = size or SZ.Text,
		TextColor3 = color or THEME.Text, Text = rich, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -(indent or 0), 0, 0), Position = UDim2.new(0, indent or 0, 0, 0),
	})
end

local function mdCode(parent, code, lang)
	local box = new("Frame", {
		Parent = parent, BackgroundColor3 = THEME.Code, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	corner(box, 4); stroke(box, 1, Color3.fromRGB(60, 60, 60))
	local head = new("Frame", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
	})
	new("TextLabel", {
		Parent = head, BackgroundTransparency = 1, Size = UDim2.new(1, -46, 1, 0),
		Position = UDim2.new(0, 6, 0, 0), Font = THEME.UI, TextSize = SZ.Small,
		TextColor3 = THEME.Dim, Text = (lang ~= "" and lang or "code"),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local cp = new("TextButton", {
		Parent = head, BackgroundColor3 = THEME.Btn, BorderSizePixel = 0, Text = "copy",
		Font = THEME.UI, TextSize = SZ.Small, TextColor3 = THEME.Text, AutoButtonColor = false,
		Size = UDim2.new(0, 38, 0, 14), Position = UDim2.new(1, -42, 0, 1),
	})
	corner(cp, 3); hoverFx(cp, THEME.Btn, THEME.Accent)
	cp.MouseButton1Click:Connect(function()
		local set = setclipboard or toclipboard or (Clipboard and Clipboard.set)
		if set then pcall(set, code); cp.Text = "ok" else cp.Text = "x" end
		task.delay(1, function() if cp and cp.Parent then cp.Text = "copy" end end)
	end)
	local lbl = new("TextLabel", {
		Parent = box, BackgroundTransparency = 1, RichText = false,
		Font = Enum.Font.RobotoMono, TextSize = SZ.Small + 1, TextColor3 = Color3.fromRGB(215, 225, 215),
		Text = code, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 6, 0, 18), Size = UDim2.new(1, -12, 0, 0),
	})
	new("UIPadding", { Parent = box, PaddingBottom = UDim.new(0, 22) })
	return box
end

-- render markdown vào 1 container có UIListLayout
function MD.render(parent, text)
	for _, c in ipairs(parent:GetChildren()) do
		if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then c:Destroy() end
	end
	local lines = {}
	for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end

	local para, quote, tbl = {}, {}, {}
	local function flushPara()
		if #para > 0 then mdLabel(parent, MD.inline(table.concat(para, " ")), SZ.Text); para = {} end
	end
	local function flushQuote()
		if #quote > 0 then
			local box = new("Frame", {
				Parent = parent, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			})
			corner(box, 3)
			new("Frame", { Parent = box, BackgroundColor3 = THEME.AccentHi, BorderSizePixel = 0,
				Size = UDim2.new(0, 2, 1, 0) })
			local l = mdLabel(box, MD.inline(table.concat(quote, " ")), SZ.Text, THEME.Dim, 8)
			l.Size = UDim2.new(1, -14, 0, 0)
			new("UIPadding", { Parent = box, PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) })
			quote = {}
		end
	end
	local function flushTable()
		if #tbl > 0 then mdCode(parent, table.concat(tbl, "\n"), "table"); tbl = {} end
	end
	local function flushAll() flushPara(); flushQuote(); flushTable() end

	local i = 1
	while i <= #lines do
		local ln = lines[i]
		local fence, lang = ln:match("^%s*```+%s*(.-)%s*$"), nil
		if ln:match("^%s*```") then
			lang = trim(ln:match("^%s*```+(.*)$") or "")
			flushAll()
			local buf = {}
			i = i + 1
			while i <= #lines and not lines[i]:match("^%s*```") do
				buf[#buf + 1] = lines[i]; i = i + 1
			end
			mdCode(parent, table.concat(buf, "\n"), lang)
			i = i + 1
		elseif ln:match("^%s*$") then
			flushAll(); i = i + 1
		elseif ln:match("^%s*[-*_]%s*[-*_]%s*[-*_][-*_%s]*$") then
			flushAll()
			new("Frame", { Parent = parent, BackgroundColor3 = THEME.Line, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1) })
			i = i + 1
		elseif ln:match("^%s*#+%s") then
			flushAll()
			local hashes, txt = ln:match("^%s*(#+)%s+(.*)$")
			local lvl = #hashes
			local size = (lvl == 1 and SZ.Text + 5) or (lvl == 2 and SZ.Text + 3) or (SZ.Text + 1)
			mdLabel(parent, MD.inline(txt), size, THEME.Text, 0, true)
			i = i + 1
		elseif ln:match("^%s*>%s?") then
			flushPara(); flushTable()
			quote[#quote + 1] = ln:gsub("^%s*>%s?", "")
			i = i + 1
		elseif ln:match("^%s*[-*+]%s+") or ln:match("^%s*%d+[%.%)]%s+") then
			flushPara(); flushQuote(); flushTable()
			local lead = #(ln:match("^(%s*)") or "")
			local bullet, body = ln:match("^%s*([-*+])%s+(.*)$")
			if not bullet then
				local num, b2 = ln:match("^%s*(%d+)[%.%)]%s+(.*)$")
				bullet, body = num .. ".", b2
			else
				bullet = "•"
			end
			local row = new("Frame", { Parent = parent, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
			new("TextLabel", {
				Parent = row, BackgroundTransparency = 1, Font = THEME.UI, TextSize = SZ.Text,
				TextColor3 = THEME.AccentHi, Text = bullet, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Position = UDim2.new(0, 6 + lead * 6, 0, 0), Size = UDim2.new(0, 16, 0, SZ.Text + 4),
			})
			local l = mdLabel(row, MD.inline(body), SZ.Text, THEME.Text, 24 + lead * 6)
			l.Size = UDim2.new(1, -(26 + lead * 6), 0, 0)
			i = i + 1
		elseif ln:find("|") and ln:gsub("[^|]", ""):len() >= 2 then
			flushPara(); flushQuote()
			tbl[#tbl + 1] = ln
			i = i + 1
		else
			flushQuote(); flushTable()
			para[#para + 1] = trim(ln)
			i = i + 1
		end
	end
	flushAll()
end

----------------------------------------------------------------------
-- 6. HTTP + PROVIDER + STREAM
----------------------------------------------------------------------
local doRequest = (function()
	local c = { (syn and syn.request), (http and http.request), http_request, request,
		(fluxus and fluxus.request), (getgenv and getgenv().http_request) }
	for _, f in ipairs(c) do if type(f) == "function" then return f end end
end)()

local function buildCall(history, systemPrompt, wantStream)
	local url, headers = CONFIG.API_URL, { ["Content-Type"] = "application/json" }
	local body
	local p = CONFIG.PROVIDER

	if p == "anthropic" then
		headers["x-api-key"] = CONFIG.API_KEY
		headers["anthropic-version"] = "2023-06-01"
		local msgs = {}
		for _, m in ipairs(history) do msgs[#msgs + 1] = { role = m.role, content = m.content } end
		body = { model = CONFIG.MODEL, max_tokens = CONFIG.MAX_TOKENS, temperature = CONFIG.TEMPERATURE,
			system = systemPrompt, messages = msgs, stream = wantStream or nil }

	elseif p == "gemini" then
		if wantStream then
			url = url:gsub(":generateContent", ":streamGenerateContent")
			if not url:find("alt=sse") then url = url .. (url:find("%?") and "&" or "?") .. "alt=sse" end
		end
		if not url:find("key=") then
			url = url .. (url:find("%?") and "&" or "?") .. "key=" .. CONFIG.API_KEY
		end
		local contents = {}
		for _, m in ipairs(history) do
			contents[#contents + 1] = { role = (m.role == "assistant") and "model" or "user",
				parts = { { text = m.content } } }
		end
		body = { contents = contents, systemInstruction = { parts = { { text = systemPrompt } } },
			generationConfig = { temperature = CONFIG.TEMPERATURE, maxOutputTokens = CONFIG.MAX_TOKENS } }

	else
		headers["Authorization"] = "Bearer " .. tostring(CONFIG.API_KEY)
		local msgs = { { role = "system", content = systemPrompt } }
		for _, m in ipairs(history) do msgs[#msgs + 1] = { role = m.role, content = m.content } end
		body = { model = CONFIG.MODEL, max_tokens = CONFIG.MAX_TOKENS, temperature = CONFIG.TEMPERATURE,
			messages = msgs, stream = wantStream or nil }
	end
	return url, headers, HttpService:JSONEncode(body)
end

-- bóc các chunk SSE thành list delta text
local function parseSSE(raw)
	local out = {}
	for line in (raw .. "\n"):gmatch("(.-)\n") do
		local data = line:match("^data:%s*(.+)$")
		if data and trim(data) ~= "[DONE]" then
			local ok, d = pcall(function() return HttpService:JSONDecode(data) end)
			if ok and type(d) == "table" then
				local t
				if d.choices and d.choices[1] then
					local ch = d.choices[1]
					t = (ch.delta and ch.delta.content) or ch.text
				elseif d.delta and d.delta.text then
					t = d.delta.text
				elseif d.candidates and d.candidates[1] and d.candidates[1].content
					and d.candidates[1].content.parts and d.candidates[1].content.parts[1] then
					t = d.candidates[1].content.parts[1].text
				end
				if type(t) == "string" and t ~= "" then out[#out + 1] = t end
			end
		end
	end
	return out
end

local function parseReply(raw)
	local ok, d = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or type(d) ~= "table" then
		local chunks = parseSSE(raw)
		if #chunks > 0 then return table.concat(chunks) end
		return nil, "JSON không hợp lệ: " .. cut(raw, 240)
	end
	if d.error then
		local e = d.error
		return nil, "API error: " .. tostring(type(e) == "table" and (e.message or HttpService:JSONEncode(e)) or e)
	end
	if d.choices and d.choices[1] then
		local c = d.choices[1]
		if c.message and c.message.content then return c.message.content end
		if c.text then return c.text end
	end
	if d.content and d.content[1] and d.content[1].text then return d.content[1].text end
	if d.candidates and d.candidates[1] and d.candidates[1].content
		and d.candidates[1].content.parts and d.candidates[1].content.parts[1] then
		return d.candidates[1].content.parts[1].text
	end
	if d.result then return d.result end
	if d.output_text then return d.output_text end
	if type(d) == "table" and d[1] then -- gemini non-sse array
		local buf = {}
		for _, part in ipairs(d) do
			pcall(function() buf[#buf + 1] = part.candidates[1].content.parts[1].text end)
		end
		if #buf > 0 then return table.concat(buf) end
	end
	return nil, "Không nhận diện được phản hồi: " .. cut(raw, 240)
end

-- gọi API; onDelta(chunk) sẽ được gọi liên tục để "stream"
local function callLLM(history, systemPrompt, onDelta)
	if CONFIG.API_URL == "" or (CONFIG.PROVIDER ~= "custom" and CONFIG.API_KEY == "") then
		return nil, "Chưa cấu hình API (bấm ⚙ để điền URL / KEY / MODEL)"
	end
	if not doRequest then return nil, "Executor không hỗ trợ HTTP request" end

	local wantStream = CONFIG.STREAM and onDelta ~= nil
	local url, headers, body = buildCall(history, systemPrompt, wantStream)
	local ok, res = pcall(doRequest, { Url = url, Method = "POST", Headers = headers, Body = body })
	if not ok then return nil, "Request lỗi: " .. tostring(res) end

	local code = res.StatusCode or res.status_code or 0
	local raw = res.Body or res.body or ""
	if code >= 400 then return nil, ("HTTP %d: %s"):format(code, cut(raw, 300)) end
	if raw == "" then return nil, "Phản hồi rỗng" end

	if wantStream then
		local chunks = parseSSE(raw)
		if #chunks > 0 then
			local full = {}
			for _, c in ipairs(chunks) do
				full[#full + 1] = c
				onDelta(c)
				task.wait(CONFIG.STREAM_DELAY)
			end
			return table.concat(full)
		end
	end

	local text, err = parseReply(raw)
	if not text then return nil, err end
	if onDelta then -- không có SSE -> typewriter theo cụm 4 ký tự
		local i = 1
		while i <= #text do
			onDelta(text:sub(i, i + 3))
			i = i + 4
			if i % 40 < 4 then task.wait(CONFIG.STREAM_DELAY) end
		end
	end
	return text
end

----------------------------------------------------------------------
-- 7. PATH / VALUE HELPERS
----------------------------------------------------------------------
local refs, refN = {}, 0
local function addRef(inst) refN = refN + 1; refs[refN] = inst; return refN end

local function fullName(inst)
	local ok, n = pcall(function() return inst:GetFullName() end)
	return ok and n or tostring(inst)
end

local COMMON_PROPS = {
	"Name", "ClassName", "Position", "Size", "CFrame", "Anchored", "CanCollide", "Transparency",
	"Color", "Material", "Value", "Text", "Visible", "Enabled", "Health", "MaxHealth",
	"WalkSpeed", "JumpPower", "Locked", "Adornee", "Brightness", "Volume", "Source",
}

local function tokenizePath(path)
	local out, i = {}, 1
	path = tostring(path)
	while i <= #path do
		local ch = path:sub(i, i)
		if ch == "." then
			i = i + 1
		elseif ch == "[" then
			local q = path:sub(i + 1, i + 1)
			if q == '"' or q == "'" then
				local e = path:find(q .. "]", i + 2, true)
				if not e then break end
				out[#out + 1] = path:sub(i + 2, e - 1); i = e + 2
			else
				local e = path:find("]", i + 1, true)
				if not e then break end
				out[#out + 1] = path:sub(i + 1, e - 1); i = e + 1
			end
		else
			local e = path:find("[%.%[]", i)
			if e then out[#out + 1] = path:sub(i, e - 1); i = e
			else out[#out + 1] = path:sub(i); break end
		end
	end
	return out
end

local function resolvePath(path)
	path = trim(path)
	if path == "" then return nil, "path rỗng" end
	if path:sub(1, 1) == "#" then
		local id = tonumber(path:sub(2))
		local inst = id and refs[id]
		if not inst then return nil, "ref không hợp lệ: " .. path end
		local alive = false
		pcall(function() alive = inst.Parent ~= nil or inst == game end)
		if not alive then return nil, "ref đã bị xoá: " .. path end
		return inst
	end
	local toks = tokenizePath(path)
	local cur, start = game, 1
	if toks[1] and toks[1]:lower() == "game" then start = 2 end
	for k = start, #toks do
		local t = toks[k]
		if t == "" then continue end
		local nxt
		if t == "LocalPlayer" then
			nxt = LP
		elseif cur == game then
			pcall(function() nxt = game:GetService(t) end)
			if not nxt then nxt = cur:FindFirstChild(t) end
		else
			nxt = cur:FindFirstChild(t)
			if not nxt then
				local ok, v = pcall(function() return cur[t] end)
				if ok and typeof(v) == "Instance" then nxt = v end
			end
		end
		if not nxt then return nil, ("không tìm thấy '%s' trong %s"):format(t, fullName(cur)) end
		cur = nxt
	end
	return cur
end

local function encodeValue(v)
	local t = typeof(v)
	if t == "Vector3" then return { x = v.X, y = v.Y, z = v.Z }
	elseif t == "Vector2" then return { x = v.X, y = v.Y }
	elseif t == "CFrame" then return { x = v.X, y = v.Y, z = v.Z, look = tostring(v.LookVector) }
	elseif t == "Color3" then return { r = math.floor(v.R * 255), g = math.floor(v.G * 255), b = math.floor(v.B * 255) }
	elseif t == "UDim2" then return tostring(v)
	elseif t == "EnumItem" then return "Enum." .. tostring(v.EnumType) .. "." .. v.Name
	elseif t == "Instance" then return fullName(v) .. " (#" .. addRef(v) .. ")"
	elseif t == "BrickColor" then return v.Name
	elseif t == "number" or t == "string" or t == "boolean" then return v
	elseif t == "table" then return v
	end
	return tostring(v)
end

local function parseValue(v)
	if type(v) == "string" then
		local a, b = v:match("^Enum%.(%w+)%.(%w+)$")
		if a and b then
			local ok, e = pcall(function() return Enum[a][b] end)
			if ok then return e end
		end
		return v
	elseif type(v) == "table" then
		if v.x and v.y and v.z then return Vector3.new(v.x, v.y, v.z) end
		if v.r and v.g and v.b then return Color3.fromRGB(v.r, v.g, v.b) end
		if #v == 3 then return Vector3.new(v[1], v[2], v[3]) end
		if #v == 2 then return Vector2.new(v[1], v[2]) end
	end
	return v
end

local function okRes(t) t = t or {}; t.ok = true; return t end
local function errRes(m) return { ok = false, error = tostring(m) } end

----------------------------------------------------------------------
-- 8. UI BÊN TRONG (nhỏ gọn, responsive)
----------------------------------------------------------------------
local W = { Win = nil, Chat = nil, Input = nil, Status = nil, Live = nil }
local openAgentWindow, runAgent

local function setStatus(txt, col)
	if W.Status then
		W.Status.Text = txt or ""
		W.Status.TextColor3 = col or THEME.Dim
	end
end

local function scrollBottom()
	if not W.Chat then return end
	task.defer(function()
		if W.Chat and W.Chat.Parent then
			W.Chat.CanvasPosition = Vector2.new(0, math.max(0, W.Chat.AbsoluteCanvasSize.Y))
		end
	end)
end

-- bong bóng: kind = user | agent | tool | error
local function addBubble(kind, text)
	if not W.Chat then return end
	local isUser = kind == "user"
	local bg = isUser and THEME.Accent or (kind == "error" and Color3.fromRGB(70, 40, 40))
		or (kind == "tool" and Color3.fromRGB(42, 46, 42) or THEME.Panel)
	local holder = new("Frame", {
		Parent = W.Chat, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	local box = new("Frame", {
		Parent = holder, BackgroundColor3 = bg, BorderSizePixel = 0,
		Size = UDim2.new(isUser and 0.86 or 0.97, 0, 0, 0),
		Position = UDim2.new(isUser and 0.14 or 0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	corner(box, 4); stroke(box, 1, Color3.fromRGB(60, 60, 60))
	local inner = new("Frame", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	pad(inner, 6)
	new("UIListLayout", { Parent = inner, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
	if kind == "tool" then
		new("TextLabel", { Parent = inner, BackgroundTransparency = 1, Font = THEME.UIBold,
			TextSize = SZ.Small, TextColor3 = THEME.Ok, Text = "tool", TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, SZ.Small + 2) })
	end
	if isUser or kind == "tool" then
		mdLabel(inner, MD.inline(text), SZ.Text, isUser and Color3.new(1, 1, 1) or THEME.Dim)
	else
		MD.render(inner, text)
	end
	scrollBottom()
	return inner
end

-- bong bóng stream: trả về hàm append/finish
local function addStreamBubble()
	local inner = addBubble("agent", "")
	local buf, last, dirty = {}, 0, false
	local alive = true
	task.spawn(function()
		while alive do
			if dirty and tick() - last > 0.08 then
				dirty = false; last = tick()
				MD.render(inner, table.concat(buf))
				scrollBottom()
			end
			task.wait(0.03)
		end
	end)
	return {
		append = function(s)
			buf[#buf + 1] = s
			dirty = true
		end,
		set = function(s)
			buf = { s }; dirty = true
		end,
		finish = function(finalText)
			alive = false
			MD.render(inner, finalText or table.concat(buf))
			scrollBottom()
		end,
		holder = inner,
	}
end

-- lấy phần "final" đang stream dở từ JSON chưa hoàn chỉnh
local function partialFinal(buf)
	local s = buf:find('"final"')
	if not s then return nil end
	local q = buf:find('"', buf:find(":", s) or s)
	if not q then return nil end
	local out, i, esc = {}, q + 1, false
	while i <= #buf do
		local ch = buf:sub(i, i)
		if esc then
			out[#out + 1] = (ch == "n" and "\n") or (ch == "t" and "\t") or ch
			esc = false
		elseif ch == "\\" then esc = true
		elseif ch == '"' then break
		else out[#out + 1] = ch end
		i = i + 1
	end
	return table.concat(out)
end

-- hộp xác nhận (nằm TRONG cửa sổ Dex, không tạo gui mới)
local function askConfirm(title, detail, cb)
	local body = W.Win.Content
	local ov = new("Frame", {
		Parent = body, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 200,
	})
	local box = new("Frame", {
		Parent = ov, BackgroundColor3 = THEME.Win, BorderSizePixel = 0, ZIndex = 201,
		Size = UDim2.new(0.9, 0, 0, 150), Position = UDim2.new(0.05, 0, 0.5, -75),
	})
	corner(box, 4); stroke(box, 1.25)
	new("TextLabel", { Parent = box, BackgroundTransparency = 1, Font = THEME.UIBold, TextSize = SZ.Text,
		TextColor3 = THEME.Warn, Text = "Xác nhận: " .. title, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0, 18), ZIndex = 202, TextTruncate = Enum.TextTruncate.AtEnd })
	local d = new("TextLabel", { Parent = box, BackgroundColor3 = THEME.Code, BorderSizePixel = 0,
		Font = Enum.Font.RobotoMono, TextSize = SZ.Small, TextColor3 = THEME.Dim, Text = cut(detail, 400),
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 8, 0, 26), Size = UDim2.new(1, -16, 0, 78), ZIndex = 202 })
	corner(d, 3)
	local function mk(txt, x, col, val)
		local b = new("TextButton", { Parent = box, BackgroundColor3 = col, BorderSizePixel = 0, Text = txt,
			Font = THEME.UIBold, TextSize = SZ.Text, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
			Size = UDim2.new(0.44, 0, 0, SZ.Btn), Position = UDim2.new(x, 0, 1, -(SZ.Btn + 8)), ZIndex = 202 })
		corner(b, 3)
		b.MouseButton1Click:Connect(function() ov:Destroy(); cb(val) end)
		return b
	end
	mk("Cho phép", 0.03, THEME.Accent, true)
	mk("Từ chối", 0.53, Color3.fromRGB(90, 50, 50), false)
end

-- panel settings (trong cửa sổ)
local function buildSettings(body)
	local panel = new("Frame", {
		Parent = body, Name = "Settings", BackgroundColor3 = THEME.Win, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 100,
	})
	local sc = new("ScrollingFrame", {
		Parent = panel, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = THEME.Line, ZIndex = 101,
	})
	pad(sc, 8)
	new("UIListLayout", { Parent = sc, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	local function field(label, key, placeholder)
		local h = new("Frame", { Parent = sc, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38) })
		new("TextLabel", { Parent = h, BackgroundTransparency = 1, Font = THEME.UI, TextSize = SZ.Small,
			TextColor3 = THEME.Dim, Text = label, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14) })
		local tb = new("TextBox", { Parent = h, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
			Font = THEME.UI, TextSize = SZ.Text, TextColor3 = THEME.Text, ClearTextOnFocus = false,
			PlaceholderText = placeholder or "", PlaceholderColor3 = Color3.fromRGB(110, 110, 110),
			Text = tostring(CONFIG[key]), TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, SZ.Row - 2) })
		corner(tb, 3); stroke(tb, 1); pad(tb, 4)
		tb.FocusLost:Connect(function()
			local v = trim(tb.Text)
			if type(CONFIG[key]) == "number" then CONFIG[key] = tonumber(v) or CONFIG[key]
			else CONFIG[key] = v end
		end)
		return tb
	end

	field("PROVIDER (openai / anthropic / gemini / custom)", "PROVIDER")
	field("API_URL", "API_URL")
	field("API_KEY", "API_KEY", "sk-... / AIza...")
	field("MODEL", "MODEL")
	field("MAX_TOKENS", "MAX_TOKENS")
	field("TEMPERATURE", "TEMPERATURE")
	field("ICON_ASSET (tuỳ chọn, rbxassetid://...)", "ICON_ASSET")

	local function toggle(label, key)
		local b = new("TextButton", { Parent = sc, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
			Font = THEME.UI, TextSize = SZ.Text, TextColor3 = THEME.Text, AutoButtonColor = false,
			Text = label .. ": " .. (CONFIG[key] and "ON" or "OFF"), Size = UDim2.new(1, 0, 0, SZ.Row) })
		corner(b, 3); stroke(b, 1); hoverFx(b, THEME.Panel, THEME.Btn)
		b.MouseButton1Click:Connect(function()
			CONFIG[key] = not CONFIG[key]
			b.Text = label .. ": " .. (CONFIG[key] and "ON" or "OFF")
		end)
	end
	toggle("Stream", "STREAM")
	toggle("Tự động cho phép ghi", "AUTO_APPROVE")

	local save = new("TextButton", { Parent = sc, BackgroundColor3 = THEME.Accent, BorderSizePixel = 0,
		Font = THEME.UIBold, TextSize = SZ.Text, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
		Text = "Lưu cấu hình", Size = UDim2.new(1, 0, 0, SZ.Row) })
	corner(save, 3)
	save.MouseButton1Click:Connect(function()
		if writefile then
			pcall(function() writefile(CONFIG.SAVE_FILE, HttpService:JSONEncode(CONFIG)) end)
			save.Text = "Đã lưu ✓"
		else
			save.Text = "Executor không có writefile"
		end
		task.delay(1.2, function() if save.Parent then save.Text = "Lưu cấu hình" end end)
	end)
	new("TextLabel", { Parent = sc, BackgroundTransparency = 1, Font = THEME.UI, TextSize = SZ.Small,
		TextColor3 = THEME.Dim, TextWrapped = true, Size = UDim2.new(1, 0, 0, 46),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "openai: /v1/chat/completions · anthropic: /v1/messages · gemini: .../models/<model>:generateContent · custom: backend trả {result=\"...\"}" })
	return panel
end

local function buildInside()
	local win = W.Win
	local body = win.Content
	body.BackgroundColor3 = THEME.Win

	-- tiêu đề: nếu là window clone/fallback thì dựng lại header trên bar của Dex
	if win.Bar then
		local ic = makeIcon(win.Bar, SZ.Bar - 10)
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 6, 0.5, 0)
		new("TextLabel", { Parent = win.Bar, BackgroundTransparency = 1, Font = THEME.UIBold,
			TextSize = SZ.Text, TextColor3 = THEME.Text, Text = "AI Agent",
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 60,
			Position = UDim2.new(0, SZ.Bar + 2, 0, 0), Size = UDim2.new(0.5, 0, 1, 0) })
		local function tb(txt, x, cb, col)
			local b = new("TextButton", { Parent = win.Bar, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
				Text = txt, Font = THEME.UIBold, TextSize = SZ.Text, TextColor3 = col or THEME.Dim,
				AutoButtonColor = false, ZIndex = 60, Size = UDim2.new(0, SZ.Bar, 1, 0),
				Position = UDim2.new(1, x, 0, 0) })
			hoverFx(b, THEME.Panel, THEME.Btn)
			b.MouseButton1Click:Connect(cb)
			return b
		end
		tb("X", -SZ.Bar, function() win.Hide() end, THEME.Err)
	end

	-- vùng chat
	local chat = new("ScrollingFrame", {
		Parent = body, Name = "Chat", BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, -(SZ.Row + 22)),
		ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Line,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	})
	pad(chat, 6)
	new("UIListLayout", { Parent = chat, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	W.Chat = chat

	-- status
	W.Status = new("TextLabel", {
		Parent = body, BackgroundTransparency = 1, Font = THEME.UI, TextSize = SZ.Small,
		TextColor3 = THEME.Dim, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 8, 1, -(SZ.Row + 20)), Size = UDim2.new(1, -16, 0, 16),
	})

	-- hàng input
	local row = new("Frame", {
		Parent = body, BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -SZ.Row - 2), Size = UDim2.new(1, 0, 0, SZ.Row + 2),
	})
	local input = new("TextBox", {
		Parent = row, BackgroundColor3 = THEME.Win, BorderSizePixel = 0, Font = THEME.UI,
		TextSize = SZ.Text, TextColor3 = THEME.Text, ClearTextOnFocus = false,
		PlaceholderText = "Hỏi hoặc ra lệnh cho AI Agent...",
		PlaceholderColor3 = Color3.fromRGB(110, 110, 110), Text = "",
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 4, 0, 2), Size = UDim2.new(1, -(SZ.Btn * 3 + 14), 0, SZ.Row - 2),
	})
	corner(input, 3); stroke(input, 1); pad(input, 5)
	W.Input = input

	local settings = buildSettings(body)

	local function sideBtn(txt, idx, cb, col)
		local b = new("TextButton", {
			Parent = row, BackgroundColor3 = THEME.Btn, BorderSizePixel = 0, Text = txt,
			Font = THEME.UIBold, TextSize = SZ.Text, TextColor3 = col or THEME.Text, AutoButtonColor = false,
			Size = UDim2.new(0, SZ.Btn, 0, SZ.Row - 2),
			Position = UDim2.new(1, -(SZ.Btn * idx + 4 * idx), 0, 2),
		})
		corner(b, 3); hoverFx(b, THEME.Btn, THEME.Accent)
		b.MouseButton1Click:Connect(cb)
		return b
	end
	sideBtn("\u{2699}", 3, function() settings.Visible = not settings.Visible end, THEME.Dim)
	sideBtn("\u{1F5D1}", 2, function()
		for _, c in ipairs(chat:GetChildren()) do
			if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then c:Destroy() end
		end
		setStatus("Đã xoá hội thoại")
	end, THEME.Dim)
	local send = sideBtn("\u{25B6}", 1, function()
		local q = trim(input.Text)
		if q == "" then return end
		input.Text = ""
		runAgent(q)
	end, THEME.AccentHi)

	input.FocusLost:Connect(function(enter)
		if enter then
			local q = trim(input.Text)
			if q ~= "" then input.Text = ""; runAgent(q) end
		end
	end)

	-- responsive: co lại khi cửa sổ nhỏ
	local root = win.Root
	local function relayout()
		local w = root.AbsoluteSize.X
		if w < 300 then
			input.Size = UDim2.new(1, -(SZ.Btn * 2 + 10), 0, SZ.Row - 2)
		else
			input.Size = UDim2.new(1, -(SZ.Btn * 3 + 14), 0, SZ.Row - 2)
		end
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()
end

openAgentWindow = function()
	if W.Win and W.Win.Root and W.Win.Root.Parent then
		W.Win.Show()
		if W.Win.Root:IsA("GuiObject") then W.Win.Root.Visible = true end
		return
	end
	-- dọn tàn dư bản cũ
	local old = guiParent():FindFirstChild("DexAIAgent")
	if old then old:Destroy() end

	W.Win = acquireWindow()
	buildInside()
	W.Win.Show()
	addBubble("agent", "**AI Agent** đã gắn vào Dex++.\n\nMình có thể: dò cây instance, đọc/ghi property, gọi method, liệt kê remote, chạy Luau, highlight, teleport và đẩy query vào ô Search của Dex.\n\n> Hành động ghi luôn hỏi bạn trước.")
	if CONFIG.API_URL == "" or (CONFIG.PROVIDER ~= "custom" and CONFIG.API_KEY == "") then
		addBubble("error", "Chưa có API. Bấm `⚙` để điền **API_URL / API_KEY / MODEL**.")
	end
end

----------------------------------------------------------------------
-- 9. VÁ MENU DEX: "AI Search" -> "AI Agent" + đổi icon
----------------------------------------------------------------------
local function replaceEntryIcon(entry)
	local slot
	for _, c in ipairs(entry:GetDescendants()) do
		if c:IsA("ImageLabel") or c:IsA("ImageButton") then
			slot = slot or c
			c.Image = ""
			c.ImageTransparency = 1
			c.ImageRectOffset = Vector2.new()
			c.ImageRectSize = Vector2.new()
		end
	end
	if entry:FindFirstChild("AIAgentIcon", true) then return end
	local host = slot or entry
	local px = math.clamp(math.floor(math.min(host.AbsoluteSize.X, host.AbsoluteSize.Y)), 12, 22)
	if px < 12 then px = 16 end
	local ic = makeIcon(host, px)
	if slot then
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
	else
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 4, 0.5, 0)
	end
end

local function wireEntry(entry)
	if entry:FindFirstChild("__AIHit") then return end
	local hit = new("TextButton", {
		Parent = entry, Name = "__AIHit", BackgroundTransparency = 1, Text = "",
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 80, AutoButtonColor = false,
	})
	hit.MouseButton1Click:Connect(function() openAgentWindow() end)
end

-- rename mục "AI Search" (bản cũ) thành "AI Agent", KHÔNG thêm mục mới
local function patchMenuEntry()
	if not Dex.Gui then return false end
	local ok, desc = pcall(function() return Dex.Gui:GetDescendants() end)
	if not ok then return false end
	local found = false
	for _, d in ipairs(desc) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
			local t = trim(d.Text)
			if t == "AI Search" or t == "AI Agent" then
				d.Text = "AI Agent"
				-- leo lên tìm "row" của mục
				local row = d
				for _ = 1, 4 do
					local p = row.Parent
					if not p or not p:IsA("GuiObject") then break end
					if p.AbsoluteSize.Y <= 40 and p.AbsoluteSize.X >= d.AbsoluteSize.X then row = p else break end
				end
				replaceEntryIcon(row)
				wireEntry(row)
				found = true
			end
		end
	end
	return found
end

-- nếu không có mục "AI Search" thì clone 1 mục sẵn có làm template (1 lần duy nhất)
local TEMPLATE_NAMES = { "Remote Spy", "Script Viewer", "Console", "Notebook", "Properties", "Explorer" }
local function ensureMenuEntry()
	if patchMenuEntry() then return end
	if not Dex.Gui then return end
	local ok, desc = pcall(function() return Dex.Gui:GetDescendants() end)
	if not ok then return end
	local tplRow, tplParent, bestRank
	for _, d in ipairs(desc) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
			local txt = trim(d.Text)
			for rank, want in ipairs(TEMPLATE_NAMES) do
				if txt == want then
					local node = d
					for _ = 1, 6 do
						local p = node.Parent
						if not p then break end
						if p:FindFirstChildWhichIsA("UIListLayout") or p:FindFirstChildWhichIsA("UIGridLayout") then
							if (not bestRank) or rank < bestRank then
								tplRow, tplParent, bestRank = node, p, rank
							end
							break
						end
						node = p
					end
				end
			end
		end
	end
	if not tplRow or not tplParent then return end
	if tplParent:FindFirstChild("AIAgentEntry") then return end
	local clone = tplRow:Clone()
	clone.Name = "AIAgentEntry"
	for _, c in ipairs(clone:GetDescendants()) do
		if (c:IsA("TextLabel") or c:IsA("TextButton")) and type(c.Text) == "string" and trim(c.Text) ~= "" then
			c.Text = "AI Agent"
		end
	end
	if (clone:IsA("TextLabel") or clone:IsA("TextButton")) and type(clone.Text) == "string" then
		clone.Text = "AI Agent"
	end
	replaceEntryIcon(clone)
	wireEntry(clone)
	clone.LayoutOrder = 999
	clone.Visible = true
	clone.Parent = tplParent
end

local function addSearchAIButton()
	local box = Dex.SearchBox
	if not box or not box.Parent then return end
	if box.Parent:FindFirstChild("__AISearchBtn") then return end
	local btn = new("TextButton", {
		Parent = box.Parent, Name = "__AISearchBtn", Text = "", AutoButtonColor = false,
		BackgroundColor3 = THEME.Btn, BorderSizePixel = 0, ZIndex = 25,
		Size = UDim2.new(0, 22, 0, 16), Position = UDim2.new(1, -46, 0, 2),
	})
	corner(btn, 2); stroke(btn, 0.5, Color3.fromRGB(42, 42, 42))
	local ic = makeIcon(btn, 12)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.new(0.5, 0, 0.5, 0)
	hoverFx(btn, THEME.Btn, THEME.Accent)
	btn.MouseButton1Click:Connect(function() openAgentWindow() end)
end

local function driveDexSearch(query)
	local box = Dex.SearchBox
	if not box or not box.Parent then
		if not waitForDex(5) then return false, "Không tìm thấy ô Search của Dex++" end
		box = Dex.SearchBox
	end
	box.Text = query
	pcall(function() box:CaptureFocus() end)
	task.wait(0.05)
	pcall(function() box:ReleaseFocus(true) end)
	return true
end

----------------------------------------------------------------------
-- 10. TOOLS
----------------------------------------------------------------------
local TOOLS = {}

TOOLS.dex_search = {
	write = false,
	desc = "Đẩy query vào ô Search của Dex++ để người dùng thấy kết quả trong Explorer.",
	args = "{query=string}",
	run = function(a)
		local q = tostring(a.query or "")
		if q == "" then return errRes("query rỗng") end
		local ok, err = driveDexSearch(q)
		if not ok then return errRes(err) end
		return okRes({ applied = q })
	end,
}

TOOLS.list_children = {
	write = false,
	desc = "Liệt kê con trực tiếp của 1 instance.",
	args = "{path=string, limit=number?}",
	run = function(a)
		local inst, err = resolvePath(a.path or "game")
		if not inst then return errRes(err) end
		local limit = math.min(tonumber(a.limit) or 60, 150)
		local out = {}
		for _, c in ipairs(inst:GetChildren()) do
			if #out >= limit then break end
			out[#out + 1] = { name = c.Name, class = c.ClassName, ref = "#" .. addRef(c), children = #c:GetChildren() }
		end
		return okRes({ path = fullName(inst), class = inst.ClassName, total = #inst:GetChildren(), children = out })
	end,
}

TOOLS.find = {
	write = false,
	desc = "Quét đệ quy tìm instance theo class và/hoặc tên.",
	args = "{class=string?, name=string?, exact=boolean?, root=string?, limit=number?}",
	run = function(a)
		local root = game
		if a.root then
			local r, err = resolvePath(a.root)
			if not r then return errRes(err) end
			root = r
		end
		local cls = a.class
		local nm = a.name and tostring(a.name):lower() or nil
		local limit = math.min(tonumber(a.limit) or 40, 120)
		local out, scanned = {}, 0
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if not ok then return errRes("không quét được " .. fullName(root)) end
		for _, d in ipairs(desc) do
			scanned = scanned + 1
			local pass = true
			if cls then
				local isa = false
				pcall(function() isa = d:IsA(cls) end)
				if not isa then pass = false end
			end
			if pass and nm then
				if a.exact then pass = (d.Name == a.name) else pass = (d.Name:lower():find(nm, 1, true) ~= nil) end
			end
			if pass then
				out[#out + 1] = { name = d.Name, class = d.ClassName, path = fullName(d), ref = "#" .. addRef(d) }
				if #out >= limit then break end
			end
		end
		return okRes({ scanned = scanned, found = #out, results = out })
	end,
}

TOOLS.get_properties = {
	write = false,
	desc = "Đọc property của 1 instance.",
	args = "{path=string, props=array?}",
	run = function(a)
		local inst, err = resolvePath(a.path)
		if not inst then return errRes(err) end
		local list = (type(a.props) == "table" and #a.props > 0) and a.props or COMMON_PROPS
		local res = {}
		for _, p in ipairs(list) do
			local ok, v = pcall(function() return inst[p] end)
			if ok and v ~= nil then
				res[p] = (p == "Source") and cut(tostring(v), 1500) or encodeValue(v)
			end
		end
		return okRes({ path = fullName(inst), class = inst.ClassName, properties = res })
	end,
}

TOOLS.set_property = {
	write = true,
	desc = "Ghi 1 property. value: số/chuỗi/bool, \"Enum.X.Y\", {x,y,z} hoặc {r,g,b}.",
	args = "{path=string, property=string, value=any}",
	run = function(a)
		local inst, err = resolvePath(a.path)
		if not inst then return errRes(err) end
		local prop = tostring(a.property or "")
		if prop == "" then return errRes("thiếu property") end
		local val = parseValue(a.value)
		if prop == "Parent" and type(a.value) == "string" then
			local p = resolvePath(a.value)
			if p then val = p end
		end
		local before
		pcall(function() before = encodeValue(inst[prop]) end)
		local ok, e = pcall(function() inst[prop] = val end)
		if not ok then return errRes("gán thất bại: " .. tostring(e)) end
		local after
		pcall(function() after = encodeValue(inst[prop]) end)
		return okRes({ path = fullName(inst), property = prop, before = before, after = after })
	end,
}

TOOLS.call_method = {
	write = true,
	desc = "Gọi method của instance (Destroy, Clone, FireServer, InvokeServer, MoveTo, Play...).",
	args = "{path=string, method=string, args=array?}",
	run = function(a)
		local inst, err = resolvePath(a.path)
		if not inst then return errRes(err) end
		local m = tostring(a.method or "")
		if m == "" then return errRes("thiếu method") end
		local fn
		local okf = pcall(function() fn = inst[m] end)
		if not okf or type(fn) ~= "function" then return errRes("method không tồn tại: " .. m) end
		local args = {}
		if type(a.args) == "table" then
			for i, v in ipairs(a.args) do args[i] = parseValue(v) end
		end
		local ok, res = pcall(function() return fn(inst, table.unpack(args)) end)
		if not ok then return errRes("gọi lỗi: " .. tostring(res)) end
		return okRes({ path = fullName(inst), method = m, returned = encodeValue(res) })
	end,
}

TOOLS.run_luau = {
	write = true,
	desc = "Chạy đoạn Luau ngắn trong client (chỉ khi tool khác không làm được). Dùng return để trả kết quả.",
	args = "{code=string}",
	run = function(a)
		local code = tostring(a.code or "")
		if code == "" then return errRes("code rỗng") end
		local ls = loadstring or (getgenv and getgenv().loadstring)
		if not ls then return errRes("executor không có loadstring") end
		local fn, cerr = ls(code)
		if not fn then return errRes("lỗi biên dịch: " .. tostring(cerr)) end
		local ok, res = pcall(fn)
		if not ok then return errRes("runtime lỗi: " .. tostring(res)) end
		return okRes({ returned = cut(tostring(res), 1200) })
	end,
}

TOOLS.highlight = {
	write = false,
	desc = "Làm nổi bật 1 instance trong game (tự tắt).",
	args = "{path=string, seconds=number?}",
	run = function(a)
		local inst, err = resolvePath(a.path)
		if not inst then return errRes(err) end
		local secs = math.clamp(tonumber(a.seconds) or 8, 1, 30)
		local made
		pcall(function()
			local h = Instance.new("Highlight")
			h.FillColor = THEME.AccentHi
			h.OutlineColor = Color3.new(1, 1, 1)
			h.FillTransparency = 0.55
			h.Adornee = inst
			h.Parent = inst
			made = h
		end)
		if not made then
			pcall(function()
				local b = Instance.new("SelectionBox")
				b.Adornee = inst; b.Color3 = THEME.AccentHi; b.Parent = inst
				made = b
			end)
		end
		if not made then return errRes("không highlight được") end
		task.delay(secs, function() pcall(function() made:Destroy() end) end)
		return okRes({ path = fullName(inst), seconds = secs })
	end,
}

TOOLS.teleport = {
	write = true,
	desc = "Dịch chuyển nhân vật tới 1 instance hoặc toạ độ.",
	args = "{path=string?, x=number?, y=number?, z=number?, offset=number?}",
	run = function(a)
		local char = LP.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return errRes("chưa có HumanoidRootPart") end
		local target
		if a.path then
			local inst, err = resolvePath(a.path)
			if not inst then return errRes(err) end
			pcall(function()
				if inst:IsA("Model") then target = inst:GetPivot().Position
				elseif inst:IsA("BasePart") then target = inst.Position end
			end)
			if not target then return errRes("instance không có vị trí") end
		else
			target = Vector3.new(tonumber(a.x) or 0, tonumber(a.y) or 0, tonumber(a.z) or 0)
		end
		local off = tonumber(a.offset) or 4
		local ok, e = pcall(function() root.CFrame = CFrame.new(target + Vector3.new(0, off, 0)) end)
		if not ok then return errRes(tostring(e)) end
		return okRes({ moved_to = { x = target.X, y = target.Y, z = target.Z } })
	end,
}

TOOLS.list_remotes = {
	write = false,
	desc = "Liệt kê RemoteEvent / RemoteFunction / UnreliableRemoteEvent.",
	args = "{root=string?, limit=number?}",
	run = function(a)
		local root = game
		if a.root then
			local r, err = resolvePath(a.root)
			if not r then return errRes(err) end
			root = r
		end
		local limit = math.min(tonumber(a.limit) or 50, 150)
		local out = {}
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if not ok then return errRes("không quét được") end
		for _, d in ipairs(desc) do
			local isR = false
			pcall(function()
				isR = d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent")
			end)
			if isR then
				out[#out + 1] = { name = d.Name, class = d.ClassName, path = fullName(d), ref = "#" .. addRef(d) }
				if #out >= limit then break end
			end
		end
		return okRes({ found = #out, remotes = out })
	end,
}

TOOLS.get_scripts = {
	write = false,
	desc = "Liệt kê script/module; kèm source nếu executor có decompile.",
	args = "{root=string?, limit=number?, decompile_path=string?}",
	run = function(a)
		if a.decompile_path then
			local inst, err = resolvePath(a.decompile_path)
			if not inst then return errRes(err) end
			local dec = decompile or (getgenv and getgenv().decompile)
			if not dec then return errRes("executor không hỗ trợ decompile") end
			local ok, src = pcall(dec, inst)
			if not ok then return errRes("decompile lỗi: " .. tostring(src)) end
			return okRes({ path = fullName(inst), source = cut(tostring(src), 4000) })
		end
		local root = game
		if a.root then
			local r, err = resolvePath(a.root)
			if not r then return errRes(err) end
			root = r
		end
		local limit = math.min(tonumber(a.limit) or 40, 120)
		local out = {}
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if not ok then return errRes("không quét được") end
		for _, d in ipairs(desc) do
			local isS = false
			pcall(function() isS = d:IsA("LuaSourceContainer") end)
			if isS then
				out[#out + 1] = { name = d.Name, class = d.ClassName, path = fullName(d), ref = "#" .. addRef(d) }
				if #out >= limit then break end
			end
		end
		return okRes({ found = #out, scripts = out })
	end,
}

TOOLS.game_info = {
	write = false,
	desc = "Thông tin game + local player.",
	args = "{}",
	run = function()
		local info = {
			PlaceId = game.PlaceId, GameId = game.GameId, JobId = game.JobId,
			Players = #Players:GetPlayers(), LocalPlayer = LP.Name, UserId = LP.UserId,
		}
		pcall(function()
			info.GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		end)
		local char = LP.Character
		if char then
			info.Character = fullName(char)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				info.Health, info.MaxHealth = hum.Health, hum.MaxHealth
				info.WalkSpeed, info.JumpPower = hum.WalkSpeed, hum.JumpPower
			end
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local p = root.Position
				info.Position = { x = math.floor(p.X), y = math.floor(p.Y), z = math.floor(p.Z) }
			end
		end
		local svc = {}
		for _, s in ipairs({ "Workspace", "Players", "ReplicatedStorage", "ReplicatedFirst", "Lighting", "SoundService", "StarterGui", "StarterPack" }) do
			local ok, o = pcall(function() return game:GetService(s) end)
			if ok and o then svc[s] = #o:GetChildren() end
		end
		info.ServiceChildCounts = svc
		return okRes({ info = info })
	end,
}

----------------------------------------------------------------------
-- 11. PROTOCOL + AGENT LOOP
----------------------------------------------------------------------
local function extractJson(text)
	text = tostring(text or ""):gsub("```json", ""):gsub("```", "")
	local s = text:find("{")
	if not s then return nil end
	local depth, inStr, esc = 0, false, false
	for i = s, #text do
		local ch = text:sub(i, i)
		if inStr then
			if esc then esc = false
			elseif ch == "\\" then esc = true
			elseif ch == '"' then inStr = false end
		else
			if ch == '"' then inStr = true
			elseif ch == "{" then depth = depth + 1
			elseif ch == "}" then
				depth = depth - 1
				if depth == 0 then return text:sub(s, i) end
			end
		end
	end
	return nil
end

local function decodeStep(text)
	local js = extractJson(text)
	if not js then return nil, trim(text) end
	local ok, d = pcall(function() return HttpService:JSONDecode(js) end)
	if not ok or type(d) ~= "table" then return nil, trim(text) end
	if not d.tool and not d.final then return nil, trim(text) end
	return d, nil
end

local function buildSystemPrompt()
	local lines = {
		"You are 'AI Agent', an autonomous assistant embedded inside Dex++ (a Roblox instance explorer on an executor client).",
		"",
		"PROTOCOL — reply with EXACTLY ONE compact JSON object, no markdown fences:",
		'  tool step: {"thought":"short","tool":"tool_name","args":{...}}',
		'  finish:    {"thought":"short","final":"answer for the user"}',
		"The 'final' string MAY use full Markdown (headings, **bold**, lists, > quotes, ```code fences```).",
		"Answer in Vietnamese if the user writes Vietnamese.",
		"After each tool call you receive a TOOL_RESULT message. Chain tools until done, then send final.",
		"",
		"RULES:",
		"- Read first (find/list_children/get_properties/game_info) before writing.",
		"- Paths: 'game.Workspace.Part', 'Workspace.Map[\"My Part\"]', 'game.Players.LocalPlayer.Character', or ref '#12'.",
		"- Use dex_search so results show in Dex++'s own Explorer. Dex syntax: plain text = name contains; \"text\" = exact; /isa <Class>; /remotes; /bindables; /rad <n>; combine with && || ( ).",
		"- run_luau is last resort; keep it short and return a value.",
		"- Write actions need user confirmation; if denied, stop and explain.",
		"- Never invent property values or paths; verify with a tool first.",
		"",
		"AVAILABLE TOOLS:",
	}
	local names = {}
	for k in pairs(TOOLS) do names[#names + 1] = k end
	table.sort(names)
	for _, k in ipairs(names) do
		local t = TOOLS[k]
		lines[#lines + 1] = ("- %s args=%s%s :: %s"):format(k, t.args, t.write and " [WRITE/confirm]" or "", t.desc)
	end
	return table.concat(lines, "\n")
end

local history = {}
local function pushHistory(role, content)
	history[#history + 1] = { role = role, content = content }
	while #history > 26 do table.remove(history, 1) end
end

local function execTool(name, args)
	local tool = TOOLS[name]
	if not tool then return errRes("tool không tồn tại: " .. tostring(name)) end
	args = (type(args) == "table") and args or {}

	if tool.write and not CONFIG.AUTO_APPROVE then
		local approved = nil
		local okj, detail = pcall(function() return HttpService:JSONEncode(args) end)
		askConfirm(name, okj and detail or "(không encode được args)", function(v) approved = v end)
		setStatus("Chờ bạn xác nhận...", THEME.Warn)
		local t0 = tick()
		while approved == nil and tick() - t0 < 120 do task.wait(0.1) end
		if approved ~= true then return errRes("người dùng từ chối hành động (denied)") end
	end

	setStatus("Đang chạy tool: " .. name, THEME.AccentHi)
	local ok, res = pcall(tool.run, args)
	if not ok then return errRes("tool lỗi: " .. tostring(res)) end
	return res
end

local busy = false
runAgent = function(userText)
	if busy then setStatus("Đang xử lý, chờ chút...", THEME.Warn); return end
	busy = true
	addBubble("user", userText)
	pushHistory("user", userText)

	task.spawn(function()
		local sys = buildSystemPrompt()
		local step = 0
		while step < CONFIG.MAX_STEPS do
			step = step + 1
			setStatus(("Đang nghĩ... (bước %d/%d)"):format(step, CONFIG.MAX_STEPS), THEME.AccentHi)

			local stream = addStreamBubble()
			local buf = ""
			local text, err = callLLM(history, sys, function(chunk)
				buf = buf .. chunk
				if buf:find("^%s*{") then
					local pf = partialFinal(buf)
					if pf then stream.set(pf) else stream.set("_đang suy nghĩ..._") end
				else
					stream.append(chunk)
				end
			end)

			if not text then
				stream.finish("**Lỗi:** " .. tostring(err))
				setStatus("Lỗi", THEME.Err)
				break
			end
			pushHistory("assistant", text)

			local stepObj, plain = decodeStep(text)
			if not stepObj then
				stream.finish(plain ~= "" and plain or "(rỗng)")
				setStatus("Xong", THEME.Ok)
				break
			end
			if stepObj.final then
				stream.finish(tostring(stepObj.final))
				setStatus("Xong", THEME.Ok)
				break
			end
			-- bước tool: biến bubble thành dòng thought gọn
			stream.finish("_" .. cut(tostring(stepObj.thought or "..."), 160) .. "_")

			local res = execTool(stepObj.tool, stepObj.args)
			local okj, enc = pcall(function() return HttpService:JSONEncode(res) end)
			enc = okj and enc or '{"ok":false,"error":"encode fail"}'
			addBubble("tool", ("`%s` → %s"):format(tostring(stepObj.tool), cut(enc, 300)))
			pushHistory("user", "TOOL_RESULT " .. cut(enc, 3500))

			if step >= CONFIG.MAX_STEPS then
				addBubble("error", "Đã đạt giới hạn " .. CONFIG.MAX_STEPS .. " bước. Hỏi tiếp để mình làm nốt.")
				setStatus("Hết bước", THEME.Warn)
			end
		end
		busy = false
	end)
end

----------------------------------------------------------------------
-- 12. BOOT
----------------------------------------------------------------------
local function loadSaved()
	if not (readfile and isfile) then return end
	pcall(function()
		if isfile(CONFIG.SAVE_FILE) then
			local d = HttpService:JSONDecode(readfile(CONFIG.SAVE_FILE))
			if type(d) == "table" then
				for k, v in pairs(d) do
					if CONFIG[k] ~= nil and type(v) == type(CONFIG[k]) then CONFIG[k] = v end
				end
			end
		end
	end)
end

local function boot()
	loadSaved()
	-- dọn bản cũ (v1 tạo ScreenGui riêng)
	for _, root in ipairs(scanRoots()) do
		local old = root:FindFirstChild("DexAIAgent")
		if old then pcall(function() old:Destroy() end) end
	end

	local found = waitForDex(25)
	openAgentWindow()

	if found then
		pcall(ensureMenuEntry)
		pcall(addSearchAIButton)
		task.spawn(function()
			while W.Win and W.Win.Root and W.Win.Root.Parent do
				pcall(ensureMenuEntry)
				pcall(addSearchAIButton)
				if not (Dex.SearchBox and Dex.SearchBox.Parent) then
					local b = findSearchBox()
					if b then Dex.SearchBox = b; Dex.Gui = dexRootOf(b) end
				end
				task.wait(1.5)
			end
		end)
		print("[AI Agent] Gắn vào Dex++ OK · window kind = " .. tostring(W.Win.Kind))
	else
		addBubble("error", "Chưa dò được UI Dex++. Cửa sổ vẫn dùng được nhưng `dex_search` sẽ không chạy tới khi Dex++ mở Explorer.")
	end
end

boot()
