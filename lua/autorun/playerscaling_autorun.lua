--[[Player Scaling by Addi--]]

-- Shared files
for k, name in ipairs({
    "sh/config.lua",
    "sh/init.lua",
}) do
    if (SERVER) then
        AddCSLuaFile("playerscaling/" .. name)
    end
    include("playerscaling/" .. name)
end

-- Server files
if (SERVER) then
    for k, name in ipairs({
        "sv/init.lua",
    }) do
        include("playerscaling/" .. name)
    end
end

-- Main client files
for k, name in ipairs({
    "cl/init.lua",
}) do
    if (SERVER) then
        AddCSLuaFile("playerscaling/" .. name)
    else
        include("playerscaling/" .. name)
    end
end