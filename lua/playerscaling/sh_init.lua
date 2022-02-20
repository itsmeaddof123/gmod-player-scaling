--[[PLAYER SCALING BY ADDI
    Hi, thanks for checking out my addon. I made this because I like geometry
    and the idea of resizing players in pvp settings (such as TTT or deathmatch)
    for dynamic gameplay. Although, I think it would be cool to see applications
    in other gamemodes.

    You can make big changes to it if you like (pls give me credit for original
    addon design), but if you just want to configure some settings then see the
    ConVars and settings table. - Addi Boi

    More info in the README on Github: https://github.com/itsmeaddof123/gmod-player-scaling/
--]]

--[[This file contains shared functions and settings
    ConVars are for major settings that are more likely to be changed
    The settings table is for things that are specific and unlikely to change--]]

-- Holds just about everything with the addon
playerscaling = playerscaling or {}
-- Keeps track of which players are actively scaled
playerscaling.players = playerscaling.players or {}

-- Initializes here instead of sv_init because the tick function errors otherwise
playerscaling.lerp = playerscaling.lerp or {}

-- These can be overriden by the playerscaling.setscale function
CreateConVar("playerscaling_speed", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player speed by default?", 0, 1) -- If disabled, speed will be overwhelming when small and underwhelming when large 
CreateConVar("playerscaling_jump", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player jump by default?", 0, 1) -- If disabled, jumps will feel massive when small and nonexistent when large
CreateConVar("playerscaling_uptime", 0.3, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How much time should it take to scale up by default?", 0) -- Set to 0 for instant scaling, or higher for slower rates. Proportional to ratio between scales
CreateConVar("playerscaling_downtime", 0.2, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How much time should it take to scale down by default?", 0) -- Set to 0 for instant scaling, or higher for slower rates. Proportional to ratio between scales

-- These can be changed serverside
CreateConVar("playerscaling_death", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling reset on death?", 0, 1) -- If disabled, large players may clip into walls on respawn
CreateConVar("playerscaling_gravity", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player gravity?", 0, 1) -- If disabled, large players will fall slowly and small players will fall quickly
CreateConVar("playerscaling_fall", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling negate certain fall damage?", 0, 1) -- If disabled, large players will take damage from proportionally small falls
CreateConVar("playerscaling_clipping", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling prevent clipping into objects?", 0, 1) -- If disabled, players may get stuck when growing
CreateConVar("playerscaling_pause", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling pause when stuck until unstuck?", 0, 1) -- If disabled, player scaling may get cancelled even if they were stuck for only a moment

-- Settings that are less likely to need change
for setting, parameter in pairs({
    maximumsize = 25, -- Maximum size multiplier. Set 1 (no growing) to 25 (largest). Can go higher, with caution
    minimumsize = 0.05, -- Minimum size multiplier. Set 0.05 (smallest) to 1 (no shrinking). Can go lower, with caution
    speedmultlarge = 2, -- Large player slowing factor. Set 1 (no slow) to 10 (full slow)
    speedmultsmall = 0.8, -- Small player speeding factor. Set 0 (no speed up) to 1 (full speed up)
    jumpmultlarge = 0, -- Large player jump boost. Set 0 (no jump boost) to 1 (full jump boost)
    jumpmultsmall = 0.6, -- Small player jump lowering. Set 0 (no lowering) to 1 (full lowering)
    minstep = 0.25, -- Minimum step size for small players. Set 0 (no lower limit) to 1 (never lower step size) 
    gravitylarge = 200, -- Large player gravity increase. Set 0 (no increase) and up (greater gravity)
    gravitysmall = 500, -- Small player gravity decrease. Set 0 (no decrease) and up (lower gravity)
    falldamagelarge = 250, -- Large player fall damage negation threshold. Set 0 (no negation) and up (higher threshold)
    doview = true, -- Scale player perspective? Set true or false (changing not recommended)
    dostep = true, -- Scale player step size? Set true or false
    printcredits = false, -- If you enable this, players will see credits for this addon in console. :)
}) do
    playerscaling[setting] = parameter
end

-- Gravity isn't predicted, so we simulate it by adding velocity each tick
local interval = engine.TickInterval()
hook.Add("Tick", "playerscaling_tickshared", function()
    -- Only affects player gravity if the setting is enabled
    if (GetConVar("playerscaling_gravity"):GetBool()) then-- Gets gravity settings
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
                ply:SetVelocity(Vector(0, 0, interval * math.min(500, gravitysmall * (1 - scale)))) -- math.max prevents players from floating
            end
        end
    end
end)