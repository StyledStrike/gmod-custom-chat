util.AddNetworkString( "customchat.set_theme" )
util.AddNetworkString( "customchat.set_emojis" )
util.AddNetworkString( "customchat.set_tags" )

local Config = CustomChat.Config or {
    LAST_SEEN_TABLE = "customchat_last_seen"
}

CustomChat.Config = Config

-- Setup SQL tables
sql.Query( "CREATE TABLE IF NOT EXISTS " .. Config.LAST_SEEN_TABLE ..
    " ( SteamID TEXT NOT NULL PRIMARY KEY, LastSeen INTEGER NOT NULL );" )

function Config:Load()
    CustomChat.EnsureDataDir()

    local Serialize, Unserialize = CustomChat.Serialize, CustomChat.Unserialize
    local LoadDataFile = CustomChat.LoadDataFile

    local themeData = Unserialize( LoadDataFile( "server_theme.json" ) )
    local emojiData = Unserialize( LoadDataFile( "server_emojis.json" ) )
    local tagsData = Unserialize( LoadDataFile( "server_tags.json" ) )

    if not table.IsEmpty( themeData ) then
        NetPrefs.Set( "customchat.theme", Serialize( themeData ) )
    end

    if not table.IsEmpty( emojiData ) then
        NetPrefs.Set( "customchat.emojis", Serialize( emojiData ) )
    end

    if not table.IsEmpty( tagsData ) then
        NetPrefs.Set( "customchat.tags", Serialize( tagsData ) )
    end
end

function Config:SetTheme( data, admin )
    CustomChat.PrintF( "%s %s the server theme.", admin or "Someone", table.IsEmpty( data ) and "removed" or "changed" )

    data.id = nil
    data.name = nil
    data.description = nil

    NetPrefs.Set( "customchat.theme", CustomChat.Serialize( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_theme.json", NetPrefs.Get( "customchat.theme", "{}" ) )
end

function Config:SetEmojis( data, admin )
    CustomChat.PrintF( "%s %s the server emojis.", admin or "Someone", table.IsEmpty( data ) and "removed" or "changed" )
    NetPrefs.Set( "customchat.emojis", CustomChat.Serialize( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_emojis.json", NetPrefs.Get( "customchat.emojis", "{}" ) )
end

function Config:SetChatTags( data, admin )
    CustomChat.PrintF( "%s changed the chat tags.", admin or "Someone" )
    NetPrefs.Set( "customchat.tags", CustomChat.Serialize( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_tags.json", NetPrefs.Get( "customchat.tags", "{}" ) )
end

function Config:SetLastSeen( steamId, time )
    local row = sql.QueryRow( "SELECT LastSeen FROM " .. self.LAST_SEEN_TABLE .. " WHERE SteamID = '" .. steamId .. "';" )
    local status = "FAILED"

    time = math.floor( time )

    if row then
        local success = sql.Query( "UPDATE " .. self.LAST_SEEN_TABLE ..
            " SET LastSeen = " .. time .. " WHERE SteamID = '" .. steamId .. "';" )

        if success ~= false then status = "UPDATED" end
    else
        local success = sql.Query( "INSERT INTO " .. self.LAST_SEEN_TABLE ..
            " ( SteamID, LastSeen ) VALUES ( '" .. steamId .. "', " .. time .. " );" )

        if success ~= false then status = "INSERTED" end
    end

    CustomChat.PrintF( "SetLastSeen SQL for player %s: %s", steamId, status )
end

function Config:GetLastSeen( steamId )
    local row = sql.QueryRow( "SELECT LastSeen FROM " .. self.LAST_SEEN_TABLE .. " WHERE SteamID = '" .. steamId .. "';" )

    if row and row.LastSeen then
        return row.LastSeen
    end
end

net.Receive( "customchat.set_theme", function( _, ply )
    if CustomChat.CanSetServerTheme( ply ) then
        local themeData = CustomChat.Unserialize( net.ReadString() )
        Config:SetTheme( themeData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the server theme." )
    end
end )

net.Receive( "customchat.set_emojis", function( _, ply )
    if CustomChat.CanSetServerEmojis( ply ) then
        local emojiData = CustomChat.Unserialize( net.ReadString() )
        Config:SetEmojis( emojiData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the server emojis." )
    end
end )

net.Receive( "customchat.set_tags", function( _, ply )
    if CustomChat.CanSetChatTags( ply ) then
        local tagsData = CustomChat.Unserialize( net.ReadString() )
        Config:SetChatTags( tagsData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the chat tags." )
    end
end )

Config:Load()

do
    -- Migrate old "last seen" data to SQL.
    -- This code will stay here for a month or two.
    local lastSeenData = CustomChat.Unserialize( CustomChat.LoadDataFile( "server_last_seen.json" ) )
    if table.IsEmpty( lastSeenData ) then return end

    CustomChat.PrintF( "Migrating old 'last seen' data to SQL..." )

    local IsNumber = isnumber
    local SteamIDTo64 = util.SteamIDTo64

    for id, time in pairs( lastSeenData ) do
        if IsNumber( time ) and SteamIDTo64( id ) ~= "0" then
            Config:SetLastSeen( id, time )
        end
    end

    local oldPath = CustomChat.DATA_DIR .. "server_last_seen.json"
    local newPath = CustomChat.DATA_DIR .. "backup_server_last_seen.json"

    file.Write( newPath, CustomChat.Serialize( lastSeenData ) )
    file.Delete( oldPath )

    CustomChat.PrintF( "Migration complete. Backup saved to: %s", newPath )
end
