local UEHelpers = require("UEHelpers")

local bHide = false

function fixBloom()
    cam = FindFirstOf("PostProcessVolume")
    if cam and cam:IsValid() then
        -- The struct holding these variables is usually "PostProcessSettings" on cameras, 
        -- or just "Settings" on a PostProcessVolume. We'll check which one exists.
        local pp = cam.PostProcessSettings or cam.Settings
        
        if pp then
            -- 1. Replace r.BloomQuality 0 (Disable Bloom completely)
            pp.bOverride_BloomIntensity = true
            pp.BloomIntensity = 0.0
            
            -- 2. Replace r.TonemapperGamma 10 (Boost Global Gamma)
            -- Gamma is stored as an FVector4 (R, G, B, Alpha)
            pp.bOverride_ColorGamma = true
            local t = 10.0
            pp.ColorGamma = {X = t, Y = t, Z = t, W = 1.0}
            
            print("Post process overrides applied to: " .. cam:GetFullName())
        end
    end
end

function setNoon()
    -- 1. Set time to noon (0.5) and freeze it
    local timeComponent = FindFirstOf("UWETimeOfDayComponent")
    if timeComponent and timeComponent:IsValid() then
        timeComponent:SetTimeOfDay(0.5)
        timeComponent:FreezeTime(true)
    end
    
    -- 2. Change the sun's light intensity
    local sky = FindFirstOf("BP_UWESky_C")
    if sky and sky:IsValid() and sky.SunDirectionalLight then
        -- Change 25.0 to whatever intensity you prefer
        sky.SunDirectionalLight:SetIntensity(100.0)

        sky.SunDirectionalLight.DynamicShadowDistanceMovableLight = 0.0
    end

    local cam = FindFirstOf("CameraComponent")
    
    -- If no camera, try a global PostProcessVolume
    if not cam or not cam:IsValid() then
        cam = FindFirstOf("PostProcessVolume")
    end
end

function toggleObjects()
    FindFirstOf("WaterBodyOceanComponent").SetHiddenInGame(bHide, true)
    FindFirstOf("ExponentialHeightFogComponent").SetHiddenInGame(bHide, true)
    -- FindFirstOf("DirectionalLightComponent").SetCastShadows(not bHide) -- disables light, breaks capture
    --FindFirstOf("DirectionalLightComponent").SetIntensity(bHide and 25.0 or 1.0)
    -- o = FindFirstOf("DirectionalLightComponent")
    --print(o:GetFullName())
    --local rot = {Pitch = -45.0, Yaw = 90.0, Roll = 0.0}
    --o:K2_SetRelativeRotation(rot, false, {}, true)
    setNoon()
end


function toggleObjectszz()
    local names = {
        'WaterBodyOceanComponent',
        'ExponentialHeightFogComponent',
    }

    for _, name in ipairs(names) do
        local c = FindFirstOf(name)
        if c:IsValid() then
            c.SetHiddenInGame(bHide, true)
        end
    end
end


function toggleObjects11()

    local ComponentClasses = {
        "WaterBodyOceanComponent",
        --"WaterBodyComponent",
        --"WaterBodyMeshComponent",
        --"WaterBodyInfoMeshComponent",
        --"WaterBodyStaticMeshComponent"
    }

    for _, ClassName in ipairs(ComponentClasses) do
        local Comps = FindAllOf(ClassName) or {}
        for _, Comp in ipairs(Comps) do
            if Comp and Comp:IsValid() and Comp.SetVisibility then

                print('toggiling', Comp:GetFullName())

                Comp:SetVisibility(not bHide, true)
                Comp:SetHiddenInGame(bHide, true)

            end
        end
    end


end


function toggleObjects22()
    local ActorClasses = {
        "BP_Ocean_C", 
        "UWEWaterBodyOcean",
        "WaterBodyOcean",
        "WaterBody",
        "WaterMeshActor",
        "WaterBodyLake",
        "WaterBodyRiver",
        "WaterBodyCustom"
    }

    for _, ClassName in ipairs(ActorClasses) do
        local Actors = FindAllOf(ClassName) or {}
        for _, Actor in ipairs(Actors) do
            if Actor and Actor:IsValid() and Actor.K2_GetActorLocation then

                local Loc = Actor:K2_GetActorLocation()
                local Scale = Actor:GetActorScale3D()

                deltaZ = 0
                if bHide then
                    deltaZ = -5000000
                end

                --print('deltaZ', deltaZ, Actor:GetFullName())
                
                --Actor:K2_SetActorLocation({X = Loc.X, Y = Loc.Y, Z = Loc.Z + deltaZ}, false, {}, true)

                print('toggiling', bHide, Actor:GetFullName())

                Actor.bHidden = bHide

                -- Actor:SetVisibility(not bHide)

                -- Actor:SetHiddenInGame(bHide, true)

            end
        end
    end
end


function toggleConsole()
    local PC = UEHelpers.GetPlayerController()

    if not PC or not PC:IsValid() then return end
    
    local World = PC:GetWorld()
    local KismetSystemLibrary = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")

    if KismetSystemLibrary and KismetSystemLibrary:IsValid() then
        bHide = not bHide
        
        local State = bHide and "0" or "1"
        local ShadowState = bHide and "0" or "5"
        
        -- Passing 'nil' as the 3rd parameter satisfies UE4SS while forcing global execution
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Water.WaterMesh.Enabled " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Water.SingleLayer.Disable " .. (bHide and "1" or "0"), nil)
        
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Fog " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.VolumetricFog " .. State, nil)
        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.Atmosphere " .. State, nil)

        KismetSystemLibrary:ExecuteConsoleCommand(World, "r.ShadowQuality " .. ShadowState, nil) -- looks like this is only cvar allowed
        
        print(bHide and "[EffectToggle] CVar Effects DISABLED" or "[EffectToggle] CVar Effects RESTORED")
    end
end


function toggleEffects()
    bHide = not bHide
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            toggleObjects()
        end)
    end)
end

RegisterKeyBind(Key.R, {ModifierKey.ALT}, toggleEffects)
