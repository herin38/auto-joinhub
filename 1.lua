--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

--// Anti-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--// Stop Camera Shake
pcall(function()
    local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
    CamShake:Stop()
end)

--// Device Detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--// Variables
local retryDelay = 5
local isAutoJoining = false
local fullMoonServers = {}
local defaultAPI = "https://game.hentaiviet.top/fullmoon.php"

--// Current Sea
local placeId = game.PlaceId
local Sea1, Sea2, Sea3 = placeId == 2753915549, placeId == 4442272183, placeId == 7449423635

--// Moon Texture Checker
local function MoonTextureId()
    if Sea1 or Sea2 then
        return game:GetService("Lighting").FantasySky.MoonTextureId
    elseif Sea3 then
        return game:GetService("Lighting").Sky.MoonTextureId
    end
end

local function CheckMoon()
    local textures = {
        full = "http://www.roblox.com/asset/?id=9709149431",
        next = "http://www.roblox.com/asset/?id=9709149052"
    }
    local id = MoonTextureId()
    if id == textures.full then return "Full Moon"
    elseif id == textures.next then return "Next Night"
    else return "Bad Moon" end
end

--// Time Display
local function GetFormattedTime()
    local t = tick() % 60
    return os.date("%H:%M:%S", os.time())
end

local function GetGameTime()
    return string.format("%.2f", workspace.DistributedGameTime or 0)
end

--// Teleport Functions
local function joinFullMoonServer(server)
    if not server or not server.jobId then return false end

    local teleportScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/herinhub/scripts/main/1.lua"))()'
    if queue_on_teleport then queue_on_teleport(teleportScript)
    elseif syn and syn.queue_on_teleport then syn.queue_on_teleport(teleportScript) end

    return pcall(function()
        if syn and syn.join_game then
            syn.join_game(server.jobId)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, Players.LocalPlayer)
        end
    end)
end

local function fetchFullMoonServers()
    local servers, success = {}, false
    success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(defaultAPI))
    end)
    if success and servers then
        local list = {}
        for _, s in ipairs(servers) do
            if s.jobId ~= game.JobId then
                table.insert(list, {
                    jobId = s.jobId,
                    players = s.playing or "?",
                    serverType = s.type or "Unknown"
                })
            end
        end
        return list
    else
        return {}
    end
end

--// Load Orion Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

--// Create Window
local Window = OrionLib:MakeWindow({
    Name = "🌕 Herina Auto Join | Blox Fruits",
    HidePremium = true,
    SaveConfig = false,
    IntroEnabled = false
})

--// Main Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            task.spawn(function()
                while isAutoJoining do
                    local moon = CheckMoon()
                    if moon == "Full Moon" then
                        fullMoonServers = fetchFullMoonServers()
                        if #fullMoonServers > 0 then
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
    Name = "Server Hop",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers > 0 then
            joinFullMoonServer(fullMoonServers[math.random(1, #fullMoonServers)])
        end
    end
})

--// Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSlider({
    Name = "Retry Delay (seconds)",
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

--// Status Tab
local StatusTab = Window:MakeTab({
    Name = "Status",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MoonStatus = StatusTab:AddLabel("Checking moon status...")
local TimeStatus = StatusTab:AddLabel("Getting time...")
local AutoJoinStatus = StatusTab:AddLabel("Auto Join: OFF")

--// Update Status
task.spawn(function()
    while task.wait(1) do
        local moon = CheckMoon()
        MoonStatus:Set("Moon Phase: " .. moon)
        TimeStatus:Set("Time: " .. GetFormattedTime())
        AutoJoinStatus:Set("Auto Join: " .. (isAutoJoining and "Running ✅" or "Stopped ❌"))
    end
end)

--// Servers Tab
local ServersTab = Window:MakeTab({
    Name = "Servers",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local ServerList = ServersTab:AddLabel("No servers found")

ServersTab:AddButton({
    Name = "Refresh Server List",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers == 0 then
            ServerList:Set("No servers available")
            return
        end

        local serverInfo = ""
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end
            serverInfo = serverInfo .. string.format("\nServer %d | Players: %s | Type: %s", 
                i, server.players, server.serverType)
        end
        
        if #fullMoonServers > 5 then
            serverInfo = serverInfo .. string.format("\n\n...and %d more servers", #fullMoonServers - 5)
        end
        
        ServerList:Set(serverInfo)
    end
})

--// Initialize
OrionLib:Init()

--// Cleanup
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Orion" then
        OrionLib:Destroy()
        isAutoJoining = false
    end
end)
