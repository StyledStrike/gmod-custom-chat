local function GetHTMLCode()
return [[<!DOCTYPE html>
<html lang="en-US">
<head><meta charset="utf-8"></head>

<body>
    <pre id="temp" class="container"></pre>
    <pre id="main" class="container"></pre>
    <div id="emojiPanel"></div>
</body>

<script>
var maxMessages = 200;
var temporaryLifetime = 10000;
var isAwesomuim = navigator.userAgent.indexOf("Awesomium") != -1;

var elmBody = document.getElementsByTagName("body")[0];
var elmTemp = document.getElementById("temp");
var elmMain = document.getElementById("main");
var elEmojiPanel = document.getElementById("emojiPanel");

function clearSelection() {
    window.getSelection().empty();
}

function scrollToBottom() {
    elmMain.scrollTop = elmMain.scrollHeight;
}

function isScrollAtBottom() {
    return (elmMain.scrollTop + elmMain.clientHeight + 10) > elmMain.scrollHeight;
}

function setEmojiPanelVisible(tgl) {
    elEmojiPanel.style["display"] = tgl ? "block" : "none";
}

function setChatVisible(tgl) {
    elmBody.style["display"] = tgl ? "block" : "none";

    if (!tgl)
        setEmojiPanelVisible(false);
}

function setDisplayMode(mode) {
    elmTemp.style["visibility"] = (mode == "temp") ? "visible" : "hidden";
    elmMain.style["visibility"] = (mode == "main") ? "visible" : "hidden";

    if (mode == "temp")
        setEmojiPanelVisible(false);
}

function appendMessage(message, showTemporary, showAnimation) {
    var wasAtBottom = isScrollAtBottom();

    elmMain.appendChild(message);

    if (elmMain.childElementCount > maxMessages)
        elmMain.removeChild(elmMain.firstChild);

    if (showAnimation) {
        var animKey = isAwesomuim ? "-webkit-animation" : "animation";
        var animValue = isAwesomuim ? "wk_anim_slidein 0.3s ease-out 1" : "ch_anim_slidein 0.3s ease-out 1";

        message.style[animKey] = animValue;
    }

    if (wasAtBottom) scrollToBottom();
    if (!showTemporary) return;

    var copy = message.cloneNode(true);

    // remove certain elements from temporary messages
    for (var i = 0; i < copy.children.length; i++) {
        var child = copy.children[i];

        if (child.className == "media-player") {
            copy.removeChild(child);
        }
    }

    elmTemp.appendChild(copy);

    if (elmTemp.childElementCount > 10)
        elmTemp.removeChild(elmTemp.firstChild);

    setTimeout(function() {
        if (elmTemp.contains(copy))
            elmTemp.removeChild(copy);
    }, temporaryLifetime);
}

function findAndHighlight(text) {
    window.find(text, false, false, true);

    var sel = window.getSelection();
    if (sel && sel.anchorNode.parentElement)
        sel.anchorNode.parentElement.scrollIntoView(true);
}

function removeElementById(id) {
    var element = document.getElementById(id);
    if (element) element.parentElement.removeChild(element);
}

window.addEventListener("contextmenu", function(ev) {
    ev.preventDefault();

    var element = ev.target;

    var data = {
        node: element.nodeName.toLowerCase(),
        text: window.getSelection().toString()
    };

    if (element.src) data.src = element.src;
    if (element.className) data.class = element.className;
    if (element._extraContext) data.extra = JSON.parse(element._extraContext);

    CChat.OnRightClick(JSON.stringify(data));
});

window.addEventListener("keydown", function(ev) {
    if (ev.which == 70 && ev.ctrlKey) {
        CChat.OnPressFind();
        ev.preventDefault();
        return false;
    }
    else if (ev.which == 13 || (isAwesomuim && ev.which == 0)) {
        CChat.OnPressEnter();
        ev.preventDefault();
        return false;
    }
});

console.log("Ready.");
</script>

<style>
/****** Base elements ******/

::selection { background-color: rgb(0,160,215); }

::-webkit-scrollbar {
    height: 16px;
    width: 12px;
    background: rgba(0, 0, 0, 50);
}

::-webkit-scrollbar-thumb {
    background: rgb(180, 180, 180);
}

::-webkit-scrollbar-corner {
    background: rgb(180, 180, 180);
    height: 16px;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    white-space: pre-wrap;
}

body {
    overflow: hidden;
    width: 100%;
    height: 100%;
}

/****** chat elements ******/

img {
    display: inline-block;
    max-width: 95%;
    max-height: 120px;
}

.container {
    display: block;
    position: absolute;
    width: 100%;
    padding: 2px;

    color: white;
    word-break: break-word;
}

#temp {
    bottom: 0;
    user-select: none;
    overflow: hidden;
}

#main {
    top: 0;
    left: 0;
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto;
    visibility: hidden;
    background-color: rgba(0,0,0,0.5);
}

