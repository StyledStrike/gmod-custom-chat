-- Panel for previewing and editing themes

local L = CustomChat.GetLanguageText

local PaintProperty = function( s, w, h )
    derma.SkinHook( "Paint", "Frame", s, w, h )
    return true
end

local function AddProperty( text, class, parent )
    local panel = vgui.Create( "DPanel", parent )
    panel:SetTall( class == "DColorMixer" and 150 or 50 )
    panel:Dock( TOP )
    panel:DockMargin( 0, 0, 0, 2 )
    panel.Paint = PaintProperty

    local label = vgui.Create( "DLabel", panel )
    label:SetPos( 25, 50 )
    label:SetText( L( text ) )
    label:SizeToContents()
    label:SetTextColor( color_white )
    label:Dock( TOP )
    label:DockMargin( 6, 5, 0, 0 )

    local item = vgui.Create( class, panel )
    item:Dock( TOP )
    item:DockMargin( 4, 8, 4, 0 )

    if class == "DNumSlider" then
        item:DockMargin( 8, 2, -24, 0 )

    elseif class == "DColorMixer" then
        item:Dock( FILL )
        item:DockMargin( 4, 10, 4, 4 )
        item:SetPalette( false )
        item:SetAlphaBar( true )
        item:SetWangs( true )
    end

    return item
end

local PANEL = {}

