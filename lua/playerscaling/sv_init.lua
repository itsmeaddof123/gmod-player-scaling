--[[This file contains serverside functions
    See sh_init.lua to configure addon settings
    playerscaling.setscale(ply, scale, dospeed, dojump, length) is the function you can use to scale players in code--]]

-- Communicates scaling to players
util.AddNetworkString("playerscaling")

-- Player command to scale themselves
concommand.Add("playerscale", function(ply, cmd, args)
    playerscaling.setscale(ply, unpack(args))
end, nil, "Set your size multiplier from 0.05 to 10. Other arguments are true/false for scale speed, scale jump", FCVAR_CHEAT)

-- Scaling size to speed 1:1 doesn't feel natural, so here's a custom conversion    
local function getspeedmult(scale)
    if (scale > 1) then -- Speeds players up less
        return 1 + scale / math.Clamp(playerscaling.speedmultlarge, 1, 10)
    else -- Slows players less
        return 1 - (1 - scale) * math.Clamp(playerscaling.speedmultsmall, 0, 1)
    end
end

-- Scaling size to jump 1:1 doesn't feel natural, so here's a custom conversion
local function getjumpmult(scale)
    if (scale > 1) then -- Upward jump scaling seems fine so far
        return scale + (scale - 1) * math.Clamp(playerscaling.jumpmultlarge, 0, 1)
    else -- Lowers jump power less
        return 1 - (1 - scale) * math.Clamp(playerscaling.jumpmultsmall, 0, 1)
    end
end

-- Scaling step size 1:1 feels good except for when you're scaled down
local function getstepmult(scale)
    return (math.max(scale, playerscaling.minstep))
end

-- Sets player scale. You can use this function when scaling players via code.
function playerscaling.setscale(ply, scale, dospeed, dojump, length)
    if (not IsValid(ply)) then
        return "Failed to scale: Invalid player"
    end

    -- Interrupt if already scaling
    if (playerscaling.lerp[ply]) then
        playerscaling.finish(ply, playerscaling.lerp[ply], "interrupted")
    end

    -- Overrides for default values
    if (dospeed ~= nil) then
        dospeed = tobool(dospeed)
    else
        dospeed = GetConVar("playerscaling_speed"):GetBool()
    end
    if (dojump ~= nil) then
        dojump = tobool(dojump)
    else
        dojump = GetConVar("playerscaling_jump"):GetBool()
    end
    local doview = playerscaling.doview
    local dostep = playerscaling.dostep
    
    -- Get old scale values if there are any, or use mirrored values
    local old = table.Copy(playerscaling.players[ply]) or {
        scale = 1,
        speed = dospeed,
        jump = dojump,
        view = doview,
        dostep = dostep,
    }

    -- If no old.scale was set for some reason
    old.scale = old.scale or 1

    -- Gets scale and returns if there are no changes
    scale = math.Clamp(scale or 1, playerscaling.minimumsize, playerscaling.maximumsize)
    if (old.scale == scale and old.speed == dospeed and old.jump == dojump and old.view == playerscaling.doview) then
        return "Failed to scale: Values unchanged"
    end

    -- Prepare scales. Divides the new scale by the old scale so that we can Lerp straight from the current scale to the target scale without having to reset to 1 first.
    local speedscale = (dospeed and getspeedmult(scale) or 1) / (old.speed and getspeedmult(old.scale) or 1)
    local jumpscale = (dojump and getjumpmult(scale) or 1) / (old.jump and getjumpmult(old.scale) or 1)
    local viewscale = (doview and scale or 1) / (old.view and old.scale or 1)
    local stepscale = (dostep and getstepmult(scale) or 1) / (old.step and getstepmult(old.scale) or 1)

    -- Sets up the lerp
    local shrinking = old.scale > scale
    local ratio = math.Clamp(shrinking and old.scale / scale or scale / old.scale, 0, 3)
    local length = length or ratio * math.max(GetConVar(shrinking and "playerscaling_downtime" or "playerscaling_uptime"):GetFloat(), 0.001)

    -- Overrides length if shrinking really small
    if (shrinking and old.scale < 1.25 and scale < 0.75) then
        length = length / 1.5
    end
    
    -- Overrides length if player is dead
    if (not ply:Alive()) then
        length = 0
    end

    -- Saves the new scale information
    playerscaling.players[ply] = {
        speed = dospeed,
        jump = dojump,
        view = doview,
        step = dostep,
    }

    -- Initializes the lerp. This will automatically be executed by the Tick hook in sh_init.lua
    playerscaling.lerp[ply] = {
        -- Lerp details
        alive = ply:Alive(),
        starttime = CurTime(),
        endtime = CurTime() + length,
        speed = dospeed,
        jump = dojump,
        view = doview,
        step = dostep,

        -- Prepare old values for the Lerp
        oldscale = old.scale,
        oldwalkspeed = ply:GetWalkSpeed(),
        oldrunspeed = ply:GetRunSpeed(),
        oldslowspeed = ply:GetSlowWalkSpeed(),
        oldmaxspeed = ply:GetMaxSpeed(),
        oldjump = ply:GetJumpPower(),
        oldview = ply:GetViewOffset(),
        oldviewducked = ply:GetViewOffsetDucked(),
        oldstep = ply:GetStepSize(),

        -- Prepare new values for the Lerp
        newscale = scale,
        newwalkspeed = ply:GetWalkSpeed() * speedscale,
        newrunspeed = ply:GetRunSpeed() * speedscale,
        newslowspeed = ply:GetSlowWalkSpeed() * speedscale,
        newmaxspeed = ply:GetMaxSpeed() * speedscale,
        newjump = ply:GetJumpPower() * jumpscale,
        newview = ply:GetViewOffset() * viewscale,
        newviewducked = ply:GetViewOffsetDucked() * viewscale,
        newstep = ply:GetStepSize() * stepscale,
    }

    -- Sends the player the updated scale
    net.Start("playerscaling")
        net.WriteFloat(scale)
        net.WriteFloat(length)
    net.Send(ply)

    return "Succeeded to scale"
