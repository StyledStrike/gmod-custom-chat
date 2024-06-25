CreateClientConVar( "custom_chat_enable", "1", true, false )

-- Keep track of the original chat functions
CustomChat.DefaultOpen = CustomChat.DefaultOpen or chat.Open
CustomChat.DefaultClose = CustomChat.DefaultClose or chat.Close
CustomChat.DefaultAddText = CustomChat.DefaultAddText or chat.AddText
CustomChat.DefaultGetChatBoxPos = CustomChat.DefaultGetChatBoxPos or chat.GetChatBoxPos
CustomChat.DefaultGetChatBoxSize = CustomChat.DefaultGetChatBoxSize or chat.GetChatBoxSize

local Floor = math.floor
local Format = string.format

function CustomChat.ChopEnds( str, n )
    return str:sub( n, -n )
end

function CustomChat.ColorToRGB( c )
    local r, g, b, a = Floor( c.r ), Floor( c.g ), Floor( c.b ), c.a

    if type( a ) == "number" and a < 255 then
        return Format( "rgba(%d,%d,%d,%02.2f)", r, g, b, a / 255 )
    end

    return Format( "rgb(%d,%d,%d)", r, g, b )
end

function CustomChat.AppendString( t, s, ... )
    t[#t + 1] = Format( s, ... )
end

function CustomChat.GetLanguageText( id )
    return language.GetPhrase( "custom_chat." .. id )
end

function CustomChat.NiceTime( time )
    local L = CustomChat.GetLanguageText
    local s = time % 60

    time = Floor( time / 60 )
    local m = time % 60

    time = Floor( time / 60 )
    local h = time % 24

    time = Floor( time / 24 )
    local d = time % 7
    local w = Floor( time / 7 )

    local parts = {}

    if w > 0 then
        parts[#parts + 1] = w .. " " .. L( "time.weeks" )
    end

    if d > 0 then
        parts[#parts + 1] = d .. " " .. L( "time.days" )
    end

    if h > 0 then
        parts[#parts + 1] = Format( "%02i ", h ) .. L( "time.hours" )
    end

    if m > 0 then
        parts[#parts + 1] = Format( "%02i ", m ) .. L( "time.minutes" )
    end

    parts[#parts + 1] = Format( "%02i ", s ) .. L( "time.seconds" )

    return table.concat( parts, " " )
end

function CustomChat.PrintMessage( text )
    chat.AddText( color_white, "[", Color( 80, 165, 204 ), "Custom Chat", color_white, "] ", text )
end

function CustomChat.GetPlayersByName()
    local playersByName = {}

    for _, ply in ipairs( player.GetAll() ) do
        playersByName[ply:Nick()] = {
            ply = ply,
            name = ply:Nick(),
            id = ply:SteamID(),
            id64 = ply:SteamID64(),
            isBot = ply:IsBot()
        }
    end

    return playersByName
end

function CustomChat.IsEnabled()
    return CustomChat.GetConVarInt( "enable", 1 ) > 0
end

--- Put a frame on the side of the chat box,
--- while keeping it inside of the screen.
function CustomChat:PutFrameToTheSide( frame )
    local chatX, chatY = chat.GetChatBoxPos()
    local chatW, chatH = chat.GetChatBoxSize()

    local x = chatX + chatW + 8
    local y = ( chatY + chatH * 0.5 ) - ( frame:GetTall() * 0.5 )

    x = math.Clamp( x, 0, ScrW() - frame:GetWide() )
    y = math.Clamp( y, 0, ScrH() - frame:GetTall() )

    frame:SetPos( x, y )
end

--- Helper function to "reset" the chat box.
--- Used for development.
function CustomChat.ResetChatbox()
    if not IsValid( CustomChat.frame ) then return end

    chat.Close()

    CustomChat.frame:CloseChat()
    CustomChat.frame:SetDeleteOnClose( true )
    CustomChat.frame:Close()
    CustomChat.frame = nil
end

CustomChat.ResetChatbox()

local Config = CustomChat.Config

function CustomChat:CreateFrame()
    self.frame = vgui.Create( "CustomChat_Frame" )
    self.frame:SetDeleteOnClose( false )
    self.frame:SetSize( Config.width, Config.height )
    self.frame:SetPos( Config:GetDefaultPosition() )
    self.frame:SetDraggable( true )
    self.frame:SetSizable( true )
    self.frame:SetScreenLock( true )
    self.frame:SetMinWidth( 250 )
    self.frame:SetMinHeight( 150 )

    self.frame._MouseReleased = self.frame.OnMouseReleased

    self.frame.OnMouseReleased = function( s )
        if s.Dragging then
            local x, y, _, h = s:GetBounds()

            Config.offsetLeft = x
            Config.offsetBottom = ScrH() - h - y
            Config:Save()
        end

        s:_MouseReleased()
    end

    self.frame.OnSizeChanged = function( s, w, h )
        local x, y = s:GetPos()

        Config.width = w
        Config.height = h
        Config.offsetLeft = x
        Config.offsetBottom = ScrH() - h - y
        Config:Save()
    end

    self.frame.OnRightClick = function( data )
        self:OpenContextMenu( data )
    end

    self.frame.OnSubmitMessage = function( text, channel )
        if string.len( text ) > 0 then
            local message = CustomChat.ToJSON( {
                channel = channel,
                text = text
            } )

            net.Start( "customchat.say", false )
            net.WriteString( message )
            net.SendToServer()
        end

        if not IsValid( self.Theme.editorFrame ) or string.len( text ) == 0 then
            chat.Close()
        end
    end

    chat.GetChatBoxPos = function()
        return self.frame:GetPos()
    end

    chat.GetChatBoxSize = function()
        return self.frame:GetSize()
    end

    if self.Theme.serverTheme then
        self:SetTheme( "server_default" )

    elseif Config.themeId ~= "default" then
        self:SetTheme( Config.themeId )
    end
end

function CustomChat:SetTheme( themeId )
    if IsValid( self.frame ) then
        self.frame:LoadThemeData( themeId == "server_default" and self.Theme.serverTheme or self.Theme.LoadFile( themeId ) )
    end
end

function CustomChat:AddMessage( contents, channelId )
    if not IsValid( self.frame ) then
        self:CreateFrame()
    end

    channelId = channelId or ( self.lastReceivedMessage and self.lastReceivedMessage.channel or "global" )

    local dmSpeaker = nil

    if util.SteamIDTo64( channelId ) ~= "0" then
        local ply = player.GetBySteamID( channelId )

        if IsValid( ply ) then
            dmSpeaker = ply
            table.insert( contents, 1, ":email: " )
        end
    end

    if not self.frame.channels[channelId] then
        -- If this is not a DM, ignore this message
        if not dmSpeaker then return end

        local channel = self.frame:CreateChannel( channelId, dmSpeaker:Nick(), dmSpeaker )
        channel.isDM = true
    end

    self.frame:AppendContents( contents, channelId, self.Config.timestamps )
end

function CustomChat:CreateCustomChannel( id, tooltip, icon )
    if not IsValid( self.frame ) then
        self:CreateFrame()
    end

    if id == "global" or id == "team" then
        error( "You cannot call CustomChat:CreateCustomChannel with a reserved channel ID!" )
    end

    if id:len() > CustomChat.MAX_CHANNEL_ID_LENGTH then
        error( "You cannot use a ID longer than " .. CustomChat.MAX_CHANNEL_ID_LENGTH .. " characters on CustomChat:CreateCustomChannel!" )
    end

    return self.frame:CreateChannel( id, tooltip, icon )
end

function CustomChat:RemoveCustomChannel( id )
    if not IsValid( self.frame ) then return end

    if id == "global" or id == "team" then
        error( "You cannot call CustomChat:RemoveCustomChannel with a reserved channel ID!" )
    end

    self.frame:RemoveChannel( id )
end

function CustomChat:OpenContextMenu( data )
    data = data or {}

    local L = CustomChat.GetLanguageText

    local optionsMenu = DermaMenu( false, self.frame )
    optionsMenu:SetMinimumWidth( 200 )
    optionsMenu:Open()

    if data.player and data.player.steamId then
        optionsMenu:AddOption( L"context.copy_steamid", function()
            SetClipboardText( data.player.steamId )
        end ):SetIcon( "icon16/comment_edit.png" )

        optionsMenu:AddOption( L"context.copy_steamid64", function()
            SetClipboardText( data.player.steamId64 )
        end ):SetIcon( "icon16/comment_edit.png" )

        optionsMenu:AddOption( L"context.open_profile", function()
            gui.OpenURL( "https://steamcommunity.com/profiles/" .. data.player.steamId64 )
        end ):SetIcon( "icon16/user.png" )
    end

    if data.url and data.url ~= "" then
        optionsMenu:AddOption( L"context.copy_link", function()
            SetClipboardText( data.url )
        end ):SetIcon( "icon16/comment_edit.png" )
    end

    if data.text and data.text ~= "" then
        optionsMenu:AddOption( L"context.copy_text", function()
            SetClipboardText( data.text )
        end ):SetIcon( "icon16/comment_edit.png" )
    end

    optionsMenu:AddSpacer()

    optionsMenu:AddOption( L"find", function()
        self.frame.history:FindText()
    end ):SetIcon( "icon16/zoom.png" )

    local channelId = self.frame.lastChannelId
    local channel = self.frame.channels[channelId]

    if channel.isDM then
        optionsMenu:AddOption( L"channel.close_dm", function()
            self.frame:RemoveChannel( channelId )
        end ):SetIcon( "icon16/cancel.png" )
    end

    optionsMenu:AddOption( L"context.clear_all", function()
        self.frame:ClearEverything()
    end ):SetIcon( "icon16/cancel.png" )

    optionsMenu:AddSpacer()

    optionsMenu:AddOption( L( Config.timestamps and "timestamps.disable" or "timestamps.enable" ), function()
        Config.timestamps = not Config.timestamps
        Config:Save()
    end ):SetIcon( Config.timestamps and "icon16/time_delete.png" or "icon16/time_add.png" )

    if Config.allowAnyURL then
        optionsMenu:AddOption( L"whitelist.enable", function()
            Config:SetWhitelistEnabled( true )
        end ):SetIcon( "icon16/picture_delete.png" )
    else
        local tip = L( "whitelist.allow_tip1" ) ..
            "\n" .. L( "whitelist.allow_tip2" ) ..
            "\n\n" .. L( "whitelist.allow_tip3" )

        optionsMenu:AddOption( L"whitelist.disable", function()
            Derma_Query( tip, L"whitelist.disable", L"whitelist.allow_anyway", function()
                Config:SetWhitelistEnabled( false )
            end, L"cancel" )
        end ):SetIcon( "icon16/picture_add.png" )
    end

    local menuReset, btnReset = optionsMenu:AddSubMenu( L"context.reset" )
    btnReset:SetIcon( "icon16/arrow_refresh.png" )

    local function Reset( position, size )
        if size then
            self.frame:SetSize( Config:GetDefaultSize() )
        end

        if position then
            Config:ResetDefaultPosition()
            self.frame:SetPos( Config:GetDefaultPosition() )
        end

        Config:Save()
    end

    menuReset:AddOption( L"context.position", function()
        Reset( true, false )
    end )

    menuReset:AddOption( L"context.size", function()
        Reset( false, true )
    end )

    menuReset:AddOption( L"context.position_and_size", function()
        Reset( true, true )
    end )

    optionsMenu:AddOption( L"context.theme", function()
        self.Theme.OpenEditor()
    end ):SetIcon( "icon16/color_wheel.png" )

    local panelFontSize = vgui.Create( "DPanel", optionsMenu )
    panelFontSize:SetBackgroundColor( Color( 0, 0, 0, 200 ) )
    panelFontSize:DockPadding( 8, -4, -22, 0 )

    local sliderFontSize = vgui.Create( "DNumSlider", panelFontSize )
    sliderFontSize:Dock( TOP )
    sliderFontSize:SetMin( 12 )
    sliderFontSize:SetMax( 48 )
    sliderFontSize:SetDecimals( 0 )
    sliderFontSize:SetDefaultValue( 16 )
    sliderFontSize:SetValue( Config.fontSize )
    sliderFontSize:SetText( L"context.font_size" )
    sliderFontSize.Label:SetTextColor( color_white )

    sliderFontSize.OnValueChanged = function( _, value )
        Config.fontSize = math.Round( math.Clamp( value, 12, 48 ) )
        self.frame.history:SetFontSize( Config.fontSize )
        Config:Save()
    end

    panelFontSize:SizeToChildren()
    optionsMenu:AddPanel( panelFontSize )
    optionsMenu:AddSpacer()

    ----- Server options

    if self.CanSetServerEmojis( LocalPlayer() ) then
        optionsMenu:AddOption( L"context.emojis", function()
            chat.Close()
            CustomChat.OpenEmojiEditor()
        end ):SetIcon( "icon16/emoticon_tongue.png" )
    end

    if self.CanSetChatTags( LocalPlayer() ) then
        optionsMenu:AddOption( L"context.tags", function()
            if self.USE_TAGS then
                chat.Close()
                CustomChat.Tags:OpenEditor()
            else
                Derma_Message( L"tags.unavailable", L"chat_tags", L"ok" )
            end
        end ):SetIcon( "icon16/tag_blue_edit.png" )
    end

end

----- Add hooks and override chat functions

local function CustomChat_AddText( ... )
    CustomChat:AddMessage( { ... } )
    CustomChat.DefaultAddText( ... )
end

local function CustomChat_Open( pcalled )
    if not pcalled then
        -- Any errors at this point can cause the UI to get stuck and
        -- block the pause menu/console, so here's a safety check
        local success, err = pcall( CustomChat_Open, true )

        if not success then
            ErrorNoHalt( err )
        end

        return
    end

    if not IsValid( CustomChat.frame ) then
        CustomChat:CreateFrame()
    end

    CustomChat.frame:MakePopup()
    CustomChat.frame:SetMouseInputEnabled( true )
    CustomChat.frame:SetKeyboardInputEnabled( true )
    CustomChat.frame:OpenChat()

    CustomChat.SetTyping( true )

    -- Make sure the gamemode and other addons know we are chatting
    hook.Run( "StartChat", CustomChat.isUsingTeamOnly == true )
end

local function CustomChat_Close()
    if not IsValid( CustomChat.frame ) then return end

    CustomChat.frame:CloseChat()
    CustomChat.frame:SetMouseInputEnabled( false )
    CustomChat.frame:SetKeyboardInputEnabled( false )
    CustomChat.SetTyping( false )

    gui.EnableScreenClicker( false )

    hook.Run( "FinishChat" )
    hook.Run( "ChatTextChanged", "" )
end

local function CustomChat_OnChatText( _, _, text, textType )
    if textType == "chat" then return end

    local canShowJoinLeave = not ( CustomChat.JoinLeave.showConnect or CustomChat.JoinLeave.showDisconnect )
    if not canShowJoinLeave and textType == "joinleave" then return end

    CustomChat:AddMessage( { Color( 0, 128, 255 ), text } )

    return true
end

local messageBinds = {
    ["messagemode"] = true,
    ["messagemode2"] = true,
    ["say"] = true,
    ["say_team"] = true
}

local function CustomChat_OnPlayerBindPress( _, bind, pressed )
    if not pressed or not messageBinds[bind] then return end

    -- Don't open if playable piano is blocking input
    if IsValid( LocalPlayer().Instrument ) then return end

    -- Don't open if Starfall is blocking input
    local existingBindHooks = hook.GetTable()["PlayerBindPress"]
    if existingBindHooks["sf_keyboard_blockinput"] then return end

    -- Don't open if anything else wants to block input
    local block = hook.Run( "CustomChatBlockInput" )
    if block == true then return end

    CustomChat.isUsingTeamOnly = ( bind == "messagemode2" )
    chat.Open()

    return true
end

local function CustomChat_HUDShouldDraw( name )
    if name == "CHudChat" then return false end
end

local isGamePaused = false

local function CustomChat_Think()
    if not CustomChat.frame then return end

    -- Hide the chat box if the game is paused
    if gui.IsGameUIVisible() then
        if isGamePaused == false then
            isGamePaused = true

            CustomChat.frame:SetVisible( false )

            if CustomChat.frame.isChatOpen then
                chat.Close()
            end
        end
    else
        if isGamePaused == true then
            isGamePaused = false
            CustomChat.frame:SetVisible( true )
        end
    end
end

function CustomChat:Enable()
    chat.AddText = CustomChat_AddText
    chat.Close = CustomChat_Close
    chat.Open = CustomChat_Open

    hook.Add( "ChatText", "CustomChat.OnChatText", CustomChat_OnChatText )
    hook.Add( "PlayerBindPress", "CustomChat.OnPlayerBindPress", CustomChat_OnPlayerBindPress )
    hook.Add( "HUDShouldDraw", "CustomChat.HUDShouldDraw", CustomChat_HUDShouldDraw )
    hook.Add( "Think", "CustomChat.Think", CustomChat_Think )

    if IsValid( CustomChat.frame ) then
        CustomChat.frame:SetVisible( true )

        chat.GetChatBoxPos = function()
            return self.frame:GetPos()
        end

        chat.GetChatBoxSize = function()
            return self.frame:GetSize()
        end
    end
end

function CustomChat:Disable()
    hook.Remove( "ChatText", "CustomChat.OnChatText" )
    hook.Remove( "PlayerBindPress", "CustomChat.OnPlayerBindPress" )
    hook.Remove( "HUDShouldDraw", "CustomChat.HUDShouldDraw" )
    hook.Remove( "Think", "CustomChat.Think" )

    chat.AddText = CustomChat.DefaultAddText
    chat.Close = CustomChat.DefaultClose
    chat.Open = CustomChat.DefaultOpen
    chat.GetChatBoxPos = CustomChat.DefaultGetChatBoxPos
    chat.GetChatBoxSize = CustomChat.DefaultGetChatBoxSize

    if self.frame then
        self.frame:SetVisible( false )
    end
end

if CustomChat.IsEnabled() then
    CustomChat:Enable()
end

cvars.RemoveChangeCallback( "custom_chat_enable_changed" )
cvars.RemoveChangeCallback( "custom_chat_cl_drawhud_changed" )

cvars.AddChangeCallback( "custom_chat_enable", function( _, _, new )
    if tonumber( new ) > 0 then
        CustomChat:Enable()
    else
        CustomChat:Disable()
    end
end, "custom_chat_enable_changed" )

-- Remove existing temporary messages when cl_drawhud is 0
cvars.AddChangeCallback( "cl_drawhud", function( _, _, new )
    if IsValid( CustomChat.frame ) and new == "0" then
        CustomChat.frame.history:ClearTemporaryMessages()
    end
end, "custom_chat_cl_drawhud_changed" )

hook.Add( "NetPrefs_OnChange", "CustomChat.OnServerConfigChange", function( key, value )
    if key == "customchat.emojis" then
        CustomChat.Print( "Received emojis from the server." )
        CustomChat.ClearCustomEmojis()

        local items = CustomChat.FromJSON( value )

        for _, emoji in ipairs( items ) do
            CustomChat.AddCustomEmoji( emoji.id, emoji.url )
        end

        if IsValid( CustomChat.frame ) then
            CustomChat.frame.history:UpdateEmojiPanel()
        end

    elseif key == "customchat.theme" then
        local data = CustomChat.FromJSON( value )

        if table.IsEmpty( data ) then
            CustomChat.Print( "Server default theme was empty." )
            CustomChat.Theme.serverTheme = nil
            CustomChat:SetTheme( Config.themeId )
        else
            CustomChat.Print( "Received the server default theme." )

            data.id = "server_default"
            data.description = CustomChat.GetLanguageText( "theme.server_default_description" )

            CustomChat.Theme.serverTheme = data
            CustomChat:SetTheme( "server_default" )
        end

    elseif key == "customchat.tags" then
        local data = CustomChat.FromJSON( value )

        CustomChat.Print( "Received chat tags from the server." )

        -- Update player tags
        local Tags = CustomChat.Tags

        Tags.byId = data.byId or {}
        Tags.byTeam = data.byTeam or {}

        -- Update join/leave messages
        local JoinLeave = CustomChat.JoinLeave

        JoinLeave.showConnect = data.connection.showConnect
        JoinLeave.showDisconnect = data.connection.showDisconnect

        JoinLeave.joinColor = data.connection.joinColor
        JoinLeave.joinPrefix = data.connection.joinPrefix
        JoinLeave.joinSuffix = data.connection.joinSuffix

        JoinLeave.leaveColor = data.connection.leaveColor
        JoinLeave.leavePrefix = data.connection.leavePrefix
        JoinLeave.leaveSuffix = data.connection.leaveSuffix
    end
end )

net.Receive( "customchat.say", function()
    local message = net.ReadString()
    local speaker = net.ReadEntity()

    if not IsValid( speaker ) then return end

    message = CustomChat.FromJSON( message )
    message.speaker = speaker

    CustomChat.lastReceivedMessage = message

    hook.Run( "OnPlayerChat", speaker, message.text, message.channel == "team", not speaker:Alive() )

    CustomChat.lastReceivedMessage = nil
end )
