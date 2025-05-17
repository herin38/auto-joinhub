repeat task.wait() until game:IsLoaded()

-- Debug Function
local function debugPrint(...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        str = str .. tostring(v) .. " "
    end

-- Key System
local function validateKey()
    local userKey = getgenv().Key
    debugPrint("Checking key:", userKey)
    
    if not userKey or userKey == "" then
        debugPrint("No key provided")
        return false
    end
    
    -- Clean the key
    userKey = tostring(userKey):gsub("%s+", "")
    debugPrint("Cleaned key:", userKey)
    
    -- Get API response
    local success, result
    local tries = 0
    repeat
        tries = tries + 1
        debugPrint("Attempt", tries, "to fetch API")
        
        success = pcall(function()
            local raw = game:HttpGet("https://bot.hentaiviet.top/index.php?action=list")
            debugPrint("Raw response:", raw)
            result = game:GetService("HttpService"):JSONDecode(raw)
        end)
        
        if not success then
            debugPrint("API call failed, retrying in 1 second")
            task.wait(1)
        end
    until success or tries >= 3
    
    if not success then
        debugPrint("Failed to fetch API after 3 attempts")
        return false
    end
    
    debugPrint("API Response received")
    
    -- Validate response format
    if type(result) ~= "table" or not result.success or not result.keys then
        debugPrint("Invalid API response format")
        return false
    end
    
    -- Check key and banned status
    for _, keyData in pairs(result.keys) do
        local apiKey = tostring(keyData.key):gsub("%s+", "")
        debugPrint("Comparing with API key:", apiKey)
        
        if apiKey == userKey then
            debugPrint("Key match found!")
            -- Check if key is banned
            if keyData.banned then
                debugPrint("Key is banned!")
                game.Players.LocalPlayer:Kick("Your key has been banned!\nBan Date: " .. (keyData.timestamp or "Unknown"))
                return false
            end
            return true
        end
    end
    
    debugPrint("No matching key found")
    return false
end

-- Wait for key to be set (max 5 seconds)
local startTime = tick()
repeat task.wait() until getgenv().Key ~= "" or tick() - startTime > 5

-- Check key
if not getgenv().Key or getgenv().Key == "" then
    game.Players.LocalPlayer:Kick("Please set your key before running the script!\n\nExample:\ngetgenv().Key = 'YOUR_KEY'\nloadstring(game:HttpGet('script_url'))()")
    return
end

-- Validate key
if not validateKey() then
    game.Players.LocalPlayer:Kick("Invalid key! Please make sure you're using a valid key.")
    return
end

debugPrint("Key validation successful - loading script...")

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon & Mirage Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "moon" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    About = Window:AddTab({ Title = "About", Icon = "help-circle" })
}

local Options = Fluent.Options
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local isAutoJoining = false
local isMirageAutoJoining = false
local retryDelay = 5
local selectedServerType = "API1"
local customAPI = "https://game.hentaiviet.top/fullmoon.php"
local mirageAPI = "https://game.hentaiviet.top/MirageIsland.php"
local fullMoonServers = {}
local mirageServers = {}
local showStatusLabel = true

local SaveFolder = "Herina"
local ConfigFile = Players.LocalPlayer.Name .. "-BloxFruit.json"
local Settings = {}

-- Sea variables for different maps
local Sea1 = false
local Sea2 = false
local Sea3 = true -- Default to Sea3 since it uses regular Sky

-- Initialize Sea based on PlaceId
if game.PlaceId == 2753915549 then 
    Sea1 = true
    Sea2 = false
    Sea3 = false
elseif game.PlaceId == 4442272183 then
    Sea1 = false
    Sea2 = true
    Sea3 = false
elseif game.PlaceId == 7449423635 then
    Sea1 = false
    Sea2 = false
    Sea3 = true
end

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
    return success and result or {}
end

Settings = LoadSettings()
isAutoJoining = Settings.isAutoJoining or false
isMirageAutoJoining = Settings.isMirageAutoJoining or false
retryDelay = Settings.retryDelay or 5
selectedServerType = Settings.selectedServerType or "API1"
customAPI = Settings.customAPI or "https://game.hentaiviet.top/fullmoon.php"
showStatusLabel = Settings.showStatusLabel

