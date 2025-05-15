-- Mobile Compatibility Check
local isMobile = game:GetService("UserInputService").TouchEnabled

-- Orion UI Library (Beautiful UI like Banana Hub style)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Create Beautiful Window
local Window = OrionLib:MakeWindow({
    Name = "HerinaAuto Join Blox Fruit", 
    HidePremium = false,
    SaveConfig = true, 
    ConfigFolder = "Herina",
    IntroEnabled = true,
    IntroText = "HerinaAuto Join",
    IntroIcon = "rbxassetid://7733955740",
    Icon = "rbxassetid://7733955740"
})

-- Services
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

CamShake:Stop()

-- Variables
local isAutoJoining = false
local retryDelay = 5
local selectedServerType = "API1"
local customAPI = "https://game.hentaiviet.top/fullmoon.php"
local fullMoonServers = {}

local SaveFolder = "Herina"
local ConfigFile = Players.LocalPlayer.Name .. "-BloxFruit.json"

local function SaveSettings(key, value)
    local settings = {}
    pcall(function()
        settings = HttpService:JSONDecode(readfile(SaveFolder .. "/" .. ConfigFile))
    end)
    settings[key] = value
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    writefile(SaveFolder .. "/" .. ConfigFile, HttpService:JSONEncode(settings))
end

local function LoadSettings()
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(SaveFolder .. "/" .. ConfigFile))
    end)
    if success then return result else return {} end
end

-- Main Tab with Beautiful Design
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://7733955740",
    PremiumOnly = false
})

MainTab:AddButton({
    Name = "Teleport to Safe Zone",
    Callback = function()
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(1000, 1000, 1000)
            OrionLib:MakeNotification({
                Name = "Teleport",
                Content = "Teleported to safe zone!",
                Image = "rbxassetid://7733955740",
                Time = 5
            })
        end
    end
})

MainTab:AddToggle({
    Name = "Auto Join Full Moon",
    Default = false,
    Callback = function(Value)
        isAutoJoining = Value
        if Value then
            OrionLib:MakeNotification({
                Name = "Auto Join",
                Content = "Started auto-joining full moon servers",
                Image = "rbxassetid://7733955740",
                Time = 5
            })
            startAutoJoining()
        else
            OrionLib:MakeNotification({
                Name = "Auto Join",
                Content = "Stopped auto-joining",
                Image = "rbxassetid://7733955740",
                Time = 5
            })
            stopAutoJoining()
        end
    end
})

MainTab:AddButton({
    Name = "Refresh Servers",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        OrionLib:MakeNotification({
            Name = "Servers",
            Content = "Server list refreshed!",
            Image = "rbxassetid://7733955740",
            Time = 5
        })
    end
})

-- Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://7733955740",
    PremiumOnly = false
})

SettingsTab:AddSlider({
    Name = "Retry Delay",
    Min = 1,
    Max = 30,
    Default = 5,
    Color = Color3.fromRGB(255, 185, 0),
    Increment = 1,
    ValueName = "seconds",
    Callback = function(Value)
        retryDelay = Value
        SaveSettings("retryDelay", Value)
        OrionLib:MakeNotification({
            Name = "Settings",
            Content = "Retry delay updated to " .. Value .. " seconds",
            Image = "rbxassetid://7733955740",
            Time = 5
        })
    end
})

SettingsTab:AddDropdown({
    Name = "Server Type",
    Default = "API1",
    Options = {"API1", "TeleportService", "ServerBrowser"},
    Callback = function(Value)
        selectedServerType = Value
        SaveSettings("selectedServerType", Value)
        OrionLib:MakeNotification({
            Name = "Settings",
            Content = "Server type changed to " .. Value,
            Image = "rbxassetid://7733955740",
            Time = 5
        })
    end
})

-- Moon Info Tab
local MoonTab = Window:MakeTab({
    Name = "Moon Info",
    Icon = "rbxassetid://7733955740",
    PremiumOnly = false
})

local MoonInfo = MoonTab:AddLabel("Loading moon info...")
local TimeInfo = MoonTab:AddLabel("Loading time info...")
local PhaseInfo = MoonTab:AddLabel("Loading phase info...")

