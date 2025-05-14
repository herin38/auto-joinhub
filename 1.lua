-- Auto Full Moon Server Joiner for Blox Fruits
-- This script automatically joins a server with Full Moon using the provided API

local http = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local player = game.Players.LocalPlayer

-- Function to fetch Full Moon server data
local function fetchFullMoonServer()
    local success, response = pcall(function()
        return http:GetAsync("https://game.hentaiviet.top/fullmoon.php")
    end)
    
    if success then
        return response
    else
        warn("Failed to fetch Full Moon data: " .. tostring(response))
        return nil
    end
end

-- Function to extract Job ID from response
local function extractJobId(response)
    -- First try to extract from the PC Copy section
    local jobId = response:match('"%*%* %[🔗%]・__Job ID %(PC Copy%)__ : %*%*", "value": "\n```\nyaml\\n([%w%-]+)\\n```\n", "inline"')
    
    if jobId then
        print("Found Job ID from PC Copy section: " .. jobId)
        return jobId
    end
    
    -- If first method fails, try the Server Id section
    jobId = response:match('"name": "Server Id", "value": "\n```\nyaml\\n([%w%-]+)\\n```\n", "inline"')
    
    if jobId then
        print("Found Job ID from Server Id section: " .. jobId)
        return jobId
    end
    
    return nil
end

-- Function to join server with specific Job ID
local function joinServer(jobId)
    print("Attempting to join server with Job ID: " .. jobId)
    
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        warn("Failed to teleport: " .. tostring(errorMessage))
        return false
    end
    
    return true
end

-- Main function
local function findAndJoinFullMoonServer()
    local maxAttempts = 5
    local attempts = 0
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        print("Attempt " .. attempts .. " to find Full Moon server")
        
        local response = fetchFullMoonServer()
        if not response then
            print("Could not get response from API. Retrying in 5 seconds...")
            wait(5)
            continue
        end
        
        local jobId = extractJobId(response)
        if not jobId then
            print("Could not extract Job ID. Retrying in 5 seconds...")
            wait(5)
            continue
        end
        
        print("Found Job ID: " .. jobId)
        local success = joinServer(jobId)
        
        if success then
            print("Successfully sent teleport request!")
            break
        else
            print("Server might be full. Retrying with a new server in 5 seconds...")
            wait(5)
        end
    end
    
    if attempts >= maxAttempts then
        print("Maximum attempts reached. Could not join a Full Moon server.")
    end
end

-- Start the process
spawn(function()
    print("Starting Auto Full Moon Server Joiner")
    findAndJoinFullMoonServer()
end)

-- You can also create a simple GUI to show the status
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
Frame.Parent = ScreenGui

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 1, -10)
StatusLabel.Position = UDim2.new(0, 5, 0, 5)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Text = "Looking for Full Moon server..."
StatusLabel.TextScaled = true
StatusLabel.Parent = Frame

-- Update the GUI when events happen
spawn(function()
    while wait(1) do
        if not ScreenGui or not ScreenGui.Parent then
            break
        end
        StatusLabel.Text = "Looking for Full Moon server...\nAttempting to join..."
    end
end)