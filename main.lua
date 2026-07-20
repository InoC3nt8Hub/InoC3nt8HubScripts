local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/library', true))()
local tab = library:CreateWindow('Reign Fall Script')
local combat = tab:AddFolder('Main')
                                    
Main:AddToggle({
    text = 'Infinite Ammo',
    flag = 'toggle',
    callback = function(v)
        if v then
            local function unlimitedAmmoLoop()
    while true do
        pcall(function()
            local Character = game:GetService("Players").LocalPlayer.Character
            if Character then
                for _, weapon in ipairs({"primary", "secondary"}) do
                    if Character:FindFirstChild(weapon) then
                        firesignal(
                            Character[weapon].ClientEvents.SetLocalAmmo.OnClientEvent,
                            Character[weapon],
                            9999,
                            true
                        )
                    end
                end
            end
        end)
        wait(0.5) -- Adjust timing as needed
    end
end

unlimitedAmmoLoop()

                
Main:AddLabel({
    text = 'Dev By InoC3nt8Hub',
    type = 'label'
})

library:Close()
library:Init()