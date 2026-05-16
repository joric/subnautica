-- before capturing, do these commands in console (those cvars can't be scripted, apparently):

-- disables fog on distance and disables water (!)
-- r.Fog 0 
-- r.Water.WaterMesh.Enabled 0 

-- these two don't seem to work properly, everything is dark
-- r.ShadowQuality 0 
-- r.DynamicGlobalIlluminationMethod 0

-- you can get the best sun with slomo 100 and then slomo 0.001 to stop the sun


local UEHelpers = require("UEHelpers")

size=200000

local cc = { left=-337193, top=433406, alt=5000} -- lifepod

local bb = { left = cc.left-size/2, top = cc.top-size/2, right = cc.left+size/2, bottom = cc.top+size/2 }

local Altitude = cc.alt

local mapSize = 4096
local tileSize = 2048

local SavePath = "C:\\Temp\\Capture\\"

local function TakeOrthoByRenderTarget()
    local PC = FindFirstOf("PlayerController")
    if not PC or not PC:IsValid() then return end

    local World = PC:GetWorld()
    local KismetRenderingLibrary = StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
    local CaptureClass = StaticFindObject("/Script/Engine.SceneCapture2D")

    if not KismetRenderingLibrary or not CaptureClass then
        print("Failed to find Rendering Library or Capture Class.")
        return
    end

    -- Grid Math
    local cols = math.floor(mapSize / tileSize)
    local rows = math.floor(mapSize / tileSize)
    local totalTiles = cols * rows
    local bbWidth = bb.right - bb.left
    local bbHeight = bb.bottom - bb.top
    local tileUUWidth = bbWidth / cols
    local tileUUHeight = bbHeight / rows
    
    local Rotation = {Pitch = 90.0, Yaw = 0.0, Roll = 0.0}

    -- 1. Spawn the hidden Capture Actor
    local CaptureActor = World:SpawnActor(CaptureClass, {X = 0, Y = 0, Z = Altitude}, Rotation)
    if not CaptureActor or not CaptureActor:IsValid() then return end

    local CaptureComp = CaptureActor.CaptureComponent2D

    -- 2. Create the Render Target 
    -- Passed exactly as: World, Width, Height, Format, ClearColor, bAutoGenerateMipMaps, bSupportFractionalGamma, Filter
    local RT = KismetRenderingLibrary:CreateRenderTarget2D(World, tileSize, tileSize, 2, {R=0.0, G=0.0, B=0.0, A=1.0}, false, false)

    -- 3. Configure the Capture Component
    CaptureComp.TextureTarget = RT
    CaptureComp.ProjectionType = 1 -- 1 = Orthographic
    CaptureComp.OrthoWidth = tileUUWidth
    CaptureComp.CaptureSource = 2  -- 2 = FinalColorLDR (Includes post-processing, use 0 for raw SceneColor if needed)
    CaptureComp.bCaptureEveryFrame = false
    CaptureComp.bCaptureOnMovement = false

    -- Spawn a hidden actor with streaming source component
    local StreamingSourceClass = StaticFindObject("/Script/Engine.WorldPartitionStreamingSourceComponent")
    local SourceActor = World:SpawnActor(StaticFindObject("/Script/Engine.Actor"), { X = 0, Y = 0, Z = 0 }, { Pitch = 0, Yaw = 0, Roll = 0 })

    if StreamingSourceClass and SourceActor then
        local StreamingComp = SourceActor:AddComponentByClass(StreamingSourceClass, false, {}, false)
        if StreamingComp then
            -- Set loading range directly on the component
            StreamingComp.DefaultLoadingRange = 500000
            StreamingComp.bEnableStreaming = true
            UEHelpers.GetGameplayStatics():FinishSpawningActor(SourceActor, { X = 0, Y = 0, Z = 0 }, 0)
            print(string.format("\n[MapCapture] finished spawning streaming source %s", StreamingComp:GetFullName()))
        end
    end

    print(string.format("\n[MapCapture] RenderTarget Capture Started! Saving to %s", SavePath))

    local tileIndex = 0

    local function CaptureNextTile()
        if tileIndex >= totalTiles then
            print("[MapCapture] Capture finished.")
            return
        end

        local c = tileIndex % cols
        local r = math.floor(tileIndex / cols)
        
        local CenterX = bb.left + (c + 0.5) * tileUUWidth
        local CenterY = bb.top + (r + 0.5) * tileUUHeight

        ExecuteInGameThread(function()
            CaptureActor:K2_SetActorLocation({X = CenterX, Y = CenterY, Z = Altitude}, false, {}, true)

            local FileName = string.format("Tile_%d_%d.png", c, r)
            print(string.format("[MapCapture] Moved RT to Tile %d/%d. Saving %s...", tileIndex + 1, totalTiles, FileName))

            ExecuteInGameThread(function()
                CaptureComp:CaptureScene()
                KismetRenderingLibrary:ExportRenderTarget(World, RT, SavePath, FileName)
                tileIndex = tileIndex + 1
                CaptureNextTile()
            end)
        end)
    end

    CaptureNextTile()

end

RegisterKeyBind(Key.R, {ModifierKey.ALT}, function()
    TakeOrthoByRenderTarget()
end)

