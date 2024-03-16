local string_sub = string.sub
local string_find = string.find

--[[
    Find patterns on strings, and turns them into "blocks"
]]

-- list of pattern ranges to look for
local rangeTypes = {
    { type = "url", pattern = "asset://[^%s%\"%>%<%!]+" },
    { type = "url", pattern = "https?://[^%s%\"%>%<%!]+" },
    { type = "hyperlink", pattern = "%[[^%c]-[^%[%]]*%]%(https?://[^'\">%s]+%)" },
    { type = "model", pattern = "models/[%w_/]+.mdl" },
    { type = "font", pattern = ";[%w_]+;" },
    { type = "italic", pattern = "%*[^%c][^%*]+%*" },
    { type = "bold", pattern = "%*%*[^%c][^%*]+%*%*" },
    { type = "bold_italic", pattern = "%*%*%*[^%c][^%*]+%*%*%*" },
    { type = "color", pattern = "<%d+,%d+,%d+>" },
    { type = "rainbow", pattern = "%$%$[^%c]+%$%$" },
    { type = "advert", pattern = "%[%[[^%c]+%]%]" },
    { type = "emoji", pattern = ":[%w_%-]+:" },
    { type = "spoiler", pattern = "||[^%c]-[^|]*||" },
    { type = "code_line", pattern = "`[^%c]+[`]*`" },
    { type = "code", pattern = "{{[^%z]-[^}}]*}}" },
    { type = "code", pattern = "```[^%z]-[^```]*```" }
}

local allowColor = false

-- A "range" is where a pattern starts/ends on a string.
-- This function searches for all ranges of one type
-- on this str, then returns them in a array.
local function FindAllRangesOfType( rangeType, str )
    if not allowColor and rangeType.type == "color" then return {} end

    local ranges = {}
    local pStart, pEnd = 1, 0

    while pStart do
        pStart, pEnd = string_find( str, rangeType.pattern, pStart )

        if pStart then
            ranges[#ranges + 1] = { s = pStart, e = pEnd, type = rangeType.type }
            pStart = pEnd
        end
    end

    return ranges
end

-- Merges a range into a array of ranges
-- in a way that overrides overlapping ranges.
local function MergeRangeInto( tbl, range )
    local newTbl = {}

    for _, other in ipairs( tbl ) do
        -- only include other ranges that do not overlap with the new range
        if other.s > range.e or other.e < range.s then
            newTbl[#newTbl + 1] = other
        end
    end

    -- include the new range
    newTbl[#newTbl + 1] = { s = range.s, e = range.e, type = range.type, value = range.value }

    return newTbl
end

local function RangeSorter( a, b )
    return a.s < b.s -- heh, get it?
end

function CustomChat.ParseString( str, outFunc )
    allowColor = CustomChat.GetConVarInt( "allow_colors", 0 ) > 0

    local ranges = {}

    -- for each range type...
    for _, rangeType in ipairs( rangeTypes ) do
        -- find all ranges (start-end) of this type
        local newRanges = FindAllRangesOfType( rangeType, str )

        -- then merge them into the ranges table
        for _, r in ipairs( newRanges ) do
            ranges = MergeRangeInto( ranges, r )
        end
    end

    -- if no ranges were found, simply output a string block
    if #ranges == 0 then
        outFunc( "string", str )
        return
    end

    -- sort ranges by their starting position
    table.sort( ranges, RangeSorter )

    local lastRangeEnd = 1

    for _, r in ipairs( ranges ) do
        -- output any text before this range
        if r.s > lastRangeEnd then
            outFunc( "string", string_sub( str, lastRangeEnd, r.s - 1 ) )
        end

        -- remember where this range ended at
        lastRangeEnd = r.e + 1

        -- output a block with the type of this range, and
        -- use where it starts/ends on the string as the value
        local value = string_sub( str, r.s, r.e )

        if value ~= "" then
            outFunc( r.type, value )
        end
    end

    -- output any leftover text after the last range
    if lastRangeEnd <= string.len( str ) then
        outFunc( "string", string_sub( str, lastRangeEnd ) )
    end
end
