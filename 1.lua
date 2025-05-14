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

--// Load UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
if not Fluent then return warn("❌ Failed to load Fluent UI Library!") end
local SaveManager = Fluent.SaveManager
local InterfaceManager = Fluent.InterfaceManager

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

--// UI Setup
local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Tabs
local MainTab = Window:AddTab({ Title = "Main", Icon = "home" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
local ServersTab = Window:AddTab({ Title = "Servers", Icon = "server" })
local MoonTab = Window:AddTab({ Title = "Moon Info", Icon = "moon" })

-- Main Tab
local MainSection = MainTab:AddSection("🌕 Full Moon Auto Join")
MainSection:AddToggle({
    Title = "Auto Join Full Moon",
    Default = false,
    Callback = function(v)
        isAutoJoining = v
        if v then
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

MainSection:AddButton({
    Title = "Server Hop",
    Description = "Jump to a new full moon server",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers > 0 then
            joinFullMoonServer(fullMoonServers[math.random(1, #fullMoonServers)])
        end
    end
})

local Status = MainTab:AddSection("📊 Status")
local statusLabel = Status:AddParagraph({
    Title = "Current Status",
    Content = "Waiting..."
})

task.spawn(function()
    while task.wait(1) do
        local moon = CheckMoon()
        statusLabel:SetContent(string.format("Moon: %s\nTime: %s\nPhase: %s\nAuto Join: %s\nDelay: %d",
            moon,
            GetFormattedTime(),
            GetGameTime(),
            isAutoJoining and "Running" or "Stopped",
            retryDelay
        ))
    end
end)

-- Settings Tab
SettingsTab:AddSection("⚙️ Settings"):AddSlider({
    Title = "Retry Delay (seconds)",
    Default = 5, Min = 1, Max = 30,
    Callback = function(v) retryDelay = v end
})

-- Moon Info
local moonParagraph = MoonTab:AddSection("🌕 Moon Status"):AddParagraph({
    Title = "Moon Phase",
    Content = "Checking..."
})

task.spawn(function()
    while task.wait(1) do
        moonParagraph:SetContent("Phase: " .. CheckMoon() .. "\nTime: " .. GetFormattedTime())
    end
end)

-- Servers Tab
local serverSection = ServersTab:AddSection("🖥️ Server List")
local serverListLabel = serverSection:AddParagraph({
    Title = "Server Results",
    Content = "No servers yet"
})

serverSection:AddButton({
    Title = "🔁 Refresh Servers",
    Callback = function()
        fullMoonServers = fetchFullMoonServers()
        if #fullMoonServers == 0 then
            serverListLabel:SetContent("❌ No servers found")
            return
        end

        local result = ""
        for i, server in ipairs(fullMoonServers) do
            if i > 5 then break end
            result = result .. string.format("🔹 Server %d | Players: %s | Type: %s\n",
                i, server.players, server.serverType)
        end
        if #fullMoonServers > 5 then
            result = result .. string.format("\n...and %d more servers", #fullMoonServers - 5)
        end
        serverListLabel:SetContent(result)
    end
})

-- Notify on load
Fluent:Notify({
    Title = "✅ Script Loaded",
    Content = "Press RightShift to toggle the UI!",
    Duration = 5
})
