--[[This file contains shared functions and settings
    ConVars are for major settings that are more likely to be changed
    The settings table is for things that are specific and unlikely to change--]]

-- Holds just about everything with the addon
playerscaling = playerscaling or {}
-- Keeps track of which players are actively scaled
playerscaling.players = playerscaling.players or {}

if (SERVER) then
    -- Initializes here instead of sv_init because the tick function errors otherwise
    playerscaling.lerp = playerscaling.lerp or {}
else

end

-- These can be overriden by the playerscaling.setscale function
CreateConVar("playerscaling_speed", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player speed by default?", 0, 1) -- If disabled, speed will be overwhelming when small and underwhelming when large 
CreateConVar("playerscaling_jump", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player jump by default?", 0, 1) -- If disabled, jumps will feel massive when small and nonexistent when large
CreateConVar("playerscaling_uptime", 0.25, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How much time should it take to scale up?", 0) -- Set to 0 for instant scaling, or higher for slower rates. Proportional to ratio between scales
CreateConVar("playerscaling_downtime", 0.15, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How much time should it take to scale down?", 0) -- Set to 0 for instant scaling, or higher for slower rates. Proportional to ratio between scales

-- These can be changed serverside
-- TODO(itsmeaddof123) Use util.TraceHull to prevent clipping on respawn
CreateConVar("playerscaling_death", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling reset on death by default?", 0, 1) -- If disabled, large players may clip into walls on respawn
CreateConVar("playerscaling_gravity", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player gravity?", 0, 1) -- If disabled, large players will fall slowly and small players will fall quickly
CreateConVar("playerscaling_fall", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling negate certain fall damage?", 0, 1) -- If disabled, large players will take damage from proportionally small falls
CreateConVar("playerscaling_clipping", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling prevent clipping into objects?", 0, 1) -- If disabled, players may get stuck when growing

-- Settings that are less likely to need change
for setting, parameter in pairs({
    maximumsize = 25, -- Maximum size multiplier. Set 1 (no growing) to 10 (largest). Can higher, with caution
    minimumsize = 0.05, -- Minimum size multiplier. Set 0.05 (smallest) to 1 (no shrinking). Can go lower, with caution
    speedmultlarge = 2, -- Large player slow. Set 1 (no slow) to 10 (full slow)
    speedmultsmall = 0.25, -- Small player speed up. Set 0 (no speed up) to 1 (full speed up)
    jumpmultlarge = 0, -- Large player jump boost. Set 0 (no jump boost) to 1 (full jump boost)
    jumpmultsmall = 0.25, -- Small player jump lowering. Set 0 (no lowering) 1 (full lowering)
    gravitylarge = 100, -- Large player gravity increase. Set 0 (no increase) and up (greater gravity)
    gravitysmall = 100, -- Small player gravity decrease. Set 0 (no decrease) and up (lower gravity)
    falldamagelarge = 250, -- Large player fall damage negation threshold. Set 0 (no negation) and up (higher threshold)
    doview = true, -- Scale player perspective? Set true or false
}) do
    playerscaling[setting] = parameter
end

-- Utility function to check if the player will fit in a given spot
local function playerwillfit(ply, pos, scale)
    if (not IsValid(ply)) then
        return
    end

    -- Use defaults for these if they weren't provided in the function call
    pos = pos or ply:GetPos()
    scale = scale or ply:GetModelScale()

    local tr = {
        start = pos,
        endpos = pos,
        filter = ply,
        mins = 1 * scale * Vector(-16, -16, 0),
        maxs = 1 * scale * Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID,
    }
    local trace = util.TraceHull(tr)

    -- If they will, see if they can be moved away
    if (trace.Hit) then
        return false
    end

    return true
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
        -- Attempt to scale players
        for ply, info in pairs(playerscaling.lerp) do
            if (not IsValid(ply)) then
                continue
            end

            -- If the player dies while scaling it needs to end
            if (ply:Alive() ~= info.alive) then
                playerscaling.lerp[ply] = nil

                -- And if players should reset scale on death, do so
                if (GetConVar("playerscaling_death"):GetBool()) then
                    playerscaling.setscale(ply, 1)
                end

                continue
            end

            -- Get the proportional progress for the lerp
            local progress = (CurTime() - info.starttime) / (info.endtime - info.starttime)
            local newscale = info.newscale
            local oldscale = info.oldscale

            -- Gets the current step and next step of scaling
            local curscale = ply:GetModelScale()
            local nextscale = Lerp(progress, oldscale, newscale)

            -- If the player is growing, alive, and not noclipping, we need to avoid clipping
            if (curscale < nextscale and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP and GetConVar("playerscaling_clipping"):GetBool()) then
                -- See if they are going to clip anything
                local pos = ply:GetPos()
                if (not playerwillfit(ply, pos, nextscale)) then
                    -- If they will clip in their current position, see if we can move them 
                    local scalediff = nextscale - curscale
                    local horidiff = 16 * scalediff
                    local vertdiff = 72 * scalediff

                    -- Check each direction for obstruction with the old scale
                    local xpos = playerwillfit(ply, pos + Vector(horidiff, 0, 0), curscale)
                    local xneg = playerwillfit(ply, pos - Vector(horidiff, 0, 0), curscale)
                    local ypos = playerwillfit(ply, pos + Vector(0, horidiff, 0), curscale)
                    local yneg = playerwillfit(ply, pos - Vector(0, horidiff, 0), curscale)
                    local zpos = playerwillfit(ply, pos + Vector(0, 0, vertdiff), curscale)
                    local zneg = playerwillfit(ply, pos - Vector(0, 0, vertdiff), curscale)

                    -- Ends the lerp early if any direction fails both ways
                    if (not (xpos or xneg) or not (ypos or yneg) or not (zpos or zneg)) then
                        playerscaling.lerp[ply] = nil
                        continue
                    end

                    -- Otherwise, we can likely move the player
                    local xoff = (xpos and xneg and 0) or (xpos and 1) or -1
                    local yoff = (ypos and yneg and 0) or (ypos and 1) or -1
                    local zoff = (zpos and 0) or -1
                    local newpos = pos + Vector(xoff * 16 * scalediff, yoff * 16 * scalediff, zoff * 72 * scalediff)

                    -- If the new position works, move the player
                    if (playerwillfit(ply, newpos, nextscale)) then
                        ply:SetPos(newpos)
                    else -- Otherwise, give up and end the lerp
                        playerscaling.lerp[ply] = nil
                        continue
                    end
                end
            end

            -- Successfully scale the player
            playerscaling.players[ply].scale = nextscale
            ply:SetModelScale(nextscale)
            ply:SetWalkSpeed(Lerp(progress, info.oldwalkspeed, info.newwalkspeed))
            ply:SetRunSpeed(Lerp(progress, info.oldrunspeed, info.newrunspeed))
            ply:SetSlowWalkSpeed(Lerp(progress, info.oldslowspeed, info.newslowspeed))
            ply:SetMaxSpeed(Lerp(progress, info.oldmaxspeed, info.newmaxspeed))
            ply:SetJumpPower(Lerp(progress, info.oldjump, info.newjump))
            ply:SetViewOffset(Lerp(progress, info.oldview, info.newview))
            ply:SetViewOffsetDucked(Lerp(progress, info.oldviewducked, info.newviewducked))

            -- End the lerp
            if (progress >= 1) then
                playerscaling.lerp[ply] = nil
                continue
            end
        end
    else
        -- Attempt to change the scale clientside
        if (playerscaling.lerpclient) then
            local ply = LocalPlayer()
            local info = playerscaling.lerpclient
            local progress = (CurTime() - info.starttime) / (info.endtime - info.starttime)

            playerscaling.players[ply].scale = Lerp(progress, info.oldscale, info.newscale)

            -- End the lerp
            if (progress >= 1) then
                playerscaling.lerpclient = nil
            end
        end
    end
end)