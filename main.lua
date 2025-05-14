-- Auto Join FullMoon Blox Fruit - All Job IDs
-- By GPT x Herin38

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local BLOX_FRUIT_PLACE_ID = 2753915549

-- Lấy danh sách JobID từ API
local function getJobIDs()
    local success, result = pcall(function()
        return HttpService:GetAsync("https://game.hentaiviet.top/fullmoon.php")
    end)

    if not success then
        warn("[❌] Lỗi khi truy cập API:", result)
        return {}
    end

    local jobIds = {}
    for job in result:gmatch("```yaml\\n(.-)\\n```") do
        table.insert(jobIds, job)
    end

    return jobIds
end

-- Tự động join từng server liên tục
local function autoJoin()
    while true do
        local jobList = getJobIDs()

        if #jobList == 0 then
            warn("[⚠️] Không tìm thấy Job ID nào. Thử lại sau.")
            wait(10)
        else
            for _, jobId in ipairs(jobList) do
                warn("[🔁] Đang thử Job ID:", jobId)
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(BLOX_FRUIT_PLACE_ID, jobId, player)
                end)

                if success then
                    warn("[✅] Đang Teleport tới Job ID:", jobId)
                    return -- Nếu thành công thì ngưng
                else
                    warn("[❌] Thử thất bại:", err)
                    wait(2)
                end
            end
        end

        wait(10) -- đợi rồi thử lại từ đầu
    end
end

-- Bắt đầu
autoJoin()
