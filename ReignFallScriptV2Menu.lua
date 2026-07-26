local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/library', true))()
local tab = library:CreateWindow('InoC3nt8 Hub')
local folder = tab:AddFolder('Reign Fall ScriptV2')

folder:AddToggle({
    text = 'infinite ammo',
    flag = 'toggle',
    callback = function(value)
        local ammoLoop
        
        if value then
            -- TOGGLE ON
            ammoLoop = game:GetService("RunService").RenderStepped:Connect(function()
                pcall(function()
                    local Character = game:GetService("Players").LocalPlayer.Character
                    if Character then
                        for _, weapon in ipairs({"primary", "secondary"}) do
                            if Character:FindFirstChild(weapon) then
                                firesignal(
                                    Character[weapon].ClientEvents.SetLocalAmmo.OnClientEvent,
                                    Character[weapon],
                                    math.huge,
                                    false
                                )
                            end
                        end
                    end
                end)
            end)
            
            -- Store connection for later use
            _G.ammoConnection = ammoLoop
        else
            -- TOGGLE OFF
            if _G.ammoConnection then
                _G.ammoConnection:Disconnect()
                _G.ammoConnection = nil
            end
        end
    end
})

folder:AddToggle({
    text = 'Aimbot Fov',
    flag = 'toggle',
    callback = function(state)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        local LocalPlayer = Players.LocalPlayer

        -- Settings
        local FOVRadius = 80
        local Smooth = 0.15

        -- Create FOV Circle
        local Circle = Drawing.new("Circle")
        Circle.Visible = state -- Toggle visibility
        Circle.Color = Color3.fromRGB(255, 255, 255)
        Circle.Thickness = 2
        Circle.NumSides = 100
        Circle.Filled = false
        Circle.Radius = FOVRadius

        -- Mobile center position
        local function GetScreenCenter()
            local Viewport = Camera.ViewportSize
            return Vector2.new(
                Viewport.X / 2,
                Viewport.Y / 2
            )
        end

        -- Smooth update
        local RenderConnection
        RenderConnection = RunService.RenderStepped:Connect(function()
            if not state then
                RenderConnection:Disconnect()
                Circle:Remove()
                return
            end

            local TargetPos = GetScreenCenter()

            Circle.Position = Circle.Position:Lerp(
                TargetPos,
                Smooth
            )

            Circle.Radius = FOVRadius
        end)

        -- NPC Alive Check
        local function GetAliveNPCs()
            local AliveNPCs = {}
            local Folder = workspace.Game.Current.Spawned.NPCs.enemies

            for _, NPC in ipairs(Folder:GetChildren()) do
                if NPC:IsA("Model") then
                    local Humanoid = NPC:FindFirstChildOfClass("Humanoid")
                    if Humanoid and Humanoid.Health > 0 then
                        table.insert(AliveNPCs, NPC)
                    end
                end
            end

            return AliveNPCs
        end

        -- Count alive NPCs
        local CountConnection
        CountConnection = task.spawn(function()
            while state and task.wait(1) do
                local Alive = GetAliveNPCs()
                print("Alive NPC:", #Alive)
            end
        end)

        -- Slider Function
        function SetFOVSize(Value)
            FOVRadius = math.clamp(Value, 50, 300)
        end
    end
})

folder:AddToggle({
    text = 'PlayerESP',
    flag = 'toggle',
    callback = function(state)
        local Players = game:GetService("Players")
        local espEnabled = state

        local function AddChams(player)
            if player.Character then
                local char = player.Character
                
                -- Remove existing highlight
                local existingHighlight = char:FindFirstChild("GreenChams")
                if existingHighlight then
                    existingHighlight:Destroy()
                end

                if espEnabled then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "GreenChams"
                    highlight.Parent = char

                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)

                    highlight.FillTransparency = 0
                    highlight.OutlineTransparency = 0
                end
            end
        end

        local function SetupPlayer(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                AddChams(player)
            end)

            if player.Character then
                AddChams(player)
            end
        end

        -- Apply to existing players
        for _, player in ipairs(Players:GetPlayers()) do
            SetupPlayer(player)
        end

        -- Apply to new players
        Players.PlayerAdded:Connect(SetupPlayer)
    end
})

