local Theme = {
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

function Theme:Save()
    file.Write( self.path, self:ToJSON() )
end

function Theme:Load()
    -- try to load the theme
    local rawData = file.Read( self.path, "DATA" )
    if rawData then
        local success, errMsg = self:Import( rawData )
        if not success then
            SChat.PrintF( "Failed to load %s: %s", self.path, errMsg )
        end
    end
end

function Theme:ToJSON()
    return util.TableToJSON( {
        pad = self.padding,
        corner = self.corner_radius,
        blur = self.blur,

        font = self.fontName,
        font_shadow = self.fontShadow,

        input = self.input,
        input_bg = self.input_background,
        highlight = self.highlight,
        background = self.background,

        scroll_bg = self.scrollbarBackground,
        scroll_thumb = self.scrollbarThumb
    }, false )
end

function Theme:Import( data )
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
        self.corner_radius = Settings:ValidateInteger( data.corner, 0, 32 )
    end

    if data.blur then
        self.blur = Settings:ValidateInteger( data.blur, 0, 8 )
    end

    if type( data.font ) == "string" then
        self.fontName = data.font
    end

    self.fontShadow = Either( data.font_shadow, true, false )

    if data.input then
        self.input = Settings:ValidateColor( data.input )
    end

    if data.input_bg then
        self.input_background = Settings:ValidateColor( data.input_bg )
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

    return true
end

function Theme:Reset()
    self.padding = 4
    self.corner_radius = 4
    self.blur = 4

    self.fontName = self.availableFonts[1]
    self.fontShadow = true

    self.input = Color( 255, 255, 255, 255 )
    self.input_background = Color( 0, 0, 0, 180 )
    self.highlight = Color( 95, 181, 231 )
    self.background = Color( 0, 0, 0, 200 )

    self.scrollbarBackground = Color( 0, 0, 0, 50 )
    self.scrollbarThumb = Color( 180, 180, 180, 255 )
end

function Theme:ShowCustomizePanel()
    if IsValid( self.customFrame ) then
        self.customFrame:RequestFocus()
        return
    end

    self.customFrame = SChat:CreateSidePanel( "Customize Theme", true )

    self.customFrame.OnClose = function()
        self:Save()
    end

    local fields = {
        {
            index = "font",
            label = "Font"
        },
        {
            index = "input",
            label = "Input Text",
            class = "DColorMixer"
        },
        {
            index = "input_background",
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
            index = "corner_radius",
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
            fieldEditor = vgui.Create( "DPanel", self.customFrame )
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

            return
        end

        fieldEditor = vgui.Create( f.class, self.customFrame )

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

    local cmbFields = vgui.Create( "DComboBox", self.customFrame )
    cmbFields:Dock( TOP )
    cmbFields:SetSortItems( false )

    for i, field in ipairs( fields ) do
        cmbFields:AddChoice( field.label, nil, i == 1 )
    end

    cmbFields.OnSelect = function( _, i )
        setCurrentField( i )
    end

    setCurrentField( 1 )

    local pnlOptions = vgui.Create( "DPanel", self.customFrame )
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
            self:Reset()
            SChat:ApplyTheme( true )

            if file.Exists( self.path, "DATA" ) then
                file.Delete( self.path )
            end
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

    local btnImport = vgui.Create( "DButton", pnlOptions )
    btnImport:SetIcon( "icon16/application_side_expand.png" )
    btnImport:SetTooltip( "Import" )
    btnImport:SetText( "" )
    btnImport:SetWide( 24 )
    btnImport:Dock( RIGHT )

    btnImport.DoClick = function()
        self:ShowImportPanel()
    end

    btnImport.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    if game.SinglePlayer() then return end
    if not SChat:CanSetServerTheme( LocalPlayer() ) then return end

    local function setServerTheme( data )
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
        local actions
        local query

        if SChat.serverTheme == "" then
            query = "This action will suggest your current theme to all players on this server (Including those who join later).\nAre you sure?"
            actions = {
                "Yes", function()
                    setServerTheme( self:ToJSON() )
                end,
                "No"
            }
        else
            query = "This server already has a theme. What do you want to do with it?"
            actions = {
                "Override", function()
                    setServerTheme( self:ToJSON() )
                end,
                "Remove", function()
                    setServerTheme( "" )
                end,
                "Cancel"
            }
        end

        Derma_Query( query, "Set Server Theme", unpack( actions ) )
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

    local lblExportHelp = vgui.Create( "DLabel", frameExport )
    lblExportHelp:SetFont( "Trebuchet18" )
    lblExportHelp:SetText( "Use this code to share your current theme with others!" )
    lblExportHelp:SetTextColor( Color( 255, 255, 255 ) )
    lblExportHelp:Dock( TOP )
    lblExportHelp:SetContentAlignment( 5 )

    local textField = vgui.Create( "DTextEntry", frameExport )
    textField:Dock( FILL )
    textField:DockMargin( 16, 16, 16, 16 )
    textField:SetEditable( false )
    textField:SetMultiline( true )
    textField:SetValue( data )

    local btnCopy = vgui.Create( "DButton", frameExport )
    btnCopy:SetText( "Copy to clipboard" )
    btnCopy:Dock( BOTTOM )

    btnCopy.DoClick = function()
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

    local lblImportHelp = vgui.Create( "DLabel", frameImport )
    lblImportHelp:SetFont( "Trebuchet18" )
    lblImportHelp:SetText( "Paste the theme code here." )
    lblImportHelp:SetTextColor( Color( 255, 255, 255 ) )
    lblImportHelp:Dock( TOP )
    lblImportHelp:SetContentAlignment( 5 )

    local textField = vgui.Create( "DTextEntry", frameImport )
    textField:Dock( FILL )
    textField:DockMargin( 16, 16, 16, 16 )
    textField:SetEditable( true )
    textField:SetMultiline( true )

    local btnImport = vgui.Create( "DButton", frameImport )
    btnImport:SetText( "Apply" )
    btnImport:Dock( BOTTOM )

    btnImport.DoClick = function()
        local success, errMsg = self:Import( textField:GetValue() )

        if success then
            self:Save()
            SChat:ApplyTheme( true )
            frameImport:Close()
        else
            Derma_Message( "Error: " .. errMsg, "Failed to import", "OK" )
        end
    end
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

SChat.Theme = Theme
