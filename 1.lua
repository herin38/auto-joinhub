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

-- Create Tabs First
local Main = Window:AddTab({ Title = "Main", Icon = "home" })
local Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
local Servers = Window:AddTab({ Title = "Servers", Icon = "server" })
local MoonInfo = Window:AddTab({ Title = "Moon Info", Icon = "moon" })

-- Main Tab Sections
local MainSection = Main:AddSection("🌕 Full Moon Auto Join")

-- Auto Join Toggle
MainSection:AddToggle({
    Title = "Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            spawn(function()
                while isAutoJoining do
                    local moonStatus = CheckMoon()
                    if moonStatus == "Full Moon" then
                        fullMoonServers = fetchFullMoonServers()
                        if #fullMoonServers > 0 then
                            joinFullMoonServer(fullMoonServers[1])
                        end
                    end
                    wait(retryDelay)
                end
            end)
        end
    end
})

-- Server Hop Button
MainSection:AddButton({
    Title = "Server Hop",
    Description = "Jump to another server",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers > 0 then
            local randomServer = fullMoonServers[math.random(1, #fullMoonServers)]
            joinFullMoonServer(randomServer)
        end
    end
})

-- Status Section
local StatusSection = Main:AddSection("📊 Status")

local statusLabel = StatusSection:AddParagraph({
    Title = "Current Status",
    Content = "Initializing..."
})

-- Update Status
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local timeInfo = GetFormattedTime()
        local gamePhase = GetGameTime()
        
        local statusText = string.format([[
Moon: %s
Time: %s
Phase: %s
Auto Join: %s
Delay: %d seconds]], 
            moonStatus,
            timeInfo,
            gamePhase,
            isAutoJoining and "Running" or "Stopped",
            retryDelay
        )
        
        statusLabel:SetContent(statusText)
    end
end)

-- Settings Tab
local SettingsSection = Settings:AddSection("⚙️ Settings")

SettingsSection:AddSlider({
    Title = "Retry Delay",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
    end
})

-- Moon Info Tab
local MoonSection = MoonInfo:AddSection("🌕 Moon Status")

local moonInfoLabel = MoonSection:AddParagraph({
    Title = "Moon Phase",
    Content = "Checking..."
})

-- Update Moon Info
spawn(function()
    while wait(1) do
        local status = CheckMoon()
        local timeInfo = GetFormattedTime()
        moonInfoLabel:SetContent(string.format("Phase: %s\nTime: %s", status, timeInfo))
    end
end)

-- Servers Tab
local ServerSection = Servers:AddSection("🖥️ Server List")

ServerSection:AddButton({
    Title = "Refresh Servers",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        updateServerList()
    end
})

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

-- Initial notification
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Press RightShift to toggle UI",
    Duration = 5
})