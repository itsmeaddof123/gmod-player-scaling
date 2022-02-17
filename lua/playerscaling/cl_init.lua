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

-- Prints addon credits once to player, if enabled (disabled by default)
hook.Add("Initialize", "playerscaling_credits", function()
    print("Player Scaling is an addon created by Addi Boi - https://github.com/itsmeaddof123/gmod-player-scaling/")
    hook.Remove("Initialize", "playerscaling_credits")
end)