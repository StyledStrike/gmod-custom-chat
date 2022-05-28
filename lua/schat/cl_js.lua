local table_insert = table.insert
local str_format = string.format
local str_jssafe = string.JavascriptSafe
local str_is_valid = function(s) return s ~= nil and s ~= '' end
local str_trim_ends = function(s, n) return string.sub(s, n, -n) end
local color_to_rgb = function(c) return str_format('rgb(%d,%d,%d)', c.r, c.g, c.b) end

--[[
	Generates JS code that creates elements based on 'blocks'
]]

local JSBuilder = {
	-- the main element that represents a single message
	rootMessageElement = 'msgElm',

	color_white = Color(255, 255, 255, 255),
	color_code_background = Color(47, 49, 54, 255)
}

-- used to test if a URL probably points to a image
local imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'}

-- used to test if a URL probably points to a sound
local audioExtensions = {'wav', 'ogg', 'mp3'}

local imagePatterns = {
	'^asset://[^%s%\'%>%<]+',
	'^https?://steamuserimages%-a%.akamaihd%.net/ugc/'
}

local function getURLType(url)
	for _, patt in ipairs(imagePatterns) do
		if url:match(patt) then
			return 'image'
		end
	end

	local withoutQueryStrings = url:gsub('%?[^/]+', ''):lower()

	for _, ext in ipairs(imageExtensions) do
		if withoutQueryStrings:EndsWith(ext) then
			return 'image'
		end
	end

	for _, ext in ipairs(audioExtensions) do
		if withoutQueryStrings:EndsWith(ext) then
			return 'audio'
		end
	end

	return 'url'
end

local templates = {
	['string'] = function(val, color, font)
		return JSBuilder:CreateText(val, font, nil, color)
	end,

	['emoji'] = function(val, color, font)
		local path, isOnline = SChat.Settings:GetEmojiInfo( val:sub(2, -2) )

		if path then
			if not isOnline then
				path = 'asset://garrysmod/' .. path
			end

			return JSBuilder:CreateImage(path, nil, 'emoji', val)
		end

		return JSBuilder:CreateText(val, font, nil, color)
	end,

	['model'] = function(val, color, font)
		local js = ''
		local prevPath = 'materials/spawnicons/' .. string.Replace(val, '.mdl', '.png')

		if file.Exists(prevPath, 'GAME') then
			js = JSBuilder:CreateImage('asset://garrysmod/' .. prevPath, nil, 'emoji')
		end

		return js .. JSBuilder:CreateText(val, font, nil, color)
	end,

	['profanity'] = function()
		return JSBuilder:CreateText('<redacted>', nil, nil, nil, JSBuilder.color_code_background)
	end,

	['url'] = function(val, _, font)
		local urlType = getURLType(val)

		if SChat:IsWhitelisted(val) then
			if urlType == 'image' then
				return JSBuilder:CreateImage(val, val, nil, val)

			elseif urlType == 'audio' and SChat.chatBox then
				return JSBuilder:CreateAudioPlayer(val, font)

			else
				return JSBuilder:CreateEmbed(val)
			end
		end

		return JSBuilder:CreateText(val, font, val)
	end,

	['spoiler'] = function(val, _, font)
		return JSBuilder:CreateText(str_trim_ends(val, 3), font, nil, nil, nil, 'spoiler')
	end,

	['italic'] = function(val, color, font)
		return JSBuilder:CreateText(str_trim_ends(val, 2), font, nil, color, nil, 'i-text')
	end,

	['bold'] = function(val, color, font)
		return JSBuilder:CreateText(str_trim_ends(val, 3), font, nil, color, nil, 'b-text')
	end,

	['bold_italic'] = function(val, color, font)
		return JSBuilder:CreateText(str_trim_ends(val, 4), font, nil, color, nil, 'b-text i-text')
	end,

	['code_line'] = function(val, color, font)
		return JSBuilder:CreateCode(str_trim_ends(val, 2), font, true)
	end,

	['code'] = function(val, color, font)
		val = string.Replace(val, '\\n', '\n')
		local trimAmount = val[1] == '{' and 3 or 4
		return JSBuilder:CreateCode(str_trim_ends(val, trimAmount), font, false)
	end,

	['rainbow'] = function(val, color, font)
		return JSBuilder:CreateText(str_trim_ends(val, 3), font, nil, nil, nil, 'tef-rainbow')
	end,

	['advert'] = function(val, color)
		return JSBuilder:CreateAdvert(str_trim_ends(val, 3), color)
	end
}

