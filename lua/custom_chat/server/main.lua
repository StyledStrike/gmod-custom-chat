resource.AddWorkshop( "2799307109" )

local LAST_SEEN_TABLE = CustomChat.LAST_SEEN_TABLE

-- Setup "last seen" SQLite table
sql.Query( "CREATE TABLE IF NOT EXISTS " .. LAST_SEEN_TABLE ..
    " ( SteamID TEXT NOT NULL PRIMARY KEY, LastSeen INTEGER NOT NULL );" )

function CustomChat:GetLastSeen( steamId )
    local row = sql.QueryRow( "SELECT LastSeen FROM " .. LAST_SEEN_TABLE .. " WHERE SteamID = '" .. steamId .. "';" )

    if row and row.LastSeen then
        return row.LastSeen
    end
end

function CustomChat:SetLastSeen( steamId, time )
    local row = sql.QueryRow( "SELECT LastSeen FROM " .. LAST_SEEN_TABLE .. " WHERE SteamID = '" .. steamId .. "';" )

    time = math.floor( time )

    if row then
        local success = sql.Query( "UPDATE " .. LAST_SEEN_TABLE ..
            " SET LastSeen = " .. time .. " WHERE SteamID = '" .. steamId .. "';" )

        if success == false then
            CustomChat.Print( "SetLastSeen SQL for player %s failed: %s", steamId, sql.LastError() )
        end
    else
        local success = sql.Query( "INSERT INTO " .. LAST_SEEN_TABLE ..
            " ( SteamID, LastSeen ) VALUES ( '" .. steamId .. "', " .. time .. " );" )

        if success == false then
            CustomChat.Print( "SetLastSeen SQL for player %s failed: %s", steamId, sql.LastError() )
        end
    end
end

function CustomChat:LoadConfig()
    CustomChat.EnsureDataDir()

    local ToJSON, FromJSON = CustomChat.ToJSON, CustomChat.FromJSON
    local LoadDataFile = CustomChat.LoadDataFile

    local themeData = FromJSON( LoadDataFile( "server_theme.json" ) )
    local emojiData = FromJSON( LoadDataFile( "server_emojis.json" ) )
    local tagsData = FromJSON( LoadDataFile( "server_tags.json" ) )

    if not table.IsEmpty( themeData ) then
        NetPrefs.Set( "customchat.theme", ToJSON( themeData ) )
    end

    if not table.IsEmpty( emojiData ) then
        NetPrefs.Set( "customchat.emojis", ToJSON( emojiData ) )
    end

    if not table.IsEmpty( tagsData ) then
        NetPrefs.Set( "customchat.tags", ToJSON( tagsData ) )
    end
end

CustomChat:LoadConfig()
