local Settings = {
    filePath = "schat.json",

    width = 550,
    height = 260,
    offset_left = -1,
    offset_bottom = -1,

    font_size = 18,
    allow_any_url = false,
    timestamps = false
}

function Settings:ValidateInteger( n, min, max )
    return math.Round( math.Clamp( tonumber( n ), min, max ) )
end

function Settings:ValidateColor( clr )
    return Color(
        self:ValidateInteger( clr.r or 255, 0, 255 ),
        self:ValidateInteger( clr.g or 255, 0, 255 ),
        self:ValidateInteger( clr.b or 255, 0, 255 ),
        self:ValidateInteger( clr.a or 255, 0, 255 )
    )
end

function Settings:Save()
    file.Write( self.filePath, util.TableToJSON( {
        width			= self.width,
        height			= self.height,
        font_size		= self.font_size,
        allow_any_url 	= self.allow_any_url,
        timestamps      = self.timestamps,
        offset_left		= self.offset_left,
        offset_bottom	= self.offset_bottom
    }, true ) )
end

function Settings:Load()
    -- try to load settings
    local rawData = file.Read( self.filePath, "DATA" )
    if rawData == nil then return end

    local data = util.JSONToTable( rawData ) or {}

    if data.width then
        self.width = self:ValidateInteger( data.width, 250, 1000 )
    end

    if data.height then
        self.height = self:ValidateInteger( data.height, 150, 1000 )
    end

    if data.font_size then
        self.font_size = self:ValidateInteger( data.font_size, 10, 64 )
    end

    if data.offset_left then
        self.offset_left = self:ValidateInteger( data.offset_left, -1, 1000 )
    end

    if data.offset_bottom then
        self.offset_bottom = self:ValidateInteger( data.offset_bottom, -1, 1000 )
    end

    self.timestamps = tobool( data.timestamps )
    self.allow_any_url = tobool( data.allow_any_url )
end

function Settings:ResetDefaultPosition()
    self.offset_left = -1
    self.offset_bottom = -1
end

function Settings:GetDefaultPosition()
    local bottomY = ( ScrH() - self.height )
    return
        Either( self.offset_left > 0, self.offset_left, ScrW() * 0.032 ),
        Either( self.offset_bottom > 0, bottomY - self.offset_bottom, bottomY - ScrH() * 0.18 )
end

function Settings:GetDefaultSize()
    return 550, 260
end

function Settings:SetWhitelistEnabled( enabled )
    self.allow_any_url = not enabled

    if enabled then
        SChat.InternalMessage( "Whitelist", "Only load images from trusted websites." )
    else
        SChat.InternalMessage( "Whitelist", "Load images from any website." )
    end
end

-- Returns the properties of a emoji.
-- path, isOnline = Settings:GetEmojiInfo(id)
function Settings:GetEmojiInfo( id )
    for _, cat in ipairs( self.emojiCategories ) do
        for _, v in ipairs( cat.emojis ) do

            if type( v ) == "string" then
                if id == v then
                    return "materials/icon72/" .. id .. ".png"
                end
            else
                if id == v[1] then
                    return v[2], true
                end
            end

        end
    end
end

