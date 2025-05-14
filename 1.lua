-- Simplified HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Stop Camera Shake
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

-- Load Redz UI Library
local Library = loadstring(game:HttpGet(("https://raw.githubusercontent.com/daucobonhi/Ui-Redz-V2/refs/heads/main/UiREDzV2.lua")))()
local Window = Library:Create("Full Moon Auto Join", "Blox Fruit")

-- Variables
local isAutoJoining = false
local retryDelay = 5 -- Default retry delay in seconds
local fullMoonServers = {}

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

-- Function to fetch servers from the Full Moon API
local function fetchFullMoonServers()
    local api = "https://game.hentaiviet.top/fullmoon.php"
    local success, response = pcall(function()
        return game:HttpGet(api)
    end)
    
    if not success then
        print("Failed to fetch Full Moon servers")
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
                -- Try to join the first server
                local joined = joinFullMoonServer(fullMoonServers[1])
                
                if joined then
                    print("Successfully joined Full Moon server!")
                    -- Wait a bit to see if teleport worked
                    wait(5)
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

-- Create Status Screen
local StatusScreen = Instance.new("ScreenGui")
local StatusFrame = Instance.new("Frame")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

StatusScreen.Name = "FullMoonStatusScreen"
StatusScreen.Parent = game.CoreGui
StatusScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StatusScreen.ResetOnSpawn = false

StatusFrame.Name = "StatusFrame"
StatusFrame.Parent = StatusScreen
StatusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StatusFrame.BackgroundTransparency = 0.3
StatusFrame.Position = UDim2.new(0, 10, 0, 50)
StatusFrame.Size = UDim2.new(0, 250, 0, 80)
StatusFrame.BorderSizePixel = 0
StatusFrame.Active = true
StatusFrame.Draggable = true

UICorner.Parent = StatusFrame
UICorner.CornerRadius = UDim.new(0, 10)

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
spawn(function()
    while true do
        local localMoonStatus = CheckMoon()
        local timeInfo = GetFormattedTime()
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
        wait(1)
    end
end)

-- UI Setup
local MainTab = Window:Tab("Main")

-- Auto Join Button
MainTab:Button("Start Auto Join", function()
    startAutoJoining()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Full Moon Auto Join",
        Text = "Auto Join Started!",
        Duration = 3
    })
end)

-- Stop Auto Join Button
MainTab:Button("Stop Auto Join", function()
    stopAutoJoining()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Full Moon Auto Join",
        Text = "Auto Join Stopped!",
        Duration = 3
    })
end)

-- Refresh Servers Button
MainTab:Button("Refresh Servers", function()
    fullMoonServers = fetchFullMoonServers()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Full Moon Auto Join",
        Text = "Found " .. #fullMoonServers .. " Full Moon servers",
        Duration = 3
    })
end)

-- Moon Info Tab
local InfoTab = Window:Tab("Moon Info")

-- Create labels for moon info
local moonLabel = InfoTab:Label("Moon: Loading...")
local timeLabel = InfoTab:Label("Time: Loading...")
local phaseLabel = InfoTab:Label("Phase: Loading...")

-- Update moon info
spawn(function()
    while wait(1) do
        moonLabel:Refresh("Moon: " .. CheckMoon())
        timeLabel:Refresh("Time: " .. GetFormattedTime())
        phaseLabel:Refresh("Phase: " .. GetGameTime())
    end
end)

-- Servers Tab
local ServersTab = Window:Tab("Servers")

-- Update server list function
local function updateServerList()
    for i = 1, #fullMoonServers do
        if i <= 5 then -- Show only first 5 servers
            local server = fullMoonServers[i]
            ServersTab:Button("Join Server " .. i .. " | Players: " .. (server.players or "N/A"), function()
                joinFullMoonServer(server)
            end)
        end
    end
end

-- Initial server fetch
spawn(function()
    wait(2) -- Wait for UI to load
    fullMoonServers = fetchFullMoonServers()
    updateServerList()
end)

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Full Moon Auto Join",
    Text = "Script loaded successfully!",
    Duration = 5
})