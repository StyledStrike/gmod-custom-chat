local Tags = SChat.Tags or {
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

SChat.Tags = Tags

hook.Add( "InitPostEntity", "SChat.PreventChatTagsConflict", function()
    hook.Remove( "InitPostEntity", "SChat.PreventChatTagsConflict" )

    if not aTags then
        SChat.USE_TAGS = true
    end
end )

net.Receive( "schat.set_tags", function()
    SChat.PrintF( "Received chat tags from the server." )

    local data = net.ReadString()
    data = util.JSONToTable( data )

    if data then
        Tags.byId = data.byId or {}
        Tags.byTeam = data.byTeam or {}
        Tags.connection = data.connection or Tags.connection
    else
        SChat.PrintF( "Failed to parse tags from the server!" )
    end
end )

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

hook.Add( "OnPlayerChat", "SChat.AddCustomTags", function( ply, text, isTeam, isDead )
    if not SChat.USE_TAGS then return end
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
end, HOOK_LOW )

gameevent.Listen( "player_connect_client" )
gameevent.Listen( "player_disconnect" )

hook.Add( "player_connect_client", "SChat.ShowConnectMessages", function( data )
    if not Tags.connection.showConnect then return end

    local c = Tags.connection.joinColor
    local name = data.name

    -- only use custom player block if schat is enabled
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

    SChat:AppendMessage( {
        Color( 255, 255, 255 ), Tags.connection.joinPrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. data.networkid .. "> ",
        Color( 255, 255, 255 ), Tags.connection.joinSuffix
    } )
end, HOOK_LOW )

hook.Add( "player_disconnect", "SChat.ShowDisconnectMessages", function( data )
    if not Tags.connection.showDisconnect then return end

    local c = Tags.connection.leaveColor
    local name = data.name

    -- only use custom player block if schat is enabled
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

    SChat:AppendMessage( {
        Color( 255, 255, 255 ), Tags.connection.leavePrefix,
        Color( c[1], c[2], c[3] ), name,
        Color( 150, 150, 150 ), " <" .. data.networkid .. "> ",
        Color( 255, 255, 255 ), Tags.connection.leaveSuffix,
        Color( 150, 150, 150 ), " (" .. data.reason .. ")"
    } )
end, HOOK_LOW )

local PARTS_PANEL = {}

function PARTS_PANEL:Init()
    self.parts = {}
    self:DockPadding( 8, 8, 8, 8 )

    self.list = vgui.Create( "DListView", self )
    self.list:Dock( FILL )
    self.list:DockMargin( 0, 0, 8, 0 )
    self.list:SetMultiSelect( false )
    self.list:SetHideHeaders( true )
    self.list:AddColumn( "-" )

    local panelOptions = vgui.Create( "DPanel", self )
    panelOptions:Dock( RIGHT )
    panelOptions:SetWide( 200 )

    local labelHint = vgui.Create( "DLabel", panelOptions )
    labelHint:SetText( "Use NAME_COL and MESSAGE_COL\nto change the name/message\ncolors respectively." )
    labelHint:SizeToContents()
    labelHint:SetColor( Color( 100, 100, 255 ) )
    labelHint:Dock( TOP )

    self.textEntry = vgui.Create( "DTextEntry", panelOptions )
    self.textEntry:Dock( TOP )
    self.textEntry:DockMargin( 0, 5, 0, 0 )
    self.textEntry:SetPlaceholderText( "Add a piece of text..." )

    local colorPicker = vgui.Create( "DColorMixer", panelOptions )
    colorPicker:Dock( FILL )
    colorPicker:DockMargin( 0, 8, 0, 8 )
    colorPicker:SetPalette( true )
    colorPicker:SetAlphaBar( false )
    colorPicker:SetWangs( true )
    colorPicker:SetColor( Color( 255, 0, 0 ) )

    self.buttonRemove = vgui.Create( "DButton", panelOptions )
    self.buttonRemove:SetIcon( "icon16/delete.png" )
    self.buttonRemove:SetText( " Remove piece" )
    self.buttonRemove:Dock( BOTTOM )
    self.buttonRemove:SetEnabled( false )

    self.buttonAdd = vgui.Create( "DButton", panelOptions )
    self.buttonAdd:SetIcon( "icon16/arrow_left.png" )
    self.buttonAdd:SetText( " Add piece" )
    self.buttonAdd:Dock( BOTTOM )
    self.buttonAdd:SetEnabled( false )

    self.buttonAdd.DoClick = function()
        local text = self.textEntry:GetValue()
        local color = colorPicker:GetColor()

        self.textEntry:SetValue( "" )

        if self.selectedIndex then
            self.parts[self.selectedIndex] = { text, color.r, color.g, color.b }
            self:RefreshList()

            return
        end

        self.parts[#self.parts + 1] = { text, color.r, color.g, color.b }
        self:RefreshList()
    end

    self.list.OnRowSelected = function( _, index )
        if self.selectedIndex == index then
            self:RefreshList()

            return
        end

        self.selectedIndex = index

        local part = self.parts[index]

        self.textEntry:SetValue( part[1] )
        colorPicker:SetColor( Color( part[2], part[3], part[4] ) )

        self.buttonAdd:SetText( " Update piece" )
        self.buttonAdd:SetEnabled( true )
        self.buttonRemove:SetEnabled( true )
    end

    self.list.OnRowRightClick = function( _, index )
        local optionsMenu = DermaMenu( false, self )

        optionsMenu:AddOption( "Remove", function()
            table.remove( self.parts, index )
            self:RefreshList()
        end ):SetIcon( "icon16/delete.png" )
    end

    self.buttonRemove.DoClick = function()
        table.remove( self.parts, self.selectedIndex )
        self:RefreshList()
    end

    self.textEntry.OnChange = function()
        self.buttonAdd:SetEnabled( self.textEntry:GetValue() ~= "" )
    end
end

function PARTS_PANEL:SetParts( parts )
    self.parts = table.Copy( parts )
    self:RefreshList()
end

function PARTS_PANEL:RefreshList()
    self.buttonAdd:SetText( " Add piece" )
    self.buttonAdd:SetEnabled( false )
    self.buttonRemove:SetEnabled( false )
    self.textEntry:SetValue( "" )

    self.selectedIndex = nil
    self.list:ClearSelection()
    self.list:Clear()

    local function PaintLine( s, w, h )
        surface.SetDrawColor( 0, 0, 0 )
        surface.DrawRect( w - 21, 1, 18, h - 2 )

        surface.SetDrawColor( s._partR, s._partG, s._partB )
        surface.DrawRect( w - 20, 2, 16, h - 4 )
    end

    for _, part in ipairs( self.parts ) do
        local line = self.list:AddLine( part[1] )
        line._partR = part[2]
        line._partG = part[3]
        line._partB = part[4]
        line.PaintOver = PaintLine
    end

    if self.OnPartsChange then
        self.OnPartsChange( self.parts )
    end
end

vgui.Register( "SChatTagEditor", PARTS_PANEL, "DPanel" )

function Tags:ShowChatTagsPanel()
    chat.Close()

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 600, 400 )
    frame:SetTitle( "Server Chat Tags" )
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
    sheet:AddSheet( "Tags for teams", pnlTeamTags, "icon16/group.png" )

    local listTeams = vgui.Create( "DListView", pnlTeamTags )
    listTeams:Dock( LEFT )
    listTeams:SetWide( 150 )
    listTeams:SetMultiSelect( false )
    listTeams:AddColumn( "ID" )
    listTeams:AddColumn( "Team" )

    local teamParts = vgui.Create( "SChatTagEditor", pnlTeamTags )
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
    sheet:AddSheet( "Tags for specific players", pnlSteamIdTags, "icon16/user.png" )

    local pnlSteamIdOptions = vgui.Create( "DPanel", pnlSteamIdTags )
    pnlSteamIdOptions:Dock( LEFT )
    pnlSteamIdOptions:SetWide( 150 )

    local listIds = vgui.Create( "DListView", pnlSteamIdOptions )
    listIds:Dock( FILL )
    listIds:SetMultiSelect( false )
    listIds:AddColumn( "SteamID" )

    local buttonRemoveUser = vgui.Create( "DButton", pnlSteamIdOptions )
    buttonRemoveUser:SetIcon( "icon16/user_delete.png" )
    buttonRemoveUser:SetText( " Remove SteamID" )
    buttonRemoveUser:SetEnabled( false )
    buttonRemoveUser:Dock( BOTTOM )

    local buttonAddUser = vgui.Create( "DButton", pnlSteamIdOptions )
    buttonAddUser:SetIcon( "icon16/user_add.png" )
    buttonAddUser:SetText( " Add SteamID" )
    buttonAddUser:SetEnabled( false )
    buttonAddUser:Dock( BOTTOM )

    local entrySteamId = vgui.Create( "DTextEntry", pnlSteamIdOptions )
    entrySteamId:Dock( BOTTOM )
    entrySteamId:SetPlaceholderText( "SteamID..." )

    entrySteamId.OnChange = function()
        buttonAddUser:SetEnabled( entrySteamId:GetValue() ~= "" )
    end

    local steamIdParts = vgui.Create( "SChatTagEditor", pnlSteamIdTags )
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

    buttonAddUser.DoClick = function()
        local id = string.Trim( entrySteamId:GetValue() )

        if util.SteamIDTo64( id ) == "0" then
            Derma_Message( "Invalid SteamID!", "Input error", "OK" )

            return
        end

        if byId[id] then
            Derma_Message( "Thah SteamID is on the list already!", "Input error", "OK" )

            return
        end

        byId[id] = {}

        buttonAddUser:SetEnabled( false )
        listIds:ClearSelection()

        local line = listIds:AddLine( id )
        listIds:SelectItem( line )
    end

    buttonRemoveUser.DoClick = function()
        byId[currentSteamId] = nil
        UpdateSteamIdsList()
        listIds:SelectFirstItem()
    end

    -------- Tags by steamid --------

    local byConnection = table.Copy( Tags.connection )

    local pnlConnectionTags = vgui.Create( "DPanel", sheet )
    pnlConnectionTags:SetPaintBackground( false )
    sheet:AddSheet( "Connect/Disconnect messages", pnlConnectionTags, "icon16/group_go.png" )

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
    checkConnect:SetText( "Show custom connection messages" )
    checkConnect:SetTextColor( Color( 255, 255, 255 ) )
    checkConnect:SetValue( byConnection.showConnect )
    checkConnect:SizeToContents()
    checkConnect:Dock( TOP )

    checkConnect.OnChange = function( _, val )
        byConnection.showConnect = val
    end

    local labelJoinPrefix = vgui.Create( "DLabel", pnlConnect )
    labelJoinPrefix:SetText( "Join prefix" )
    labelJoinPrefix:SizeToContents()
    labelJoinPrefix:Dock( TOP )
    labelJoinPrefix:DockMargin( 0, 12, 0, 4 )

    local entryJoinPrefix = vgui.Create( "DTextEntry", pnlConnect )
    entryJoinPrefix:SetPlaceholderText( "Join prefix..." )
    entryJoinPrefix:SetValue( byConnection.joinPrefix )
    entryJoinPrefix:Dock( TOP )

    entryJoinPrefix.OnChange = function()
        byConnection.joinPrefix = entryJoinPrefix:GetValue()
    end

    local labelJoinSuffix = vgui.Create( "DLabel", pnlConnect )
    labelJoinSuffix:SetText( "Join suffix" )
    labelJoinSuffix:SizeToContents()
    labelJoinSuffix:Dock( TOP )
    labelJoinSuffix:DockMargin( 0, 12, 0, 4 )

    local entryJoinSuffix = vgui.Create( "DTextEntry", pnlConnect )
    entryJoinSuffix:SetPlaceholderText( "Join suffix..." )
    entryJoinSuffix:SetValue( byConnection.joinSuffix )
    entryJoinSuffix:Dock( TOP )

    entryJoinSuffix.OnChange = function()
        byConnection.joinSuffix = entryJoinSuffix:GetValue()
    end

    local labelJoinColor = vgui.Create( "DLabel", pnlConnect )
    labelJoinColor:SetText( "Connected player color" )
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
    checkDisconnect:SetText( "Show custom disconnection messages" )
    checkDisconnect:SetTextColor( Color( 255, 255, 255 ) )
    checkDisconnect:SetValue( byConnection.showDisconnect )
    checkDisconnect:SizeToContents()
    checkDisconnect:Dock( TOP )

    checkDisconnect.OnChange = function( _, val )
        byConnection.showDisconnect = val
    end

    local labelLeavePrefix = vgui.Create( "DLabel", pnlDisconnect )
    labelLeavePrefix:SetText( "Leave prefix" )
    labelLeavePrefix:SizeToContents()
    labelLeavePrefix:Dock( TOP )
    labelLeavePrefix:DockMargin( 0, 12, 0, 4 )

    local entryLeavePrefix = vgui.Create( "DTextEntry", pnlDisconnect )
    entryLeavePrefix:SetPlaceholderText( "Leave prefix..." )
    entryLeavePrefix:SetValue( byConnection.leavePrefix )
    entryLeavePrefix:Dock( TOP )

    entryLeavePrefix.OnChange = function()
        byConnection.leavePrefix = entryLeavePrefix:GetValue()
    end

    local labelLeaveSuffix = vgui.Create( "DLabel", pnlDisconnect )
    labelLeaveSuffix:SetText( "Leave suffix" )
    labelLeaveSuffix:SizeToContents()
    labelLeaveSuffix:Dock( TOP )
    labelLeaveSuffix:DockMargin( 0, 12, 0, 4 )

    local entryLeaveSuffix = vgui.Create( "DTextEntry", pnlDisconnect )
    entryLeaveSuffix:SetPlaceholderText( "Join suffix..." )
    entryLeaveSuffix:SetValue( byConnection.leaveSuffix )
    entryLeaveSuffix:Dock( TOP )

    entryLeaveSuffix.OnChange = function()
        byConnection.leaveSuffix = entryLeaveSuffix:GetValue()
    end

    local labelLeaveColor = vgui.Create( "DLabel", pnlDisconnect )
    labelLeaveColor:SetText( "Disconnected player color" )
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
    buttonApply:SetText( " Apply all changes" )
    buttonApply:Dock( BOTTOM )

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

        Derma_Query( "This action will apply the chat tags on this server.\nAre you sure?",
            "Set Chat Tags", "Yes", function()
                net.Start( "schat.set_tags", false )
                net.WriteString( data )
                net.SendToServer()

                frame:Close()
            end,
            "No" )
    end
end
