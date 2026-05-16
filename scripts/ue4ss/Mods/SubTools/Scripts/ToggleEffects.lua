local UEHelpers = require("UEHelpers")

local bEffectsDisabled = false

RegisterKeyBind(Key.E, {ModifierKey.ALT}, function()
    local PC = FindFirstOf("PlayerController")
    if not PC or not PC:IsValid() then return end
    
    local World = PC:GetWorld()
    local KismetSystemLibrary = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")

    if KismetSystemLibrary and KismetSystemLibrary:IsValid() then
        bEffectsDisabled = not bEffectsDisabled
        
        local State = bEffectsDisabled and "0" or "1"
        local ShadowState = bEffectsDisabled and "0" or "5"
        
        -- Passing 'nil' as the 3rd parameter satisfies UE4SS while forcing global execution
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Water.WaterMesh.Enabled " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Water.SingleLayer.Disable " .. (bEffectsDisabled and "1" or "0"), nil)
        
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Fog " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.VolumetricFog " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Atmosphere " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.ShadowQuality " .. ShadowState, nil) -- looks like this is only cvar allowed
        
        print(bEffectsDisabled and "[EffectToggle] CVar Effects DISABLED" or "[EffectToggle] CVar Effects RESTORED")
    end
end)
