--[[
	SChat by StyledStrike
]]
resource.AddWorkshop('2799307109')

util.AddNetworkString('schat.istyping')
util.AddNetworkString('schat.set_theme')
util.AddNetworkString('schat.set_emojis')

-- lets restore the "hands on the ear"
-- behaviour from the default chat.
local PLY = FindMetaTable('Player')

PLY.DefaultIsTyping = PLY.DefaultIsTyping or PLY.IsTyping

function PLY:IsTyping()
	return self:GetNWBool('IsTyping', false)
end

net.Receive('schat.istyping', function(_, ply)
	ply:SetNWBool('IsTyping', net.ReadBool())
end)

-- server settings
local Settings = {
	themeFilePath = 'schat_server_theme.json',
	emojiFilePath = 'schat_server_emojis.json',

	themeData = {},
	emojiData = {}
}

function Settings:Serialize(tbl)
	return util.TableToJSON(tbl)
end

function Settings:Unserialize(str)
	if not str or str == '' then
		return {}
	end

	return util.JSONToTable(str) or {}
end

function Settings:Load()
	-- load an existing server theme
	self.themeData = self:Unserialize( file.Read(self.themeFilePath, 'DATA') )

	-- load existing server emojis
	self.emojiData = self:Unserialize( file.Read(self.emojiFilePath, 'DATA') )
end

function Settings:Save()
	file.Write(self.themeFilePath, self:Serialize(self.themeData))
	file.Write(self.emojiFilePath, self:Serialize(self.emojiData))
end

function Settings:ShareTheme(ply)
	if game.SinglePlayer() then return end

	net.Start('schat.set_theme', false)
	net.WriteString( self:Serialize(self.themeData) )

	if IsValid(ply) then
		net.Send(ply)
		SChat.PrintF('Sent theme data to %s', ply:Nick())
	else
		net.Broadcast()
	end
end

function Settings:ShareEmojis(ply)
	net.Start('schat.set_emojis', false)
	net.WriteString( self:Serialize(self.emojiData) )

	if IsValid(ply) then
		net.Send(ply)
		SChat.PrintF('Sent emoji data to %s', ply:Nick())
	else
		net.Broadcast()
	end
end

function Settings:SetTheme(data, admin)
	SChat.PrintF('%s %s the server theme.', admin or 'Someone', table.IsEmpty(data) and 'removed' or 'changed')

	self.themeData = data
	self:ShareTheme()
	self:Save()
end

function Settings:SetEmojis(data, admin)
	SChat.PrintF('%s %s the server emojis.', admin or 'Someone', table.IsEmpty(data) and 'removed' or 'changed')

	self.emojiData = data
	self:ShareEmojis()
	self:Save()
end

net.Receive('schat.set_theme', function(_, ply)
	if SChat:CanSetServerTheme(ply) then
		local themeData = Settings:Unserialize(net.ReadString())
		Settings:SetTheme(themeData, ply:Nick())
	else
		ply:ChatPrint('SChat: You cannot change server themes.')
	end
end)

net.Receive('schat.set_emojis', function(_, ply)
	if SChat:CanSetServerEmojis(ply) then
		local emojiData = Settings:Unserialize(net.ReadString())
		Settings:SetEmojis(emojiData, ply:Nick())
	else
		ply:ChatPrint('SChat: You cannot change server emojis.')
	end
end)

-- the sheer amount of workarounds down here...

-- since PlayerInitialSpawn is called BEFORE the player is ready
-- to receive net events, we have to use ClientSignOnStateChanged
hook.Add('ClientSignOnStateChanged', 'schat_ClientStateChanged', function(user, old, new)
	if new == SIGNONSTATE_FULL then
		-- since we can only retrieve the player entity
		-- after this hook runs, lets use a timer
		timer.Simple(0, function(arguments)
			local ply = Player(user)
			if not IsValid(ply) then return end

			-- send the server theme (if set)
			if not table.IsEmpty(Settings.themeData) then
				Settings:ShareTheme(ply)
			end

			-- send the server emojis (if set)
			if not table.IsEmpty(Settings.emojiData) then
				Settings:ShareEmojis(ply)
			end
		end)
	end
end)

Settings:Load()

SChat.Settings = Settings