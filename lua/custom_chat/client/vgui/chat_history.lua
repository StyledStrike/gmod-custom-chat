local function GetHTML()
return [[<!DOCTYPE html>
<html lang="en-US">

<head>
    <meta charset="utf-8">
</head>

<body>
    <pre id="tempContainer"></pre>
    <div id="channelContainer"></div>
    <div id="emojiContainer"></div>
</body>

<style>
/****** Page ******/

::selection { background-color: #5abdff; }

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
    white-space: pre-wrap;
}

body {
    overflow: hidden;
    width: 100%;
    height: 100%;
    -webkit-font-smoothing: antialiased;
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
    0% { opacity: 0; -webkit-transform: translateX(10%); }
    100% { opacity: 1; -webkit-transform: translateX(0%); }
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

/****** Containers ******/

pre {
    display: block;
    position: absolute;
    width: 100%;
    padding: 2px;

    color: white;
    word-break: break-word;
}

#tempContainer {
    bottom: 0;
    width: 100%;
    user-select: none;
    overflow: hidden;
}

#channelContainer {
    visibility: hidden;
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0,0,0,0.4);
}

#emojiContainer {
    display: none;
    position: fixed;
    bottom: 0;
    right: 0;
    width: 45%;
    height: 90%;
    padding: 4px;
    user-select: none;
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
}

.channel {
    top: 0;
    left: 0;
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto;
}

/****** Message elements ******/

img {
    display: inline-block;
    max-width: 95%;
    max-height: 120px;
}

.b-text { font-weight: 800; }
.i-text { font-style: italic; }

.timestamp {
    color: #74ABD3;
    font-weight: 200;
    font-size: 90%;
}

