-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection and Fluent Renewed UI

-- Error Handling Function
local function safeCall(func, ...)
    if func then
        local success, result = pcall(func, ...)
        if not success then
            warn("Error executing function:", result)
        end
        return success, result
    end
    return false, "Function is nil"
end

-- Stop Camera Shake
local success, CamShake = pcall(function()
    return require(game.ReplicatedStorage.Util.CameraShaker)
end)
if success and CamShake then
    CamShake:Stop()
end

-- Load Fluent Library with Error Handling
local Fluent = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
end)
if success then
    Fluent = result
else
    warn("Failed to load Fluent library:", result)
    return
end

-- Load SaveManager with Error Handling
local SaveManager = nil
success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/addons/SaveManager.lua"))()
end)
if success then
    SaveManager = result
else
    warn("Failed to load SaveManager:", result)
end

-- Load InterfaceManager with Error Handling
local InterfaceManager = nil
success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/addons/InterfaceManager.lua"))()
end)
if success then
    InterfaceManager = result
else
    warn("Failed to load InterfaceManager:", result)
end

-- Create Window with Error Handling
local Window = nil
if Fluent then
    Window = Fluent:CreateWindow({
        Title = "HerinaAuto Join Blox Fruit",
        SubTitle = "Full Moon Auto Joiner",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.End
    })
else
    warn("Cannot create window - Fluent library not loaded")
    return
end

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
local Tabs = {}
if Window then
    Tabs = {
        Main = Window:AddTab({ Title = "Main", Icon = "home" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
        Servers = Window:AddTab({ Title = "Servers", Icon = "server" }),
        MoonInfo = Window:AddTab({ Title = "Moon Info", Icon = "moon" })
    }
end

-- Initialize SaveManager with config
if SaveManager and Fluent then
    SaveManager:SetLibrary(Fluent)
    SaveManager:SetFolder("HerinaBloxFruit")
    if Tabs.Settings then
        SaveManager:BuildConfigSection(Tabs.Settings)
    end
end

-- Setup Interface Manager for themes
if InterfaceManager and Fluent then
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("HerinaBloxFruit")
    if Tabs.Settings then
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    end
end

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
local MainSection = Tabs.Main:AddSection("Main Controls")

-- Auto Join Toggle
MainSection:AddToggle("AutoJoinToggle", {
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
        if SaveManager then
            SaveManager:Save({ retryDelay = Value })
        end
    end
})

-- Server Type Dropdown
SettingsSection:AddDropdown("ServerTypeDropdown", {
    Title = "Server Type",
    Values = { "All", "TeleportService", "ServerBrowser" },
    Default = selectedServerType,
    Callback = function(Value)
        selectedServerType = Value
        if SaveManager then
            SaveManager:Save({ selectedServerType = Value })
        end
    end
})

-- Servers tab and list management
local ServerListSection = Tabs.Servers:AddSection("Server List")
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

-- Add server hop button
MainSection:AddButton({
    Title = "Server Hop",
    Callback = function()
        local success, servers = pcall(function()
            return game:GetService("HttpService"):JSONDecode(
                game:HttpGet(defaultAPI)
            )
        end)
        
        if success and #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            if randomServer then
                local joined = joinFullMoonServer(randomServer)
                if joined and Fluent then
                    Fluent:Notify({
                        Title = "Server Hop",
                        Content = "Attempting to join new server...",
                        Duration = 3
                    })
                end
            end
        else
            if Fluent then
                Fluent:Notify({
                    Title = "Error",
                    Content = "No servers available for hopping",
                    Duration = 3
                })
            end
        end
    end
})

-- Add status indicator
local StatusSection = Tabs.Main:AddSection("Status")

local statusLabel = StatusSection:AddParagraph({
    Title = "Auto Join Status",
    Content = "Disabled"
})

-- Update status label
spawn(function()
    while wait(1) do
        if statusLabel then
            local status = isAutoJoining and "Enabled" or "Disabled"
            local content = "Status: " .. status
            if isAutoJoining then
                content = content .. "\nRetry Delay: " .. retryDelay .. "s"
                content = content .. "\nServer Type: " .. selectedServerType
            end
            pcall(function()
                statusLabel:SetContent(content)
            end)
        end
    end
end)

-- Add server count indicator
local serverCountLabel = ServerListSection:AddParagraph({
    Title = "Server Count",
    Content = "0 servers found"
})

-- Update server count
function updateServerCount()
    if serverCountLabel then
        pcall(function()
            serverCountLabel:SetContent(#fullMoonServers .. " servers found")
        end)
    end
end

-- Hook the server count update to the refresh function
local originalRefresh = fetchFullMoonServers
fetchFullMoonServers = function()
    local servers = originalRefresh()
    updateServerCount()
    return servers
end

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

-- Initial notification
if Fluent then
    Fluent:Notify({
        Title = "HerinaAuto Join Blox Fruit",
        Content = "Loaded successfully!",
        Duration = 5
    })
end

-- Initial server fetch
spawn(function()
    wait(2) -- Wait for UI to load
    local success, servers = pcall(fetchFullMoonServers)
    if success then
        fullMoonServers = servers
        updateServerCount()
        updateServerList()
    end
end)