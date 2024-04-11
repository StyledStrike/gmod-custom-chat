local PANEL = {}

function PANEL:Init()
    self:SetTitle( "" )
    self:ShowCloseButton( false )

    self.history = vgui.Create( "CustomChatHistory", self )
    self.history:Dock( FILL )
    self.history:DockMargin( 0, -24, 0, 0 )
    self.history:SetDisplayMode( "temp" )
    self.history:SetFontSize( CustomChat.Config.fontSize )
    self.history:UpdateEmojiPanel()

    self.history.OnClickLink = function( url )
        gui.OpenURL( url )
    end

    self.history.OnPressEnter = function()
        if self.isChatOpen then self:SubmitMessage() end
    end

    self.history.OnSelectEmoji = function( id )
        if self.isChatOpen then self:AppendAtCaret( ":" .. id .. ":" ) end
    end

    self.history.OnRightClick = function( data )
        if self.isChatOpen then self.OnRightClick( data ) end
    end

    self.entryDock = vgui.Create( "DPanel", self )
    self.entryDock:Dock( BOTTOM )
    self.entryDock:DockMargin( 0, 4, 0, 0 )
    self.entryDock._backgroundColor = Color( 0, 0, 0 )

    self.entryDock.Paint = function( s, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, s._backgroundColor )
    end

    self.entry = vgui.Create( "DTextEntry", self.entryDock )
    self.entry:SetFont( "ChatFont" )
    self.entry:SetDrawBorder( false )
    self.entry:SetPaintBackground( false )
    self.entry:SetMaximumCharCount( CustomChat.MAX_MESSAGE_LENGTH )
    self.entry:SetTabbingDisabled( true )
    self.entry:SetMultiline( true )
    self.entry:SetHistoryEnabled( true )
    self.entry:SetDrawLanguageID( false )
    self.entry:Dock( FILL )

    self.entry.Paint = function( s, w, h )
        derma.SkinHook( "Paint", "TextEntry", s, w, h )
    end

    self.entry.OnChange = function( s )
        if s.GetText then
            local text = s:GetText() or ""

            hook.Run( "ChatTextChanged", text )

            local _, lineCount = string.gsub( text, "\n", "\n" )
            lineCount = math.Clamp( lineCount + 1, 1, 5 )

            self.entryDock:SetTall( 20 * lineCount )
            self.entry._multilineMode = lineCount > 1
        end
    end

    self.entry.OnKeyCodeTyped = function( s, code )
        if code == KEY_ESCAPE then
            chat.Close()
            gui.HideGameUI()

        elseif code == KEY_F then
            if input.IsControlDown() then
                self.history:FindText()
            end

        elseif code == KEY_TAB then
            local text = s:GetText()
            local replaceText = hook.Run( "OnChatTab", text )

            if type( replaceText ) == "string" and replaceText ~= text:Trim() then
                s:SetText( replaceText )
                s:SetCaretPos( string.len( replaceText ) )
            else
                self:AppendAtCaret( "  " )
            end

        elseif code == KEY_ENTER and not input.IsShiftDown() then
            self:SubmitMessage()
            return true
        end

        if not s._multilineMode and s.m_bHistory then
            if code == KEY_UP then
                s.HistoryPos = s.HistoryPos - 1
                s:UpdateFromHistory()
            end

            if code == KEY_DOWN then
                s.HistoryPos = s.HistoryPos + 1
                s:UpdateFromHistory()
            end
        end
    end

    local emojisButton = vgui.Create( "DImageButton", self.entryDock )
    emojisButton:SetImage( "icon16/emoticon_smile.png" )
    emojisButton:SetStretchToFit( false )
    emojisButton:SetWide( 22 )
    emojisButton:Dock( RIGHT )

    emojisButton.DoClick = function()
        self.history:ToggleEmojiPanel()
    end

    self.isChatOpen = false
    self:LoadThemeData()
    self:CloseChat()
end