if showStatusLabel == nil then
    showStatusLabel = true -- Default to visible if setting not found
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
StatusFrame.Size = UDim2.new(0, 200, 0, 95)
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
StatusLabel.TextSize = 13
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Create floating toggle button for mobile
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 44, 0, 44)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -22)
ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BackgroundTransparency = 0.3
ToggleButton.Image = "rbxassetid://7733955740"
ToggleButton.Parent = StatusScreen
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.ZIndex = 10

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local function MoonTextureId()
    if Sea1 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea2 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea3 then
        return game:GetService("Lighting").Sky.MoonTextureId
    end
end

local function CheckMoon()
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

local function GetGameTime()
    local clockTime = game.Lighting.ClockTime
    if clockTime >= 18 or clockTime < 5 then
        return "Night"
    else
        return "Day"
    end
end

local function GetFormattedTime()
    local clockTime = game.Lighting.ClockTime
    local hours = math.floor(clockTime)
    local minutes = math.floor((clockTime - hours) * 60)
    return string.format("%02d:%02d", hours, minutes)
end

local function GetMoonTimeInfo()
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

-- Status Label updater function
local function updateStatusLabel()
    while true do
        if showStatusLabel then
            StatusFrame.Visible = true
            
            local localMoonStatus = CheckMoon()
            local timeInfo = GetMoonTimeInfo()
            local gameTimePhase = GetGameTime()
            
            -- Check Mirage Island status
            local mirageStatus = "Not Spawning ❌"
            local success, result = pcall(function()
                local workspace = game:GetService("Workspace")
                if workspace:FindFirstChild("_WorldOrigin") 
                and workspace._WorldOrigin:FindFirstChild("Locations") 
                and workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") then
                    return true
                end
                return false
            end)
            if success and result then
                mirageStatus = "Spawning ✅"
            end
            
            local statusText = ""
            statusText = statusText .. "Moon: " .. localMoonStatus .. "\n"
            statusText = statusText .. "Time: " .. timeInfo .. "\n"
            statusText = statusText .. "Phase: " .. gameTimePhase .. "\n"
            statusText = statusText .. "Mirage: " .. mirageStatus .. "\n"
            
            if isAutoJoining then
                statusText = statusText .. "Full Moon: ON"
            else
                statusText = statusText .. "Full Moon: OFF"
            end
            
            if isMirageAutoJoining then
                statusText = statusText .. " | Mirage: ON"
            else
                statusText = statusText .. " | Mirage: OFF"
            end
            
            StatusLabel.Text = statusText
        else
            StatusFrame.Visible = false
        end
        
        wait(1)
    end
end

-- Start status label updater
spawn(updateStatusLabel)

-- Debug function
local function DebugPrint(message)
    print("[DEBUG] " .. message)
end

-- Continuous status updates
local lastMoonStatus = ""
spawn(function()
    while wait(1) do
        local currentMoonStatus = CheckMoon()
        
        -- Notify on moon status change
        if currentMoonStatus ~= lastMoonStatus then
            if currentMoonStatus == "Full Moon" then
                Fluent:Notify({
                    Title = "Full Moon Alert!",
                    Content = "Full Moon has appeared!",
                    Duration = 5
                })
            elseif currentMoonStatus == "Next Night" then
                Fluent:Notify({
                    Title = "Moon Alert!",
                    Content = "Full Moon coming next night!",
                    Duration = 5
                })
            end
            lastMoonStatus = currentMoonStatus
        end
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

-- Function to join Mirage server
local function joinMirageServer(server)
    if type(server) ~= "table" or (not server.teleportScript and not server.jobId) then 
        return false 
    end
    
    local success = pcall(function()
        if server.jobId and server.jobId:match("^%s*(.-)%s*$") ~= "" then
            local jobId = server.jobId:match("^%s*(.-)%s*$") -- trim whitespace
            local TeleportService = game:GetService("TeleportService")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId)
        elseif server.teleportScript and server.teleportScript:match("^%s*(.-)%s*$") ~= "" then
            loadstring(server.teleportScript)()
        end
    end)
    
    if not success then
        warn("Failed to join Mirage server")
        return false
    end
    
    return true
end