#emojiPanel {
    display: none;
    position: fixed;
    bottom: 0;
    right: 0;
    width: 40%;
    height: 80%;
    padding: 4px;

    overflow-x: hidden;
    overflow-y: scroll;

    border: solid;
    border-width: 2px;
    border-radius: 4px;
    border-color: #cccccc;
    background-color: rgba(0,0,0,0.5);

    -webkit-animation: wk_anim_fadein 0.3s ease-out;
    -webkit-animation-iteration-count: 1;

    animation: ch_anim_fadein 0.3s ease-out;
    animation-iteration-count: 1;
}

.emoji {
    height: 1.2em;
    cursor: default;
    display: inline-block;
    vertical-align: text-bottom;
}
.emoji-button {
    display: inline-block;
    width: 30px;
    height: 30px;
    margin: 4px;
    cursor: pointer;
}
.emoji-category {
    width: 100%;
    height: 22px;
    padding: 2px;
    margin: 2px;
    color: white;
    font-size: 16px;
    text-shadow: 1px 1px 2px #000, 0px 0px 2px #000;
}

.advert {
    display: block;
    margin: 2px;
    font-family: "monospace";
    overflow: hidden;
    background-color: rgba(32, 34, 37, 0.4);
}
.advert p {
    display: inline-block;
    bottom: 0px;
    padding-left: 100%;
    text-indent: 0;
    white-space: nowrap;
    -webkit-animation: wk_anim_advert 10s linear infinite;
    animation: ch_anim_advert 10s linear infinite;
}

.embed {
    display: block;
    padding: 2px;

    border: solid;
    border-radius: 4px;
    border-width: 1px;
    border-color: #202225;

    background-color: #2F3136;
    cursor: pointer;
}
.embed-thumb, .embed-body {
    display: inline-block;
    vertical-align: middle;
}
.embed-thumb {
    max-width: 15%;
    display: inline-block;
}
.embed-body {
    color: #ffffff;
    margin-left: 8px;
    width: 80%;
}
.embed-body > h1 {
    font-size: 90%;
    color: #3264ff;
}
.embed-body > h2 {
    font-size: 80%;
}
.embed-body > i {
    display: block;
    font-size: 14px;
    color: #cccccc;
}

.link {
    display: inline-block;
    color: #3264ff;
    cursor: pointer;
}
.hyperlink {
    text-decoration: underline;
}
.avatar {
    height: 1.2em;
    cursor: default;
    display: inline-block;
    vertical-align: text-bottom;
    margin-right: 0.2em;

    border: solid;
    border-radius: 25%;
    border-width: 1px;
    border-color: #555555;
}

.spoiler {
    border-radius: 4px;
    background-color: #202225;
    color: rgba(255, 255, 255, 0.0);
    text-shadow: none;
}
.spoiler:hover {
    color: rgba(255, 255, 255, 1.0);
}

