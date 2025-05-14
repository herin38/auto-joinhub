if not game:IsLoaded() then game.Loaded:Wait() end

-- Anti-Kick Protection
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Protection Check
if getgenv().HerinaHubLoaded then return end
getgenv().HerinaHubLoaded = true

-- Services
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Variables
local retryDelay = 5
local isAutoJoining = false
local fullMoonServers = {}
local defaultAPI = "https://game.hentaiviet.top/fullmoon.php"

-- Game Check
if not game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 7449423635 then
    return warn("⚠️ Script only works in Blox Fruits!")
end

-- Current Sea Detection
local placeId = game.PlaceId
local Sea1, Sea2, Sea3 = placeId == 2753915549, placeId == 4442272183, placeId == 7449423635
local CurrentSea = Sea1 and "Sea 1" or Sea2 and "Sea 2" or Sea3 and "Sea 3" or "Unknown"

-- Moon Checker
local function MoonTextureId()
    local success, result = pcall(function()
        if Sea1 or Sea2 then
            return game:GetService("Lighting").FantasySky.MoonTextureId
        elseif Sea3 then
            return game:GetService("Lighting").Sky.MoonTextureId
        end
    end)
    return success and result or ""
end

local function CheckMoon()
    local textures = {
        full = "http://www.roblox.com/asset/?id=9709149431",
        next = "http://www.roblox.com/asset/?id=9709149052"
    }
    local id = MoonTextureId()
    if id == textures.full then return "Full Moon ⭐"
    elseif id == textures.next then return "Next Night 🌙"
    else return "Bad Moon ❌" end
end

-- Time Functions
local function GetFormattedTime()
    return os.date("%H:%M:%S")
end

local function GetGameTime()
    return string.format("%.2f", workspace.DistributedGameTime or 0)
end

-- Server Functions
local function joinFullMoonServer(server)
    if not server or not server.jobId then return false end
    
    -- Queue Script
    local queueScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/herinhub/scripts/main/1.lua"))()'
    if queue_on_teleport then
        queue_on_teleport(queueScript)
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport(queueScript)
    end

    -- Teleport
    local success, error = pcall(function()
        if syn and syn.join_game then
            syn.join_game(server.jobId)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, LocalPlayer)
        end
    end)
    
    return success
end

local function fetchFullMoonServers()
    local servers, success = {}, false
    success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(defaultAPI))
    end)
    
    if success and type(servers) == "table" then
        local list = {}
        for _, s in ipairs(servers) do
            if s.jobId and s.jobId ~= game.JobId then
                table.insert(list, {
                    jobId = s.jobId,
                    players = s.playing or "?",
                    serverType = s.type or "Unknown"
                })
            end
        end
        return list
    end
    return {}
end

-- Load Orion Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
if not OrionLib then return warn("⚠️ Failed to load UI library!") end

-- Create Window
local Window = OrionLib:MakeWindow({
    Name = "🌕 Herina Hub | Blox Fruits",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "HerinaHub",
    IntroEnabled = false
})

-- Main Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddParagraph("Game Info", string.format(
    "👤 Player: %s\n🌊 Current Sea: %s",
    LocalPlayer.Name,
    CurrentSea
))

MainTab:AddToggle({
    Name = "🌕 Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            task.spawn(function()
                while isAutoJoining do
                    local moon = CheckMoon()
                    if moon:find("Full Moon") then
                        fullMoonServers = fetchFullMoonServers()
                        if #fullMoonServers > 0 then
                            OrionLib:MakeNotification({
                                Name = "Full Moon Found!",
                                Content = "Attempting to join server...",
                                Image = "rbxassetid://4483345998",
                                Time = 5
                            })
                            joinFullMoonServer(fullMoonServers[1])
                        end
                    end
                    task.wait(retryDelay)
                end
            end)
        end
    end
})

MainTab:AddButton({
    Name = "🔄 Server Hop",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers > 0 then
            OrionLib:MakeNotification({
                Name = "Server Hop",
                Content = "Joining new server...",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
            joinFullMoonServer(fullMoonServers[math.random(1, #fullMoonServers)])
        else
            OrionLib:MakeNotification({
                Name = "Server Hop",
                Content = "No servers available!",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    end
})

-- Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSlider({
    Name = "⏱️ Check Delay",
    Min = 1,
    Max = 30,
    Default = 5,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "seconds",
    Callback = function(Value)
        retryDelay = Value
    end
})

-- Status Tab
local StatusTab = Window:MakeTab({
    Name = "Status",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MoonStatus = StatusTab:AddLabel("Checking moon status...")
local TimeStatus = StatusTab:AddLabel("Getting time...")
local AutoJoinStatus = StatusTab:AddLabel("Auto Join: OFF")

-- Update Status
task.spawn(function()
    while task.wait(1) do
        if not getgenv().HerinaHubLoaded then break end
        
        local moon = CheckMoon()
        MoonStatus:Set("🌕 Moon Phase: " .. moon)
        TimeStatus:Set("⏰ Time: " .. GetFormattedTime())
        AutoJoinStatus:Set("🤖 Auto Join: " .. (isAutoJoining and "Running ✅" or "Stopped ❌"))
    end
end)

-- Servers Tab
local ServersTab = Window:MakeTab({
    Name = "Servers",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local ServerList = ServersTab:AddLabel("No servers found")

ServersTab:AddButton({
    Name = "🔍 Refresh Server List",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers == 0 then
            ServerList:Set("❌ No servers available")
            return
        end

        local serverInfo = "📋 Available Servers:"
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end
            serverInfo = serverInfo .. string.format("\n%d) Players: %s | Type: %s", 
                i, server.players, server.serverType)
        end
        
        if #fullMoonServers > 5 then
            serverInfo = serverInfo .. string.format("\n\n...and %d more servers", #fullMoonServers - 5)
        end
        
        ServerList:Set(serverInfo)
    end
})

-- Initialize
OrionLib:Init()

-- Cleanup
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Orion" then
        getgenv().HerinaHubLoaded = false
        OrionLib:Destroy()
        isAutoJoining = false
    end
end)

-- Initial Notification
OrionLib:MakeNotification({
    Name = "✅ Herina Hub Loaded!",
    Content = string.format("Welcome %s! Current Sea: %s", LocalPlayer.Name, CurrentSea),
    Image = "rbxassetid://4483345998",
    Time = 5
})
