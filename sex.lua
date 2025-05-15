local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local Window = Library:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "moon" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
local MoonTab = Window:AddTab({ Title = "Moon Info", Icon = "info" })
local AboutTab = Window:AddTab({ Title = "About", Icon = "help-circle" })

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local isAutoJoining = false
local retryDelay = 5
local selectedServerType = "API1"
local customAPI = "https://game.hentaiviet.top/fullmoon.php"
local fullMoonServers = {}

local SaveFolder = "Herina"
local ConfigFile = Players.LocalPlayer.Name .. "-BloxFruit.json"
local Settings = {}

local function SaveSettings(key, value)
    Settings[key] = value
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    writefile(SaveFolder .. "/" .. ConfigFile, HttpService:JSONEncode(Settings))
end

local function LoadSettings()
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(SaveFolder .. "/" .. ConfigFile))
    end)
    if success then return result else return {} end
end

Settings = LoadSettings()
isAutoJoining = Settings.isAutoJoining or false
retryDelay = Settings.retryDelay or 5
selectedServerType = Settings.selectedServerType or "API1"
customAPI = Settings.customAPI or "https://game.hentaiviet.top/fullmoon.php"

local Sea1, Sea2, Sea3 = false, false, false
if game.PlaceId == 2753915549 then Sea1 = true
elseif game.PlaceId == 4442272183 then Sea2 = true
elseif game.PlaceId == 7449423635 then Sea3 = true end

local function MoonTextureId()
    if Sea1 or Sea2 then return Lighting.FantasySky.MoonTextureId
    elseif Sea3 then return Lighting.Sky.MoonTextureId end
end

local function CheckMoon()
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"
    local moon4 = "http://www.roblox.com/asset/?id=9709149052"
    local moon = MoonTextureId()
    if moon == moon5 then return "Full Moon"
    elseif moon == moon4 then return "Next Night" else return "Bad Moon" end
end

local function GetFormattedTime()
    local h = math.floor(Lighting.ClockTime)
    local m = math.floor((Lighting.ClockTime - h) * 60)
    return string.format("%02d:%02d", h, m)
end

local function GetGameTime()
    local ct = Lighting.ClockTime
    return (ct >= 18 or ct < 5) and "Night" or "Day"
end

local function GetMoonTimeInfo()
    local status = CheckMoon()
    local ct = Lighting.ClockTime
    if status == "Full Moon" then
        if ct <= 5 then return GetFormattedTime() .. " (Moon ends in " .. math.floor(5 - ct) .. "m)"
        elseif ct < 12 then return GetFormattedTime() .. " (Fake Moon)"
        elseif ct < 18 then return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - ct) .. "m)"
        else return GetFormattedTime() .. " (Moon ends in " .. math.floor(24 + 6 - ct) .. "m)" end
    elseif status == "Next Night" then
        if ct < 12 then return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - ct) .. "m)"
        else return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 + 12 - ct) .. "m)" end
    end
    return GetFormattedTime()
end

local moonLabel = MoonTab:AddParagraph({ Title = "Moon", Content = "Loading..." })
local timeLabel = MoonTab:AddParagraph({ Title = "Time", Content = "Loading..." })
local phaseLabel = MoonTab:AddParagraph({ Title = "Phase", Content = "Loading..." })

task.spawn(function()
    while true do
        moonLabel:SetText("Moon: " .. CheckMoon())
        timeLabel:SetText("Time: " .. GetMoonTimeInfo())
        phaseLabel:SetText("Phase: " .. GetGameTime())
        task.wait(1)
    end
end)

local function fetchFullMoonServers()
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(customAPI))
    end)
    if not success then return {} end
    local servers = {}
    if res.status == "done" and res.results then
        for _, ch in ipairs(res.results) do
            for _, msg in ipairs(ch.messages or {}) do
                for _, embed in ipairs(msg.embeds or {}) do
                    local info = { jobId = nil, teleportScript = nil, serverType = nil, players = "N/A" }
                    for _, field in ipairs(embed.fields or {}) do
                        if field.name:find("Job ID") then
                            info.jobId = field.value:match("```yaml\n(.-)```") or field.value
                        elseif field.name:find("Join Script") then
                            info.teleportScript = field.value:match("```lua\n(.-)```") or field.value
                            if info.teleportScript:find("TeleportService") then
                                info.serverType = "TeleportService"
                            elseif info.teleportScript:find("__ServerBrowser") then
                                info.serverType = "ServerBrowser"
                            end
                        elseif field.name:find("Players") then
                            info.players = field.value:match("```yaml\n(.-)```") or field.value
                        end
                    end
                    if info.teleportScript then table.insert(servers, info) end
                end
            end
        end
    end
    return servers
end

local function joinFullMoonServer(info)
    local success, err = pcall(function()
        loadstring(info.teleportScript)()
    end)
    return success
end

local function startAutoJoining()
    if isAutoJoining then return end
    isAutoJoining = true
    SaveSettings("isAutoJoining", true)
    task.spawn(function()
        while isAutoJoining do
            fullMoonServers = fetchFullMoonServers()
            for _, server in ipairs(fullMoonServers) do
                if selectedServerType == "API1" or server.serverType == selectedServerType then
                    if joinFullMoonServer(server) then break end
                end
            end
            task.wait(retryDelay)
        end
    end)
end

local function stopAutoJoining()
    isAutoJoining = false
    SaveSettings("isAutoJoining", false)
end

MainTab:AddToggle("AutoJoin", {
    Title = "Auto Join Full Moon Servers",
    Default = isAutoJoining,
    Callback = function(state)
        if state then startAutoJoining() else stopAutoJoining() end
    end
})

MainTab:AddButton("Refresh Servers", function()
    fullMoonServers = fetchFullMoonServers()
end)

SettingsTab:AddSlider("Retry Delay", {
    Title = "Retry Delay (sec)",
    Description = "Time between join attempts",
    Default = retryDelay,
    Min = 1,
    Max = 30,
    Callback = function(value)
        retryDelay = value
        SaveSettings("retryDelay", value)
    end
})

SettingsTab:AddDropdown("Server Type", {
    Title = "Server Type",
    Values = {"API1", "TeleportService", "ServerBrowser"},
    Default = selectedServerType,
    Callback = function(option)
        selectedServerType = option
        SaveSettings("selectedServerType", option)
    end
})

SettingsTab:AddInput("Custom API", {
    Title = "Custom API URL",
    Default = customAPI,
    Placeholder = "https://example.com/api",
    Callback = function(text)
        customAPI = text
        SaveSettings("customAPI", text)
    end
})

AboutTab:AddParagraph({
    Title = "About",
    Content = "HerinaAuto Join Blox Fruit (Fluent UI Edition)\nPress RightShift to toggle UI."
})

if isAutoJoining then startAutoJoining() end
