--playerscaling = playerscaling or {}
--playerscaling.players = playerscaling.players or {}

-- This was going to be used to edit speeds but I decided to just use the simple functions for now
 --[[hook.Add("Move", "playerscaling_move", function(ply, mv)
    if (not (IsValid(ply) and ply:Alive()) then
        return
    end

    if (not (playerscaling[ply] or not playerscaling[ply].Speed or not playerscaling[ply].Scale)) then
        return
    end

    local speedmult = playerscaling[ply].Scale
    local speed
	
	if (mv:KeyDown(IN_WALK) and ply:IsOnGround()) then
		speed = ply:GetSlowWalkSpeed()
	else
		speed = ply:GetWalkSpeed()
	end

	if (ply:Crouching() and ply:IsOnGround()) then
		speed = speed * ply:GetCrouchedWalkSpeed()
	end

	mv:SetMaxSpeed(speed * speedmult)
	mv:SetMaxClientSpeed(speed * speedmult)
end)--]]