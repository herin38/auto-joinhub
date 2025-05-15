-- Mobile Compatibility Check
local isMobile = game:GetService("UserInputService").TouchEnabled

-- Services
local CamShake = require(game.ReplicatedStorage.Util.CameraShaker)
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

CamShake:Stop()

-- UI Library with Mobile Support
local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local Window = Library:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = isMobile and 120 or 160,
    Size = isMobile and UDim2.fromOffset(460, 380) or UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = isMobile and nil or Enum.KeyCode.RightShift
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "moon" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
local MoonTab = Window:AddTab({ Title = "Moon Info", Icon = "info" })
local AboutTab = Window:AddTab({ Title = "About", Icon = "help-circle" })

local isAutoJoining = false
local retryDelay = 5
local selectedServerType = "API1"
local customAPI = "https://game.hentaiviet.top/fullmoon.php"
local fullMoonServers = {}

local SaveFolder = "Herina"
local ConfigFile = Players.LocalPlayer.Name .. "-BloxFruit.json"
local Settings = {}

local function SaveSettings(key, value)
    Settings[key] = value
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    writefile(SaveFolder .. "/" .. ConfigFile, HttpService:JSONEncode(Settings))
end

local function LoadSettings()
    if not isfolder(SaveFolder) then makefolder(SaveFolder) end
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(SaveFolder .. "/" .. ConfigFile))
    end)
    if success then return result else return {} end
end

Settings = LoadSettings()
isAutoJoining = Settings.isAutoJoining or false
retryDelay = Settings.retryDelay or 5
selectedServerType = Settings.selectedServerType or "API1"
customAPI = Settings.customAPI or "https://game.hentaiviet.top/fullmoon.php"

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

local moonLabel = MoonTab:AddParagraph({ Title = "Moon", Content = "Loading..." })
local timeLabel = MoonTab:AddParagraph({ Title = "Time", Content = "Loading..." })
local phaseLabel = MoonTab:AddParagraph({ Title = "Phase", Content = "Loading..." })

task.spawn(function()
    while true do
        moonLabel:SetText("Moon: " .. CheckMoon())
        timeLabel:SetText("Time: " .. GetMoonTimeInfo())
        phaseLabel:SetText("Phase: " .. GetGameTime())
        task.wait(1)
    end
end)

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

-- Add Mobile-friendly notifications
local function notify(title, message)
    if Library and Library.Notify then
        Library:Notify({
            Title = title or "Notification",
            Content = message or "",
            Duration = 5
        })
    end
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

-- Main Tab Functions
local MainSection = MainTab:AddSection("Main Functions")

MainSection:AddButton({
    Title = "Teleport to Safe Zone",
    Description = "Teleports you to a safe zone",
    Callback = function()
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(1000, 1000, 1000)
            notify("Teleport", "Teleported to safe zone!")
        end
    end
})

MainSection:AddButton({
    Title = "Refresh Moon Status",
    Description = "Check current moon status",
    Callback = function()
        local status = CheckMoon()
        notify("Moon Status", "Current Moon: " .. status)
    end
})

-- Auto Join Section
local AutoJoinSection = MainTab:AddSection("Auto Join Settings")

AutoJoinSection:AddToggle({
    Title = "Auto Join Full Moon",
    Default = isAutoJoining,
    Description = "Automatically join Full Moon servers",
    Callback = function(state)
        if state then
            startAutoJoining()
            notify("Auto Join", "Started auto-joining full moon servers")
        else
            stopAutoJoining()
            notify("Auto Join", "Stopped auto-joining")
        end
    end
})

AutoJoinSection:AddButton({
    Title = "Manual Server Refresh",
    Description = "Manually refresh server list",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        notify("Servers", "Server list refreshed!")
    end
})

-- Settings Tab Functions
local SettingsSection = SettingsTab:AddSection("Settings")

SettingsSection:AddSlider({
    Title = "Retry Delay",
    Description = "Time between join attempts (seconds)",
    Default = retryDelay,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        retryDelay = value
        SaveSettings("retryDelay", value)
        notify("Settings", "Retry delay updated to " .. value .. " seconds")
    end
})

SettingsSection:AddDropdown({
    Title = "Server Type",
    Description = "Select server join method",
    Values = {"API1", "TeleportService", "ServerBrowser"},
    Default = selectedServerType,
    Multi = false,
    Callback = function(option)
        selectedServerType = option
        SaveSettings("selectedServerType", option)
        notify("Settings", "Server type changed to " .. option)
    end
})

-- Custom API Section
local APISection = SettingsTab:AddSection("API Settings")

APISection:AddInput({
    Title = "Custom API URL",
    Description = "Enter custom API URL for server list",
    Default = customAPI,
    Placeholder = "https://example.com/api",
    Callback = function(text)
        if text ~= "" then
            customAPI = text
            SaveSettings("customAPI", text)
            notify("API", "Custom API URL updated")
        end
    end
})

-- Moon Info Display
local MoonSection = MoonTab:AddSection("Moon Information")

local function UpdateMoonInfo()
    moonLabel:SetText("Moon: " .. CheckMoon())
    timeLabel:SetText("Time: " .. GetMoonTimeInfo())
    phaseLabel:SetText("Phase: " .. GetGameTime())
end

MoonSection:AddButton({
    Title = "Update Moon Info",
    Description = "Manually update moon information",
    Callback = function()
        UpdateMoonInfo()
        notify("Moon Info", "Information updated!")
    end
})

-- About Section
local AboutSection = AboutTab:AddSection("Information")

AboutSection:AddParagraph({
    Title = "Script Information",
    Content = "HerinaAuto Join Blox Fruit (Fluent UI Edition)\nVersion: 1.0.0\nCreated by: Herina\n\nPress RightShift to toggle UI on PC\nUse the buttons above on mobile"
})

-- Initialize UI Updates
task.spawn(function()
    while true do
        UpdateMoonInfo()
        task.wait(1)
    end
end)

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
        notify("Error", "Failed to fetch servers. Retrying...")
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
