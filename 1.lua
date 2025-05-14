local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Full Moon Auto Join Hub", "DarkTheme")

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Full Moon Auto Join")

-- Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Settings")

-- Variables
local isAutoJoining = false
local retryDelay = 5 -- Default retry delay in seconds
local selectedServerType = "API1" -- Default server type
local customAPI = "https://game.hentaiviet.top/fullmoon.php" -- Default API
local fullMoonServers = {}

-- Functions

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
        print("Invalid server information")
        return false
    end
    
    local success, errorMsg = pcall(function()
        -- Execute the teleport script
        loadstring(serverInfo.teleportScript)()
    end)
    
    if not success then
        print("Failed to join server: " .. errorMsg)
        return false
    end
    
    return true
end

-- Function to start auto joining
local function startAutoJoining()
    if isAutoJoining then return end
    
    isAutoJoining = true
    
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
                        print("Successfully joined Full Moon server!")
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
end

-- UI Setup

-- Auto Join Toggle
MainSection:NewToggle("Auto Join Full Moon Servers", "Automatically join servers with Full Moon", function(state)
    if state then
        startAutoJoining()
    else
        stopAutoJoining()
    end
end)

-- Retry Delay Slider
SettingsSection:NewSlider("Retry Delay (seconds)", "Set delay between join attempts", 30, 1, function(value)
    retryDelay = value
end)

-- Server Type Dropdown
SettingsSection:NewDropdown("Server Type", "Select server type to join", {"API1", "TeleportService", "ServerBrowser"}, function(currentOption)
    selectedServerType = currentOption
end)

-- Custom API Input
SettingsSection:NewTextBox("Custom API URL", "Enter custom API URL", function(text)
    customAPI = text
end)

-- Refresh Servers Button
MainSection:NewButton("Refresh Servers", "Manually refresh Full Moon servers", function()
    fullMoonServers = fetchFullMoonServers()
    print("Found " .. #fullMoonServers .. " Full Moon servers")
end)

-- Server List
local serverListSection = MainTab:NewSection("Full Moon Servers")

-- Function to update server list
local function updateServerList()
    -- Clear existing labels
    for _, element in ipairs(serverListSection:GetElements()) do
        if element.Name:find("ServerInfo") then
            element:Remove()
        end
    end
    
    -- Add server information
    if #fullMoonServers == 0 then
        serverListSection:NewLabel("No servers found")
    else
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end -- Show only the first 5 servers
            
            local serverLabel = "Server " .. i .. " | Type: " .. (server.serverType or "Unknown") 
                .. " | Players: " .. (server.players or "N/A")
            
            serverListSection:NewLabel(serverLabel)
            
            -- Add join button for this server
            serverListSection:NewButton("Join Server " .. i, "Join this Full Moon server", function()
                joinFullMoonServer(server)
            end)
        end
    end
end

-- Initial server fetch
spawn(function()
    wait(1) -- Wait for UI to load
    fullMoonServers = fetchFullMoonServers()
    updateServerList()
end)

-- Update server list button
MainSection:NewButton("Update Server List", "Update the server list display", function()
    updateServerList()
end)

-- Auto refresh server list
spawn(function()
    while wait(30) do -- Refresh every 30 seconds
        updateServerList()
    end
end)

-- Info Tab
local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:NewSection("Information")

InfoSection:NewLabel("Full Moon Auto Join Hub v1.0")
InfoSection:NewLabel("Made for Blox Fruits")
InfoSection:NewLabel("Press RightShift to toggle GUI")

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Full Moon Auto Join Hub",
    Text = "Loaded successfully! Press RightShift to toggle GUI",
    Duration = 5
})