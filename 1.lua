-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection and Fluent Renewed UI

-- Stop Camera Shake
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

-- Load Fluent Renewed UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

-- Variables for Auto Join
local isAutoJoining = false
local retryDelay = 5 -- Default retry delay in seconds
local selectedServerType = "All" -- Default server type
local fullMoonServers = {}
local defaultAPI = "https://game.hentaiviet.top/fullmoon.php" -- Default API (fixed, not customizable)

-- Get Current Sea
local placeId = game.PlaceId
local Sea1 = placeId == 2753915549
local Sea2 = placeId == 4442272183
local Sea3 = placeId == 7449423635

-- Moon Status Functions
function MoonTextureId()
    if Sea1 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea2 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea3 then
        return game:GetService("Lighting").Sky.MoonTextureId
    end
end

function CheckMoon()
    local moonTextures = {
        moon8 = "http://www.roblox.com/asset/?id=9709150401",
        moon7 = "http://www.roblox.com/asset/?id=9709150086",
        moon6 = "http://www.roblox.com/asset/?id=9709149680",
        moon5 = "http://www.roblox.com/asset/?id=9709149431", -- Full moon
        moon4 = "http://www.roblox.com/asset/?id=9709149052", -- Next night
        moon3 = "http://www.roblox.com/asset/?id=9709143733",
        moon2 = "http://www.roblox.com/asset/?id=9709139597",
        moon1 = "http://www.roblox.com/asset/?id=9709135895"
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

function GetFormattedTime()
    local clockTime = game.Lighting.ClockTime
    local hours = math.floor(clockTime)
    local minutes = math.floor((clockTime - hours) * 60)
    return string.format("%02d:%02d", hours, minutes)
end

-- Setup tabs for Fluent UI
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Servers = Window:AddTab({ Title = "Servers", Icon = "server" }),
    MoonInfo = Window:AddTab({ Title = "Moon Info", Icon = "moon" })
}

-- Initialize SaveManager with config
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("HerinaBloxFruit")
SaveManager:BuildConfigSection(Tabs.Settings)

-- Setup Interface Manager for themes
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("HerinaBloxFruit")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- Current Moon Status Labels
local MoonStatusSection = Tabs.MoonInfo:AddSection("Current Moon Status")

local moonStatusLabel = MoonStatusSection:AddParagraph({
    Title = "Moon Status",
    Content = "Loading..."
})

-- Update Moon Status Information
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local timeInfo = GetMoonTimeInfo()
        local gameTimePhase = GetGameTime()
        
        local statusContent = "Moon: " .. moonStatus .. "\n"
        statusContent = statusContent .. "Time: " .. timeInfo .. "\n"
        statusContent = statusContent .. "Phase: " .. gameTimePhase
        
        moonStatusLabel:SetContent(statusContent)
    end
end)

-- Main tab
local MainSection = Tabs.Main:AddSection("Full Moon Auto Join")

-- Auto Join Toggle
local autoJoinToggle = MainSection:AddToggle("AutoJoinToggle", {
    Title = "Auto Join Full Moon Servers",
    Default = isAutoJoining,
    Callback = function(Value)
        if Value then
            startAutoJoining()
        else
            stopAutoJoining()
        end
    end
})

-- Refresh Servers Button
MainSection:AddButton({
    Title = "Refresh Servers",
    Callback = function()
        Fluent:Notify({
            Title = "Refreshing",
            Content = "Fetching Full Moon servers...",
            Duration = 3
        })
        
        fullMoonServers = fetchFullMoonServers()
        
        if #fullMoonServers > 0 then
            Fluent:Notify({
                Title = "Success",
                Content = "Found " .. #fullMoonServers .. " Full Moon servers",
                Duration = 3
            })
            updateServerList()
        else
            Fluent:Notify({
                Title = "No Servers",
                Content = "No Full Moon servers found",
                Duration = 3
            })
        end
    end
})

-- Settings tab
local SettingsSection = Tabs.Settings:AddSection("Auto Join Settings")