-- Update moon info every second
spawn(function()
    while true do
        MoonInfo:Set("Moon: " .. CheckMoon())
        TimeInfo:Set("Time: " .. GetMoonTimeInfo())
        PhaseInfo:Set("Phase: " .. GetGameTime())
        wait(1)
    end
end)

-- About Tab
local AboutTab = Window:MakeTab({
    Name = "About",
    Icon = "rbxassetid://7733955740",
    PremiumOnly = false
})

AboutTab:AddLabel("HerinaAuto Join Blox Fruit")
AboutTab:AddLabel("Version: 1.0.0")
AboutTab:AddLabel("Created by: Herina")

-- Initialize settings
local settings = LoadSettings()
isAutoJoining = settings.isAutoJoining or false
retryDelay = settings.retryDelay or 5
selectedServerType = settings.selectedServerType or "API1"
customAPI = settings.customAPI or "https://game.hentaiviet.top/fullmoon.php"

local Sea1, Sea2, Sea3 = false, false, false
if game.PlaceId == 2753915549 then Sea1 = true
elseif game.PlaceId == 4442272183 then Sea2 = true
elseif game.PlaceId == 7449423635 then Sea3 = true end

local function MoonTextureId()
    if Sea1 or Sea2 then return Lighting.FantasySky.MoonTextureId
    elseif Sea3 then return Lighting.Sky.MoonTextureId end
end

local function CheckMoon()
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"
    local moon4 = "http://www.roblox.com/asset/?id=9709149052"
    local moon = MoonTextureId()
    if moon == moon5 then return "Full Moon"
    elseif moon == moon4 then return "Next Night" else return "Bad Moon" end
end

local function GetFormattedTime()
    local h = math.floor(Lighting.ClockTime)
    local m = math.floor((Lighting.ClockTime - h) * 60)
    return string.format("%02d:%02d", h, m)
end

local function GetGameTime()
    local ct = Lighting.ClockTime
    return (ct >= 18 or ct < 5) and "Night" or "Day"
end

local function GetMoonTimeInfo()
    local status = CheckMoon()
    local ct = Lighting.ClockTime
    if status == "Full Moon" then
        if ct <= 5 then return GetFormattedTime() .. " (Moon ends in " .. math.floor(5 - ct) .. "m)"
        elseif ct < 12 then return GetFormattedTime() .. " (Fake Moon)"
        elseif ct < 18 then return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - ct) .. "m)"
        else return GetFormattedTime() .. " (Moon ends in " .. math.floor(24 + 6 - ct) .. "m)" end
    elseif status == "Next Night" then
        if ct < 12 then return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 - ct) .. "m)"
        else return GetFormattedTime() .. " (Full Moon in " .. math.floor(18 + 12 - ct) .. "m)" end
    end
    return GetFormattedTime()
end

local function joinFullMoonServer(info)
    if not info or not info.teleportScript then return false end
    
    local success, err = pcall(function()
        if info.jobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, info.jobId)
        else
            loadstring(info.teleportScript)()
        end
    end)
    
    if not success then
        warn("Teleport failed:", err)
        return false
    end
    return true
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

-- Mobile-specific UI adjustments
if isMobile then
    Window:SetSize(UDim2.fromOffset(460, 380))
    
    -- Add a floating button for mobile users
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0.9, 0, 0.8, 0)
    ToggleButton.Text = "Toggle"
    ToggleButton.Parent = game.CoreGui
    
    ToggleButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
end

-- Add error handling for server fetching
local function fetchFullMoonServers()
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(customAPI))
    end)
    
    if not success then
        OrionLib:MakeNotification({
            Name = "Error",
            Content = "Failed to fetch servers. Retrying...",
            Image = "rbxassetid://7733955740",
            Time = 5
        })
        return {}
    end
    
    local servers = {}
    if res and res.status == "done" and res.results then
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
                    if info.teleportScript or info.jobId then 
                        table.insert(servers, info)
                    end
                end
            end
        end
    end
    return servers
end

-- Initialize on both mobile and PC
if isAutoJoining then 
    task.spawn(function()
        wait(1) -- Small delay to ensure UI is loaded
        startAutoJoining()
    end)
end

-- Initialize Orion
OrionLib:Init()