.safeguard {
    position: relative;
    display: inline-block;
}
.safeguard-hint {
    display: inline-block;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    min-width: 150px;
    min-height: 20px;

    vertical-align: middle;
    text-align: center;

    font-size: 80%;
    font-style: italic;

    color: #aaaaaa;
    background-color: #202225;
    cursor: pointer;
}

.b-text {
    font-weight: 800;
}

.i-text {
    font-style: italic;
}

.code {
    display: block;
    padding: 6px;
    margin: 2px;
    font-size: 80%;
    border: solid;
    border-radius: 4px;
    border-width: 1px;
    border-color: #151618;
}

.code-line {
    display: inline;
    padding: 2px;
    margin: 2px;
    border-radius: 4px;
    font-size: 95%;
}

.media-player {
    display: block;
    width: 80%;
}
.timestamp {
    color: #74ABD3;
    font-weight: 200;
    font-size: 90%;
}

/****** Text effects ******/

.tef-rainbow {
    background-image: -webkit-linear-gradient(left, #ff0000, #d817ff, #1742ff, #00ff00, #ffff01, #ff0000);
    background: linear-gradient(to left, #ff0000, #d817ff, #1742ff, #00ff00, #ffff01, #ff0000);

    color: transparent;
    text-shadow: none;
    font-weight: 800;

    -webkit-background-clip: text;
    background-clip: text;
    background-size: 200% 100%;

    -webkit-animation: wk_anim_rainbow 2s linear infinite;
    animation: ch_anim_rainbow 2s linear infinite;
}

/****** Webkit Animations ******/

@-webkit-keyframes wk_anim_slidein {
    0% { -webkit-transform: translateX(-100%); }
    100% { -webkit-transform: translateX(0%); }
}

@-webkit-keyframes wk_anim_rainbow {
    0% { background-position: 0 0; }
    100% { background-position: 200% 0; }
}

@-webkit-keyframes wk_anim_advert {
    0% { -webkit-transform: translateX(10%); }
    100% { -webkit-transform: translateX(-100%); }
}

@-webkit-keyframes wk_anim_fadein {
    0% { opacity: 0; -webkit-transform: translateX(10%) }
    100% { opacity: 1; -webkit-transform: translateX(0%) }
}

/****** Chromium Animations ******/

@keyframes ch_anim_slidein {
    0% { transform: translateX(-100vw); }
    100% { transform: translateX(0vw); }
}

@keyframes ch_anim_rainbow {
    0% { background-position: 0 0; }
    100% { background-position: 200% 0; }
}

@keyframes ch_anim_advert {
    0% { transform: translateX(10%); }
    100% { transform: translateX(-100%); }
}

@keyframes ch_anim_fadein {
    0% { opacity: 0; transform: translateX(50%) }
    100% { opacity: 1; transform: translateX(0%) }
}
</style>
</html>]]
end

local blockTypes = CustomChat.blockTypes

-- avatar url cache
local avatarCache = {}

-- avatar placeholder until we are done fetching the player's avatar
local avatarPlaceholder = "asset://garrysmod/materials/icon16/user.png"

-- force plain HTTP for certain image links when Chromium is not in use
local forceHTTP

if BRANCH == "unknown" then
    CustomChat.PrintF( "Not using Chromium, enforcing plain HTTP for some image links." )

    forceHTTP = {
        ["avatars.cloudflare.steamstatic.com"] = true,
        ["avatars.akamai.steamstatic.com"] = true,
        ["media.discordapp.net"] = true,
        ["cdn.discordapp.com"] = true -- seems like it still does not work
    }
end

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

local string_sub = string.sub
local SafeString = string.JavascriptSafe
local IsStringValid = CustomChat.IsStringValid
local RGBAToJs = CustomChat.RGBAToJs
local RGBToJs = CustomChat.RGBToJs
local AddLine = CustomChat.AddLine

local PANEL = {}

