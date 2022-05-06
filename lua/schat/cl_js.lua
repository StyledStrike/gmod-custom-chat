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
	color_code_background = Color(30, 30, 30, 255)
}

-- used to test if a URL probably points to a image
local imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'}

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

		if urlType == 'image' and SChat:IsWhitelisted(val) then
			return JSBuilder:CreateImage(val, val, nil, val)
		end

		local ytVideoId = string.match(val, 'youtube.com/watch%?v=(.+)')

		if not ytVideoId then
			ytVideoId = string.match(val, 'youtu.be/(.+)')
		end

		if ytVideoId and #ytVideoId == 11 then
			return JSBuilder:CreateEmbedLink('https://img.youtube.com/vi/' .. ytVideoId .. '/hqdefault.jpg',
				'Youtube URL', val)
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

	['code'] = function(val, color, font)
		val = string.Replace(val, '\\n', '\n')
		local trimAmount = val[1] == '{' and 3 or 4
		return JSBuilder:CreateText(str_trim_ends(val, trimAmount), font, nil, color, nil, 'code')
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

-- generates JS code that creates a element using the provided properties
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

-- generates code to create a text element
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

-- generates code to create a image
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

-- generates a embed link box (with a title and thumbnail)
function JSBuilder:CreateEmbedLink(iconUrl, title, link)
	local props = {className = {value = 'embed'}}

	props['onclick'] = {
		type = 'function',
		value = 'SChatBox.OnClickLink("' .. str_jssafe(link) .. '")'
	}

	local strTbl = {
		self:CreateElement('span', 'elm', self.rootMessageElement, props),
		self:CreateElement('img', 'elmIcon', 'elm',	{src			= {value = iconUrl} }),
		self:CreateElement('h3', 'elmTitle', 'elm',	{textContent	= {value = title}	}),
		self:CreateElement('p', 'elmLink', 'elm',	{textContent	= {value = link}	})
	}

	return table.concat(strTbl, '\n')
end

-- generates a marquee-like animated text (moving right to left) 
function JSBuilder:CreateAdvert(text, color)
	return table.concat({
		self:CreateElement('span', 'elm', self.rootMessageElement, {className = {value = 'advert'}}),
		self:CreateElement('p', 'elmText', 'elm', {
			textContent = {value = str_jssafe(text)},
			['style.color'] = {value = color_to_rgb(color)}
		})
	}, '\n')
end

-- Builds a JS code that creates a message element based on 'contents'.
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

	jsLines[#jsLines + 1] = 'appendMessageBlock(' .. JSBuilder.rootMessageElement .. ');'

	return table.concat(jsLines, '\n')
end

-- Builds a JS code that elements for the emoji panel.
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