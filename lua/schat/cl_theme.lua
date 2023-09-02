local Theme = SChat.Theme or {
    path = "schat_theme.json",

    availableFonts = {
        "Arial",
        "Roboto",
        "Lucida Console",
        "Comic Sans MS",
        "Calibri",
        "Consolas",
        "Impact",
        "Helvetica Neue",
        "monospace"
    }
}

SChat.Theme = Theme

function Theme:Save()
    file.Write( self.path, self:ToJSON() )
end

function Theme:Load()
    local rawData = file.Read( self.path, "DATA" )

    if rawData then
        local success, errorMessage = self:Import( rawData )

        if not success then
            SChat.PrintF( "Failed to load %s: %s", self.path, errorMessage )
        end
    end
end

function Theme:ToJSON()
    return util.TableToJSON( {
        pad = self.padding,
        corner = self.cornerRadius,
        blur = self.blur,

        font = self.fontName,
        font_shadow = self.fontShadow,
        slide_anim = self.slideAnimation,

        input = self.input,
        input_bg = self.inputBackground,
        highlight = self.highlight,
        background = self.background,

        scroll_bg = self.scrollbarBackground,
        scroll_thumb = self.scrollbarThumb
    }, false )
end

function Theme:Import( data )
    if type( data ) ~= "string" then
        return false, "Invalid data"
    end

    data = string.Trim( data )

    if string.len( data ) == 0 then
        return false, "JSON is empty"
    end

    data = util.JSONToTable( data )

    if not data then
        return false, "Invalid JSON"
    end

    local Settings = SChat.Settings

    if data.pad then
        self.padding = Settings:ValidateInteger( data.pad, 0, 64 )
    end

    if data.corner then
        self.cornerRadius = Settings:ValidateInteger( data.corner, 0, 32 )
    end

    if data.blur then
        self.blur = Settings:ValidateInteger( data.blur, 0, 8 )
    end

    if type( data.font ) == "string" then
        self.fontName = data.font
    end

    self.fontShadow = Either( data.font_shadow, true, false )
    self.slideAnimation = Either( data.slide_anim, true, false )

    if data.input then
        self.input = Settings:ValidateColor( data.input )
    end

    if data.input_bg then
        self.inputBackground = Settings:ValidateColor( data.input_bg )
    end

    if data.highlight then
        self.highlight = Settings:ValidateColor( data.highlight )
    end

    if data.background then
        self.background = Settings:ValidateColor( data.background )
    end

    if data.scroll_bg then
        self.scrollbarBackground = Settings:ValidateColor( data.scroll_bg )
    end

    if data.scroll_thumb then
        self.scrollbarThumb = Settings:ValidateColor( data.scroll_thumb )
    end

    self.imported = true

    return true
end

function Theme:Reset()
    self.imported = false

    self.padding = 8
    self.cornerRadius = 8
    self.blur = 4

    self.fontName = self.availableFonts[1]
    self.fontShadow = true
    self.slideAnimation = true

    self.input = Color( 255, 255, 255, 255 )
    self.inputBackground = Color( 0, 0, 0, 100 )
    self.highlight = Color( 95, 181, 231 )
    self.background = Color( 40, 40, 40, 200 )

    self.scrollbarBackground = Color( 0, 0, 0, 80 )
    self.scrollbarThumb = Color( 120, 120, 120, 255 )
end