function PANEL:Init()
    self:SetAllowLua( false )
    self:SetHTML( GetHTMLCode() )

    self.lastSearch = ""
    self.lastEmbedId = 0

    self.animateMessages = true
    self.animationCooldown = 0
    self.displayAvatars = true

    -- the main element that represents a single message,
    -- and is the parent for all of it's blocks
    self.rootElement = "elMessage"

    -- background color for code snippets
    self.codeBackgroundColor = Color( 47, 49, 54, 255 )

    self:AddInternalCallback( "OnPressFind", function()
        self:FindText()
    end )

    self:AddInternalCallback( "OnClickLink", function( url )
        self.OnClickLink( url )
    end )

    self:AddInternalCallback( "OnPressEnter", function()
        self.OnPressEnter()
    end )

    self:AddInternalCallback( "OnSelectEmoji", function( id )
        self.OnSelectEmoji( id )
    end )

    self:AddInternalCallback( "OnRightClick", function( data )
        if self.OnRightClick then
            self.OnRightClick( util.JSONToTable( data ) or {} )
        end
    end )
end

function PANEL:OnClickLink( _url ) end
function PANEL.OnPressEnter() end
function PANEL.OnSelectEmoji( _id ) end

function PANEL:AddInternalCallback( name, callback )
    self:AddFunction( "CChat", name, callback )
end

function PANEL:ConsoleMessage( msg )
    if istable( msg ) then
        msg = util.TableToJSON( msg, false )
    end

    CustomChat.PrintF( "CustomChatHistory: %s", tostring( msg ) )
end

function PANEL:FindText()
    local LangGet = CustomChat.GetLanguageText

    local frame = Derma_StringRequest(
        LangGet( "find" ),
        LangGet( "find_tip" ),
        self.lastSearch,
        function( text )
            self.lastSearch = text
            text = string.JavascriptSafe( text )
            self:QueueJavascript( string.format( "findAndHighlight('%s')", text ) )
        end
    )

    local x, y, w, h = self:GetBounds()
    local frameW, frameH = frame:GetSize()

    x, y = self:LocalToScreen( x, y )
    x = x + ( w * 0.5 ) - ( frameW * 0.5 )
    y = y + ( h * 0.5 ) - ( frameH * 0.5 )

    frame:SetPos( x, y )
end

function PANEL:ScrollToBottom()
    self:QueueJavascript( "scrollToBottom();" )
end

function PANEL:ClearSelection()
    self:QueueJavascript( "clearSelection();" )
end

function PANEL:ClearTemporaryMessages()
    self:QueueJavascript( "elmTemp.textContent = '';" )
end

function PANEL:ClearEverything()
    self:QueueJavascript( "elmMain.textContent = '';" )
end

function PANEL:ToggleEmojiPanel()
    self:QueueJavascript( "setEmojiPanelVisible(elEmojiPanel.style['display'] != 'block');" )
end

function PANEL:SetVisible( enable )
    self:QueueJavascript( "setChatVisible(" .. ( enable and "true" or "false" ) .. ");" )
end

function PANEL:SetDisplayMode( mode )
    self:QueueJavascript( "setDisplayMode('" .. mode .. "');" )
end

function PANEL:SetEnableAnimations( enable )
    self.animateMessages = enable
end

function PANEL:SetEnableAvatars( enable )
    self.displayAvatars = enable

    -- Show/hide existing avatar elements
    local display = enable and "inline-block" or "none"

    self:QueueJavascript( [[
        var avatarElements = document.getElementsByClassName('avatar');

        for (var i = 0; i < avatarElements.length; i++) {
            avatarElements[i].style["display"] = ']] .. display .. [[';
        }
    ]] )
end

function PANEL:SetDefaultFont( fontName )
    local code = "document.styleSheets[0].cssRules[4].style.fontFamily = '%s';"
    self:QueueJavascript( string.format( code, fontName ) )
end

function PANEL:SetFontSize( size )
    size = size and math.Round( size ) or 16
    local code = "elmMain.style.fontSize = '%spx'; elmTemp.style.fontSize = '%spx';"

    self:QueueJavascript( string.format( code, size, size ) )
