-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection and Fluent Renewed UI

-- Error Handling Function
local function safeRequire(path)
    local success, result = pcall(require, path)
    if not success then
        warn("Failed to require:", path, result)
        return nil
    end
    return result
end

-- Stop Camera Shake
local CamShake = safeRequire(game.ReplicatedStorage.Util.CameraShaker)
if CamShake then
    CamShake:Stop()
end

-- Load Fluent Library (using raw GitHub URLs)
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Fluent.luau"))()
end)

if not success then
    warn("Failed to load Fluent library:", Fluent)
    return
end

-- Load SaveManager
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Addons/SaveManager.luau"))()

-- Load InterfaceManager
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Addons/InterfaceManager.luau"))()

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

-- Setup tabs for Fluent Renewed UI
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

-- Main tab components
local MainSection = Tabs.Main:AddSection("Full Moon Auto Join")

MainSection:AddToggle("AutoJoinToggle", {
    Title = "Auto Join Full Moon Servers",
    Default = false,
    Description = "Automatically join servers with Full Moon",
    Callback = function(Value)
        if Value then
            startAutoJoining()
        else
            stopAutoJoining()
        end
    end
})

MainSection:AddButton({
    Title = "Refresh Servers",
    Description = "Fetch new Full Moon servers",
    Callback = function()
        Fluent:Notify({
            Title = "Refreshing",
            Content = "Fetching Full Moon servers...",
            Duration = 3
        })
        
        local servers = fetchFullMoonServers()
        if #servers > 0 then
            fullMoonServers = servers
            updateServerList()
            Fluent:Notify({
                Title = "Success",
                Content = string.format("Found %d Full Moon servers", #servers),
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "No Servers",
                Content = "No Full Moon servers found",
                Duration = 3
            })
        end
    end
})

-- Settings tab components
local SettingsSection = Tabs.Settings:AddSection("Auto Join Settings")

SettingsSection:AddSlider("RetryDelay", {
    Title = "Retry Delay",
    Description = "Seconds to wait between server checks",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
        SaveManager:Save("AutoJoinConfig")
    end
})

SettingsSection:AddDropdown("ServerType", {
    Title = "Server Type",
    Description = "Filter servers by type",
    Values = {"All", "TeleportService", "ServerBrowser"},
    Default = "All",
    Multi = false,
    Callback = function(Value)
        selectedServerType = Value
        SaveManager:Save("AutoJoinConfig")
    end
})

-- Moon Info tab components
local MoonSection = Tabs.MoonInfo:AddSection("Current Moon Status")

local moonStatusLabel = MoonSection:AddParagraph({
    Title = "Moon Phase",
    Content = "Checking..."
})

-- Update moon status
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local timeInfo = GetMoonTimeInfo()
        local gameTimePhase = GetGameTime()
        
        local content = string.format(
            "Status: %s\nTime: %s\nPhase: %s",
            moonStatus,
            timeInfo,
            gameTimePhase
        )
        
        moonStatusLabel:SetContent(content)
    end
end)

-- Server list components
local ServerSection = Tabs.Servers:AddSection("Available Servers")

local serverListLabel = ServerSection:AddParagraph({
    Title = "Server List",
    Content = "No servers found"
})

-- Update server list
function updateServerList()
    local content = ""
    if #fullMoonServers == 0 then
        content = "No Full Moon servers available"
    else
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end
            content = content .. string.format(
                "\nServer %d | Players: %s | Type: %s",
                i,
                server.players or "N/A",
                server.serverType or "Unknown"
            )
        end
    end
    serverListLabel:SetContent(content)
end

-- Load saved settings
SaveManager:LoadAutoloadConfig()

-- Initial notification
Fluent:Notify({
    Title = "HerinaAuto Join Blox Fruit",
    Content = "Successfully loaded!",
    Duration = 5
})

-- Function to fetch Full Moon servers from API with error handling
function fetchFullMoonServers()
    local servers = {}
    
    local success, response = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:HttpGet(defaultAPI)
        )
    end)
    
    if success and response then
        for _, server in ipairs(response) do
            if type(server) == "table" then
                table.insert(servers, {
                    jobId = server.jobId,
                    players = server.playing or "N/A",
                    serverType = server.type or "Unknown",
                    placeId = server.placeId or game.PlaceId
                })
            end
        end
    else
        if Fluent then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to fetch servers from API",
                Duration = 3
            })
        end
        warn("Failed to fetch servers:", response)
    end
    
    return servers
end

-- Function to join a Full Moon server with error handling
function joinFullMoonServer(server)
    if not server or not server.jobId then
        warn("Invalid server data")
        return false
    end
    
    local success, result = pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            server.placeId or game.PlaceId,
            server.jobId,
            game.Players.LocalPlayer
        )
    end)
    
    if not success then
        warn("Failed to teleport:", result)
    end
    
    return success
end

-- Function to start auto joining with error handling
function startAutoJoining()
    if isAutoJoining then return end
    
    isAutoJoining = true
    if SaveManager then
        SaveManager:Save({ isAutoJoining = true })
    end
    
    if Fluent then
        Fluent:Notify({
            Title = "Auto Join",
            Content = "Full Moon Auto Join enabled",
            Duration = 3
        })
    end
    
    spawn(function()
        while isAutoJoining do
            local success, servers = pcall(fetchFullMoonServers)
            if success and #servers > 0 then
                local filteredServers = {}
                
                for _, server in ipairs(servers) do
                    if selectedServerType == "All" or server.serverType == selectedServerType then
                        table.insert(filteredServers, server)
                    end
                end
                
                if #filteredServers > 0 then
                    local joined = joinFullMoonServer(filteredServers[1])
                    if joined and Fluent then
                        Fluent:Notify({
                            Title = "Auto Join",
                            Content = "Successfully joined Full Moon server!",
                            Duration = 3
                        })
                        wait(5)
                    end
                end
            end
            wait(retryDelay)
        end
    end)
end

-- Function to stop auto joining
function stopAutoJoining()
    isAutoJoining = false
    if SaveManager then
        SaveManager:Save({ isAutoJoining = false })
    end
    
    if Fluent then
        Fluent:Notify({
            Title = "Auto Join",
            Content = "Full Moon Auto Join disabled",
            Duration = 3
        })
    end
end

-- Function to get moon time information
function GetMoonTimeInfo()
    local clockTime = game.Lighting.ClockTime
    local timeStr = GetFormattedTime()
    
    -- Calculate time until night/day
    local timeUntil = ""
    if clockTime >= 5 and clockTime < 18 then
        -- It's day, calculate time until night
        local hoursUntil = 18 - clockTime
        if hoursUntil < 0 then hoursUntil = hoursUntil + 24 end
        timeUntil = string.format("%.1f hours until night", hoursUntil)
    else
        -- It's night, calculate time until day
        local hoursUntil = 5 - clockTime
        if hoursUntil < 0 then hoursUntil = hoursUntil + 24 end
        timeUntil = string.format("%.1f hours until day", hoursUntil)
    end
    
    return timeStr .. " (" .. timeUntil .. ")"
end
end