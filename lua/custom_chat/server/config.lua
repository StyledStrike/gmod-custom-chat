util.AddNetworkString( "customchat.set_theme" )
util.AddNetworkString( "customchat.set_emojis" )
util.AddNetworkString( "customchat.set_tags" )

local Config = CustomChat.Config or {}

CustomChat.Config = Config

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