end

function PANEL:SetFontShadowEnabled( enabled )
    local code = "elmMain.style.textShadow = '%s'; elmTemp.style.textShadow = '%s';"
    local shadowCSS = enabled and "1px 1px 2px #000, 0px 0px 2px #000" or ""

    self:QueueJavascript( string.format( code, shadowCSS, shadowCSS ) )
end

function PANEL:SetHighlightColor( color )
    local code = "document.styleSheets[0].cssRules[0].style.backgroundColor = '%s';"
    self:QueueJavascript( string.format( code, RGBAToJs( color ) ) )
end

function PANEL:SetBackgroundColor( color )
    local code = "elmMain.style.backgroundColor = '%s';"
    self:QueueJavascript( string.format( code, RGBAToJs( color ) ) )
end

function PANEL:SetScrollBackgroundColor( color )
    local code = "document.styleSheets[0].cssRules[1].style.backgroundColor = '%s';"
    self:QueueJavascript( string.format( code, RGBAToJs( color ) ) )
end

function PANEL:SetScrollBarColor( color )
    local code = "document.styleSheets[0].cssRules[2].style.backgroundColor = '%s';"
    self:QueueJavascript( string.format( code, RGBAToJs( color ) ) )
end

function PANEL:UpdateEmojiPanel()
    local GetEmojiURL = CustomChat.GetEmojiURL
    local LangGet = CustomChat.GetLanguageText
    local lines = { "elEmojiPanel.textContent = '';" }

    for _, category in ipairs( CustomChat.emojiCategories ) do
        if #category.items > 0 then
            lines[#lines + 1] = [[
                var elCategory = document.createElement('div');
                elCategory.className = 'emoji-category';
                elCategory.textContent = ']] .. SafeString( LangGet( category.name ) ) .. [[';
                elEmojiPanel.appendChild(elCategory);
            ]]

            for _, emoji in ipairs( category.items ) do
                local url = GetEmojiURL( emoji.id )

                lines[#lines + 1] = [[
                    var elEmoji = document.createElement('img');
                    elEmoji.src = ']] .. SafeString( url ) .. [[';
                    elEmoji.className = 'emoji-button';
                    elEmoji.onclick = function(){ CChat.OnSelectEmoji(']] .. emoji.id .. [[') };
                    elEmojiPanel.appendChild(elEmoji);
                ]]
            end
        end
    end

    self:QueueJavascript( table.concat( lines, "\n" ) )
end

local ChopEnds = CustomChat.ChopEnds

