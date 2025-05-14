-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection
-- Exploit Version

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Stop Camera Shake
pcall(function()
    local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
    CamShake:Stop()
end)

-- Device Detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Load UI Library
local Fluent = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()

if not Fluent then
    warn("Failed to load Fluent UI Library!")
    return
end

-- Load addons after Fluent is loaded
local SaveManager = Fluent.SaveManager
local InterfaceManager = Fluent.InterfaceManager

-- Variables
local isAutoJoining = false
local retryDelay = 5
local selectedServerType = "All"
local fullMoonServers = {}
local defaultAPI = "https://game.hentaiviet.top/fullmoon.php"

-- Get Current Sea
local placeId = game.PlaceId
local Sea1 = placeId == 2753915549
local Sea2 = placeId == 4442272183
local Sea3 = placeId == 7449423635

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Setup tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Servers = Window:AddTab({ Title = "Servers", Icon = "server" }),
    MoonInfo = Window:AddTab({ Title = "Moon Info", Icon = "moon" })
}

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("HerinaBloxFruit")
SaveManager:BuildConfigSection(Tabs.Settings)

-- Setup Interface Manager
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("HerinaBloxFruit")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

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

-- Server Functions
local function fetchFullMoonServers()
    local servers = {}
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(defaultAPI))
    end)
    
    if success and response then
        for _, server in ipairs(response) do
            if server.jobId ~= game.JobId then
                table.insert(servers, {
                    jobId = server.jobId,
                    players = server.playing or "N/A",
                    serverType = server.type or "Unknown",
                    placeId = server.placeId
                })
            end
        end
    end
    
    return servers
end

local function joinFullMoonServer(server)
    if not server or not server.jobId then return false end
    
    -- Queue script for after teleport
    if queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/herinhub/scripts/main/1.lua"))()')
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/herinhub/scripts/main/1.lua"))()')
    end
    
    -- Try different teleport methods
    local success = pcall(function()
        if syn and syn.join_game then
            syn.join_game(server.jobId)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, Players.LocalPlayer)
        end
    end)
    
    return success
end

-- Main tab with icons
local MainSection = Tabs.Main:AddSection("🌕 Full Moon Auto Join")

-- Auto Join Toggle with status
MainSection:AddToggle({
    Title = "🔄 Auto Join Full Moon",
    Description = "Automatically join servers with Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            Fluent:Notify({
                Title = "Auto Join",
                Content = "Started searching for Full Moon servers",
                Duration = 3,
                Type = "success"
            })
            spawn(function()
                while isAutoJoining do
                    local moonStatus = CheckMoon()
                    if moonStatus == "Full Moon" then
                        fullMoonServers = fetchFullMoonServers()
                        if #fullMoonServers > 0 then
                            joinFullMoonServer(fullMoonServers[1])
                            wait(5) -- Wait after join attempt
                        end
                    end
                    wait(retryDelay)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Join",
                Content = "Stopped searching",
                Duration = 3,
                Type = "info"
            })
        end
    end
})

