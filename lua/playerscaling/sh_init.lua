--[[This file contains shared functions and settings
    ConVars are for major settings that are more likely to be changed
    The settings table is for things that are specific and unlikely to change--]]

-- Holds just about everything with the addon
playerscaling = playerscaling or {}
-- Keeps track of which players are actively scaled
playerscaling.players = playerscaling.players or {}

-- Settings that may be changed often
-- These can be overriden per calling of the playerscaling.setscale function
CreateConVar("playerscaling_speed", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player speed by default?", 0, 1) -- If disabled, speed will be overwhelming when small and underwhelming when large 
CreateConVar("playerscaling_jump", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player jump by default?", 0, 1) -- If disabled, jumps will feel massive when small and nonexistent when large
CreateConVar("playerscaling_time", 0.1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How much time should it take to scale?", 0) -- Set to 0 for instant scaling, or higher for slower rates. Proportional to ratio between scales

-- These cannot be overriden and should be changed serverside
-- TODO(itsmeaddof123) Use util.TraceHull to prevent clipping on respawn
CreateConVar("playerscaling_death", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling reset on death by default?", 0, 1) -- If disabled, large players may clip into walls on respawn
CreateConVar("playerscaling_gravity", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player gravity?", 0, 1) -- If disabled, large players will fall slowly and small players will fall quickly
CreateConVar("playerscaling_falldamage", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling negate certain fall damage?", 0, 1) -- If disabled, large players will take damage from proportionally small falls
CreateConVar("playerscaling_clipping", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling prevent clipping into objects?", 0, 1) -- If disabled, players may get stuck when growing

-- Settings that are less likely to change
for setting, parameter in pairs({
    maximumsize = 10, -- Maximum size multiplier. Set 1 (no growing) to 10 (largest). Can higher, with caution
    minimumsize = 0.05, -- Minimum size multiplier. Set 0.05 (smallest) to 1 (no shrinking). Can go lower, with caution
    speedmultlarge = 0.5, -- Large player speed gain. Set 0 (no gain) to 1 (full gain)
    speedmultsmall = 0.25, -- Small player speed slow. Set 0 (no slow) to 1 (full slow)
    jumpmultlarge = 0, -- Large player jump boost. Set 0 (no jump boost) to 1 (full jump boost)
    jumpmultsmall = 0.25, -- Small player jump lowering. Set 0 (no lowering) 1 (full lowering)
    gravitylarge = 100, -- Large player gravity increase. Set 0 (no increase) and up (greater gravity)
    gravitysmall = 100, -- Small player gravity decrease. Set 0 (no decrease) and up (lower gravity)
    falldamagelarge = 250, -- Large player fall damage negation threshold. Set 0 (no negation) and up (higher threshold)
    doview = true, -- Scale player perspective? Set true or false
}) do
    playerscaling[setting] = parameter
end

-- Gravity isn't predicted, so we simulate it by adding velocity each tick
local interval = engine.TickInterval()
hook.Add("Tick", "playerscaling_gravity", function()
    -- Only affects player gravity if the setting is enabled
    if (not GetConVar("playerscaling_gravity"):GetBool()) then
        return
    end

    -- Gets gravity settings
    local gravitylarge = -1 * math.max(playerscaling.gravitylarge or 100, 0)
    local gravitysmall = math.max(playerscaling.gravitysmall or 100, 0)

    -- Cycles through each currently scaled player
    for ply, info in pairs(playerscaling.players) do
        -- Skip gravity on invalid, dead, and grounded players
        if (not IsValid(ply) or not ply:Alive() or ply:IsOnGround()) then
            continue
        end

        -- Gets scale and skips unscaled players
        local scale = info.scale
        if (not scale or scale == 1) then
            continue
        end

        -- Gravity affects everything the same so this is really more about simulating air resistance
        if (scale > 1) then -- Increase acceleration for large players
            ply:SetVelocity(Vector(0, 0, interval * gravitylarge * scale))
        else -- Decrease acceleration for small players
            --TODO(itsmeaddof123) calibrate max velocity
            ply:SetVelocity(Vector(0, 0, interval * math.max(500, gravitysmall * scale))) -- math.max prevents players from floating
        end
    end

    if (SERVER) then
        for ply, info in pairs(playerscaling.lerp) do
            local progress = (CurTime() - info.starttime) / (info.endtime - info.starttime)

            playerscaling.players[ply].scale = Lerp(progress, info.oldscale, info.newscale)
            ply:SetModelScale(Lerp(progress, info.oldscale, info.newscale))
            ply:SetWalkSpeed(Lerp(progress, info.oldwalkspeed, info.newwalkspeed))
            ply:SetRunSpeed(Lerp(progress, info.oldrunspeed, info.newrunspeed))
            ply:SetSlowWalkSpeed(Lerp(progress, info.oldslowspeed, info.newslowspeed))
            ply:SetMaxSpeed(Lerp(progress, info.oldmaxspeed, info.newmaxspeed))
            ply:SetJumpPower(Lerp(progress, info.oldjump, info.newjump))
            ply:SetViewOffset(Lerp(progress, info.oldview, info.newview))
            ply:SetViewOffsetDucked(Lerp(progress, info.oldviewducked, info.newviewducked))

            if (progress >= 1) then
                playerscaling.lerp[ply] = nil
            end
        end
    else
        if (playerscaling.lerpclient) then
            local ply = LocalPlayer()
            local info = playerscaling.lerpclient
            local progress = (CurTime() - info.starttime) / (info.endtime - info.starttime)

            playerscaling.players[ply].scale = Lerp(progress, info.oldscale, info.newscale)

            if (progress >= 1) then
                playerscaling.lerpclient = nil
            end
        end
    end
end)