-- Generates JS code that creates a message element based on "contents".
-- "contents" must be a sequential table, containing strings, colors, and/or player entities.
function PANEL:AppendContents( contents, showTimestamp )
    if not istable( contents ) then
        ErrorNoHalt( "Contents must be a table!" )
        return
    end

    CustomChat:CachePlayerNames()

    local playersByName = CustomChat.playersByName

    -- lets split the message contents into "blocks"
    local blocks = {}

    local function AddBlock( type, value )
        blocks[#blocks + 1] = {
            type = type,
            value = value
        }
    end

    for _, obj in ipairs( contents ) do
        if type( obj ) == "table" then
            if obj.r and obj.g and obj.b then
                AddBlock( "color", obj )

            elseif obj.blockType and obj.blockValue then
                AddBlock( obj.blockType, obj.blockValue )

            else
                AddBlock( "string", tostring( obj ) )
            end

        elseif type( obj ) == "string" then
            if playersByName[obj] then
                AddBlock( "player", playersByName[obj] )
            else
                -- find more blocks using patterns
                CustomChat.ParseString( obj, AddBlock )
            end

        elseif type( obj ) == "Player" and IsValid( obj ) then
            AddBlock( "player", {
                ply = obj,
                name = obj:Nick(),
                id = obj:SteamID(),
                id64 = obj:SteamID64(),
                isBot = obj:IsBot()
            } )
        else
            AddBlock( "string", tostring( obj ) )
        end
    end

    -- then, convert the blocks into JS code,
    -- and it will create the HTML elements for us
    local lines = {
        ( "var %s = document.createElement('div');" ):format( self.rootElement )
    }

    if showTimestamp then
        local code = [[
            var elTimestamp = document.createElement('span');
            %s.appendChild(elTimestamp);
            elTimestamp.className = 'timestamp';
            elTimestamp.textContent = '%s ';
        ]]

        lines[#lines + 1] = code:format( self.rootElement, os.date( "%H:%M:%S" ) )
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
            local func = blockTypes[b.type]

            if func then
                lines[#lines + 1] = func( self, b.value, currentColor, currentFont )
            else
                CustomChat.PrintF( "Invalid chat block type: %s", b.type )
            end
        end
    end

    -- lets not add this message to the temp container if hud is disabled
    local showTemporary = ( GetConVar( "cl_drawhud" ):GetInt() == 0 ) and "false" or "true"

    -- prevent animations while the chat is being spammed
    local t = RealTime()
    local showAnimation = ( t > self.animationCooldown and self.animateMessages ) and "true" or "false"
    self.animationCooldown = t + 0.5

    lines[#lines + 1] = ( "appendMessage(%s, %s, %s);" ):format( self.rootElement, showTemporary, showAnimation )

    self:QueueJavascript( table.concat( lines, "\n" ) )
end

--- Returns JS code to create an element,
--- and make it a child of another one.
---
--- tag string Element tag type
--- myVar string Element's variable
--- parentVar string Element's parent variable (PANEL.rootElement by default)
function PANEL:CreateElement( tag, myVar, parentVar )
    parentVar = parentVar or self.rootElement

    return ( [[
        var %s = document.createElement('%s');
        %s.appendChild(%s);
    ]] ):format( myVar, tag, parentVar, myVar )
end

--- Returns JS code to create a text element.
--- Optionally, it can act as a clickable link.
function PANEL:CreateText( text, font, link, color, bgColor, cssClass )
    local lines = { self:CreateElement( "span", "elText" ) }

    AddLine( lines, "elText.textContent = '%s';", SafeString( text ) )

    if IsStringValid( font ) then
        AddLine( lines, "elText.style.fontFamily = '%s';", font )
    end

    if IsStringValid( link ) then
        AddLine( lines, "elText.onclick = function(){ CChat.OnClickLink('%s') };", SafeString( link ) )
        AddLine( lines, "elText.clickableText = true;" )
        AddLine( lines, "elText.style.cursor = 'pointer';" )
    end

    if cssClass then
        AddLine( lines, "elText.className = '%s';", cssClass )
    end

    if color and color ~= color_white then
        AddLine( lines, "elText.style.color = '%s';", RGBToJs( color ) )
    end

    if bgColor then
        AddLine( lines, "elText.style.backgroundColor = '%s';", RGBToJs( bgColor ) )
    end

    return table.concat( lines, "\n" )
end

--- Returns JS code to create a image element
--- (optionally, it can act as a clickable link)
function PANEL:CreateImage( url, link, cssClass, altText, safeFilter )
    if forceHTTP then
        local prefix, site = string.match( url, "^(%w-)://([^/]*)/" )

        if site and prefix == "https" and forceHTTP[site] then
            CustomChat.PrintF( "Forcing plain HTTP for %s", site )
            url = "http" .. string_sub( url, 6 )
        end
    end

    url = SafeString( url )

    local lines = {}

    if safeFilter then
        self.lastEmbedId = self.lastEmbedId + 1

        local safeguardId = "safeguard_" .. self.lastEmbedId

        AddLine( lines, self:CreateElement( "span", "elSafeguard" ) )
        AddLine( lines, "elSafeguard.className = 'safeguard';" )

        AddLine( lines, self:CreateElement( "img", "elImg", "elSafeguard" ) )

        AddLine( lines, self:CreateElement( "span", "elHint", "elSafeguard" ) )
        AddLine( lines, "elHint.id = '%s';", safeguardId )
        AddLine( lines, "elHint.className = 'safeguard-hint';" )
        AddLine( lines, "elHint.textContent = '%s';", CustomChat.GetLanguageText( "click_to_reveal" ) )
        AddLine( lines, "elHint.onclick = function(){ removeElementById('%s'); };", safeguardId )
    else
        AddLine( lines, self:CreateElement( "img", "elImg" ) )
    end

    AddLine( lines, "elImg.src = '%s';", url )

    if link then
        link = SafeString( link )
        AddLine( lines, "elImg.onclick = function(){ CChat.OnClickLink('%s') };", link )
    end

    if cssClass then
        AddLine( lines, "elImg.className = '%s';", cssClass )
    end

    if altText then
        AddLine( lines, "elImg.alt = '%s';", altText )
    end

    return table.concat( lines, "\n" )
end

--- Returns JS code that creates a marquee-like animated text (moving right to left) 
function PANEL:CreateAdvert( text, color )
    local lines = {
        self:CreateElement( "span", "elAdvert" ),
        "elAdvert.className = 'advert';",
        self:CreateElement( "p", "elText", "elAdvert" )
    }

    AddLine( lines, "elText.textContent = '%s';", SafeString( text ) )
    AddLine( lines, "elText.style.color = '%s';", RGBToJs( color ) )

    return table.concat( lines, "\n" )
end

--- Returns JS code to create a audio player
function PANEL:CreateAudioPlayer( url, font )
    url = SafeString( url )

    local lines = {
        self:CreateText( url, font, url ),
        self:CreateElement( "audio", "elAudio" ),
        [[elAudio.className = 'media-player';
        elAudio.volume = 0.5;
        elAudio.setAttribute('preload', 'metadata');
        elAudio.setAttribute('controls', 'controls');
        elAudio.setAttribute('controlsList', 'nodownload noremoteplayback');
        elAudio.src = ']] .. url .. "';"
    }

    return table.concat( lines, "\n" )
end

--- Returns JS code that creates a block of code
function PANEL:CreateCode( code, font, inline )
    local lines = { self:CreateElement( "span", "elCode" ) }

    AddLine( lines, "elCode.className = '%s';", inline and "code-line" or "code" )
    AddLine( lines, "elCode.style.backgroundColor = '%s';", RGBToJs( self.codeBackgroundColor ) )

    font = IsStringValid( font ) and font or "monospace"

    -- "highlight" the code, creating child elements for each token
    local tokens = CustomChat.TokenizeCode( code )

    for _, t in ipairs( tokens ) do
        lines[#lines + 1] = self:CreateElement( "span", "elToken", "elCode" )

        AddLine( lines, "elToken.textContent = '%s';", SafeString( t.value ) )
        AddLine( lines, "elToken.style.color = '%s';", t.color )
        AddLine( lines, "elToken.style.fontFamily = '%s';", font )
    end

    return table.concat( lines, "\n" )
end

--- Returns JS code that creates a embed box
function PANEL:CreateEmbed( url )
    self.lastEmbedId = self.lastEmbedId + 1

    local embedId = "embed_" .. self.lastEmbedId

    HTTP( {
        url = url,
        method = "GET",

        success = function( code, body )
            code = tostring( code )

            local isHTML = body:len() > 15 and body:sub( 1, 15 ) == "<!DOCTYPE html>"

            if not isHTML and code:sub( 1, 1 ) ~= "2" then
                return
            end

            self:OnHTTPResponse( embedId, body, url )
        end
    } )

    url = SafeString( url )

    local lines = { self:CreateElement( "p", "elEmbed" ) }

    AddLine( lines, "elEmbed.className = '%s';", "link " .. embedId )
    AddLine( lines, "elEmbed.textContent = '%s';", url )
    AddLine( lines, "elEmbed.onclick = function(){ CChat.OnClickLink('%s') };", url )

    return table.concat( lines, "\n" )
end

--- Received a response from our metadata fetcher
function PANEL:OnHTTPResponse( embedId, body, url )
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
    -- with what we got from the internet
    local lines = { ( [[
        var embedElements = document.getElementsByClassName('%s');

        for (var i = 0; i < embedElements.length; i++) {
            var elEmbed = embedElements[i];
            elEmbed.textContent = "";
            elEmbed.className = "embed %s";
        ]] ):format( embedId, embedId )
    }

    if props["image"] then
        if string_sub( props["image"], 1, 2 ) == "//" then
            props["image"] = "https:" .. props["image"]
        end

        AddLine( lines, self:CreateElement( "img", "elImg", "elEmbed" ) )
        AddLine( lines, "elImg.className = 'embed-thumb';" )
        AddLine( lines, "elImg.src = '%s';", SafeString( props["image"] ) )
    end

    AddLine( lines, self:CreateElement( "section", "elEmbedBody", "elEmbed" ) )
    AddLine( lines, "elEmbedBody.className = 'embed-body';" )

    if props["site_name"] then
        AddLine( lines, self:CreateElement( "h1", "elName", "elEmbedBody" ) )
        AddLine( lines, "elName.innerHTML = '%s';", SafeString( props["site_name"] ) )
    end

    local title = props["title"] or site

    if title:len() > 50 then
        title = title:Left( 47 ) .. "..."
    end

    AddLine( lines, self:CreateElement( "h2", "elTitle", "elEmbedBody" ) )
    AddLine( lines, "elTitle.innerHTML = '%s';", SafeString( title ) )

    local desc = props["description"] or url

    if desc:len() > 100 then
        desc = desc:Left( 97 ) .. "..."
    end

    AddLine( lines, self:CreateElement( "i", "elDesc", "elEmbedBody" ) )
    AddLine( lines, "elDesc.innerHTML = '%s';", SafeString( desc ) )
    AddLine( lines, "}" )

    self:QueueJavascript( table.concat( lines, "\n" ) )
end

----- Steam avatar fetcher -----

local function ExtractAvatarFromXML( data )
    local urlPattern = "<!%[CDATA%[(https://[%g%.]+/[%g]+%.jpg)%]%]>"
    local _, _, url = string.find( data, "<avatarMedium>" .. urlPattern .. "</avatarMedium>"  )

    if not url then
        _, _, url = string.find( data, "<avatarIcon>" .. urlPattern .. "</avatarIcon>"  )
    end

    return url
end

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

--- Replace the image source of existing avatars for a specific steamid
function PANEL:UpdateAllAvatars( steamId64, url )
    local code = (
        [[var avatarElements = document.getElementsByClassName('ply-%s');

        for (var i = 0; i < avatarElements.length; i++) {
            avatarElements[i].src = '%s';
        }]]
    ):format( steamId64, url )

    self:QueueJavascript( code )
end

function PANEL:FetchUserAvatarURL( id )
    if not id then
        return avatarPlaceholder
    end

    local url = avatarCache[id]

    if url and url ~= "" then
        return url
    end

    -- prevent fetching the same user
    -- multiple times at the same time
    if url == "" then
        return avatarPlaceholder
    end

    avatarCache[id] = ""

    CustomChat.PrintF( "Fetching profile data for %s", id )

    local OnFail = function( reason )
        CustomChat.PrintF( "Failed to fetch avatar for %s: %s", id, reason )
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

            url = ExtractAvatarFromXML( body )

            if url then
                if forceHTTP then
                    url = "http" .. string_sub( url, 6 )
                end

                CustomChat.PrintF( "Fetching avatar image for %s: %s", id, url )

                ValidateURL( url, function( success )
                    if success then
                        avatarCache[id] = url

                        CustomChat.PrintF( "Got avatar for %s", id )
                        self:UpdateAllAvatars( id, url )
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

vgui.Register( "CustomChatHistory", PANEL, "DHTML" )