function PANEL.OnSubmitMessage( _text ) end
function PANEL.OnRightClick( _data ) end

function PANEL:SubmitMessage()
    local text = CustomChat.CleanupString( self.entry:GetText() )

    if string.len( text ) > 0 then
        local history = self.entry.History
        table.RemoveByValue( history, text )

        local historyCount = #history
        history[historyCount + 1] = text

        if historyCount >= 50 then
            table.remove( history, 1 )
        end
    end

    self.entry:SetText( "" )
    self.OnSubmitMessage( text )
end

function PANEL:AppendContents( contents, showTimestamp )
    self.history:AppendContents( contents, showTimestamp )
end

function PANEL:AppendAtCaret( text )
    local caretPos = self.entry:GetCaretPos()
    local oldText = self.entry:GetText()
    local newText = oldText:sub( 1, caretPos ) .. text .. oldText:sub( caretPos + 1 )

    if string.len( newText ) < self.entry:GetMaximumCharCount() then
        self.entry:SetText( newText )
        self.entry:SetCaretPos( caretPos + text:len() )
    else
        surface.PlaySound( "resource/warning.wav" )
    end
end

function PANEL:OpenChat()
    self.entry:RequestFocus()
    self.entryDock:SetTall( 20 )
    self.history:ScrollToBottom()

    self:SetDisplayMode( "main" )
    self.isChatOpen = true
end

function PANEL:CloseChat()
    self.history:ClearSelection()
    self.entry:SetText( "" )
    self.entry.HistoryPos = 0
    self.entry._multilineMode = false

    self:SetDisplayMode( "temp" )
    self.isChatOpen = false
end

function PANEL:SetDisplayMode( mode )
    self.history:SetDisplayMode( mode )

    local areChildrenVisible = mode == "main"

    for _, pnl in ipairs( self:GetChildren() ) do
        if pnl ~= self.history and
            pnl ~= self.btnMaxim and
            pnl ~= self.btnClose and
            pnl ~= self.btnMinim
        then
            pnl:SetVisible( areChildrenVisible )
        end
    end
end

function PANEL:SetEntryLabel( label, color )
    self.entry:SetPlaceholderText( label )
    self.entryDock._backgroundColor = color or self.inputBackgroundColor
end

function PANEL:LoadThemeData( data )
    CustomChat.Theme.ParseTheme( data, self )

    self.history:SetDefaultFont( self.fontName )
    self.history:SetFontShadowEnabled( self.enableFontShadow )
    self.history:SetEnableAnimations( self.enableSlideAnimation )
    self.history:SetEnableAvatars( self.enableAvatars )

    self.history:SetBackgroundColor( self.inputBackgroundColor )
    self.history:SetScrollBarColor( self.scrollBarColor )
    self.history:SetScrollBackgroundColor( self.scrollBackgroundColor )
    self.history:SetHighlightColor( self.highlightColor )

    self:DockPadding( self.padding, self.padding + 24, self.padding, self.padding )

    self.entry:SetTextColor( self.inputColor )
    self.entry:SetCursorColor( self.inputColor )
    self.entry:SetHighlightColor( self.highlightColor )
    self.entryDock._backgroundColor = self.inputBackgroundColor

    self:InvalidateChildren()
end

local MAT_BLUR = Material( "pp/blurscreen" )

function PANEL:Paint( w, h )
    if self.isChatOpen then
        if self.backgroundBlur > 0 then
            surface.SetDrawColor( 255, 255, 255, 255 )
            surface.SetMaterial( MAT_BLUR )

            MAT_BLUR:SetFloat( "$blur", self.backgroundBlur )
            MAT_BLUR:Recompute()

            render.UpdateScreenEffectTexture()

            local x, y = self:LocalToScreen( 0, 0 )
            surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
        end

        draw.RoundedBox( self.cornerRadius, 0, 0, w, h, self.backgroundColor )
    end
end

vgui.Register( "CustomChatFrame", PANEL, "DFrame" )
