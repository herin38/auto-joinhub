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

-- Main Section
local MainSection = Tabs.Main:AddSection("Full Moon Auto Join")

MainSection:AddToggle("AutoJoinToggle", {
    Title = "Auto Join Full Moon Servers",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            spawn(function()
                while isAutoJoining do
                    fullMoonServers = fetchFullMoonServers()
                    if #fullMoonServers > 0 then
                        joinFullMoonServer(fullMoonServers[1])
                    end
                    wait(retryDelay)
                end
            end)
        end
    end
})

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

-- Moon Info Section
local MoonSection = Tabs.MoonInfo:AddSection("Moon Status")

local moonStatusLabel = MoonSection:AddParagraph({
    Title = "Current Moon",
    Content = "Loading..."
})

-- Update moon status
spawn(function()
    while wait(1) do
        local status = "Moon: " .. CheckMoon()
        status = status .. "\nTime: " .. game.Lighting.ClockTime
        moonStatusLabel:SetContent(status)
    end
end)

-- Initial notification
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Press RightShift to toggle UI",
    Duration = 5
})