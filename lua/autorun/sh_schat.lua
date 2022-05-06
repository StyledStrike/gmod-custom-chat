SChat = {}

-- You can override the 'CanSet' functions if you want.
-- Just make sure to do it both on SERVER and CLIENT

function SChat:CanSetServerTheme(ply)
	return ply:IsSuperAdmin()
end

function SChat:CanSetServerEmojis(ply)
	return ply:IsSuperAdmin()
end

function SChat.PrintF(str, ...)
	MsgC(Color(0, 123, 255), '[Custom Chat] ', Color(255,255,255), string.format(str, ...), '\n')
end

if SERVER then
	include('schat/sv_main.lua')

	AddCSLuaFile('schat/cl_js.lua')
	AddCSLuaFile('schat/cl_parser.lua')
	AddCSLuaFile('schat/cl_settings.lua')
	AddCSLuaFile('schat/cl_theme.lua')
	AddCSLuaFile('schat/cl_whitelist.lua')
	AddCSLuaFile('schat/cl_chatbox.lua')
	AddCSLuaFile('schat/cl_interface.lua')
end

if CLIENT then
	function SChat.InternalMessage(source, text)
		chat.AddText(color_white, '[', Color(80,165,204), source, color_white, '] ', text)
	end

	include('schat/cl_js.lua')
	include('schat/cl_parser.lua')
	include('schat/cl_settings.lua')
	include('schat/cl_theme.lua')
	include('schat/cl_whitelist.lua')
	include('schat/cl_chatbox.lua')
	include('schat/cl_interface.lua')
end