-- Blox Fruit Full Moon Auto Join Hub
-- Made by GPT for Herin38

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Blox Fruit Game ID
local BLOX_FRUIT_GAME_ID = 2753915549

-- GUI setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 100)
Frame.Position = UDim2.new(0, 10, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Toggle = Instance.new("TextButton", Frame)
Toggle.Size = UDim2.new(1, -20, 0, 40)
Toggle.Position = UDim2.new(0, 10, 0, 10)
Toggle.Text = "Auto Join Full Moon: OFF"
Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextSize = 16

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, -20, 0, 40)
Status.Position = UDim2.new(0, 10, 0, 55)
Status.Text = "Trạng thái: Đang chờ..."
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.Font = Enum.Font.SourceSans
Status.TextSize = 14

-- Auto Join logic
local autoJoin = false

Toggle.MouseButton1Click:Connect(function()
    autoJoin = not autoJoin
    Toggle.Text = "Auto Join Full Moon: " .. (autoJoin and "ON" or "OFF")
end)

local function getFullMoonJobIds()
    local success, response = pcall(function()
        return HttpService:GetAsync("https://game.hentaiviet.top/fullmoon.php")
    end)

    if success then
        local jobIds = {}
        for value in response:gmatch('```yaml\\n(.-)\\n```') do
            table.insert(jobIds, value)
        end
        return jobIds
    else
        warn("Không thể lấy dữ liệu từ API")
        return {}
    end
end

local function tryJoin()
    local jobIds = getFullMoonJobIds()
    for _, jobId in ipairs(jobIds) do
        Status.Text = "Thử vào: " .. jobId
        local success, result = pcall(function()
            TeleportService:TeleportToPlaceInstance(BLOX_FRUIT_GAME_ID, jobId, player)
        end)
        if success then
            Status.Text = "Đang Teleport..."
            return
        else
            warn("Lỗi join:", result)
            wait(1)
        end
    end
    Status.Text = "Tất cả server đều lỗi. Thử lại sau..."
end

task.spawn(function()
    while true do
        if autoJoin then
            tryJoin()
        end
        wait(10)
    end
end)
