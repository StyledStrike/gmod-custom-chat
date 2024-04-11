--[[
    Add a bunch of functions to turn blocks into JS
]]

local blockTypes = CustomChat.blockTypes or {}

CustomChat.blockTypes = blockTypes

-- used to test if a URL probably points to a image
local imageExtensions = { "png", "jpg", "jpeg", "gif", "webp", "svg" }

-- used to test if a URL probably points to a sound
local audioExtensions = { "wav", "ogg", "mp3" }

local function GetURLType( url )
    local withoutQueryStrings = url:gsub( "%?[^/]+", "" ):lower()

    for _, ext in ipairs( imageExtensions ) do
        if withoutQueryStrings:EndsWith( ext ) then
            return "image"
        end
    end

    for _, ext in ipairs( audioExtensions ) do
        if withoutQueryStrings:EndsWith( ext ) then
            return "audio"
        end
    end

    return "url"
end

local SafeString = string.JavascriptSafe
local IsStringValid = CustomChat.IsStringValid
local ChopEnds = CustomChat.ChopEnds
local RGBToJs = CustomChat.RGBToJs
local AddLine = CustomChat.AddLine

blockTypes["string"] = function( panel, str, color, font )
    return panel:CreateText( str, font, nil, color )
end

blockTypes["player"] = function( panel, data, color, font )
    local lines = {}

    if not data.isBot and panel.displayAvatars then
        lines[#lines + 1] = panel:CreateImage( panel:FetchUserAvatarURL( data.id64 ), nil, "avatar ply-" .. data.id64 )
    end

    lines[#lines + 1] = panel:CreateElement( "span", "elPlayer" )
    AddLine( lines, "elPlayer.textContent = '%s';", SafeString( data.name ) )

    if not data.isBot then
        AddLine( lines, "elPlayer._extraContext = '%s';", util.TableToJSON( {
            steamId = data.id,
            steamId64 = data.id64
        } ) )

        AddLine( lines, "elPlayer.style.cursor = 'pointer';" )
        AddLine( lines, "elPlayer.clickableText = true;" )
    end

    if IsStringValid( font ) then
        AddLine( lines, "elPlayer.style.fontFamily = '%s';", font )
    end

    if IsValid( data.ply ) then
        if CustomChat.USE_TAGS then
            local nameColor = CustomChat.Tags:GetNameColor( data.ply )
            if nameColor then color = nameColor end

        elseif data.ply.getChatTag then
            -- aTags support
            local _, _, nameColor = data.ply:getChatTag()
            if nameColor then color = nameColor end
        end
    end

    if color and color ~= color_white then
        AddLine( lines, "elPlayer.style.color = '%s';", RGBToJs( color ) )

        if panel.displayAvatars then
            AddLine( lines, "elImg.style['border-color'] = '%s';", RGBToJs( color ) )
        end
    end

    return table.concat( lines, "\n" )
end

blockTypes["emoji"] = function( panel, id, color, font )
    local url = CustomChat.GetEmojiURL( id:sub( 2, -2 ) )

    if url then
        return panel:CreateImage( url, nil, "emoji", id )
    end

    return panel:CreateText( id, font, nil, color )
end

blockTypes["model"] = function( panel, path, color, font )
    local js = ""
    local iconPath = "materials/spawnicons/" .. string.Replace( path, ".mdl", ".png" )

    if file.Exists( iconPath, "GAME" ) then
        js = panel:CreateImage( "asset://garrysmod/" .. iconPath, nil, "emoji" )
    end

    return js .. panel:CreateText( path, font, nil, color )
end

blockTypes["url"] = function( panel, url, _, font )
    local urlType = GetURLType( url )
    local canEmbed = false

    if url:sub( 1, 8 ) == "asset://" then
        canEmbed = true

    elseif IsValid( CustomChat.lastSpeaker ) then
        canEmbed = hook.Run( "CanEmbedCustomChat", CustomChat.lastSpeaker, url, urlType ) ~= false
    end

    if canEmbed and CustomChat.IsWhitelisted( url ) then
        if urlType == "image" then
            local safeFilter = CustomChat.GetConVarInt( "safe_mode", 1 ) > 0
            return panel:CreateImage( url, url, nil, url, safeFilter )

        elseif urlType == "audio" then
            return panel:CreateAudioPlayer( url, font )

        else
            return panel:CreateEmbed( url )
        end
    end

    return panel:CreateText( url, font, url, Color( 50, 100, 255 ) )
end

blockTypes["hyperlink"] = function( panel, text, color, font )
    local label = string.match( text, "%[[%s%g]+%]" )
    local url = string.match( text, "%(https?://[^'\">%s]+%)" )

    label = ChopEnds( label, 2 )
    url = ChopEnds( url, 2 )

    return panel:CreateText( label, font, url, color, nil, "hyperlink" )
end

blockTypes["spoiler"] = function( panel, text, _, font )
    return panel:CreateText( ChopEnds( text, 3 ), font, nil, nil, nil, "spoiler" )
end

blockTypes["italic"] = function( panel, text, color, font )
    return panel:CreateText( ChopEnds( text, 2 ), font, nil, color, nil, "i-text" )
end

blockTypes["bold"] = function( panel, text, color, font )
    return panel:CreateText( ChopEnds( text, 3 ), font, nil, color, nil, "b-text" )
end

blockTypes["bold_italic"] = function( panel, text, color, font )
    return panel:CreateText( ChopEnds( text, 4 ), font, nil, color, nil, "b-text i-text" )
end

blockTypes["code_line"] = function( panel, text, _, font )
    return panel:CreateCode( ChopEnds( text, 2 ), font, true )
end

blockTypes["code"] = function( panel, text, _, font )
    local code = ChopEnds( text, text[1] == "{" and 3 or 4 )

    -- trim line breaks from the beginning
    code = code:gsub( "[\n\r]-", "" )

    return panel:CreateCode( code:Trim(), font, false )
end

blockTypes["rainbow"] = function( panel, text, _, font )
    return panel:CreateText( ChopEnds( text, 3 ), font, nil, nil, nil, "tef-rainbow" )
end

blockTypes["advert"] = function( panel, text, color )
    return panel:CreateAdvert( ChopEnds( text, 3 ), color )
end
