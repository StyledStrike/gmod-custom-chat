local Theme = CustomChat.Theme or {}

CustomChat.Theme = Theme

Theme.fonts = {
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

function Theme.GetDefaultTheme()
    return {
        id = "default",
        name = "",
        description = CustomChat.GetLanguageText( "theme.default_description" ),

        font = Theme.fonts[1],
        font_shadow = true,
        animate = true,
        avatars = true,
        blur = 4,
        corner_radius = 8,
        padding = 8,

        bg_r = 40,
        bg_g = 40,
        bg_b = 40,
        bg_a = 200,

        input_r = 255,
        input_g = 255,
        input_b = 255,
        input_a = 255,

        input_bg_r = 0,
        input_bg_g = 0,
        input_bg_b = 0,
        input_bg_a = 100,

        scroll_bar_r = 0,
        scroll_bar_g = 0,
        scroll_bar_b = 0,
        scroll_bar_a = 80,

        scroll_bg_r = 120,
        scroll_bg_g = 120,
        scroll_bg_b = 120,
        scroll_bg_a = 255,

        highlight_r = 95,
        highlight_g = 181,
        highlight_b = 231,
        highlight_a = 255
    }
end

local IsStringValid = CustomChat.IsStringValid
local SetNumber = CustomChat.Config.SetNumber
local SetBool = CustomChat.Config.SetBool
local SetColor = CustomChat.Config.SetColor

function Theme.ParseTheme( data, themeTable )
    data = data or Theme.GetDefaultTheme()
    themeTable = themeTable or {}

    themeTable.name = IsStringValid( data.name ) and data.name or "???"
    themeTable.description = IsStringValid( data.description ) and data.description or ""
    themeTable.fontName = IsStringValid( data.font ) and data.font or CustomChat.Theme.fonts[1]

    SetBool( themeTable, "enableFontShadow", data.font_shadow )
    SetBool( themeTable, "enableSlideAnimation", data.animate )
    SetBool( themeTable, "enableAvatars", data.avatars )

    SetNumber( themeTable, "backgroundBlur", data.blur, 0, 8 )
    SetNumber( themeTable, "cornerRadius", data.corner_radius, 0, 32 )
    SetNumber( themeTable, "padding", data.padding, 0, 64 )

    SetColor( themeTable, "backgroundColor", data.bg_r, data.bg_g, data.bg_b, data.bg_a )
    SetColor( themeTable, "inputColor", data.input_r, data.input_g, data.input_b, data.input_a )
    SetColor( themeTable, "inputBackgroundColor", data.input_bg_r, data.input_bg_g, data.input_bg_b, data.input_bg_a )

    SetColor( themeTable, "scrollBarColor", data.scroll_bar_r, data.scroll_bar_g, data.scroll_bar_b, data.scroll_bar_a )
    SetColor( themeTable, "scrollBackgroundColor", data.scroll_bg_r, data.scroll_bg_g, data.scroll_bg_b, data.scroll_bg_a )
    SetColor( themeTable, "highlightColor", data.highlight_r, data.highlight_g, data.highlight_b, data.highlight_a )

    return themeTable
end

function Theme.LoadThemeFile( themeId )
    if themeId == "default" then
        return Theme.GetDefaultTheme()
    end

    local filePath = CustomChat.DATA_DIR .. "themes/" .. themeId .. ".json"
    local data = file.Read( filePath, "DATA" )

    if not data then
        CustomChat.PrintF( "Failed to load theme file: %s", filePath )

        return Theme.GetDefaultTheme()
    end

    local theme = CustomChat.Unserialize( data )
    theme.id = themeId
    theme.name = IsStringValid( theme.name ) and theme.name or "???"
    theme.description = IsStringValid( theme.description ) and theme.description or ""

    return theme
end

function Theme.SaveThemeFile( themeId, data )
    local filePath = "themes/" .. themeId .. ".json"

    data.id = data.id or themeId

    CustomChat.EnsureDataDir()
    CustomChat.SaveDataFile( filePath, CustomChat.Serialize( data ) )

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

    local themesFolder = CustomChat.DATA_DIR .. "themes/"
    local files = file.Find( themesFolder .. "*", "DATA" )

    for _, fileName in ipairs( files ) do
        themes[#themes + 1] = Theme.LoadThemeFile( fileName:sub( 1, -6 ) )
    end

    return themes
end

hook.Add( "FinishChat", "CustomChat.CloseThemePanel", function()
    if IsValid( Theme.themeFrame ) then
        Theme.themeFrame:Close()
    end
end )

hook.Add( "NetPrefs_OnChange", "CustomChat.UpdateThemeList", function( key )
    if key == "customchat.theme" and IsValid( Theme.themeFrame ) then
        timer.Simple( 0, Theme.themeFrame._RefreshList )
    end
end )

local Config = CustomChat.Config
local L = CustomChat.GetLanguageText

function Theme.OpenEditor()
    if IsValid( Theme.themeFrame ) then
        Theme.themeFrame:Close()
    end

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 600, 400 )
    frame:SetTitle( L"theme.customize_title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    frame.OnClose = function()
        Theme.themeFrame = nil
    end

    Theme.themeFrame = frame

    -- put the frame to the side of the chat
    -- but keep it inside of the screen
    do
        local chatX, chatY = chat.GetChatBoxPos()
        local chatW, chatH = chat.GetChatBoxSize()

        local x = chatX + chatW + 8
        local y = ( chatY + chatH * 0.5 ) - ( frame:GetTall() * 0.5 )

        x = math.Clamp( x, 0, ScrW() - frame:GetWide() )
        y = math.Clamp( y, 0, ScrH() - frame:GetTall() )

        frame:SetPos( x, y )
    end

    local items = {}
    local selectedIndex, selectedPanel, isRefreshingList
    local OnSelectTheme, RefreshList

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
        Theme.ShowExportPanel( items[selectedIndex] )
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

    local editorPanel = vgui.Create( "CustomChatThemeEditor", frame )
    editorPanel:Dock( RIGHT )
    editorPanel:SetWide( 200 )

    editorPanel.OnThemeChanged = function( key, value )
        if not selectedIndex then return end

        local theme = items[selectedIndex]
        theme[key] = value

        CustomChat.frame:LoadThemeData( theme )

        -- avoid spamming the file system
        timer.Remove( "CustomChat.SaveThemeDelay" )
        timer.Create( "CustomChat.SaveThemeDelay", 1, 1, function()
            Theme.SaveThemeFile( theme.id, theme )
        end )

        if key == "name" then
            selectedPanel._labelName:SetText( "[" .. theme.id .. ".json] " .. value  )

        elseif key == "description" then
            selectedPanel._labelDescription:SetText( value )
        end
    end

    local colorSelected = Color( 39, 86, 156 )
    local colorUnselected = Color( 50, 50, 50, 255 )
    local colorTitle = Color( 0, 0, 0, 200 )

    local PaintTheme = function( s, w, h )
        if s._isSelected then
            draw.RoundedBox( 4, 0, 0, w, h, colorSelected )
        else
            draw.RoundedBox( 4, 0, 0, w, h, colorUnselected )
        end

        draw.RoundedBoxEx( 4, 0, 0, w, 22, colorTitle, true, true )

        if s._isSelected then
            surface.SetDrawColor( 255, 255, 255, 255 * math.abs( math.sin( RealTime() * 3 ) ) )
            surface.DrawOutlinedRect( 0, 0, w, h, 1 )
        end
    end

    OnSelectTheme = function( s )
        if IsValid( selectedPanel ) then
            selectedPanel._isSelected = nil
        end

        selectedIndex = s._themeIndex
        selectedPanel = s
        s._isSelected = true

        local theme = items[selectedIndex]
        local disableEditing = theme.id == "default" or theme.id == "server_default"

        buttonDelete:SetDisabled( disableEditing )
        buttonExport:SetDisabled( disableEditing )
        editorPanel:SetDisabled( disableEditing )
        editorPanel:LoadThemeData( theme )

        if isRefreshingList then return end

        CustomChat:SetTheme( theme.id )

        if theme.id == "server_default" then return end

        CustomChat.Config.themeId = theme.id
        CustomChat.Config:Save()
    end

    RefreshList = function()
        themesList:Clear()
        items = Theme.GetList()
        isRefreshingList = true

        local shouldSelect
        local currentThemeId = Theme.serverTheme and "server_default" or Config.themeId

        for i, theme in ipairs( items ) do
            local panel = themesList:Add( "DButton" )
            panel:SetTall( 50 )
            panel:SetText( "" )
            panel:Dock( TOP )
            panel:DockMargin( 0, 0, 0, 5 )

            panel._themeIndex = i
            panel.Paint = PaintTheme
            panel.DoClick = OnSelectTheme

            local labelName = vgui.Create( "DLabel", panel )

            if theme.id == "server_default" then
                labelName:SetText( L"theme.server_default" )

            elseif theme.id == "default" then
                labelName:SetText( L"theme.default" )

            else
                labelName:SetText( "[" .. theme.id .. ".json] " .. theme.name )
            end

            labelName:SizeToContents()
            labelName:SetTextColor( color_white )
            labelName:Dock( TOP )
            labelName:DockMargin( 6, 5, 0, 0 )
            panel._labelName = labelName

            local labelDescription = vgui.Create( "DLabel", panel )
            labelDescription:SetText( theme.description )
            labelDescription:Dock( TOP )
            labelDescription:DockMargin( 4, 8, 4, 0 )
            labelDescription:SetTextColor( Color( 200, 200, 200 ) )
            panel._labelDescription = labelDescription

            if theme.id == currentThemeId then
                shouldSelect = panel
            end
        end

        if shouldSelect then
            shouldSelect:DoClick()
        end

        isRefreshingList = false
    end

    buttonNew.DoClick = function()
        Derma_StringRequest( L"theme.new", L"theme.new_tip", "", function( text )
            local id = Theme.CreateThemeFile( text )
            if not id then return end

            CustomChat.Config.themeId = id
            CustomChat.Config:Save()

            timer.Simple( 0, RefreshList )
        end )
    end

    buttonDelete.DoClick = function()
        local theme = items[selectedIndex]

        Derma_Query( L"theme.delete_tip" .. "\n\n" .. theme.id, L"theme.delete", L"yes", function()
            file.Delete( CustomChat.DATA_DIR .. "themes/" .. theme.id .. ".json", "DATA" )

            CustomChat.Config.themeId = "default"
            CustomChat.Config:Save()
            CustomChat:SetTheme( "default" )

            timer.Simple( 0, RefreshList )
        end, L"no" )
    end

    frame._RefreshList = RefreshList
    RefreshList()

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
        local query
        local args
        local data = ""

        if selectedIndex then
            data = CustomChat.Serialize( items[selectedIndex] )
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

function Theme.CreateThemeFile( themeId, data )
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
    CustomChat.SaveDataFile( filePath, CustomChat.Serialize( data ) )

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

        local id = Theme.CreateThemeFile( themeId, data )
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

            CustomChat.InternalMessage( CustomChat.GetLanguageText( "theme.import_success" ) )

        elseif errorMessage then
            Derma_Message( L( "theme.import_failed" ) .. ": " .. errorMessage, L"theme.import_failed", L"ok" )
        end
    end
end

function Theme.ShowExportPanel( data )
    chat.Close()

    data = CustomChat.Serialize( data )

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
