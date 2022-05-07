-- Cleanup previous stuff when reloading this script (helps during development)
if IsValid(SChat.frame) then
	chat.Close()

	SChat.frame:SetMouseInputEnabled(false)
	SChat.frame:SetKeyboardInputEnabled(false)
	SChat.frame:SetDeleteOnClose(true)
	SChat.frame:Close()

	SChat.chatBox = nil
	SChat.frame = nil
end

SChat.isOpened = false
SChat.usingServerTheme = false
SChat.serverTheme = ''

-- keep track of the original functions
chat.DefaultOpen = chat.DefaultOpen or chat.Open
chat.DefaultClose = chat.DefaultClose or chat.Close
chat.DefaultAddText = chat.DefaultAddText or chat.AddText
chat.DefaultGetChatBoxPos = chat.DefaultGetChatBoxPos or chat.GetChatBoxPos
chat.DefaultGetChatBoxSize = chat.DefaultGetChatBoxSize or chat.GetChatBoxSize

local Settings = SChat.Settings
local Theme = SChat.Theme

function SChat:CreatePanels()
	Settings:Load()
	Theme:Load()

	self.frame = vgui.Create('DFrame')
	self.frame:SetSize(Settings.width, Settings.height)
	self.frame:SetPos(Settings:GetDefaultPosition())
	self.frame:SetTitle('')
	self.frame:ShowCloseButton(false)
	self.frame:SetDraggable(true)
	self.frame:SetSizable(true)
	self.frame:SetScreenLock(true)
	self.frame:SetMinWidth(250)
	self.frame:SetMinHeight(150)

	self.frame.Paint = function(s, w, h)
		if self.isOpened then
			draw.RoundedBox(Theme.corner_radius, 0, 0, w, h, Theme.background)
		end
	end

	self.frame.OnSizeChanged = function(s, w, h)
		local x, y = s:GetPos()

		Settings.width = w
		Settings.height = h
		Settings.offset_left = x
		Settings.offset_bottom = ScrH() - h - y
		Settings:Save()
	end

	self.frame._MouseReleased = self.frame.OnMouseReleased

	self.frame.OnMouseReleased = function(s)
		if s.Dragging then
			local x, y, _, h = s:GetBounds()

			Settings.offset_left = x
			Settings.offset_bottom = ScrH() - h - y
			Settings:Save()
		end

		s:_MouseReleased()
	end

	self.chatBox = vgui.Create('SChatBox', self.frame)
	self.chatBox:SetFontSize(Settings.font_size)
	self.chatBox:Dock(FILL)
	self.chatBox:DockMargin(0, -24, 0, 0)
	self.chatBox:UpdateEmojiPanel()

	self.chatBox.OnSelectEmoji = function(_, id)
		local txt = self.entry:GetText() .. ':' .. id .. ':'

		if string.len(txt) < self.entry:GetMaximumCharCount() then
			self.entry:SetText(txt)
			self.entry:SetCaretPos(string.len(txt))
		else
			surface.PlaySound('resource/warning.wav')
		end
	end

	self.chatBox.OnPressEnter = function()
		self:OnPressEnter()
	end

	self.entryDock = vgui.Create('DPanel', self.frame)
	self.entryDock:Dock(BOTTOM)
	self.entryDock:DockMargin(0, 4, 0, 0)
	self.entryDock._backgroundColor = Theme.input_background

	self.entryDock.Paint = function(s, w, h)
		draw.RoundedBox(0, 0, 0, w, h, s._backgroundColor)
	end

	self.entry = vgui.Create('DTextEntry', self.entryDock)
	self.entry:SetFont('ChatFont')
	self.entry:SetDrawBorder(false)
	self.entry:SetPaintBackground(false)
	self.entry:SetMaximumCharCount(126)
	self.entry:SetTabbingDisabled(true)
	self.entry:Dock(FILL)

	self.entry.Paint = function(s, w, h)
		derma.SkinHook('Paint', 'TextEntry', s, w, h)
	end

	self.entry.OnTextChanged = function(s)
		if s and s.GetText then
			hook.Run('ChatTextChanged', s:GetText() or '')
		end
	end

	self.entry.OnKeyCodeTyped = function(s, code)
		if code == KEY_ESCAPE then
			chat.Close()
			gui.HideGameUI()

		elseif code == KEY_F then
			if input.IsControlDown() then
				self.chatBox:FindText()
			end

		elseif code == KEY_TAB then
			local replaceText = hook.Run('OnChatTab', s:GetText() or '')
			if replaceText and type(replaceText) == 'string' then
				s:SetText(replaceText)
				s:SetCaretPos(string.len(replaceText))
			end

		elseif code == KEY_ENTER then
			self:OnPressEnter()
		end
	end

	local btnEmotes = vgui.Create('DImageButton', self.entryDock)
	btnEmotes:SetImage('icon16/emoticon_smile.png')
	btnEmotes:SetStretchToFit(false)
	btnEmotes:SetWide(22)
	btnEmotes:Dock(RIGHT)

	btnEmotes.DoClick = function()
		self.chatBox:ToggleEmojiPanel()
	end

	chat.GetChatBoxPos = function()
		return self.frame:GetPos()
	end

	chat.GetChatBoxSize = function()
		return self.frame:GetSize()
	end

	self:ApplyTheme(true)
	self:SuggestServerTheme()
	self:SetInputEnabled(false)
