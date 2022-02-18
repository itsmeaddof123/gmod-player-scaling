--[[This file contains clientside functions--]]

-- Reads in player scale updates
net.Receive("playerscaling", function(len)
    local ply = LocalPlayer()
    playerscaling.players[ply] = playerscaling.players[ply] or {
        scale = 1,
    }

    -- Reads in new scaling info
    local newscale = net.ReadFloat()
    local length = net.ReadFloat()
    local oldscale = playerscaling.players[ply].scale

    -- Skips if no change
    if (scale == oldscale) then -- Sets the scale
        return
    end

    -- Lerps the scale (only needed for gravity prediction)
    playerscaling.lerpclient = {
        starttime = CurTime(),
        endtime = CurTime() + length,
        oldscale = oldscale,
        newscale = newscale,
    }
end)

-- Lerps the scale clientside for gravity prediction
local tick = engine.TickInterval()
hook.Add("Tick", "playerscaling_client", function()
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
end)

-- Prints addon credits once to player, if enabled (disabled by default)
hook.Add("Initialize", "playerscaling_credits", function()
    print("Player Scaling is an addon created by Addi Boi - https://github.com/itsmeaddof123/gmod-player-scaling/")
    hook.Remove("Initialize", "playerscaling_credits")
end)