-- run commands in console before capturing

-- r.Fog 0
-- r.ShadowQuality 0
-- r.Water.WaterMesh.Enabled 0
-- r.DynamicGlobalIlluminationMethod 0

-- the results are in %localappdata%\Subnautica2\Saved\Screenshots\Windows

local UEHelpers = require("UEHelpers")

size=50000

local cc = { left=-337193, top=433406, alt=25000}

local bb = { left = cc.left-size/2, top = cc.top-size/2, right = cc.left+size/2, bottom = cc.top+size/2 }

local Altitude = cc.alt

local mapSize = 4096
local tileSize = 2048

local function TakeGlitchFreeOrtho()
    local PC = FindFirstOf("PlayerController")
    if not PC or not PC:IsValid() then return end

    local World = PC:GetWorld()
    local OriginalPawn = PC.Pawn
    local KismetSystemLibrary = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")

    local SpectatorClass = StaticFindObject("/Script/Engine.SpectatorPawn")
    if not SpectatorClass or not SpectatorClass:IsValid() then
        SpectatorClass = StaticFindObject("/Script/Engine.DefaultPawn")
    end

    local Rotation = {Pitch = -90.0, Yaw = 0.0, Roll = 0.0}
    local CapturePawn = World:SpawnActor(SpectatorClass, {X = 0, Y = 0, Z = Altitude}, Rotation)
    if not CapturePawn or not CapturePawn:IsValid() then return end

    PC:Possess(CapturePawn)
    CapturePawn:K2_SetActorRotation(Rotation, false)
    PC:SetControlRotation(Rotation)

    -- Grid Math
    local cols = math.floor(mapSize / tileSize)
    local rows = math.floor(mapSize / tileSize)
    local totalTiles = cols * rows
    local bbWidth = bb.right - bb.left
    local bbHeight = bb.bottom - bb.top
    local tileUUWidth = bbWidth / cols
    local tileUUHeight = bbHeight / rows
    
    local PCM = PC.PlayerCameraManager
    local OldOrtho = false
    local OldWidth = 1000
    if PCM and PCM:IsValid() then
        OldOrtho = PCM.bIsOrthographic
        OldWidth = PCM.DefaultOrthoWidth
        PCM.bIsOrthographic = true
        PCM.DefaultOrthoWidth = tileUUWidth
    end

    print(string.format("\n[MapCapture] Starting Glitch-Free Capture of %d tiles...", totalTiles))

    local tileIndex = 0

    local function CaptureNextTile()
        if tileIndex >= totalTiles then
            print("[MapCapture] Finished! Restoring camera and engine settings.")
            
            -- Restore Settings
            if PCM and PCM:IsValid() then
                PCM.bIsOrthographic = OldOrtho
                PCM.DefaultOrthoWidth = OldWidth
            end
            if OriginalPawn and OriginalPawn:IsValid() then PC:Possess(OriginalPawn) end
            CapturePawn:K2_DestroyActor()
            return
        end

        local c = tileIndex % cols
        local r = math.floor(tileIndex / cols)
        local CenterX = bb.left + (c + 0.5) * tileUUWidth
        local CenterY = bb.top + (r + 0.5) * tileUUHeight

        CapturePawn:K2_SetActorLocation({X = CenterX, Y = CenterY, Z = Altitude}, false, {}, true)

        -- Wait for chunks to stream in
        ExecuteWithDelay(2500, function()
            if KismetSystemLibrary and KismetSystemLibrary:IsValid() then
                KismetSystemLibrary:ExecuteConsoleCommand(World, string.format("HighResShot %dx%d", tileSize, tileSize), nil)
                print(string.format("[MapCapture] Snapped Tile %d (Col: %d, Row: %d)", tileIndex + 1, c, r))
            end

            -- Wait for IO to disk
            ExecuteWithDelay(3000, function()
                tileIndex = tileIndex + 1
                CaptureNextTile()
            end)
        end)
    end

    CaptureNextTile()
end

RegisterKeyBind(Key.S, {ModifierKey.ALT}, function()
    TakeGlitchFreeOrtho()
end)
