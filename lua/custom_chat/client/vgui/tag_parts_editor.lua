local L = CustomChat.GetLanguageText
local PANEL = {}

function PANEL:Init()
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
    labelHint:SetText( L"tags.piece_tip" )
    labelHint:SizeToContents()
    labelHint:SetColor( Color( 100, 100, 255 ) )
    labelHint:Dock( TOP )

    self.textEntry = vgui.Create( "DTextEntry", panelOptions )
    self.textEntry:Dock( TOP )
    self.textEntry:DockMargin( 0, 5, 0, 0 )
    self.textEntry:SetPlaceholderText( L"tags.text_placeholder" )

    local colorPicker = vgui.Create( "DColorMixer", panelOptions )
    colorPicker:Dock( FILL )
    colorPicker:DockMargin( 0, 8, 0, 8 )
    colorPicker:SetPalette( true )
    colorPicker:SetAlphaBar( false )
    colorPicker:SetWangs( true )
    colorPicker:SetColor( Color( 255, 0, 0 ) )

    self.buttonRemove = vgui.Create( "DButton", panelOptions )
    self.buttonRemove:SetIcon( "icon16/delete.png" )
    self.buttonRemove:SetText( L( "tags.remove_piece" ) )
    self.buttonRemove:Dock( BOTTOM )
    self.buttonRemove:SetEnabled( false )

    self.buttonAdd = vgui.Create( "DButton", panelOptions )
    self.buttonAdd:SetIcon( "icon16/arrow_left.png" )
    self.buttonAdd:SetText( L( "tags.add_piece" ) )
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

    self.buttonRemove.DoClick = function()
        table.remove( self.parts, self.selectedIndex )
        self:RefreshList()
    end

    self.textEntry.OnChange = function()
        self.buttonAdd:SetEnabled( self.textEntry:GetValue() ~= "" )
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

        self.buttonAdd:SetText( L( "tags.update_piece" ) )
        self.buttonAdd:SetEnabled( true )
        self.buttonRemove:SetEnabled( true )
    end

    self.list.OnRowRightClick = function( _, index )
        local optionsMenu = DermaMenu()

        optionsMenu:AddOption( L"tags.remove_piece", function()
            table.remove( self.parts, index )
            self:RefreshList()
        end ):SetIcon( "icon16/delete.png" )

        optionsMenu:Open()
    end
end

function PANEL:SetParts( parts )
    self.parts = table.Copy( parts )
    self:RefreshList()
end

function PANEL:RefreshList()
    self.buttonAdd:SetText( L( "tags.add_piece" ) )
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

    self.OnPartsChange( self.parts )
end

function PANEL.OnPartsChange( _parts ) end

vgui.Register( "CustomChat_TagPartsEditor", PANEL, "DPanel" )
