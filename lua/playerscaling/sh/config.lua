--[[Player Scaling By Addi

    See listed configurables here. You can edit these here if you like,
    or just change the ConVar values on your server itself--]]

-- ConVars relevant only to the server. It's fine that they're shared because it isn't sensitive info
if SERVER then
    -- Scaling toggles/parameters that the playerscaling.setscale function can override
    CreateConVar("playerscaling_speed", 1, {FCVAR_ARCHIVE}, "Should scaling affect player speed by default?", 0, 1) -- If disabled, speed will be overwhelming when small and underwhelming when large 
    CreateConVar("playerscaling_jump", 1, {FCVAR_ARCHIVE}, "Should scaling affect player jump by default?", 0, 1) -- If disabled, jumps will feel massive when small and nonexistent when large
    CreateConVar("playerscaling_uptime", 0.3, {FCVAR_ARCHIVE}, "Default upscale rate", 0)
    CreateConVar("playerscaling_downtime", 0.2, {FCVAR_ARCHIVE}, "Default downscale rate", 0)

    -- Scaling toggles
    CreateConVar("playerscaling_death", 1, {FCVAR_ARCHIVE}, "Should scaling reset on death?", 0, 1) -- If disabled, large players may clip into walls on respawn
    CreateConVar("playerscaling_fall", 1, {FCVAR_ARCHIVE}, "Should scaling negate certain fall damage?", 0, 1) -- If disabled, large players will take damage from proportionally small falls
    CreateConVar("playerscaling_clipping", 1, {FCVAR_ARCHIVE}, "Should scaling prevent clipping into objects?", 0, 1) -- If disabled, players may get stuck when growing
    CreateConVar("playerscaling_pause", 1, {FCVAR_ARCHIVE}, "Should scaling pause when stuck until unstuck?", 0, 1) -- If disabled, player scaling may get cancelled even if they were stuck for only a moment
    CreateConVar("playerscaling_view", 1, {FCVAR_ARCHIVE}, "Should scaling change player view offset?", 0, 1) -- If disabled, player view offset will be unnatural
    CreateConVar("playerscaling_step", 1, {FCVAR_ARCHIVE}, "Should scaling change player step size?", 0, 1) -- If disabled, players will have disproportionate step sizes up/down

    -- Scaling parameters
    CreateConVar("playerscaling_maxsize", 25, {FCVAR_ARCHIVE}, "Maximum scaling size (Exceeding 25 not recommended)", 1, 50)
    CreateConVar("playerscaling_minsize", 0.05, {FCVAR_ARCHIVE}, "Minimum scaling size (Setting below 0.05 not recommended)", 0.01, 1)
    CreateConVar("playerscaling_speedlarge", 0.5, {FCVAR_ARCHIVE}, "Upscale speed factor (Higher is faster)", 0, 1)
    CreateConVar("playerscaling_speedsmall", 0.8, {FCVAR_ARCHIVE}, "Downscale speed factor (Higher is faster)", 0, 1)
    CreateConVar("playerscaling_jumplarge", 1, {FCVAR_ARCHIVE}, "Upscale jump factor (Higher is higher jump)", 0, 1)
    CreateConVar("playerscaling_jumpsmall", 0.6, {FCVAR_ARCHIVE}, "Downscale jump factor (Higher is higher jump)", 0, 1)
    CreateConVar("playerscaling_stepsmall", 0.25, {FCVAR_ARCHIVE}, "Minimum downscaled step size", 0, 1)
    CreateConVar("playerscaling_falllarge", 250, {FCVAR_ARCHIVE}, "Upscale fall damage protection (Higher is greater protection)", 0)
end

-- Shared scaling toggles
CreateConVar("playerscaling_gravity", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should scaling affect player gravity?", 0, 1) -- If disabled, large players will fall slowly and small players will fall quickly
CreateConVar("playerscaling_credits", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should addon credits be printed once in client console? (Disabled by default)", 0, 1) -- If enabled, players can see where the addon comes from in console :)

-- Shared scaling parameters
CreateConVar("playerscaling_gravitylarge", 200, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Upscale gravity increase (Higher is stronger)", 0)
CreateConVar("playerscaling_gravitysmall", 500, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Downscale gravity decress (Higher is weaker)", 0)