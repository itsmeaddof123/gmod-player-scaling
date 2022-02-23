--[[Player Scaling By Addi

    Hi, thanks for checking out my addon. I made this because I like geometry
    and the idea of resizing players in pvp settings (such as TTT or deathmatch)
    for dynamic gameplay. Although, I think it would be cool to see applications
    in other gamemodes.

    You can make big changes to it if you like (pls give me credit for original
    addon design), but if you just want to configure some settings then see the
    ConVars and settings table. - Addi Boi

    More info in the README on Github: https://github.com/itsmeaddof123/gmod-player-scaling/

    This file contains shared initialization and functions
    ConVars can be seen listed in sh/config.lua--]]

-- Holds everything in the addon
playerscaling = playerscaling or {}
-- Keeps track of which players are currently scaled
playerscaling.players = playerscaling.players or {}
-- Keeps track of which players are currently being scaled
playerscaling.lerp = playerscaling.lerp or {}

-- ConVars used in this file
local gravity = GetConVar("playerscaling_gravity")
local gravitylarge = GetConVar("playerscaling_gravitylarge")
local gravitysmall = GetConVar("playerscaling_gravitysmall")

-- Gravity isn't predicted, so we simulate it by adding velocity each tick
local interval = engine.TickInterval()
hook.Add("Tick", "playerscaling_tickshared", function()
    -- Only affects player gravity if the setting is enabled
    if (gravity:GetBool()) then-- Gets gravity settings
        local multlarge = -1 * math.max(gravitylarge:GetFloat() or 100, 0)
        local multsmall = math.max(gravitysmall:GetFloat() or 100, 0)

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
                ply:SetVelocity(Vector(0, 0, interval * multlarge * scale))
            else -- Decrease acceleration for small players
                ply:SetVelocity(Vector(0, 0, interval * math.min(500, multsmall * (1 - scale)))) -- math.max prevents players from floating
            end
        end
    end
end)