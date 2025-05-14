-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection
-- Mobile & Multi-Exploit Compatible Version

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

-- Error Handling
local function SafeGet(callback)
    local success, result = pcall(callback)
    return success and result or nil
end

-- Variables
local isAutoJoining = false
local retryDelay = 5
local customAPI = "https://game.hentaiviet.top/fullmoon.php"

-- Load UI Library (with error handling)
local Library = nil
local success, error = pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
end)

if not success then
    warn("Failed to load Kavo UI. Trying backup UI...")
    -- You can add a backup UI library here if needed
    return
end

-- Create UI
local Window = Library.CreateLib("HerinaAuto Join Blox Fruit Mobile", "Ocean")

-- Get Current Sea
local placeId = game.PlaceId
local currentSea = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3
}[placeId] or 0

-- Moon Status Functions with Error Handling
function MoonTextureId()
    if currentSea == 3 then
        return SafeGet(function() return Lighting.Sky.MoonTextureId end)
    else
        return SafeGet(function() return Lighting.FantasySky.MoonTextureId end)
    end
end

function CheckMoon()
    local moonTextures = {
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon",
        ["http://www.roblox.com/asset/?id=9709149052"] = "Next Night"
    }
    
    local moonreal = MoonTextureId()
    return moonTextures[moonreal] or "Bad Moon"
end

function GetGameTime()
    local clockTime = Lighting.ClockTime
    return (clockTime >= 18 or clockTime < 5) and "Night" or "Day"
end

-- Server Functions with Enhanced Error Handling
function fetchFullMoonServers()
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(customAPI))
    end)
    
    if not success then
        warn("Failed to fetch servers:", response)
        return {}
    end
    
    local servers = {}
    if type(response) == "table" then
        for _, server in pairs(response) do
            if server.jobId and server.jobId ~= game.JobId then
                table.insert(servers, {
                    jobId = server.jobId,
                    players = server.playing or "N/A"
                })
            end
        end
    end
    
    return servers
end

-- Teleport Function with Retry
function joinServer(server)
    if not server or not server.jobId then return end
    
    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, Players.LocalPlayer)
    end)
    
    if not success then
        warn("Teleport failed:", error)
        wait(1)
        -- Retry once
        pcall(function()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
    end
end

-- Create Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Join")

-- Auto Join Toggle with Status
local statusLabel = MainSection:NewLabel("Status: Idle")
MainSection:NewToggle("Auto Join Full Moon", "Automatically join Full Moon servers", function(state)
    isAutoJoining = state
    statusLabel:UpdateLabel("Status: " .. (state and "Running" or "Stopped"))
    
    if state then
        spawn(function()
            while isAutoJoining do
                local servers = fetchFullMoonServers()
                statusLabel:UpdateLabel("Status: Found " .. #servers .. " servers")
                
                if #servers > 0 then
                    for _, server in ipairs(servers) do
                        if isAutoJoining then
                            statusLabel:UpdateLabel("Status: Joining server...")
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
    statusLabel:UpdateLabel("Status: Found " .. #servers .. " servers")
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
        status = status .. "\nTime: " .. GetGameTime()
        status = status .. "\nSea: " .. currentSea
        moonLabel:UpdateLabel(status)
    end
end)

-- Initial Notification with Error Handling
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Script Loaded",
        Text = "Mobile Version Active - Press RightShift to toggle UI",
        Duration = 5
    })
end)