folder:AddToggle({
    text = 'ObjectiveESP',
    flag = 'toggle',
    callback = function(state)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local folder = workspace.Game.Current.Spawned.GameObjects

        local allowed = {
            objective_radio = true,
            objective_card_reader = true,
            objective_fusebox = true,
            mission_item = true,
            objective_c4 = true
        }

        local function getPart(obj)
            if obj:IsA("BasePart") then
                return obj
            end

            if obj:IsA("Model") then
                return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
        end

        local function createESP(obj)
            local part = getPart(obj)
            if not part then return end

            if obj:FindFirstChild("ObjectiveESP") then return end

            -- White ESP
            local highlight = Instance.new("Highlight")
            highlight.Name = "ObjectiveESP"
            highlight.Adornee = obj
            highlight.FillColor = Color3.fromRGB(255,255,255)
            highlight.OutlineColor = Color3.fromRGB(255,255,255)
            highlight.FillTransparency = 0
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = obj

            -- Distance line
            local attachment0 = Instance.new("Attachment")
            attachment0.Parent = player.Character:WaitForChild("HumanoidRootPart")

            local attachment1 = Instance.new("Attachment")
            attachment1.Parent = part

            local beam = Instance.new("Beam")
            beam.Name = "ObjectiveLine"
            beam.Attachment0 = attachment0
            beam.Attachment1 = attachment1
            beam.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
            beam.Width0 = 0.05
            beam.Width1 = 0.05
            beam.FaceCamera = true
            beam.Parent = part
        end

        local function removeESP(obj)
            local highlight = obj:FindFirstChild("ObjectiveESP")
            if highlight then
                highlight:Destroy()
            end

            -- Remove beam and attachments
            local beam = obj:FindFirstChild("ObjectiveLine")
            if beam then
                if beam.Attachment0 then beam.Attachment0:Destroy() end
                if beam.Attachment1 then beam.Attachment1:Destroy() end
                beam:Destroy()
            end
        end

        local function scan()
            for _, obj in ipairs(folder:GetChildren()) do
                if allowed[obj.Name] then
                    if state then
                        createESP(obj)
                    else
                        removeESP(obj)
                    end
                end
            end
        end

        if state then
            scan()

            folder.ChildAdded:Connect(function(obj)
                task.wait(0.2)
                if allowed[obj.Name] and state then
                    createESP(obj)
                end
            end)
        else
            scan()
        end
    end
})

local espEnabled = false
local espConnection = nil
local espLoop = nil

folder:AddToggle({
    text = 'ZombiesESP',
    flag = 'toggle',
    callback = function()
        espEnabled = not espEnabled
        
        if espEnabled then
            startESP()
        else
            stopESP()
        end
    end
})

function startESP()
    local Workspace = game:GetService("Workspace")
    local enemiesFolder = Workspace.Game.Current.Spawned.NPCs.enemies

    local function isAlive(model)
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health > 0
        end
        return false
    end

    local function addChams(model)
        if not model:IsA("Model") then return end
        if not isAlive(model) then return end

        local old = model:FindFirstChild("EnemyChams")
        if old then
            old:Destroy()
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "EnemyChams"
        highlight.Parent = model

        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0
        highlight.OutlineTransparency = 0
    end

    local function scanEnemies()
        for _, npc in ipairs(enemiesFolder:GetChildren()) do
            addChams(npc)
        end
    end

    -- Initial scan
    scanEnemies()

    -- Auto update
    if espConnection then
        espConnection:Disconnect()
    end
    
    espConnection = enemiesFolder.ChildAdded:Connect(function(npc)
        if espEnabled then
            task.wait(0.2)
            addChams(npc)
        end
    end)

    -- Remove highlight when NPC dies
    if espLoop then
        task.cancel(espLoop)
    end
    
    espLoop = task.spawn(function()
        while espEnabled do
            task.wait(0.5)
            
            for _, npc in ipairs(enemiesFolder:GetChildren()) do
                if npc:IsA("Model") then
                    if isAlive(npc) then
                        addChams(npc)
                    else
                        local esp = npc:FindFirstChild("EnemyChams")
                        if esp then
                            esp:Destroy()
                        end
                    end
                end
            end
        end
    end)
end

function stopESP()
    espEnabled = false
    
    -- Disconnect ChildAdded event
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    -- Cancel the loop
    if espLoop then
        task.cancel(espLoop)
        espLoop = nil
    end

    -- Remove all highlights
    pcall(function()
        local Workspace = game:GetService("Workspace")
        local enemiesFolder = Workspace.Game.Current.Spawned.NPCs.enemies
        
        for _, npc in ipairs(enemiesFolder:GetChildren()) do
            local esp = npc:FindFirstChild("EnemyChams")
            if esp then
                esp:Destroy()
            end
        end
    end)
end


folder:AddLabel({
    text = 'by a InoC3nt8Hub',
    type = 'label'
})

library:Init()