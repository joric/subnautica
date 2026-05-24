local UEHelpers = require("UEHelpers")

local chunkSize = 12800 -- do not change

local tileSize = 2048
local savePath = "C:\\Temp\\Capture\\"
local delay = 3000
local forceOverwrite = true

local locations = {
    lifepod = { left = -337193, top = 433406, alt = 1000, size = chunkSize*2 },
    planetary = { left = -222771, top = 432320, alt = 500, size = chunkSize * 2 },
    turbine = { left = -160717, top = 436872, alt = 500, size = chunkSize * 2 },
    the_pit = { left = -344231.96875, top = 449815.84375, alt = 1000, size = chunkSize },
    glyph = { left = -232185.984375, top = 431499.40625, alt = 500, size = chunkSize*4 },
    all = { left = -222771, top = 432320, alt = 1000, size = 25600*11 }
}

local cc = locations.lifepod

local function fileExists(p)
    local f = io.open(p, "r")
    if f then f:close() return true end
end

local function setScene(bHide)
    local names = {
        'WaterBodyOceanComponent',
        'ExponentialHeightFogComponent',
    }

    for _, name in ipairs(names) do
        local o = FindFirstOf(name)
        if o and o:IsValid() and o.SetHiddenInGame then
            o.SetHiddenInGame(bHide, true)
        end
    end

    local timeComponent = FindFirstOf("UWETimeOfDayComponent")
    if timeComponent and timeComponent:IsValid() then
        timeComponent:SetTimeOfDay(0.5)
        --timeComponent:FreezeTime(bHide)
    end
    
    local sky = FindFirstOf("BP_UWESky_C")
    if sky and sky:IsValid() and sky.SunDirectionalLight then
        local light = sky.SunDirectionalLight
        light:SetIntensity(bHide and 90.0 or 10.0)

        
        -- light.IndirectLightingIntensity = 30.0
        -- light.SpecularScale = 0.02
        -- light.VolumetricScatteringIntensity = 0

        if sky.SkyLight then
            --sky.SkyLight:SetIntensity(bHide and 1.0 or 1.0)
        end

    end

    local pc = UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local world = pc:GetWorld()
        local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        if world and world:IsValid() and ksl and ksl:IsValid() then
            -- note that not all command work in script runtime, most need actual user input in console
            local cmds = {
                --'r.BloomQuality 0',
                --'r.Tonemapper.Quality 0',
                --'r.TonemapperGamma 6',

                'r.AmbientOcclusionLevels 0',
                'r.ContactShadows 0',
                'r.DistanceFieldAO 0',
                'r.Shadow.FilterMethod 1', -- 3 for PCSS (softer, lighter-looking shadows)
                'r.Shadow.MaxCSMResolution 512', --(lower resolution = blurrier = lighter)
                'r.Shadow.CSM.MaxCascades 1',
                'r.Shadow.RadiusThreshold 0.001', --to 0.5 (higher threshold = fewer shadows cast)

                'r.ForceLOD 0', -- not recognized
                'r.ParticleLODBias -10',
                'r.HLOD 0', -- not recognized
                'r.HLOD.DistanceScale 0', -- not recognized

                'r.LandscapeLODDistributionScale 3',
                'r.LandscapeLOD0DistributionScale 3',
                'r.LandscapeLODBias -3',

                'r.ViewDistanceScale 3', -- recognized but doesn't do shit
                'foliage.ForceLOD 0',
                'r.Nanite.MaxPixelsPerEdge 0.5',
                'r.LandscapeLOD0ScreenSize 10',
                'r.Streaming.FullyLoadUsedTextures 1',
                'r.Streaming.UseAllMips 1',

                'r.Nanite.MaxPixelsPerEdge 0.25',
                'r.Nanite.ViewMeshLODBias.Offset -4',
                'r.ScreenPercentage 200',
                'r.ViewDistanceScale 100',

            }

            local cmds11 = {
            }

            local cmdszz = {

                "r.ViewDistanceScale 10",
                "r.Streaming.FullyLoadUsedTextures 1",
                "r.Streaming.UseAllMips 1",

                "r.Nanite.MaxPixelsPerEdge 0.1",
                "r.Nanite.ViewMeshLODBias.Offset -5",

                "r.LandscapeLODBias -5",
                "r.LandscapeLOD0ScreenSize 100",

                "foliage.ForceLOD 0",

                "r.ScreenPercentage 200",
                "r.Tonemapper.Quality 0",    

                'r.AmbientOcclusionLevels=0',
                'r.Tonemapper.Quality=0',
 
                "r.DefaultFeature.AutoExposure 0",
                "r.EyeAdaptationQuality 0",

                "r.SkyLightIntensityMultiplier 3",
                "r.AmbientOcclusionLevels 0",
                "r.DistanceFieldAO 0",
                "r.ContactShadows 0",

                "r.Shadow.MaxCSMResolution 256",
                "r.Shadow.CSM.MaxCascades 1",
                "r.Shadow.RadiusThreshold 0.5",
                "r.Shadow.DistanceScale 0.5",
                "r.Shadow.Sharpen 0",
                "r.Shadow.FilterMethod 1",

                "r.Tonemapper.Gamma 3.2"
            }

            for _, cmd in ipairs(cmds) do
                ksl:ExecuteConsoleCommand(world, cmd, nil)
            end


            ksl:ExecuteConsoleCommand(world, "slomo " .. (bHide and "0.00000001" or "1"), nil)
        end
    end

