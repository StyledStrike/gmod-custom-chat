local SafeString = string.JavascriptSafe
local ChopEnds = function( s, n ) return string.sub( s, n, -n ) end

local JSBuilder = {
    -- list of functions that convert blocks into JS code
    builders = {},

    -- the main element that represents a single message,
    -- and is the parent for all of it's blocks
    rootElement = "elMessage",

    -- background color for code snippets
    codeBackgroundColor = Color( 47, 49, 54, 255 )
}

-- list of fonts usable on messages
local fontNames = {
    ["monospace"] = "monospace",
    ["lucida"] = "Lucida Console",
    ["comic"] = "Comic Sans MS",
    ["arial"] = "Arial",
    ["calibri"] = "Calibri",
    ["consolas"] = "Consolas",
    ["impact"] = "Impact",
    ["symbol"] = "Symbol",
    ["helvetica"] = "Helvetica Neue",
    ["sugoe"] = "Sugoe Script",
    ["roboto"] = "Roboto"
}

-- Generates JS code that creates a message element based on "contents".
-- "contents" must be a sequential table, containing strings, colors, and/or player entities.
function SChat:GenerateMessageFromTable( contents )
    local playerNicks = {}

    for _, ply in ipairs( player.GetAll() ) do
        playerNicks[ply:Nick()] = true
    end

    -- first, lets split the message contents into "blocks"
    local blocks = {}

    local function addBlock( type, value )
        blocks[#blocks + 1] = {
            type = type,
            value = value
        }
    end

    for _, obj in ipairs( contents ) do
        if type( obj ) == "table" then
            if obj.r and obj.g and obj.b then
                addBlock( "color", obj )
            else
                addBlock( "string", tostring( obj ) )
            end

        elseif type( obj ) == "string" then
            -- if obj is a player name...
            if playerNicks[obj] then
                -- add it as a plain string (maybe do a "mention" system later?)
                addBlock( "string", obj )
            else
                -- otherwise find more blocks using patterns
                SChat:ParseString( obj, addBlock )
            end

        elseif type( obj ) == "Player" and IsValid( obj ) then
            local nameColor = team.GetColor( obj:Team() )

            -- aTags support
            if obj.getChatTag then
                _, _, nameColor = obj:getChatTag()
            end

            addBlock( "color", nameColor )
            addBlock( "string", obj:Nick() )
        else
            addBlock( "string", tostring( obj ) )
        end
    end

    -- then, convert the blocks into JS code,
    -- and it will create the HTML elements for us
    local lines = {
        ( "var %s = document.createElement('div');" ):format( JSBuilder.rootElement )
    }

    if self.Settings.timestamps then
        local code = [[
            var elTimestamp = document.createElement('span');
            %s.appendChild(elTimestamp);
            elTimestamp.className = 'timestamp';
            elTimestamp.textContent = '%s ';
        ]]

        lines[#lines + 1] = code:format( JSBuilder.rootElement, os.date( "%H:%M:%S" ) )
    end

    local currentColor = color_white
    local currentFont = ""

    for _, b in ipairs( blocks ) do
        if b.type == "font" then
            local newFont = ChopEnds( b.value, 2 )
            if fontNames[newFont] then
                currentFont = fontNames[newFont]
            end

        elseif b.type == "color" then
            if type( b.value ) == "string" then
                local colorStr = ChopEnds( b.value, 2 )
                local colorTbl = string.Explode( ",", colorStr, false )

                currentColor = Color(
                    math.Clamp( tonumber( colorTbl[1] ) or 0, 0, 255 ),
                    math.Clamp( tonumber( colorTbl[2] ) or 0, 0, 255 ),
                    math.Clamp( tonumber( colorTbl[3] ) or 0, 0, 255 )
                )
            else
                currentColor = b.value
            end

        else
            local func = JSBuilder.builders[b.type]

            if func then
                lines[#lines + 1] = func( b.value, currentColor, currentFont )
            else
                SChat.PrintF( "Invalid chat block type: %s", b.type )
            end
        end
    end

    -- lets not add this message to the temp container if hud is disabled
    local showTemp = ( GetConVar( "cl_drawhud" ):GetInt() == 0 ) and "false" or "true"
    local showAnim = self.Theme.slideAnimation and "true" or "false"

    lines[#lines + 1] = ( "appendMessage(%s, %s, %s);" ):format( JSBuilder.rootElement, showTemp, showAnim )

    return table.concat( lines, "\n" )
end

-- Generates JS code that populates the emoji panel
function SChat:GenerateEmojiList()
    local emojiCategories = self.Settings.emojiCategories
    local lines = { "elEmojiPanel.textContent = '';" }

    for _, cat in ipairs( emojiCategories ) do
        if #cat.emojis > 0 then
            lines[#lines + 1] = [[
                var emojiCat = document.createElement('div');
                emojiCat.className = 'emoji-category';
                emojiCat.textContent = ']] .. cat.category .. [[';
                elEmojiPanel.appendChild(emojiCat);
            ]]

            for _, emoji in ipairs( cat.emojis ) do
                local isBuiltin = type( emoji ) == "string"

                local id = isBuiltin and emoji or emoji[1]
                local src = isBuiltin and "asset://garrysmod/materials/icon72/" .. emoji .. ".png" or emoji[2]

                lines[#lines + 1] = [[
                    var elEmoji = document.createElement('img');
                    elEmoji.src = ']] .. SafeString( src ) .. [[';
                    elEmoji.className = 'emoji-button';
                    elEmoji.onclick = function(){ SChatBox.OnSelectEmoji(']] .. id .. [[') };
                    elEmojiPanel.appendChild(elEmoji);
                ]]
            end
        end
    end

    return table.concat( lines, "\n" )
end

--[[
    Now, lets add a bunch of functions to turn those blocks into JS
]]

local IsStringValid = function( s ) return s and s ~= "" end
local ColorToJs = function( c ) return string.format( "rgb(%d,%d,%d)", c.r, c.g, c.b ) end
local AddLine = function( t, line, ... ) t[#t + 1] = string.format( line, ... ) end

-- used to test if a URL probably points to a image
local imageExtensions = { "png", "jpg", "jpeg", "gif", "webp", "svg" }

-- used to test if a URL probably points to a sound
local audioExtensions = { "wav", "ogg", "mp3" }

local imagePatterns = {
    "^asset://[^%s%\"%>%<]+",
    "^https?://steamuserimages%-a%.akamaihd%.net/ugc/"
}

local function GetURLType( url )
    for _, patt in ipairs( imagePatterns ) do
        if url:match( patt ) then
            return "image"
        end
    end

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

JSBuilder.builders["string"] = function( val, color, font )
    return JSBuilder:CreateText( val, font, nil, color )
end

JSBuilder.builders["emoji"] = function( val, color, font )
    local path, isOnline = SChat.Settings:GetEmojiInfo( val:sub( 2, -2 ) )

    if path then
        if not isOnline then
            path = "asset://garrysmod/" .. path
        end

        return JSBuilder:CreateImage( path, nil, "emoji", val )
    end

    return JSBuilder:CreateText( val, font, nil, color )
end

JSBuilder.builders["model"] = function( val, color, font )
    local js = ""
    local prevPath = "materials/spawnicons/" .. string.Replace( val, ".mdl", ".png" )

    if file.Exists( prevPath, "GAME" ) then
        js = JSBuilder:CreateImage( "asset://garrysmod/" .. prevPath, nil, "emoji" )
    end

    return js .. JSBuilder:CreateText( val, font, nil, color )
end

JSBuilder.builders["url"] = function( val, _, font )
    local urlType = GetURLType( val )
    local canEmbed = hook.Run( "CanEmbedCustomChat", SChat._lastPlayer, val, urlType ) ~= false

    if canEmbed and SChat:IsWhitelisted( val ) then
        if urlType == "image" then
            local cvarSafeMode = GetConVar( "custom_chat_safe_mode" )
            local safeFilter = ( cvarSafeMode and cvarSafeMode:GetInt() or 0 ) > 0

            return JSBuilder:CreateImage( val, val, nil, val, safeFilter )

        elseif urlType == "audio" and SChat.chatBox then
            return JSBuilder:CreateAudioPlayer( val, font )

        else
            return JSBuilder:CreateEmbed( val )
        end
    end

    return JSBuilder:CreateText( val, font, val, Color( 50, 100, 255 ) )
end

JSBuilder.builders["hyperlink"] = function( val, color, font )
    local label = string.match( val, "%[[%s%g]+%]" )
    local url = string.match( val, "%(https?://[^'\">%s]+%)" )

    label = ChopEnds( label, 2 )
    url = ChopEnds( url, 2 )

    return JSBuilder:CreateText( label, font, url, color, nil, "hyperlink" )
end

JSBuilder.builders["spoiler"] = function( val, _, font )
    return JSBuilder:CreateText( ChopEnds( val, 3 ), font, nil, nil, nil, "spoiler" )
end

JSBuilder.builders["italic"] = function( val, color, font )
    return JSBuilder:CreateText( ChopEnds( val, 2 ), font, nil, color, nil, "i-text" )
end

JSBuilder.builders["bold"] = function( val, color, font )
    return JSBuilder:CreateText( ChopEnds( val, 3 ), font, nil, color, nil, "b-text" )
end

JSBuilder.builders["bold_italic"] = function( val, color, font )
    return JSBuilder:CreateText( ChopEnds( val, 4 ), font, nil, color, nil, "b-text i-text" )
end

JSBuilder.builders["code_line"] = function( val, _, font )
    return JSBuilder:CreateCode( ChopEnds( val, 2 ), font, true )
end

JSBuilder.builders["code"] = function( val, _, font )
    val = string.Replace( val, "\\n", "\n" )
    local chopAmount = val[1] == "{" and 3 or 4
    return JSBuilder:CreateCode( ChopEnds( val, chopAmount ), font, false )
end

JSBuilder.builders["rainbow"] = function( val, _, font )
    return JSBuilder:CreateText( ChopEnds( val, 3 ), font, nil, nil, nil, "tef-rainbow" )
end

JSBuilder.builders["advert"] = function( val, color )
    return JSBuilder:CreateAdvert( ChopEnds( val, 3 ), color )
end

--
-- Returns JS code to create an element,
-- and make it a child of another one.
--
-- tag: the element tag type
-- myVar: the element's variable
-- parentVar: the element's parent variable (JSBuilder.rootElement by default)
--
function JSBuilder:CreateElement( tag, myVar, parentVar )
    parentVar = parentVar or self.rootElement

    return ( [[
        var %s = document.createElement('%s');
        %s.appendChild(%s);
    ]] ):format( myVar, tag, parentVar, myVar )
end

-- Returns JS code to create a text element
-- (optionally, it can act as a clickable link)
function JSBuilder:CreateText( text, font, link, color, bgColor, cssClass )
    local lines = { self:CreateElement( "span", "elText" ) }

    AddLine( lines, "elText.textContent = '%s';", SafeString( text ) )

    if IsStringValid( font ) then
        AddLine( lines, "elText.style.fontFamily = '%s';", font )
    end

    if IsStringValid( link ) then
        AddLine( lines, "elText.onclick = function(){ SChatBox.OnClickLink('%s') };", SafeString( link ) )
        AddLine( lines, "elText.clickableText = true;" )
        AddLine( lines, "elText.style.cursor = 'pointer';" )
        AddLine( lines, "elText.style.wordBreak = 'break-all';" )
    end

    if cssClass then
        AddLine( lines, "elText.className = '%s';", cssClass )
    end

    if color and color ~= color_white then
        AddLine( lines, "elText.style.color = '%s';", ColorToJs( color ) )
    end

    if bgColor then
        AddLine( lines, "elText.style.backgroundColor = '%s';", ColorToJs( bgColor ) )
    end

    return table.concat( lines, "\n" )
end

-- Returns JS code to create a image element
-- (optionally, it can act as a clickable link)
function JSBuilder:CreateImage( url, link, cssClass, altText, safeFilter )
    url = SafeString( url )

    local lines = {}

    if safeFilter then
        self.lastEmbedId = ( self.lastEmbedId or 0 ) + 1

        local safeguardId = "safeguard_" .. self.lastEmbedId

        AddLine( lines, self:CreateElement( "span", "elSafeguard" ) )
        AddLine( lines, "elSafeguard.className = 'safeguard';" )

        AddLine( lines, self:CreateElement( "img", "elImg", "elSafeguard" ) )

        AddLine( lines, self:CreateElement( "span", "elHint", "elSafeguard" ) )
        AddLine( lines, "elHint.className = 'safeguard-hint %s';", safeguardId )
        AddLine( lines, "elHint.textContent = 'Click to reveal image';" )
        AddLine( lines, "elHint.onclick = function(){ removeByClass('%s'); };", safeguardId )
    else
        AddLine( lines, self:CreateElement( "img", "elImg" ) )
    end

    AddLine( lines, "elImg.src = '%s';", url )

    if link then
        link = SafeString( link )

        AddLine( lines, "elImg.onclick = function(){ SChatBox.OnClickLink('%s') };", link )
        AddLine( lines, "elImg.onmouseenter = function(){ SChatBox.OnImageHover('%s', true) };", link )
        AddLine( lines, "elImg.onmouseleave = function(){ SChatBox.OnImageHover('%s', false) };", link )
    end

    if cssClass then
        AddLine( lines, "elImg.className = '%s';", cssClass )
    end

    if cssClass then
        AddLine( lines, "elImg.alt = '%s';", altText )
    end

    return table.concat( lines, "\n" )
end

-- Returns JS code that creates a marquee-like animated text (moving right to left) 
function JSBuilder:CreateAdvert( text, color )
    local lines = {
        self:CreateElement( "span", "elAdvert" ),
        "elAdvert.className = 'advert';",
        self:CreateElement( "p", "elText", "elAdvert" )
    }

    AddLine( lines, "elText.textContent = '%s';", SafeString( text ) )
    AddLine( lines, "elText.style.color = '%s';", ColorToJs( color ) )

    return table.concat( lines, "\n" )
end

-- Returns JS code to create a audio player
function JSBuilder:CreateAudioPlayer( url, font )
    url = SafeString( url )

    local lines = {
        self:CreateText( url, font, url ),
        self:CreateElement( "audio", "elAudio" ),
        [[elAudio.className = 'media-player';
        elAudio.volume = 0.5;
        elAudio.setAttribute('preload', 'none');
        elAudio.setAttribute('controls', 'controls');
        elAudio.setAttribute('controlsList', 'nodownload noremoteplayback');]]
    }

    return table.concat( lines, "\n" )
end

-- Returns JS code that creates a block of code
function JSBuilder:CreateCode( code, font, inline )
    local lines = { self:CreateElement( "span", "elCode" ) }

    AddLine( lines, "elCode.className = '%s';", inline and "code-line" or "code" )
    AddLine( lines, "elCode.style.backgroundColor = '%s';", ColorToJs( JSBuilder.codeBackgroundColor ) )

    font = Either( IsStringValid( font ), font, "monospace" )

    -- "highlight" the code, creating child elements for each token
    local tokens = SChat:GenerateHighlightTokens( code )

    for _, t in ipairs( tokens ) do
        lines[#lines + 1] = self:CreateElement( "span", "elToken", "elCode" )

        AddLine( lines, "elToken.textContent = '%s';", SafeString( t.value ) )
        AddLine( lines, "elToken.style.color = '%s';", t.color )
        AddLine( lines, "elToken.style.fontFamily = '%s';", font )
    end

    return table.concat( lines, "\n" )
end

-- Returns JS code that creates a embed box
function JSBuilder:CreateEmbed( url )
    self.lastEmbedId = ( self.lastEmbedId or 0 ) + 1

    local embedId = "embed_" .. self.lastEmbedId

    HTTP( {
        url = url,
        method = "GET",

        success = function( code, body )
            code = tostring( code )

            if code == "204" or code:sub( 1, 1 ) ~= "2" then
                return
            end

            self:OnHTTPResponse( embedId, body, url )
        end
    } )

    url = SafeString( url )

    local lines = { self:CreateElement( "p", "elEmbed" ) }

    AddLine( lines, "elEmbed.className = '%s';", "link " .. embedId )
    AddLine( lines, "elEmbed.textContent = '%s';", url )
    AddLine( lines, "elEmbed.onclick = function(){ SChatBox.OnClickLink('%s') };", url )

    return table.concat( lines, "\n" )
end

-- Received a response from our metadata fetcher
function JSBuilder:OnHTTPResponse( embedId, body, url )
    local metaTags = {}
    local metaPatt = "<meta[%g%s]->"

    for s in string.gmatch( body, metaPatt ) do
        metaTags[#metaTags + 1] = s
    end

    if #metaTags == 0 then return end

    local props = {}

    for _, meta in ipairs( metaTags ) do
        -- try to find any content on this meta tag
        local _, _, content = string.find( meta, "content=\"([%g%s]-)\"" )

        -- try to find the meta tag name for Facebook
        local _, _, name = string.find( meta, "property=\"og:([%g]-)\"" )

        -- try to find the meta tag name for Twitter
        if not name then
            _, _, name = string.find( meta, "name=\"twitter:([%g]-)\"" )
        end

        if name and content then
            props[name] = content
        end
    end

    local _, site = string.match( url, "^(%w-)://([^/]*)/?" )

    -- replace the content of existing embeds
    -- with what we've got from the internet
    local lines = { ( [[
        var embedElements = document.getElementsByClassName('%s');

        for (var i = 0; i < embedElements.length; i++) {
            var elEmbed = embedElements[i];
            elEmbed.textContent = "";
            elEmbed.className = "embed %s";
        ]] ):format( embedId, embedId )
    }

    if props["image"] then
        AddLine( lines, self:CreateElement( "img", "elImg", "elEmbed" ) )
        AddLine( lines, "elImg.className = 'embed-thumb';" )
        AddLine( lines, "elImg.src = '%s';", SafeString( props["image"] ) )
    end

    AddLine( lines, self:CreateElement( "section", "elEmbedBody", "elEmbed" ) )
    AddLine( lines, "elEmbedBody.className = 'embed-body';" )

    if props["site_name"] then
        AddLine( lines, self:CreateElement( "h1", "elName", "elEmbedBody" ) )
        AddLine( lines, "elName.textContent = '%s';", SafeString( props["site_name"] ) )
    end

    local title = props["title"] or site

    if title:len() > 50 then
        title = title:Left( 47 ) .. "..."
    end

    AddLine( lines, self:CreateElement( "h2", "elTitle", "elEmbedBody" ) )
    AddLine( lines, "elTitle.textContent = '%s';", SafeString( title ) )

    local desc = props["description"] or url

    if desc:len() > 100 then
        desc = desc:Left( 97 ) .. "..."
    end

    AddLine( lines, self:CreateElement( "i", "elDesc", "elEmbedBody" ) )
    AddLine( lines, "elDesc.textContent = '%s';", SafeString( desc ) )
    AddLine( lines, "}" )

    SChat.chatBox:QueueJavascript( table.concat( lines, "\n" ) )
end
