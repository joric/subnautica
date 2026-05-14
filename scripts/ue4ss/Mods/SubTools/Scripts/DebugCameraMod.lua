local UEHelpers = require("UEHelpers")

local function getHitResult(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 90000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    local TraceChannel = 1
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, TraceChannel, false, {}, 0, HitResult, true, Color, Color, 0.0)
    if WasHit then return HitResult end
    return nil
end

function getImpactPoint(WorldObject, StartVector, Rotation)
    return (getHitResult(WorldObject, StartVector, Rotation) or { ImpactPoint = StartVector }).ImpactPoint
end

local inDebugCamera = false

local function getCameraController()
    if inDebugCamera then
        return FindFirstOf("DebugCameraController")
    else
        return UEHelpers.GetPlayerController()
    end
end

local function teleportToTrace(PlayerPawn)
    local cam = getCameraController().PlayerCameraManager
    local rot = cam:GetCameraRotation()
    local loc = getImpactPoint(PlayerPawn, cam:GetCameraLocation(), rot)
    loc.Z = loc.Z + 100 -- above the ground
    if not PlayerPawn or not PlayerPawn:IsValid() then
        print("INVALID PAWN, CAN'T TELEPORT!!!")
        return
    end
    PlayerPawn.RootComponent:K2_SetWorldLocation(loc, false, {}, true) -- safer
end

local function toggleDebugCamera()
    local pc = getCameraController()
    if inDebugCamera then
        if not pc.CheatManager:IsValid() then
            pc.CheatManager = StaticConstructObject(StaticFindObject("/Script/Engine.CheatManager"), pc)
        end
        pc.CheatManager:DisableDebugCamera()
        inDebugCamera = false
    else
        pc.CheatManager:EnableDebugCamera()
        inDebugCamera = true
    end
end

local function teleportPlayer()
    if not inDebugCamera then return end
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            teleportToTrace(UEHelpers.GetPlayerController().Pawn)
        end)
    end)
end


RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)