-- used by users to change the text font at any point
local fontNames = {
	['monospace'] = 'monospace',
	['lucida'] = 'Lucida Console',
	['comic'] = 'Comic Sans MS',
	['arial'] = 'Arial',
	['calibri'] = 'Calibri',
	['consolas'] = 'Consolas',
	['impact'] = 'Impact',
	['symbol'] = 'Symbol',
	['helvetica'] = 'Helvetica Neue',
	['sugoe'] = 'Sugoe Script',
	['roboto'] = 'Roboto'
}

-- Received a response from our metadata fetcher
function JSBuilder:OnHTTPResponse(embedId, body, url)
	local metaTags = {}
	local metaPatt = '<meta[%g%s]->'

	for s in string.gmatch(body, metaPatt) do
		metaTags[#metaTags + 1] = s
	end

	if #metaTags == 0 then return end

	local props = {}

	for _, meta in ipairs(metaTags) do
		-- try to find any content on this meta tag
		local _, _, content = string.find(meta, 'content="([%g%s]-)"')

		-- try to find the meta tag name for Facebook
		local _, _, name = string.find(meta, 'property="og:([%g]-)"')

		-- try to find the meta tag name for Twitter
		if not name then
			_, _, name = string.find(meta, 'name="twitter:([%g]-)"')
		end

		if name and content then
			props[name] = content
		end
	end

	local _, site = string.match(url, '^(%w-)://([^/]*)/?')

	local jsTbl = {[[var embeds = document.getElementsByClassName("]] .. embedId .. [[");

		for (var i = 0; i < embeds.length; i++) {
			var elm = embeds[i];
			elm.textContent = "";
			elm.className = "embed ]] .. embedId .. [[";]]}

	if props['image'] then
		jsTbl[#jsTbl + 1] = self:CreateElement('img', 'elmImg', 'elm', {
			className = { value = 'embed-thumb' },
			src = { value = str_jssafe(props['image']) }
		})
	end

	jsTbl[#jsTbl + 1] = self:CreateElement('section', 'elmEmbedBody', 'elm', {
		className = { value = 'embed-body' }
	})

	if props['site_name'] then
		jsTbl[#jsTbl + 1] = self:CreateElement('h1', 'elmName', 'elmEmbedBody', {
			textContent = { value = str_jssafe(props['site_name']) }
		})
	end

	local title = props['title'] or site

	if title:len() > 50 then
		title = title:Left(47) .. '...'
	end

	jsTbl[#jsTbl + 1] = self:CreateElement('h2', 'elmTitle', 'elmEmbedBody', {
		textContent = { value = str_jssafe(title) }
	})

	local desc = props['description'] or url

	if desc:len() > 100 then
		desc = desc:Left(97) .. '...'
	end

	jsTbl[#jsTbl + 1] = self:CreateElement('i', 'elmDesc', 'elmEmbedBody', {
		textContent = { value = str_jssafe(desc) }
	})

	jsTbl[#jsTbl + 1] = '}'

	SChat.chatBox:QueueJavascript( table.concat(jsTbl, '\n') )
end

-- Generates JS code that creates a element using the provided properties
function JSBuilder:CreateElement(tag, var, parentVar, props)
	local strTbl = {
		str_format('var %s = document.createElement("%s");', var, tag),
		str_format('%s.appendChild(%s);', parentVar, var)
	}

	for name, p in pairs(props) do
		if p.type == 'raw' then
			table_insert(strTbl, str_format('%s.%s = %s;', var, name, p.value))
		elseif p.type == 'function' then
			table_insert(strTbl, str_format('%s.%s = function(){ %s };', var, name, p.value))
		else
			table_insert(strTbl, str_format('%s.%s = "%s";', var, name, p.value))
		end
	end

	return table.concat(strTbl, '\n')
end

-- Generates JS code to create a text element
-- (optionally, it can act as a clickable link)
function JSBuilder:CreateText(text, font, link, color, bgColor, cssClass)
	local props = {textContent = {value = str_jssafe(text)}}

	if str_is_valid(font) then
		props['style.fontFamily'] = {value = font}
	end

	if str_is_valid(link) then
		color = Color(50, 100, 255)

		props['onclick'] = {
			type = 'function',
			value = 'SChatBox.OnClickLink("' .. str_jssafe(link) .. '")'
		}

		props['clickableText'] = {type = 'raw', value = 'true'}
		props['style.cursor'] = {value = 'pointer'}
		props['style.wordBreak'] = {value = 'break-all'}
	end

	if cssClass then
		props['className'] = {value = cssClass}
	end

	if color and color ~= self.color_white then
		props['style.color'] = {value = color_to_rgb(color)}
	end

	if bgColor then
		props['style.backgroundColor'] = {value = color_to_rgb(bgColor)}
	end

	return self:CreateElement('span', 'elm', self.rootMessageElement, props)
end

-- Generates JS code to create a block of code
function JSBuilder:CreateCode(code, font, inline)
	local parentProps = {
		['className'] = {
			value = inline and 'code-line' or 'code'
		},
		['style.backgroundColor'] = {
			value = color_to_rgb(JSBuilder.color_code_background)
		}
	}

	font = Either(str_is_valid(font), font, 'monospace');

	local elements = {
		-- create a parent element that will hold other elements
		self:CreateElement('span', 'elm', self.rootMessageElement, parentProps)
	}

	-- then "highlight" the code, creating child elements for each token
	local tokens = SChat:GenerateHighlightTokens(code)

	for _, t in ipairs(tokens) do
		elements[#elements + 1] = self:CreateElement('span', 'elmText', 'elm', {
			['textContent'] = { value = str_jssafe(t.value) },
			['style.color'] = { value = t.color },
			['style.fontFamily'] = {value = font}
		})
	end

	return table.concat(elements, '\n')