function Theme:ShowCustomizePanel()
    if IsValid( self.customizeFrame ) then
        self.customizeFrame:RequestFocus()
        return
    end

    self.customizeFrame = SChat:CreateSidePanel( "Customize Theme", true )
    self.hasChanged = false

    self.customizeFrame.OnClose = function()
        if self.hasChanged then
            self:Save()
        end
    end

    local fields = {
        {
            index = "font",
            label = "Font & Behaviour"
        },
        {
            index = "input",
            label = "Input Text",
            class = "DColorMixer"
        },
        {
            index = "inputBackground",
            label = "Input Background",
            class = "DColorMixer"
        },
        {
            index = "highlight",
            label = "Highlighted Text",
            class = "DColorMixer"
        },
        {
            index = "background",
            label = "Chat Background",
            class = "DColorMixer"
        },
        {
            index = "cornerRadius",
            label = "Corner Radius",
            class = "DNumSlider",
            min = 0,
            max = 32
        },
        {
            index = "padding",
            label = "Padding",
            class = "DNumSlider",
            min = 0,
            max = 64
        },
        {
            index = "blur",
            label = "Blur",
            class = "DNumSlider",
            min = 0,
            max = 8
        },
        {
            index = "scrollbarBackground",
            label = "Scrollbar Background",
            class = "DColorMixer"
        },
        {
            index = "scrollbarThumb",
            label = "Scrollbar Handle",
            class = "DColorMixer"
        }
    }

    local fieldEditor

    local function setCurrentField( i )
        local f = fields[i]

        if IsValid( fieldEditor ) then
            fieldEditor:Remove()
        end

        if f.index == "font" then
            fieldEditor = vgui.Create( "DPanel", self.customizeFrame )
            fieldEditor:SetPaintBackground( false )
            fieldEditor:Dock( FILL )
            fieldEditor:DockMargin( 8, 8, 8, 0 )

            local cmbFonts = vgui.Create( "DComboBox", fieldEditor )
            cmbFonts:Dock( TOP )
            cmbFonts:SetSortItems( false )
            cmbFonts:AddChoice( "<Custom>", nil, true )

            for _, font in ipairs( self.availableFonts ) do
                cmbFonts:AddChoice( font, nil, font == self.fontName )
            end

            cmbFonts.OnSelect = function( _, index )
                if index > 1 then
                    self.fontName = self.availableFonts[index - 1]
                    SChat:ApplyTheme()
                else
                    Derma_StringRequest( "Custom Font", "Please enter the desired font name.", self.fontName, function( txt )
                        self.fontName = string.JavascriptSafe( string.Trim( txt ) )
                        SChat:ApplyTheme()
                    end )
                end
            end

            local tglFontShadow = vgui.Create( "DButton", fieldEditor )
            tglFontShadow:SetText( "Font Shadow" )
            tglFontShadow:SetIcon( self.fontShadow and "icon16/accept.png" or "icon16/cross.png" )
            tglFontShadow:Dock( TOP )
            tglFontShadow:DockMargin( 0, 8, 0, 0 )

            tglFontShadow.DoClick = function()
                self.fontShadow = not self.fontShadow
                tglFontShadow:SetIcon( self.fontShadow and "icon16/accept.png" or "icon16/cross.png" )
                SChat:ApplyTheme()
            end

            local tglSlideAnim = vgui.Create( "DButton", fieldEditor )
            tglSlideAnim:SetText( "Slide-In Animation" )
            tglSlideAnim:SetIcon( self.slideAnimation and "icon16/accept.png" or "icon16/cross.png" )
            tglSlideAnim:Dock( TOP )
            tglSlideAnim:DockMargin( 0, 8, 0, 0 )

            tglSlideAnim.DoClick = function()
                self.slideAnimation = not self.slideAnimation
                tglSlideAnim:SetIcon( self.slideAnimation and "icon16/accept.png" or "icon16/cross.png" )
                SChat:ApplyTheme()
            end

            return
        end

        fieldEditor = vgui.Create( f.class, self.customizeFrame )

        if f.class == "DColorMixer" then
            fieldEditor:Dock( FILL )
            fieldEditor:SetPalette( true )
            fieldEditor:SetAlphaBar( true )
            fieldEditor:SetWangs( true )
            fieldEditor:SetColor( self[f.index] )

            fieldEditor.ValueChanged = function( _, clr )
                -- clr doesnt have the color metatable... *sigh*
                self[f.index] = Color( clr.r, clr.g, clr.b, clr.a )
                SChat:ApplyTheme()
            end

        elseif f.class == "DNumSlider" then
            fieldEditor:Dock( TOP )
            fieldEditor:SetText( f.label )
            fieldEditor:SetMin( f.min )
            fieldEditor:SetMax( f.max )
            fieldEditor:SetDecimals( 0 )
            fieldEditor:SetValue( self[f.index] )
            fieldEditor.Label:SetTextColor( Color( 255, 255, 255 ) )

            fieldEditor.OnValueChanged = function( _, value )
                self[f.index] = math.floor( value )
                SChat:ApplyTheme( true )
            end
        end

        fieldEditor:DockMargin( 2, 12, 2, 12 )
    end

    local cmbFields = vgui.Create( "DComboBox", self.customizeFrame )
    cmbFields:Dock( TOP )
    cmbFields:SetSortItems( false )

    for i, field in ipairs( fields ) do
        cmbFields:AddChoice( field.label, nil, i == 1 )
    end

    cmbFields.OnSelect = function( _, i )
        setCurrentField( i )
    end

    setCurrentField( 1 )

    local pnlOptions = vgui.Create( "DPanel", self.customizeFrame )
    pnlOptions:SetTall( 22 )
    pnlOptions:Dock( BOTTOM )

    pnlOptions.Paint = nil

    local btnReset = vgui.Create( "DButton", pnlOptions )
    btnReset:SetIcon( "icon16/arrow_undo.png" )
    btnReset:SetTooltip( "Reset" )
    btnReset:SetText( "" )
    btnReset:SetWide( 24 )
    btnReset:Dock( LEFT )

    btnReset.DoClick = function()
        Derma_Query( "Reset theme to default? All changes will be lost!", "Reset Theme", "Yes", function()
            self.customizeFrame:Close()
            self:Reset()

            SChat:ApplyTheme( true )

            if file.Exists( self.path, "DATA" ) then
                file.Delete( self.path )
            end

            timer.Simple( 0, function()
                self:ShowCustomizePanel()
            end )
        end, "No" )
    end

    btnReset.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    local btnExport = vgui.Create( "DButton", pnlOptions )
    btnExport:SetIcon( "icon16/application_side_contract.png" )
    btnExport:SetTooltip( "Export" )
    btnExport:SetText( "" )
    btnExport:SetWide( 24 )
    btnExport:Dock( RIGHT )

    btnExport.DoClick = function()
        self:ShowExportPanel()
    end

    btnExport.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    local buttonImport = vgui.Create( "DButton", pnlOptions )
    buttonImport:SetIcon( "icon16/application_side_expand.png" )
    buttonImport:SetTooltip( "Import" )
    buttonImport:SetText( "" )
    buttonImport:SetWide( 24 )
    buttonImport:Dock( RIGHT )

    buttonImport.DoClick = function()
        self:ShowImportPanel()
    end

    buttonImport.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    if game.SinglePlayer() then return end
    if not SChat:CanSetServerTheme( LocalPlayer() ) then return end

    local function SetServerTheme( data )
        net.Start( "schat.set_theme", false )
        net.WriteString( data )
        net.SendToServer()

        SChat.usingServerTheme = false
    end

    local btnSetServerTheme = vgui.Create( "DButton", pnlOptions )
    btnSetServerTheme:SetIcon( "icon16/asterisk_yellow.png" )
    btnSetServerTheme:SetTooltip( "Set as the server theme" )
    btnSetServerTheme:SetText( "" )
    btnSetServerTheme:SetWide( 24 )
    btnSetServerTheme:Dock( RIGHT )

    btnSetServerTheme.DoClick = function()
        local query
        local args

        if SChat.serverTheme == "" then
            query = "This action will make all players (including those who join later) use this theme."
                .. "\nFor players who are not using the default theme, it shows a button that players"
                .. " can click to try it out.\nAre you sure?"

            args = {
                "Yes", function()
                    SetServerTheme( self:ToJSON() )
                end,
                "No"
            }
        else
            query = "This server already has a theme. What do you want to do with it?"
            args = {
                "Override", function()
                    SetServerTheme( self:ToJSON() )
                end,
                "Remove", function()
                    SetServerTheme( "" )
                end,
                "Cancel"
            }
        end

        Derma_Query( query, "Set Server Theme", unpack( args ) )
    end

    btnSetServerTheme.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end
