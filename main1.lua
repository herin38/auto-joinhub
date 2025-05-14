-- HerinaAuto Join Blox Fruit
-- Auto Full Moon Joiner with Moon Detection

-- Variables
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

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/addons/SaveManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "by herin38",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

-- Create Tabs
local Tabs = {
    AutoJoin = Window:AddTab({ Title = "Auto Join", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Servers = Window:AddTab({ Title = "Servers", Icon = "server" })
}

-- Auto Join Section
local AutoJoinSection = Tabs.AutoJoin:AddSection("Auto Join Control")

AutoJoinSection:AddToggle("AutoJoinToggle", {
    Title = "Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        CONFIG.isAutoJoining = Value
        if Value then
            Fluent:Notify({
                Title = "Auto Join",
                Content = "Started searching for Full Moon servers",
                Duration = 3
            })
            -- Start auto join loop
            spawn(function()
                while CONFIG.isAutoJoining do
                    local success, servers = pcall(function()
                        return HttpService:JSONDecode(game:HttpGet(CONFIG.defaultAPI))
                    end)
                    
                    if success and #servers > 0 then
                        for _, server in ipairs(servers) do
                            if CONFIG.selectedServerType == "All" or server.type == CONFIG.selectedServerType then
                                pcall(function()
                                    TeleportService:TeleportToPlaceInstance(
                                        game.PlaceId,
                                        server.jobId,
                                        LocalPlayer
                                    )
                                end)
                                wait(5) -- Wait before next attempt
                                break
                            end
                        end
                    end
                    wait(CONFIG.retryDelay)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Join",
                Content = "Stopped searching",
                Duration = 3
            })
        end
    end
})

AutoJoinSection:AddButton({
    Title = "Refresh Servers",
    Description = "Check for new Full Moon servers",
    Callback = function()
        local success, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(CONFIG.defaultAPI))
        end)
        
        if success then
            Fluent:Notify({
                Title = "Server List",
                Content = string.format("Found %d servers", #servers),
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to fetch servers",
                Duration = 3
            })
        end
    end
})

-- Settings Section
local SettingsSection = Tabs.Settings:AddSection("Settings")

SettingsSection:AddSlider("RetryDelay", {
    Title = "Retry Delay",
    Description = "Seconds between server checks",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        CONFIG.retryDelay = Value
    end
})

SettingsSection:AddDropdown("ServerType", {
    Title = "Server Type",
    Description = "Filter server types",
    Values = {"All", "TeleportService", "ServerBrowser"},
    Default = "All",
    Multi = false,
    Callback = function(Value)
        CONFIG.selectedServerType = Value
    end
})

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("HerinaBloxFruit")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Initial Notification
Fluent:Notify({
    Title = "Script Loaded",
    Content = "HerinaAuto Join is ready!",
    Duration = 5
})