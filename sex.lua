local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HerinaAuto Join Blox Fruit",
    SubTitle = "Full Moon Auto Joiner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "moon" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Status = Window:AddTab({ Title = "Server Status", Icon = "info" }),
    About = Window:AddTab({ Title = "About", Icon = "help-circle" })
}

local Options = Fluent.Options
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

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
    return success and result or {}
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

local moonLabel = Tabs.Status:AddParagraph({ Title = "Moon", Content = "Loading..." })
local timeLabel = Tabs.Status:AddParagraph({ Title = "Time", Content = GetMoonTimeInfo() })
local phaseLabel = Tabs.Status:AddParagraph({ Title = "Phase", Content = GetGameTime() })
local mirageLabel = Tabs.Status:AddParagraph({ Title = "Mirage", Content = "Checking..." })

spawn(function()
    while wait(1) do
        moonLabel:SetText("Moon: " .. CheckMoon())
        timeLabel:SetText("Time: " .. GetMoonTimeInfo())
        phaseLabel:SetText("Phase: " .. GetGameTime())
    end
end)

spawn(function()
    while wait(1) do
        if game.Workspace:FindFirstChild("_WorldOrigin") and game.Workspace._WorldOrigin:FindFirstChild("Locations") then
            if game.Workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") then
                mirageLabel:SetText("Mirage: Spawning ✅")
            else
                mirageLabel:SetText("Mirage: Not Spawning ❌")
            end
        else
            mirageLabel:SetText("Mirage: Not Spawning ❌")
        end
    end
end)