end

function Theme:ShowExportPanel()
    chat.Close()

    local data = self:ToJSON()

    local frameExport = vgui.Create( "DFrame" )
    frameExport:SetSize( 400, 280 )
    frameExport:SetTitle( "Export Theme" )
    frameExport:ShowCloseButton( true )
    frameExport:SetDeleteOnClose( true )
    frameExport:Center()
    frameExport:MakePopup()

    local labelHelp = vgui.Create( "DLabel", frameExport )
    labelHelp:SetFont( "Trebuchet18" )
    labelHelp:SetText( "Use this code to share your current theme with others!" )
    labelHelp:SetTextColor( Color( 255, 255, 255 ) )
    labelHelp:Dock( TOP )
    labelHelp:SetContentAlignment( 5 )

    local textField = vgui.Create( "DTextEntry", frameExport )
    textField:Dock( FILL )
    textField:DockMargin( 16, 16, 16, 16 )
    textField:SetEditable( false )
    textField:SetMultiline( true )
    textField:SetValue( data )

    local buttonCopy = vgui.Create( "DButton", frameExport )
    buttonCopy:SetText( "Copy to clipboard" )
    buttonCopy:Dock( BOTTOM )

    buttonCopy.DoClick = function()
        SetClipboardText( data )
        frameExport:Close()
    end