function PANEL:Init()
    self.parsedData = {}

    local panelProperties = vgui.Create( "DScrollPanel", self )
    panelProperties:SetPaintBackgroundEnabled( false )
    panelProperties:Dock( FILL )
    panelProperties:GetCanvas():DockPadding( 4, 4, 4, 4 )

    -- Name
    self.entryName = AddProperty( "theme.name", "DTextEntry", panelProperties )
    self.entryName:SetUpdateOnType( true )
    self.entryName.OnValueChange = function( _, value )
        self:ValueChanged( "name", value )
    end

    -- Description
    self.entryDescription = AddProperty( "theme.description", "DTextEntry", panelProperties )
    self.entryDescription:SetUpdateOnType( true )
    self.entryDescription.OnValueChange = function( _, value )
        self:ValueChanged( "description", value )
    end

    -- Font
    self.comboFont = AddProperty( "theme.font", "DComboBox", panelProperties )
    self.comboFont:SetSortItems( false )
    self.comboFont:AddChoice( L"theme.font_custom_item", nil, true )

    for _, font in ipairs( CustomChat.Theme.fonts ) do
        self.comboFont:AddChoice( font, nil )
    end

    self.comboFont.OnSelect = function( _, index )
        if self.loadingData then return end

        if index > 1 then
            self:ValueChanged( "font", CustomChat.Theme.fonts[index - 1] )
        else
            Derma_StringRequest( L"theme.font_custom", L"theme.font_custom_name", self.fontName, function( txt )
                self:ValueChanged( "font", string.JavascriptSafe( string.Trim( txt ) ) )
            end )
        end
    end

    -- Font Shadow
    self.buttonFontShadow = AddProperty( "theme.font_shadow", "DButton", panelProperties )
    self.buttonFontShadow:SetText( L"theme.font_shadow" )

    self.buttonFontShadow.DoClick = function()
        self.enableFontShadow = not self.enableFontShadow
        self.buttonFontShadow:SetIcon( self.enableFontShadow and "icon16/accept.png" or "icon16/cross.png" )
        self:ValueChanged( "font_shadow", self.enableFontShadow )
    end

    -- Slide-in Animation
    self.buttonSlideAnimation = AddProperty( "theme.slide_animation", "DButton", panelProperties )
    self.buttonSlideAnimation:SetText( L"theme.slide_animation" )

    self.buttonSlideAnimation.DoClick = function()
        self.enableSlideAnimation = not self.enableSlideAnimation
        self.buttonSlideAnimation:SetIcon( self.enableSlideAnimation and "icon16/accept.png" or "icon16/cross.png" )
        self:ValueChanged( "animate", self.enableSlideAnimation )
    end

    -- Player Avatars
    self.playerAvatars = AddProperty( "theme.avatars", "DButton", panelProperties )
    self.playerAvatars:SetText( L"theme.avatars" )

    self.playerAvatars.DoClick = function()
        self.enableAvatars = not self.enableAvatars
        self.playerAvatars:SetIcon( self.enableAvatars and "icon16/accept.png" or "icon16/cross.png" )
        self:ValueChanged( "avatars", self.enableAvatars )
    end

    -- Background Blur
    self.sliderBlur = AddProperty( "theme.bg_blur", "DNumSlider", panelProperties )
    self.sliderBlur:SetText( L"theme.bg_blur" )
    self.sliderBlur:SetMin( 0 )
    self.sliderBlur:SetMax( 8 )
    self.sliderBlur:SetDecimals( 0 )
    self.sliderBlur.Label:SetTextColor( Color( 255, 255, 255 ) )

    self.sliderBlur.OnValueChanged = function( _, value )
        value = math.floor( value )
        self:ValueChanged( "blur", value )
    end

    -- Corner Radius
    self.sliderCorner = AddProperty( "theme.corner_radius", "DNumSlider", panelProperties )
    self.sliderCorner:SetText( L"theme.corner_radius" )
    self.sliderCorner:SetMin( 0 )
    self.sliderCorner:SetMax( 32 )
    self.sliderCorner:SetDecimals( 0 )
    self.sliderCorner.Label:SetTextColor( Color( 255, 255, 255 ) )

    self.sliderCorner.OnValueChanged = function( _, value )
        value = math.floor( value )
        self:ValueChanged( "corner_radius", value )
    end

    -- Padding
    self.sliderPadding = AddProperty( "theme.padding", "DNumSlider", panelProperties )
    self.sliderPadding:SetText( L"theme.padding" )
    self.sliderPadding:SetMin( 0 )
    self.sliderPadding:SetMax( 64 )
    self.sliderPadding:SetDecimals( 0 )
    self.sliderPadding.Label:SetTextColor( Color( 255, 255, 255 ) )

    self.sliderPadding.OnValueChanged = function( _, value )
        value = math.floor( value )
        self:ValueChanged( "padding", value )
    end

    -- Background Color
    self.mixerBackground = AddProperty( "theme.color.bg", "DColorMixer", panelProperties )
    self.mixerBackground.ValueChanged = function( _, color )
        self:ColorChanged( "backgroundColor", color )
    end

    -- Input Text Color
    self.mixerInput = AddProperty( "theme.color.input", "DColorMixer", panelProperties )
    self.mixerInput.ValueChanged = function( _, color )
        self:ColorChanged( "inputColor", color )
    end

    -- Input Background Color
    self.mixerInputBackground = AddProperty( "theme.color.input_bg", "DColorMixer", panelProperties )
    self.mixerInputBackground.ValueChanged = function( _, color )
        self:ColorChanged( "inputBackgroundColor", color )
    end

    -- Scrollbar Color
    self.mixerScrollBar = AddProperty( "theme.color.scroll_bar", "DColorMixer", panelProperties )
    self.mixerScrollBar.ValueChanged = function( _, color )
        self:ColorChanged( "scrollBarColor", color )
    end

    -- Scroll Background Color
    self.mixerScrollBackground = AddProperty( "theme.color.scroll_bg", "DColorMixer", panelProperties )
    self.mixerScrollBackground.ValueChanged = function( _, color )
        self:ColorChanged( "scrollBackgroundColor", color )
    end

    -- Selected Text Background Color
    self.mixerHighlight = AddProperty( "theme.color.highlight", "DColorMixer", panelProperties )
    self.mixerHighlight.ValueChanged = function( _, color )
        self:ColorChanged( "highlightColor", color )
    end
end

