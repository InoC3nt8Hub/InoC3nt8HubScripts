local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.Scheme.MainColor = Color3.fromRGB(0, 0, 0)

Library.Scheme.AccentColor = Color3.fromRGB(85, 217, 255)

Library.Scheme.BackgroundColor = Color3.fromRGB(0, 0, 0)

Library.Scheme.OutlineColor = Color3.fromRGB(25, 23, 23)

Library.Scheme.FontColor = Color3.fromRGB(255, 255, 255)

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- Window
local Window = Library:CreateWindow({
    Title = "InoC3nt8 Hub",
    Footer = "Ground War v1.0",
    Icon = 6942501524,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

Window:SetCornerRadius(8)

local DiscordInvite = "https://discord.gg/EzxJkFcuH"
local DiscordTab = Window:AddTab("Discord", "message-circle")

-- Tabs
local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Visual = Window:AddTab("Visual", "eye"),
    Misc = Window:AddTab("Misc", "wrench"),
    Settings = Window:AddTab("Settings", "cog"),
}

local CommunityBox = DiscordTab:AddLeftGroupbox("Community Info", "crown")

CommunityBox:AddLabel(
    "Welcome to our community!\n\n"
    .. "• Script updates\n"
    .. "• Game support\n"
    .. "• Announcements\n"
    .. "• Community events\n"
    .. "• Support & feedback",
    true
)

CommunityBox:AddDivider()

CommunityBox:AddLabel("Discord Server: Online")


local DiscordBox = DiscordTab:AddLeftGroupbox("Discord", "external-link")

DiscordBox:AddButton({
    Text = "Join Discord",

    Func = function()

        if setclipboard then
            setclipboard(DiscordInvite)
        end

        Library:Notify({
            Title = "Discord",
            Description = "Invite link copied!",
            Time = 3
        })

        -- Opens Discord invite when supported by the executor
        pcall(function()
            if syn and syn.request then
                syn.request({
                    Url = DiscordInvite,
                    Method = "GET"
                })
            end
        end)

    end
})


DiscordBox:AddButton({
    Text = "Copy Invite Link",

    Func = function()

        if setclipboard then

            setclipboard(DiscordInvite)

            Library:Notify({
                Title = "Discord",
                Description = "Invite link copied to clipboard!",
                Time = 3
            })

        else

            Library:Notify({
                Title = "Discord",
                Description = DiscordInvite,
                Time = 5
            })

        end

    end
})

DiscordBox:AddDivider()

DiscordBox:AddLabel("Server Status")

local StatusLabel = DiscordBox:AddLabel(
    "● Checking...",
    false
)

local MemberLabel = DiscordBox:AddLabel(
    "Members: Checking...",
    false
)

task.spawn(function()

    while task.wait(30) do

        local Success, Response = pcall(function()

            return game:HttpGet(
                "https://discord.com/api/v10/invites/"
                .. DiscordInvite:match("discord.gg/(.+)$")
                .. "?with_counts=true"
            )

        end)

        if Success and Response then

            local Data = game:GetService("HttpService"):JSONDecode(Response)

            if Data and Data.approximate_presence_count then

                StatusLabel:SetText("● Server Online")

                MemberLabel:SetText(
                    "Members Online: "
                    .. tostring(Data.approximate_presence_count)
                )

            else

                StatusLabel:SetText("● Server Available")

            end

        else

            StatusLabel:SetText("● Status Unavailable")

            MemberLabel:SetText("Members: Unknown")

        end

    end

end)


StatusLabel:SetText("● Server Available")
MemberLabel:SetText("Members: Loading...")

local UpdateBox = DiscordTab:AddRightGroupbox("Update Logs","scroll-text")

UpdateBox:AddLabel([[
Ground War V1.0

+ HitBox
+ BringPlayer
+ Aimbot
+ Ragebot
+ FOV
+ TeamCheck
+ WallCheck
+ EnemyESP
+ TeammateESP
+ VehicleESP
+ FPSBooster 
+ FullBright 
+ CustomCrossHair
+ Anti AFK
+ Server Hop
+ Auto Server Rejoin
+ Rejoin Server

]], true)

--------------------------------------------------
-- MAIN TAB
--------------------------------------------------

local MainBox = Tabs.Main:AddLeftGroupbox("Combat Features", "swords")
local MainBox2 = Tabs.Main:AddLeftGroupbox("Aimbot", "crosshair")
local MainBox3 = Tabs.Main:AddRightGroupbox("Targeting", "locate")
local MainBox4 = Tabs.Main:AddRightGroupbox("Aim Prediction", "menu")
local MainBox5 = Tabs.Main:AddRightGroupbox("Bring Enemy", "users")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local originals = {}

-- Settings (persistent while script runs)
local enabled = false
local hitboxSize = 6
local selectedPartName = "Head"               -- default part
local hitboxColor = Color3.fromRGB(85, 217, 255) -- fixed color (as requested)
local includeNPCs = false                     -- toggle to expand NPCs

-- --------------------------------
-- Helper Functions
-- --------------------------------

local function isVehicle(model)
    -- Skip models that are vehicles
    if model:FindFirstChildOfClass("VehicleSeat") then return true end
    if string.find(model.Name:lower(), "vehicle") then return true end
    return false
end

local function isEnemy(model)
    -- Returns true if the model is an enemy (player on other team or NPC if allowed)
    if not model:FindFirstChildOfClass("Humanoid") then return false end

    -- Check if it's a player character
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        -- Players: only enemy if teams differ and both have a team
        if localPlayer.Team and player.Team then
            return localPlayer.Team ~= player.Team
        else
            -- If no team, treat as enemy (or could ignore)
            return true
        end
    else
        -- Non-player: NPC
        return includeNPCs  -- only expand if toggle is on
    end
end

local function store(part)
    if not originals[part] then
        originals[part] = part.Size
    end
end

local function expand(part)
    store(part)
    part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
    part.Transparency = 0.35
    part.Material = Enum.Material.Neon
    part.Color = hitboxColor
    part.CanCollide = false
end

local function expandCharacter(model)
    if isVehicle(model) then return end
    if not isEnemy(model) then return end

    local part = model:FindFirstChild(selectedPartName)
    if part and part:IsA("BasePart") then
        expand(part)
        return
    end

    -- Fallback: if selected part not found, try PrimaryPart
    if model.PrimaryPart then
        expand(model.PrimaryPart)
        return
    end

    -- If nothing found, expand all BaseParts (just in case)
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            expand(v)
        end
    end
end

local function restoreCharacter(model)
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") and originals[v] then
            v.Size = originals[v]
            v.Transparency = 0
            v.Material = Enum.Material.Plastic
            originals[v] = nil
        end
    end
end

local function applyAll()
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
            expandCharacter(model)
        end
    end
end

local function removeAll()
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
            restoreCharacter(model)
        end
    end
end

-- Watch for new characters entering workspace
workspace.DescendantAdded:Connect(function(obj)
    if not enabled then return end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
        task.wait(0.2)  -- wait for parts to load
        expandCharacter(obj)
    end
end)

-- Also watch for parts being added to existing models (e.g. NPC spawns)
workspace.DescendantAdded:Connect(function(obj)
    if not enabled then return end
    if obj:IsA("BasePart") then
        local model = obj.Parent
        if model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
            task.wait(0.1)
            expandCharacter(model)
        end
    end
end)

-- --------------------------------
-- MainBox UI integration
-- --------------------------------

if not MainBox then
    warn("MainBox not found – UI will not work")
else
    local Main = MainBox

    -- Toggle: Enable/Disable hitbox
    Main:AddToggle("EnableHitbox", {
        Text = "Enable Hitbox",
        Default = false,
        Callback = function(value)
            enabled = value
            if enabled then
                applyAll()
            else
                removeAll()
            end
        end
    })
    
        -- Dropdown: Select part to expand
    Main:AddDropdown("PartSelect", {
        Values = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" },
        Default = 1,
        Text = "Part to Expand",
        Callback = function(value)
            selectedPartName = value
            if enabled then
                removeAll()
                applyAll()
            end
        end
    })

    -- Slider: Hitbox size
    Main:AddSlider("SizeSlider", {
        Text = "Hitbox Size",
        Default = 6,
        Min = 3,
        Max = 150,
        Rounding = 0,
        Callback = function(value)
            hitboxSize = value
            if enabled then
                removeAll()
                applyAll()
            end
        end
    })

    -- Toggle: Include NPCs (non-player characters)
    Main:AddToggle("IncludeNPCs", {
        Text = "Enemy Only HitBox",
        Default = false,
        Callback = function(value)
            includeNPCs = value
            if enabled then
                removeAll()
                applyAll()
            end
        end
    })

    print("NPC Hitbox v5 loaded with MainBox UI (fixed color)")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local AimEnabled = false
local RagebotEnabled = false          -- New: Ragebot toggle
local PredictionEnabled = true        -- New: Prediction toggle
local PredictionStrength = 0.3        -- New: Prediction multiplier (0-1)

local FOVEnabled = false
local TeamCheck = true
local WallCheck = true
local VehiclePlayerCheck = true

local FOVSize = 150
local AimDistance = 200
local AimSmoothness = 0.18

local TargetPartName = "Head"
local FOVColor = Color3.fromRGB(85, 217, 255)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = FOVEnabled
FOVCircle.Radius = FOVSize
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Color = FOVColor

--==================================================
-- TARGET CACHE
--==================================================

local TargetCache = {}

local function AddTarget(object)
    if not object:IsA("Model") then return end
    local humanoid = object:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if object == LocalPlayer.Character then return end
    TargetCache[object] = true
end

local function RemoveTarget(object)
    TargetCache[object] = nil
end

-- Existing Humanoid Models
for _, object in ipairs(workspace:GetDescendants()) do
    AddTarget(object)
end

-- New Models
workspace.DescendantAdded:Connect(function(object)
    if object:IsA("Model") then
        task.defer(function() AddTarget(object) end)
    end
end)

workspace.DescendantRemoving:Connect(function(object)
    if object:IsA("Model") then
        RemoveTarget(object)
    end
end)

--==================================================
-- ALIVE CHECK
--==================================================

local function IsAlive(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

--==================================================
-- PLAYER CHECK
--==================================================

local function GetPlayerFromCharacter(model)
    return Players:GetPlayerFromCharacter(model)
end

--==================================================
-- TEAM CHECK
--==================================================

local function IsSameTeam(model)
    if not TeamCheck then return false end
    local player = GetPlayerFromCharacter(model)
    if not player then return false end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

--==================================================
-- VEHICLE PLAYER CHECK
--==================================================

local function IsPlayerInVehicle(model)
    if not VehiclePlayerCheck then return false end
    local player = GetPlayerFromCharacter(model)
    if not player then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.SeatPart then return true end
    return false
end

--==================================================
-- TARGET PART
--==================================================

local function GetTargetPart(model)
    if TargetPartName == "Head" then
        local head = model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
    elseif TargetPartName == "HumanoidRootPart" then
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
    end
    -- Fallback
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    return nil
end

--==================================================
-- WALL CHECK
--==================================================

local function HasLineOfSight(part)
    if not WallCheck then return true end
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(part.Parent)
end

--==================================================
-- FOV CHECK
--==================================================

local function IsInsideFOV(part)
    if not part then return false end
    local screenPosition, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local screenPoint = Vector2.new(screenPosition.X, screenPosition.Y)
    local distance = (screenPoint - center).Magnitude
    return distance <= FOVSize
end

--==================================================
-- PREDICTION
--==================================================

local function GetPredictedPosition(part)
    if not PredictionEnabled then
        return part.Position
    end
    -- Use the part's velocity (works for vehicles too)
    local velocity = part.Velocity
    if velocity.Magnitude < 0.1 then
        return part.Position
    end
    -- Estimate travel time based on distance and a base speed (adjust as needed)
    local distance = (part.Position - Camera.CFrame.Position).Magnitude
    local baseSpeed = 2000  -- hypothetical bullet speed (studs/sec)
    local travelTime = distance / baseSpeed
    -- Apply prediction strength as a multiplier on travel time
    local predicted = part.Position + velocity * travelTime * PredictionStrength
    return predicted
end

--==================================================
-- GET NEAREST TARGET
--==================================================

local function GetNearestTarget()
    local cameraPosition = Camera.CFrame.Position
    local nearestModel = nil
    local nearestPart = nil
    local nearestDistance = AimDistance

    for model in pairs(TargetCache) do
        if model and model.Parent and model:IsDescendantOf(workspace) and model ~= LocalPlayer.Character then
            if IsAlive(model) then
                if not IsSameTeam(model) then
                    if not IsPlayerInVehicle(model) then
                        local targetPart = GetTargetPart(model)
                        if targetPart then
                            local distance = (targetPart.Position - cameraPosition).Magnitude
                            if distance <= AimDistance then
                                -- FOV check: skip if Ragebot is on, else enforce FOV
                                if RagebotEnabled or IsInsideFOV(targetPart) then
                                    if HasLineOfSight(targetPart) then
                                        if distance < nearestDistance then
                                            nearestDistance = distance
                                            nearestModel = model
                                            nearestPart = targetPart
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestModel, nearestPart
end

--==================================================
-- AIM
--==================================================

local function AimAt(part, dt)
    if not part then return end

    -- If Ragebot is enabled, force smoothness to zero
    local smoothness = RagebotEnabled and 0 or AimSmoothness

    -- Get predicted position
    local targetPos = GetPredictedPosition(part)
    local cameraCFrame = Camera.CFrame
    local cameraPosition = cameraCFrame.Position
    local direction = targetPos - cameraPosition
    if direction.Magnitude <= 0 then return end
    direction = direction.Unit

    local targetCFrame = CFrame.new(cameraPosition, cameraPosition + direction)
    local alpha = math.clamp(1 - math.pow(smoothness, dt * 60), 0, 1)
    Camera.CFrame = cameraCFrame:Lerp(targetCFrame, alpha)
end

--==================================================
-- RENDER LOOP
--==================================================

RunService.RenderStepped:Connect(function(dt)
    -- FOV
    FOVCircle.Visible = FOVEnabled
    FOVCircle.Radius = FOVSize
    FOVCircle.Color = FOVColor
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aim
    if not AimEnabled then return end
    local targetModel, targetPart = GetNearestTarget()
    if targetPart then
        AimAt(targetPart, dt)
    end
end)

--==================================================
-- E KEY TOGGLE
--==================================================

LocalPlayer:GetMouse().KeyDown:Connect(function(key)
    if key:lower() == "e" then
        AimEnabled = not AimEnabled
    end
end)

--==================================================
-- OBSIDIAN UI
--==================================================

MainBox2:AddToggle("AimAssistToggle", {
    Text = "Aim bot",
    Default = false,
    Callback = function(Value)
        AimEnabled = Value
    end
}):AddKeyPicker("AimAssistKeybind", {
    Default = "LeftShift",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Aim bot Keybind",
})

MainBox3:AddToggle("FOVToggle", {
    Text = "FOV Circle",
    Default = false,
    Callback = function(Value)
        FOVEnabled = Value
        FOVCircle.Visible = Value
    end
}):AddColorPicker("FOVColorPicker", {
    Default = Color3.fromRGB(85, 217, 255),
    Title = "FOV Color",
    Callback = function(Value)
        FOVColor = Value
        FOVCircle.Color = Value
    end
}):AddKeyPicker("FOVKeybind", {
    Default = "F",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "FOV Circle Keybind",
})

MainBox2:AddToggle("RagebotToggle", {
    Text = "Ragebot",
    Default = false,
    Callback = function(Value)
        RagebotEnabled = Value
    end
}):AddKeyPicker("RagebotKeybind", {
    Default = "X",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Ragebot Keybind",
})

-- Prediction Toggle
MainBox4:AddToggle("PredictionToggle", {
    Text = "Prediction",
    Default = true,
    Callback = function(Value)
        PredictionEnabled = Value
    end
})

-- Prediction Strength Slider
MainBox4:AddSlider("PredictionStrengthSlider", {
    Text = "Prediction Strength",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        PredictionStrength = Value
    end
})

MainBox2:AddDropdown("AimTargetDropdown", {
    Values = {"Head", "HumanoidRootPart"},
    Default = "Head",
    Text = "Target Part",
    Callback = function(Value)
        TargetPartName = Value
    end
})

-- FOV Size
MainBox3:AddSlider("FOVSizeSlider", {
    Text = "FOV Size",
    Default = 150,
    Min = 25,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        FOVSize = Value
        FOVCircle.Radius = Value
    end
})

-- Aim Distance
MainBox2:AddSlider("AimDistanceSlider", {
    Text = "Aim Distance",
    Default = 200,
    Min = 25,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        AimDistance = Value
    end
})

-- Aim Smoothness
MainBox2:AddSlider("AimSmoothnessSlider", {
    Text = "Aim Smoothness",
    Default = 0.18,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        AimSmoothness = Value
    end
})

-- Team Check
MainBox3:AddToggle("TeamCheckToggle", {
    Text = "Team Check",
    Default = true,
    Callback = function(Value)
        TeamCheck = Value
    end
})

-- Wall Check
MainBox3:AddToggle("WallCheckToggle", {
    Text = "Wall Check",
    Default = true,
    Callback = function(Value)
        WallCheck = Value
    end
})

-- Vehicle Player Check
MainBox3:AddToggle("VehiclePlayerCheckToggle", {
    Text = "Vehicle Player Check",
    Default = true,
    Callback = function(Value)
        VehiclePlayerCheck = Value
    end
})

--==================================================
-- ENEMY BRING
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local BringEnabled = false
local BringDistance = 5

--==================================================
-- GET CHARACTER
--==================================================

local function getCharacterFromHumanoid(humanoid)
    if not humanoid then
        return nil
    end

    local character = humanoid.Parent

    if character and character:IsA("Model") then
        return character
    end

    return nil
end

--==================================================
-- TEAM CHECK
--==================================================

local function isEnemy(character)
    local player = Players:GetPlayerFromCharacter(character)

    if not player then
        return false
    end

    if player == LocalPlayer then
        return false
    end

    -- Enemy Team Only
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end

    return true
end

--==================================================
-- VEHICLE CHECK
--==================================================

local function isInVehicle(character)
    if not character then
        return false
    end

    -- Attribute checks
    if character:GetAttribute("InVehicle") == true then
        return true
    end

    if character:GetAttribute("Vehicle") ~= nil then
        return true
    end

    -- VehicleSeat check
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.SeatPart then
        if humanoid.SeatPart:IsA("VehicleSeat") then
            return true
        end
    end

    return false
end

--==================================================
-- VALID ENEMY
--==================================================

local function isValidEnemy(character)
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then
        return false
    end

    if humanoid.Health <= 0 then
        return false
    end

    -- Enemy only
    if not isEnemy(character) then
        return false
    end

    -- Vehicle enemy ignored
    if isInVehicle(character) then
        return false
    end

    return true
end

--==================================================
-- BRING ONE ENEMY
--==================================================

local function bringEnemy(character, playerHRP)
    if not isValidEnemy(character) then
        return
    end

    local enemyHRP = character:FindFirstChild("HumanoidRootPart")

    if not enemyHRP then
        return
    end

    -- Bring enemy in front of LocalPlayer
    enemyHRP.CFrame =
        playerHRP.CFrame *
        CFrame.new(0, 0, -BringDistance)

    -- Prevent collision
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

--==================================================
-- BRING ALL ENEMIES
--==================================================

local function bringAllEnemies()
    if not BringEnabled then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local playerHRP = character:FindFirstChild("HumanoidRootPart")

    if not playerHRP then
        return
    end

    -- Find all Humanoids in Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then

            local enemyCharacter =
                getCharacterFromHumanoid(obj)

            if enemyCharacter then
                bringEnemy(
                    enemyCharacter,
                    playerHRP
                )
            end
        end
    end
end

--==================================================
-- LOOP
--==================================================

task.spawn(function()
    while true do

        if BringEnabled then
            bringAllEnemies()
        end

        task.wait(0.15)
    end
end)

--==================================================
-- OBISIDIAN UI
--==================================================

MainBox5:AddSlider("BringDistanceSlider", {
    Text = "Bring Distance",

    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,

    Callback = function(Value)
        BringDistance = Value
    end
})

MainBox5:AddToggle("BringEnemyToggle", {
    Text = "Bring Enemy",
    Default = false,

    Callback = function(Value)
        BringEnabled = Value
    end
})


local ESPBox = Tabs.Visual:AddLeftGroupbox("EnemyESP Features", "triangle-alert")
local ESPBox2 = Tabs.Visual:AddRightGroupbox("TeamESP Features", "user")
local ESPBox3 = Tabs.Visual:AddLeftGroupbox("VehicleEnemyESP Features", "rocket")
local ESPBox4 = Tabs.Visual:AddRightGroupbox("FPS Features", "flame")


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local ESPColor = Color3.fromRGB(85, 217, 255)

local ESPEnabled = false
local ESPObjects = {}
local ESPConnection

local ESPStyles = {
    ["Box ESP"] = true,
    ["Outline ESP"] = true,
    ["Top Tracer ESP"] = true,
    ["Chams ESP"] = true,
    ["Distance ESP"] = true,
    ["Name Text ESP"] = true,
}

--==================================================
-- TEAM CHECK
-- NO TOGGLE
--==================================================

local function IsValidEnemy(Player)

    if not Player or Player == LocalPlayer then
        return false
    end

    -- Player Team မရှိရင် SKIP
    if not Player.Team then
        return false
    end

    -- LocalPlayer Team မရှိရင် SKIP
    if not LocalPlayer.Team then
        return false
    end

    local TeamName = string.lower(Player.Team.Name)

    -- Lobby / Joining Team SKIP
    if TeamName == "lobby"
        or TeamName == "joining"
        or TeamName == "join"
        or TeamName == "neutral"
        or TeamName == "spectator"
        or TeamName == "spectators"
    then
        return false
    end

    -- LocalPlayer နဲ့ Team တူရင် SKIP
    if Player.Team == LocalPlayer.Team then
        return false
    end

    -- Team မတူတဲ့ valid Player = Enemy
    return true
end

--==================================================
-- VEHICLE CHECK
-- NO TOGGLE
--==================================================

local function IsVehiclePlayer(Character)

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return false
    end

    local Seat = Humanoid.SeatPart

    if not Seat then
        return false
    end

    return Seat:IsA("VehicleSeat")
        or Seat:IsA("Seat")
end

--==================================================
-- GET PLAYER
--==================================================

local function GetPlayerFromCharacter(Model)

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player")
            and Player.Character == Model
        then
            return Player
        end

    end

    return nil
end

--==================================================
-- DRAWING
--==================================================

local function NewDrawing(Type)

    local Object = Drawing.new(Type)

    Object.Visible = false

    return Object
end

--==================================================
-- REMOVE ESP
--==================================================

local function RemoveESP(Model)

    local Data = ESPObjects[Model]

    if not Data then
        return
    end

    if Data.Box then
        Data.Box:Remove()
    end

    if Data.Tracer then
        Data.Tracer:Remove()
    end

    if Data.Name then
        Data.Name:Remove()
    end

    if Data.Distance then
        Data.Distance:Remove()
    end

    if Data.Outline then
        Data.Outline:Destroy()
    end

    if Data.Chams then
        Data.Chams:Destroy()
    end

    ESPObjects[Model] = nil
end

--==================================================
-- CREATE ESP
--==================================================

local function CreateESP(Model)

    if not ESPEnabled then
        return
    end

    if ESPObjects[Model] then
        return
    end

    if not Model:IsA("Model") then
        return
    end

    local Humanoid =
        Model:FindFirstChildOfClass("Humanoid")

    local Root =
        Model:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root then
        return
    end

    local Player =
        GetPlayerFromCharacter(Model)

    if not Player then
        return
    end

    -- IMPORTANT TEAM CHECK
    if not IsValidEnemy(Player) then
        return
    end

    -- IMPORTANT VEHICLE CHECK
    if IsVehiclePlayer(Model) then
        return
    end

    local Data = {}

    --==================================================
    -- BOX
    --==================================================

    if ESPStyles["Box ESP"] then

        local Box = NewDrawing("Square")

        Box.Thickness = 1.5
        Box.Filled = false
        Box.Color = ESPColor

        Data.Box = Box
    end

    --==================================================
    -- TOP TRACER
    --==================================================

    if ESPStyles["Top Tracer ESP"] then

        local Tracer = NewDrawing("Line")

        Tracer.Thickness = 1.5
        Tracer.Color = ESPColor

        Data.Tracer = Tracer
    end

    --==================================================
    -- NAME
    --==================================================

    if ESPStyles["Name Text ESP"] then

        local Name = NewDrawing("Text")

        Name.Size = 9
        Name.Center = true
        Name.Outline = true
        Name.Font = 2
        Name.Color = ESPColor

        Data.Name = Name
    end

    --==================================================
    -- DISTANCE
    --==================================================

    if ESPStyles["Distance ESP"] then

        local Distance = NewDrawing("Text")

        Distance.Size = 9
        Distance.Center = true
        Distance.Outline = true
        Distance.Font = 2
        Distance.Color = ESPColor

        Data.Distance = Distance
    end

    --==================================================
    -- OUTLINE
    --==================================================

    if ESPStyles["Outline ESP"] then

        local Outline = Instance.new("Highlight")

        Outline.Name = "EnemyESP_Outline"
        Outline.Adornee = Model

        Outline.FillTransparency = 1
        Outline.OutlineTransparency = 0

        Outline.OutlineColor = ESPColor

        Outline.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Outline.Parent = Model

        Data.Outline = Outline
    end

    --==================================================
    -- CHAMS
    --==================================================

    if ESPStyles["Chams ESP"] then

        local Chams = Instance.new("Highlight")

        Chams.Name = "EnemyESP_Chams"
        Chams.Adornee = Model

        Chams.FillColor = ESPColor
        Chams.OutlineColor = ESPColor

        Chams.FillTransparency = 0.45
        Chams.OutlineTransparency = 0

        Chams.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Chams.Parent = Model

        Data.Chams = Chams
    end

    ESPObjects[Model] = Data
end

--==================================================
-- UPDATE
--==================================================

local function UpdateESP(Model, Data)

    if not Model.Parent then
        RemoveESP(Model)
        return
    end

    local Humanoid =
        Model:FindFirstChildOfClass("Humanoid")

    local Root =
        Model:FindFirstChild("HumanoidRootPart")

    local Player =
        GetPlayerFromCharacter(Model)

    if not Humanoid or not Root or not Player then
        RemoveESP(Model)
        return
    end

    if Humanoid.Health <= 0 then
        RemoveESP(Model)
        return
    end

    -- Re-check Team every frame
    if not IsValidEnemy(Player) then
        RemoveESP(Model)
        return
    end

    -- Re-check Vehicle every frame
    if IsVehiclePlayer(Model) then
        RemoveESP(Model)
        return
    end

    local RootScreen, OnScreen =
        Camera:WorldToViewportPoint(Root.Position)

    if not OnScreen then

        if Data.Box then
            Data.Box.Visible = false
        end

        if Data.Tracer then
            Data.Tracer.Visible = false
        end

        if Data.Name then
            Data.Name.Visible = false
        end

        if Data.Distance then
            Data.Distance.Visible = false
        end

        return
    end

    --==================================================
    -- BOUNDING
    --==================================================

    local CFrameValue, Size =
        Model:GetBoundingBox()

    local TopWorld =
        CFrameValue.Position
        + Vector3.new(0, Size.Y / 2, 0)

    local BottomWorld =
        CFrameValue.Position
        - Vector3.new(0, Size.Y / 2, 0)

    local Top =
        Camera:WorldToViewportPoint(TopWorld)

    local Bottom =
        Camera:WorldToViewportPoint(BottomWorld)

    local Height =
        math.abs(Top.Y - Bottom.Y)

    local Width =
        Height * 0.55

    --==================================================
    -- BOX
    --==================================================

    if Data.Box then

        Data.Box.Position = Vector2.new(
            RootScreen.X - Width / 2,
            Top.Y
        )

        Data.Box.Size =
            Vector2.new(Width, Height)

        Data.Box.Color = ESPColor
        Data.Box.Visible = true
    end

    --==================================================
    -- TOP TRACER
    --==================================================

    if Data.Tracer then

        local Viewport =
            Camera.ViewportSize

        Data.Tracer.From =
            Vector2.new(Viewport.X / 2, 0)

        Data.Tracer.To =
            Vector2.new(RootScreen.X, Top.Y)

        Data.Tracer.Color = ESPColor
        Data.Tracer.Visible = true
    end

    --==================================================
    -- NAME
    --==================================================

    if Data.Name then

        Data.Name.Text =
            Player.DisplayName

        Data.Name.Position =
            Vector2.new(
                RootScreen.X,
                Top.Y - 13
            )

        Data.Name.Size = 9
        Data.Name.Color = ESPColor
        Data.Name.Visible = true
    end

    --==================================================
    -- DISTANCE
    --==================================================

    if Data.Distance then

        local Distance =
            (Camera.CFrame.Position - Root.Position).Magnitude

        Data.Distance.Text =
            string.format("[%dm]", Distance)

        Data.Distance.Position =
            Vector2.new(
                RootScreen.X,
                Bottom.Y + 2
            )

        Data.Distance.Size = 9
        Data.Distance.Color = ESPColor
        Data.Distance.Visible = true
    end

    --==================================================
    -- OUTLINE
    --==================================================

    if Data.Outline then
        Data.Outline.OutlineColor = ESPColor
    end

    --==================================================
    -- CHAMS
    --==================================================

    if Data.Chams then
        Data.Chams.FillColor = ESPColor
        Data.Chams.OutlineColor = ESPColor
    end
end

--==================================================
-- SCAN PLAYERS
--==================================================

local function ScanPlayers()

    if not ESPEnabled then
        return
    end

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player") then

            local Character = Player.Character

            if Character
                and Character:IsA("Model")
                and Character:FindFirstChildOfClass("Humanoid")
            then
                CreateESP(Character)
            end

        end
    end
end

--==================================================
-- ESP ON / OFF
--==================================================

local function SetESP(State)

    ESPEnabled = State

    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end

    if not State then

        for Model in pairs(ESPObjects) do
            RemoveESP(Model)
        end

        return
    end

    ScanPlayers()

    ESPConnection =
        RunService.RenderStepped:Connect(function()

            ScanPlayers()

            for Model, Data in pairs(ESPObjects) do

                if Model.Parent then
                    UpdateESP(Model, Data)
                else
                    RemoveESP(Model)
                end

            end
        end)
end

--==================================================
-- PLAYER CHARACTER EVENTS
--==================================================

Players.PlayerAdded:Connect(function(Player)

    Player.CharacterAdded:Connect(function(Character)

        if ESPEnabled then
            task.wait()
            CreateESP(Character)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(Player)

    if Player.Character then
        RemoveESP(Player.Character)
    end
end)

--==================================================
-- OBSIDIAN UI
--==================================================

--==================================================
-- MULTI STYLE DROPDOWN
--==================================================

ESPBox:AddDropdown("ESPStyleDropdown", {

    Values = {
        "Box ESP",
        "Outline ESP",
        "Top Tracer ESP",
        "Chams ESP",
        "Distance ESP",
        "Name Text ESP",
    },

    Default = {
        "Box ESP",
        "Outline ESP",
        "Top Tracer ESP",
        "Chams ESP",
        "Distance ESP",
        "Name Text ESP",
    },

    Multi = true,

    Text = "ESP Style",

    Callback = function(Value)

        ESPStyles["Box ESP"] =
            Value["Box ESP"] == true

        ESPStyles["Outline ESP"] =
            Value["Outline ESP"] == true

        ESPStyles["Top Tracer ESP"] =
            Value["Top Tracer ESP"] == true

        ESPStyles["Chams ESP"] =
            Value["Chams ESP"] == true

        ESPStyles["Distance ESP"] =
            Value["Distance ESP"] == true

        ESPStyles["Name Text ESP"] =
            Value["Name Text ESP"] == true

        if ESPEnabled then

            SetESP(false)

            task.defer(function()
                SetESP(true)
            end)

        end
    end,
})

local ESPToggle = ESPBox:AddToggle("EnemyESPToggle", {

    Text = "Enemy ESP",

    Default = false,

    Callback = function(Value)

        SetESP(Value)

    end,
})

-- ONE TOGGLE + ONE COLOR PICKER
ESPToggle:AddColorPicker("EnemyESPColor", {

    Default = Color3.fromRGB(85, 217, 255),

    Title = "ESP Color",

    Transparency = 0,

    Callback = function(Value)

        ESPColor = Value

    end,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local ESPEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)

local VehicleCheck = true

local ESPConnection
local ESPObjects = {}

local ESPStyles = {
    ["Box ESP"] = true,
    ["Outline ESP"] = true,
    ["Top Tracer ESP"] = true,
    ["Chams ESP"] = true,
    ["Distance ESP"] = true,
    ["Name Text ESP"] = true,
}

--==================================================
-- TEAM CHECK
-- OWN TEAM ONLY
--==================================================

local function IsValidOwnTeamPlayer(Player)

    if not Player then
        return false
    end

    -- LocalPlayer ကိုယ်တိုင် မပြ
    if Player == LocalPlayer then
        return false
    end

    -- LocalPlayer Team မရှိရင် မပြ
    if not LocalPlayer.Team then
        return false
    end

    -- Player Team မရှိရင် မပြ
    if not Player.Team then
        return false
    end

    local TeamName = string.lower(Player.Team.Name)

    -- Lobby / Joining / Spectator / Neutral မပြ
    if TeamName == "lobby"
        or TeamName == "joining"
        or TeamName == "join"
        or TeamName == "neutral"
        or TeamName == "spectator"
        or TeamName == "spectators"
    then
        return false
    end

    -- ကိုယ့် Team တူမှ ESP
    if Player.Team ~= LocalPlayer.Team then
        return false
    end

    return true
end

--==================================================
-- VEHICLE CHECK
--==================================================

local function IsVehiclePlayer(Character)

    if not VehicleCheck then
        return false
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return false
    end

    local Seat = Humanoid.SeatPart

    if not Seat then
        return false
    end

    return Seat:IsA("VehicleSeat")
        or Seat:IsA("Seat")
end

--==================================================
-- CHARACTER VALID CHECK
--==================================================

local function IsCharacterReady(Character)

    if not Character then
        return false
    end

    -- Workspace ထဲ တကယ်ရောက်နေမှ
    if not Character:IsDescendantOf(workspace) then
        return false
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root then
        return false
    end

    if Humanoid.Health <= 0 then
        return false
    end

    return true
end

--==================================================
-- GET PLAYER FROM MODEL
--==================================================

local function GetPlayerFromCharacter(Model)

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player")
            and Player.Character == Model
        then
            return Player
        end

    end

    return nil
end

--==================================================
-- DRAWING
--==================================================

local function NewDrawing(Type)

    local Object = Drawing.new(Type)

    Object.Visible = false

    return Object
end

--==================================================
-- REMOVE ESP
--==================================================

local function RemoveESP(Model)

    local Data = ESPObjects[Model]

    if not Data then
        return
    end

    if Data.Box then
        Data.Box:Remove()
    end

    if Data.Tracer then
        Data.Tracer:Remove()
    end

    if Data.Name then
        Data.Name:Remove()
    end

    if Data.Distance then
        Data.Distance:Remove()
    end

    if Data.Outline then
        Data.Outline:Destroy()
    end

    if Data.Chams then
        Data.Chams:Destroy()
    end

    ESPObjects[Model] = nil
end

--==================================================
-- CREATE ESP
--==================================================

local function CreateESP(Model)

    if not ESPEnabled then
        return
    end

    if ESPObjects[Model] then
        return
    end

    -- Character ready check
    if not IsCharacterReady(Model) then
        return
    end

    local Player =
        GetPlayerFromCharacter(Model)

    if not Player then
        return
    end

    -- OWN TEAM ONLY
    if not IsValidOwnTeamPlayer(Player) then
        return
    end

    -- VEHICLE CHECK
    if IsVehiclePlayer(Model) then
        return
    end

    local Data = {}

    --==================================================
    -- BOX ESP
    --==================================================

    if ESPStyles["Box ESP"] then

        local Box = NewDrawing("Square")

        Box.Thickness = 1.5
        Box.Filled = false
        Box.Color = ESPColor

        Data.Box = Box
    end

    --==================================================
    -- TOP TRACER ESP
    --==================================================

    if ESPStyles["Top Tracer ESP"] then

        local Tracer = NewDrawing("Line")

        Tracer.Thickness = 1.5
        Tracer.Color = ESPColor

        Data.Tracer = Tracer
    end

    --==================================================
    -- NAME ESP
    --==================================================

    if ESPStyles["Name Text ESP"] then

        local Name = NewDrawing("Text")

        Name.Size = 9
        Name.Center = true
        Name.Outline = true
        Name.Font = 2
        Name.Color = ESPColor

        Data.Name = Name
    end

    --==================================================
    -- DISTANCE ESP
    --==================================================

    if ESPStyles["Distance ESP"] then

        local Distance = NewDrawing("Text")

        Distance.Size = 9
        Distance.Center = true
        Distance.Outline = true
        Distance.Font = 2
        Distance.Color = ESPColor

        Data.Distance = Distance
    end

    --==================================================
    -- OUTLINE ESP
    --==================================================

    if ESPStyles["Outline ESP"] then

        local Outline = Instance.new("Highlight")

        Outline.Name = "OwnTeamESP_Outline"
        Outline.Adornee = Model

        Outline.FillTransparency = 1
        Outline.OutlineTransparency = 0

        Outline.OutlineColor = ESPColor

        Outline.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Outline.Parent = Model

        Data.Outline = Outline
    end

    --==================================================
    -- CHAMS ESP
    --==================================================

    if ESPStyles["Chams ESP"] then

        local Chams = Instance.new("Highlight")

        Chams.Name = "OwnTeamESP_Chams"
        Chams.Adornee = Model

        Chams.FillColor = ESPColor
        Chams.OutlineColor = ESPColor

        Chams.FillTransparency = 0.45
        Chams.OutlineTransparency = 0

        Chams.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Chams.Parent = Model

        Data.Chams = Chams
    end

    ESPObjects[Model] = Data
end

--==================================================
-- UPDATE ESP
--==================================================

local function UpdateESP(Model, Data)

    if not IsCharacterReady(Model) then
        RemoveESP(Model)
        return
    end

    local Player =
        GetPlayerFromCharacter(Model)

    local Humanoid =
        Model:FindFirstChildOfClass("Humanoid")

    local Root =
        Model:FindFirstChild("HumanoidRootPart")

    if not Player or not Humanoid or not Root then
        RemoveESP(Model)
        return
    end

    -- Team ပြောင်းသွားရင် ချက်ချင်း Remove
    if not IsValidOwnTeamPlayer(Player) then
        RemoveESP(Model)
        return
    end

    -- Vehicle ထဲဝင်သွားရင် Remove
    if IsVehiclePlayer(Model) then
        RemoveESP(Model)
        return
    end

    local RootScreen, OnScreen =
        Camera:WorldToViewportPoint(Root.Position)

    if not OnScreen then

        if Data.Box then
            Data.Box.Visible = false
        end

        if Data.Tracer then
            Data.Tracer.Visible = false
        end

        if Data.Name then
            Data.Name.Visible = false
        end

        if Data.Distance then
            Data.Distance.Visible = false
        end

        return
    end

    --==================================================
    -- BOUNDING BOX
    --==================================================

    local BoundingCFrame, BoundingSize =
        Model:GetBoundingBox()

    local TopWorld =
        BoundingCFrame.Position
        + Vector3.new(0, BoundingSize.Y / 2, 0)

    local BottomWorld =
        BoundingCFrame.Position
        - Vector3.new(0, BoundingSize.Y / 2, 0)

    local Top =
        Camera:WorldToViewportPoint(TopWorld)

    local Bottom =
        Camera:WorldToViewportPoint(BottomWorld)

    local Height =
        math.abs(Top.Y - Bottom.Y)

    local Width =
        Height * 0.55

    --==================================================
    -- BOX
    --==================================================

    if Data.Box then

        Data.Box.Position =
            Vector2.new(
                RootScreen.X - Width / 2,
                Top.Y
            )

        Data.Box.Size =
            Vector2.new(
                Width,
                Height
            )

        Data.Box.Color = ESPColor
        Data.Box.Visible = true
    end

    --==================================================
    -- TOP TRACER
    --==================================================

    if Data.Tracer then

        local Viewport =
            Camera.ViewportSize

        Data.Tracer.From =
            Vector2.new(
                Viewport.X / 2,
                0
            )

        Data.Tracer.To =
            Vector2.new(
                RootScreen.X,
                Top.Y
            )

        Data.Tracer.Color = ESPColor
        Data.Tracer.Visible = true
    end

    --==================================================
    -- NAME
    --==================================================

    if Data.Name then

        Data.Name.Text =
            Player.DisplayName

        Data.Name.Position =
            Vector2.new(
                RootScreen.X,
                Top.Y - 13
            )

        Data.Name.Size = 9
        Data.Name.Color = ESPColor
        Data.Name.Visible = true
    end

    --==================================================
    -- DISTANCE
    --==================================================

    if Data.Distance then

        local Distance =
            (Camera.CFrame.Position - Root.Position).Magnitude

        Data.Distance.Text =
            string.format(
                "[%dm]",
                Distance
            )

        Data.Distance.Position =
            Vector2.new(
                RootScreen.X,
                Bottom.Y + 2
            )

        Data.Distance.Size = 9
        Data.Distance.Color = ESPColor
        Data.Distance.Visible = true
    end

    --==================================================
    -- OUTLINE
    --==================================================

    if Data.Outline then
        Data.Outline.OutlineColor = ESPColor
    end

    --==================================================
    -- CHAMS
    --==================================================

    if Data.Chams then

        Data.Chams.FillColor =
            ESPColor

        Data.Chams.OutlineColor =
            ESPColor
    end
end

--==================================================
-- SCAN ALL PLAYERS
--==================================================

local function ScanPlayers()

    if not ESPEnabled then
        return
    end

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player") then

            local Character =
                Player.Character

            if Character
                and Character:IsDescendantOf(workspace)
            then
                CreateESP(Character)
            end
        end
    end
end

--==================================================
-- ENABLE / DISABLE
--==================================================

local function SetESP(State)

    ESPEnabled = State

    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end

    if not State then

        for Model in pairs(ESPObjects) do
            RemoveESP(Model)
        end

        return
    end

    ScanPlayers()

    ESPConnection =
        RunService.RenderStepped:Connect(function()

            if not ESPEnabled then
                return
            end

            ScanPlayers()

            for Model, Data in pairs(ESPObjects) do

                if Model.Parent then
                    UpdateESP(Model, Data)
                else
                    RemoveESP(Model)
                end

            end
        end)
end

--==================================================
-- RESPAWN CHECK
--==================================================

local function SetupPlayer(Player)

    Player.CharacterAdded:Connect(function(Character)

        if not ESPEnabled then
            return
        end

        task.spawn(function()

            -- Workspace / Map ထဲဝင်တဲ့အထိစောင့်
            while ESPEnabled
                and Player.Parent
                and Character.Parent == nil
            do
                task.wait()
            end

            if not ESPEnabled then
                return
            end

            -- Workspace ထဲမဝင်သေးရင် မလုပ်
            if not Character:IsDescendantOf(workspace) then
                return
            end

            -- HumanoidRootPart ရောက်တဲ့အထိစောင့်
            local Root =
                Character:WaitForChild(
                    "HumanoidRootPart",
                    10
                )

            if not Root then
                return
            end

            -- Team / Vehicle / Lobby အားလုံးပြန်စစ်
            CreateESP(Character)

        end)
    end)
end

for _, Player in ipairs(Players:GetChildren()) do

    if Player:IsA("Player")
        and Player ~= LocalPlayer
    then
        SetupPlayer(Player)
    end
end

Players.PlayerAdded:Connect(function(Player)

    if Player ~= LocalPlayer then
        SetupPlayer(Player)
    end
end)

Players.PlayerRemoving:Connect(function(Player)

    if Player.Character then
        RemoveESP(Player.Character)
    end
end)

--==================================================
-- UI
--==================================================


ESPBox2:AddDropdown(
    "OwnTeamESPStyle",
    {
        Values = {
            "Box ESP",
            "Outline ESP",
            "Top Tracer ESP",
            "Chams ESP",
            "Distance ESP",
            "Name Text ESP",
        },

        Default = {
            "Box ESP",
            "Outline ESP",
            "Top Tracer ESP",
            "Chams ESP",
            "Distance ESP",
            "Name Text ESP",
        },

        Multi = true,

        Text = "ESP Style",

        Callback = function(Value)

            ESPStyles["Box ESP"] =
                Value["Box ESP"] == true

            ESPStyles["Outline ESP"] =
                Value["Outline ESP"] == true

            ESPStyles["Top Tracer ESP"] =
                Value["Top Tracer ESP"] == true

            ESPStyles["Chams ESP"] =
                Value["Chams ESP"] == true

            ESPStyles["Distance ESP"] =
                Value["Distance ESP"] == true

            ESPStyles["Name Text ESP"] =
                Value["Name Text ESP"] == true

            if ESPEnabled then

                SetESP(false)

                task.defer(function()
                    SetESP(true)
                end)

            end
        end,
    }
)

local ESPToggle = ESPBox2:AddToggle(
    "OwnTeamESPToggle",
    {
        Text = "Team ESP",

        Default = false,

        Callback = function(Value)

            SetESP(Value)

        end,
    }
)

--==================================================
-- ONE COLOR PICKER
--==================================================

ESPToggle:AddColorPicker(
    "OwnTeamESPColor",
    {
        Default =
            Color3.fromRGB(
                255,
                255,
                255
            ),

        Title = "ESP Color",

        Transparency = 0,

        Callback = function(Value)

            ESPColor = Value

        end,
    }
)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local ESPEnabled = false
local ESPColor = Color3.fromRGB(85, 217, 255)

local ESPObjects = {}
local ESPConnection

local ESPStyles = {
    ["Box ESP"] = true,
    ["Outline ESP"] = true,
    ["Top Tracer ESP"] = true,
    ["Chams ESP"] = true,
    ["Distance ESP"] = true,
    ["Name Text ESP"] = true,
}

--==================================================
-- ENEMY TEAM CHECK
--==================================================

local function IsEnemy(Player)

    if not Player or Player == LocalPlayer then
        return false
    end

    -- LocalPlayer Team မရှိ
    if not LocalPlayer.Team then
        return false
    end

    -- Enemy Player Team မရှိ
    if not Player.Team then
        return false
    end

    local TeamName =
        string.lower(Player.Team.Name)

    -- Lobby / Joining / Spectator မပြ
    if TeamName == "lobby"
        or TeamName == "joining"
        or TeamName == "join"
        or TeamName == "neutral"
        or TeamName == "spectator"
        or TeamName == "spectators"
    then
        return false
    end

    -- Enemy Team Only
    return Player.Team ~= LocalPlayer.Team
end

--==================================================
-- VEHICLE PLAYER ONLY
--==================================================

local function IsVehicleEnemy(Character)

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return false
    end

    -- SeatPart က player ထိုင်နေတဲ့ Seat ကိုပေးတယ်
    local Seat = Humanoid.SeatPart

    if not Seat then
        return false
    end

    -- VehicleSeat / Seat နှစ်မျိုးလုံး support
    if Seat:IsA("VehicleSeat")
        or Seat:IsA("Seat")
    then
        return true
    end

    return false
end

--==================================================
-- CHARACTER READY
--==================================================

local function IsCharacterReady(Character)

    if not Character then
        return false
    end

    -- Workspace ထဲ တကယ်ရောက်မှ
    if not Character:IsDescendantOf(workspace) then
        return false
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root then
        return false
    end

    if Humanoid.Health <= 0 then
        return false
    end

    return true
end

--==================================================
-- GET PLAYER
--==================================================

local function GetPlayerFromCharacter(Model)

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player")
            and Player.Character == Model
        then
            return Player
        end

    end

    return nil
end

--==================================================
-- DRAWING
--==================================================

local function NewDrawing(Type)

    local Object = Drawing.new(Type)

    Object.Visible = false

    return Object
end

--==================================================
-- REMOVE ESP
--==================================================

local function RemoveESP(Model)

    local Data = ESPObjects[Model]

    if not Data then
        return
    end

    if Data.Box then
        Data.Box:Remove()
    end

    if Data.Tracer then
        Data.Tracer:Remove()
    end

    if Data.Name then
        Data.Name:Remove()
    end

    if Data.Distance then
        Data.Distance:Remove()
    end

    if Data.Outline then
        Data.Outline:Destroy()
    end

    if Data.Chams then
        Data.Chams:Destroy()
    end

    ESPObjects[Model] = nil
end

--==================================================
-- CREATE ESP
--==================================================

local function CreateESP(Model)

    if not ESPEnabled then
        return
    end

    if ESPObjects[Model] then
        return
    end

    if not IsCharacterReady(Model) then
        return
    end

    local Player =
        GetPlayerFromCharacter(Model)

    if not Player then
        return
    end

    -- Enemy Team Only
    if not IsEnemy(Player) then
        return
    end

    -- IMPORTANT:
    -- Vehicle ထဲထိုင်နေသူပဲ ESP
    if not IsVehicleEnemy(Model) then
        return
    end

    local Data = {}

    --==================================================
    -- BOX ESP
    --==================================================

    if ESPStyles["Box ESP"] then

        local Box = NewDrawing("Square")

        Box.Thickness = 1.5
        Box.Filled = false
        Box.Color = ESPColor

        Data.Box = Box
    end

    --==================================================
    -- TOP TRACER ESP
    --==================================================

    if ESPStyles["Top Tracer ESP"] then

        local Tracer = NewDrawing("Line")

        Tracer.Thickness = 1.5
        Tracer.Color = ESPColor

        Data.Tracer = Tracer
    end

    --==================================================
    -- NAME ESP
    --==================================================

    if ESPStyles["Name Text ESP"] then

        local Name = NewDrawing("Text")

        Name.Size = 9
        Name.Center = true
        Name.Outline = true
        Name.Font = 2
        Name.Color = ESPColor

        Data.Name = Name
    end

    --==================================================
    -- DISTANCE ESP
    --==================================================

    if ESPStyles["Distance ESP"] then

        local Distance = NewDrawing("Text")

        Distance.Size = 9
        Distance.Center = true
        Distance.Outline = true
        Distance.Font = 2
        Distance.Color = ESPColor

        Data.Distance = Distance
    end

    --==================================================
    -- OUTLINE ESP
    --==================================================

    if ESPStyles["Outline ESP"] then

        local Outline = Instance.new("Highlight")

        Outline.Name = "EnemyVehicleESP_Outline"
        Outline.Adornee = Model

        Outline.FillTransparency = 1
        Outline.OutlineTransparency = 0

        Outline.OutlineColor = ESPColor

        Outline.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Outline.Parent = Model

        Data.Outline = Outline
    end

    --==================================================
    -- CHAMS ESP
    --==================================================

    if ESPStyles["Chams ESP"] then

        local Chams = Instance.new("Highlight")

        Chams.Name = "EnemyVehicleESP_Chams"
        Chams.Adornee = Model

        Chams.FillColor = ESPColor
        Chams.OutlineColor = ESPColor

        Chams.FillTransparency = 0.45
        Chams.OutlineTransparency = 0

        Chams.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Chams.Parent = Model

        Data.Chams = Chams
    end

    ESPObjects[Model] = Data
end

--==================================================
-- UPDATE ESP
--==================================================

local function UpdateESP(Model, Data)

    if not IsCharacterReady(Model) then
        RemoveESP(Model)
        return
    end

    local Player =
        GetPlayerFromCharacter(Model)

    local Humanoid =
        Model:FindFirstChildOfClass("Humanoid")

    local Root =
        Model:FindFirstChild("HumanoidRootPart")

    if not Player or not Humanoid or not Root then
        RemoveESP(Model)
        return
    end

    -- Enemy Team ပြန်စစ်
    if not IsEnemy(Player) then
        RemoveESP(Model)
        return
    end

    -- Vehicle မဟုတ်တော့ရင် ချက်ချင်း Remove
    if not IsVehicleEnemy(Model) then
        RemoveESP(Model)
        return
    end

    local RootScreen, OnScreen =
        Camera:WorldToViewportPoint(
            Root.Position
        )

    if not OnScreen then

        if Data.Box then
            Data.Box.Visible = false
        end

        if Data.Tracer then
            Data.Tracer.Visible = false
        end

        if Data.Name then
            Data.Name.Visible = false
        end

        if Data.Distance then
            Data.Distance.Visible = false
        end

        return
    end

    --==================================================
    -- BOUNDING BOX
    --==================================================

    local BoundingCFrame, BoundingSize =
        Model:GetBoundingBox()

    local TopWorld =
        BoundingCFrame.Position
        + Vector3.new(
            0,
            BoundingSize.Y / 2,
            0
        )

    local BottomWorld =
        BoundingCFrame.Position
        - Vector3.new(
            0,
            BoundingSize.Y / 2,
            0
        )

    local Top =
        Camera:WorldToViewportPoint(
            TopWorld
        )

    local Bottom =
        Camera:WorldToViewportPoint(
            BottomWorld
        )

    local Height =
        math.abs(
            Top.Y - Bottom.Y
        )

    local Width =
        Height * 0.55

    --==================================================
    -- BOX
    --==================================================

    if Data.Box then

        Data.Box.Position =
            Vector2.new(
                RootScreen.X - Width / 2,
                Top.Y
            )

        Data.Box.Size =
            Vector2.new(
                Width,
                Height
            )

        Data.Box.Color = ESPColor
        Data.Box.Visible = true
    end

    --==================================================
    -- TOP TRACER
    --==================================================

    if Data.Tracer then

        local Viewport =
            Camera.ViewportSize

        Data.Tracer.From =
            Vector2.new(
                Viewport.X / 2,
                0
            )

        Data.Tracer.To =
            Vector2.new(
                RootScreen.X,
                Top.Y
            )

        Data.Tracer.Color = ESPColor
        Data.Tracer.Visible = true
    end

    --==================================================
    -- NAME
    --==================================================

    if Data.Name then

        Data.Name.Text =
            Player.DisplayName

        Data.Name.Position =
            Vector2.new(
                RootScreen.X,
                Top.Y - 13
            )

        Data.Name.Size = 9
        Data.Name.Color = ESPColor
        Data.Name.Visible = true
    end

    --==================================================
    -- DISTANCE
    --==================================================

    if Data.Distance then

        local Distance =
            (
                Camera.CFrame.Position
                - Root.Position
            ).Magnitude

        Data.Distance.Text =
            string.format(
                "[%dm]",
                Distance
            )

        Data.Distance.Position =
            Vector2.new(
                RootScreen.X,
                Bottom.Y + 2
            )

        Data.Distance.Size = 9
        Data.Distance.Color = ESPColor
        Data.Distance.Visible = true
    end

    --==================================================
    -- OUTLINE
    --==================================================

    if Data.Outline then

        Data.Outline.OutlineColor =
            ESPColor

    end

    --==================================================
    -- CHAMS
    --==================================================

    if Data.Chams then

        Data.Chams.FillColor =
            ESPColor

        Data.Chams.OutlineColor =
            ESPColor

    end
end

--==================================================
-- SCAN PLAYERS
--==================================================

local function ScanPlayers()

    if not ESPEnabled then
        return
    end

    for _, Player in ipairs(Players:GetChildren()) do

        if Player:IsA("Player")
            and Player ~= LocalPlayer
        then

            local Character =
                Player.Character

            if Character
                and Character:IsDescendantOf(workspace)
            then
                CreateESP(Character)
            end

        end
    end
end

--==================================================
-- ESP ON / OFF
--==================================================

local function SetESP(State)

    ESPEnabled = State

    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end

    if not State then

        for Model in pairs(ESPObjects) do
            RemoveESP(Model)
        end

        return
    end

    ScanPlayers()

    ESPConnection =
        RunService.RenderStepped:Connect(
            function()

                if not ESPEnabled then
                    return
                end

                ScanPlayers()

                for Model, Data in pairs(ESPObjects) do

                    if Model.Parent then
                        UpdateESP(
                            Model,
                            Data
                        )
                    else
                        RemoveESP(Model)
                    end

                end
            end
        )
end

--==================================================
-- RESPAWN
--==================================================

local function SetupPlayer(Player)

    if Player == LocalPlayer then
        return
    end

    Player.CharacterAdded:Connect(
        function(Character)

            if not ESPEnabled then
                return
            end

            task.spawn(function()

                -- Workspace ထဲရောက်တဲ့အထိ စောင့်
                while ESPEnabled
                    and Player.Parent
                    and not Character:IsDescendantOf(workspace)
                do
                    task.wait()
                end

                if not ESPEnabled then
                    return
                end

                if not Character:IsDescendantOf(workspace) then
                    return
                end

                local Root =
                    Character:WaitForChild(
                        "HumanoidRootPart",
                        10
                    )

                if not Root then
                    return
                end

                -- Enemy + Vehicle check
                CreateESP(Character)

            end)
        end
    )
end

-- Existing Players
for _, Player in ipairs(Players:GetChildren()) do

    if Player:IsA("Player") then
        SetupPlayer(Player)
    end

end

-- New Players
Players.PlayerAdded:Connect(function(Player)

    SetupPlayer(Player)

end)

-- Remove Player
Players.PlayerRemoving:Connect(function(Player)

    if Player.Character then
        RemoveESP(Player.Character)
    end

end)

--==================================================
-- OBSIDIAN TOGGLE + COLOR
--==================================================

ESPBox3:AddDropdown(
    "EnemyVehicleESPStyle",
    {
        Values = {
            "Box ESP",
            "Outline ESP",
            "Top Tracer ESP",
            "Chams ESP",
            "Distance ESP",
            "Name Text ESP",
        },

        Default = {
            "Box ESP",
            "Outline ESP",
            "Top Tracer ESP",
            "Chams ESP",
            "Distance ESP",
            "Name Text ESP",
        },

        Multi = true,

        Text = "ESP Style",

        Callback = function(Value)

            ESPStyles["Box ESP"] =
                Value["Box ESP"] == true

            ESPStyles["Outline ESP"] =
                Value["Outline ESP"] == true

            ESPStyles["Top Tracer ESP"] =
                Value["Top Tracer ESP"] == true

            ESPStyles["Chams ESP"] =
                Value["Chams ESP"] == true

            ESPStyles["Distance ESP"] =
                Value["Distance ESP"] == true

            ESPStyles["Name Text ESP"] =
                Value["Name Text ESP"] == true

            -- Rebuild
            if ESPEnabled then

                SetESP(false)

                task.defer(function()
                    SetESP(true)
                end)

            end
        end,
    }
)

local ESPToggle = ESPBox3:AddToggle(
    "EnemyVehicleESPToggle",
    {
        Text = "Enemy Vehicle ESP",

        Default = false,

        Callback = function(Value)

            SetESP(Value)

        end,
    }
)

ESPToggle:AddColorPicker(
    "EnemyVehicleESPColor",
    {
        Default =
            Color3.fromRGB(
                85,
                217,
                255
            ),

        Title = "ESP Color",

        Transparency = 0,

        Callback = function(Value)

            ESPColor = Value

        end,
    }
)

local Lighting = game:GetService("Lighting")

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local FullbrightEnabled = false

local function SetFullbright(enabled)
    FullbrightEnabled = enabled

    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
end

ESPBox4:AddToggle("FullbrightToggle", {
    Text = "Fullbright",
    Default = false,

    Callback = function(Value)
        SetFullbright(Value)
    end
})

--==================================================
-- FPS BOOSTER • LOW POTATO DEVICE
-- Toggle ON / OFF
--==================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local FPSBoosterEnabled = false
local SavedProperties = {}

--==================================================
-- SAVE PROPERTY
--==================================================

local function SaveProperty(Object, Property)
    if not SavedProperties[Object] then
        SavedProperties[Object] = {}
    end

    if SavedProperties[Object][Property] == nil then
        local Success, Value = pcall(function()
            return Object[Property]
        end)

        if Success then
            SavedProperties[Object][Property] = Value
        end
    end
end

local function SetProperty(Object, Property, Value)
    SaveProperty(Object, Property)

    pcall(function()
        Object[Property] = Value
    end)
end

--==================================================
-- DISABLE OBJECT EFFECTS
--==================================================

local function OptimizeObject(Object)
    -- Shadows
    if Object:IsA("BasePart") then
        SetProperty(Object, "CastShadow", false)
    end

    -- Particle / Visual Effects
    if Object:IsA("ParticleEmitter")
    or Object:IsA("Trail")
    or Object:IsA("Beam")
    or Object:IsA("Smoke")
    or Object:IsA("Fire")
    or Object:IsA("Sparkles") then

        SetProperty(Object, "Enabled", false)
    end

    -- Lights
    if Object:IsA("PointLight")
    or Object:IsA("SpotLight")
    or Object:IsA("SurfaceLight") then

        SetProperty(Object, "Enabled", false)
    end

    -- Post Processing
    if Object:IsA("BloomEffect")
    or Object:IsA("BlurEffect")
    or Object:IsA("ColorCorrectionEffect")
    or Object:IsA("DepthOfFieldEffect")
    or Object:IsA("SunRaysEffect") then

        SetProperty(Object, "Enabled", false)
    end

    -- Atmosphere
    if Object:IsA("Atmosphere") then
        SetProperty(Object, "Density", 0)
        SetProperty(Object, "Haze", 0)
        SetProperty(Object, "Glare", 0)
    end
end

--==================================================
-- LIGHTING OPTIMIZATION
--==================================================

local function OptimizeLighting()
    SetProperty(Lighting, "GlobalShadows", false)
    SetProperty(Lighting, "Technology", Enum.Technology.Compatibility)

    for _, Object in ipairs(Lighting:GetChildren()) do
        OptimizeObject(Object)
    end
end

--==================================================
-- WATER OPTIMIZATION
--==================================================

local function OptimizeWater(Object)
    if Object:IsA("Terrain") then
        SetProperty(Object, "WaterWaveSize", 0)
        SetProperty(Object, "WaterWaveSpeed", 0)
        SetProperty(Object, "WaterReflectance", 0)
        SetProperty(Object, "WaterTransparency", 1)
    end
end

--==================================================
-- APPLY FPS BOOST
--==================================================

local function EnableFPSBooster()
    -- Lighting
    OptimizeLighting()

    -- Workspace
    for _, Object in ipairs(Workspace:GetDescendants()) do
        OptimizeObject(Object)

        if Object:IsA("Terrain") then
            OptimizeWater(Object)
        end
    end

    -- New objects
    Workspace.DescendantAdded:Connect(function(Object)
        if FPSBoosterEnabled then
            task.defer(function()
                OptimizeObject(Object)

                if Object:IsA("Terrain") then
                    OptimizeWater(Object)
                end
            end)
        end
    end)
end

--==================================================
-- RESTORE
--==================================================

local function DisableFPSBooster()
    for Object, Properties in pairs(SavedProperties) do
        if Object and Object.Parent then
            for Property, Value in pairs(Properties) do
                pcall(function()
                    Object[Property] = Value
                end)
            end
        end
    end

    SavedProperties = {}
end

--==================================================
-- MAIN TOGGLE FUNCTION
--==================================================

local function SetFPSBooster(Value)
    FPSBoosterEnabled = Value

    if Value then
        EnableFPSBooster()
    else
        DisableFPSBooster()
    end
end

--==================================================
-- OBSIDIAN UI
--==================================================

ESPBox4:AddToggle("FPSBoosterToggle", {
    Text = "FPS Booster",
    Default = false,

    Callback = function(Value)
        SetFPSBooster(Value)
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local CrosshairEnabled = true
local CrosshairSize = 35

local RotationSpeed = 120
local RainbowSpeed = 0.4

--==================================================
-- REMOVE OLD
--==================================================

local OldGui = PlayerGui:FindFirstChild("CustomCrosshair")
if OldGui then
    OldGui:Destroy()
end

--==================================================
-- SCREEN GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "CustomCrosshair"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

--==================================================
-- CROSSHAIR
--==================================================

local Crosshair = Instance.new("ImageLabel")
Crosshair.Name = "Crosshair"
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Position = UDim2.fromScale(0.5, 0.5)

Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxassetid://11763278596"
Crosshair.ImageTransparency = 0
Crosshair.ScaleType = Enum.ScaleType.Fit

Crosshair.Size = UDim2.fromOffset(
    CrosshairSize,
    CrosshairSize
)

Crosshair.Parent = Gui

--==================================================
-- TOGGLE FUNCTION
--==================================================

local function SetCrosshair(state)
    CrosshairEnabled = state
    Crosshair.Visible = state
end

local function ToggleCrosshair()
    SetCrosshair(not CrosshairEnabled)
end

--==================================================
-- SIZE FUNCTION
--==================================================

local function SetCrosshairSize(size)
    CrosshairSize = math.clamp(size, 10, 100)

    Crosshair.Size = UDim2.fromOffset(
        CrosshairSize,
        CrosshairSize
    )
end

--==================================================
-- ANIMATION
--==================================================

local Rotation = 0
local Hue = 0

RunService.RenderStepped:Connect(function(dt)

    if not CrosshairEnabled then
        return
    end

    -- Rotation
    Rotation = (Rotation + RotationSpeed * dt) % 360
    Crosshair.Rotation = Rotation

    -- Rainbow
    Hue = (Hue + RainbowSpeed * dt) % 1
    Crosshair.ImageColor3 = Color3.fromHSV(
        Hue,
        1,
        1
    )
end)

ESPBox4:AddSlider("CrosshairSizeSlider", {
    Text = "Crosshair Size",
    Default = 35,
    Min = 10,
    Max = 100,
    Rounding = 0,

    Callback = function(Value)
        SetCrosshairSize(Value)
    end
})

ESPBox4:AddToggle("CrosshairToggle", {
    Text = "Custom Crosshair",
    Default = true,

    Callback = function(Value)
        SetCrosshair(Value)
    end
})

local MiscBox = Tabs.Misc:AddLeftGroupbox("Misc Features", "wrench")

--// Anti AFK
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local AntiAFKEnabled = false
local AntiAFKConnection

local function StartAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end

    AntiAFKConnection = LocalPlayer.Idled:Connect(function()
        if not AntiAFKEnabled then
            return
        end

        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function StopAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

MiscBox:AddToggle("AntiAFKToggle", {
    Text = "Anti AFK",
    Default = false,

    Callback = function(Value)
        AntiAFKEnabled = Value

        if Value then
            StartAntiAFK()
        else
            StopAntiAFK()
        end
    end
})

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

MiscBox:AddButton({
    Text = "Rejoin Server",
    Func = function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            LocalPlayer
        )
    end
})

--// Auto Rejoin Server - Instant
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local AutoRejoinEnabled = false

MiscBox:AddToggle("AutoRejoinToggle", {
    Text = "Auto Rejoin Server",
    Default = false,

    Callback = function(Value)
        AutoRejoinEnabled = Value
    end
})

LocalPlayer.OnTeleport:Connect(function(State)
    if not AutoRejoinEnabled then
        return
    end

    if State == Enum.TeleportState.Failed then
        task.wait(0.1)

        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                LocalPlayer
            )
        end)
    end
end)

--// Server Hop
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function ServerHop()
    local PlaceId = game.PlaceId
    local CurrentJobId = game.JobId

    local success, result = pcall(function()
        return game:HttpGet(
            "https://games.roblox.com/v1/games/" ..
            PlaceId ..
            "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)

    if not success then
        return
    end

    local data = HttpService:JSONDecode(result)

    for _, server in ipairs(data.data or {}) do
        if server.id ~= CurrentJobId
            and server.playing < server.maxPlayers then

            TeleportService:TeleportToPlaceInstance(
                PlaceId,
                server.id,
                LocalPlayer
            )

            break
        end
    end
end

MiscBox:AddButton({
    Text = "Server Hop",
    Func = function()
        ServerHop()
    end
})

--------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------

local SettingsBox = Tabs.Settings:AddLeftGroupbox("UI Settings", "setting")


SettingsBox:AddToggle("CustomCursor", {

    Text = "Custom Cursor",

    Default = Library.ShowCustomCursor,

    Callback = function(Value)

        Library.ShowCustomCursor = Value

    end,
})


SettingsBox:AddDropdown("NotifySide", {

    Values = {
        "Left",
        "Right"
    },

    Default = "Right",

    Text = "Notification Side",

    Callback = function(Value)

        Library:SetNotifySide(Value)

    end,
})


SettingsBox:AddButton({

    Text = "Unload Menu",

    Func = function()

        Library:Unload()

    end,

})

SettingsBox:AddLabel("Menu Keybind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu Keybind",
    })


--------------------------------------------------
-- CONFIG + THEME
--------------------------------------------------

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({
    "MenuKeybind"
})


ThemeManager:SetFolder("InoC3nt8Hub")
SaveManager:SetFolder("InoC3nt8Hub")


SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:ApplyToTab(Tabs.Settings)


--------------------------------------------------
-- MENU KEY
--------------------------------------------------

Library.ToggleKeybind = Options.MenuKeybind 