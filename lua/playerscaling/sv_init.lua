--[[This file contains serverside functions
    See sh_init.lua to configure addon settings
    playerscaling.setscale(ply, scale, dospeed, dojump) is the function you can use to scale players in code--]]

-- Communicates scaling to players
util.AddNetworkString("playerscaling")

-- Player command to scale themselves
concommand.Add("playerscale", function(ply, cmd, args)
    --TODO(itsmeaddof123) Possibly, add a usergroup confirmation
    ply:ChatPrint(playerscaling.setscale(ply, unpack(args)))
end, nil, "Set your size multiplier from 0.05 to 10. Other arguments are true/false for scale speed, scale jump")

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

-- Sets player scale. You can use this function when scaling players via code.
function playerscaling.setscale(ply, scale, dospeed, dojump)
    if (not IsValid(ply)) then
        return "Failed to scale: Invalid player"
    end

    -- Return if already scaling
    if (playerscaling.lerp[ply]) then
        return "Failed to scale: Already scaling"
    end
    
    -- Get old scale values if there are any
    local old = table.Copy(playerscaling.players[ply]) or {
        scale = 1,
        speed = false,
        jump = false,
        view = false,
    }

    -- If no old.scale was set for some reason
    old.scale = old.scale or 1

    -- Overrides for default values
    dospeed = tobool(dospeed) or GetConVar("playerscaling_speed"):GetBool()
    dojump = tobool(dojump) or GetConVar("playerscaling_jump"):GetBool()
    local doview = playerscaling.doview

    -- Gets scale and returns if there are no changes
    scale = math.Clamp(scale or 1, playerscaling.minimumsize, playerscaling.maximumsize)
    if (old.scale == scale and old.speed == dospeed and old.jump == dojump and old.view == playerscaling.doview) then
        return "Failed to scale: Values unchanged"
    end

    -- Prepare scales. Divides the new scale by the old scale so that we can Lerp straight from the current scale to the target scale without having to reset to 1 first.
    local speedscale = (dospeed and getspeedmult(scale) or 1) / (old.speed and getspeedmult(old.scale) or 1)
    local jumpscale = (dojump and getjumpmult(scale) or 1) / (old.jump and getjumpmult(old.scale) or 1)
    local viewscale = (doview and scale or 1) / (old.view and old.scale or 1)

    -- Sets up the lerp
    local shrinking = old.scale > scale
    local ratio = math.Clamp(shrinking and old.scale / scale or scale / old.scale, 0, 3)
    local length = ratio * math.max(GetConVar(shrinking and "playerscaling_downtime" or "playerscaling_uptime"):GetFloat(), 0)

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

        -- Prepare old values for the Lerp
        oldscale = old.scale,
        oldwalkspeed = ply:GetWalkSpeed(),
        oldrunspeed = ply:GetRunSpeed(),
        oldslowspeed = ply:GetSlowWalkSpeed(),
        oldmaxspeed = ply:GetMaxSpeed(),
        oldjump = ply:GetJumpPower(),
        oldview = ply:GetViewOffset(),
        oldviewducked = ply:GetViewOffsetDucked(),

        -- Prepare new values for the Lerp
        newscale = scale,
        newwalkspeed = ply:GetWalkSpeed() * speedscale,
        newrunspeed = ply:GetRunSpeed() * speedscale,
        newslowspeed = ply:GetSlowWalkSpeed() * speedscale,
        newmaxspeed = ply:GetMaxSpeed() * speedscale,
        newjump = ply:GetJumpPower() * jumpscale,
        newview = ply:GetViewOffset() * viewscale,
        newviewducked = ply:GetViewOffsetDucked() * viewscale,
    }

    -- Sends the player the updated scale
    net.Start("playerscaling")
        net.WriteFloat(scale)
        net.WriteFloat(length)
    net.Send(ply)
end

--[[-- Resets scaling on marked players on death
hook.Add("PlayerDeath", "playerscaling_death", function(ply, inf, att)
    if (not IsValid(ply) or not playerscaling.players[ply] or not GetConVar("playerscaling_death"):GetBool()) then
        return
    end

    playerscaling.lerp[ply] = {}
    playerscaling.setscale(ply, 1)
end)--]]

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