end

-- Generates JS code to create a image
-- (optionally, it can act as a clickable link)
function JSBuilder:CreateImage(url, link, cssClass, altText)
	local props = { src = { value = str_jssafe(url) } }

	if link then
		link = str_jssafe(link)

		props['onclick'] = {
			type = 'function',
			value = 'SChatBox.OnClickLink("' .. link .. '")'
		}

		props['onmouseenter'] = {
			type = 'function',
			value = 'SChatBox.OnImageHover("' .. link .. '", true)'
		}

		props['onmouseleave'] = {
			type = 'function',
			value = 'SChatBox.OnImageHover("' .. link .. '", false)'
		}
	end

	if cssClass then
		props['className'] = {value = cssClass}
	end

	if altText then
		props['alt'] = {value = altText}
	end

	return self:CreateElement('img', 'elm', self.rootMessageElement, props)
end

-- Generates a embed box (with a title and thumbnail)
function JSBuilder:CreateEmbed(url)
	self.lastEmbedId = (self.lastEmbedId or 0) + 1

	local embedId = 'embed_' .. self.lastEmbedId

	HTTP({
		url = url,
		method = 'GET',

		success = function(code, body)
			code = tostring(code)

			if code == '204' or code:sub(1,1) ~= '2' then
				return
			end

			self:OnHTTPResponse(embedId, body, url)
		end
	})

	local props = {
		className = { value = embedId .. ' link' },
		textContent = { value = url },
		onclick = {
			type = 'function',
			value = 'SChatBox.OnClickLink("' .. str_jssafe(url) .. '")'
		}
	}

	return self:CreateElement('p', 'elm', self.rootMessageElement, props)
end

-- Generates a marquee-like animated text (moving right to left) 
function JSBuilder:CreateAdvert(text, color)
	return table.concat({
		self:CreateElement('span', 'elm', self.rootMessageElement, {className = {value = 'advert'}}),
		self:CreateElement('p', 'elmText', 'elm', {
			textContent = {value = str_jssafe(text)},
			['style.color'] = {value = color_to_rgb(color)}
		})
	}, '\n')
end

