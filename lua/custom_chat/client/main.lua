CreateClientConVar( "customchat_disable", "0", true, false )

-- clean stuff when loading this script (helps during development)
if IsValid( CustomChat.frame ) then
    chat.Close()
    cvars.RemoveChangeCallback( "customchat_disable", "customchat_disable_changed" )

    CustomChat.frame:CloseChat()
    CustomChat.frame:SetDeleteOnClose( true )
    CustomChat.frame:Close()
    CustomChat.frame = nil
end

-- keep track of the original chat functions
CustomChat.DefaultOpen = CustomChat.DefaultOpen or chat.Open
CustomChat.DefaultClose = CustomChat.DefaultClose or chat.Close
CustomChat.DefaultAddText = CustomChat.DefaultAddText or chat.AddText
CustomChat.DefaultGetChatBoxPos = CustomChat.DefaultGetChatBoxPos or chat.GetChatBoxPos
CustomChat.DefaultGetChatBoxSize = CustomChat.DefaultGetChatBoxSize or chat.GetChatBoxSize

function CustomChat.InternalMessage( text )
    chat.AddText( color_white, "[", Color( 80, 165, 204 ), "Custom Chat", color_white, "] ", text )
end

function CustomChat:CachePlayerNames()
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

    self.playersByName = playersByName
end

local Config = CustomChat.Config

function CustomChat:CreateFrame()
    self.frame = vgui.Create( "CustomChatFrame" )
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
        -- save position/size
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

    self.frame.OnSubmitMessage = function( text )
        if string.len( text ) > 0 then
            local channel = self.channels[self.teamMode and "team" or "everyone"]

            net.Start( "customchat.say", false )
            net.WriteUInt( channel, 4 )
            net.WriteString( text )
            net.SendToServer()
        end

        if not IsValid( self.Theme.themeFrame ) then
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
        self.frame:LoadThemeData( themeId == "server_default" and
            self.Theme.serverTheme or self.Theme.LoadThemeFile( themeId ) )
    end
end

function CustomChat:AddMessage( contents )
    if not IsValid( self.frame ) then
        self:CreateFrame()
    end

    self.frame:AppendContents( contents, self.Config.timestamps )
end

