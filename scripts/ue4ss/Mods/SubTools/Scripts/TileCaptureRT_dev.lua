local UEHelpers = require("UEHelpers")

local chunkSize = 100000/2

local tileSize = 4096
local savePath = "C:\\Temp\\Capture\\"
local delay = 250
local forceOverwrite = true

local locations = {
    lifepod = { left = -337193, top = 433406, alt = 1000, size = chunkSize },
    planetary = { left = -222771, top = 432320, alt = 500, size = chunkSize * 2 },
    turbine = { left = -160717, top = 436872, alt = 500, size = chunkSize * 2 },
    the_pit = { left = -344231.96875, top = 449815.84375, alt = 1000, size = chunkSize },
    glyph = { left = -232185.984375, top = 431499.40625, alt = 500, size = chunkSize },
    all = { left = -222771, top = 432320, alt = -100, size = 25600*11 }
}

local cc = locations.all

--local bb = {left=cc.left-cc.size/2, top=cc.top-cc.size/2, right=cc.left+cc.size/2, bottom=cc.top+cc.size/2}

local bb = { left = -388342, bottom = 511341, top = 363219, right = -73747 }



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
    end
    
    local sky = FindFirstOf("BP_UWESky_C")
    if sky and sky:IsValid() and sky.SunDirectionalLight then
        local light = sky.SunDirectionalLight
        light:SetIntensity(bHide and 90.0 or 10.0)
    end

    local pc = UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local world = pc:GetWorld()
        local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")

        if world and world:IsValid() and ksl and ksl:IsValid() then
            local cmds1 = {
                'r.AmbientOcclusionLevels 0',
                'r.ContactShadows 0',
                'r.DistanceFieldAO 0',
                'r.Shadow.FilterMethod 1',
                'r.Shadow.MaxCSMResolution 512',
                'r.Shadow.CSM.MaxCascades 1',
                'r.Shadow.RadiusThreshold 0.001',
                'r.ForceLOD 0',
                'r.ParticleLODBias -10',
                'r.HLOD 0',
                'r.HLOD.DistanceScale 0',
                'r.LandscapeLODDistributionScale 3',
                'r.LandscapeLOD0DistributionScale 3',
                'r.LandscapeLODBias -3',
                'r.ViewDistanceScale 3',
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

            local cmds = {
                "r.ViewDistanceScale 100",
                "r.Streaming.FullyLoadUsedTextures 1",
                "r.Streaming.UseAllMips 1",

                "r.Nanite.MaxPixelsPerEdge 0.1",
                "r.Nanite.ViewMeshLODBias.Offset -5",

                "r.LandscapeLODBias -5",
                "r.LandscapeLOD0ScreenSize 100",

                "foliage.ForceLOD 0",

                "r.ScreenPercentage 200",
                "r.Tonemapper.Quality 5",
                'r.AmbientOcclusionLevels=0',
 
                "r.DefaultFeature.AutoExposure 0",
                "r.EyeAdaptationQuality 0",

                "r.SkyLightIntensityMultiplier 6",
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

local function startCapture()
    local pc = FindFirstOf("PlayerController")
    local world = pc:GetWorld()

    local capClass = StaticFindObject("/Script/Engine.SceneCapture2D")
    local capActor = world:SpawnActor(capClass, { X = 0, Y = 0, Z = cc.alt }, { Pitch = 90, Yaw = 0, Roll = 0 })

    local cap = capActor.CaptureComponent2D
    cap:K2_SetWorldRotation({ Pitch = -90.0, Yaw = -90.0, Roll = 0.0 }, false, {}, true)

    cap.ProjectionType = 1
    cap.OrthoWidth = chunkSize
    cap.CaptureSource = 2
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

    local minGX = math.floor(bb.left / chunkSize)
    local maxGX = math.floor((bb.right - 1) / chunkSize)

    local minGY = math.floor(bb.top / chunkSize)
    local maxGY = math.floor((bb.bottom - 1) / chunkSize)

    local chunks = {}

    for gy = minGY, maxGY do
        for gx = minGX, maxGX do
            chunks[#chunks + 1] = {
                px = (gx + 0.5) * chunkSize,
                py = (gy + 0.5) * chunkSize,
                gx = gx,
                gy = gy
            }
        end
    end

    print("[CAPTURE] Capturing grid", maxGX-minGX+1, maxGY-minGY+1)


    local total = #chunks
    local i = 1

    local function step()
        if i > total then
            setScene(false)
            print("[CAPTURE] DONE")
            return
        end

        local c = chunks[i]

        local px = c.px
        local py = c.py
        local gx = c.gx
        local gy = c.gy

        local file = string.format("Chunk_%d_%dp_%d_%d.png", chunkSize, tileSize, gx, gy)

        if not forceOverwrite and fileExists(savePath .. file) then
            print(string.format("[CAPTURE] %d/%d SKIP %s", i, total, file))
            i = i + 1
            step()
            return
        end

        print(string.format("[CAPTURE] %d/%d %s", i, total, file))

        ExecuteInGameThread(function()
            capActor:K2_SetActorLocation({ X = px, Y = py, Z = cc.alt }, false, {}, true)
            cap:CaptureScene()

            ExecuteWithDelay(delay, function()
                ExecuteInGameThread(function()
                    cap:CaptureScene()
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
