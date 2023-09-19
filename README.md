# Custom Chat

A simple and customizable chat box that can format text, display images and emojis.

[![GLuaLint](https://github.com/StyledStrike/gmod-custom-chat/actions/workflows/glualint.yml/badge.svg)](https://github.com/FPtje/GLuaFixer)
[![Workshop Page](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-steam-workshop.jross.me%2F2799307109%2Fsubscriptions-text)](https://steamcommunity.com/sharedfiles/filedetails/?id=2799307109)

### Features

* Customizable
* Has built-in emojis
* Supports text formatting (bold, italic, fonts, code blocks, etc.)
* Embed image/audio files (Only loads from trusted websites by default)
* Find text with _Ctrl+F_
* Shows icons for prop models
* Keeps the default "hands on ear when the chat is open" behaviour
* Can be enabled/disabled at any time *(Using the `customchat_disable` console variable)*
* _(Admin Only)_ Suggest a theme to be used on your server
* _(Admin Only)_ Set custom emojis
* _(Admin Only)_ Set custom chat tags
* _(Admin Only)_ Set custom join/leave messages

---

### Text Formatting Options

```
||Spoilers here||
*Italic text here*
**Bold text here**
***Bold & Italic text here***
$$rainbow text here$$
`line of code here`
{{block of code here}}
```block of code here```
[[Marquee-like advert here]]
[Link text Here](https://link-url-here.org)
<255,0,0>Red text here, and <0,0,255>blue text here
```

---

### Fonts

You can change the font by typing **;fontname;** before the text.
_(A list of fonts can be found on the workshop page.)_

```;comic; This will be displayed as Comic Sans```

---

### Whitelisted Sites

By default, the chat box will only load pictures from trusted websites. You can open a pull request to add more, or send a request [here](https://steamcommunity.com/workshop/filedetails/discussion/2799307109/3272437487156558008/).

### For developers

You can prevent links from certain players from embedding, by using the `CanEmbedCustomChat` hook on the **clientside**.

```lua
hook.Add( "CanEmbedCustomChat", "override_chat_embed_access", function( ply, url, urlType )
    -- return false to block embeds from "url"

    -- "urlType" will be one of these strings:
    -- "image", "audio", and "url" for other stuff

    -- example: only allow super admins to use embeds
    if not ply:IsSuperAdmin() then return false end

    -- example: prevent audio from embedding for everyone
    if urlType == "audio" then return false end
end )
```