-- Add a image from the web as a emoji.
-- "index" is optional
function Settings:AddOnlineEmoji( id, url, index )
    local emojis = self.emojiCategories[1].emojis

    index = index and math.Clamp( index, 1, #emojis + 1 ) or #emojis + 1
    emojis[index] = { id, url }
end

function Settings:ClearCustomEmojis()
    self.emojiCategories[1].emojis = {}
end

function Settings:ShowServerEmojisPanel()
    chat.Close()

    local pnl = vgui.Create( "DFrame" )
    pnl:SetSize( 600, 400 )
    pnl:SetTitle( "Server Emojis" )
    pnl:ShowCloseButton( true )
    pnl:SetDeleteOnClose( true )
    pnl:Center()
    pnl:MakePopup()

    local emojis = table.Copy( self.emojiCategories[1].emojis )
    local refreshListFunc

    local scrollEmojis = vgui.Create( "DScrollPanel", pnl )
    scrollEmojis:Dock( FILL )

    local function removeEmoji( index )
        table.remove( emojis, index )
        refreshListFunc()
    end

    local function updateEmoji( index, id, url )
        emojis[index][1] = id
        emojis[index][2] = url
    end

    local function markEntryAsInvalid( entry, reason )
        entry._invalidReason = reason
        entry:SetBGColor( Color( 100, 0, 0, 255 ) )
        entry:SetPaintBackgroundEnabled( true )
    end

    local function markEntryAsValid( entry )
        entry._invalidReason = nil
        entry:SetPaintBackgroundEnabled( false )
    end

    local function findEmojiIndexById( id )
        for k, v in ipairs( emojis ) do
            if v[1] == id then
                return k
            end
        end
    end

    local function addListItem( index, id, url, scroll )
        if index == 1 then
            -- remove "no emojis yet"
            scrollEmojis:Clear()
        end

        local item = scrollEmojis:Add( "DPanel" )
        item:Dock( TOP )
        item:DockMargin( 0, 2, 0, 2 )
        item:DockPadding( 2, 2, 2, 2 )

        local lblIndex = vgui.Create( "DLabel", item )
        lblIndex:SetText( index )
        lblIndex:SizeToContents()
        lblIndex:Dock( LEFT )
        lblIndex:DockMargin( 2, 0, 4, 0 )

        local editId = vgui.Create( "DTextEntry", item )
        editId:SetWide( 100 )
        editId:Dock( LEFT )
        editId:SetHistoryEnabled( false )
        editId:SetMultiline( false )
        editId:SetMaximumCharCount( 32 )
        editId:SetUpdateOnType( true )
        editId:SetPlaceholderText( "<emoji id>" )

        editId.OnValueChange = function( s, value )
            local newId = string.Trim( value )
            local existingId = findEmojiIndexById( newId )

            if existingId and existingId ~= index then
                markEntryAsInvalid( s, "Emoji #" .. existingId .. " has the same ID" )

            elseif string.len( newId ) == 0 then
                markEntryAsInvalid( s, "The ID is empty" )

            elseif string.find( newId, "[^%w_%-]" ) then
                markEntryAsInvalid( s, "Only _, -, characters between 0-9 and A-Z are allowed" )
            else
                markEntryAsValid( s )
            end

            updateEmoji( index, newId, emojis[index][2] )
        end

        local editURL = vgui.Create( "DTextEntry", item )
        editURL:Dock( FILL )
        editURL:DockMargin( 4, 0, 4, 0 )
        editURL:SetHistoryEnabled( false )
        editURL:SetMultiline( false )
        editURL:SetMaximumCharCount( 256 )
        editURL:SetUpdateOnType( true )
        editURL:SetPlaceholderText( "<link to a image>" )
        editURL._branchWarning = true

        editURL.OnValueChange = function( s, value )
            local newURL = string.Trim( value )

            if string.len( newURL ) == 0 then
                markEntryAsInvalid( s, "The URL is empty" )
            else
                if not s._branchWarning and BRANCH == "unknown" and newURL:sub( 1, 5 ) == "https" then
                    s._branchWarning = true
                    Derma_Message( "Some websites using the TLS protocol (https) will not work without the Chromium beta for Garry's Mod.", "Warning", "OK" )
                end

                markEntryAsValid( s )
            end

            updateEmoji( index, emojis[index][1], newURL )
        end

        timer.Simple( 0, function()
            editId:SetValue( id )
            editURL:SetValue( url )

            -- we only want to show branch warnings
            -- when the user edits this field
            editURL._branchWarning = nil
        end )

        local btnRemove = vgui.Create( "DButton", item )
        btnRemove:SetIcon( "icon16/cancel.png" )
        btnRemove:SetTooltip( "Remove" )
        btnRemove:SetText( "" )
        btnRemove:SetWide( 24 )
        btnRemove:Dock( RIGHT )

        btnRemove.DoClick = function()
            removeEmoji( index )
        end

        emojis[index][3] = editId
        emojis[index][4] = editURL

        if scroll then
            scrollEmojis:ScrollToChild( item )
        end
    end

    refreshListFunc = function()
        scrollEmojis:Clear()

        if #emojis == 0 then
            local item = scrollEmojis:Add( "DLabel" )
            item:Dock( TOP )
            item:SetText( "No emojis yet." )
            item:SetContentAlignment( 5 )
            item:DockMargin( 4, 4, 4, 4 )
            item:DockPadding( 2, 2, 2, 2 )
            return
        end

        for index, v in ipairs( emojis ) do
            addListItem( index, v[1], v[2] )
        end
    end

    refreshListFunc()

    local pnlOptions = vgui.Create( "DPanel", pnl )
    pnlOptions:Dock( BOTTOM )

    local btnAdd = vgui.Create( "DButton", pnlOptions )
    btnAdd:SetIcon( "icon16/add.png" )
    btnAdd:SetText( " Add" )
    btnAdd:SetWide( 100 )
    btnAdd:Dock( LEFT )

    btnAdd.DoClick = function()
        local newIndex = #emojis + 1
        local newId = "emoji-" .. newIndex

        table.insert( emojis, { newId, "" } )
        addListItem( newIndex, newId, "", true )
    end

    local btnAddSilk = vgui.Create( "DButton", pnlOptions )
    btnAddSilk:SetIcon( "icon16/emoticon_evilgrin.png" )
    btnAddSilk:SetText( " Add Silkicon" )
    btnAddSilk:SetTooltip( "Add one of the icons bundled with Garry's Mod" )
    btnAddSilk:SetWide( 95 )
    btnAddSilk:Dock( LEFT )

    local silkPanel

    pnl.OnClose = function()
        if IsValid( silkPanel ) then
            silkPanel:Close()
        end
    end

    btnAddSilk.DoClick = function()
        if IsValid( silkPanel ) then
            silkPanel:MakePopup()
            return
        end

        silkPanel = vgui.Create( "DFrame" )
        silkPanel:SetSize( 335, 200 )
        silkPanel:SetTitle( "Add Silkicon" )
        silkPanel:Center()
        silkPanel:MakePopup()

        local iconBrowser = vgui.Create( "DIconBrowser", silkPanel )
        iconBrowser:Dock( FILL )

        iconBrowser.OnChange = function( s )
            local iconPath = s:GetSelectedIcon()

            local newIndex = #emojis + 1
            local newId = string.GetFileFromFilename( iconPath ):sub( 1, -5 )
            local newUrl = "asset://garrysmod/materials/" .. iconPath

            table.insert( emojis, { newId, newUrl } )
            addListItem( newIndex, newId, newUrl, true )

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

    local btnApply = vgui.Create( "DButton", pnlOptions )
    btnApply:SetIcon( "icon16/accept.png" )
    btnApply:SetText( " Apply" )
    btnApply:Dock( RIGHT )

    btnApply.DoClick = function()
        local data = {}

        for k, v in ipairs( emojis ) do
            local invalidReason = v[3]._invalidReason or v[4]._invalidReason

            if invalidReason then
                Derma_Message( "Invalid emoji #" .. k .. ": " .. invalidReason, "Invalid Emoji", "OK" )
                return
            end

            data[k] = { v[1], v[2] }
        end

        local action = ( #data > 0 ) and "set the" or "remove all"

        data = ( #data > 0 ) and util.TableToJSON( data ) or ""

        Derma_Query( "This action will " .. action .. " custom emojis for this server.\nAre you sure?",
            "Set Custom Emojis", "Yes", function()
                net.Start( "schat.set_emojis", false )
                net.WriteString( data )
                net.SendToServer()

                pnl:Close()
            end,
            "No" )
    end
end

Settings.emojiCategories = {
    { category = "Custom", emojis = {
        { "rainbowplz", "https://emoji.gg/assets/emoji/1908_RainbowPls.gif" }
    } },
    { category = "People", emojis = {
        "angel",
        "anger",
        "angry",
        "anguished",
        "astonished",
        "baby",
        "blue_heart",
        "blush",
        "boom",
        "broken_heart",
        "bust_in_silhouette",
        "clap",
        "cold_sweat",
        "confounded",
        "confused",
        "cry",
        "cupid",
        "disappointed",
        "dizzy",
        "dizzy_face",
        "droplet",
        "ear",
        "exclamation",
        "expressionless",
        "eyes",
        "fearful",
        "feet",
        "fire",
        "fist",
        "flushed",
        "frowning",
        "grey_exclamation",
        "grey_question",
        "grimacing",
        "grin",
        "grinning",
        "hand",
        "hankey",
        "hear_no_evil",
        "heart",
        "heart_eyes",
        "heartpulse",
        "hushed",
        "imp",
        "innocent",
        "joy",
        "kiss",
        "kissing",
        "kissing_heart",
        "kissing_smiling_eyes",
        "laughing",
        "lips",
        "mask",
        "muscle",
        "musical_note",
        "neutral_face",
        "no_good",
        "no_mouth",
        "nose",
        "notes",
        "ok_hand",
        "open_hands",
        "open_mouth",
        "pensive",
        "persevere",
        "point_down",
        "point_left",
        "point_right",
        "point_up",
        "pray",
        "punch",
        "question",
        "rage",
        "raised_hands",
        "relaxed",
        "relieved",
        "revolving_hearts",
        "satisfied",
        "scream",
        "see_no_evil",
        "sleeping",
        "sleepy",
        "smile",
        "smiley",
        "smirk",
        "sob",
        "sparkles",
        "speak_no_evil",
        "star",
        "star2",
        "stuck_out_tongue",
        "stuck_out_tongue_closed_eyes",
        "stuck_out_tongue_winking_eye",
        "sunglasses",
        "sweat",
        "sweat_drops",
        "sweat_smile",
        "thought_balloon",
        "tired_face",
        "triumph",
        "unamused",
        "wave",
        "weary",
        "wink",
        "worried",
        "yum",
        "zzz"
    } },
    { category = "Objects", emojis = {
        "8ball",
        "alarm_clock",
        "apple",
        "art",
        "baby_bottle",
        "bar_chart",
        "basketball",
        "bathtub",
        "battery",
        "beer",
        "bell",
        "birthday",
        "bomb",
        "book",
        "bookmark",
        "books",
        "bread",
        "briefcase",
        "bulb",
        "camera",
        "candy",
        "cd",
        "christmas_tree",
        "clapper",
        "clipboard",
        "computer",
        "corn",
        "credit_card",
        "date",
        "doughnut",
        "dvd",
        "eggplant",
        "electric_plug",
        "email",
        "eyeglasses",
        "file_folder",
        "flashlight",
        "floppy_disk",
        "game_die",
        "gem",
        "gift",
        "grapes",
        "guitar",
        "gun",
        "hamburger",
        "hammer",
        "high_brightness",
        "high_heel",
        "hourglass",
        "icecream",
        "lock",
        "mans_shoe",
        "musical_keyboard",
        "mute",
        "paperclip",
        "pencil2",
        "pill",
        "pushpin",
        "satellite",
        "soccer",
        "sound",
        "toilet",
        "tv",
        "video_game",
        "wine_glass",
        "wrench"
    } },
    { category = "Symbols", emojis = {
        "+1",
        "-1",
        "100",
        "1234",
        "abc",
        "zero",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "arrow_backward",
        "arrow_double_down",
        "arrow_double_up",
        "arrow_down",
        "arrow_down_small",
        "arrow_forward",
        "arrow_heading_down",
        "arrow_heading_up",
        "arrow_left",
        "arrow_lower_left",
        "arrow_lower_right",
        "arrow_right",
        "arrow_right_hook",
        "arrow_up",
        "arrow_up_down",
        "arrow_up_small",
        "arrow_upper_left",
        "arrow_upper_right",
        "arrows_clockwise",
        "arrows_counterclockwise",
        "bangbang",
        "black_large_square",
        "black_medium_small_square",
        "black_square_button",
        "cancer",
        "cinema",
        "clock1",
        "cool",
        "copyright",
        "fast_forward",
        "free",
        "hash",
        "heavy_check_mark",
        "heavy_division_sign",
        "heavy_dollar_sign",
        "heavy_minus_sign",
        "heavy_multiplication_x",
        "heavy_plus_sign",
        "id",
        "information_source",
        "interrobang",
        "keycap_ten",
        "koko",
        "new",
        "ng",
        "no_entry",
        "no_entry_sign",
        "ok",
        "parking",
        "radio_button",
        "recycle",
        "red_circle",
        "registered",
        "signal_strength",
        "small_blue_diamond",
        "small_orange_diamond",
        "small_red_triangle",
        "small_red_triangle_down",
        "sos",
        "tm",
        "underage",
        "up",
        "white_check_mark"
    } },
    { category = "Nature", emojis = {
        "bear",
        "bird",
        "blossom",
        "cat",
        "cat2",
        "cherry_blossom",
        "chicken",
        "cow2",
        "cyclone",
        "dog",
        "dog2",
        "dolphin",
        "earth_americas",
        "elephant",
        "evergreen_tree",
        "fish",
        "four_leaf_clover",
        "globe_with_meridians",
        "maple_leaf",
        "monkey_face",
        "mouse",
        "mouse2",
        "ocean",
        "rooster",
        "rose",
        "snowflake",
        "wolf",
        "zap"
    } },
    { category = "Places", emojis = {
        "airplane",
        "ambulance",
        "barber",
        "beginner",
        "bike",
        "blue_car",
        "boat",
        "bullettrain_front",
        "bus",
        "car",
        "checkered_flag",
        "helicopter",
        "moyai",
        "rainbow",
        "rocket",
        "stars",
        "traffic_light",
        "vertical_traffic_light",
        "warning"
    } }
}

SChat.Settings = Settings
