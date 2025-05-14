-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Stop Camera Shake
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

-- Load UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("HerinaAuto Join Blox Fruit", "Midnight")

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

-- Moon Status Functions from the second script
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

-- UI Setup

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Full Moon Auto Join")

-- Auto Join Toggle
MainSection:NewToggle("Auto Join Full Moon Servers", "Automatically join servers with Full Moon", function(state)
    if state then
        startAutoJoining()
    else
        stopAutoJoining()
    end
end)

-- Status Label Toggle
MainSection:NewToggle("Show Status Label", "Show/Hide the floating status label", function(state)
    showStatusLabel = state
    SaveSettings("showStatusLabel", state)
end)

-- Server List Section
local ServerSection = MainTab:NewSection("Server List")

-- Function to update server list
local function updateServerList()
    -- Clear existing buttons
    for _, element in ipairs(ServerSection:GetElements()) do
        if element.Name:find("ServerButton") then
            element:Remove()
        end
    end
    
    -- Add server information
    if #fullMoonServers == 0 then
        ServerSection:NewLabel("No servers found")
    else
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end -- Show only the first 5 servers
            
            -- Add join button for this server
            local serverLabel = "Join Server " .. i .. " | Type: " .. (server.serverType or "Unknown") .. 
                " | Players: " .. (server.players or "N/A")
            
            ServerSection:NewButton(serverLabel, "Join this Full Moon server", function()
                joinFullMoonServer(server)
            end)
        end
    end
end

