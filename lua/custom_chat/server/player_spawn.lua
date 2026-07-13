util.AddNetworkString( "customchat.player_spawned" )

local connectingSteamIDs = {}
gameevent.Listen( "player_connect" )
hook.Add( "player_connect", "CustomChat.TrackConnectingPlayers", function( data )
    local steamId = data.networkid
    connectingSteamIDs[steamId] = SysTime()
end )

gameevent.Listen( "player_disconnect" )
hook.Add( "player_disconnect", "CustomChat.TrackDisconnectingPlayers", function( data )
    local steamId = data.networkid
    connectingSteamIDs[steamId] = nil
end )

local serverStartTime = SysTime()
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

        local timeToSpawn = 0
        if connectingSteamIDs[steamId] then
            local connectTime = connectingSteamIDs[steamId]
            timeToSpawn = SysTime() - connectTime
        else -- needed for when a player joins from a map transition as they wont trigger the player_connect event.
            timeToSpawn = SysTime() - serverStartTime
        end

        net.Start( "customchat.player_spawned", false )
        net.WriteString( steamId )
        net.WriteString( ply:Nick() )
        net.WriteColor( color, false )
        net.WriteFloat( absenceLength )
        net.WriteFloat( timeToSpawn )
        net.Broadcast()

        hook.Run( "CustomChatPlayerInitialSpawn", ply, steamId, color, absenceLength, timeToSpawn )
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
