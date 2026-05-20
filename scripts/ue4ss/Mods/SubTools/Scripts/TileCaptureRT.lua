-- before capturing, do these commands in console (those cvars can't be scripted, apparently):
-- r.Fog 0
-- r.Water.WaterMesh.Enabled 0
-- r.BloomQuality 0
-- r.TonemapperGamma 10

local UEHelpers = require("UEHelpers")

local chunkSize = 25600 -- do not change this

-- these locations use coordinates as an interest point (roughly in the center), aligned to chunk boundaries
-- so if you set size to chunkSize*1 it's mostly 2x2 chunks, and chunkSize*9 would be 10x10 chunks

local locations = {
    lifepod = { left = -337193, top = 433406, alt = 5000, size = chunkSize },
    planetary = { left = -222771, top = 432320, alt = 1000, size = chunkSize },
    turbine = { left = -160717, top = 436872, alt = 5000, size = chunkSize },
    planetary_all = { left = -222771, top = 432320, alt = 5000, size = chunkSize*11 },
}

--local cc = locations.turbine
--local cc = locations.lifepod
local cc = locations.planetary_all


local tileSize = 2048 -- Resolution of the final exported image per chunk (e.g., 512x512px)
local streamingDelay = 4000 -- delay to wait for chunk to load after teleporting pawn
local loadDistanceThreshold = chunkSize*4 -- distance from last load point before triggering another load wait

local Altitude = cc.alt
local size = cc.size

local SavePath = "C:\\Temp\\Capture\\"

local captureStopped = true

-- widget

local VISIBLE = 4
local HIDDEN = 2

local statsWidget = FindObject("UserWidget", "CaptureWidget")
local textBlock = FindObject("TextBlock", "CaptureTextBlock")

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local function setText(text)
    if textBlock and textBlock:IsValid() and FText then
        textBlock:SetText(FText(text))
    end
end

local function _print(s) 
    setText(s)
    print('[TileCaptureRT] ' .. s)
end

local function setAlignment(slot, alignment)
    local b = 0
    local alignments = {
        center = {anchor = {0.5, 0.5}, align = {0.5, 0.5}, pos = {0, 0}},
        top = {anchor = {0.5, 0}, align = {0.5, 0}, pos = {0, b}},
        bottom = {anchor = {0.5, 1}, align = {0.5, 1}, pos = {0, -b}},
        topleft = {anchor = {0, 0}, align = {0, 0}, pos = {b, b}},
        topright = {anchor = {1, 0}, align = {1, 0}, pos = {-b, b}},
        bottomleft = {anchor = {0, 1}, align = {0, 1}, pos = {b, -b}},
        bottomright = {anchor = {1, 1}, align = {1, 1}, pos = {-b, -b}}
    }
    local a = alignments[alignment] or alignments.center
    slot:SetAnchors({Minimum = {X = a.anchor[1], Y = a.anchor[2]}, Maximum = {X = a.anchor[1], Y = a.anchor[2]}})
    slot:SetAlignment({X = a.align[1], Y = a.align[2]})
    slot:SetPosition({X = a.pos[1], Y = a.pos[2]})
end

local function createTextWidget()
    useStats = false
    if statsWidget and statsWidget:IsValid() then
        return
    end

    local gi = UEHelpers.GetGameInstance()
    widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("StatsWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("StatsSimpleTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("StatsCanvas"))
    widget.WidgetTree.RootWidget = canvas

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("StatsBG"))
    bg:SetBrushColor(FLinearColor(0,0,0,0.25))
    bg:SetPadding({Left = 15, Top = 10, Right = 15, Bottom = 10})

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetAutoSize(true)
    setAlignment(slot, alignment or 'topright')

    local text = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), bg, FName("StatsTextBlock"))
    text.Font.Size = 24
    text:SetColorAndOpacity(FSlateColor(1,1,1,1))
    text:SetShadowOffset({X = 1, Y = 1})
    text:SetShadowColorAndOpacity(FLinearColor(0,0,0,0.5))
    text:SetText(FText('Hello World!'))
    text:SetVisibility(VISIBLE)
    textBlock = text
    bg:SetContent(text)

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(VISIBLE)

    widget:AddToViewport(99)

    statsWidget = widget

    _print('TileCaptureRT loaded, Ctrl+F to start/stop capture.')
end

-- /widget


local function toggleEffects(bHide)
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
        timeComponent:FreezeTime(bHide)
    end
    
    local sky = FindFirstOf("BP_UWESky_C")
    if sky and sky:IsValid() and sky.SunDirectionalLight then
        local light = sky.SunDirectionalLight
        light:SetIntensity(bHide and 50.0 or 10.0)
    end

    local pc = UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local world = pc:GetWorld()
        local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        if world and world:IsValid() and ksl and ksl:IsValid() then
            ksl:ExecuteConsoleCommand(world, "slomo " .. (bHide and "0.00000001" or "1"), nil)

            -- note that not all command work in script runtime, most need actual user input in console
            local cmds = {
                'landscape.ForceLOD 0',
                'r.ForceLOD 0',
                'foliage.ForceLOD 0',
                'r.BloomQuality 0',
                'r.Tonemapper.Quality 0',
                'r.TonemapperGamma 4',
                -- 'r.AntiAliasingMethod 0', -- breaks pictures, they become fully transparent
                -- 'r.ShadowQuality 0' -- breaks pictures, they become black
            }

            for _, cmd in ipairs(cmds) do
                ksl:ExecuteConsoleCommand(world, cmd, nil)
            end
        end
    end