-- Server Hop Button
MainSection:AddButton({
    Title = "🔄 Server Hop",
    Description = "Hop to another server",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers > 0 then
            local randomServer = fullMoonServers[math.random(1, #fullMoonServers)]
            joinFullMoonServer(randomServer)
        else
            Fluent:Notify({
                Title = "Server Hop",
                Content = "No servers available",
                Duration = 3,
                Type = "error"
            })
        end
    end
})

-- Status Section
local StatusSection = Tabs.Main:AddSection("📊 Status")

-- Live Status Display
local statusLabel = StatusSection:AddParagraph({
    Title = "🎯 Current Status",
    Content = "Initializing..."
})

-- Update Status
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local timeInfo = GetFormattedTime()
        local gamePhase = GetGameTime()
        
        local statusText = string.format([[
🌕 Moon: %s
⏰ Time: %s
🌙 Phase: %s
🔄 Auto Join: %s
⏱️ Delay: %d seconds
📡 Servers Found: %d]], 
            moonStatus,
            timeInfo,
            gamePhase,
            isAutoJoining and "Running" or "Stopped",
            retryDelay,
            #fullMoonServers
        )
        
        -- Add color indicators
        local statusColor = moonStatus == "Full Moon" and "🟢" or 
                           moonStatus == "Next Night" and "🟡" or "🔴"
                           
        statusLabel:SetContent(statusColor .. " " .. statusText)
    end
end)

-- Moon Info Section
local MoonSection = Tabs.MoonInfo:AddSection("🌕 Moon Information")

-- Moon Phase Display
local moonPhaseLabel = MoonSection:AddParagraph({
    Title = "🌕 Moon Phase",
    Content = "Checking..."
})

-- Time Until Display
local timeUntilLabel = MoonSection:AddParagraph({
    Title = "⏳ Time Until",
    Content = "Calculating..."
})

-- Update Moon Info
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local clockTime = game.Lighting.ClockTime
        local timeUntil = ""
        
        -- Calculate time until next phase
        if moonStatus == "Full Moon" then
            if clockTime < 5 then
                timeUntil = string.format("Full Moon ends in %.1f hours", 5 - clockTime)
            else
                timeUntil = "Waiting for next cycle"
            end
        elseif moonStatus == "Next Night" then
            if clockTime < 18 then
                timeUntil = string.format("Full Moon starts in %.1f hours", 18 - clockTime)
            else
                timeUntil = string.format("Full Moon starts in %.1f hours", (24 - clockTime) + 18)
            end
        else
            timeUntil = "Waiting for Next Night phase"
        end
        
        -- Update labels with emoji indicators
        local phaseEmoji = moonStatus == "Full Moon" and "🌕" or 
                          moonStatus == "Next Night" and "🌓" or "🌑"
                          
        moonPhaseLabel:SetContent(string.format("%s Current Phase: %s", phaseEmoji, moonStatus))
        timeUntilLabel:SetContent(string.format("⏳ %s", timeUntil))
    end
end)

-- Server List Section
local ServerSection = Tabs.Servers:AddSection("🖥️ Available Servers")

-- Refresh Button
ServerSection:AddButton({
    Title = "🔄 Refresh Server List",
    Description = "Get latest Full Moon servers",
    Callback = function()
        Fluent:Notify({
            Title = "Refreshing",
            Content = "Fetching server list...",
            Duration = 2
        })
        
        fullMoonServers = fetchFullMoonServers()
        updateServerList()
        
        Fluent:Notify({
            Title = "Refresh Complete",
            Content = string.format("Found %d servers", #fullMoonServers),
            Duration = 3,
            Type = "success"
        })
    end
})

-- Server List Display
local serverListLabel = ServerSection:AddParagraph({
    Title = "📋 Server List",
    Content = "Click Refresh to see servers"
})

-- Update Server List
function updateServerList()
    if #fullMoonServers == 0 then
        serverListLabel:SetContent("❌ No servers found")
        return
    end
    
    local serverText = ""
    for i, server in ipairs(fullMoonServers) do
        if i > 5 then break end -- Show only top 5 servers
        serverText = serverText .. string.format(
            "🔹 Server %d | Players: %s | Type: %s\n",
            i,
            server.players,
            server.serverType
        )
    end
    
    if #fullMoonServers > 5 then
        serverText = serverText .. string.format("\n...and %d more servers", #fullMoonServers - 5)
    end
    
    serverListLabel:SetContent(serverText)
end

-- Settings Section
local SettingsSection = Tabs.Settings:AddSection("Settings")

SettingsSection:AddSlider("RetryDelaySlider", {
    Title = "Retry Delay (seconds)",
    Default = retryDelay,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
    end
})

-- Initial notification
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Press RightShift to toggle UI",
    Duration = 5
})