.emoji {
    height: 1.2em;
    cursor: default;
    display: inline-block;
    vertical-align: text-bottom;
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

.rainbow {
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
</style>

<script>
var MAX_MESSAGES = 200;
var TEMPORARY_LIFETIME = 10000;
var IS_AWESOMIUM = navigator.userAgent.indexOf("Awesomium") != -1;

var elBody = document.getElementsByTagName("body")[0];
var elTemp = document.getElementById("tempContainer");
var elChannelPanel = document.getElementById("channelContainer");
var elEmojiPanel = document.getElementById("emojiContainer");

var channels = {};

function RemoveElementById(id) {
    var e = document.getElementById(id);
    if (e) e.parentElement.removeChild(e);
}

function SetActiveChannel(chid) {
    for (var id in channels) {
        channels[id].style["visibility"] = (id == chid) ? "visible" : "hidden";
    }
}

function CreateChannel(chid) {
    if (channels[chid]) return;

    channels[chid] = document.createElement("pre");
    channels[chid].id = "channel_" + chid;
    channels[chid].className = "channel";
    elChannelPanel.appendChild(channels[chid]);
}

function RemoveChannel(chid) {
    if (!channels[chid]) return;

    elChannelPanel.removeChild(channels[chid]);
    delete channels[chid];
}

function SetEmojiPanelVisible(v) {
    elEmojiPanel.style["display"] = v ? "block" : "none";
}

function SetChatVisible(v) {
    elBody.style["display"] = v ? "block" : "none";

    if (!v) SetEmojiPanelVisible(false);
}

function SetTemporaryMode(v) {
    elTemp.style["visibility"] = v ? "visible" : "hidden";

    if (v) {
        elChannelPanel.style["visibility"] = "hidden";
        SetActiveChannel();
    }
    else {
        elChannelPanel.style["visibility"] = "visible";
        SetActiveChannel("global");
    }

    if (v) SetEmojiPanelVisible(false);
}

function ClearSelection() {
    window.getSelection().empty();
}

function ClearChannels() {
    for (var id in channels) { channels[id].textContent = ""; }
}

function IsScrollAtBottom(e) {
    return (e.scrollTop + e.clientHeight + 10) > e.scrollHeight;
}

function ScrollToBottom(e) {
    e.scrollTop = e.scrollHeight;
}

function ScrollAllChannelsToBottom() {
    for (var k in channels) { ScrollToBottom(channels[k]); }
}

function AddMessage(message, chid, showAnimation, showTemporary) {
    var e = channels[chid];
    if (!e) return;

    var wasAtBottom = IsScrollAtBottom(e);
    e.appendChild(message);

    if (e.childElementCount > MAX_MESSAGES)
        e.removeChild(e.firstChild);

    if (showAnimation) {
        var k = IS_AWESOMIUM ? "-webkit-animation" : "animation";
        var v = IS_AWESOMIUM ? "wk_anim_slidein 0.3s ease-out 1" : "ch_anim_slidein 0.3s ease-out 1";
        message.style[k] = v;
    }

    if (wasAtBottom) ScrollToBottom(e);
    if (!showTemporary) return;

    var copy = message.cloneNode(true);
    elTemp.appendChild(copy);

    if (elTemp.childElementCount > 10) {
        clearTimeout(elTemp.firstChild._timeoutId);
        elTemp.removeChild(elTemp.firstChild);
    }

    copy._timeoutId = setTimeout(function() {
        if (elTemp.contains(copy))
            elTemp.removeChild(copy);
    }, TEMPORARY_LIFETIME);
}

function FindAndHighlight(text) {
    window.find(text, false, false, true);

    var sel = window.getSelection();

    if (sel && sel.anchorNode.parentElement)
        sel.anchorNode.parentElement.scrollIntoView(true);
}

function OnSelectEmoji(test) {
    if (this._emojiId) CChat.OnSelectEmoji(this._emojiId);
}

window.addEventListener("contextmenu", function(ev) {
    ev.preventDefault();

    var element = ev.target;

    var data = {
        node: element.nodeName.toLowerCase(),
        text: window.getSelection().toString()
    };

    if (element.src) data.url = element.src;
    if (element.className) data.class = element.className;
    if (element._playerData) data.player = JSON.parse(element._playerData);

    CChat.OnRightClick(JSON.stringify(data));
});

window.addEventListener("keydown", function(ev) {
    if (ev.which == 70 && ev.ctrlKey) {
        CChat.OnPressFind();
        ev.preventDefault();
        return false;
    }
    else if (ev.which == 13 || (IS_AWESOMIUM && ev.which == 0)) {
        CChat.OnPressEnter();
        ev.preventDefault();
        return false;
    }
});

console.log("Ready.");
</script>
</html>]]
end

local Format = string.format
local ColorToRGB = CustomChat.ColorToRGB
local L = CustomChat.GetLanguageText

local PANEL = {}

function PANEL:Init()
    self:SetAllowLua( false )
    self:SetHTML( GetHTML() )

    self.lastSearch = ""
    self.displayAvatars = true
    self.animateMessages = true
    self.animationCooldown = 0

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
        self.OnRightClick( util.JSONToTable( data ) or {} )
    end )
end

function PANEL:AddInternalCallback( name, callback )
    self:AddFunction( "CChat", name, callback )
end

function PANEL:ConsoleMessage( msg )
    if istable( msg ) then
        msg = util.TableToJSON( msg, false )
    end

    CustomChat.Print( "HTML: %s", tostring( msg ) )
end