-- Function to fetch Mirage Island servers
local function fetchMirageServers()
    local success, response = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet(mirageAPI))
    end)
    
    if not success then 
        warn("Failed to fetch Mirage servers:", response)
        return {} 
    end
    
    local servers = {}
    if type(response) == "table" and response.status == "done" and response.results then
        for _, result in ipairs(response.results) do
            if type(result) == "table" and result.messages then
                for _, message in ipairs(result.messages) do
                    if type(message) == "table" and message.embeds then
                        for _, embed in ipairs(message.embeds) do
                            if type(embed) == "table" and embed.fields then
                                local serverInfo = {
                                    jobId = nil,
                                    teleportScript = nil,
                                    serverType = "Unknown",
                                    players = "N/A"
                                }
                                
                                for _, field in ipairs(embed.fields) do
                                    if field.name:find("Job ID") then
                                        serverInfo.jobId = field.value:match("```yaml\n(.-)```") or field.value
                                    elseif field.name:find("Join Script") then
                                        serverInfo.teleportScript = field.value:match("```lua\n(.-)```") or field.value
                                        if serverInfo.teleportScript:find("TeleportService") then
                                            serverInfo.serverType = "TeleportService"
                                        elseif serverInfo.teleportScript:find("__ServerBrowser") then
                                            serverInfo.serverType = "ServerBrowser"
                                        end
                                    elseif field.name:find("Players") then
                                        serverInfo.players = field.value:match("```yaml\n(.-)```") or field.value
                                    end
                                end
                                
                                -- Only add server if it has either jobId or teleportScript
                                if (serverInfo.jobId and serverInfo.jobId:match("^%s*(.-)%s*$") ~= "") or 
                                   (serverInfo.teleportScript and serverInfo.teleportScript:match("^%s*(.-)%s*$") ~= "") then
                                    table.insert(servers, serverInfo)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return servers
end

