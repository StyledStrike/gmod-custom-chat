local function GetHTMLCode()
return [[<!DOCTYPE html>
<html lang="en-US">

<head>
    <meta charset="utf-8">
    <style>
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
    </style>
</head>

<body>
    <pre id="temp" class="container"></pre>
    <pre id="main" class="container"></pre>
    <div id="emojiPanel"></div>
</body>

<script>
var elmBody = document.getElementsByTagName("body")[0];
var elmTemp = document.getElementById("temp");
var elmMain = document.getElementById("main");
var elEmojiPanel = document.getElementById("emojiPanel");

var isAwesomuim = navigator.userAgent.indexOf("Awesomium") != -1;
var appendCount = 0;

function clearSelection() {
    window.getSelection().empty();
}

function scrollToBottom() {
    elmMain.scrollTop = elmMain.scrollHeight;
}

function isScrollAtBottom() {
    return (elmMain.scrollTop + elmMain.clientHeight + 10) > elmMain.scrollHeight;
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

function setEmojiPanelVisible(tgl) {
    elEmojiPanel.style["display"] = tgl ? "block" : "none";
}

function toggleEmojiPanel() {
    setEmojiPanelVisible(elEmojiPanel.style["display"] != "block");
}

// remove certain elements from messages
// that are going to the "temp" container
function filterTempElements(elm) {
    for (var i = 0; i < elm.children.length; i++) {
        var child = elm.children[i];

        if (child.className == "media-player") {
            elm.removeChild(child);
        }
    }
}

function appendMessage(message, showTemporary, animate) {
    // only allow the existance of one media player at a time
    var mediaElements = document.getElementsByClassName("media-player");

    for (var i = 0; i < mediaElements.length; i++) {
        var parent = mediaElements[i].parentElement;
        parent.removeChild(mediaElements[i]);
    }

    var wasAtBottom = isScrollAtBottom();
    var copy;

    if (showTemporary) {
        copy = message.cloneNode(true);
        filterTempElements(copy);
        elmTemp.appendChild(copy);
    }

    elmMain.appendChild(message);
    appendCount++;

    if (appendCount > 256) {
        appendCount--;
        elmMain.removeChild(elmMain.firstChild);
    }

    if (animate) {
        var animStr = isAwesomuim ? "wk_anim_slidein 0.3s ease-out 1" : "ch_anim_slidein 0.3s ease-out 1";
        var animProp = isAwesomuim ? "-webkit-animation" : "animation";

        message.style[animProp] = animStr;
        if (copy) copy.style[animProp] = animStr;
    }

    if (wasAtBottom) scrollToBottom();
    if (!showTemporary) return;

    if (elmTemp.childElementCount > 10)
        elmTemp.removeChild(elmTemp.firstChild);

    setTimeout(function() {
        if (elmTemp.contains(copy))
            elmTemp.removeChild(copy);
    }, 10000);
}

function findAndHighlight(text) {
    window.find(text, false, false, true);

    var sel = window.getSelection();
    if (sel && sel.anchorNode.parentElement)
        sel.anchorNode.parentElement.scrollIntoView(true);
}

window.addEventListener("contextmenu", function(ev) {
    ev.preventDefault();
    var nodeName = ev.target.nodeName.toLowerCase();

    if (nodeName == "img")
        SChatBox.OnRightClick(ev.target.src, true);
    else if (ev.target.clickableText)
        SChatBox.OnRightClick(ev.target.textContent, true);
    else
        SChatBox.OnRightClick(window.getSelection().toString());
});

window.addEventListener("keydown", function(ev) {
    if (ev.which == 70 && ev.ctrlKey) {
        SChatBox.OnPressFind();
        ev.preventDefault();
        return false;
    }
    else if (ev.which == 13 || (isAwesomuim && ev.which == 0)) {
        SChatBox.OnPressEnter();
        ev.preventDefault();
        return false;
    }
});

console.log("Ready.");
</script>

<style>
/****** Base elements ******/

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
    cursor: pointer;
}
.safeguard-hint {
    display: inline-block;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;

    vertical-align: middle;
    text-align: center;

    font-size: 80%;
    font-style: italic;

    color: #aaaaaa;
    background-color: #202225;
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

local SChatBox = {
    lastSearch = ""
}

function SChatBox:Init()
    self:SetAllowLua( false )
    self:SetHTML( GetHTMLCode() )

    self:AddInternalCallback( "OnPressFind", function()
        self:FindText()
    end )

    self:AddInternalCallback( "OnPressEnter", function()
        self:OnPressEnter()
    end )

    self:AddInternalCallback( "OnClickLink", function( url )
        self:OnClickLink( url )
    end )

    self:AddInternalCallback( "OnImageHover", function( url, isHovering )
        self:OnImageHover( url, isHovering )
    end )

    self:AddInternalCallback( "OnSelectEmoji", function( id )
        self:OnSelectEmoji( id )
    end )

    self:AddInternalCallback( "OnRightClick", function( data, isLink )
        if SChat.isOpen then
            SChat:OpenContextMenu( data, isLink )
        end
    end )
end

function SChatBox:UpdateEmojiPanel()
    self:QueueJavascript( SChat:GenerateEmojiList() )
end

function SChatBox:AddInternalCallback( name, callback )
    self:AddFunction( "SChatBox", name, callback )
end

function SChatBox:FindText()
    local reqFrame = Derma_StringRequest(
        "Find...",
        "Input some text you want to find on the chat",
        self.lastSearch,
        function( text )
            self.lastSearch = text
            text = string.JavascriptSafe( text )
            self:QueueJavascript( string.format( "findAndHighlight('%s')", text ) )
        end
    )

    local x, y, selfW, selfH = self:GetBounds()
    x, y = self:LocalToScreen( x, y )

    local w, h = reqFrame:GetSize()

    x = x + ( selfW * 0.5 ) - ( w * 0.5 )
    y = y + ( selfH * 0.5 ) - ( h * 0.5 )

    reqFrame:SetPos( x, y )
end

function SChatBox:ScrollToBottom()
    self:QueueJavascript( "scrollToBottom();" )
end

function SChatBox:ClearSelection()
    self:QueueJavascript( "clearSelection();" )
end

function SChatBox:ClearTempMessages()
    self:QueueJavascript( "elmTemp.textContent = '';" )
end

function SChatBox:ClearEverything()
    self:QueueJavascript( "elmMain.textContent = ''; appendCount = 0;" )
end

function SChatBox:SetVisible( enable )
    self:QueueJavascript( "setChatVisible(" .. ( enable and "true" or "false" ) .. ");" )
end

function SChatBox:SetDisplayMode( mode )
    self:QueueJavascript( "setDisplayMode('" .. mode .. "');" )
end

function SChatBox:ToggleEmojiPanel()
    self:QueueJavascript( "toggleEmojiPanel()" )
end

function SChatBox:SetHighlightColor( color )
    local code = "document.styleSheets[0].cssRules[0].style.backgroundColor = 'rgb(%d,%d,%d)';"
    self:Call( string.format( code, color.r, color.g, color.b ) )
end

function SChatBox:SetBackgroundColor( color )
    local code = "elmMain.style.backgroundColor = 'rgba(%d,%d,%d,%02.2f)';"
    self:QueueJavascript( string.format( code, color.r, color.g, color.b, color.a / 255 ) )
end

function SChatBox:SetFontSize( size )
    size = size and math.Round( size ) or 16
    self:QueueJavascript(
        string.format( "elmMain.style.fontSize = '%spx'; elmTemp.style.fontSize = '%spx';", size, size )
    )
end

function SChatBox:SetDefaultFont( fontName )
    local code = "document.styleSheets[1].cssRules[0].style.fontFamily = '%s';"
    self:QueueJavascript( string.format( code, fontName ) )
end

function SChatBox:SetFontShadowEnabled( enabled )
    local code = "elmMain.style.textShadow = '%s'; elmTemp.style.textShadow = '%s';"
    local shadowCSS = enabled and "1px 1px 2px #000, 0px 0px 2px #000" or ""

    self:QueueJavascript( string.format( code, shadowCSS, shadowCSS ) )
end

function SChatBox:SetScrollbarBackgroundColor( color )
    local code = "document.styleSheets[0].cssRules[1].style.backgroundColor = 'rgba(%d,%d,%d,%02.2f)';"
    self:Call( string.format( code, color.r, color.g, color.b, color.a / 255 ) )
end

function SChatBox:SetScrollbarThumbColor( color )
    local code = "document.styleSheets[0].cssRules[2].style.backgroundColor = 'rgba(%d,%d,%d,%02.2f)';"
    self:Call( string.format( code, color.r, color.g, color.b, color.a / 255 ) )
end

function SChatBox:AppendContents( contents )
    if not istable( contents ) then
        ErrorNoHalt( "Contents must be a table!" )
        return
    end

    self:QueueJavascript( SChat:GenerateMessageFromTable( contents ) )
end

function SChatBox:ConsoleMessage( msg )
    if istable( msg ) then
        msg = util.TableToJSON( msg, false )
    end

    SChat.PrintF( "JS: %s", tostring( msg ) )
end

function SChatBox:OnClickLink( url )
    gui.OpenURL( url )
end

function SChatBox:OnPressEnter() end
function SChatBox:OnImageHover( _url, _isHovering ) end
function SChatBox:OnSelectEmoji() end

vgui.Register( "SChatBox", SChatBox, "DHTML" )