-- Refresh Servers Button
MainSection:NewButton("Refresh Servers", "Manually refresh Full Moon servers", function()
    fullMoonServers = fetchFullMoonServers()
    print("Found " .. #fullMoonServers .. " Full Moon servers")
    updateServerList()
end)

-- Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Settings")

-- Retry Delay Slider
SettingsSection:NewSlider("Retry Delay (seconds)", "Set delay between join attempts", 30, 1, function(value)
    retryDelay = value
    SaveSettings("retryDelay", value)
end)

-- Server Type Dropdown
SettingsSection:NewDropdown("Server Type", "Select server type to join", {"API1", "TeleportService", "ServerBrowser"}, function(currentOption)
    selectedServerType = currentOption
    SaveSettings("selectedServerType", currentOption)
end)

-- Custom API Input
SettingsSection:NewTextBox("Custom API URL", "Enter custom API URL", function(text)
    customAPI = text
    SaveSettings("customAPI", text)
end)

-- Moon Info Tab
local MoonTab = Window:NewTab("Moon Info")
local MoonSection = MoonTab:NewSection("Current Moon Status")

local CurrentMoonLabel = MoonSection:NewLabel("Moon: Loading...")
local CurrentTimeLabel = MoonSection:NewLabel("Time: Loading...")
local CurrentPhaseLabel = MoonSection:NewLabel("Phase: Loading...")

-- Update moon info
spawn(function()
    while wait(1) do
        CurrentMoonLabel:UpdateLabel("Moon: " .. CheckMoon())
        CurrentTimeLabel:UpdateLabel("Time: " .. GetFormattedTime())
        CurrentPhaseLabel:UpdateLabel("Phase: " .. GetGameTime())
    end
end)

-- About Tab
local AboutTab = Window:NewTab("About")
local AboutSection = AboutTab:NewSection("About")

AboutSection:NewLabel("HerinaAuto Join Blox Fruit v1.0")
AboutSection:NewLabel("Press RightShift to toggle UI")

-- Race V4 Tab
local RaceV4Tab = Window:NewTab("Race V4")
local RaceV4Section = RaceV4Tab:NewSection("Race V4")

if not Sea3 then
    RaceV4Section:NewLabel("You Are Not in Third Sea!!")
else
    RaceV4Section:NewSection("👾 Race V4 👾")
    
    RaceV4Section:NewButton("Teleport To Top Of GreatTree", "Teleports you to the Great Tree", function()
        Tween(CFrame.new(2947.556884765625, 2281.630615234375, -7213.54931640625))
    end)
    
    RaceV4Section:NewButton("Teleport To Temple Of Time", "Teleports you to the Temple of Time", function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(28286.35546875, 14895.3017578125, 102.62469482421875)
    end)
    
    RaceV4Section:NewButton("Teleport To Lever Pull", "Teleports you to the Lever", function()
        Tween(CFrame.new(28575.181640625, 14936.6279296875, 72.31636810302734))
    end)
    
    RaceV4Section:NewButton("Teleport To Ancient One", "Must be in Temple Of Time!", function()
        Tween(CFrame.new(28981.552734375, 14888.4267578125, -120.245849609375))
    end)
    
    RaceV4Section:NewButton("Unlock Lever", "Unlocks the Temple of Time lever", function()
        Library:Notify("Unlocked")
        if game:GetService("Workspace").Map["Temple of Time"].Lever.Prompt:FindFirstChild("ProximityPrompt") then
            game:GetService("Workspace").Map["Temple of Time"].Lever.Prompt:FindFirstChild("ProximityPrompt"):Remove()
        end
        
        local ProximityPrompt = Instance.new("ProximityPrompt")
        ProximityPrompt.Parent = game:GetService("Workspace").Map["Temple of Time"].Lever.Prompt
        ProximityPrompt.MaxActivationDistance = 10
        ProximityPrompt.ActionText = "Secrets Beholds Inside"
        ProximityPrompt.ObjectText = "An unknown lever of time"
        
        ProximityPrompt.Triggered:Connect(function()
            local part = game:GetService("Workspace").Map["Temple of Time"].MainDoor1
            local partnew = game:GetService("Workspace").Map["Temple of Time"].MainDoor2
            local TweenService = game:GetService("TweenService")
            
            -- Door 1 Animation
            local tween = TweenService:Create(part, 
                TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                {Position = part.Position + Vector3.new(0, -50, 0)}
            )
            tween:Play()
            
            -- Door 2 Animation
            local tween2 = TweenService:Create(partnew,
                TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                {Position = partnew.Position + Vector3.new(0, -50, 0)}
            )
            tween2:Play()
            
            -- Sound Effect
            local SoundSFX = Instance.new("Sound")
            SoundSFX.Parent = workspace
            SoundSFX.SoundId = "rbxassetid://1904813041"
            SoundSFX.Name = "POwfpxzxzfFfFF"
            SoundSFX:Play()
            
            -- Cleanup
            ProximityPrompt:Remove()
            wait(5)
            workspace:FindFirstChild("POwfpxzxzfFfFF"):Remove()
            
            -- Remove NoGlitching parts
            for _, v in pairs(game:GetService("Workspace").Map["Temple of Time"]:GetChildren()) do
                if v.Name == "NoGlitching" then
                    v:Remove()
                end
            end
        end)
    end)
    
    RaceV4Section:NewButton("Clock Access", "Removes barriers in Clock Room", function()
        game:GetService("Workspace").Map["Temple of Time"].DoNotEnter:Remove()
        game:GetService("Workspace").Map["Temple of Time"].ClockRoomExit:Remove()
    end)
    
    RaceV4Section:NewToggle("Disable Inf Stairs", "Disables infinite stairs effect", function(value)
        if game.Players.LocalPlayer.Character:FindFirstChild("InfiniteStairs") then
            game.Players.LocalPlayer.Character.InfiniteStairs.Disabled = value
        end
    end)
    
    -- Race Door Teleports
    local doors = {
        ["Cyborg"] = CFrame.new(28492.4140625, 14894.4267578125, -422.1100158691406),
        ["Fish"] = CFrame.new(28224.056640625, 14889.4267578125, -210.5872039794922),
        ["Ghoul"] = CFrame.new(28672.720703125, 14889.1279296875, 454.5961608886719),
        ["Human"] = CFrame.new(29237.294921875, 14889.4267578125, -206.94955444335938),
        ["Mink"] = CFrame.new(29020.66015625, 14889.4267578125, -379.2682800292969),
        ["Sky"] = CFrame.new(28967.408203125, 14918.0751953125, 234.31198120117188)
    }
    
    for name, cf in pairs(doors) do
        RaceV4Section:NewButton("Teleport " .. name .. " Door", "Must be in Temple Of Time!", function()
            Tween(cf)
        end)
    end
    
    RaceV4Section:NewSection("🍃 Auto Complete Trials 🍃")
    
    RaceV4Section:NewButton("Auto Upgrade Tier", "Automatically upgrades your race tier", function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer('UpgradeRace','Buy')
    end)
    
    RaceV4Section:NewButton("Auto Complete Angel Trial", "Completes the Sky/Angel trial", function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Workspace.Map.SkyTrial.Model.FinishPart.CFrame
    end)
    
    RaceV4Section:NewButton("Auto Complete Rabbit Trial", "Completes the Mink/Rabbit trial", function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Map.MinkTrial.Ceiling.CFrame * CFrame.new(0,-5,0)
    end)
    
    RaceV4Section:NewButton("Auto Complete Cyborg Trial", "Completes the Cyborg trial", function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,300,0)
    end)
end

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
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "HerinaAuto Join Blox Fruit",
    Text = "Loaded successfully! Press RightShift to toggle GUI",
    Duration = 5
})
