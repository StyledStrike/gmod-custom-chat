local Theme = CustomChat.Theme or {}

CustomChat.Theme = Theme

do
    local fonts = {}

    for _, name in pairs( CustomChat.chatFonts ) do
        fonts[#fonts + 1] = name
    end

    table.sort( fonts, function( a, b ) return a < b end )

    Theme.fonts = fonts
end

function Theme.GetDefaultTheme()
    return {
        id = "default",
        name = "",
        description = CustomChat.GetLanguageText( "theme.default_description" ),

        font = "Arial",
        font_shadow = true,
        animate = true,
        avatars = true,
        blur = 2,
        corner_radius = 4,
        padding = 6,

        bg_r = 40,
        bg_g = 40,
        bg_b = 40,
        bg_a = 200,

        input_r = 255,
        input_g = 255,
        input_b = 255,
        input_a = 255,

        input_bg_r = 20,
        input_bg_g = 20,
        input_bg_b = 20,
        input_bg_a = 140,

        scroll_bar_r = 0,
        scroll_bar_g = 0,
        scroll_bar_b = 0,
        scroll_bar_a = 80,

        scroll_bg_r = 120,
        scroll_bg_g = 120,
        scroll_bg_b = 120,
        scroll_bg_a = 255,

        highlight_r = 60,
        highlight_g = 105,
        highlight_b = 230,
        highlight_a = 255
    }
end

local IsStringValid = CustomChat.IsStringValid
local SetNumber = CustomChat.Config.SetNumber
local SetBool = CustomChat.Config.SetBool
local SetColor = CustomChat.Config.SetColor

function Theme.Parse( data, output )
    data = data or Theme.GetDefaultTheme()
    output = output or {}

    output.name = IsStringValid( data.name ) and data.name or "???"
    output.description = IsStringValid( data.description ) and data.description or ""
    output.fontName = IsStringValid( data.font ) and data.font or "Arial"

    SetBool( output, "enableFontShadow", data.font_shadow )
    SetBool( output, "enableSlideAnimation", data.animate )
    SetBool( output, "enableAvatars", Either( data.avatars == nil, true, data.avatars ) )

    SetNumber( output, "backgroundBlur", data.blur, 0, 8 )
    SetNumber( output, "cornerRadius", data.corner_radius, 0, 32 )
    SetNumber( output, "padding", data.padding, 0, 64 )

    SetColor( output, "backgroundColor", data.bg_r, data.bg_g, data.bg_b, data.bg_a )
    SetColor( output, "inputColor", data.input_r, data.input_g, data.input_b, data.input_a )
    SetColor( output, "inputBackgroundColor", data.input_bg_r, data.input_bg_g, data.input_bg_b, data.input_bg_a )

    SetColor( output, "scrollBarColor", data.scroll_bar_r, data.scroll_bar_g, data.scroll_bar_b, data.scroll_bar_a )
    SetColor( output, "scrollBackgroundColor", data.scroll_bg_r, data.scroll_bg_g, data.scroll_bg_b, data.scroll_bg_a )
    SetColor( output, "highlightColor", data.highlight_r, data.highlight_g, data.highlight_b, data.highlight_a )

    return output
end

function Theme.LoadFile( themeId )
    if themeId == "default" then
        return Theme.GetDefaultTheme()
    end

    local filePath = CustomChat.DATA_DIR .. "themes/" .. themeId .. ".json"
    local data = file.Read( filePath, "DATA" )

    if not data then
        CustomChat.Print( "Failed to load theme file: %s", filePath )

        return Theme.GetDefaultTheme()
    end

    local theme = CustomChat.FromJSON( data )
    theme.id = themeId
    theme.name = IsStringValid( theme.name ) and theme.name or "???"
    theme.description = IsStringValid( theme.description ) and theme.description or ""

    return theme
end

function Theme.SaveFile( themeId, data )
    local filePath = "themes/" .. themeId .. ".json"

    data.id = data.id or themeId

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( filePath, CustomChat.ToJSON( data ) )

    return themeId
end

function Theme.GetList()
    CustomChat.EnsureDataDir()

    local themes = {
        Theme.GetDefaultTheme()
    }

    if Theme.serverTheme then
        themes[#themes + 1] = Theme.serverTheme
    end

    local files = file.Find( CustomChat.DATA_DIR .. "themes/*", "DATA" )

    for _, fileName in ipairs( files ) do
        themes[#themes + 1] = Theme.LoadFile( fileName:sub( 1, -6 ) )
    end

    return themes
end

----- Theme Editor

hook.Add( "FinishChat", "CustomChat.CloseThemePanel", function()
    if IsValid( Theme.editorFrame ) then
        Theme.editorFrame:Close()
    end
end )

hook.Add( "NetPrefs_OnChange", "CustomChat.UpdateThemeList", function( key )
    if key == "customchat.theme" and IsValid( Theme.editorFrame ) then
        timer.Simple( 0, Theme.editorFrame._RefreshList )
    end
end )

local Config = CustomChat.Config
local L = CustomChat.GetLanguageText

function Theme.OpenEditor()
    if IsValid( Theme.editorFrame ) then
        Theme.editorFrame:Close()
    end

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 600, 400 )
    frame:SetTitle( L"theme.customize_title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    frame.OnClose = function()
        Theme.editorFrame._RefreshList = nil
        Theme.editorFrame = nil
    end

    Theme.editorFrame = frame
    CustomChat:PutFrameToTheSide( frame )

    local editor = {
        items = {},
        selectedIndex = nil,
        selectedPanel = nil,

        colorSelected = Color( 39, 86, 156 ),
        colorUnselected = Color( 50, 50, 50, 255 ),
        colorTitle = Color( 0, 0, 0, 200 )
    }

    ----- Theme list

    local themesList = vgui.Create( "DScrollPanel", frame )
    themesList:Dock( FILL )
    themesList:GetCanvas():DockPadding( 4, 4, 4, 4 )

    themesList.Paint = function( _, w, h )
        surface.SetDrawColor( 10, 10, 10, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local panelOptions = vgui.Create( "DPanel", frame )
    panelOptions:Dock( BOTTOM )
    panelOptions:DockPadding( 4, 4, 4, 4 )
    panelOptions:SetTall( 32 )

    local buttonNew = vgui.Create( "DButton", panelOptions )
    buttonNew:SetIcon( "icon16/add.png" )
    buttonNew:SetText( L"theme.new" )
    buttonNew:SetWide( 110 )
    buttonNew:Dock( LEFT )

    local buttonDelete = vgui.Create( "DButton", panelOptions )
    buttonDelete:SetIcon( "icon16/cancel.png" )
    buttonDelete:SetText( L"theme.delete" )
    buttonDelete:SetWide( 110 )
    buttonDelete:Dock( LEFT )

    local buttonExport = vgui.Create( "DButton", panelOptions )
    buttonExport:SetIcon( "icon16/application_side_contract.png" )
    buttonExport:SetText( L"theme.export" )
    buttonExport:SetWide( 100 )
    buttonExport:Dock( RIGHT )

    buttonExport.DoClick = function()
        frame:Close()
        Theme.ShowExportPanel( editor.items[editor.selectedIndex] )
    end

    local buttonImport = vgui.Create( "DButton", panelOptions )
    buttonImport:SetIcon( "icon16/application_side_expand.png" )
    buttonImport:SetText( L"theme.import" )
    buttonImport:SetWide( 100 )
    buttonImport:Dock( RIGHT )

    buttonImport.DoClick = function()
        frame:Close()
        Theme.ShowImportPanel()
    end

    ----- Theme editor

    local editorPanel = vgui.Create( "CustomChat_ThemeEditor", frame )
    editorPanel:Dock( RIGHT )
    editorPanel:SetWide( 200 )

    editorPanel.OnThemeChanged = function( key, value )
        if not editor.selectedIndex then return end

        local theme = editor.items[editor.selectedIndex]
        theme[key] = value

        CustomChat.frame:LoadThemeData( theme )

        -- Update the theme name/description on the themes list
        if key == "name" then
            if theme.id == "server_default" then
                editor.selectedPanel._labelName:SetText( L"theme.server_default" )
            else
                editor.selectedPanel._labelName:SetText( "[" .. theme.id .. ".json] " .. value  )
            end

        elseif key == "description" then
            editor.selectedPanel._labelDescription:SetText( value )
        end

        if theme.id == "server_default" then return end

        -- Avoid spamming the file system
        timer.Remove( "CustomChat.SaveThemeDelay" )
        timer.Create( "CustomChat.SaveThemeDelay", 1, 1, function()
            Theme.SaveFile( theme.id, theme )
        end )
    end

    editor.OnSelectTheme = function( s, dontUpdate )
        if IsValid( editor.selectedPanel ) then
            editor.selectedPanel._isSelected = nil
        end

        editor.selectedIndex = s._themeIndex
        editor.selectedPanel = s
        s._isSelected = true

        local theme = editor.items[editor.selectedIndex]
        local disableEditing = theme.id == "default" or theme.id == "server_default"

        -- Allow players with permission to edit the server theme
        if theme.id == "server_default" and CustomChat.CanSetServerTheme( LocalPlayer() ) then
            disableEditing = false
        end

        buttonDelete:SetDisabled( disableEditing or theme.id == "server_default" )
        buttonExport:SetDisabled( theme.id == "default" )

        editorPanel:SetDisabled( disableEditing )
        editorPanel:LoadThemeData( theme )

        if dontUpdate then return end

        CustomChat:SetTheme( theme.id )

        if theme.id == "server_default" then return end

        CustomChat.Config.themeId = theme.id
        CustomChat.Config:Save()
    end

    editor.PaintTheme = function( s, w, h )
        if s._isSelected then
            draw.RoundedBox( 4, 0, 0, w, h, editor.colorSelected )
        else
            draw.RoundedBox( 4, 0, 0, w, h, editor.colorUnselected )
        end

        draw.RoundedBoxEx( 4, 0, 0, w, 22, editor.colorTitle, true, true )

        if s._isSelected then
            surface.SetDrawColor( 255, 255, 255, 255 * math.abs( math.sin( RealTime() * 3 ) ) )
            surface.DrawOutlinedRect( 0, 0, w, h, 1 )
        end
    end

    editor.RefreshList = function()
        themesList:Clear()
        editor.items = Theme.GetList()

        local currentThemeId = Theme.serverTheme and "server_default" or Config.themeId

        for i, theme in ipairs( editor.items ) do
            local panel = themesList:Add( "DButton" )
            panel:SetTall( 50 )
            panel:SetText( "" )
            panel:Dock( TOP )
            panel:DockMargin( 0, 0, 0, 5 )

            local labelName = vgui.Create( "DLabel", panel )

            labelName:SetText( theme.id == "server_default" and L"theme.server_default" or (
                theme.id == "default" and L"theme.default" or "[" .. theme.id .. ".json] " .. theme.name
            ) )

            labelName:SizeToContents()
            labelName:SetTextColor( color_white )
            labelName:Dock( TOP )
            labelName:DockMargin( 6, 5, 0, 0 )

            local labelDescription = vgui.Create( "DLabel", panel )
            labelDescription:SetText( theme.description )
            labelDescription:Dock( TOP )
            labelDescription:DockMargin( 4, 8, 4, 0 )
            labelDescription:SetTextColor( Color( 200, 200, 200 ) )

            panel._themeIndex = i
            panel._labelName = labelName
            panel._labelDescription = labelDescription
            panel.Paint = editor.PaintTheme
            panel.DoClick = editor.OnSelectTheme

            if theme.id == currentThemeId then
                editor.OnSelectTheme( panel, true )
            end
        end
    end

    buttonNew.DoClick = function()
        Derma_StringRequest( L"theme.new", L"theme.new_tip", "", function( text )
            local id = Theme.CreateFile( text )
            if not id then return end

            CustomChat.Config.themeId = id
            CustomChat.Config:Save()

            timer.Simple( 0, editor.RefreshList )
        end )
    end

    buttonDelete.DoClick = function()
        local theme = editor.items[editor.selectedIndex]

        Derma_Query( L"theme.delete_tip" .. "\n\n" .. theme.id, L"theme.delete", L"yes", function()
            file.Delete( CustomChat.DATA_DIR .. "themes/" .. theme.id .. ".json", "DATA" )

            CustomChat.Config.themeId = "default"
            CustomChat.Config:Save()
            CustomChat:SetTheme( "default" )

            timer.Simple( 0, editor.RefreshList )
        end, L"no" )
    end

    frame._RefreshList = editor.RefreshList
    editor.RefreshList()

    if game.SinglePlayer() then return end
    if not CustomChat.CanSetServerTheme( LocalPlayer() ) then return end

    local buttonServerTheme = vgui.Create( "DButton", panelOptions )
    buttonServerTheme:SetIcon( "icon16/asterisk_yellow.png" )
    buttonServerTheme:SetText( L"server_theme.set" )
    buttonServerTheme:SetWide( 130 )
    buttonServerTheme:Dock( RIGHT )

    local function SetServerTheme( data )
        net.Start( "customchat.set_theme", false )
        net.WriteString( data )
        net.SendToServer()
    end

    buttonServerTheme.DoClick = function()
        local query, args
        local data = ""

        if editor.selectedIndex then
            data = CustomChat.ToJSON( editor.items[editor.selectedIndex] )
        end

        if Theme.serverTheme then
            query = L"server_theme.already_set"
            args = {
                L"server_theme.override", function()
                    SetServerTheme( data )
                end,
                L"server_theme.remove", function()
                    SetServerTheme( "" )
                end,
                L"cancel"
            }
        else
            query = L"server_theme.tip"

            args = {
                L"yes", function()
                    SetServerTheme( data )
                end,
                L"no"
            }
        end

        Derma_Query( query, L"server_theme.set", unpack( args ) )
    end
end

function Theme.CreateFile( themeId, data )
    if string.len( themeId ) == 0 or themeId == "default" or themeId == "server_theme" then
        Derma_Message( L"theme.invalid_file_name", L"invalid_input", L"ok" )

        return false
    end

    local filePath = "themes/" .. themeId .. ".json"

    if file.Exists( CustomChat.DATA_DIR .. filePath, "DATA" ) then
        Derma_Message( L"theme.file_name_exists", L"invalid_input", L"ok" )

        return false
    end

    if not data then
        data = Theme.GetDefaultTheme()
        data.id = themeId
        data.name = ""
        data.description = ""
    end

    data.id = data.id or themeId
    data.name = IsStringValid( data.name ) and data.name or CustomChat.GetLanguageText( "theme.new_name" )

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( filePath, CustomChat.ToJSON( data ) )

    if not file.Exists( CustomChat.DATA_DIR .. filePath, "DATA" ) then
        Derma_Message( L"theme.invalid_file_name", L"invalid_input", L"ok" )

        return false
    end

    return themeId
end

function Theme.ShowImportPanel()
    chat.Close()

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 400, 280 )
    frame:SetTitle( L"theme.import_title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    local labelFileName = vgui.Create( "DLabel", frame )
    labelFileName:SetText( L"theme.new_tip" )
    labelFileName:Dock( TOP )
    labelFileName:DockMargin( 0, 8, 0, 0 )
    labelFileName:SetTextColor( color_white )
    labelFileName:SetFont( "Trebuchet18" )
    labelFileName:SetContentAlignment( 5 )

    local entryFileName = vgui.Create( "DTextEntry", frame )
    entryFileName:Dock( TOP )
    entryFileName:DockMargin( 16, 16, 16, 16 )

    local labelCode = vgui.Create( "DLabel", frame )
    labelCode:SetText( L"theme.import_tip" )
    labelCode:Dock( TOP )
    labelCode:DockMargin( 0, 0, 0, 0 )
    labelCode:SetTextColor( color_white )
    labelCode:SetFont( "Trebuchet18" )
    labelCode:SetContentAlignment( 5 )

    local entryCode = vgui.Create( "DTextEntry", frame )
    entryCode:Dock( FILL )
    entryCode:DockMargin( 16, 16, 16, 16 )
    entryCode:SetEditable( true )
    entryCode:SetMultiline( true )

    local buttonImport = vgui.Create( "DButton", frame )
    buttonImport:SetText( L"theme.import" )
    buttonImport:Dock( BOTTOM )

    local function Import( themeId, data )
        data = string.Trim( data )

        if string.len( data ) == 0 then
            return false, L"theme.import_error_empty"
        end

        data = util.JSONToTable( data )

        if not data then
            return false, L"theme.import_error_json"
        end

        local id = Theme.CreateFile( themeId, data )
        if not id then return false end

        return true
    end

    buttonImport.DoClick = function()
        local themeId = entryFileName:GetValue()
        local success, errorMessage = Import( themeId, entryCode:GetValue() )

        if success then
            CustomChat.Config.themeId = themeId
            CustomChat.Config:Save()
            CustomChat:SetTheme( themeId )
            frame:Close()

            CustomChat.PrintMessage( CustomChat.GetLanguageText( "theme.import_success" ) )

        elseif errorMessage then
            Derma_Message( L( "theme.import_failed" ) .. ": " .. errorMessage, L"theme.import_failed", L"ok" )
        end
    end
end

function Theme.ShowExportPanel( data )
    chat.Close()

    data = CustomChat.ToJSON( data )

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 400, 280 )
    frame:SetTitle( L"theme.export_title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    local labelHelp = vgui.Create( "DLabel", frame )
    labelHelp:SetFont( "Trebuchet18" )
    labelHelp:SetText( L"theme.export_tip" )
    labelHelp:SetTextColor( Color( 255, 255, 255 ) )
    labelHelp:Dock( TOP )
    labelHelp:SetContentAlignment( 5 )

    local entryCode = vgui.Create( "DTextEntry", frame )
    entryCode:Dock( FILL )
    entryCode:DockMargin( 16, 16, 16, 16 )
    entryCode:SetEditable( false )
    entryCode:SetMultiline( true )
    entryCode:SetValue( data )

    local buttonCopy = vgui.Create( "DButton", frame )
    buttonCopy:SetText( L"copy_to_clipboard" )
    buttonCopy:Dock( BOTTOM )

    buttonCopy.DoClick = function()
        SetClipboardText( data )
        frame:Close()
    end
end
