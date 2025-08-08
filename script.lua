--===[ GLOBAL TOGGLE ]===
_G.AutoBotEnabled = true

--===[ CONFIGS ]===
_G.DelayDodgeNormal = 0.15
_G.DelayDodgeHeavy = 0.3
_G.activateRange = 10
_G.EnableCounter = true
_G.M1Delay = 0.2
_G.EnableIdleAttack = true
_G.EnableDodge = true
_G.EnableFeint = false
_G.FeintDelay = 0.1

--===[ SERVICE & PLAYER CACHE ]===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")
local States = Workspace:WaitForChild("States"):WaitForChild(LocalPlayer.Name)
local Occupied = States.Occupied
local LockedOn = Occupied.LockedOn
local mouse = LocalPlayer:GetMouse()

--===[ MAIN HOOK DETECTION ]===
local Main
for _, v in next, getgc(true) do
    if typeof(v) == "table" and rawget(v, "StartupHighlight") then
        Main = v
        break
    end
end
if not Main then
    repeat
        for _, v in next, getgc(true) do
            if typeof(v) == "table" and rawget(v, "StartupHighlight") then
                Main = v
                break
            end
        end
        RunService.Heartbeat:Wait()
    until Main
end

--===[ FUNCTIONS ]===
local function getDistance()
    if not _G.AutoBotEnabled then return false end
    local char = LocalPlayer.Character
    local target = LockedOn.Value
    if char and target and char:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart") then
        return (char.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude <= _G.activateRange
    end
    return false
end

local function Dodge()
    if _G.AutoBotEnabled and _G.EnableDodge then
        keypress(0x20)
        task.wait(0.05)
        keyrelease(0x20)
    end
end

local function Block()
    if _G.AutoBotEnabled then
        keypress(0x46)
        task.wait(1)
        keyrelease(0x46)
    end
end

--===[ HOOKS ]===
local oldStartup = Main.StartupHighlight
local oldDash = Main.DashHighlight
Main._Highlighting = false

Main.StartupHighlight = function(data)
    if not _G.AutoBotEnabled then return oldStartup(data) end
    Main._Highlighting = true

    local target = LockedOn.Value
    if target and data[2] == target and getDistance() then
        local isFeint, isHeavy, isUltimate = data[7], data[3], data[5]

        task.spawn(function()
            if isFeint then
                keyrelease(0x46)
                mouse1press()
                task.wait(_G.M1Delay)
                mouse1release()
            elseif isHeavy then
                if _G.EnableCounter then
                    keyrelease(0x46)
                    mouse1press()
                    task.wait(_G.M1Delay)
                    mouse1release()
                else
                    task.wait(_G.DelayDodgeHeavy)
                    Dodge()
                end
            elseif isUltimate then
                Block()
            else
                task.wait(_G.DelayDodgeNormal)
                Dodge()
            end
        end)
    end

    Main._Highlighting = false
    return oldStartup(data)
end

Main.DashHighlight = function(data)
    if not _G.AutoBotEnabled then return oldDash(data) end
    local target = LockedOn.Value
    if target and target == data[2] and getDistance() then
        keyrelease(0x46)
        mouse1press()
        task.wait(_G.M1Delay)
        mouse1release()
    end
    return oldDash(data)
end

--===[ RIGHT-CLICK FEINT LISTENER ]===
mouse.Button2Down:Connect(function()
    if not _G.AutoBotEnabled then return end
    if not _G.EnableFeint then return end
    if not LockedOn.Value then return end
    if not getDistance() then return end
    if Main._Highlighting then return end

    task.spawn(function()
        task.wait(_G.FeintDelay)
        keyrelease(0x46)
        mouse1press()
        task.wait(_G.M1Delay)
        mouse1release()
    end)
end)

--===[ IDLE ATTACK LOOP ]===
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoBotEnabled and _G.EnableIdleAttack and LockedOn.Value and getDistance() and not Main._Highlighting then
            mouse2press()
            task.wait(0.05)
            mouse2release()
            mouse1press()
            task.wait(_G.M1Delay)
            mouse1release()
        end
    end
end)

--===[ GUI ]===
local gui = Instance.new("ScreenGui")
gui.Name = "AutoBotConfig"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 220)
frame.Position = UDim2.new(0, 10, 1, -240)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.1
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.FillDirection = Enum.FillDirection.Vertical
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = frame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    _G.AutoBotEnabled = false
    _G.EnableCounter = false
    _G.EnableIdleAttack = false
    _G.EnableDodge = false
    _G.EnableFeint = false
    gui:Destroy()
end)

local function createToggle(label, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 2
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    if _G[key] == nil then _G[key] = false end

    local function updateStyle()
        btn.Text = label .. ": " .. (_G[key] and "ON" or "OFF")
        btn.BorderColor3 = _G[key] and Color3.fromRGB(0, 255, 0) or btn.BackgroundColor3
    end

    btn.MouseButton1Click:Connect(function()
        _G[key] = not _G[key]
        updateStyle()
    end)

    updateStyle()
end

createToggle("Main", "AutoBotEnabled")
createToggle("Counter", "EnableCounter")
createToggle("Feint", "EnableFeint")
createToggle("Idle Attack", "EnableIdleAttack")
createToggle("Dodge", "EnableDodge")
