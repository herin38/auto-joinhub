-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Variables
local isAutoJoining = false
local retryDelay = 5
local customAPI = "https://game.hentaiviet.top/fullmoon.php"

-- Load UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("HerinaAuto Join Blox Fruit", "DarkTheme")

-- Get Current Sea
local placeId = game.PlaceId
local Sea1 = placeId == 2753915549
local Sea2 = placeId == 4442272183
local Sea3 = placeId == 7449423635

-- Moon Status Functions
function MoonTextureId()
    if Sea1 or Sea2 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea3 then
        return game:GetService("Lighting").Sky.MoonTextureId
    end
end

function CheckMoon()
    local moonTextures = {
        moon5 = "http://www.roblox.com/asset/?id=9709149431", -- Full moon
        moon4 = "http://www.roblox.com/asset/?id=9709149052" -- Next night
    }
    
    local moonreal = MoonTextureId()
    local moonStatus = "Bad Moon"
    
    if moonreal == moonTextures.moon5 then
        moonStatus = "Full Moon"
    elseif moonreal == moonTextures.moon4 then
        moonStatus = "Next Night"
    end
    
    return moonStatus
end

function GetGameTime()
    local clockTime = game.Lighting.ClockTime
    if clockTime >= 18 or clockTime < 5 then
        return "Night"
    else
        return "Day"
    end
end

-- Function to fetch servers
function fetchFullMoonServers()
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(customAPI))
    end)
    
    if not success then return {} end
    
    local servers = {}
    if type(response) == "table" then
        for _, server in pairs(response) do
            if server.jobId then
                table.insert(servers, {
                    jobId = server.jobId,
                    players = server.playing or "N/A"
                })
            end
        end
    end
    
    return servers
end

-- Function to join server
function joinServer(server)
    if server and server.jobId then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, Players.LocalPlayer)
    end
end

-- Create Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Join")

-- Auto Join Toggle
MainSection:NewToggle("Auto Join Full Moon", "Automatically join Full Moon servers", function(state)
    isAutoJoining = state
    
    if state then
        spawn(function()
            while isAutoJoining do
                local servers = fetchFullMoonServers()
                if #servers > 0 then
                    for _, server in ipairs(servers) do
                        if isAutoJoining then
                            joinServer(server)
                            wait(5)
                        else
                            break
                        end
                    end
                end
                wait(retryDelay)
            end
        end)
    end
end)

-- Refresh Button
MainSection:NewButton("Refresh Servers", "Check for new servers", function()
    local servers = fetchFullMoonServers()
    print("Found " .. #servers .. " servers")
end)

-- Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Settings")

-- Retry Delay Slider
SettingsSection:NewSlider("Retry Delay", "Seconds between checks", 30, 1, function(value)
    retryDelay = value
end)

-- Moon Info Tab
local MoonTab = Window:NewTab("Moon Info")
local MoonSection = MoonTab:NewSection("Moon Status")

local moonLabel = MoonSection:NewLabel("Checking moon status...")

-- Update moon info
spawn(function()
    while wait(1) do
        local status = "Moon: " .. CheckMoon()
        status = status .. "\nPhase: " .. GetGameTime()
        moonLabel:UpdateLabel(status)
    end
end)

-- Initial Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Script Loaded",
    Text = "Press RightShift to toggle UI",
    Duration = 5
})