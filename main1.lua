-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Stop Camera Shake
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
CamShake:Stop()

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/src/Addons/InterfaceManager.luau"))()

-- Variables
local isAutoJoining = false
local retryDelay = 5 -- Default retry delay in seconds
local selectedServerType = "API1" -- Default server type
local customAPI = "https://game.hentaiviet.top/fullmoon.php" -- Default API
local fullMoonServers = {}
local showStatusLabel = true

-- Get Current Sea
local placeId = game.PlaceId
local Sea1 = placeId == 2753915549
local Sea2 = placeId == 4442272183
local Sea3 = placeId == 7449423635

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "by herin38",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Moon = Window:AddTab({ Title = "Moon Info", Icon = "moon" }),
    About = Window:AddTab({ Title = "About", Icon = "info" })
}

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("HerinaBloxFruit")
SaveManager:BuildConfigSection(Tabs.Settings)

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

-- Main Section
local MainSection = Tabs.Main:AddSection("Auto Join Control")

MainSection:AddToggle("AutoJoin", {
    Title = "Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            startAutoJoining()
        else
            stopAutoJoining()
        end
    end
})

MainSection:AddToggle("ShowStatus", {
    Title = "Show Status Label",
    Default = true,
    Callback = function(Value)
        showStatusLabel = Value
        SaveManager:Save({ showStatusLabel = Value })
    end
})

MainSection:AddButton({
    Title = "Refresh Servers",
    Description = "Check for new Full Moon servers",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        updateServerList()
        Fluent:Notify({
            Title = "Servers Refreshed",
            Content = string.format("Found %d servers", #fullMoonServers),
            Duration = 3
        })
    end
})

-- Settings Section
local SettingsSection = Tabs.Settings:AddSection("Settings")

SettingsSection:AddSlider({
    Title = "Retry Delay",
    Description = "Seconds between join attempts",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        retryDelay = Value
        SaveManager:Save({ retryDelay = Value })
    end
})

SettingsSection:AddDropdown({
    Title = "Server Type",
    Description = "Select server type to join",
    Values = {"API1", "TeleportService", "ServerBrowser"},
    Default = "API1",
    Multi = false,
    Callback = function(Value)
        selectedServerType = Value
        SaveManager:Save({ selectedServerType = Value })
    end
})

SettingsSection:AddInput({
    Title = "Custom API URL",
    Description = "Enter custom API URL",
    Default = customAPI,
    Placeholder = "Enter URL here",
    Callback = function(Value)
        customAPI = Value
        SaveManager:Save({ customAPI = Value })
    end
})

-- Moon Info Section
local MoonSection = Tabs.Moon:AddSection("Moon Status")

local moonStatusLabel = MoonSection:AddParagraph({
    Title = "Current Moon Status",
    Content = "Loading..."
})

-- Update moon status
spawn(function()
    while wait(1) do
        local status = string.format(
            "Moon: %s\nTime: %s\nPhase: %s",
            CheckMoon(),
            GetFormattedTime(),
            GetGameTime()
        )
        moonStatusLabel:SetContent(status)
    end
end)

-- About Section
local AboutSection = Tabs.About:AddSection("Information")

AboutSection:AddParagraph({
    Title = "HerinaAuto Join Blox Fruit",
    Content = "Version 1.0\nPress RightShift to toggle UI"
})

-- Load saved settings
local savedSettings = SaveManager:LoadAutoloadConfig()
if savedSettings then
    isAutoJoining = savedSettings.isAutoJoining or false
    retryDelay = savedSettings.retryDelay or 5
    selectedServerType = savedSettings.selectedServerType or "API1"
    customAPI = savedSettings.customAPI or "https://game.hentaiviet.top/fullmoon.php"
    showStatusLabel = savedSettings.showStatusLabel ~= nil and savedSettings.showStatusLabel or true
end

-- Initial setup
if isAutoJoining then
    startAutoJoining()
end

-- Initial notification
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Press RightShift to toggle UI",
    Duration = 5
})