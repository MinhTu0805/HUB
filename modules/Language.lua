-- ═══ Language.lua ═══ English / Tiếng Việt translations (Tr)
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local S = SV.S

-- ─── LANGUAGE ───────────────────────────────────────────
-- English is the source text. Tr() maps it to Vietnamese when selected; anything unknown passes through.
local VI = {
    -- tabs
    ["Display"] = "Hiển thị", ["Solver"] = "Bộ giải", ["Auto"] = "Tự động", ["Stats"] = "Thống kê",
    ["Settings"] = "Cài đặt", ["About"] = "Giới thiệu",
    -- readout strip / legend
    ["Safe"] = "An toàn", ["Mine"] = "Mìn", ["Mines"] = "Mìn", ["Best"] = "Tốt nhất", ["Risk"] = "Rủi ro",
    ["Best risk"] = "Rủi ro thấp nhất", ["Solve"] = "Giải",
    -- sections
    ["Overlay"] = "Lớp phủ", ["Style"] = "Kiểu", ["Effects"] = "Hiệu ứng", ["Interface"] = "Giao diện",
    ["Engine"] = "Động cơ", ["Actions"] = "Hành động", ["Autopilot  ·  starts OFF every time"] = "Tự động  ·  luôn TẮT khi khởi động",
    ["Movement"] = "Di chuyển", ["Flagging"] = "Cắm cờ", ["Status"] = "Trạng thái", ["Board"] = "Bàn chơi",
    ["Script"] = "Script", ["Language"] = "Ngôn ngữ", ["Window"] = "Cửa sổ", ["Controls"] = "Phím điều khiển",
    ["How it works"] = "Cách hoạt động", ["Tips"] = "Mẹo",
    -- display page
    ["Solver active"] = "Bật bộ giải", ["Turn everything off without unloading"] = "Tắt mọi thứ mà không cần gỡ script",
    ["Safe tiles"] = "Ô an toàn", ["Guess probabilities"] = "Xác suất đoán", ["Best guess"] = "Lượt đoán tốt nhất",
    ["Flagged mines"] = "Mìn đã cắm cờ", ["Keep the overlay on tiles you flagged"] = "Giữ lớp phủ trên ô bạn đã cắm cờ",
    ["Overlay style"] = "Kiểu lớp phủ", ["Soft"] = "Mềm", ["Outline"] = "Viền", ["Dot"] = "Chấm",
    ["Fill opacity"] = "Độ đậm màu", ["Show % on guesses"] = "Hiện % khi đoán", ["Mine chance instead of “?”"] = "Hiện tỉ lệ mìn thay cho “?”",
    ["See through walls"] = "Nhìn xuyên tường", ["Animations"] = "Hoạt ảnh", ["Pop-in and colour fades"] = "Hiện dần và chuyển màu",
    ["Pulse best guess"] = "Nhấp nháy ô đoán tốt nhất",
    -- solver page
    ["Accuracy"] = "Độ chính xác", ["Fast"] = "Nhanh", ["Balanced"] = "Cân bằng", ["Max"] = "Tối đa",
    ["Trust my flags"] = "Tin cờ của tôi", ["Treat flagged tiles as mines"] = "Coi ô có cờ là mìn",
    ["Re-solve now"] = "Giải lại ngay", ["Clear overlays"] = "Xóa lớp phủ",
    -- auto page
    ["Auto flag mines"] = "Tự cắm cờ mìn", ["Flags every mine the solver proves"] = "Cắm cờ mọi mìn mà bộ giải chứng minh được",
    ["Auto remove wrong flags"] = "Tự gỡ cờ sai", ["Takes flags off tiles proven safe"] = "Gỡ cờ khỏi ô đã chứng minh an toàn",
    ["Auto move"] = "Tự di chuyển", ["Walks only over revealed / proven-safe tiles"] = "Chỉ đi trên ô đã mở / an toàn",
    ["Auto guess when stuck"] = "Tự đoán khi bí", ["Steps on the best guess if risk is low enough"] = "Bước vào ô đoán tốt nhất nếu rủi ro đủ thấp",
    ["Max guess risk"] = "Rủi ro đoán tối đa",
    ["Jump over hazards"] = "Nhảy qua ô nguy hiểm", ["Hops one blocked tile when it saves a long detour"] = "Nhảy qua một ô chặn khi tránh được đường vòng dài",
    ["Boost jump on hops"] = "Nhảy cao hơn khi vượt ô", ["Higher arc: lands on the far tile with speed to spare"] = "Vòng cung cao hơn: tiếp đất ô xa an toàn hơn",
    ["Walk over flagged tiles"] = "Đi qua ô có cờ", ["Flagged mines count as walkable"] = "Mìn đã cắm cờ được coi là đi được",
    ["Strict safety"] = "An toàn nghiêm ngặt", ["Only tiles proven by local logic, not by mine count"] = "Chỉ ô được chứng minh bằng logic cục bộ, không dựa vào số mìn",
    ["Safety margin"] = "Biên an toàn", ["Caution speed"] = "Tốc độ thận trọng",
    ["Flag method"] = "Cách cắm cờ", ["Click"] = "Click", ["Mouse"] = "Chuột",
    ["Flags per pass"] = "Cờ mỗi lượt", ["Flag delay"] = "Độ trễ cắm cờ",
    ["Move"] = "Di chuyển", ["Flag"] = "Cờ", ["Flags placed"] = "Cờ đã cắm", ["Flags removed"] = "Cờ đã gỡ", ["Unflag method"] = "Cách gỡ cờ",
    ["Stop all automation"] = "Dừng mọi tự động",
    -- stats page
    ["Game"] = "Ván chơi", ["Grid"] = "Lưới", ["Tiles tracked"] = "Ô đang theo dõi", ["Mines found"] = "Mìn tìm thấy",
    ["Best guess risk"] = "Rủi ro đoán tốt nhất", ["Last solve"] = "Lần giải gần nhất", ["Solves"] = "Số lần giải",
    ["Unload script"] = "Gỡ script", ["In progress"] = "Đang chơi", ["Idle"] = "Chờ",
    -- footer / live states
    ["RightShift  show / hide   ·   drag the title bar"] = "RightShift  ẩn / hiện   ·   kéo thanh tiêu đề để di chuyển",
    ["ROUND LIVE"] = "ĐANG CHƠI", ["IDLE"] = "CHỜ",
    ["Off"] = "Tắt", ["Waiting for round"] = "Chờ ván mới", ["No character"] = "Không có nhân vật", ["Jumping"] = "Đang nhảy",
    ["No flag method available"] = "Không có cách cắm cờ", ["Recovered from an error"] = "Đã khắc phục lỗi",
    -- settings page
    ["UI scale"] = "Kích cỡ giao diện", ["Reset UI size"] = "Đặt lại kích cỡ", ["Language changed"] = "Đã đổi ngôn ngữ",
    ["UI size reset"] = "Đã đặt lại kích cỡ",
    -- about page
    ["Name"] = "Tên", ["Version"] = "Phiên bản", ["Game"] = "Ván chơi", ["Made for"] = "Dành cho",
    ["Blockerman (Roblox minesweeper)"] = "Blockerman (dò mìn trên Roblox)",
    ["Toggle window"] = "Ẩn / hiện cửa sổ", ["Move window"] = "Di chuyển cửa sổ", ["Drag the title bar"] = "Kéo thanh tiêu đề",
    ["Floating button"] = "Nút nổi", ["Tap to open / close"] = "Bấm để mở / đóng",
    ["The solver reads the board, works out which tiles are provably safe or mines, and estimates the mine chance for the rest. Green = safe, red = mine, blue = best guess."] =
        "Bộ giải đọc bàn chơi, tìm ra ô nào chắc chắn an toàn hoặc là mìn, rồi ước tính xác suất mìn cho các ô còn lại. Xanh = an toàn, đỏ = mìn, xanh dương = lượt đoán tốt nhất.",
    ["Autopilot can flag mines, walk and guess for you. It always starts OFF and only walks over tiles it has proven safe."] =
        "Chế độ tự động có thể cắm cờ, di chuyển và đoán giúp bạn. Nó luôn TẮT khi khởi động và chỉ đi trên ô đã chứng minh an toàn.",
    ["If a guess is unavoidable, pick the tile with the lowest risk. Use “Strict safety” for the safest autopilot."] =
        "Khi buộc phải đoán, hãy chọn ô có rủi ro thấp nhất. Bật “An toàn nghiêm ngặt” để tự động an toàn nhất.",
    ["Your settings are saved automatically when your executor supports file writing."] =
        "Cài đặt được lưu tự động nếu executor của bạn hỗ trợ ghi file.",
    -- toasts
    ["Re-solving…"] = "Đang giải lại…", ["Automation stopped"] = "Đã dừng tự động", ["Unloading…"] = "Đang gỡ…",
    ["Solver ready"] = "Bộ giải đã sẵn sàng", ["Solver ready · waiting for next round"] = "Bộ giải đã sẵn sàng · chờ ván tiếp theo",
}
local VIU = {}
for k, v in next, VI do VIU[string.upper(k)] = v end

local function Tr(text)
    if S.Language ~= "Tiếng Việt" or type(text) ~= "string" then return text end
    return VI[text] or VIU[text] or text
end

-- ─── exports ───
SV.Tr = Tr
SV.VI = VI
SV.VIU = VIU
