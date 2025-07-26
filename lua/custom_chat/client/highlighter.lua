--[[
    Very basic and generalized syntax highlighter.

    Only deals with (, ), {, }, [, ], strings, numbers and a few 
    keywords that may exist in many languages (especially SF/E2/Lua).
]]

local punctuation = {
    ["["] = "bracket",
    ["]"] = "bracket",
    ["{"] = "bracket",
    ["}"] = "bracket",
    ["("] = "bracket",
    [")"] = "bracket"
}

local groups = {
    ["\""] = "string",
    ["'"] = "string"
}

local keywords = {
    ["if"] = "keyword",
    ["then"] = "keyword",
    ["elseif"] = "keyword",
    ["else"] = "keyword",
    ["do"] = "keyword",
    ["end"] = "keyword",
    ["local"] = "keyword",
    ["var"] = "keyword",
    ["const"] = "keyword",
    ["for"] = "keyword",
    ["while"] = "keyword",
    ["repeat"] = "keyword",
    ["until"] = "keyword",
    ["continue"] = "keyword",
    ["function"] = "keyword",
    ["return"] = "keyword",
    ["and"] = "keyword",
    ["or"] = "keyword",

    ["print"] = "func",
    ["Vector"] = "func",
    ["Angle"] = "func",
    ["Color"] = "func",
    ["vec"] = "func",
    ["vec2"] = "func",
    ["vec4"] = "func",

    ["undefined"] = "const",
    ["nil"] = "const",
    ["true"] = "const",
    ["false"] = "const",
    ["SERVER"] = "const",
    ["CLIENT"] = "const",
    ["_G"] = "const"
}

local colors = {
    text = "#FFFFFF",
    bracket = "#FFD700",
    string = "#CE9178",
    number = "#B5CEA8",
    keyword = "#C586C0",
    func = "#DCDC80",
    const = "#569CD6"
}

local string_sub = string.sub

function CustomChat.TokenizeCode( inputStr )
    local inputLen = string.len( inputStr ) + 1
    local tokens = {}
    local buffer = ""
    local i = 0
    local char

    local function NextChar()
        i = i + 1
        char = string_sub( inputStr, i, i )
    end

    local function PushToken( type, value )
        if buffer:len() > 0 then
            tokens[#tokens + 1] = {
                color = colors.text,
                value = buffer
            }

            buffer = ""
        end

        tokens[#tokens + 1] = {
            color = colors[type],
            value = value
        }
    end

    while i < inputLen do
        NextChar()

        if punctuation[char] then
            PushToken( punctuation[char], char )

        elseif char:find( "%d" ) then
            local value = ""

            while char:find( "%d" ) do
                value = value .. char
                NextChar()
            end

            PushToken( "number", value )
            i = i - 1

        elseif groups[char] then
            local type = groups[char]
            local closer = char
            local value = char

            NextChar()

            while char ~= closer and i < inputLen do
                value = value .. char
                NextChar()
            end

            PushToken( type, value .. char )

        elseif char:find( "[%w_]" ) then
            local value = ""

            while char:find( "[%w_]" ) and i < inputLen do
                value = value .. char
                NextChar()
            end

            PushToken( keywords[value] or "text", value )
            i = i - 1
        else
            buffer = buffer .. char
        end
    end

    if buffer:len() > 0 then
        tokens[#tokens + 1] = {
            color = colors.text,
            value = buffer
        }
    end

    return tokens
end
