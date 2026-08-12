-- FPS Booster Auto Function
local function FPSBooster()

    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    pcall(function()

        -- Graphics Optimization
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

        Lighting.GlobalShadows = false
        Lighting.FogEnd = math.huge
        Lighting.Brightness = 1

        -- Disable Lighting Effects
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end

        -- Terrain Optimization
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        -- Remove Heavy Effects
        for _,v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter")
                or v:IsA("Trail")
                or v:IsA("Smoke")
                or v:IsA("Fire")
                or v:IsA("Sparkles") then

                    v.Enabled = false
                end

                if v:IsA("BasePart") then
                    v.CastShadow = false
                end
            end)
        end

        -- Texture / Rendering Optimization
        game:GetService("RunService"):Set3dRenderingEnabled(true)

    end)
end

-- Auto Execute
FPSBooster()