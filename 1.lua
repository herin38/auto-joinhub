-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Stop Camera Shake
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

-- Load Fluent UI Library
local Library = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/refs/heads/main/Addons/SaveManager.luau"))()
-- InterfaceManager might be missing, so we'll create a minimal version
local InterfaceManager = {}
InterfaceManager.Library = nil
InterfaceManager.SetLibrary = function(self, library) self.Library = library end

-- Try to load the official InterfaceManager if it exists
pcall(function()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/refs/heads/main/Addons/InterfaceManager.luau"))()
end)

-- Create Window
local Window = Library:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "by Herina",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Variables
local isAutoJoining = false
local retryDelay = 5 -- Default retry delay in seconds
local selectedServerType = "API1" -- Default server type
local customAPI = "https://game.hentaiviet.top/fullmoon.php" -- Default API
local fullMoonServers = {}
local showStatusLabel = true

-- Get Current Sea
local placeId = game.PlaceId
local Sea1 = false
local Sea2 = false  
local Sea3 = false

if placeId == 2753915549 then
    Sea1 = true
elseif placeId == 4442272183 then
    Sea2 = true
elseif placeId == 7449423635 then
    Sea3 = true
end

-- Settings System
local HttpService = game:GetService("HttpService")
local SaveFolder = "Herina"
local ConfigFile = game.Players.LocalPlayer.Name .. "-BloxFruit.json"
local Settings = {}

-- Functions for Settings Management
function SaveSettings(key, value)
    if key ~= nil then
        Settings[key] = value
    end
    
    if not isfolder(SaveFolder) then
        makefolder(SaveFolder)
    end
    
    writefile(SaveFolder .. "/" .. ConfigFile, HttpService:JSONEncode(Settings))
end

function LoadSettings()
    local success, result = pcall(function()
        if not isfolder(SaveFolder) then
            makefolder(SaveFolder)
        end
        return HttpService:JSONDecode(readfile(SaveFolder .. "/" .. ConfigFile))
    end)
    
    if success then
        return result
    else
        SaveSettings()
        return LoadSettings()
    end
end

-- Try to load settings
pcall(function()
    Settings = LoadSettings()
    isAutoJoining = Settings.isAutoJoining or false
    retryDelay = Settings.retryDelay or 5
    selectedServerType = Settings.selectedServerType or "API1"
    customAPI = Settings.customAPI or "https://game.hentaiviet.top/fullmoon.php"
    showStatusLabel = Settings.showStatusLabel ~= nil and Settings.showStatusLabel or true
end)

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
    local moon8 = "http://www.roblox.com/asset/?id=9709150401"
    local moon7 = "http://www.roblox.com/asset/?id=9709150086"
    local moon6 = "http://www.roblox.com/asset/?id=9709149680"
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"
    local moon4 = "http://www.roblox.com/asset/?id=9709149052"
    local moon3 = "http://www.roblox.com/asset/?id=9709143733"
    local moon2 = "http://www.roblox.com/asset/?id=9709139597"
    local moon1 = "http://www.roblox.com/asset/?id=9709135895"
    
    local moonreal = MoonTextureId()
    local moonStatus = "Bad Moon"
    
    if moonreal == moon5 then
        moonStatus = "Full Moon"
    elseif moonreal == moon4 then
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

function GetMoonTimeInfo()
    local clockTime = game.Lighting.ClockTime
    local moonStatus = CheckMoon()
    
    if moonStatus == "Full Moon" and clockTime <= 5 then
        return GetFormattedTime() .. " (Moon ends in " .. math.floor(5 - clockTime) .. " minutes)"
    elseif moonStatus == "Full Moon" and (clockTime > 5 and clockTime < 12) then
        return GetFormattedTime() .. " (Fake Moon)"
    elseif moonStatus == "Full Moon" and (clockTime > 12 and clockTime < 18) then
        return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - clockTime) .. " minutes)"
    elseif moonStatus == "Full Moon" and (clockTime > 18 and clockTime <= 24) then
        return GetFormattedTime() .. " (Moon ends in " .. math.floor(24 + 6 - clockTime) .. " minutes)"
    elseif moonStatus == "Next Night" and clockTime < 12 then
        return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - clockTime) .. " minutes)"
    elseif moonStatus == "Next Night" and clockTime > 12 then
        return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 + 12 - clockTime) .. " minutes)"
    end
    
    return GetFormattedTime()