function CustomChat:OpenContextMenu( data )
    local L = CustomChat.GetLanguageText

    local optionsMenu = DermaMenu( false, self.frame )
    optionsMenu:SetMinimumWidth( 200 )
    optionsMenu:Open()

    if data.extra and data.extra.steamId then
        optionsMenu:AddOption( L"context.copy_steamid", function()
            SetClipboardText( data.extra.steamId )
        end ):SetIcon( "icon16/comment_edit.png" )

        optionsMenu:AddOption( L"context.copy_steamid64", function()
            SetClipboardText( data.extra.steamId64 )
        end ):SetIcon( "icon16/comment_edit.png" )

        optionsMenu:AddOption( L"context.open_profile", function()
            gui.OpenURL( "https://steamcommunity.com/profiles/" .. data.extra.steamId64 )
        end ):SetIcon( "icon16/user.png" )
    end

    if data.src and data.src ~= "" then
        optionsMenu:AddOption( L"context.copy_link", function()
            SetClipboardText( data.src )
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

    optionsMenu:AddOption( L"context.clear_all", function()
        self.frame.history:ClearEverything()
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
        Config.fontSize = math.floor( math.Clamp( value, 12, 48 ) )
        self.frame.history:SetFontSize( Config.fontSize )
        Config:Save()
    end

    panelFontSize:SizeToChildren()
    optionsMenu:AddPanel( panelFontSize )
    optionsMenu:AddSpacer()

    --- server settings

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

----- Add hooks and override chat functions -----

local function CustomChat_AddText( ... )
    CustomChat:AddMessage( { ... } )
    CustomChat.DefaultAddText( ... )
end

local function CustomChat_Open( pcalled )
    if not pcalled then
        -- any errors at this point can cause the UI to get stuck and
        -- block the pause menu/console, so heres a safety check
        local success, err = pcall( CustomChat_Open, true )

        if not success then
            ErrorNoHalt( err )
        end

        return
    end

    if not IsValid( CustomChat.frame ) then
        CustomChat:CreateFrame()
    end

    -- Update the "Say" label and the color of the text entry 
    if CustomChat.teamMode == true then
        local color = team.GetColor( LocalPlayer():Team() )

        color.r = color.r * 0.3
        color.g = color.g * 0.3
        color.b = color.b * 0.3
        color.a = CustomChat.frame.inputBackgroundColor.a

        CustomChat.frame:SetEntryLabel( "custom_chat.team_say", color )
    else
        CustomChat.frame:SetEntryLabel( "custom_chat.say" )
    end

    CustomChat.frame:MakePopup()
    CustomChat.frame:SetMouseInputEnabled( true )
    CustomChat.frame:SetKeyboardInputEnabled( true )
    CustomChat.frame:OpenChat()

    net.Start( "customchat.is_typing", false )
    net.WriteBool( true )
    net.SendToServer()

    -- make sure other addons know we are chatting
    hook.Run( "StartChat" )
end

local function CustomChat_Close()
    if not IsValid( CustomChat.frame ) then return end

    CustomChat.frame:CloseChat()
    CustomChat.frame:SetMouseInputEnabled( false )
    CustomChat.frame:SetKeyboardInputEnabled( false )

    gui.EnableScreenClicker( false )

    net.Start( "customchat.is_typing", false )
    net.WriteBool( false )
    net.SendToServer()

    hook.Run( "FinishChat" )
    hook.Run( "ChatTextChanged", "" )
end

local function CustomChat_OnChatText( _, _, text, textType )
    if textType == "chat" then return end

    local canShowJoinLeave = not ( CustomChat.Tags.connection.showConnect or CustomChat.Tags.connection.showDisconnect )
    if not canShowJoinLeave and textType == "joinleave" then return end

    CustomChat:AddMessage( { Color( 0, 128, 255 ), text } )

    return true
end

local function CustomChat_OnPlayerBindPress( _, bind, pressed )
    if not pressed then return end
    if bind ~= "messagemode" and bind ~= "messagemode2" then return end

    -- dont open if playable piano is blocking input
    if IsValid( LocalPlayer().Instrument ) then return end

    -- dont open if Starfall is blocking input
    local existingBindHooks = hook.GetTable()["PlayerBindPress"]
    if existingBindHooks["sf_keyboard_blockinput"] then return end

    -- dont open if anything else blocks input
    local block = hook.Run( "CustomChatBlockInput" )
    if block == true then return end

    CustomChat.teamMode = ( bind == "messagemode2" )
    chat.Open()

    return true
end

local function CustomChat_HUDShouldDraw( name )
    if name == "CHudChat" then return false end
end

local isGamePaused = false

local function CustomChat_Think()
    if not CustomChat.frame then return end

    -- hide the chat box if the game is paused
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

if GetConVar( "customchat_disable" ):GetInt() == 0 then
    CustomChat:Enable()
end

cvars.AddChangeCallback( "customchat_disable", function( _, _, new )
    if tonumber( new ) == 0 then
        CustomChat:Enable()
    else
        CustomChat:Disable()
    end
end, "customchat_disable_changed" )

-- remove existing temporary messages when cl_drawhud is 0
cvars.RemoveChangeCallback( "customchat_cl_drawhud_changed" )

cvars.AddChangeCallback( "cl_drawhud", function( _, _, new )
    if IsValid( CustomChat.frame ) and new == "0" then
        CustomChat.frame.history:ClearTemporaryMessages()
    end
end, "customchat_cl_drawhud_changed" )

-- received a message
net.Receive( "customchat.say", function()
    local channel = net.ReadUInt( 4 )
    local text = net.ReadString()
    local ply = net.ReadEntity()

    if not IsValid( ply ) then return end

    local isDead = not ply:Alive()

    CustomChat.lastSpeaker = ply
    hook.Run( "OnPlayerChat", ply, text, channel ~= CustomChat.channels.everyone, isDead )
end )

hook.Add( "InitPostEntity", "CustomChat.StoreLocalSteamId", function()
    CustomChat.localSteamId = LocalPlayer():SteamID()
end )

hook.Add( "NetPrefs_OnChange", "CustomChat.OnServerConfigChange", function( key, value )
    if key == "customchat.emojis" then
        CustomChat.PrintF( "Received emojis from the server." )
        CustomChat.ClearCustomEmojis()

        local items = CustomChat.Unserialize( value )

        for _, emoji in ipairs( items ) do
            CustomChat.AddCustomEmoji( emoji.id, emoji.url )
        end

        if IsValid( CustomChat.frame ) then
            CustomChat.frame.history:UpdateEmojiPanel()
        end

    elseif key == "customchat.theme" then
        local data = CustomChat.Unserialize( value )

        if table.IsEmpty( data ) then
            CustomChat.PrintF( "Server default theme was empty." )
            CustomChat.Theme.serverTheme = nil
            CustomChat:SetTheme( Config.themeId )
        else
            CustomChat.PrintF( "Received the server default theme." )

            data.id = "server_default"
            data.description = CustomChat.GetLanguageText( "theme.server_default_description" )

            CustomChat.Theme.serverTheme = data
            CustomChat:SetTheme( "server_default" )
        end

    elseif key == "customchat.tags" then
        CustomChat.PrintF( "Received chat tags from the server." )

        local data = CustomChat.Unserialize( value )
        local Tags = CustomChat.Tags

        Tags.byId = data.byId or {}
        Tags.byTeam = data.byTeam or {}
        Tags.connection = data.connection or Tags.connection
    end
end )

local function OnPlayerActivated( ply, steamId, color, absenceLength )
    local name = ply:Nick()

    -- only use a player block if custom chat is enabled
    if GetConVar( "customchat_disable" ):GetInt() == 0 then
        name = {
            blockType = "player",
            blockValue = {
                name = name,
                id = steamId,
                id64 = ply:SteamID64(),
                isBot = ply:IsBot()
            }
        }
    end

    -- show a message if this player is a friend
    if
        CustomChat.GetConVarInt( "enable_friend_messages", 0 ) > 0 and
        steamId ~= CustomChat.localSteamId and
        ply:GetFriendStatus() == "friend"
    then
        chat.AddText(
            Color( 255, 255, 255 ), ":small_blue_diamond: " .. CustomChat.GetLanguageText( "friend_spawned1" ) .. " ",
            color, name,
            Color( 255, 255, 255 ), " " .. CustomChat.GetLanguageText( "friend_spawned2" )
        )
    end

    if absenceLength < 1 then return end
    if CustomChat.GetConVarInt( "enable_absence_messages", 0 ) == 0 then return end

    -- show the last time the server saw this player
    local lastSeenTime = CustomChat.NiceTime( math.Round( absenceLength ) )

    chat.AddText(
        color, name,
        Color( 150, 150, 150 ), " " .. CustomChat.GetLanguageText( "last_seen1" ),
        Color( 200, 200, 200 ), " " .. lastSeenTime,
        Color( 150, 150, 150 ), " " .. CustomChat.GetLanguageText( "last_seen2" )
    )
end

net.Receive( "customchat.player_spawned", function()
    local steamId = net.ReadString()
    local color = net.ReadColor( false )
    local absenceLength = net.ReadFloat()

    -- wait till the player entity is valid, within a few tries
    local timerId = "CustomChat.WaitValid" .. steamId

    timer.Create( timerId, 0.2, 50, function()
        local ply = player.GetBySteamID( steamId )

        if IsValid( ply ) then
            timer.Remove( timerId )
            OnPlayerActivated( ply, steamId, color, absenceLength )
        end
    end )
end )
