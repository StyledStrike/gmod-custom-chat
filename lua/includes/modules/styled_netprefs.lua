local NetPrefs = _G.NetPrefs or {
    values = {},
    MAX_KEY_LENGTH = 32,
    MAX_VALUE_SIZE = 1024 * 40
}

_G.NetPrefs = NetPrefs

--- Gets a value saved on the server.
function NetPrefs.Get( key, default )
    return NetPrefs.values[key] or default
end

--- Calculates the size (in bytes) of a value after being compressed.
function NetPrefs.CalculateValueSize( value )
    if type( value ) ~= "string" then
        ErrorNoHalt( "Only string values are supported." )
        return
    end

    return string.len( util.Compress( value ) or "" )
end

if SERVER then
    util.AddNetworkString( "netprefs.sync_value" )

    -- store players who we should send values to
    local queue = {}

    local function QueueItem( key, target )
        -- if this key was queued to be sent to the same target before,
        -- or we are sending to all players, remove duplicates from the queue
        for i = #queue, 1, -1 do
            local item = queue[i]

            if key == item.key and ( target == "all" or target == item.target ) then
                table.remove( queue, i )
            end
        end

        queue[#queue + 1] = { key = key, target = target }
    end

    --- Sets a value on the server. Only supports strings.
    function NetPrefs.Set( key, value )
        if type( value ) ~= "string" then
            ErrorNoHalt( "Only string values are supported." )
            return
        end

        if string.len( key ) > NetPrefs.MAX_KEY_LENGTH then
            ErrorNoHalt( "Key is too long, max. " .. NetPrefs.MAX_KEY_LENGTH .. " characters." )
            return
        end

        local compressedSize = NetPrefs.CalculateValueSize( value )

        if compressedSize > NetPrefs.MAX_VALUE_SIZE then
            ErrorNoHalt( "Value is too big, max. " .. string.NiceSize( NetPrefs.MAX_VALUE_SIZE ) )
            return
        end

        NetPrefs.values[key] = value

        if player.GetCount() > 0 then
            QueueItem( key, "all" )
        end

        hook.Run( "NetPrefs_OnChange", key, value )
    end

    timer.Create( "NetPrefs.AutoSync", 0.3, 0, function()
        if #queue == 0 then return end

        local item = table.remove( queue, 1 )

        -- skip if there are no players
        if player.GetCount() == 0 then return end

        -- skip disconnected players
        if item.target ~= "all" and not IsValid( item.target ) then return end

        local value = util.Compress( NetPrefs.values[item.key] )
        local valueSize = #value

        net.Start( "netprefs.sync_value", false )
        net.WriteString( item.key )
        net.WriteUInt( valueSize, 16 )
        net.WriteData( value, valueSize )

        if item.target == "all" then
            net.Broadcast()
        else
            net.Send( item.target )
        end
    end )

    -- The sheer amount of workarounds here...
    -- Since PlayerInitialSpawn is called before the player is ready
    -- to receive net events, we have to use ClientSignOnStateChanged instead.
    hook.Add( "ClientSignOnStateChanged", "NetPrefs.SendValues", function( user, _, new )
        if new ~= SIGNONSTATE_FULL then return end

        -- We can only retrieve the player entity after this hook runs, so lets use a timer.
        -- It could have been 0, its just higher here to strain the network a bit less.
        timer.Simple( 5, function()
            local ply = Player( user )

            if not IsValid( ply ) then return end
            if ply:IsBot() then return end

            -- Queue all values to be sent to this player
            for k, _ in pairs( NetPrefs.values ) do
                QueueItem( k, ply )
            end
        end )
    end )
end

if CLIENT then
    local function PrintF( str, ... )
        MsgC( Color( 76, 0, 255 ), "[NetPrefs] ", Color( 255, 255, 255 ), string.format( str, ... ), "\n" )
    end

    net.Receive( "netprefs.sync_value", function()
        local key = net.ReadString()
        local valueSize = net.ReadUInt( 16 )
        local value = net.ReadData( valueSize )

        value = util.Decompress( value )

        NetPrefs.values[key] = value
        PrintF( "Synchronized key '%s'", key )

        hook.Run( "NetPrefs_OnChange", key, value )
    end )
end
