util.AddNetworkString( "customchat.player_spawned" )

hook.Add( "PlayerInitialSpawn", "CustomChat.BroadcastInitialSpawn", function( ply )
    -- Give some time for other addons to assign the team
    timer.Simple( 3, function()
        if not IsValid( ply ) then return end

        local steamId = ply:SteamID()
        local color = team.GetColor( ply:Team() )

        local time = os.time()
        local absenceLength = 0
        local lastSeen = CustomChat:GetLastSeen( steamId )

        if lastSeen then
            absenceLength = math.max( time - lastSeen, 0 )
        end

        CustomChat:SetLastSeen( steamId, time )

        net.Start( "customchat.player_spawned", false )
        net.WriteUInt( ply:UserID(), 8 )
        net.WriteString( steamId )
        net.WriteString( ply:Nick() )
        net.WriteColor( color, false )
        net.WriteFloat( absenceLength )
        net.Broadcast()
    end )
end, HOOK_LOW )

hook.Add( "ShutDown", "CustomChat.SaveLastSeen", function()
    local time = os.time()

    for _, ply in ipairs( player.GetHumans() ) do
        local steamId = ply:SteamID()

        if steamId then -- Could be nil on the listen server host
            CustomChat:SetLastSeen( steamId, time )
        end
    end
end )
