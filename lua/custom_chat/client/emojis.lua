-- Dictionary of all emojis, where keys are emoji IDs and values are tables
local emojis = {}

-- Array of emoji categories
local emojiCategories = {}

CustomChat.emojis = emojis
CustomChat.emojiCategories = emojiCategories

local BUILT_IN_URL = "asset://garrysmod/materials/icon72/%s.png"

--- Returns the URL of a emoji, if it exists.
function CustomChat.GetEmojiURL( id )
    local emoji = emojis[id]
    if not emoji then return end

    if emoji.isBuiltIn then
        return BUILT_IN_URL:format( id )
    end

    return emoji.url
end

--- Clears all "Custom" emojis.
function CustomChat.ClearCustomEmojis()
    local categoryItems = emojiCategories[1].items

    -- Remove emojis from the dictionary of all emojis too
    for _, item in ipairs( categoryItems ) do
        emojis[item.id] = nil
    end

    emojiCategories[1].items = {}
end

--- Adds a emoji to the "Custom" category.
function CustomChat.AddCustomEmoji( id, url )
    local categoryItems = emojiCategories[1].items

    -- Don't allow overriding built-in emojis
    local existingEmoji = emojis[id]

    if existingEmoji and existingEmoji.isBuiltIn then
        CustomChat.Print( "AddCustomEmoji tried to use built-in ID '%s'!", id )
        return
    end

    -- If this emoji id already exists, remove it
    for i, item in ipairs( categoryItems ) do
        if item.id == id then
            table.remove( categoryItems, i )
            break
        end
    end

    local item = { id = id, url = url }

    emojis[id] = item
    categoryItems[#categoryItems + 1] = item
end

--- Adds a emoji category, and all of its items to the dictionary of all emojis.
function CustomChat.AddEmojiCategory( name, items )
    local categoryItems = {}

    for _, item in ipairs( items ) do
        if type( item ) == "string" then
            item = { id = item, isBuiltIn = true }
        end

        emojis[item.id] = item
        categoryItems[#categoryItems + 1] = item
    end

    emojiCategories[#emojiCategories + 1] = {
        name = name,
        items = categoryItems
    }
end

do
    -- Create "custom" category
    CustomChat.AddEmojiCategory( "category.custom", {} )

    -- Load the default categories from a data file
    local data = file.Read( "data_static/custom_chat_emojis.json", "GAME" )

    if not data then
        CustomChat.Print( "Couldn't load default emojis, data_static/custom_chat_emojis.json is missing!" )
        return
    end

    data = CustomChat.FromJSON( data )

    for _, category in ipairs( data ) do
        CustomChat.AddEmojiCategory( category.name, category.items )
    end
end

function CustomChat.OpenEmojiEditor()
    local L = CustomChat.GetLanguageText

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 700, 400 )
    frame:SetTitle( L"emojis.title" )
    frame:ShowCloseButton( true )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()

    if system.IsLinux() then
        local panelWarning = vgui.Create( "DPanel", frame )
        panelWarning:Dock( BOTTOM )
        panelWarning:DockPadding( 4, 4, 4, 4 )
        panelWarning:SetBackgroundColor( Color( 82, 63, 23 ) )

        local labelWarning = vgui.Create( "DLabel", panelWarning )
        labelWarning:Dock( FILL )
        labelWarning:SetTextColor( Color( 255, 255, 160 ) )
        labelWarning:SetContentAlignment( 5 )
        labelWarning:SetText( L"emojis.branch_warning" )
    end

    local customEmojis = table.Copy( emojiCategories[1].items )
    local RefreshList

    local scrollEmojis = vgui.Create( "DScrollPanel", frame )
    scrollEmojis:Dock( FILL )
    scrollEmojis:GetCanvas():DockPadding( 0, 0, 0, 4 )

    scrollEmojis.Paint = function( _, w, h )
        surface.SetDrawColor( 30, 30, 30, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local function RemoveEmoji( index )
        table.remove( customEmojis, index )
        RefreshList()
    end

    local function UpdateEmoji( index, id, url )
        customEmojis[index].id = id
        customEmojis[index].url = url
    end

    local function MarkEntryAsValid( entry )
        entry._invalidReason = nil
        entry:SetPaintBackgroundEnabled( false )
    end

    local function MarkEntryAsInvalid( entry, reason )
        entry._invalidReason = reason
        entry:SetBGColor( Color( 153, 86, 86 ) )
        entry:SetPaintBackgroundEnabled( true )
    end

    local function FindEmojiIndexById( id )
        for k, v in ipairs( customEmojis ) do
            if v.id == id then
                return k
            end
        end
    end

    local function IsBuiltInEmoji( id )
        local emoji = emojis[id]
        if emoji then
            return emoji.isBuiltIn
        end
    end

    local function AddListItem( index, id, url, shouldScroll )
        if index == 1 then
            scrollEmojis:Clear()
        end

        local item = scrollEmojis:Add( "DPanel" )
        item:Dock( TOP )
        item:DockMargin( 2, 2, 2, 2 )
        item:DockPadding( 2, 2, 2, 2 )

        local labelIndex = vgui.Create( "DLabel", item )
        labelIndex:SetText( index )
        labelIndex:SizeToContents()
        labelIndex:Dock( LEFT )
        labelIndex:DockMargin( 2, 0, 4, 0 )
        labelIndex:SetColor( Color( 0, 0, 0, 255 ) )

        local entryId = vgui.Create( "DTextEntry", item )
        entryId:SetWide( 100 )
        entryId:Dock( LEFT )
        entryId:SetHistoryEnabled( false )
        entryId:SetMultiline( false )
        entryId:SetMaximumCharCount( 32 )
        entryId:SetUpdateOnType( true )
        entryId:SetPlaceholderText( "<emoji id>" )

        entryId.OnValueChange = function( s, value )
            local newId = string.Trim( value )
            local existingIndex = FindEmojiIndexById( newId )

            if string.len( newId ) == 0 then
                MarkEntryAsInvalid( s, L"emojis.empty_id" )

            elseif string.find( newId, "[^%w_%-]" ) then
                MarkEntryAsInvalid( s, L"emojis.invalid_characters" )

            elseif existingIndex and existingIndex ~= index then
                MarkEntryAsInvalid( s, string.format( L"emojis.id_in_use", existingIndex ) )

            elseif IsBuiltInEmoji( newId ) then
                MarkEntryAsInvalid( s, string.format( L"emojis.id_builtin", newId ) )

            else
                MarkEntryAsValid( s )
            end

            UpdateEmoji( index, newId, customEmojis[index].url )
        end

        local entryURL = vgui.Create( "DTextEntry", item )
        entryURL:Dock( FILL )
        entryURL:DockMargin( 4, 0, 4, 0 )
        entryURL:SetHistoryEnabled( false )
        entryURL:SetMultiline( false )
        entryURL:SetMaximumCharCount( 256 )
        entryURL:SetUpdateOnType( true )
        entryURL:SetPlaceholderText( L"emojis.url_placeholder" )

        entryURL.OnValueChange = function( s, value )
            local newURL = string.Trim( value )

            if string.len( newURL ) == 0 then
                MarkEntryAsInvalid( s, L"emojis.empty_url" )
            else
                MarkEntryAsValid( s )
            end

            UpdateEmoji( index, customEmojis[index].id, newURL )
        end

        timer.Simple( 0, function()
            entryId:SetValue( id )
            entryURL:SetValue( url )
        end )

        local btnRemove = vgui.Create( "DButton", item )
        btnRemove:SetIcon( "icon16/cancel.png" )
        btnRemove:SetTooltip( L"emojis.remove" )
        btnRemove:SetText( "" )
        btnRemove:SetWide( 24 )
        btnRemove:Dock( RIGHT )

        btnRemove.DoClick = function()
            RemoveEmoji( index )
        end

        customEmojis[index]._idEntry = entryId
        customEmojis[index]._urlEntry = entryURL

        if shouldScroll then
            timer.Simple( 0, function()
                scrollEmojis:ScrollToChild( item )
            end )
        end
    end

    RefreshList = function()
        scrollEmojis:Clear()

        if #customEmojis == 0 then
            local item = scrollEmojis:Add( "DLabel" )
            item:Dock( TOP )
            item:SetText( L"emojis.empty_list" )
            item:SetContentAlignment( 5 )
            item:DockMargin( 4, 4, 4, 4 )
            item:DockPadding( 2, 2, 2, 2 )
            return
        end

        for index, v in ipairs( customEmojis ) do
            AddListItem( index, v.id, v.url )
        end
    end

    RefreshList()

    local panelOptions = vgui.Create( "DPanel", frame )
    panelOptions:Dock( BOTTOM )
    panelOptions:DockPadding( 4, 4, 4, 4 )
    panelOptions:SetTall( 32 )

    local buttonAdd = vgui.Create( "DButton", panelOptions )
    buttonAdd:SetIcon( "icon16/add.png" )
    buttonAdd:SetText( L"emojis.add" )
    buttonAdd:SetWide( 130 )
    buttonAdd:Dock( LEFT )

    buttonAdd.DoClick = function()
        local newIndex = #customEmojis + 1
        local newId = "emoji-" .. newIndex

        table.insert( customEmojis, { id = newId, url = "" } )
        AddListItem( newIndex, newId, "", true )
    end

    local buttonAddSilk = vgui.Create( "DButton", panelOptions )
    buttonAddSilk:SetIcon( "icon16/emoticon_evilgrin.png" )
    buttonAddSilk:SetText( L"emojis.add_silkicon" )
    buttonAddSilk:SetTooltip( L"emojis.add_silkicon_tip" )
    buttonAddSilk:SetWide( 130 )
    buttonAddSilk:Dock( LEFT )

    local silkPanel

    frame.OnClose = function()
        if IsValid( silkPanel ) then
            silkPanel:Close()
        end
    end

    buttonAddSilk.DoClick = function()
        if IsValid( silkPanel ) then
            silkPanel:MakePopup()
            return
        end

        silkPanel = vgui.Create( "DFrame" )
        silkPanel:SetSize( 335, 200 )
        silkPanel:SetTitle( L"emojis.add_silkicon" )
        silkPanel:Center()
        silkPanel:MakePopup()

        local iconBrowser = vgui.Create( "DIconBrowser", silkPanel )
        iconBrowser:Dock( FILL )

        iconBrowser.OnChange = function( s )
            local iconPath = s:GetSelectedIcon()
            local newIndex = #customEmojis + 1
            local newId = string.GetFileFromFilename( iconPath ):sub( 1, -5 )
            local newUrl = "asset://garrysmod/materials/" .. iconPath

            table.insert( customEmojis, { id = newId, url = newUrl } )
            AddListItem( newIndex, newId, newUrl, true )

            silkPanel:Close()
        end

        local editFilter = vgui.Create( "DTextEntry", silkPanel )
        editFilter:SetHistoryEnabled( false )
        editFilter:SetMultiline( false )
        editFilter:SetMaximumCharCount( 50 )
        editFilter:SetUpdateOnType( true )
        editFilter:SetPlaceholderText( "<search>" )
        editFilter:Dock( BOTTOM )

        editFilter.OnValueChange = function( _, value )
            iconBrowser:FilterByText( string.Trim( value ) )
        end
    end

    local buttonApply = vgui.Create( "DButton", panelOptions )
    buttonApply:SetIcon( "icon16/accept.png" )
    buttonApply:SetText( L"emojis.apply" )
    buttonApply:SetWide( 150 )
    buttonApply:Dock( RIGHT )

    buttonApply._DefaultPaint = buttonApply.Paint

    buttonApply.Paint = function( s, w, h )
        s:_DefaultPaint( w, h )

        surface.SetDrawColor( 255, 255, 0, 180 * math.abs( math.sin( RealTime() * 3 ) ) )
        surface.DrawRect( 0, 0, w, h )
    end

    buttonApply.DoClick = function()
        local data = {}

        for k, v in ipairs( customEmojis ) do
            local invalidReason = v._idEntry._invalidReason or v._urlEntry._invalidReason

            if invalidReason then
                local text = string.format( L"emojis.invalid_reason", k, invalidReason )
                Derma_Message( text, L"emojis.invalid", L"ok" )

                return
            end

            data[k] = { id = v.id, url = v.url }
        end

        local action = ( #data > 0 ) and "emojis.apply_tip" or "emojis.remove_tip"

        data = ( #data > 0 ) and util.TableToJSON( data ) or ""

        Derma_Query( L( action ), L"emojis.apply_title", L"yes", function()
            net.Start( "customchat.set_emojis", false )
            net.WriteString( data )
            net.SendToServer()

            frame:Close()
        end, L"no" )
    end
end
