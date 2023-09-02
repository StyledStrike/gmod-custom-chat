-- lets restore the "hands on the ear"
-- behaviour from the default chat.
local PLAYER = FindMetaTable( "Player" )

PLAYER.DefaultIsTyping = PLAYER.DefaultIsTyping or PLAYER.IsTyping

function PLAYER:IsTyping()
    return self:GetNWBool( "IsTyping", false )
end

if SERVER then
    net.Receive( "schat.is_typing", function( _, ply )
        ply:SetNWBool( "IsTyping", net.ReadBool() )
    end )
end
