-- Auto Join Blox Fruit FullMoon Server (Retry Until Success)
-- By GPT x Herin38

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PLACE_ID = 2753915549 -- Blox Fruit

-- Lấy Job IDs từ API
local function getJobIDs()
    local success, response = pcall(function()
        return HttpService:GetAsync("https://game.hentaiviet.top/fullmoon.php")
    end)

    if not success then
        warn("[❌] Không thể truy cập API:", response)
        return {}
    end

    local jobIds = {}
    for job in response:gmatch("```yaml\\n(.-)\\n```") do
        table.insert(jobIds, job)
    end

    return jobIds
end

-- Thử teleport nhiều lần vào 1 job ID
local function tryJoinJobID(jobId)
    while true do
        warn("[🌕] Đang cố join Job ID:", jobId)
        local success, result = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, player)
        end)

        if success then
            warn("[✅] Đang teleport đến server:", jobId)
            break
        else
            warn("[❌] Lỗi join:", result)
            wait(2)
        end
    end
end

-- Main logic
local function main()
    local jobIds = getJobIDs()

    if #jobIds == 0 then
        warn("[⚠️] Không tìm thấy Job ID nào. Thoát.")
        return
    end

    for _, jobId in ipairs(jobIds) do
        tryJoinJobID(jobId)
        wait(3)
    end

    warn("[❌] Đã thử tất cả Job ID nhưng không vào được.")
end

-- Chạy script
main()
