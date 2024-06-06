--- This file contains utilities to turn blocks into Javascript code.

local Find = string.find
local Format = string.format
local Substring = string.sub
local SafeString = string.JavascriptSafe

local Append = CustomChat.AppendString
local ColorToRGB = CustomChat.ColorToRGB
local IsStringValid = CustomChat.IsStringValid

-- Force plain HTTP for certain image links when Chromium is not in use
local forceHTTP

if BRANCH == "unknown" then
    CustomChat.Print( "Not using Chromium, enforcing plain HTTP for some image links." )

    forceHTTP = {
        ["avatars.cloudflare.steamstatic.com"] = true,
        ["avatars.akamai.steamstatic.com"] = true,
        ["media.discordapp.net"] = true,
        ["cdn.discordapp.com"] = true -- seems like it still does not work
    }
end

--[[
    Utilities to create HTML elements
]]

local Create = {}

--- Utility to generate unique IDs for embeds.
function CustomChat:GenerateEmbedID()
    local embedId = ( self.lastEmbedId or 0 ) + 1
    self.lastEmbedId = embedId
    return embedId
end

--- Received a response from our metadata fetcher
function CustomChat.OnHTTPResponse( embedId, body, url, panel )
    if not IsValid( panel ) then return end

    local metaTags = {}
    local metaPatt = "<meta[%g%s]->"

    for s in string.gmatch( body, metaPatt ) do
        metaTags[#metaTags + 1] = s
    end

    if #metaTags == 0 then return end

    local props = {}

    for _, meta in ipairs( metaTags ) do
        -- Try to find any content on this meta tag
        local _, _, content = Find( meta, "content=\"([%g%s]-)\"" )

        -- Try to find the meta tag name for Facebook
        local _, _, name = Find( meta, "property=\"og:([%g]-)\"" )

        -- Try to find the meta tag name for Twitter/X
        if not name then
            _, _, name = Find( meta, "name=\"twitter:([%g]-)\"" )
        end

        if name and content then
            props[name] = content
        end
    end

    local _, site = string.match( url, "^(%w-)://([^/]*)/?" )

    -- Replace the content of existing embeds
    -- with what we got from the internet
    local lines = { ( [[
        var embedElements = document.getElementsByClassName('%s');

        for (var i = 0; i < embedElements.length; i++) {
            var elEmbed = embedElements[i];
            elEmbed.textContent = "";
            elEmbed.className = "embed %s";
        ]] ):format( embedId, embedId )
    }

    -- Embed thumbnail
    if props["image"] then
        if Substring( props["image"], 1, 2 ) == "//" then
            props["image"] = "https:" .. props["image"]
        end

        Append( lines, Create.Element( "img", "elImg", "elEmbed" ) )
        Append( lines, "elImg.className = 'embed-thumb';" )
        Append( lines, "elImg.src = '%s';", SafeString( props["image"] ) )
    end

    Append( lines, Create.Element( "section", "elEmbedBody", "elEmbed" ) )
    Append( lines, "elEmbedBody.className = 'embed-body';" )

    if props["site_name"] then
        Append( lines, Create.Element( "h1", "elName", "elEmbedBody" ) )
        Append( lines, "elName.innerHTML = '%s';", SafeString( props["site_name"] ) )
    end

    -- Embed title
    local title = props["title"] or site

    if title:len() > 50 then
        title = title:Left( 47 ) .. "..."
    end

    Append( lines, Create.Element( "h2", "elTitle", "elEmbedBody" ) )
    Append( lines, "elTitle.innerHTML = '%s';", SafeString( title ) )

    -- Embed description
    local desc = props["description"] or url

    if desc:len() > 100 then
        desc = desc:Left( 97 ) .. "..."
    end

    Append( lines, Create.Element( "i", "elDesc", "elEmbedBody" ) )
    Append( lines, "elDesc.innerHTML = '%s';", SafeString( desc ) )
    Append( lines, "}" )

    panel:QueueJavascript( table.concat( lines, "\n" ) )
end

--- Returns JS code to create an element,
--- and make it a child of another one.
---
--- tag string Element tag type
--- myVar string Element's variable
--- parentVar string Element's parent variable ("message" by default)
function Create.Element( tag, myVar, parentVar )
    parentVar = parentVar or "message"

    return Format( [[
var %s = document.createElement('%s');
%s.appendChild(%s);
    ]], myVar, tag, parentVar, myVar )
end

--- Returns JS code to create a text element.
--- Optionally, it can act as a clickable link.
function Create.Text( text, font, link, color, bgColor, cssClass )
    local lines = { Create.Element( "span", "elText" ) }

    Append( lines, "elText.textContent = '%s';", SafeString( text ) )

    if IsStringValid( font ) then
        Append( lines, "elText.style.fontFamily = '%s';", font )
    end

    if IsStringValid( link ) then
        Append( lines, "elText.onclick = function(){ CChat.OnClickLink('%s') };", SafeString( link ) )
        Append( lines, "elText.clickableText = true;" )
        Append( lines, "elText.style.cursor = 'pointer';" )
    end

    if cssClass then
        Append( lines, "elText.className = '%s';", cssClass )
    end

    if color and color ~= color_white then
        Append( lines, "elText.style.color = '%s';", ColorToRGB( color ) )
    end

    if bgColor then
        Append( lines, "elText.style.backgroundColor = '%s';", ColorToRGB( bgColor ) )
    end

    return table.concat( lines, "\n" )
end

--- Returns JS code to create a image element.
--- Optionally, it can act as a clickable link
function Create.Image( url, link, cssClass, altText, safeFilter )
    if forceHTTP then
        local prefix, site = string.match( url, "^(%w-)://([^/]*)/" )

        if site and prefix == "https" and forceHTTP[site] then
            CustomChat.Print( "Forcing plain HTTP for %s", site )
            url = "http" .. Substring( url, 6 )
        end
    end

    url = SafeString( url )

    local lines = {}

    if safeFilter then
        local embedId = CustomChat:GenerateEmbedID()
        local safeguardId = "safeguard_" .. embedId

        Append( lines, Create.Element( "span", "elSafeguard" ) )
        Append( lines, "elSafeguard.className = 'safeguard';" )

        Append( lines, Create.Element( "img", "elImg", "elSafeguard" ) )

        Append( lines, Create.Element( "span", "elHint", "elSafeguard" ) )
        Append( lines, "elHint.id = '%s';", safeguardId )
        Append( lines, "elHint.className = 'safeguard-hint';" )
        Append( lines, "elHint.textContent = '%s';", CustomChat.GetLanguageText( "click_to_reveal" ) )
        Append( lines, "elHint.onclick = function(){ RemoveElementById('%s'); };", safeguardId )
    else
        Append( lines, Create.Element( "img", "elImg" ) )
    end

    Append( lines, "elImg.src = '%s';", url )

    if link then
        link = SafeString( link )
        Append( lines, "elImg.onclick = function(){ CChat.OnClickLink('%s') };", link )
    end

    if cssClass then
        Append( lines, "elImg.className = '%s';", cssClass )
    end

    if altText then
        Append( lines, "elImg.alt = '%s';", altText )
    end

    return table.concat( lines, "\n" )
end

-- Background color for code snippets
local CODE_BG_COLOR = Color( 47, 49, 54, 255 )

--- Returns JS code that creates a block of code
function Create.Code( code, font, inline )
    local lines = { Create.Element( "span", "elCode" ) }

    Append( lines, "elCode.className = '%s';", inline and "code-line" or "code" )
    Append( lines, "elCode.style.backgroundColor = '%s';", ColorToRGB( CODE_BG_COLOR ) )

    font = IsStringValid( font ) and font or "monospace"

    -- "highlight" the code, creating child elements for each token
    local tokens = CustomChat.TokenizeCode( code )

    for _, t in ipairs( tokens ) do
        lines[#lines + 1] = Create.Element( "span", "elToken", "elCode" )

        Append( lines, "elToken.textContent = '%s';", SafeString( t.value ) )
        Append( lines, "elToken.style.color = '%s';", t.color )
        Append( lines, "elToken.style.fontFamily = '%s';", font )
    end

    return table.concat( lines, "\n" )
end

--- Returns JS code that creates a box to display website metadata.
function Create.Embed( url, panel )
    local embedId = "embed_" .. CustomChat:GenerateEmbedID()

    HTTP( {
        url = url,
        method = "GET",

        success = function( code, body )
            code = tostring( code )

            local isHTML = body:len() > 15 and body:sub( 1, 15 ) == "<!DOCTYPE html>"
            if not isHTML and code:sub( 1, 1 ) ~= "2" then return end

            CustomChat.OnHTTPResponse( embedId, body, url, panel )
        end
    } )

    url = SafeString( url )

    local lines = { Create.Element( "p", "elEmbed" ) }

    Append( lines, "elEmbed.className = '%s';", "link " .. embedId )
    Append( lines, "elEmbed.textContent = '%s';", url )
    Append( lines, "elEmbed.onclick = function(){ CChat.OnClickLink('%s') };", url )

    return table.concat( lines, "\n" )
end

--[[
    Steam avatar fetcher
]]

-- Avatar URL cache
local avatarCache = {}

-- Avatar placeholder until we are done fetching the player's avatar
local avatarPlaceholder = "asset://garrysmod/materials/icon16/user.png"

local function ExtractAvatarFromXML( data )
    local urlPattern = "<!%[CDATA%[(https://[%g%.]+/[%g]+%.jpg)%]%]>"
    local _, _, url = Find( data, "<avatarMedium>" .. urlPattern .. "</avatarMedium>"  )

    if not url then
        _, _, url = Find( data, "<avatarIcon>" .. urlPattern .. "</avatarIcon>"  )
    end

    return url
end

--- Make sure this URL returns a successful status code.
local function ValidateURL( url, callback )
    HTTP( {
        url = url,
        method = "GET",

        success = function( code )
            callback( code < 400 )
        end,

        failed = function()
            callback( false )
        end
    } )
end

--- Replace the image source of existing avatars for a specific SteamID.
local function UpdateAllAvatars( panel, steamId64, url )
    if not IsValid( panel ) then return end

    local code = (
        [[var avatarElements = document.getElementsByClassName('ply-%s');

        for (var i = 0; i < avatarElements.length; i++) {
            avatarElements[i].src = '%s';
        }]]
    ):format( steamId64, url )

    panel:QueueJavascript( code )
end

function CustomChat.FetchUserAvatarURL( id, panel )
    if not id then
        return avatarPlaceholder
    end

    local url = avatarCache[id]

    if url and url ~= "" then
        return url
    end

    -- Prevent fetching the same user
    -- multiple times at the same time
    if url == "" then
        return avatarPlaceholder
    end

    avatarCache[id] = ""

    CustomChat.Print( "Fetching profile data for %s", id )

    local OnFail = function( reason )
        CustomChat.Print( "Failed to fetch avatar for %s: %s", id, reason )
        avatarCache[id] = nil
    end

    HTTP( {
        url = string.format( "https://steamcommunity.com/profiles/%s?xml=true", id ),
        method = "GET",

        success = function( code, body )
            if not body or code ~= 200 then
                OnFail( "Non-OK code or empty profile data" )
                return
            end

            -- Is the panel still available?
            if not IsValid( panel ) then return end

            url = ExtractAvatarFromXML( body )

            if url then
                if forceHTTP then
                    url = "http" .. Substring( url, 6 )
                end

                CustomChat.Print( "Fetching avatar image for %s: %s", id, url )

                ValidateURL( url, function( success )
                    if success then
                        avatarCache[id] = url

                        CustomChat.Print( "Got avatar for %s", id )
                        UpdateAllAvatars( panel, id, url )
                    else
                        OnFail( "Failed to fetch avatar image" )
                    end
                end )
            else
                OnFail( "Missing avatar URL from the XML data" )
            end
        end,

        failed = OnFail
    } )

    return avatarPlaceholder
end

--[[
    Block registry
]]

local blocks = CustomChat.blocks or {}

CustomChat.blocks = blocks

-- Used to test if a URL probably points to a image
local imageExtensions = { "png", "jpg", "jpeg", "gif", "webp", "svg" }

local function GetURLType( url )
    local withoutQueryStrings = url:gsub( "%?[^/]+", "" ):lower()

    for _, ext in ipairs( imageExtensions ) do
        if withoutQueryStrings:EndsWith( ext ) then
            return "image"
        end
    end

    return "url"
end

local ChopEnds = CustomChat.ChopEnds

blocks["string"] = function( value, ctx )
    return Create.Text( value, ctx.font, nil, ctx.color )
end

blocks["player"] = function( value, ctx )
    local lines = {}

    if not value.isBot and ctx.panel.displayAvatars then
        lines[#lines + 1] = Create.Image( CustomChat.FetchUserAvatarURL( value.id64, ctx.panel ), nil, "avatar ply-" .. value.id64 )
    end

    lines[#lines + 1] = Create.Element( "span", "elPlayer" )
    Append( lines, "elPlayer.textContent = '%s';", SafeString( value.name ) )

    if not value.isBot then
        Append( lines, "elPlayer._playerData = '%s';", util.TableToJSON( {
            steamId = value.id,
            steamId64 = value.id64
        } ) )

        Append( lines, "elPlayer.style.cursor = 'pointer';" )
        Append( lines, "elPlayer.clickableText = true;" )
    end

    if IsStringValid( ctx.font ) then
        Append( lines, "elPlayer.style.fontFamily = '%s';", ctx.font )
    end

    local color = ctx.color

    if IsValid( value.ply ) then
        if CustomChat.USE_TAGS then
            local nameColor = CustomChat.Tags:GetNameColor( value.ply )
            if nameColor then color = nameColor end

        elseif value.ply.getChatTag then
            -- aTags support
            local _, _, nameColor = value.ply:getChatTag()
            if nameColor then color = nameColor end
        end
    end

    if color then
        Append( lines, "elPlayer.style.color = '%s';", ColorToRGB( color ) )

        if ctx.panel.displayAvatars then
            Append( lines, "elImg.style['border-color'] = '%s';", ColorToRGB( color ) )
        end
    end

    return table.concat( lines, "\n" )
end

blocks["emoji"] = function( value, ctx )
    local url = CustomChat.GetEmojiURL( value:sub( 2, -2 ) )

    if url then
        return Create.Image( url, nil, "emoji", value )
    end

    return Create.Text( value, ctx.font, nil, ctx.color )
end

blocks["model"] = function( value, ctx )
    local js = ""
    local iconPath = "materials/spawnicons/" .. string.Replace( value, ".mdl", ".png" )

    if file.Exists( iconPath, "GAME" ) then
        js = Create.Image( "asset://garrysmod/" .. iconPath, nil, "emoji" )
    end

    return js .. Create.Text( value, ctx.font, nil, ctx.color )
end

blocks["url"] = function( value, ctx )
    local urlType = GetURLType( value )
    local canEmbed = false

    local lastMessage = CustomChat.lastReceivedMessage

    if value:sub( 1, 8 ) == "asset://" then
        canEmbed = true

    elseif lastMessage and IsValid( lastMessage.speaker ) then
        canEmbed = hook.Run( "CanEmbedCustomChat", lastMessage.speaker, value, urlType ) ~= false
    end

    if canEmbed and CustomChat.IsWhitelisted( value ) then
        if urlType == "image" then
            return Create.Image( value, value, nil, value, CustomChat.GetConVarInt( "safe_mode", 1 ) > 0 )
        else
            return Create.Embed( value, ctx.panel )
        end
    end

    return Create.Text( value, ctx.font, value, Color( 50, 100, 255 ) )
end

blocks["hyperlink"] = function( value, ctx )
    local label = string.match( value, "%[[%s%g]+%]" )
    local url = string.match( value, "%(https?://[^'\">%s]+%)" )

    label = ChopEnds( label, 2 )
    url = ChopEnds( url, 2 )

    return Create.Text( label, ctx.font, url, ctx.color, nil, "hyperlink" )
end

blocks["spoiler"] = function( value, ctx )
    return Create.Text( ChopEnds( value, 3 ), ctx.font, nil, nil, nil, "spoiler" )
end

blocks["bold"] = function( value, ctx )
    return Create.Text( ChopEnds( value, 3 ), ctx.font, nil, ctx.color, nil, "b-text" )
end

blocks["italic"] = function( value, ctx )
    return Create.Text( ChopEnds( value, 2 ), ctx.font, nil, ctx.color, nil, "i-text" )
end

blocks["bold_italic"] = function( value, ctx )
    return Create.Text( ChopEnds( value, 4 ), ctx.font, nil, ctx.color, nil, "b-text i-text" )
end

blocks["code_line"] = function( value, ctx )
    return Create.Code( ChopEnds( value, 2 ), ctx.font, true )
end

blocks["code"] = function( value, ctx )
    value = ChopEnds( value, value[1] == "{" and 3 or 4 )
    value = value:gsub( "[\n\r]-", "" ) -- trim line breaks

    return Create.Code( value:Trim(), ctx.font, false )
end

blocks["rainbow"] = function( value, ctx )
    return Create.Text( ChopEnds( value, 3 ), ctx.font, nil, nil, nil, "rainbow" )
end

blocks["advert"] = function( value, ctx )
    value = ChopEnds( value, 3 )

    local lines = {
        Create.Element( "span", "elAdvert" ),
        "elAdvert.className = 'advert';",
        Create.Element( "p", "elText", "elAdvert" )
    }

    Append( lines, "elText.textContent = '%s';", SafeString( value ) )
    Append( lines, "elText.style.color = '%s';", ColorToRGB( ctx.color ) )

    return table.concat( lines, "\n" )
end