end

function SChat:OnPressEnter()
	if not self.isOpened then return end

	local text = string.Trim(self.entry:GetText())

	if string.len(text) > 0 then
		local commandStr = self.teamMode and 'say_team "%s"' or 'say "%s"'
		LocalPlayer():ConCommand( string.format(commandStr, text) )
	end

	chat.Close()
end

function SChat:SuggestServerTheme()
	if IsValid(self.btnSuggest) then
		self.btnSuggest:Remove()
		self.btnSuggest = nil
	end

	if self.serverTheme == '' then
		return
	end

	self:CloseExtraPanels()

	self.btnSuggest = vgui.Create('DImageButton', self.entryDock)
	self.btnSuggest:SetImage('icon16/asterisk_yellow.png')
	self.btnSuggest:SetTooltip('Server Theme')
	self.btnSuggest:SetStretchToFit(false)
	self.btnSuggest:SetWide(22)
	self.btnSuggest:Dock(RIGHT)

	self.btnSuggest.DoClick = function()
		Derma_Query('This server has a custom theme.\nDo you want to use it?', 'Server Theme', 'Yes', function()
			local success, errMsg = Theme:Import(self.serverTheme)
			if success then
				self.usingServerTheme = true
				self:ApplyTheme(true)

				self.btnSuggest:Remove()
				self.btnSuggest = nil
			else
				Derma_Message('Error: ' .. errMsg, 'Failed to apply the server theme', 'OK')
			end
		end, 'No')
	end
end

