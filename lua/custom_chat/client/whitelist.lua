--[[
    Whitelist code from thegrb93/StarfallEx

    You can ask to add more URLs here:
    https://steamcommunity.com/workshop/filedetails/discussion/2799307109/3272437487156558008/
]]

local function pattern( str ) return "^" .. str .. "$" end
local function simple( str ) return "^" .. string.PatternSafe( str ) .. "/.*" end

local whitelist = {
    -- Dropbox
    pattern [[%w+%.dl%.dropboxusercontent%.com/(.+)]],
    simple [[dl.dropboxusercontent.com]],
    simple [[dl.dropbox.com]],
    simple [[www.dropbox.com]],

    -- Onedrive
    simple [[onedrive.live.com/redir]],

    -- Google
    simple [[google.com]],
    simple [[www.google.com]],

    -- Google Drive
    pattern [[docs%.google%.com/uc.+]],
    pattern [[drive%.google%.com/uc.+]],

    -- Backblaze B2 (ShareX)
    pattern [[(%w+)%.backblazeb2%.com/(.+)]],

    -- Imgur
    simple [[i.imgur.com]],

    -- Gitlab
    simple [[gitlab.com]],

    -- bitbucket
    simple [[bitbucket.org]],

    -- Github
    simple [[github.com]],
    simple [[raw.githubusercontent.com]],
    simple [[gist.githubusercontent.com]],
    simple [[cloud.githubusercontent.com]],
    simple [[user-images.githubusercontent.com]],
    pattern [[avatars(%d*)%.githubusercontent%.com/(.+)]],

    -- teknik
    simple [[u.teknik.io]],
    simple [[p.teknik.io]],

    -- TinyPic
    pattern [[i([%w-_]+)%.tinypic%.com/(.+)]],

    -- puush
    simple [[puu.sh]],

    -- Steam
    pattern [[([%w-_%.]*)%.steamstatic.com/(.+)]],
    pattern [[images%.[%w-_]+%.steamusercontent%.com/(.+)]],
    pattern [[avatars%.[%w-_]+%.steamstatic%.com/(.+)]],
    simple [[images.akamai.steamusercontent.com]],
    simple [[steamuserimages-a.akamaihd.net]],
    simple [[steamcdn-a.akamaihd.net]],
    simple [[steamcommunity.com]],

    -- Discord
    pattern [[cdn[%w-_]*.discordapp%.com/(.+)]],
    pattern [[images-([%w%-]+)%.discordapp%.net/external/(.+)]],
    pattern [[media(%d*)%.discordapp%.net/.+]],

    -- Reddit
    simple [[i.redditmedia.com]],
    simple [[i.redd.it]],
    simple [[preview.redd.it]],

    -- ipfs
    simple [[ipfs.io]],

    -- Soundcloud
    pattern [[(%w+)%.sndcdn%.com/(.+)]],

    -- Youtube Image Hosting
    simple [[i.ytimg.com]],

    -- Spotify Image CDN
    simple [[i.scdn.co]],

    -- Deezer Image CDN
    pattern [[([%w-_]+)%.dzcdn%.net/(.+)]],

    -- emoji.gg
    simple [[emoji.gg]],
    pattern [[([%w-_]+)%.emoji%.gg/(.+)]],

    -- Tenor
    simple [[tenor.com]],
    pattern [[[%w-_]-%.tenor%.com/.+]],

    -- Youtube
    simple [[youtu.be]],
    pattern [[([%w-_]+)%.youtube%.com/(.+)]],

    -- Pinterest
    simple [[i.pinimg.com]],

    -- ImgBB
    simple [[i.ibb.co]],

    -- Stack Overflow
    pattern [[([%w-_]*)([%.]-)stackoverflow%.com/(.+)]],

    -- Bandcamp
    pattern [[([%w-_]+)%.bandcamp%.com/(.+)]],

    -- Twitter
    simple [[twitter.com]],
    simple [[fxtwitter.com]],
    simple [[x.com]],

    -- Deviant Art
    pattern [[([%w-_]+)%.deviantart%.com/(.+)]],

    -- Soundcloud
    simple [[soundcloud.com]],

    -- Twitch
    pattern [[([%w-_]*)([%.]-)twitch%.tv/(.+)]],

    -- Facepunch
    pattern [[([%w-_]+)%.facepunch%.com/(.+)]],

    -- Revolt
    simple [[static.revolt.chat]],
    simple [[autumn.revolt.chat]],

    -- Catbox
    simple [[files.catbox.moe]],
}

function CustomChat.IsWhitelisted( url )
    if CustomChat.Config.allowAnyURL then
        return true
    end

    if url:sub( 1, 8 ) == "asset://" then
        return true
    end

    local prefix, site, data = string.match( url, "^(%w-)://([^/]*)/?(.*)" )

    if not prefix or not site then
        CustomChat.Print( "Malformed URL: %s", url )
        return false
    end

    site = site .. "/" .. ( data or "" )

    for _, patt in ipairs( whitelist ) do
        if site:match( patt ) then
            return true
        end
    end

    return false
end
