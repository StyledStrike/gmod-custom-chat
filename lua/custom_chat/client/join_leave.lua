local JoinLeave = CustomChat.JoinLeave or {
    showConnect = false,
    showDisconnect = false,

    joinColor = { 85, 172, 238 },
    joinPrefix = ":small_blue_diamond:",
    joinSuffix = "is joining the game...",

    leaveColor = { 244, 144, 12 },
    leavePrefix = ":small_orange_diamond:",
    leaveSuffix = "left!",

    botConnectDisconnect = false,
}

CustomChat.JoinLeave = JoinLeave

gameevent.Listen( "player_connect_client" )
gameevent.Listen( "player_disconnect" )

hook.Add( "player_connect_client", "CustomChat.ShowConnectMessages", function( data )
    if not JoinLeave.showConnect then return end

    local c = JoinLeave.joinColor
    local name = data.name
    local steamId = data.networkid
    local isBot = data.bot == 1

    if isBot and not JoinLeave.botConnectDisconnect then return end

    -- Only use a player block if Custom Chat is enabled
    if CustomChat.IsEnabled() then
        name = {
            blockType = "player",
            blockValue = {
                name = data.name,
                id = steamId,
                id64 = util.SteamIDTo64( steamId ),
                isBot = isBot
            }
        }
    end

    chat.AddText(
        Color( 255, 255, 255 ), JoinLeave.joinPrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. steamId .. "> ",
        Color( 255, 255, 255 ), JoinLeave.joinSuffix
    )
end, HOOK_LOW )

hook.Add( "player_disconnect", "CustomChat.ShowDisconnectMessages", function( data )
    if not JoinLeave.showDisconnect then return end

    local c = JoinLeave.leaveColor
    local name = data.name
    local steamId = data.networkid
    local isBot = data.bot == 1

    if isBot and not JoinLeave.botConnectDisconnect then return end

    -- Only use a player block if Custom Chat is enabled
    if CustomChat.IsEnabled() then
        name = {
            blockType = "player",
            blockValue = {
                name = data.name,
                id = steamId,
                id64 = util.SteamIDTo64( steamId ),
                isBot = isBot
            }
        }
    end

    chat.AddText(
        Color( 255, 255, 255 ), JoinLeave.leavePrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. steamId .. "> ",
        Color( 255, 255, 255 ), JoinLeave.leaveSuffix,
        Color( 150, 150, 150 ), " (" .. data.reason .. ")"
    )
end, HOOK_LOW )

local function OnPlayerActivated( ply, steamId, name, color, absenceLength )
    if ply:IsBot() and not JoinLeave.botConnectDisconnect then return end

    -- Only use a player block if Custom Chat is enabled
    if CustomChat.IsEnabled() then
        name = {
            blockType = "player",
            blockValue = {
                name = name,
                id = steamId,
                id64 = ply:SteamID64(),
                isBot = ply:IsBot()
            }
        }
    end

    -- Show a message if this player is a friend
    if
        CustomChat.GetConVarInt( "enable_friend_messages", 0 ) > 0 and
        steamId ~= LocalPlayer():SteamID() and
        ply:GetFriendStatus() == "friend"
    then
        chat.AddText(
            Color( 255, 255, 255 ), ":small_blue_diamond: " .. CustomChat.GetLanguageText( "friend_spawned1" ) .. " ",
            color, name,
            Color( 255, 255, 255 ), " " .. CustomChat.GetLanguageText( "friend_spawned2" )
        )
    end

    if absenceLength < 1 then return end
    if CustomChat.GetConVarInt( "enable_absence_messages", 0 ) == 0 then return end

    -- Show the last time the server saw this player
    local lastSeenTime = CustomChat.NiceTime( math.Round( absenceLength ) )

    chat.AddText(
        color, name,
        Color( 150, 150, 150 ), " " .. CustomChat.GetLanguageText( "last_seen1" ),
        Color( 200, 200, 200 ), " " .. lastSeenTime,
        Color( 150, 150, 150 ), " " .. CustomChat.GetLanguageText( "last_seen2" )
    )
end

net.Receive( "customchat.player_spawned", function()
    local steamId = net.ReadString()
    local name = net.ReadString()
    local color = net.ReadColor( false )
    local absenceLength = net.ReadFloat()

    -- Wait until the player entity is valid, within a few tries
    local timerId = "CustomChat.WaitValid" .. steamId

    -- Try every 1/2 seconds, 20 times, for a total of 10 seconds
    timer.Create( timerId, 0.5, 20, function()
        local ply = player.GetBySteamID( steamId )

        if IsValid( ply ) then
            timer.Remove( timerId )
            OnPlayerActivated( ply, steamId, name, color, absenceLength )
        end
    end )
end )

