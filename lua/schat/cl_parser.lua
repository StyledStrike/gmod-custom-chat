local table_insert = table.insert
local str_sub = string.sub

--[[
    Parses patterns on strings, turning them into "blocks"
]]

-- List of patterns to search on the input,
-- from the lowest to highest priority, meaning the
-- next item on the table overrides the previous
local rangeTypes = {
    { type = "url", pattern = "asset://[^%s%\"%>%<%!]+" },
    { type = "url", pattern = "https?://[^%s%\"%>%<%!]+" },
    { type = "model", pattern = "models/[%w_/]+.mdl" },
    { type = "font", pattern = ";[%w_]+;" },
    { type = "italic", pattern = "%*[%g%s][^%*]+%*" },
    { type = "bold", pattern = "%*%*[%g%s][^%*]+%*%*" },
    { type = "bold_italic", pattern = "%*%*%*[%g%s][^%*]+%*%*%*" },
    { type = "rainbow", pattern = "%$%$[%g%s%*]+%$%$" },
    { type = "advert", pattern = "%[%[[%g%s%*]+%]%]" },
    { type = "emoji", pattern = ":[%w_%-]+:" },
    { type = "spoiler", pattern = "||[%g%s][^||]+||" },
    { type = "code_line", pattern = "`[%g%s{}%[%]]+`" },
    { type = "code", pattern = "{{[%g%s{}]+}}" },
    { type = "code", pattern = "```[%g%s`]+```" }
}

-- A "range" is where a pattern starts/ends on a string.
-- This function searches for all ranges of one type
-- on this str, then returns them in a table.
local function FindAllRangesOfType( r, str )
    if r.ignoreCase then
        str = string.lower( str )
    end

    local ranges = {}
    local pStart, pEnd = 1, 0

    while pStart do
        pStart, pEnd = string.find( str, r.pattern, pStart )

        if pStart then
            table_insert( ranges, { s = pStart, e = pEnd, type = r.type } )
            pStart = pEnd
        end
    end

    return ranges
end

-- Merges a new range into a table of ranges
-- in a way that overrides existing ranges.
local function MergeRangeInto( tbl, newr )
    local newTbl = {}

    for _, other in ipairs( tbl ) do
        -- only include other ranges that do not overlap with the new range
        if other.s > newr.e or other.e < newr.s then
            newTbl[#newTbl + 1] = other
        end
    end

    -- finally, include the new range
    newTbl[#newTbl + 1] = { s = newr.s, e = newr.e, type = newr.type }

    return newTbl
end

function SChat:ParseString( inputStr, outFunc )
    local ranges = {}

    -- for each range type...
    for _, rangeType in ipairs( rangeTypes ) do
        -- find all ranges (start-end) of this type
        local newRanges = FindAllRangesOfType( rangeType, inputStr )

        -- then merge them into the ranges table
        for _, r in ipairs( newRanges ) do
            ranges = MergeRangeInto( ranges, r )
        end
    end

    -- if no ranges were found, simply output a string block
    if #ranges == 0 then
        outFunc( "string", inputStr )
        return
    end

    -- sort ranges by their starting position
    table.sort( ranges, function( a, b )
        return a.s < b.s
    end )

    local lastRangeEnd = 1

    for _, r in ipairs( ranges ) do
        -- output any text before this range
        if r.s > lastRangeEnd then
            outFunc( "string", str_sub( inputStr, lastRangeEnd, r.s - 1 ) )
        end

        -- remeber where this range ended at
        lastRangeEnd = r.e + 1

        -- output a block with the type of this range, and
        -- where (on the string) it starts/ends as a value
        local value = str_sub( inputStr, r.s, r.e )

        if value ~= "" then
            outFunc( r.type, value )
        end
    end

    -- output any leftover text after the last range
    if lastRangeEnd - 1 < string.len( inputStr ) then
        outFunc( "string", str_sub( inputStr, lastRangeEnd ) )
    end
end
