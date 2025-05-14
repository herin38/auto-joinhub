-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    retryDelay = 5,
    selectedServerType = "All",
    isAutoJoining = false,
    defaultAPI = "https://game.hentaiviet.top/fullmoon.php"
}

-- Create Main Window
local Window = OrionLib:MakeWindow({
    Name = "HerinaAuto Join Blox Fruit", 
    HidePremium = false,
    SaveConfig = true, 
    ConfigFolder = "HerinaBloxFruit",
    IntroEnabled = true,
    IntroText = "HerinaAuto Join"
})

-- Create Tabs
local AutoJoinTab = Window:MakeTab({
    Name = "Auto Join",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local ServersTab = Window:MakeTab({
    Name = "Servers",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Auto Join Section
local AutoJoinSection = AutoJoinTab:AddSection({
    Name = "Auto Join Control"
})

AutoJoinSection:AddToggle({
    Name = "Auto Join Full Moon",
    Default = false,
    Save = true,
    Flag = "autoJoinEnabled",
    Callback = function(Value)
        CONFIG.isAutoJoining = Value
        if Value then
            OrionLib:MakeNotification({
                Name = "Auto Join",
                Content = "Started searching for Full Moon servers",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
            
            spawn(function()
                while CONFIG.isAutoJoining do
                    local success, response = pcall(function()
                        return HttpService:JSONDecode(game:HttpGet(CONFIG.defaultAPI))
                    end)
                    
                    if success and type(response) == "table" and #response > 0 then
                        for _, server in ipairs(response) do
                            if CONFIG.selectedServerType == "All" or server.type == CONFIG.selectedServerType then
                                pcall(function()
                                    TeleportService:TeleportToPlaceInstance(
                                        game.PlaceId,
                                        server.jobId,
                                        LocalPlayer
                                    )
                                end)
                                wait(5)
                                break
                            end
                        end
                    end
                    wait(CONFIG.retryDelay)
                end
            end)
        else
            OrionLib:MakeNotification({
                Name = "Auto Join",
                Content = "Stopped searching",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    end
})

AutoJoinSection:AddButton({
    Name = "Refresh Servers",
    Callback = function()
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(CONFIG.defaultAPI))
        end)
        
        if success and type(response) == "table" then
            OrionLib:MakeNotification({
                Name = "Server List",
                Content = string.format("Found %d servers", #response),
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        else
            OrionLib:MakeNotification({
                Name = "Error",
                Content = "Failed to fetch servers",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    end
})

-- Settings Section
local SettingsSection = SettingsTab:AddSection({
    Name = "Settings"
})

SettingsSection:AddSlider({
    Name = "Retry Delay",
    Min = 1,
    Max = 30,
    Default = 5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "seconds",
    Save = true,
    Flag = "retryDelay",
    Callback = function(Value)
        CONFIG.retryDelay = Value
    end    
})

SettingsSection:AddDropdown({
    Name = "Server Type",
    Default = "All",
    Options = {"All", "TeleportService", "ServerBrowser"},
    Save = true,
    Flag = "serverType",
    Callback = function(Value)
        CONFIG.selectedServerType = Value
    end    
})

-- Servers Section
local ServersSection = ServersTab:AddSection({
    Name = "Server Information"
})

ServersSection:AddParagraph("Server Status", "Waiting for refresh...")

-- Initialize
OrionLib:Init()

-- Initial Notification
OrionLib:MakeNotification({
    Name = "Script Loaded",
    Content = "HerinaAuto Join is ready!",
    Image = "rbxassetid://4483345998",
    Time = 5
})