end

-- Function to fetch servers from the Full Moon API
local function fetchFullMoonServers()
    local success, response = pcall(function()
        return game:HttpGet(customAPI)
    end)
    
    if not success then
        print("Failed to fetch Full Moon servers: " .. response)
        return {}
    end
    
    local servers = {}
    
    -- Try to parse the JSON response
    local success, parsedResponse = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response)
    end)
    
    if not success then
        print("Failed to parse API response")
        return {}
    end
    
    -- Check the structure of the response
    if parsedResponse.status == "done" and parsedResponse.results then
        for _, channel in ipairs(parsedResponse.results) do
            if channel.messages then
                for _, message in ipairs(channel.messages) do
                    -- Check for embeds
                    if message.embeds and #message.embeds > 0 then
                        for _, embed in ipairs(message.embeds) do
                            -- Check for fields
                            if embed.fields then
                                local serverInfo = {
                                    jobId = nil,
                                    teleportScript = nil,
                                    serverType = nil,
                                    players = "N/A",
                                    timestamp = message.timestamp
                                }
                                
                                -- Extract server information
                                for _, field in ipairs(embed.fields) do
                                    -- Extract Job ID
                                    if field.name:find("Job ID") then
                                        local jobId = field.value:match("```yaml\n(.-)```") or field.value
                                        jobId = jobId:gsub("```yaml\n", ""):gsub("\n```", ""):gsub("%s+", "")
                                        serverInfo.jobId = jobId
                                    end
                                    
                                    -- Extract Teleport Script
                                    if field.name:find("Join Script") or field.name:find("__Join Script") then
                                        local script = field.value:match("```lua\n(.-)```") or field.value
                                        script = script:gsub("```lua\n", ""):gsub("\n```", "")
                                        serverInfo.teleportScript = script
                                        
                                        -- Determine server type
                                        if script:find("TeleportService") then
                                            serverInfo.serverType = "TeleportService"
                                        elseif script:find("__ServerBrowser") then
                                            serverInfo.serverType = "ServerBrowser"
                                        end
                                    end
                                    
                                    -- Extract Players if available
                                    if field.name:find("Players") then
                                        serverInfo.players = field.value:match("```yaml\n(.-)```") or field.value
                                        serverInfo.players = serverInfo.players:gsub("```yaml\n", ""):gsub("\n```", "")
                                    end
                                end
                                
                                -- Check if embed description has teleport script
                                if embed.description and embed.description:find("Join Script") then
                                    local script = embed.description:match("```lua\n(.-)```")
                                    if script then
                                        serverInfo.teleportScript = script
                                        
                                        -- Determine server type
                                        if script:find("TeleportService") then
                                            serverInfo.serverType = "TeleportService"
                                        elseif script:find("__ServerBrowser") then
                                            serverInfo.serverType = "ServerBrowser"
                                        end
                                    end
                                end
                                
                                -- Add server to list if it has required info
                                if serverInfo.jobId and serverInfo.teleportScript then
                                    table.insert(servers, serverInfo)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort servers by timestamp (newest first)
    table.sort(servers, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return servers
end

-- Function to join a Full Moon server
local function joinFullMoonServer(serverInfo)
    if not serverInfo or not serverInfo.teleportScript then
        Library:Notify({
            Title = "Error",
            Content = "Invalid server information",
            Duration = 5
        })
        return false
    end
    
    local success, errorMsg = pcall(function()
        -- Execute the teleport script
        loadstring(serverInfo.teleportScript)()
    end)
    
    if not success then
        Library:Notify({
            Title = "Error",
            Content = "Failed to join server: " .. errorMsg,
            Duration = 5
        })
        return false
    end
    
    return true
end

-- Function to start auto joining
local function startAutoJoining()
    if isAutoJoining then return end
    
    isAutoJoining = true
    SaveSettings("isAutoJoining", true)
    
    spawn(function()
        while isAutoJoining do
            -- Fetch latest servers
            fullMoonServers = fetchFullMoonServers()
            
            -- Check if we have servers
            if #fullMoonServers > 0 then
                -- Filter servers by selected type if needed
                local filteredServers = {}
                
                if selectedServerType == "API1" then
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
                        Library:Notify({
                            Title = "Success",
                            Content = "Successfully joined Full Moon server!",
                            Duration = 5
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
    SaveSettings("isAutoJoining", false)
end

-- Create Status Screen
local StatusScreen = Instance.new("ScreenGui")
local StatusFrame = Instance.new("Frame")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

StatusScreen.Name = "HerinaStatusScreen"
StatusScreen.Parent = game.CoreGui
StatusScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StatusScreen.ResetOnSpawn = false

StatusFrame.Name = "StatusFrame"
StatusFrame.Parent = StatusScreen
StatusFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
StatusFrame.BackgroundTransparency = 0.1
StatusFrame.Position = UDim2.new(0, 10, 0, 50)
StatusFrame.Size = UDim2.new(0, 250, 0, 100)
StatusFrame.BorderSizePixel = 0
StatusFrame.Active = true
StatusFrame.Draggable = true

UICorner.Parent = StatusFrame
UICorner.CornerRadius = UDim.new(0, 8)

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = StatusFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0, 5)
StatusLabel.Size = UDim2.new(1, -20, 1, -10)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.Text = "Loading..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Update Status Function
local function updateStatus()
    while true do
        if showStatusLabel then
            StatusFrame.Visible = true
            
            local localMoonStatus = CheckMoon()
            local timeInfo = GetMoonTimeInfo()
            local gameTimePhase = GetGameTime()
            
            local statusText = ""
            statusText = statusText .. "Moon: " .. localMoonStatus .. "\n"
            statusText = statusText .. "Time: " .. timeInfo .. "\n"
            statusText = statusText .. "Phase: " .. gameTimePhase
            
            if isAutoJoining then
                statusText = statusText .. "\nAuto Join: ON"
            else
                statusText = statusText .. "\nAuto Join: OFF"
            end
            
            StatusLabel.Text = statusText
        else
            StatusFrame.Visible = false
        end
        
        wait(1)
    end
end

-- Start status updater
spawn(updateStatus)

-- Set up tabs
local MainTab = Window:AddTab({ Title = "Main", Icon = "rbxassetid://9087102675" })
local ServerTab = Window:AddTab({ Title = "Servers", Icon = "rbxassetid://9741251534" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "rbxassetid://9087103497" })
local MoonTab = Window:AddTab({ Title = "Moon Info", Icon = "rbxassetid://9087101050" })
local AboutTab = Window:AddTab({ Title = "About", Icon = "rbxassetid://9087100771" })

-- Create Main Tab sections
local MainSection = MainTab:AddSection("Full Moon Auto Join")

-- Auto Join Toggle
local AutoJoinToggle = MainTab:AddToggle("AutoJoinToggle", {
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

-- Status Label Toggle
local StatusLabelToggle = MainTab:AddToggle("StatusLabelToggle", {
    Title = "Show Status Label",
    Default = showStatusLabel,
    Callback = function(Value)
        showStatusLabel = Value
        SaveSettings("showStatusLabel", Value)
    end
})

-- Refresh Servers Button
local RefreshButton = MainTab:AddButton({
    Title = "Refresh Servers",
    Description = "Manually refresh Full Moon servers",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        Library:Notify({
            Title = "Server List Updated",
            Content = "Found " .. #fullMoonServers .. " Full Moon servers",
            Duration = 3
        })
        updateServerList()
    end
})

-- Create Server Tab
local ServerListSection = ServerTab:AddSection("Available Full Moon Servers")

-- Server List Items
local serverButtons = {}

-- Function to update server list
function updateServerList()
    -- Clear existing server buttons
    for _, button in ipairs(serverButtons) do
        button:Destroy()
    end
    serverButtons = {}
    
    -- Add new server buttons
    if #fullMoonServers == 0 then
        ServerTab:AddParagraph({
            Title = "No Servers Found",
            Content = "No full moon servers are currently available. Try refreshing the list."
        })
    else
        for i, server in ipairs(fullMoonServers) do
            if i > 8 then break end -- Show only the first 8 servers
            
            local buttonTitle = "Server " .. i
            local buttonDesc = "Type: " .. (server.serverType or "Unknown") .. " | Players: " .. (server.players or "N/A")
            
            local serverButton = ServerTab:AddButton({
                Title = buttonTitle,
                Description = buttonDesc,
                Callback = function()
                    joinFullMoonServer(server)
                end
            })
            
            table.insert(serverButtons, serverButton)
        end
    end
end

-- Create Settings Tab sections
local SettingsSection = SettingsTab:AddSection("Auto Join Settings")

-- Retry Delay Slider
local DelaySlider = SettingsTab:AddSlider("RetryDelaySlider", {
    Title = "Retry Delay (seconds)",
    Description = "Set delay between join attempts",
    Default = retryDelay,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
        SaveSettings("retryDelay", Value)
    end
})

-- Server Type Dropdown
local ServerTypeDropdown = SettingsTab:AddDropdown("ServerTypeDropdown", {
    Title = "Server Type",
    Description = "Select server type to join",
    Values = {"API1", "TeleportService", "ServerBrowser"},
    Default = selectedServerType,
    Multi = false,
    Callback = function(Value)
        selectedServerType = Value
        SaveSettings("selectedServerType", Value)
    end
})

-- Custom API Input
local APIInput = SettingsTab:AddInput("CustomAPIInput", {
    Title = "Custom API URL",
    Default = customAPI,
    Placeholder = "Enter custom API URL",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        customAPI = Value
        SaveSettings("customAPI", Value)
    end
})

-- Create Moon Info Tab sections
local MoonInfoSection = MoonTab:AddSection("Current Moon Status")

-- Moon Status
local MoonStatusParagraph = MoonTab:AddParagraph({
    Title = "Moon Status",
    Content = "Loading..."
})

-- Moon Time
local MoonTimeParagraph = MoonTab:AddParagraph({
    Title = "Game Time",
    Content = "Loading..."
})

-- Update moon info
spawn(function()
    while wait(1) do
        MoonStatusParagraph:SetDesc("Current Status: " .. CheckMoon() .. "\nPhase: " .. GetGameTime())
        MoonTimeParagraph:SetDesc("Time: " .. GetFormattedTime() .. "\n" .. GetMoonTimeInfo())
    end
end)

-- Create About Tab sections
local AboutSection = AboutTab:AddSection("About This Script")

AboutTab:AddParagraph({
    Title = "HerinaAuto Join Blox Fruit",
    Content = "Version 1.1 - Fluent UI Edition\nPress RightShift to toggle UI\n\nAuto joins Full Moon servers based on API data."
})

-- Set up SaveManager and InterfaceManager
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)

-- Setup SaveManager
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("Herina")
SaveManager:BuildConfigSection(SettingsTab)

-- Set up theme UI
Window:SelectTab(1)

-- Initial setup
if Settings.isAutoJoining then
    startAutoJoining()
end

-- Initial server fetch
spawn(function()
    wait(1) -- Wait for UI to load
    fullMoonServers = fetchFullMoonServers()
    updateServerList()
end)

-- Notification
Library:Notify({
    Title = "HerinaAuto Join Blox Fruit",
    Content = "Loaded successfully! Press RightShift to toggle GUI",
    Duration = 5
})