-- Retry Delay Slider
SettingsSection:AddSlider("RetryDelaySlider", {
    Title = "Retry Delay (seconds)",
    Default = retryDelay,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
        SaveManager:Save({ retryDelay = Value })
    end
})

-- Server Type Dropdown
SettingsSection:AddDropdown("ServerTypeDropdown", {
    Title = "Server Type",
    Values = { "All", "TeleportService", "ServerBrowser" },
    Default = selectedServerType,
    Callback = function(Value)
        selectedServerType = Value
        SaveManager:Save({ selectedServerType = Value })
    end
})

-- Servers tab and list management
local ServerListSection = Tabs.Servers:AddSection("Full Moon Servers")
local serverButtons = {}

-- Function to update the server list UI
function updateServerList()
    -- Clear existing buttons
    for _, button in ipairs(serverButtons) do
        button:Destroy()
    end
    serverButtons = {}
    
    -- Add server information
    if #fullMoonServers == 0 then
        local noServersLabel = ServerListSection:AddParagraph({
            Title = "No Servers",
            Content = "No Full Moon servers found. Try refreshing."
        })
        table.insert(serverButtons, noServersLabel)
    else
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end -- Show only the first 5 servers
            
            local serverButton = ServerListSection:AddButton({
                Title = "Server " .. i .. " | Type: " .. (server.serverType or "Unknown"),
                Description = "Players: " .. (server.players or "N/A"),
                Callback = function()
                    Fluent:Notify({
                        Title = "Joining Server",
                        Content = "Attempting to join Full Moon server...",
                        Duration = 3
                    })
                    joinFullMoonServer(server)
                end
            })
            
            table.insert(serverButtons, serverButton)
        end
    end
end

-- Initial server fetch
spawn(function()
    wait(2) -- Wait for UI to load
    fullMoonServers = fetchFullMoonServers()
    updateServerList()
end)

-- Load saved settings
SaveManager:LoadAutoloadConfig()

-- Initial notification
Fluent:Notify({
    Title = "HerinaAuto Join Blox Fruit",
    Content = "Loaded successfully!",
    Duration = 5
})d

-- Function to start auto joining
local function startAutoJoining()
    if isAutoJoining then return end
    
    isAutoJoining = true
    SaveManager:Save({ isAutoJoining = true })
    
    Fluent:Notify({
        Title = "Auto Join",
        Content = "Full Moon Auto Join enabled",
        Duration = 3
    })
    
    spawn(function()
        while isAutoJoining do
            -- Fetch latest servers
            fullMoonServers = fetchFullMoonServers()
            
            -- Check if we have servers
            if #fullMoonServers > 0 then
                -- Filter servers by selected type if needed
                local filteredServers = {}
                
                if selectedServerType == "All" then
                    -- Use all servers
                    filteredServers = fullMoonServers
                elseif selectedServerType == "TeleportService" then
                    -- Filter TeleportService servers
                    for _, server in ipairs(fullMoonServers) do
                        if server.serverType == "TeleportService" then
                            table.insert(filteredServers, server)
                        end
                    end
                elseif selectedServerType == "ServerBrowser" then
                    -- Filter ServerBrowser servers
                    for _, server in ipairs(fullMoonServers) do
                        if server.serverType == "ServerBrowser" then
                            table.insert(filteredServers, server)
                        end
                    end
                end
                
                -- Try to join the first server
                if #filteredServers > 0 then
                    local joined = joinFullMoonServer(filteredServers[1])
                    
                    if joined then
                        Fluent:Notify({
                            Title = "Auto Join",
                            Content = "Successfully joined Full Moon server!",
                            Duration = 3
                        })
                        -- Wait a bit to see if teleport worked
                        wait(5)
                    end
                else
                    print("No suitable Full Moon servers found")
                end
            else
                print("No Full Moon servers found")
            end
            
            -- Wait before retrying
            wait(retryDelay)
        end
    end)
end

-- Function to stop auto joining
local function stopAutoJoining()
    isAutoJoining = false
    SaveManager:Save({ isAutoJoining = false })
    
    Fluent:Notify({
        Title = "Auto Join",
        Content = "Full Moon Auto Join disabled",
        Duration = 3
    })
end