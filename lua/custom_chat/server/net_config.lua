util.AddNetworkString( "customchat.set_theme" )
util.AddNetworkString( "customchat.set_emojis" )
util.AddNetworkString( "customchat.set_tags" )

function CustomChat:SetServerTheme( data, admin )
    CustomChat.Print( "%s %s the server theme.", admin or "Someone", table.IsEmpty( data ) and "removed" or "changed" )

    data.id = nil
    data.name = nil
    data.description = nil

    NetPrefs.Set( "customchat.theme", CustomChat.ToJSON( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_theme.json", NetPrefs.Get( "customchat.theme", "{}" ) )
end

function CustomChat:SetServerEmojis( data, admin )
    CustomChat.Print( "%s %s the server emojis.", admin or "Someone", table.IsEmpty( data ) and "removed" or "changed" )
    NetPrefs.Set( "customchat.emojis", CustomChat.ToJSON( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_emojis.json", NetPrefs.Get( "customchat.emojis", "{}" ) )
end

function CustomChat:SetChatTags( data, admin )
    CustomChat.Print( "%s changed the chat tags.", admin or "Someone" )
    NetPrefs.Set( "customchat.tags", CustomChat.ToJSON( data ) )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( "server_tags.json", NetPrefs.Get( "customchat.tags", "{}" ) )
end

net.Receive( "customchat.set_theme", function( _, ply )
    if CustomChat.CanSetServerTheme( ply ) then
        local themeData = CustomChat.FromJSON( net.ReadString() )
        CustomChat:SetServerTheme( themeData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the server theme." )
    end
end )

net.Receive( "customchat.set_emojis", function( _, ply )
    if CustomChat.CanSetServerEmojis( ply ) then
        local emojiData = CustomChat.FromJSON( net.ReadString() )
        CustomChat:SetServerEmojis( emojiData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the server emojis." )
    end
end )

net.Receive( "customchat.set_tags", function( _, ply )
    if CustomChat.CanSetChatTags( ply ) then
        local tagsData = CustomChat.FromJSON( net.ReadString() )
        CustomChat:SetChatTags( tagsData, ply:Nick() )
    else
        ply:ChatPrint( "CustomChat: You cannot change the chat tags." )
    end
end )
