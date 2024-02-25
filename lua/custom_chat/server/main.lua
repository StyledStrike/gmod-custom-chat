resource.AddWorkshop( "2799307109" )

util.AddNetworkString( "customchat.say" )
util.AddNetworkString( "customchat.player_spawned" )

-- handle message networking 
local sayCooldown = {}

-- Gets a list of all players who can
-- listen to messages from a "speaker".
function CustomChat:GetListeners( speaker, text, channel )
    local targets = {}

    if channel == self.channels.everyone then
        targets = player.GetHumans()

    elseif channel == self.channels.team then
        targets = team.GetPlayers( speaker:Team() )
    end

    local listeners = {}
    local teamOnly = channel ~= CustomChat.channels.everyone

    for _, ply in ipairs( targets ) do
        if hook.Run( "PlayerCanSeePlayersChat", text, teamOnly, ply, speaker ) then
            listeners[#listeners + 1] = ply
        end
    end

    return listeners
end

net.Receive( "customchat.say", function( _, ply )
    local id = ply:AccountID()
    local nextSay = sayCooldown[id] or 0

    if RealTime() < nextSay then return end

    sayCooldown[id] = RealTime() + 0.5

    local channel = net.ReadUInt( 4 )
    local text = net.ReadString()

    if text:len() > CustomChat.MAX_MESSAGE_LENGTH then
        text = text:Left( CustomChat.MAX_MESSAGE_LENGTH )
    end

    text = CustomChat.CleanupString( text )
    text = hook.Run( "PlayerSay", ply, text, channel ~= CustomChat.channels.everyone )

    if not isstring( text ) or text == "" then return end

    hook.Run( "player_say", {
        priority = 1, -- ??
        userid = ply:UserID(),
        text = text,
    } )

    local targets = CustomChat:GetListeners( ply, text, channel )
    if #targets == 0 then return end

    net.Start( "customchat.say", false )
    net.WriteUInt( channel, 4 )
    net.WriteString( text )
    net.WriteEntity( ply )
    net.Send( targets )
end )

hook.Add( "PlayerDisconnected", "CustomChat.SayCooldownCleanup", function( ply )
    sayCooldown[ply:AccountID()] = nil
    CustomChat.Config:SetLastSeen( ply:SteamID(), os.time() )
end )

hook.Add( "PlayerInitialSpawn", "CustomChat.BroadcastInitialSpawn", function( ply )
    local steamId = ply:SteamID()
    local color = team.GetColor( ply:Team() )

    local lastSeen = CustomChat.Config.lastSeen
    local time = os.time()
    local absenceLength = 0

    if lastSeen[steamId] then
        absenceLength = math.max( time - lastSeen[steamId], 0 )
    end

    CustomChat.Config:SetLastSeen( steamId, time )

    net.Start( "customchat.player_spawned", false )
    net.WriteString( steamId )
    net.WriteColor( color, false )
    net.WriteFloat( absenceLength )
    net.Broadcast()
end )