-- Function to start Mirage Island auto joining
local function startMirageAutoJoining()
    if isMirageAutoJoining then return end
    isMirageAutoJoining = true
    SaveSettings("isMirageAutoJoining", true)
    
    Fluent:Notify({
        Title = "Auto Join",
        Content = "Started Mirage Island auto join",
        Duration = 3
    })
    
    spawn(function()
        while isMirageAutoJoining do
            local servers = fetchMirageServers()
            
            if #servers > 0 then
                Fluent:Notify({
                    Title = "Mirage Island",
                    Content = string.format("Found %d servers, attempting to join...", #servers),
                    Duration = 3
                })
                
                for _, server in ipairs(servers) do
                    if not isMirageAutoJoining then break end
                    
                    if selectedServerType == "API1" or server.serverType == selectedServerType then
                        if joinMirageServer(server) then
                            wait(5) -- Wait before trying next server if join fails
                            break -- Exit loop if join was successful
                        end
                    end
                end
            end
            
            wait(retryDelay)
        end
    end)
end

-- Function to stop Mirage Island auto joining
local function stopMirageAutoJoining()
    isMirageAutoJoining = false
    SaveSettings("isMirageAutoJoining", false)
    
    Fluent:Notify({
        Title = "Auto Join",
        Content = "Stopped Mirage Island auto join",
        Duration = 3
    })
end

-- Create Main tab sections
local FullMoonSection = Tabs.Main:AddSection("Full Moon")
local StatusSection = Tabs.Main:AddSection("Status") -- Status controls within Main tab
local MirageSection = Tabs.Main:AddSection("Mirage Island")

-- Add Show Status Label toggle in Main tab
StatusSection:AddToggle("ShowStatusLabel", {
    Title = "Show Status Label",
    Default = showStatusLabel,
    Description = "Show/Hide the floating status label"
}):OnChanged(function(Value)
    showStatusLabel = Value
    SaveSettings("showStatusLabel", Value)
    StatusFrame.Visible = Value
end)

-- Full Moon Auto Join Toggle
do
    local fullMoonToggle = FullMoonSection:AddToggle("AutoJoinFullMoon", {
        Title = "Auto Join Full Moon",
        Default = Settings.isAutoJoining or false,
        Description = "Automatically join servers with Full Moon"
    })

    fullMoonToggle:OnChanged(function(Value)
        if Value then
            startAutoJoining()
        else
            stopAutoJoining()
        end
    end)

    FullMoonSection:AddButton({
        Title = "Refresh Full Moon Servers",
        Description = "Manually refresh server list",
        Callback = function()
            fullMoonServers = fetchFullMoonServers()
            Fluent:Notify({
                Title = "Full Moon Servers",
                Content = string.format("Found %d servers", #fullMoonServers),
                Duration = 3
            })
        end
    })
end

-- Add Mirage Island toggle with proper implementation
MirageSection:AddToggle("AutoJoinMirage", {
    Title = "Auto Join Mirage Island",
    Default = Settings.isMirageAutoJoining or false,
    Description = "Automatically join servers with Mirage Island"
}):OnChanged(function(Value)
    if Value then
        startMirageAutoJoining()
    else
        stopMirageAutoJoining()
    end
end)

MirageSection:AddButton({
    Title = "Refresh Mirage Servers",
    Description = "Manually refresh Mirage Island server list",
    Callback = function()
        local servers = fetchMirageServers()
        Fluent:Notify({
            Title = "Mirage Island",
            Content = string.format("Found %d servers", #servers),
            Duration = 3
        })
    end
})

-- Settings tab
do
    Tabs.Settings:AddDropdown("ServerType", {
        Title = "Server Type",
        Values = {"API1", "TeleportService", "ServerBrowser"},
        Default = selectedServerType,
        Description = "Select server join method"
    }):OnChanged(function(Value)
        selectedServerType = Value
        SaveSettings("selectedServerType", Value)
    end)

    Tabs.Settings:AddSlider("RetryDelay", {
        Title = "Retry Delay (sec)",
        Description = "Time between join attempts",
        Default = retryDelay,
        Min = 1,
        Max = 30
    }):OnChanged(function(Value)
        retryDelay = Value
        SaveSettings("retryDelay", Value)
    end)
end

Tabs.About:AddParagraph({
    Title = "About",
    Content = "HerinaAuto Join Blox Fruit using dawid-scripts Fluent GUI\nPress RightShift to toggle UI."
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("HerinaFluent")
SaveManager:SetFolder("HerinaFluent/BloxFruit")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)

-- Add GUI toggle functionality with proper state management
local guiVisible = true

-- Function to toggle GUI visibility
local function toggleGui()
    guiVisible = not guiVisible
    
    -- Toggle main window
    if Window then
        Window.Enabled = guiVisible
    end
    
    -- Toggle status frame
    if StatusFrame then
        StatusFrame.Visible = guiVisible and showStatusLabel
    end
    
    -- Update button appearance
    if ToggleButton then
        ToggleButton.BackgroundColor3 = guiVisible and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 0, 0)
    end
    
    -- Show notification
    Fluent:Notify({
        Title = "GUI Visibility",
        Content = guiVisible and "GUI Enabled" or "GUI Disabled",
        Duration = 2
    })
end

-- Handle toggle button click
ToggleButton.MouseButton1Down:Connect(function()
    toggleGui()
end)

-- Also handle RightShift key
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        toggleGui()
    end
end)

-- Make toggle button draggable
local dragging = false
local dragStart
local startPos

local function updateDrag(input)
    if dragging and ToggleButton and ToggleButton.Parent then
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        
        -- Constrain to screen bounds
        local buttonSize = ToggleButton.AbsoluteSize
        local screenSize = ToggleButton.Parent.AbsoluteSize
        local minX = 0
        local maxX = screenSize.X - buttonSize.X
        local minY = 0
        local maxY = screenSize.Y - buttonSize.Y
        
        position = UDim2.new(
            0,
            math.clamp(position.X.Offset, minX, maxX),
            0,
            math.clamp(position.Y.Offset, minY, maxY)
        )
        
        ToggleButton.Position = position
    end
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        updateDrag(input)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Initialize GUI state
Window.Enabled = true
if StatusFrame then
    StatusFrame.Visible = showStatusLabel
end

Fluent:Notify({ Title = "HerinaAuto", Content = "Script Loaded", Duration = 5 })

-- Start auto joining if enabled in settings
if isAutoJoining then startAutoJoining() end
if isMirageAutoJoining then 
    print("Auto-starting Mirage Island join from saved settings")
    startMirageAutoJoining() 
end
