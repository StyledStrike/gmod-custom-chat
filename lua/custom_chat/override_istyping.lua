-- Restore the "hands on the ear"
-- behaviour from the default chat.
local PLAYER = FindMetaTable( "Player" )

PLAYER.DefaultIsTyping = PLAYER.DefaultIsTyping or PLAYER.IsTyping

function PLAYER:IsTyping()
    return self:GetNWBool( "IsTyping", false ) or self:DefaultIsTyping()
end

if SERVER then
    util.AddNetworkString( "customchat.is_typing" )

    net.Receive( "customchat.is_typing", function( _, ply )
        ply:SetNWBool( "IsTyping", net.ReadBool() )
    end )
end

if CLIENT then
    function CustomChat.SetTyping( isTyping )
        net.Start( "customchat.is_typing", false )
        net.WriteBool( isTyping )
        net.SendToServer()
    end
end