function SChat:OpenContextMenu(data, isLink)
	local optionsMenu = DermaMenu(false, self.frame)
	optionsMenu:SetMinimumWidth(200)

	if data ~= '' then
		optionsMenu:AddOption(isLink and 'Copy Link..' or 'Copy...', function()
			SetClipboardText(data)
		end):SetIcon('icon16/comment_edit.png')
	end

	optionsMenu:AddOption('Find...', function()
		self.chatBox:FindText()
	end):SetIcon('icon16/eye.png')

	optionsMenu:AddOption('Clear everything', function()
		self.chatBox:ClearEverything()
	end):SetIcon('icon16/cancel.png')

	optionsMenu:AddSpacer()

	local panelSettings = vgui.Create('DPanel', optionsMenu)
	panelSettings:SetBackgroundColor(Color(0,0,0,200))
	panelSettings:DockPadding(8, -4, -22, 0)

	local slidFontSize = vgui.Create('DNumSlider', panelSettings)
	slidFontSize:Dock(TOP)
	slidFontSize:SetMin(12)
	slidFontSize:SetMax(48)
	slidFontSize:SetDecimals(0)
	slidFontSize:SetDefaultValue(16)
	slidFontSize:SetValue(Settings.font_size)
	slidFontSize:SetText('Font size')
	slidFontSize.Label:SetTextColor(Color(255,255,255))

	slidFontSize.OnValueChanged = function(_, value)
		Settings.font_size = math.floor( math.Clamp(value, 12, 48) )
		self.chatBox:SetFontSize(Settings.font_size)
		Settings:Save()
	end

	panelSettings:SizeToChildren()
	optionsMenu:AddPanel(panelSettings)

	if Settings.allow_any_url then
		optionsMenu:AddOption('Block images from unknown URLs', function()
			Settings:SetWhitelistEnabled(true)
		end):SetIcon('icon16/image_delete.png')
	else
		optionsMenu:AddOption('Allow images from unknown URLs', function()
			Derma_Query([[This option will allow images to be loaded from any URL.
This means no matter which website they came from, you will load it, and it CAN be used to grab your IP address.]],
			'Allow unknown image URLs', 'Allow anyway', function()
				Settings:SetWhitelistEnabled(false)
			end, 'Cancel')
		end):SetIcon('icon16/image_add.png')
	end

	optionsMenu:AddSpacer()

	optionsMenu:AddOption('Customize...', function()
		if self.usingServerTheme then
			Derma_Query('You\'re using a server theme. What to do want to do with it?', 'Customize Theme',
			'Customize it (Your old theme will be lost)', function()
				Theme:Save()
				Theme:ShowCustomizePanel()
				self.usingServerTheme = false
			end,
			'Reset back to my old theme', function()
				Theme:Load()
				self:ApplyTheme(true)

				Theme:ShowCustomizePanel()
				self.usingServerTheme = false
			end,
			'Cancel')
		else
			Theme:ShowCustomizePanel()
		end
	end):SetIcon('icon16/image_edit.png')

	local menuReset, btnReset = optionsMenu:AddSubMenu('Reset...')
	btnReset:SetIcon('icon16/arrow_refresh.png')

	menuReset:AddOption('Position', function()
		Settings:ResetDefaultPosition()
		Settings:Save()

		self.frame:SetPos(Settings:GetDefaultPosition())
	end)

	menuReset:AddOption('Position & Size', function()
		self.frame:SetSize(Settings:GetDefaultSize())

		Settings:ResetDefaultPosition()
		Settings:Save()

		self.frame:SetPos(Settings:GetDefaultPosition())
	end)

	if self:CanSetServerEmojis(LocalPlayer()) then
		optionsMenu:AddOption('[Admin] Custom Emojis...', function()
			Settings:ShowServerEmojisPanel()
		end):SetIcon('icon16/emoticon_tongue.png')
	end

	optionsMenu:Open()
end

function SChat:CreateSidePanel(title, showCloseButton)
	self:CloseExtraPanels()

	local chatX, chatY, chatW, chatH = self.frame:GetBounds()

	chatH = math.Clamp(chatH, 280, 400)

	local pnl = vgui.Create('DFrame')
	pnl:SetSize(250, chatH)
	pnl:SetPos(chatX + chatW + 5, chatY)
	pnl:SetTitle(title)
	pnl:ShowCloseButton(showCloseButton)
	pnl:SetDeleteOnClose(true)
	pnl:MakePopup()

	pnl.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Theme.background)
		draw.RoundedBox(4, 0, 0, w, 25, Color(0, 0, 0, 200))
	end

	pnl.OnKeyCodePressed = function(_, code)
		if code == KEY_ENTER then
			self.entry:OnKeyCodeTyped(KEY_ENTER)
		end
	end

	return pnl
end

function SChat:CloseExtraPanels()
	CloseDermaMenus()

	if IsValid(Theme.customFrame) then
		Theme.customFrame:Close()
	end
end

function SChat:ApplyTheme(invalidate)
	self.frame:DockPadding(Theme.padding, Theme.padding + 24, Theme.padding, Theme.padding)

	self.entry:SetTextColor(Theme.input)
	self.entry:SetCursorColor(Theme.input)
	self.entry:SetHighlightColor(Theme.highlight)
	self.entryDock._backgroundColor = Theme.input_background

	self.chatBox:SetHighlightColor(Theme.highlight)
	self.chatBox:SetBackgroundColor(Theme.input_background)

	if invalidate then
		self.frame:InvalidateChildren(false)
	end
end

function SChat:SetInputEnabled(enable)
	for _, pnl in ipairs( self.frame:GetChildren() ) do
		if pnl == self.chatBox or
			pnl == self.frame.btnMaxim or
			pnl == self.frame.btnClose or
			pnl == self.frame.btnMinim
		then
			continue
		end

		pnl:SetVisible(enable)
	end

	self.chatBox:SetDisplayMode(enable and 'main' or 'temp')
end

function SChat:AppendMessage(contents)
	if not IsValid(self.frame) then
		self:CreatePanels()
	end

	self.chatBox:AppendContents(contents)
end

