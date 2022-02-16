--- File Loader for Player Scaling by Addi ---

-- Shared files
for k, v in pairs(file.Find("quickbinds/sh_*", "LUA")) do
    if (SERVER) then
        AddCSLuaFile("quickbinds/" .. tostring(v))
    end
    include("quickbinds/" .. tostring(v))
end

-- Server files
if (SERVER) then
    for k, v in pairs(file.Find("quickbinds/sv_*", "LUA")) do
        include("quickbinds/" .. tostring(v))
    end
end

-- Main client files
for k, v in pairs(file.Find("quickbinds/cl_*", "LUA")) do
    if (SERVER) then
        AddCSLuaFile("quickbinds/" .. tostring(v))
    else
        include("quickbinds/" .. tostring(v))
    end
end
