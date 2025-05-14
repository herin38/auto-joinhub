repeat wait() until game:IsLoaded()

local exec = identifyexecutor and identifyexecutor() or "Unknown"
if not getgenv then
    return warn("⚠️ Executor not supported!")
end

-- Protection
if getgenv().HerinaHubLoaded then return end
getgenv().HerinaHubLoaded = true

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
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
if not (game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 7449423635) then
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

-- Server Functions
local function joinFullMoonServer(server)
    if not server or not server.jobId then return false end
    
    -- Queue Script
    local queueScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/herinhub/scripts/main/1.lua"))()'
    
    -- Support different executors
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(queueScript)
    elseif queue_on_teleport then
        queue_on_teleport(queueScript)
    end

    -- Teleport with different executor support
    local success, error = pcall(function()
        if syn and syn.join_game then
            syn.join_game(server.jobId)
        elseif KRNL_LOADED then
            -- KRNL specific teleport
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, LocalPlayer)
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

-- Create simple UI using KRNL-compatible methods
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/kavo"))()
local window = library.CreateLib("Herina Hub | Blox Fruits", "Ocean")

-- Main Tab
local MainTab = window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Join")

MainSection:NewLabel("Player: " .. LocalPlayer.Name)
MainSection:NewLabel("Current Sea: " .. CurrentSea)
MainSection:NewLabel("Executor: " .. exec)

MainSection:NewToggle("Auto Join Full Moon", "Automatically joins full moon servers", function(state)
    isAutoJoining = state
    if state then
        task.spawn(function()
            while isAutoJoining do
                local moon = CheckMoon()
                if moon:find("Full Moon") then
                    fullMoonServers = fetchFullMoonServers()
                    if #fullMoonServers > 0 then
                        joinFullMoonServer(fullMoonServers[1])
                    end
                end
                task.wait(retryDelay)
            end
        end)
    end
end)

MainSection:NewButton("Server Hop", "Hop to another server", function()
    fullMoonServers = fetchFullMoonServers()
    if #fullMoonServers > 0 then
        joinFullMoonServer(fullMoonServers[math.random(1, #fullMoonServers)])
    end
end)

-- Settings Tab
local SettingsTab = window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Settings")

SettingsSection:NewSlider("Check Delay", "Delay between checks (seconds)", 30, 1, function(value)
    retryDelay = value
end)

-- Status Tab
local StatusTab = window:NewTab("Status")
local StatusSection = StatusTab:NewSection("Live Status")

local moonLabel = StatusSection:NewLabel("Checking moon...")
local timeLabel = StatusSection:NewLabel("Getting time...")
local statusLabel = StatusSection:NewLabel("Auto Join: OFF")

-- Update Status
task.spawn(function()
    while wait(1) do
        if not getgenv().HerinaHubLoaded then break end
        
        local moon = CheckMoon()
        moonLabel:UpdateLabel("Moon: " .. moon)
        timeLabel:UpdateLabel("Time: " .. GetFormattedTime())
        statusLabel:UpdateLabel("Auto Join: " .. (isAutoJoining and "ON" or "OFF"))
    end
end)

-- Servers Tab
local ServersTab = window:NewTab("Servers")
local ServersSection = ServersTab:NewSection("Server List")

local serverLabel = ServersSection:NewLabel("No servers found")

ServersSection:NewButton("Refresh Servers", "Update server list", function()
    fullMoonServers = fetchFullMoonServers()
    if #fullMoonServers == 0 then
        serverLabel:UpdateLabel("No servers available")
        return
    end

    local serverInfo = "Available Servers:"
    for i, server in ipairs(fullMoonServers) do
        if i > 5 then break end
        serverInfo = serverInfo .. "\n" .. i .. ") Players: " .. server.players .. " | Type: " .. server.serverType
    end
    
    if #fullMoonServers > 5 then
        serverInfo = serverInfo .. "\n\n...and " .. (#fullMoonServers - 5) .. " more servers"
    end
    
    serverLabel:UpdateLabel(serverInfo)
end)

-- Cleanup
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Kavo" then
        getgenv().HerinaHubLoaded = false
        isAutoJoining = false
    end
end)