function SChat:Think()
	if not self.chatBox then return end

	-- Hide the chat box if the game is paused
	if gui.IsGameUIVisible() then
		if self.isOpened then
			chat.Close()
		end

		if not self.isGamePaused then
			self.isGamePaused = true
			self.chatBox:SetVisible(false)
		end
	else
		if self.isGamePaused then
			self.isGamePaused = false
			self.chatBox:SetVisible(true)
		end
	end
end

chat.AddText = function(...)
	SChat:AppendMessage({...})
	chat.DefaultAddText(...)
end

chat.Close = function()
	if not IsValid(SChat.frame) then return end

	SChat:CloseExtraPanels()
	SChat:SetInputEnabled(false)
	SChat.isOpened = false

	SChat.frame:SetMouseInputEnabled(false)
	SChat.frame:SetKeyboardInputEnabled(false)
	SChat.chatBox:ClearSelection()
	SChat.entry:SetText('')

	gui.EnableScreenClicker(false)

	hook.Run('FinishChat')
	hook.Run('ChatTextChanged', '')

	net.Start('schat.istyping', false)
	net.WriteBool(false)
	net.SendToServer()
end

chat.Open = function()
	if not IsValid(SChat.frame) then
		SChat:CreatePanels()
	end

	-- Update the 'Say' label and the color of the text entry 
	if SChat.teamMode == true then
		local teamColor = team.GetColor(LocalPlayer():Team())

		teamColor.r = teamColor.r * 0.3
		teamColor.g = teamColor.g * 0.3
		teamColor.b = teamColor.b * 0.3
		teamColor.a = Theme.input_background.a

		SChat.entryDock._backgroundColor = teamColor
		SChat.entry:SetPlaceholderText('Say (TEAM)...')
	else
		SChat.entryDock._backgroundColor = Theme.input_background
		SChat.entry:SetPlaceholderText('Say...')
	end

	SChat.isOpened = true
	SChat:SetInputEnabled(true)

	-- MakePopup calls the input functions so we dont need to call those
	-- (refering to SetMouseInputEnabled/SetKeyboardInputEnabled)
	SChat.frame:MakePopup()
	SChat.entry:RequestFocus()
	SChat.chatBox:ScrollToBottom()

	-- Make sure other addons know we are chatting
	hook.Run('StartChat')

	net.Start('schat.istyping', false)
	net.WriteBool(true)
	net.SendToServer()
end

hook.Add('ChatText', 'schat_ChatText', function(_, _, text, textType)
	if textType ~= 'chat' then
		SChat:AppendMessage({Color(0, 128, 255), text})
		return true
	end
end)

hook.Add('PlayerBindPress', 'schat_PlayerBindPress', function(_, bind, _)
	if bind ~= 'messagemode' and bind ~= 'messagemode2' then return end

	-- Dont open the chat if Starfall is blocking input
	local existingBindHooks = hook.GetTable()['PlayerBindPress']
	if existingBindHooks['sf_keyboard_blockinput'] then return end

	-- Dont open if anything else blocks input
	local block = hook.Run('SChat_BlockChatInput')
	if block == true then return end

	SChat.teamMode = (bind == 'messagemode2')
	chat.Open()

	return true
end)

hook.Add('HUDShouldDraw', 'schat_HUDShouldDraw', function(name)
	if name == 'CHudChat' then return false end
end)

hook.Add('Think', 'schat_Think', function()
	SChat:Think()
end)

-- Custom 'IsTyping' behavior
local PLY = FindMetaTable('Player')

PLY.DefaultIsTyping = PLY.DefaultIsTyping or PLY.IsTyping

function PLY:IsTyping()
	return self:GetNWBool('IsTyping', false)
end

-- Receive server theme & emojis

net.Receive('schat.set_theme', function()
	SChat.serverTheme = net.ReadString()

	if IsValid(SChat.frame) then
		SChat:SuggestServerTheme()
	end
end)

net.Receive('schat.set_emojis', function()
	Settings:ClearCustomEmojis()
	SChat.PrintF('Received emojis from the server.')

	local data = net.ReadString()
	if data ~= '' then
		data = util.JSONToTable(data)

		if data then
			for _, v in ipairs(data) do
				Settings:AddOnlineEmoji(v[1], v[2])
			end
		else
			SChat.PrintF('Failed to parse emojis from the server!')
		end
	end

	if IsValid(SChat.chatBox) then
		SChat.chatBox:UpdateEmojiPanel()
	end
end)