-- Generates JS code to create a audio player.
-- To prevent lag/crashes, only allow the existance of one at a time.
function JSBuilder:CreateAudioPlayer(url, font)
	url = str_jssafe(url)

	local jsTbl = {
		JSBuilder:CreateText(url, font, url), [[
		var media = document.getElementsByClassName("media-player");

		for (var i = 0; i < media.length; i++) {
			var parent = media[i].parentElement;
			parent.removeChild(media[i]);
		}
	]]}

	local props = {
		src = { value = url },
		className = { value = 'media-player' },
		volume = { type = 'raw', value = '0.5' }
	}

	jsTbl[#jsTbl + 1] = self:CreateElement('audio', 'elm', self.rootMessageElement, props)
	jsTbl[#jsTbl + 1] = 'elm.setAttribute("preload", "none");'
	jsTbl[#jsTbl + 1] = 'elm.setAttribute("controls", "controls");'
	jsTbl[#jsTbl + 1] = 'elm.setAttribute("controlsList", "nodownload noremoteplayback");'

	return table.concat(jsTbl, '\n')
end

-- Generates JS code that creates a message element based on 'contents'.
-- 'contents' must be a sequential table.
function SChat:GenerateMessageFromTable(contents)
	-- first, convert the contents into blocks
	local blocks = {}

	local function addBlock(type, value)
		blocks[#blocks + 1] = {
			type = type,
			value = value
		}
	end

	for _, obj in ipairs(contents) do
		if type(obj) == 'table' then
			if obj.r and obj.g and obj.b then
				addBlock('color', obj)
			else
				addBlock('string', tostring(obj))
			end

		elseif type(obj) == 'string' then
			-- if obj is a string, find more blocks using patterns
			SChat:ParseString(obj, addBlock)

		elseif type(obj) == 'Player' and IsValid(obj) then
			local nameColor = team.GetColor(obj:Team())

			-- aTags support
			if obj.getChatTag then
				_, _, nameColor = obj:getChatTag()
			end

			addBlock('color', nameColor)
			addBlock('string', obj:Nick())
		else
			addBlock('string', tostring(obj))
		end
	end

	-- then, convert the blocks into JS code that creates elements
	local jsLines = {'var ' .. JSBuilder.rootMessageElement .. ' = document.createElement("div");'}
	local color = color_white
	local font = ''

	for _, b in ipairs(blocks) do
		if b.type == 'font' then
			local newFont = str_trim_ends(b.value, 2)
			if fontNames[newFont] then
				font = fontNames[newFont]
			end

		elseif b.type == 'color' then
			color = b.value
		else
			local templateFunc = templates[b.type]
			if templateFunc then
				jsLines[#jsLines + 1] = templateFunc(b.value, color, font)
			else
				SChat.PrintF('Invalid chat block type: %s', b.type)
			end
		end
	end

	local showTemporary = (GetConVar('cl_drawhud'):GetInt() == 0) and 'false' or 'true'
	jsLines[#jsLines + 1] = 'appendMessageBlock(' .. JSBuilder.rootMessageElement .. ',' .. showTemporary .. ');'

	return table.concat(jsLines, '\n')
end

-- Generates JS code that populates the emoji panel.
function SChat:GenerateEmojiList()
	local emojiCategories = self.Settings.emojiCategories
	local jsTbl = {'elmEmojiPanel.textContent = "";'}

	for _, cat in ipairs(emojiCategories) do
		if #cat.emojis == 0 then continue end

		jsTbl[#jsTbl + 1] = 'var emojiCat = document.createElement("div");'
		jsTbl[#jsTbl + 1] = 'emojiCat.className = "emoji-category";'
		jsTbl[#jsTbl + 1] = 'emojiCat.textContent = "' .. cat.category .. '";'
		jsTbl[#jsTbl + 1] = 'elmEmojiPanel.appendChild(emojiCat);'

		for _, v in ipairs(cat.emojis) do
			local emojiID

			jsTbl[#jsTbl + 1] = 'var emojiElm = document.createElement("img");'

			if type(v) == 'string' then
				emojiID = v
				jsTbl[#jsTbl + 1] = 'emojiElm.src = "' .. str_jssafe('asset://garrysmod/materials/icon72/' .. v .. '.png') .. '";'
			else
				emojiID = v[1]
				jsTbl[#jsTbl + 1] = 'emojiElm.src = "' .. str_jssafe(v[2]) .. '";'
			end

			jsTbl[#jsTbl + 1] = 'emojiElm.className = "emoji-button";'
			jsTbl[#jsTbl + 1] = 'emojiElm.onclick = function(){'
			jsTbl[#jsTbl + 1] = 'SChatBox.OnSelectEmoji("' .. emojiID .. '")};'
			jsTbl[#jsTbl + 1] = 'elmEmojiPanel.appendChild(emojiElm);'
		end
	end

	return table.concat(jsTbl, '\n')
end