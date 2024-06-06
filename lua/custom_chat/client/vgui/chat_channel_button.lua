local PANEL = {}

PANEL.colorSelected = Color( 34, 52, 142 )
PANEL.colorHover = Color( 255, 255, 255, 30 )
PANEL.colorIndicator = Color( 200, 0, 0, 255 )
PANEL.colorText = Color( 255, 255, 255, 255 )
PANEL.hoverFunc = function() return false end

function PANEL:Init()
    self:SetCursor( "hand" )
    self.icon = vgui.Create( "DImage", self )

    self.isSelected = false
    self.notificationCount = 0
end

function PANEL:SetIcon( path )
    self.icon:Remove()

    if isentity( path ) and IsValid( path ) and path:IsPlayer() then
        self.icon = vgui.Create( "AvatarImage", self )
        self.icon:SetPlayer( path, 64 )
        self.icon:SetZPos( self:GetZPos() + 10 )
        self.icon.TestHover = self.hoverFunc

        return
    end

    self.icon = vgui.Create( "DImage", self )

    if type( path ) == "string" then
        self.icon:SetImage( path )
    end
end

function PANEL:PerformLayout( w, h )
    local size = math.max( w, h ) * 0.6

    self.icon:SetSize( size, size )
    self.icon:Center()
end

function PANEL:Paint( w, h )
    if self.isSelected then
        draw.RoundedBox( 4, 0, 0, w, h, self.colorSelected )
    end

    if self:IsHovered() then
        surface.SetDrawColor( self.colorHover:Unpack() )
        surface.DrawRect( 0, 0, w, h )
    end
end

function PANEL:PaintOver( w, h )
    if self.notificationCount > 0 then
        local size = 14
        local x = w - size - 2
        local y = h - size - 2

        draw.RoundedBox( size * 0.5, x, y, size, size, self.colorIndicator )
        draw.SimpleText( self.notificationCount, "TargetIDSmall", x + size * 0.5, y + size * 0.5, self.colorText, 1, 1 )
    end
end

function PANEL:OnMousePressed( keyCode )
    -- self -> channel list -> chat frame
    local frame = self:GetParent():GetParent()

    if keyCode == MOUSE_LEFT then
        frame:SetActiveChannel( self.channelId )
    end
end

vgui.Register( "CustomChat_ChannelButton", PANEL, "DPanel" )
