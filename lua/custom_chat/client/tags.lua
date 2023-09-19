local Tags = CustomChat.Tags or {
    -- tags by steam id
    byId = {},

    -- tags by team
    byTeam = {},

    -- connect/disconnect messages
    connection = {
        showConnect = false,
        showDisconnect = false,

        joinColor = { 85, 172, 238 },
        joinPrefix = ":small_blue_diamond:",
        joinSuffix = "is joining the game...",

        leaveColor = { 244, 144, 12 },
        leavePrefix = ":small_orange_diamond:",
        leaveSuffix = "left!"
    }
}

CustomChat.Tags = Tags

function Tags:GetParts( ply )
    if self.byId[ply:SteamID()] then
        return self.byId[ply:SteamID()]
    end

    if self.byTeam[ply:Team()] then
        return self.byTeam[ply:Team()]
    end
end

function Tags:GetNameColor( ply )
    local parts = self:GetParts( ply )

    if parts and #parts > 0 then
        for _, v in pairs( parts ) do
            if v[1] == "NAME_COL" then
                return Color( v[2], v[3], v[4] )
            end
        end
    end

    return GAMEMODE:GetTeamColor( ply )
end

local function CustomChat_AddCustomTags( ply, text, isTeam, isDead )
    if not IsValid( ply ) or not ply:IsPlayer() then return end

    local parts = Tags:GetParts( ply )
    if not parts then return end

    local message = {}

    local function Insert( item )
        message[#message + 1] = item
    end

    if isTeam then
        Insert( Color( 20, 160, 35 ) )
        Insert( "(TEAM) " )
    end

    if isDead then
        Insert( Color( 255, 0, 0 ) )
        Insert( "*DEAD* " )
    end

    local messageColor = Color( 255, 255, 255 )

    if #parts > 0 then
        for _, v in pairs( parts ) do
            local color = Color( v[2], v[3], v[4] )

            if v[1] == "MESSAGE_COL" then
                messageColor = color

            elseif v[1] ~= "NAME_COL" then
                Insert( color )
                Insert( v[1] )
            end
        end
    end

    Insert( ply )
    Insert( messageColor )
    Insert( ": " .. text )

    chat.AddText( unpack( message ) )

    return true
end

hook.Add( "InitPostEntity", "CustomChat.PreventChatTagsConflict", function()
    if aTags then return end

    CustomChat.USE_TAGS = true
    hook.Add( "OnPlayerChat", "CustomChat.AddCustomTags", CustomChat_AddCustomTags, HOOK_LOW )
end )

gameevent.Listen( "player_connect_client" )
gameevent.Listen( "player_disconnect" )

hook.Add( "player_connect_client", "CustomChat.ShowConnectMessages", function( data )
    if not Tags.connection.showConnect then return end

    local c = Tags.connection.joinColor
    local name = data.name

    -- only force a player block if custom chat is enabled
    if GetConVar( "customchat_disable" ):GetInt() == 0 then
        name = {
            blockType = "player",
            blockValue = {
                name = data.name,
                id = data.networkid,
                id64 = util.SteamIDTo64( data.networkid ),
                isBot = data.bot == 1
            }
        }
    end

    chat.AddText(
        Color( 255, 255, 255 ), Tags.connection.joinPrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. data.networkid .. "> ",
        Color( 255, 255, 255 ), Tags.connection.joinSuffix
    )
end, HOOK_LOW )

hook.Add( "player_disconnect", "CustomChat.ShowDisconnectMessages", function( data )
    if not Tags.connection.showDisconnect then return end

    local c = Tags.connection.leaveColor
    local name = data.name

    -- only force a player block if custom chat is enabled
    if GetConVar( "customchat_disable" ):GetInt() == 0 then
        name = {
            blockType = "player",
            blockValue = {
                name = data.name,
                id = data.networkid,
                id64 = util.SteamIDTo64( data.networkid ),
                isBot = data.bot == 1
            }
        }
    end

    chat.AddText(
        Color( 255, 255, 255 ), Tags.connection.leavePrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. data.networkid .. "> ",
        Color( 255, 255, 255 ), Tags.connection.leaveSuffix,
        Color( 150, 150, 150 ), " (" .. data.reason .. ")"
    )
end, HOOK_LOW )

function Tags:OpenEditor()
    local L = CustomChat.GetLanguageText

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 600, 400 )
    frame:SetTitle( L"tags.title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    local sheet = vgui.Create( "DPropertySheet", frame )
    sheet:Dock( FILL )

    -------- Tags by team index --------

    local byTeam = table.Copy( Tags.byTeam )
    local currentTeamId

    local pnlTeamTags = vgui.Create( "DPanel", sheet )
    sheet:AddSheet( L"tab.team_tags", pnlTeamTags, "icon16/group.png" )

    local listTeams = vgui.Create( "DListView", pnlTeamTags )
    listTeams:Dock( LEFT )
    listTeams:SetWide( 150 )
    listTeams:SetMultiSelect( false )
    listTeams:AddColumn( L"id" )
    listTeams:AddColumn( L"team" )

    local teamParts = vgui.Create( "CustomChatTagPartsEditor", pnlTeamTags )
    teamParts:Dock( FILL )

    for id, t in pairs( team.GetAllTeams() ) do
        if id > 0 then
            listTeams:AddLine( id, t.Name )
        end
    end

    listTeams.OnRowSelected = function( _, _, row )
        currentTeamId = row:GetValue( 1 )
        teamParts:SetParts( byTeam[currentTeamId] or {} )
    end

    teamParts.OnPartsChange = function( parts )
        if #parts == 0 then
            byTeam[currentTeamId] = nil
        else
            byTeam[currentTeamId] = parts
        end
    end

    listTeams:SelectFirstItem()

    -------- Tags by steamid --------

    local byId = table.Copy( Tags.byId )
    local currentSteamId

    local pnlSteamIdTags = vgui.Create( "DPanel", sheet )
    sheet:AddSheet( L"tab.player_tags", pnlSteamIdTags, "icon16/user.png" )

    local pnlSteamIdOptions = vgui.Create( "DPanel", pnlSteamIdTags )
    pnlSteamIdOptions:Dock( LEFT )
    pnlSteamIdOptions:SetWide( 150 )

    local listIds = vgui.Create( "DListView", pnlSteamIdOptions )
    listIds:Dock( FILL )
    listIds:SetMultiSelect( false )
    listIds:AddColumn( L"steamid" )

    local buttonAddPlayer = vgui.Create( "DButton", pnlSteamIdOptions )
    buttonAddPlayer:SetIcon( "icon16/user_green.png" )
    buttonAddPlayer:SetText( L( "tags.add_player" ) )
    buttonAddPlayer:Dock( BOTTOM )

    local buttonRemoveUser = vgui.Create( "DButton", pnlSteamIdOptions )
    buttonRemoveUser:SetIcon( "icon16/user_delete.png" )
    buttonRemoveUser:SetText( L( "tags.remove_steamid" ) )
    buttonRemoveUser:SetEnabled( false )
    buttonRemoveUser:Dock( BOTTOM )

    local buttonAddUser = vgui.Create( "DButton", pnlSteamIdOptions )
    buttonAddUser:SetIcon( "icon16/user_add.png" )
    buttonAddUser:SetText( L( "tags.add_steamid" ) )
    buttonAddUser:SetEnabled( false )
    buttonAddUser:Dock( BOTTOM )

    local entrySteamId = vgui.Create( "DTextEntry", pnlSteamIdOptions )
    entrySteamId:Dock( BOTTOM )
    entrySteamId:SetPlaceholderText( L( "steamid" ) .. "..." )

    entrySteamId.OnChange = function()
        buttonAddUser:SetEnabled( entrySteamId:GetValue() ~= "" )
    end

    local steamIdParts = vgui.Create( "CustomChatTagPartsEditor", pnlSteamIdTags )
    steamIdParts:Dock( FILL )

    local function UpdateSteamIdsList()
        currentSteamId = nil
        steamIdParts:SetParts( {} )

        listIds:ClearSelection()
        listIds:Clear()

        for id, _ in pairs( byId ) do
            listIds:AddLine( id )
        end
    end

    steamIdParts.OnPartsChange = function( parts )
        if currentSteamId then
            byId[currentSteamId] = parts
        end
    end

    listIds.OnRowSelected = function( _, _, row )
        currentSteamId = row:GetValue( 1 )
        steamIdParts:SetParts( byId[currentSteamId] )
        buttonRemoveUser:SetEnabled( true )
    end

    UpdateSteamIdsList()
    listIds:SelectFirstItem()

    local function AddSteamID( id )
        if type( id ) == "Panel" then
            id = id._steamId
        end

        if util.SteamIDTo64( id ) == "0" then
            Derma_Message( L"tags.invalid_steamid", L"invalid_input", L"ok" )

            return
        end

        if byId[id] then
            Derma_Message( L"tags.steamid_already_in_use", L"invalid_input", L"ok" )

            return
        end

        byId[id] = {}

        buttonAddUser:SetEnabled( false )
        listIds:ClearSelection()

        local line = listIds:AddLine( id )
        listIds:SelectItem( line )
    end

    buttonAddPlayer.DoClick = function()
        local menuPlayers = DermaMenu()
        menuPlayers:SetMaxHeight( 200 )

        for _, ply in ipairs( player.GetHumans() ) do
            local item = menuPlayers:AddOption( ply:Nick(), AddSteamID )
            item._steamId = ply:SteamID()
        end

        menuPlayers:Open()
    end

    buttonAddUser.DoClick = function()
        AddSteamID( string.Trim( entrySteamId:GetValue() ) )
    end

    buttonRemoveUser.DoClick = function()
        byId[currentSteamId] = nil
        UpdateSteamIdsList()
        listIds:SelectFirstItem()
    end

    -------- Connect/disconnect messages --------

    local byConnection = table.Copy( Tags.connection )

    local pnlConnectionTags = vgui.Create( "DPanel", sheet )
    pnlConnectionTags:SetPaintBackground( false )
    sheet:AddSheet( L"tab.conn_disconn", pnlConnectionTags, "icon16/group_go.png" )

    -- connect messages
    local pnlConnect = vgui.Create( "DPanel", pnlConnectionTags )
    pnlConnect:Dock( LEFT )
    pnlConnect:SetWide( 284 )
    pnlConnect:DockPadding( 6, 6, 6, 6 )

    pnlConnect.Paint = function( s, w, h )
        derma.SkinHook( "Paint", "Frame", s, w, h )
        return true
    end

    local checkConnect = vgui.Create( "DCheckBoxLabel", pnlConnect )
    checkConnect:SetText( L"tags.show_join_messages" )
    checkConnect:SetTextColor( Color( 255, 255, 255 ) )
    checkConnect:SetValue( byConnection.showConnect )
    checkConnect:SizeToContents()
    checkConnect:Dock( TOP )

    checkConnect.OnChange = function( _, val )
        byConnection.showConnect = val
    end

    local labelJoinPrefix = vgui.Create( "DLabel", pnlConnect )
    labelJoinPrefix:SetText( L"tags.join_prefix" )
    labelJoinPrefix:SizeToContents()
    labelJoinPrefix:Dock( TOP )
    labelJoinPrefix:DockMargin( 0, 12, 0, 4 )

    local entryJoinPrefix = vgui.Create( "DTextEntry", pnlConnect )
    entryJoinPrefix:SetPlaceholderText( L( "tags.join_prefix" ) .. "..." )
    entryJoinPrefix:SetValue( byConnection.joinPrefix )
    entryJoinPrefix:Dock( TOP )

    entryJoinPrefix.OnChange = function()
        byConnection.joinPrefix = entryJoinPrefix:GetValue()
    end

    local labelJoinSuffix = vgui.Create( "DLabel", pnlConnect )
    labelJoinSuffix:SetText( L"tags.join_suffix" )
    labelJoinSuffix:SizeToContents()
    labelJoinSuffix:Dock( TOP )
    labelJoinSuffix:DockMargin( 0, 12, 0, 4 )

    local entryJoinSuffix = vgui.Create( "DTextEntry", pnlConnect )
    entryJoinSuffix:SetPlaceholderText( L( "tags.join_suffix" ) .. "..." )
    entryJoinSuffix:SetValue( byConnection.joinSuffix )
    entryJoinSuffix:Dock( TOP )

    entryJoinSuffix.OnChange = function()
        byConnection.joinSuffix = entryJoinSuffix:GetValue()
    end

    local labelJoinColor = vgui.Create( "DLabel", pnlConnect )
    labelJoinColor:SetText( L"tags.join_color" )
    labelJoinColor:SizeToContents()
    labelJoinColor:Dock( TOP )
    labelJoinColor:DockMargin( 0, 8, 0, 0 )

    local joinColorPicker = vgui.Create( "DColorMixer", pnlConnect )
    joinColorPicker:Dock( FILL )
    joinColorPicker:DockMargin( 0, 8, 0, 8 )
    joinColorPicker:SetPalette( true )
    joinColorPicker:SetAlphaBar( false )
    joinColorPicker:SetWangs( true )
    joinColorPicker:SetColor( Color(
        byConnection.joinColor[1],
        byConnection.joinColor[2],
        byConnection.joinColor[3]
    ) )

    joinColorPicker.ValueChanged = function( _, col )
        byConnection.joinColor = { col.r, col.g, col.b }
    end

    -- disconnect messages
    local pnlDisconnect = vgui.Create( "DPanel", pnlConnectionTags )
    pnlDisconnect:Dock( RIGHT )
    pnlDisconnect:SetWide( 284 )
    pnlDisconnect:DockPadding( 6, 6, 6, 6 )

    pnlDisconnect.Paint = function( s, w, h )
        derma.SkinHook( "Paint", "Frame", s, w, h )
        return true
    end

    local checkDisconnect = vgui.Create( "DCheckBoxLabel", pnlDisconnect )
    checkDisconnect:SetText( L"tags.show_leave_messages" )
    checkDisconnect:SetTextColor( Color( 255, 255, 255 ) )
    checkDisconnect:SetValue( byConnection.showDisconnect )
    checkDisconnect:SizeToContents()
    checkDisconnect:Dock( TOP )

    checkDisconnect.OnChange = function( _, val )
        byConnection.showDisconnect = val
    end

    local labelLeavePrefix = vgui.Create( "DLabel", pnlDisconnect )
    labelLeavePrefix:SetText( L"tags.leave_prefix" )
    labelLeavePrefix:SizeToContents()
    labelLeavePrefix:Dock( TOP )
    labelLeavePrefix:DockMargin( 0, 12, 0, 4 )

    local entryLeavePrefix = vgui.Create( "DTextEntry", pnlDisconnect )
    entryLeavePrefix:SetPlaceholderText( L( "tags.leave_prefix" ) .. "..." )
    entryLeavePrefix:SetValue( byConnection.leavePrefix )
    entryLeavePrefix:Dock( TOP )

    entryLeavePrefix.OnChange = function()
        byConnection.leavePrefix = entryLeavePrefix:GetValue()
    end

    local labelLeaveSuffix = vgui.Create( "DLabel", pnlDisconnect )
    labelLeaveSuffix:SetText( L"tags.leave_suffix" )
    labelLeaveSuffix:SizeToContents()
    labelLeaveSuffix:Dock( TOP )
    labelLeaveSuffix:DockMargin( 0, 12, 0, 4 )

    local entryLeaveSuffix = vgui.Create( "DTextEntry", pnlDisconnect )
    entryLeaveSuffix:SetPlaceholderText( L( "tags.leave_suffix" ) .. "..." )
    entryLeaveSuffix:SetValue( byConnection.leaveSuffix )
    entryLeaveSuffix:Dock( TOP )

    entryLeaveSuffix.OnChange = function()
        byConnection.leaveSuffix = entryLeaveSuffix:GetValue()
    end

    local labelLeaveColor = vgui.Create( "DLabel", pnlDisconnect )
    labelLeaveColor:SetText( L"tags.leave_color" )
    labelLeaveColor:SizeToContents()
    labelLeaveColor:Dock( TOP )
    labelLeaveColor:DockMargin( 0, 8, 0, 0 )

    local leaveColorPicker = vgui.Create( "DColorMixer", pnlDisconnect )
    leaveColorPicker:Dock( FILL )
    leaveColorPicker:DockMargin( 0, 8, 0, 8 )
    leaveColorPicker:SetPalette( true )
    leaveColorPicker:SetAlphaBar( false )
    leaveColorPicker:SetWangs( true )
    leaveColorPicker:SetColor( Color(
        byConnection.leaveColor[1],
        byConnection.leaveColor[2],
        byConnection.leaveColor[3]
    ) )

    leaveColorPicker.ValueChanged = function( _, col )
        byConnection.leaveColor = { col.r, col.g, col.b }
    end

    -------- Apply the settings --------

    local buttonApply = vgui.Create( "DButton", frame )
    buttonApply:SetIcon( "icon16/accept.png" )
    buttonApply:SetText( L( "tags.apply" ) )
    buttonApply:Dock( BOTTOM )

    buttonApply._DefaultPaint = buttonApply.Paint

    buttonApply.Paint = function( s, w, h )
        s:_DefaultPaint( w, h )

        surface.SetDrawColor( 255, 255, 0, 180 * math.abs( math.sin( RealTime() * 3 ) ) )
        surface.DrawRect( 0, 0, w, h )
    end

    buttonApply.DoClick = function()
        local data = {
            connection = byConnection
        }

        if not table.IsEmpty( byTeam ) then
            data.byTeam = byTeam
        end

        if not table.IsEmpty( byId ) then
            data.byId = byId
        end

        data = table.IsEmpty( data ) and "{}" or util.TableToJSON( data )

        Derma_Query( L"tags.apply_query",
            L"tags.title",
            L"yes",
            function()
                net.Start( "customchat.set_tags", false )
                net.WriteString( data )
                net.SendToServer()

                frame:Close()
            end,
            L"no"
        )
    end
end
