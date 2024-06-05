local PANEL = {}

PANEL.buttonSelected = Color( 34, 52, 142 )
PANEL.buttonHover = Color( 255, 255, 255, 30 )

PANEL.indicatorBackground = Color( 200, 0, 0, 255 )
PANEL.indicatorText = Color( 255, 255, 255, 255 )

function PANEL:Init()
    self:SetCursor( "hand" )
    self.isSelected = false
    self.notificationCount = 0
    self.icon = vgui.Create( "DImage", self )
end

function PANEL:SetIcon( path )
    self.icon:SetImage( path )
end

function PANEL:PerformLayout( w, h )
    local size = math.max( w, h ) * 0.6

    self.icon:SetSize( size, size )
    self.icon:Center()
end

function PANEL:Paint( w, h )
    if self.isSelected then
        draw.RoundedBox( 4, 0, 0, w, h, self.buttonSelected )
    end

    if self:IsHovered() then
        surface.SetDrawColor( self.buttonHover:Unpack() )
        surface.DrawRect( 0, 0, w, h )
    end
end

function PANEL:PaintOver( w, h )
    if self.notificationCount > 0 then
        local size = 14
        local x = w - size - 2
        local y = h - size - 2

        draw.RoundedBox( size * 0.5, x, y, size, size, self.indicatorBackground )
        draw.SimpleText( self.notificationCount, "TargetIDSmall", x + size * 0.5, y + size * 0.5, self.indicatorText, 1, 1 )
    end
end

function PANEL:OnMousePressed( keyCode )
    if keyCode == MOUSE_LEFT then
        -- self -> channel list -> chat frame
        self:GetParent():GetParent():SetActiveChannel( self.channelId )
    end
end

vgui.Register( "CustomChat_ChannelButton", PANEL, "DPanel" )
