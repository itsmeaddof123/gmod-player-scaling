--[[File Loader for Player Scaling by Addi--]]

-- Shared files
for k, v in pairs(file.Find("playerscaling/sh_*", "LUA")) do
    if (SERVER) then
        AddCSLuaFile("playerscaling/" .. tostring(v))
    end
    include("playerscaling/" .. tostring(v))
end

-- Server files
if (SERVER) then
    for k, v in pairs(file.Find("playerscaling/sv_*", "LUA")) do
        include("playerscaling/" .. tostring(v))
    end
end

-- Main client files
for k, v in pairs(file.Find("playerscaling/cl_*", "LUA")) do
    if (SERVER) then
        AddCSLuaFile("playerscaling/" .. tostring(v))
    else
        include("playerscaling/" .. tostring(v))
    end
end
