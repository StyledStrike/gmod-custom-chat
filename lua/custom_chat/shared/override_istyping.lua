-- Restore the "hands on the ear"
-- behaviour from the default chat.
local PLAYER = FindMetaTable( "Player" )

PLAYER.DefaultIsTyping = PLAYER.DefaultIsTyping or PLAYER.IsTyping

function PLAYER:IsTyping()
    return self:GetNWBool( "IsTyping", false )
end

if SERVER then
    util.AddNetworkString( "customchat.is_typing" )

    net.Receive( "customchat.is_typing", function( _, ply )
        ply:SetNWBool( "IsTyping", net.ReadBool() )
    end )
end
