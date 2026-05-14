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

local function teleportToTrace(PlayerPawn)
    local cam = UEHelpers.GetPlayerController().PlayerCameraManager
    local rot = cam:GetCameraRotation()
    local loc = getImpactPoint(PlayerPawn, cam:GetCameraLocation(), rot)
    loc.Z = loc.Z + 100
    PlayerPawn.RootComponent:K2_SetWorldLocation(loc, false, {}, true)
end

local function teleportPlayer()
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            teleportToTrace(UEHelpers.GetPlayerController().Pawn)
        end)
    end)
end

RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, {ModifierKey.ALT}, teleportPlayer)
print("[TeleportMod] Click Alt+LMB to teleport to cursor")
