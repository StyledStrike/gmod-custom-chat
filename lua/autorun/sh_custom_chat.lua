CustomChat = CustomChat or {
    DATA_DIR = "custom_chat/",
    MAX_MESSAGE_LENGTH = 500
}

CustomChat.channels = {
    everyone = 0,
    team = 1
}

CreateConVar( "custom_chat_safe_mode", "0", bit.bor( FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY ),
    "Enable safe mode to all players. Only show images after clicking them.", 0, 1 )

CreateConVar( "custom_chat_allow_colors", "1", bit.bor( FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY ),
    "Allows the usage of color formatting options. Recommended to be disabled on servers.", 0, 1 )

CreateConVar( "custom_chat_max_lines", "6", bit.bor( FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY ),
    "Limits how many lines each message can have. Recommended to be low on servers.", 0, 10 )

-- Utility functions

function CustomChat.PrintF( str, ... )
    MsgC( Color( 0, 123, 255 ), "[Custom Chat] ", Color( 255, 255, 255 ), string.format( str, ... ), "\n" )
end

function CustomChat.GetConVarInt( name, default )
    local cvar = GetConVar( "custom_chat_" .. name )
    return cvar and cvar:GetInt() or default
end

function CustomChat.Serialize( tbl )
    return util.TableToJSON( tbl )
end

function CustomChat.Unserialize( str )
    if not str or str == "" then
        return {}
    end

    return util.JSONToTable( str ) or {}
end

function CustomChat.EnsureDataDir()
    if not file.IsDir( CustomChat.DATA_DIR, "DATA" ) then
        file.CreateDir( CustomChat.DATA_DIR )
    end

    local themesDir = CustomChat.DATA_DIR .. "themes/"

    if not file.IsDir( themesDir, "DATA" ) then
        file.CreateDir( themesDir )
    end
end

function CustomChat.LoadDataFile( path )
    return file.Read( CustomChat.DATA_DIR .. path, "DATA" )
end

function CustomChat.SaveDataFile( path, data )
    CustomChat.PrintF( "%s: writing %s", path, string.NiceSize( string.len( data ) ) )
    file.Write( CustomChat.DATA_DIR .. path, data )
end

function CustomChat.IsStringValid( str )
    return type( str ) == "string" and str ~= ""
end

-- You can override these "CanSet" functions if you want.
-- Just make sure to do it both on SERVER and CLIENT.

function CustomChat.CanSetServerTheme( ply )
    return ply:IsSuperAdmin()
end

function CustomChat.CanSetServerEmojis( ply )
    return ply:IsSuperAdmin()
end

function CustomChat.CanSetChatTags( ply )
    return ply:IsSuperAdmin()
end

-- UTF8 cleanup lookup table provided by EasyChat
local lookup = {
    -- zero width chars
    [utf8.char( 0x200b )] = "", -- ZERO WIDTH SPACE
    [utf8.char( 0x200c )] = "", -- ZERO WIDTH NON JOINER
    [utf8.char( 0x200d )] = "", -- ZERO WIDTH JOINER
    [utf8.char( 0x2060 )] = "", -- WORD JOINER

    -- spaces
    [utf8.char( 0x00a0 )] = " ", -- NO BREAK SPACE
    [utf8.char( 0x1680 )] = "  ", -- OGHAM SPACE MARK
    [utf8.char( 0x2000 )] = "  ", -- EN QUAD
    [utf8.char( 0x2001 )] = "   ", -- EM QUAD
    [utf8.char( 0x2002 )] = "  ", -- EN SPACE
    [utf8.char( 0x2003 )] = "   ", -- EM SPACE
    [utf8.char( 0x2004 )] = " ", -- THREE PER EM SPACE
    [utf8.char( 0x2005 )] = " ", -- FOUR PER EM SPACE
    [utf8.char( 0x2006 )] = " ", -- SIX PER EM SPACE
    [utf8.char( 0x2007 )] = "  ", -- FIGURE SPACE
    [utf8.char( 0x2008 )] = " ", -- PUNCTUATION SPACE
    [utf8.char( 0x2009 )] = " ", -- THIN SPACE
    [utf8.char( 0x200a )] = " ", -- HAIR SPACE
    [utf8.char( 0x2028 )] = "\n", -- LINE SEPARATOR
    [utf8.char( 0x2029 )] = "\n\n", -- PARAGRAPH SEPARATOR
    [utf8.char( 0x202f )] = " ", -- NARROW NO BREAK SPACE
    [utf8.char( 0x205f )] = " ", -- MEDIUM MATHEMATICAL SPACE
    [utf8.char( 0x3000 )] = "   ", -- IDEOGRAPHIC SPACE
    [utf8.char( 0x03164 )] = "  ", -- HANGUL FILLER
    [utf8.char( 0x0e00aa )] = "", -- UNKNOWN CHAR MOST FONTS RENDER AS NOTHING

    -- control chars
    [utf8.char( 0x03 )] = "^C", -- END OF TEXT
    [utf8.char( 0x2067 )] = "" -- Right-To-Left Isolate
}