function PANEL:LoadThemeData( data )
    -- prevent triggering "OnThemeChanged" while we load the data
    self.loadingData = true

    self.entryName:SetValue( data.name or "" )
    self.entryDescription:SetValue( data.description or "" )

    CustomChat.Theme.ParseTheme( data, self )

    local fontIndex = table.KeyFromValue( CustomChat.Theme.fonts, self.fontName )
    self.comboFont:ChooseOptionID( fontIndex and fontIndex + 1 or 1 )

    self.buttonFontShadow:SetIcon( self.enableFontShadow and "icon16/accept.png" or "icon16/cross.png" )
    self.buttonSlideAnimation:SetIcon( self.enableSlideAnimation and "icon16/accept.png" or "icon16/cross.png" )
    self.playerAvatars:SetIcon( self.enableAvatars and "icon16/accept.png" or "icon16/cross.png" )

    self.sliderBlur:SetValue( self.backgroundBlur )
    self.sliderCorner:SetValue( self.cornerRadius )
    self.sliderPadding:SetValue( self.padding )

    self.mixerBackground:SetColor( self.backgroundColor )
    self.mixerInput:SetColor( self.inputColor )
    self.mixerInputBackground:SetColor( self.inputBackgroundColor )

    self.mixerScrollBar:SetColor( self.scrollBarColor )
    self.mixerScrollBackground:SetColor( self.scrollBackgroundColor )
    self.mixerHighlight:SetColor( self.highlightColor )

    self.loadingData = nil
end

function PANEL:SetDisabled( disabled )
    if self.labelDisabled then
        self.labelDisabled:Remove()
        self.labelDisabled = nil
    end

    self.entryName:SetDisabled( disabled )
    self.entryDescription:SetDisabled( disabled )

    self.comboFont:SetDisabled( disabled )
    self.buttonFontShadow:SetDisabled( disabled )
    self.buttonSlideAnimation:SetDisabled( disabled )
    self.playerAvatars:SetDisabled( disabled )

    self.sliderBlur:SetEnabled( not disabled )
    self.sliderCorner:SetEnabled( not disabled )
    self.sliderPadding:SetEnabled( not disabled )

    self.mixerBackground:SetDisabled( disabled )
    self.mixerInput:SetDisabled( disabled )
    self.mixerInputBackground:SetDisabled( disabled )

    self.mixerScrollBar:SetDisabled( disabled )
    self.mixerScrollBackground:SetDisabled( disabled )
    self.mixerHighlight:SetDisabled( disabled )

    if not disabled then return end

    self.labelDisabled = vgui.Create( "DLabel", self )
    self.labelDisabled:SetPos( 25, 50 )
    self.labelDisabled:SetText( L"theme.no_edit" )
    self.labelDisabled:SetTextColor( Color( 255, 50, 50 ) )
    self.labelDisabled:SetContentAlignment( 5 )
    self.labelDisabled:Dock( TOP )
    self.labelDisabled:DockMargin( 6, 5, 0, 0 )
end

function PANEL:Paint( w, h )
    surface.SetDrawColor( 30, 30, 30, 255 )
    surface.DrawRect( 0, 0, w, h )
end

local colorKeys = {
    backgroundColor = { "bg_r", "bg_g", "bg_b", "bg_a" },
    inputColor = { "input_r", "input_g", "input_b", "input_a" },
    inputBackgroundColor = { "input_bg_r", "input_bg_g", "input_bg_b", "input_bg_a" },

    scrollBarColor = { "scroll_bar_r", "scroll_bar_g", "scroll_bar_b", "scroll_bar_a" },
    scrollBackgroundColor = { "scroll_bg_r", "scroll_bg_g", "scroll_bg_b", "scroll_bg_a" },
    highlightColor = { "highlight_r", "highlight_g", "highlight_b", "highlight_a" },
}

function PANEL:ColorChanged( key, value )
    local actualKeys = colorKeys[key]

    self:ValueChanged( actualKeys[1], value.r )
    self:ValueChanged( actualKeys[2], value.g )
    self:ValueChanged( actualKeys[3], value.b )
    self:ValueChanged( actualKeys[4], value.a )
end

function PANEL:ValueChanged( key, value )
    if self.loadingData then return end

    self.OnThemeChanged( key, value )
end

function PANEL.OnThemeChanged( _key, _value ) end

vgui.Register( "CustomChatThemeEditor", PANEL, "DPanel" )