end

local function setScene00(bHide)

    local world = UEHelpers.GetPlayerController():GetWorld()
    local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")

    local cmds = {
        "r.ViewDistanceScale 10",
        "r.Streaming.FullyLoadUsedTextures 1",
        "r.Streaming.UseAllMips 1",

        "r.Nanite.MaxPixelsPerEdge 0.1",
        "r.Nanite.ViewMeshLODBias.Offset -5",

        "r.LandscapeLODBias -5",
        "r.LandscapeLOD0ScreenSize 100",

        "foliage.ForceLOD 0",

        "r.ScreenPercentage 200",
        "r.Tonemapper.Quality 0",    
    }

    cmds0 = {
        "r.TonemapperGamma 3.2", --default

        "r.Shadow.MaxCSMResolution 2048",
        "r.Shadow.CSM.MaxCascades 1",
        "r.AmbientOcclusionLevels 0",
        "r.ContactShadows 0",
        "r.DistanceFieldAO 0",
        
        'r.Shadow.FilterMethod 3', -- 3 for PCSS (softer, lighter-looking shadows)
        'r.Shadow.MaxCSMResolution 256', --(lower resolution = blurrier = lighter)
        'r.Shadow.CSM.MaxCascades 1',
        'r.Shadow.RadiusThreshold 0.001', --to 0.5 (higher threshold = fewer shadows cast)
    }

    if world and ksl and bHide then
        for _, c in ipairs(cmds) do
            ksl:ExecuteConsoleCommand(world, c, nil)
        end
        --ksl:ExecuteConsoleCommand(world, "slomo 0.00000001", nil)
    else
        --ksl:ExecuteConsoleCommand(world, "slomo 1", nil)
    end

    local names = {
        'WaterBodyOceanComponent',
        'ExponentialHeightFogComponent',
    }

    for _, name in ipairs(names) do
        local o = FindFirstOf(name)
        if o and o:IsValid() and o.SetHiddenInGame then
            o.SetHiddenInGame(bHide, true)
        end
    end

    local time = FindFirstOf("UWETimeOfDayComponent")
    if time then
        time:SetTimeOfDay(0.5)
        --time:FreezeTime(bHide)
    end

    local sky = FindFirstOf("BP_UWESky_C")
    if sky then
        if sky.SunDirectionalLight then
            sky.SunDirectionalLight:SetIntensity(60.0)
        end
    end

end

local function startCapture()

    local pc = FindFirstOf("PlayerController")
    local world = pc:GetWorld()

    local capClass = StaticFindObject("/Script/Engine.SceneCapture2D")
    local capActor = world:SpawnActor(capClass, { X = 0, Y = 0, Z = cc.alt }, { Pitch = 90, Yaw = 0, Roll = 0 })

    local cap = capActor.CaptureComponent2D
    cap:K2_SetWorldRotation({ Pitch = -90.0, Yaw = -90.0, Roll = 0.0 }, false, {}, true)

    cap.ProjectionType = 1
    cap.OrthoWidth = chunkSize
    cap.CaptureSource = 2 -- 3 means HDR, no postprocessing
    cap.bCaptureEveryFrame = false

    local krl = StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
    local rt = krl:CreateRenderTarget2D(world, tileSize, tileSize, 2, { R = 0, G = 0, B = 0, A = 1 }, false, false)
    cap.TextureTarget = rt

    local scClass = StaticFindObject("/Script/Engine.WorldPartitionStreamingSourceComponent")
    if scClass then
        local sc = capActor:AddComponentByClass(scClass, false, {}, false)
        if sc then
            sc.DefaultLoadingRange = chunkSize * 10
            sc.Priority = 999
            sc:EnableStreamingSource()
        end
    end

    local sizeChunks = math.ceil(cc.size / chunkSize)
    local cx = math.floor(cc.left / chunkSize)
    local cy = math.floor(cc.top / chunkSize)
    local half = math.floor(sizeChunks / 2)

    local minX = (cx - half) * chunkSize
    local minY = (cy - half) * chunkSize

    local total = sizeChunks * sizeChunks
    local i = 0

    local function step()

        if i >= total then
            setScene(false)
            print("[CAPTURE] DONE")
            return
        end

        local x = i % sizeChunks
        local y = math.floor(i / sizeChunks)

        local px = minX + (x + 0.5) * chunkSize
        local py = minY + (y + 0.5) * chunkSize

        local gx = math.floor(px / chunkSize)
        local gy = math.floor(py / chunkSize)

        local file = string.format("Chunk_%d_%dp_%d_%d.png", chunkSize, tileSize, gx, gy)

        print(string.format("[CAPTURE] %d/%d %s", i + 1, total, file))

        ExecuteInGameThread(function()

            capActor:K2_SetActorLocation({ X = px, Y = py, Z = cc.alt }, false, {}, true)
            cap:CaptureScene()

            ExecuteWithDelay(delay, function()
                ExecuteInGameThread(function() -- mandatory or it crashes
                cap:CaptureScene()
                krl:ExportRenderTarget(world, rt, savePath, file)
                i = i + 1
                step()
                end)
            end)

        end)
    end
    step()
end

RegisterKeyBind(Key.F, { ModifierKey.CONTROL }, function()
    setScene(true)
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            startCapture()
        end)
    end)
end)