end

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

    -- Grid Math - fixed the X/Y mixup here!
    local minX = math.floor((cc.left - size / 2) / chunkSize) * chunkSize
    local maxX = math.ceil((cc.left + size / 2) / chunkSize) * chunkSize
    local minY = math.floor((cc.top - size / 2) / chunkSize) * chunkSize
    local maxY = math.ceil((cc.top + size / 2) / chunkSize) * chunkSize

    local cols = math.floor((maxX - minX) / chunkSize)
    local rows = math.floor((maxY - minY) / chunkSize)
    local totalChunks = cols * rows

    local Rotation = { Pitch = 90.0, Yaw = 0.0, Roll = 0.0 }

    -- 1. Spawn the hidden Capture Actor
    local CaptureActor = World:SpawnActor(CaptureClass, { X = 0, Y = 0, Z = Altitude }, Rotation)
    if not CaptureActor or not CaptureActor:IsValid() then return end

    local CaptureComp = CaptureActor.CaptureComponent2D
    CaptureComp:K2_SetWorldRotation({ Pitch = -90.0, Yaw = -90.0, Roll = 0.0 }, false, {}, true)

    -- 2. Create the Render Target
    local RT = KismetRenderingLibrary:CreateRenderTarget2D(World, tileSize, tileSize, 2, { R = 0.0, G = 0.0, B = 0.0, A = 1.0 }, false, false)

    -- 3. Configure the Capture Component
    CaptureComp.TextureTarget = RT
    CaptureComp.ProjectionType = 1 -- Orthographic
    CaptureComp.OrthoWidth = chunkSize -- Camera covers exactly one chunk perfectly
    CaptureComp.CaptureSource = 2  -- FinalColorLDR
    CaptureComp.bCaptureEveryFrame = false
    CaptureComp.bCaptureOnMovement = false

    -- Attach the Streaming Source directly to the CaptureActor
    local StreamingSourceClass = StaticFindObject("/Script/Engine.WorldPartitionStreamingSourceComponent")
    if StreamingSourceClass then
        local StreamingComp = CaptureActor:AddComponentByClass(StreamingSourceClass, false, {}, false)
        if StreamingComp then
            StreamingComp.DefaultLoadingRange = loadDistanceThreshold * 2 -- Cover a wide area around the camera
            StreamingComp.bEnableStreaming = true
            StreamingComp:EnableStreamingSource()
            -- print("[MapCapture] Attached WorldPartitionStreamingSource to Camera.")
        end
    end

    _print(string.format("Capture Started! Saving %d chunks (%dp) to %s", totalChunks, tileSize, SavePath))

    local chunkIndex = 0
    local lastLoc = nil

    local function CaptureNextChunk()
        if captureStopped or chunkIndex >= totalChunks then
            toggleEffects(false)
            captureStopped = true
            _print("Capture finished. Ctrl+R to reload script, Ctrl+F to capture.")
            return
        end

        local c = chunkIndex % cols
        local r = math.floor(chunkIndex / cols)

        local CenterX = minX + (c + 0.5) * chunkSize
        local CenterY = minY + (r + 0.5) * chunkSize

        ExecuteInGameThread(function()
            local loc = { X = CenterX, Y = CenterY, Z = Altitude }
            
            -- Move Camera (The streaming source component is attached and moves with it)
            CaptureActor:K2_SetActorLocation(loc, false, {}, true)

            local FileName = string.format("Chunk_%d_%d.png", c, r)

            -- Check if we are far enough from the last loaded center to warrant a pause
            local dist = 999999
            if lastLoc then
                dist = math.sqrt((CenterX - lastLoc.X)^2 + (CenterY - lastLoc.Y)^2)
            end

            local delayTime = 100 -- brief delay even if 0 to ensure transform update

            -- If we moved beyond our threshold, apply the streaming delay
            if streamingDelay > 0 and dist > loadDistanceThreshold then
                -- print(string.format("[MapCapture] Waiting for chunk to stream (Distance: %.0f > %.0f)...", dist, loadDistanceThreshold))
                lastLoc = loc
                delayTime = streamingDelay
            end

            -- Wait for streaming, then capture
            ExecuteWithDelay(delayTime, function()
                ExecuteInGameThread(function()
                    CaptureComp:CaptureScene()

                    --_print(string.format("Ctrl+F to stop. Saving chunk %d/%d (%d, %d) to %s...", chunkIndex + 1, totalChunks, CenterX, CenterY, FileName))

                    _print(string.format("Saving chunk %d/%d (%dp) [%d,%d]. Ctrl+F to stop.", chunkIndex + 1, totalChunks, tileSize, CenterX, CenterY))

                    KismetRenderingLibrary:ExportRenderTarget(World, RT, SavePath, FileName)
                    -- print(string.format("[MapCapture] Saved %s", FileName))
                    chunkIndex = chunkIndex + 1
                    CaptureNextChunk()
                end)
            end)
        end)
    end

    CaptureNextChunk()
end

RegisterKeyBind(Key.F, { ModifierKey.CONTROL }, function()
    captureStopped  = not captureStopped
    if captureStopped then
        return
    end

    toggleEffects(true)
    ExecuteWithDelay(2000, function() -- wait 2 sec for autoexposure to settle
        ExecuteInGameThread(function()
            TakeOrthoByRenderTarget()
        end)
    end)
end)


local function updateWidget()
    if statsWidget and statsWidget:IsValid() then
        if not statsWidget:IsInViewport() then statsWidget:AddToViewport(99) end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    createTextWidget()
end)

createTextWidget()
updateWidget()

