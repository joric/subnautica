local UEHelpers = require("UEHelpers")

local function getHitResult(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 90000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    --[[
    ECollisionChannel
    ECC_WorldStatic = 0,
    ECC_WorldDynamic = 1,
    ECC_Pawn = 2,
    ECC_Visibility = 3,
    ECC_Camera = 4,
    ECC_PhysicsBody = 5,
    ECC_Vehicle = 6,
    ECC_Destructible = 7,
    ]]
    local TraceChannel = 1
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, TraceChannel, false, {}, 0, HitResult, true, Color, Color, 0.0)
    if WasHit then return HitResult end
    return nil
end

function getImpactPoint(WorldObject, StartVector, Rotation)
    return (getHitResult(WorldObject, StartVector, Rotation) or { ImpactPoint = StartVector }).ImpactPoint
end

function getHitObject(WorldObject, StartVector, Rotation)
    return UEHelpers.GetActorFromHitResult(getHitResult(WorldObject, StartVector, Rotation))
end

inDebugCamera = false -- global variable

local PlayerControllerCache = CreateInvalidObject()

function getPlayerController()
    if PlayerControllerCache:IsValid() then return PlayerControllerCache end
    local Controllers = FindAllOf("PlayerController") or FindAllOf("Controller") ---@type AController[]?
    if Controllers then
        for _, Controller in ipairs(Controllers) do
            if Controller:IsValid() and (Controller.IsPlayerController and Controller:IsPlayerController() or Controller:IsLocalPlayerController()) then
                PlayerControllerCache = Controller
                break
            end
        end
    end
    return PlayerControllerCache
end

local DebugCameraControllerCache = CreateInvalidObject()

function getDebugCameraController()
    if DebugCameraControllerCache:IsValid() then return DebugCameraControllerCache end
    for _, Controller in ipairs(FindAllOf("DebugCameraController") or {}) do
        if Controller:IsValid() and (Controller.IsPlayerController and Controller:IsPlayerController() or Controller:IsLocalPlayerController()) then
            DebugCameraControllerCache = Controller
            return DebugCameraControllerCache
        end
    end
    return getPlayerController()
end

function getCameraController()
    if inDebugCamera then return getDebugCameraController() else return getPlayerController() end
end

function getCameraHitObject()
    local pc = UEHelpers.GetPlayerController()
    local cam = getCameraController().PlayerCameraManager
    return getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end

function getCameraImpactPoint()
    local pc = UEHelpers.GetPlayerController()
    local cam = getCameraController().PlayerCameraManager
    return getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end


local function remoteControl()
    local hitObject = getCameraHitObject()
    if not hitObject or not hitObject:IsValid() then return end

    print("--- hitObject ---", hitObject:GetFullName())
end


local function cheatable(PlayerController)
    if not PlayerController.CheatManager:IsValid() then
        print("Restoring CheatManager")
        local CheatManagerClass = StaticFindObject("/Script/Engine.CheatManager")
        if CheatManagerClass:IsValid() then
            PlayerController.CheatManager = StaticConstructObject(CheatManagerClass, PlayerController)
        end
    end
    return PlayerController
end

-- this hook fixes the toggledebugcamera issue, see https://github.com/UE4SS-RE/RE-UE4SS/issues/514
-- crashes UE4SS_v3.0.1-596-g96c34c5.zip no matter the return value (object/true/false/nil/empty body)
-- stable version returned object https://docs.ue4ss.com/lua-api/global-functions/notifyonnewobject.html
-- dev version returns true/false https://docs.ue4ss.com/dev/lua-api/global-functions/notifyonnewobject.html
-- Fixed in 599, see https://github.com/UE4SS-RE/RE-UE4SS/pull/1065

NotifyOnNewObject("/Script/Engine.PlayerController", function(PlayerController)
    cheatable(PlayerController)
    return false
end)


local function toggleDebugCamera()
    if not inDebugCamera then
        pcall(function() cheatable(getPlayerController()).CheatManager:EnableDebugCamera() end)
        inDebugCamera = true
    else
        pcall(function() cheatable(getDebugCameraController()).CheatManager:DisableDebugCamera() end)
        inDebugCamera = false
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
    --PlayerPawn:K2_SetActorLocation(loc, false, {}, true)  -- crashes a lot
    --PlayerPawn:K2_TeleportTo(loc, { Pitch = 0, Yaw = rot.Yaw, Roll = 0 }) -- also crashes a lot
    PlayerPawn.RootComponent:K2_SetWorldLocation(loc, false, {}, true) -- safer
end

local lastTime = 0

local function teleportPlayer()
    if not inDebugCamera then return end

    local pc = getPlayerController()
    pc:ClientFlushLevelStreaming()
    pc:ClientForceGarbageCollection()

    local cc = getCameraController()
    cc:ClientFlushLevelStreaming()
    cc:ClientForceGarbageCollection()

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            -- pc.Pawn:K2_TeleportTo(cam:GetCameraLocation(), cam:GetCameraRotation()) -- teleport to debug camera position
            -- getCameraController().CheatManager:Teleport() -- built-in teleport console command, but it needs line of sight / navmesh
            teleportToTrace(pc.Pawn) -- teleport to impact point, may hit hidden volumes
        end)
    end)
end


RegisterKeyBind(Key.E, {ModifierKey.ALT}, remoteControl)
RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)


-- require("GameStats")

