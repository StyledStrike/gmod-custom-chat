local Tags = SChat.Tags or {
    byId = {},
    byTeam = {}
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

hook.Add( "OnPlayerChat", "SChat.AddCustomTags", function( ply, text, isTeam, isDead )
    if not SChat.USE_TAGS then return end

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

    local nameColor = GAMEMODE:GetTeamColor( ply )
    local messageColor = Color( 255, 255, 255 )

    if #parts > 0 then
        for _, v in pairs( parts ) do
            local color = Color( v[2], v[3], v[4] )

            if v[1] == "NAME_COL" then
                nameColor = color
            elseif v[1] == "MESSAGE_COL" then
                messageColor = color
            else
                Insert( color )
                Insert( v[1] )
            end
        end
    end

    Insert( nameColor )
    Insert( ply:Nick() )

    Insert( messageColor )
    Insert( ": " .. text )

    chat.AddText( unpack( message ) )

    return true
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

    local pnlOptions = vgui.Create( "DPanel", self )
    pnlOptions:Dock( RIGHT )
    pnlOptions:SetWide( 200 )

    local labelHint = vgui.Create( "DLabel", pnlOptions )
    labelHint:SetText( "Use NAME_COL and MESSAGE_COL\nto change the name/message\ncolors respectively." )
    labelHint:SizeToContents()
    labelHint:SetColor( Color( 100, 100, 255 ) )
    labelHint:Dock( TOP )

    self.textEntry = vgui.Create( "DTextEntry", pnlOptions )
    self.textEntry:Dock( TOP )
    self.textEntry:DockMargin( 0, 5, 0, 0 )
    self.textEntry:SetPlaceholderText( "Add a piece of text..." )

    local colorPicker = vgui.Create( "DColorMixer", pnlOptions )
    colorPicker:Dock( FILL )
    colorPicker:DockMargin( 0, 8, 0, 8 )
    colorPicker:SetPalette( true )
    colorPicker:SetAlphaBar( false )
    colorPicker:SetWangs( true )
    colorPicker:SetColor( Color( 255, 0, 0 ) )

    self.btnRemove = vgui.Create( "DButton", pnlOptions )
    self.btnRemove:SetIcon( "icon16/delete.png" )
    self.btnRemove:SetText( " Remove piece" )
    self.btnRemove:Dock( BOTTOM )
    self.btnRemove:SetEnabled( false )

    self.btnAdd = vgui.Create( "DButton", pnlOptions )
    self.btnAdd:SetIcon( "icon16/arrow_left.png" )
    self.btnAdd:SetText( " Add piece" )
    self.btnAdd:Dock( BOTTOM )
    self.btnAdd:SetEnabled( false )

    self.btnAdd.DoClick = function()
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

        self.btnAdd:SetText( " Update piece" )
        self.btnAdd:SetEnabled( true )
        self.btnRemove:SetEnabled( true )
    end

    self.list.OnRowRightClick = function( _, index )
        local optionsMenu = DermaMenu( false, self )

        optionsMenu:AddOption( "Remove", function()
            table.remove( self.parts, index )
            self:RefreshList()
        end ):SetIcon( "icon16/delete.png" )
    end

    self.btnRemove.DoClick = function()
        table.remove( self.parts, self.selectedIndex )
        self:RefreshList()
    end

    self.textEntry.OnChange = function()
        self.btnAdd:SetEnabled( self.textEntry:GetValue() ~= "" )
    end
end

function PARTS_PANEL:SetParts( parts )
    self.parts = table.Copy( parts )
    self:RefreshList()
end

function PARTS_PANEL:RefreshList()
    self.btnAdd:SetText( " Add piece" )
    self.btnAdd:SetEnabled( false )
    self.btnRemove:SetEnabled( false )
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

    local pnlSteamIdOptions = vgui.Create( "DHorizontalDivider", pnlSteamIdTags )
    pnlSteamIdOptions:Dock( LEFT )
    pnlSteamIdOptions:SetWide( 150 )

    local listIds = vgui.Create( "DListView", pnlSteamIdOptions )
    listIds:Dock( FILL )
    listIds:SetMultiSelect( false )
    listIds:AddColumn( "SteamID" )

    local btnRemoveUser = vgui.Create( "DButton", pnlSteamIdOptions )
    btnRemoveUser:SetIcon( "icon16/user_delete.png" )
    btnRemoveUser:SetText( " Remove SteamID" )
    btnRemoveUser:SetEnabled( false )
    btnRemoveUser:Dock( BOTTOM )

    local btnAddUser = vgui.Create( "DButton", pnlSteamIdOptions )
    btnAddUser:SetIcon( "icon16/user_add.png" )
    btnAddUser:SetText( " Add SteamID" )
    btnAddUser:SetEnabled( false )
    btnAddUser:Dock( BOTTOM )

    local entrySteamId = vgui.Create( "DTextEntry", pnlSteamIdOptions )
    entrySteamId:Dock( BOTTOM )
    entrySteamId:SetPlaceholderText( "SteamID..." )

    entrySteamId.OnChange = function()
        btnAddUser:SetEnabled( entrySteamId:GetValue() ~= "" )
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
        btnRemoveUser:SetEnabled( true )
    end

    UpdateSteamIdsList()
    listIds:SelectFirstItem()

    btnAddUser.DoClick = function()
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

        btnAddUser:SetEnabled( false )
        listIds:ClearSelection()

        local line = listIds:AddLine( id )
        listIds:SelectItem( line )
    end

    btnRemoveUser.DoClick = function()
        byId[currentSteamId] = nil
        UpdateSteamIdsList()
        listIds:SelectFirstItem()
    end

    local btnApply = vgui.Create( "DButton", frame )
    btnApply:SetIcon( "icon16/accept.png" )
    btnApply:SetText( " Apply all changes" )
    btnApply:Dock( BOTTOM )

    btnApply.DoClick = function()
        local data = {}

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
