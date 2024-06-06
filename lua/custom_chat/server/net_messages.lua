util.AddNetworkString( "customchat.say" )

-- Gets a list of all players who can
-- listen to messages from a "speaker".
local function GetListeners( speaker, text, channel )
    local teamOnly = channel == "team"
    local targets = teamOnly and team.GetPlayers( speaker:Team() ) or player.GetHumans()
    local listeners = {}

    for _, ply in ipairs( targets ) do
        if hook.Run( "PlayerCanSeePlayersChat", text, teamOnly, ply, speaker, channel ) then
            listeners[#listeners + 1] = ply
        end
    end

    return listeners
end

local sayCooldown = {}

net.Receive( "customchat.say", function( _, ply )
    local id = ply:AccountID()
    local nextSay = sayCooldown[id] or 0

    if RealTime() < nextSay then return end

    sayCooldown[id] = RealTime() + 0.5

    local channel = net.ReadString()
    if not CustomChat.IsStringValid( channel ) then return end

    local text = net.ReadString()

    if text:len() > CustomChat.MAX_MESSAGE_LENGTH then
        text = text:Left( CustomChat.MAX_MESSAGE_LENGTH )
    end

    local teamOnly = channel == "team"

    text = CustomChat.CleanupString( text )
    text = hook.Run( "PlayerSay", ply, text, teamOnly )

    if not isstring( text ) or text == "" then return end

    hook.Run( "player_say", {
        priority = 1, -- ??
        userid = ply:UserID(),
        text = text,
        teamonly = teamOnly and 1 or 0,
    } )

    local targets = GetListeners( ply, text, channel )
    if #targets == 0 then return end

    net.Start( "customchat.say", false )
    net.WriteString( channel )
    net.WriteString( text )
    net.WriteEntity( ply )
    net.Send( targets )
end )

hook.Add( "PlayerDisconnected", "CustomChat.SayCooldownCleanup", function( ply )
    sayCooldown[ply:AccountID()] = nil
    CustomChat.Config:SetLastSeen( ply:SteamID(), os.time() )
end )