function PANEL:UpdateEmojiPanel()
    local SafeString = string.JavascriptSafe
    local GetEmojiURL = CustomChat.GetEmojiURL
    local Append = CustomChat.AppendString

    local lines = { "elEmojiPanel.textContent = '';" }

    for _, category in ipairs( CustomChat.emojiCategories ) do
        if #category.items > 0 then
            Append( lines, [[
                var elCategory = document.createElement('div');
                elCategory.className = 'emoji-category';
                elCategory.textContent = '%s';
                elEmojiPanel.appendChild(elCategory);
            ]], SafeString( L( category.name ) ) )

            for _, emoji in ipairs( category.items ) do
                local url = GetEmojiURL( emoji.id )

                Append( lines, [[
                    var elEmoji = document.createElement('img');
                    elEmoji.src = '%s';
                    elEmoji.className = 'emoji-button';
                    elEmoji._emojiId = '%s';
                    elEmoji.onclick = OnSelectEmoji;
                    elEmojiPanel.appendChild(elEmoji);
                ]], SafeString( url ), emoji.id, emoji.id )
            end
        end
    end

    self:QueueJavascript( table.concat( lines, "\n" ) )
end

function PANEL:FindText()
    local frame = Derma_StringRequest(
        L"find",
        L"find_tip",
        self.lastSearch,
        function( text )
            self.lastSearch = text
            text = string.JavascriptSafe( text )
            self:QueueJavascript( Format( "FindAndHighlight('%s')", text ) )
        end
    )

    local x, y, w, h = self:GetBounds()
    local frameW, frameH = frame:GetSize()

    x, y = self:LocalToScreen( x, y )
    x = x + ( w * 0.5 ) - ( frameW * 0.5 )
    y = y + ( h * 0.5 ) - ( frameH * 0.5 )

    frame:SetPos( x, y )
end

--- Set if the chat history should only show temporary messages.
function PANEL:SetTemporaryMode( tempMode )
    self:QueueJavascript( "SetTemporaryMode(" .. ( tempMode and "true" or "false" ) .. ");" )
end

function PANEL:ToggleEmojiPanel()
    self:QueueJavascript( "SetEmojiPanelVisible(elEmojiPanel.style['display'] != 'block');" )
end

function PANEL:ClearSelection()
    self:QueueJavascript( "ClearSelection();" )
end

function PANEL:ScrollToBottom()
    self:QueueJavascript( "ScrollAllChannelsToBottom();" )
end

function PANEL:ClearTemporaryMessages()
    self:QueueJavascript( "elTemp.textContent = '';" )
end

function PANEL:ClearEverything()
    self:QueueJavascript( "ClearChannels();" )
end

function PANEL:SetVisible( enable )
    self:QueueJavascript( "SetChatVisible(" .. ( enable and "true" or "false" ) .. ");" )
end

function PANEL:SetFontSize( size )
    size = size and math.Round( size ) or 16
    local code = "elChannelPanel.style.fontSize = '%spx'; elTemp.style.fontSize = '%spx';"
    self:QueueJavascript( Format( code, size, size ) )
end

function PANEL:SetDefaultFont( fontName )
    local code = "document.styleSheets[0].cssRules[4].style.fontFamily = '%s';"
    self:QueueJavascript( Format( code, fontName ) )
end

function PANEL:SetFontShadowEnabled( enabled )
    local code = "document.styleSheets[0].cssRules[4].style.textShadow = '%s';"
    local shadowCSS = enabled and "1px 1px 2px #000000, 0px 0px 2px #000000" or ""
    self:QueueJavascript( Format( code, shadowCSS ) )
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

function PANEL:SetHighlightColor( color )
    local code = "document.styleSheets[0].cssRules[0].style.backgroundColor = '%s';"
    self:QueueJavascript( Format( code, ColorToRGB( color ) ) )
end

function PANEL:SetBackgroundColor( color )
    local code = "elChannelPanel.style.backgroundColor = '%s';"
    self:QueueJavascript( Format( code, ColorToRGB( color ) ) )
end

function PANEL:SetScrollBarColor( color )
    local code = "document.styleSheets[0].cssRules[2].style.backgroundColor = '%s';"
    self:QueueJavascript( Format( code, ColorToRGB( color ) ) )
end

function PANEL:SetScrollBackgroundColor( color )
    local code = "document.styleSheets[0].cssRules[1].style.backgroundColor = '%s';"
    self:QueueJavascript( Format( code, ColorToRGB( color ) ) )
