local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Full Moon Auto Join", "Ocean")

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Full Moon Features")

-- Variables
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local AutoJoinEnabled = false
local CheckInterval = 60 -- Check every 60 seconds

-- Moon Status Functions
local function MoonTextureId()
    local Lighting = game:GetService("Lighting")
    if Lighting:FindFirstChild("FantasySky") then
        return Lighting.FantasySky.MoonTextureId
    elseif Lighting:FindFirstChild("Sky") then
        return Lighting.Sky.MoonTextureId
    end
    return ""
end

local function CheckMoon()
    local moonTextures = {
        ["http://www.roblox.com/asset/?id=9709150401"] = "Moon 8",
        ["http://www.roblox.com/asset/?id=9709150086"] = "Moon 7",
        ["http://www.roblox.com/asset/?id=9709149680"] = "Moon 6",
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon",
        ["http://www.roblox.com/asset/?id=9709149052"] = "Next Night",
        ["http://www.roblox.com/asset/?id=9709143733"] = "Moon 3",
        ["http://www.roblox.com/asset/?id=9709139597"] = "Moon 2",
        ["http://www.roblox.com/asset/?id=9709135895"] = "Moon 1"
    }
    
    local currentMoon = MoonTextureId()
    return moonTextures[currentMoon] or "Unknown"
end

-- Teleport Functions
local function topos(targetCFrame)
    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local tweenInfo = TweenInfo.new(
        (targetCFrame.Position - humanoidRootPart.Position).Magnitude/300,
        Enum.EasingStyle.Linear
    )
    
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

local function getBlueGear()
    if game.workspace.Map:FindFirstChild("MysticIsland") then
        for _, v in pairs(game.workspace.Map.MysticIsland:GetChildren()) do
            if v:IsA("MeshPart") and v.MeshId == "rbxassetid://10153114969" then
                return v
            end
        end
    end
    return nil
end

local function getHighestPoint()
    if not game.workspace.Map:FindFirstChild("MysticIsland") then
        return nil
    end
    for _, v in pairs(game.workspace.Map.MysticIsland:GetDescendants()) do
        if v:IsA("MeshPart") and v.MeshId == "rbxassetid://6745037796" then
            return v
        end
    end
    return nil
end

-- Server Joining Functions
local function JoinServer(serverId)
    if serverId then
        local success, error = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        end)
        if not success then
            warn("Failed to teleport:", error)
        end
    end
end

local function CheckAndJoinFullMoonServer()
    local success, response = pcall(function()
        return game:HttpGet("https://game.hentaiviet.top/fullmoon.php")
    end)
    
    if success then
        local serverData = game:GetService("HttpService"):JSONDecode(response)
        if serverData and serverData.value then
            JoinServer(serverData.value)
        end
    end
end

-- UI Elements
MainSection:NewToggle("Auto Join Full Moon Server", "Automatically joins a server with Full Moon", function(state)
    AutoJoinEnabled = state
    if state then
        spawn(function()
            while AutoJoinEnabled do
                local moonStatus = CheckMoon()
                if moonStatus ~= "Full Moon" then
                    CheckAndJoinFullMoonServer()
                end
                wait(CheckInterval)
            end
        end)
    end
end)

MainSection:NewButton("Check Moon Status", "Shows current moon phase", function()
    local status = CheckMoon()
    Library:Notify("Moon Status", status, 5)
end)

MainSection:NewButton("Teleport to Blue Gear", "Teleports to Blue Gear if available", function()
    local blueGear = getBlueGear()
    if blueGear then
        topos(blueGear.CFrame)
    else
        Library:Notify("Error", "Blue Gear not found!", 3)
    end
end)

MainSection:NewButton("Teleport to Highest Point", "Teleports to highest point of Mystic Island", function()
    local highestPoint = getHighestPoint()
    if highestPoint then
        topos(highestPoint.CFrame * CFrame.new(0, 211.88, 0))
    else
        Library:Notify("Error", "Highest point not found!", 3)
    end
end)

-- Status Label
local StatusSection = MainTab:NewSection("Status")
local StatusLabel = StatusSection:NewLabel("Checking status...")

-- Update Status
spawn(function()
    while wait(1) do
        local moonStatus = CheckMoon()
        local mysticIsland = game.workspace.Map:FindFirstChild("MysticIsland") and "Yes" or "No"
        StatusLabel:UpdateLabel("Moon: " .. moonStatus .. " | Mystic Island: " .. mysticIsland)
    end
end) 