end

-- Mark the scaling as finished
function playerscaling.finish(ply, info, reason)
    if (not IsValid(ply)) then
        return
    end

    -- Not used in this addon but may be useful in implementation
    hook.Run("playerscaling_finish", ply, table.Copy(info), reason or "unknown")

    -- Stop the scaling
    playerscaling.lerp[ply] = nil
end

-- Negates fall damage for certain scaled up players
hook.Add("GetFallDamage", "playerscaling_fall", function(ply, speed)
    if (not IsValid(ply) or not playerscaling.players[ply] or not GetConVar("playerscaling_fall"):GetBool()) then
        return
    end

    -- Negates fall damage for large players under a certain speed
    local scale = playerscaling.players[ply].scale or 1
    if (speed < 250 * (1 + scale)) then
        return 0
    end
end)

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
        maxs = 1 * scale * Vector(16, 16, ply:Crouching() and 36 or 72),
        mask = MASK_PLAYERSOLID,
    }
    local trace = util.TraceHull(tr)

    -- If they will, see if they can be moved away
    if (trace.Hit) then
        return false
    end

    return true
end

-- Used in Lerping 
local interval = engine.TickInterval()

-- Handles scale pausing
local function scaleshouldpause(ply, info)
    if (GetConVar("playerscaling_pause"):GetBool()) then
        -- Offsets the Lerp so that it continues smoothly after unpausing
        info.starttime = info.starttime + interval
        info.endtime = info.endtime + interval
        return true
    else
        return false
    end
end

-- Lerps the scale servside to scale players up and down
hook.Add("Tick", "playescaling_tickserver", function()
    -- Attempt to scale players
    for ply, info in pairs(playerscaling.lerp) do
        if (not IsValid(ply)) then
            continue
        end

        -- If the player dies while scaling it needs to end
        if (ply:Alive() ~= info.alive) then
            playerscaling.finish(ply, info, "death")

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
                local vertdiff = (ply:Crouching() and 36 or 72) * scalediff

                -- Check each direction for obstruction with the old scale
                local xpos = playerwillfit(ply, pos + Vector(horidiff, 0, 0), curscale)
                local xneg = playerwillfit(ply, pos - Vector(horidiff, 0, 0), curscale)
                local ypos = playerwillfit(ply, pos + Vector(0, horidiff, 0), curscale)
                local yneg = playerwillfit(ply, pos - Vector(0, horidiff, 0), curscale)
                local zpos = playerwillfit(ply, pos + Vector(0, 0, vertdiff), curscale)
                local zneg = playerwillfit(ply, pos - Vector(0, 0, vertdiff), curscale)

                -- Ends the lerp early if any direction fails both ways
                if (not (xpos or xneg) or not (ypos or yneg) or not (zpos or zneg)) then
                    if (not scaleshouldpause(ply, info)) then -- Pauses until there is room
                        playerscaling.finish(ply, info, "stuck")
                    end
                    continue
                end

                -- Otherwise, we can likely move the player
                local xoff = (xpos and xneg and 0) or (xpos and 1) or -1
                local yoff = (ypos and yneg and 0) or (ypos and 1) or -1
                local zoff = (zpos and 0) or -1
                local newpos = pos + Vector(xoff * 16 * scalediff, yoff * 16 * scalediff, zoff * (ply:Crouching() and 36 or 72) * scalediff)

                -- If the new position works, move the player
                if (playerwillfit(ply, newpos, nextscale)) then
                    ply:SetPos(newpos)
                else -- Otherwise, give up and end the lerp
                    if (not scaleshouldpause(ply, info)) then -- Pauses until there is room
                        playerscaling.finish(ply, info, "failed")
                    end
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
        ply:SetStepSize(Lerp(progress, info.oldstep, info.newstep))

        -- For some reason this has to be manual or player view switches to standing
        if (ply:Crouching()) then
            ply:SetCurrentViewOffset(ply:GetViewOffsetDucked())
        end

        -- End the lerp
        if (progress >= 1) then
            -- Occasionally players will get stuck in the final tick of the Lerp, so this will get them unstuck
            if (not playerwillfit(ply, ply:GetPos(), ply:GetModelScale()) and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP and GetConVar("playerscaling_clipping"):GetBool()) then
                playerscaling.setscale(ply, info.newscale * 0.95, info.dospeed, info.dojump, 0)
                continue
            end

            playerscaling.finish(ply, info, "complete")
            continue
        end
    end
end)

-- Resets player scaling on death
hook.Add("PlayerDeath", "playerscaling_death", function(ply, inf, att)
    if (not IsValid(ply) or (playerscaling.lerp[ply])) then
        return
    end

    local info = playerscaling.players[ply]
    if (info) then
        playerscaling.setscale(ply, 1)
    end
end)