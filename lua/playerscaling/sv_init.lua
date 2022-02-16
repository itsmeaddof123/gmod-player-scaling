 -- Communicates scaling to players
util.AddNetworkString("playerscaling_set")

playerscaling = playerscaling or {}
playerscaling.players = playerscaling.players or {}

local playerscaling_death = CreateConVar("playerscaling_death", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling reset on death by default?", 0, 1)
local playerscaling_eyes = CreateConVar("playerscaling_eyes", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player eyes by default?", 0, 1)
local playerscaling_speed = CreateConVar("playerscaling_speed", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player speed by default?", 0, 1)
local playerscaling_jump = CreateConVar("playerscaling_jump", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player jump by default?", 0, 1)

-- Player command to scale themselves
concommand.Add("playerscale_me", function(ply, cmd, args)
    playerscaling.setscale(ply, unpack(args))
end, nil, "Set a scale from 0.05 to 10. Other arguments are true/false for (in order): death reset, scale eyes, scale speed, scale jump")

-- Sets player scale. You can use this function when scaling players via code.
function playerscaling.setscale(ply, scale, dodeath, doeyes, dospeed, dojump)
    if (not IsValid(ply)) then
        return
    end
    
    -- Resets player scale
    playerscaling.resetscale(ply)

    -- Gets scale and returns if only reset
    scale = math.Clamp(scale or 1, 0.05, 10)
    if (scale == 1) then
        return
    end

    -- Overrides for default values
    dodeath = dodeath or playerscaling_death:GetBool()
    doeyes = doeyes or playerscaling_eyes:GetBool()
    dospeed = dospeed or playerscaling_speed:GetBool()
    dojump = dojump or playerscaling_jump:GetBool()

    -- Initializes saved scaling values
    playerscaling.players[ply] = {}

    -- Scales player
    ply:SetModelScale(scale)
    playerscaling.players[ply].Scale = scale

    -- Scales eyes
    if (doeyes) then
        ply:SetViewOffset(ply:GetViewOffset() * scale)
        ply:SetViewOffsetDucked(ply:GetViewOffsetDucked() * scale)
        playerscaling.players[ply].Eyes = true
    end

    -- Scales speed
    if (dospeed) then
        --TODO(itsmeaddof123) Custom speed scale
        ply:SetCrouchedWalkSpeed(ply:GetCrouchedWalkSpeed() * scale)
        ply:SetSlowWalkSpeed(ply:GetSlowWalkSpeed() * scale)
        ply:SetWalkSpeed(ply:GetWalkSpeed() * scale)
        ply:SetMaxSpeed(ply:GetMaxSpeed() * scale)
        ply:SetRunSpeed(ply:GetRunSpeed() * scale)
        playerscaling.players[ply].Speed = true
    end

    -- Scales jump
    if (dojump) then
        --TODO(itsmeaddof123) Custom jump scale
        ply:SetJumpPower(ply:GetJumpPower() * scale)
        playerscaling.players[ply].Jump = true
    end
end

-- Resets player scale. 
function playerscaling.resetscale(ply)
    if (not IsValid(ply) or not playerscaling.players[ply]) then
        return
    end

    -- Resets scale
    local scale = playerscaling.players[ply].Scale or 1 -- Should never be 1, but just in case
    ply:SetModelScale(1)

    -- Resets eyes
    if (playerscaling.players[ply].Eyes) then
        ply:SetViewOffset(ply:GetViewOffset() / scale)
        ply:SetViewOffsetDucked(ply:GetViewOffsetDucked() / scale)
    end

    -- Resets speed
    if (playerscaling.players[ply].Speed) then
        --TODO(itsmeaddof123) Custom speed scale
        ply:SetCrouchedWalkSpeed(ply:GetCrouchedWalkSpeed() / scale)
        ply:SetSlowWalkSpeed(ply:GetSlowWalkSpeed() / scale)
        ply:SetWalkSpeed(ply:GetWalkSpeed() / scale)
        ply:SetMaxSpeed(ply:GetMaxSpeed() / scale)
        ply:SetRunSpeed(ply:GetRunSpeed() / scale)
    end

    -- Resets jump
    if (playerscaling.players[ply].Jump) then
        --TODO(itsmeaddof123) Custom jump scale
        ply:SetJumpPower(ply:GetJumpPower() / scale)
    end

    -- Removes saved scaling values
    playerscaling.players[ply] = nil
end

--TODO(itsmeaddof123) Add death hook