function CustomChat.CleanupString( str )
    if not str then return "" end

    str = utf8.force( str )

    for unicode, replacement in pairs( lookup ) do
        str = str:gsub( unicode, replacement )
    end

    -- limit the number of line breaks
    local max = CustomChat.GetConVarInt( "max_lines", 5 )
    local breaks = 0

    str = str:gsub( "\n", function()
        breaks = breaks + 1

        return breaks > max and "" or "\n"
    end )

    return str:Trim()
end

if SERVER then
    -- Libraries
    require( "styled_netprefs" )
    AddCSLuaFile( "includes/modules/styled_netprefs.lua" )

    -- Shared files
    include( "custom_chat/shared/migrate_data.lua" )
    include( "custom_chat/shared/override_istyping.lua" )
    AddCSLuaFile( "custom_chat/shared/migrate_data.lua" )
    AddCSLuaFile( "custom_chat/shared/override_istyping.lua" )

    -- Server files
    include( "custom_chat/server/config.lua" )
    include( "custom_chat/server/main.lua" )

    -- Send client files
    AddCSLuaFile( "custom_chat/client/block_types.lua" )
    AddCSLuaFile( "custom_chat/client/config.lua" )
    AddCSLuaFile( "custom_chat/client/emojis.lua" )
    AddCSLuaFile( "custom_chat/client/highlighter.lua" )
    AddCSLuaFile( "custom_chat/client/parser.lua" )
    AddCSLuaFile( "custom_chat/client/tags.lua" )
    AddCSLuaFile( "custom_chat/client/theme.lua" )
    AddCSLuaFile( "custom_chat/client/whitelist.lua" )
    AddCSLuaFile( "custom_chat/client/main.lua" )

    AddCSLuaFile( "custom_chat/client/vgui/chat_frame.lua" )
    AddCSLuaFile( "custom_chat/client/vgui/chat_history.lua" )
    AddCSLuaFile( "custom_chat/client/vgui/tag_parts_editor.lua" )
    AddCSLuaFile( "custom_chat/client/vgui/theme_editor.lua" )
end

if CLIENT then
    -- Client specific utilities
    function CustomChat.ChopEnds( str, n )
        return str:sub( n, -n )
    end

    function CustomChat.RGBToJs( c )
        return string.format( "rgb(%d,%d,%d)", c.r, c.g, c.b )
    end

    function CustomChat.RGBAToJs( c )
        return string.format( "rgba(%d,%d,%d,%02.2f)", c.r, c.g, c.b, c.a / 255 )
    end

    function CustomChat.AddLine( t, line, ... )
        t[#t + 1] = line:format( ... )
    end

    function CustomChat.GetLanguageText( id )
        return language.GetPhrase( "custom_chat." .. id )
    end

    -- Libraries
    require( "styled_netprefs" )

    -- Shared files
    include( "custom_chat/shared/migrate_data.lua" )
    include( "custom_chat/shared/override_istyping.lua" )

    -- Client files
    include( "custom_chat/client/block_types.lua" )
    include( "custom_chat/client/config.lua" )
    include( "custom_chat/client/emojis.lua" )
    include( "custom_chat/client/highlighter.lua" )
    include( "custom_chat/client/parser.lua" )
    include( "custom_chat/client/tags.lua" )
    include( "custom_chat/client/theme.lua" )
    include( "custom_chat/client/whitelist.lua" )
    include( "custom_chat/client/main.lua" )

    include( "custom_chat/client/vgui/chat_frame.lua" )
    include( "custom_chat/client/vgui/chat_history.lua" )
    include( "custom_chat/client/vgui/tag_parts_editor.lua" )
    include( "custom_chat/client/vgui/theme_editor.lua" )
end
