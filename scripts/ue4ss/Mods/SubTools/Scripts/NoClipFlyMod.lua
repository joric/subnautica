-- originally from https://github.com/joric/supraworld/scripts/ue4ss/

local noclip = false
local flySpeed = 2000

-- Find the player character
local function getPlayer()
    return FindFirstOf("Character")
end

-- Get player controller
local function getPlayerController()
    return FindFirstOf("PlayerController")
end

local function moveUp()
    if not noclip then return end
    print("[NoclipFlyMod] UP")
    local p = getPlayer()
    if not p then return end
    if not p.CharacterMovement then return end
    p.CharacterMovement:AddImpulse({X = 0, Y = 0, Z = flySpeed}, true)
end

local function moveDown()
    if not noclip then return end
    print("[NoclipFlyMod] DOWN")
    local p = getPlayer()
    if not p then return end
    if not p.CharacterMovement then return end
    p.CharacterMovement:AddImpulse({X = 0, Y = 0, Z = -flySpeed}, true)
end

-- Enable noclip: collisions off, flying mode
local function enableNoclip()
    local p = getPlayer()
    if not p then return end
    p:SetActorEnableCollision(false)
    if p.CharacterMovement then
        p.CharacterMovement:SetMovementMode(5, 0) -- MOVE_Flying
        p.CharacterMovement.bCheatFlying = true
        p.CharacterMovement.MaxFlySpeed = flySpeed
        p.CharacterMovement.BrakingDecelerationFlying = flySpeed * 2
        p.CharacterMovement.MaxAcceleration = flySpeed * 4
        p.CharacterMovement.GravityScale = 0.0
        p.CharacterMovement.bOrientRotationToMovement = false
        p.CharacterMovement.bUseControllerDesiredRotation = true
    end
    noclip = true
    print("[NoclipFlyMod] Noclip ON")
end

-- Disable noclip: collisions on, walking mode
local function disableNoclip()
    local p = getPlayer()
    if not p then return end
    p:SetActorEnableCollision(true)
    if p.CharacterMovement then
        p.CharacterMovement:SetMovementMode(1, 0) -- MOVE_Walking
        p.CharacterMovement.bCheatFlying = false
        p.CharacterMovement.GravityScale = 1.0
        p.CharacterMovement.bOrientRotationToMovement = true
        p.CharacterMovement.bUseControllerDesiredRotation = false
    end
    noclip = false
    print("[NoclipFlyMod] Noclip OFF")
end

-- Toggle noclip
local function toggleNoclip()
    if noclip then
        disableNoclip()
    else
        enableNoclip()
    end
end

-- Bind keys - override default WASD with custom camera-relative movement
RegisterKeyBind(Key.C, toggleNoclip)
RegisterKeyBind(Key.SPACE, moveUp)
RegisterKeyBind(Key.Z, moveDown)


print("[NoclipFlyMod] Press C to toggle noclip")
print("[NoclipFlyMod] WASD moves relative to camera direction")
print("[NoclipFlyMod] Space = up, Z = down")