end

function Theme:ShowImportPanel()
    chat.Close()

    local frameImport = vgui.Create( "DFrame" )
    frameImport:SetSize( 400, 280 )
    frameImport:SetTitle( "Import Theme" )
    frameImport:ShowCloseButton( true )
    frameImport:SetDeleteOnClose( true )
    frameImport:Center()
    frameImport:MakePopup()

    local labelHelp = vgui.Create( "DLabel", frameImport )
    labelHelp:SetFont( "Trebuchet18" )
    labelHelp:SetText( "Paste the theme code here." )
    labelHelp:SetTextColor( Color( 255, 255, 255 ) )
    labelHelp:Dock( TOP )
    labelHelp:SetContentAlignment( 5 )

    local textField = vgui.Create( "DTextEntry", frameImport )
    textField:Dock( FILL )
    textField:DockMargin( 16, 16, 16, 16 )
    textField:SetEditable( true )
    textField:SetMultiline( true )

    local buttonApply = vgui.Create( "DButton", frameImport )
    buttonApply:SetText( "Apply" )
    buttonApply:Dock( BOTTOM )

    buttonApply.DoClick = function()
        local success, errorMessage = self:Import( textField:GetValue() )

        if success then
            self:Save()
            SChat:ApplyTheme( true )
            frameImport:Close()
        else
            Derma_Message( "Error: " .. errorMessage, "Failed to import", "OK" )
        end
    end
end

function Theme:GetHashFromJSON( data )
    local t = util.JSONToTable( data )
    if not t then return end

    local function GetColorParts( c )
        if type( c ) ~= "table" then
            return 0, 0, 0, 0
        end

        return c.r or 0, c.g or 0, c.b or 0, c.a or 0
    end

    local parts = {
        t.pad or 0,
        t.corner or 0,
        t.blur or 0,

        t.font or "",
        t.font_shadow,
        t.slide_anim,

        GetColorParts( t.input ),
        GetColorParts( t.input_bg ),
        GetColorParts( t.highlight ),
        GetColorParts( t.background ),

        GetColorParts( t.scroll_bg ),
        GetColorParts( t.scroll_thumb )
    }

    for i, v in ipairs( parts ) do
        parts[i] = tostring( v )
    end

    return util.SHA256( table.concat( parts, " " ) )
end

local MAT_BLUR = Material( "pp/blurscreen" )

function Theme:BlurPanel( panel )
    if self.blur > 0 then
        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.SetMaterial( MAT_BLUR )

        MAT_BLUR:SetFloat( "$blur", self.blur )
        MAT_BLUR:Recompute()

        render.UpdateScreenEffectTexture()

        local x, y = panel:LocalToScreen( 0, 0 )
        surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
    end
end

Theme:Reset()