end

local ChopEnds = CustomChat.ChopEnds
local chatFonts = CustomChat.chatFonts
local blockTypes = CustomChat.blocks

--- Generates JS code that creates a message element based on "contents".
--- "contents" must be a sequential table, containing strings, colors, and/or player entities.
function PANEL:AppendContents( contents, channelId, showTimestamp )
    if not istable( contents ) then
        ErrorNoHalt( "Contents must be a table!" )
        return
    end

    local playersByName = CustomChat.GetPlayersByName()

    -- Split the contents into "blocks"
    local blocks = {}

    local function AddBlock( type, value )
        blocks[#blocks + 1] = { type = type, value = value }
    end

    for _, obj in ipairs( contents ) do
        if type( obj ) == "table" then
            if obj.r and obj.g and obj.b then
                AddBlock( "color", obj ) -- color block

            elseif obj.blockType and obj.blockValue then
                AddBlock( obj.blockType, obj.blockValue ) -- custom block

            else
                AddBlock( "string", tostring( obj ) ) -- text block
            end

        elseif type( obj ) == "string" then
            if playersByName[obj] then
                -- Make sure player names get treated as player blocks.
                -- (Prevents embedding players with URLs on their names)
                AddBlock( "player", playersByName[obj] )
            else
                -- Find more blocks on this text using patterns
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

    -- Then, convert the blocks into JS code,
    -- and it will create the HTML elements for us
    local lines = { "var message = document.createElement('div');" }

    if showTimestamp then
        lines[#lines + 1] = Format( [[
var elTimestamp = document.createElement('span');
message.appendChild(elTimestamp);
elTimestamp.className = 'timestamp';
elTimestamp.textContent = '%s ';
        ]], os.date( "%H:%M:%S" ) )
    end

    -- State of the message as we build the JS code
    local ctx = {
        panel = self,
        font = "",
        color = color_white
    }

    for _, b in ipairs( blocks ) do
        if b.type == "font" then
            -- Update the context's font
            local font = ChopEnds( b.value, 2 )

            if chatFonts[font] then
                ctx.font = chatFonts[font]
            end

        elseif b.type == "color" then
            -- Update the context's color
            if type( b.value ) == "string" then
                -- Color string with the <R,G,B> format
                local colorStr = ChopEnds( b.value, 2 )
                local colorTbl = string.Explode( ",", colorStr, false )

                ctx.color = Color(
                    math.Clamp( tonumber( colorTbl[1] ) or 0, 0, 255 ),
                    math.Clamp( tonumber( colorTbl[2] ) or 0, 0, 255 ),
                    math.Clamp( tonumber( colorTbl[3] ) or 0, 0, 255 )
                )
            else
                ctx.color = b.value -- color table
            end

        else
            local func = blockTypes[b.type]

            if func then
                lines[#lines + 1] = func( b.value, ctx )
            else
                CustomChat.Print( "Invalid chat block type: %s", b.type )
            end
        end
    end

    -- Do not add this message to the temporary feed if the HUD is disabled
    local showTemporary = ( GetConVar( "cl_drawhud" ):GetInt() == 0 ) and "false" or "true"

    -- Prevent animations while the chat is being spammed
    local t = RealTime()
    local showAnimation = ( t > self.animationCooldown and self.animateMessages ) and "true" or "false"
    self.animationCooldown = t + 0.5

    lines[#lines + 1] = ( "AddMessage(message, '%s', %s, %s);" ):format( channelId, showAnimation, showTemporary )

    self:QueueJavascript( table.concat( lines, "\n" ) )
end

function PANEL:OnClickLink( _url ) end
function PANEL.OnPressEnter() end
function PANEL.OnSelectEmoji( _id ) end
function PANEL.OnRightClick( _data ) end

vgui.Register( "CustomChat_History", PANEL, "DHTML" )
