--===[ GLOBAL TOGGLE & CONFIGS ]===
_G.AutoBotEnabled = true
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
                if _G.EnableFeint then
                    keyrelease(0x46)
                    mouse1press()
                    task.wait(_G.M1Delay)
                    mouse1release()
                end
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

--===[ GUI LIBRARY INIT ]===
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Other/main/1"))()
library:init()

local Window = library.NewWindow({
    title = "AutoBot Controller",
    size = UDim2.new(0, 525, 0, 650)
})

local tabs = {
    Main = Window:AddTab("Main"),
    Settings = library:CreateSettingsTab(Window)
}

local sections = {
    Toggles = tabs.Main:AddSection("Toggles", 1),
    Config = tabs.Main:AddSection("Config", 2)
}

--===[ TOGGLES ]===
sections.Toggles:AddToggle({ text = "Auto Bot Enabled", enabled = _G.AutoBotEnabled, callback = function(state) _G.AutoBotEnabled = state end })
sections.Toggles:AddToggle({ text = "Counter", enabled = _G.EnableCounter, callback = function(state) _G.EnableCounter = state end })
sections.Toggles:AddToggle({ text = "Feint", enabled = _G.EnableFeint, callback = function(state) _G.EnableFeint = state end })
sections.Toggles:AddToggle({ text = "Idle Attack", enabled = _G.EnableIdleAttack, callback = function(state) _G.EnableIdleAttack = state end })
sections.Toggles:AddToggle({ text = "Dodge", enabled = _G.EnableDodge, callback = function(state) _G.EnableDodge = state end })

--===[ CONFIG INPUTS ]===
sections.Config:AddBox({ text = "Delay Dodge Normal", input = tostring(_G.DelayDodgeNormal), callback = function(val) local num = tonumber(val) if num then _G.DelayDodgeNormal = num end end })
sections.Config:AddBox({ text = "Delay Dodge Heavy", input = tostring(_G.DelayDodgeHeavy), callback = function(val) local num = tonumber(val) if num then _G.DelayDodgeHeavy = num end end })
sections.Config:AddBox({ text = "Activate Range", input = tostring(_G.activateRange), callback = function(val) local num = tonumber(val) if num then _G.activateRange = num end end })
sections.Config:AddBox({ text = "M1 Delay", input = tostring(_G.M1Delay), callback = function(val) local num = tonumber(val) if num then _G.M1Delay = num end end })
sections.Config:AddBox({ text = "Feint Delay", input = tostring(_G.FeintDelay), callback = function(val) local num = tonumber(val) if num then _G.FeintDelay = num end end })

library:SendNotification("AutoBot Fully Loaded", 5, Color3.fromRGB(0, 200, 0))
