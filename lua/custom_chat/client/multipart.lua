-- Modified from https://github.com/CFC-Servers/gm_formdata/blob/main/lua/includes/modules/formdata.lua
local function getMime( data )
    if data:sub( 1, 4 ) == "\x89PNG" then
        return "image/png"
    elseif data:sub( 1, 3 ) == "\xff\xd8\xff" then
        return "image/jpeg"
    elseif data:sub( 1, 4 ) == "GIF8" then
        return "image/gif"
    elseif data:sub( 1, 4 ) == "%PDF" then
        return "application/pdf"
    end

    return false
end

function CustomChat.FormData()
    return {
        entries = {},
        boundary = tostring( math.Round( os.time() ) ),

        Append = function( self, name, value, filename )
            local mime = getMime( value )

            table.insert( self.entries, {
                name = name,
                value = value,
                mime = mime,
                filename = filename
            } )
        end,

        Read = function( self )
            local body = ""

            for _, entry in ipairs( self.entries ) do
                local mime = entry.mime
                local name = entry.name
                local value = entry.value
                local filename = entry.filename

                body = body .. "--" .. self.boundary
                body = body .. "\r\nContent-Disposition: form-data; name=\"" .. name .. "\""
                if filename then
                    body = body .. "; filename=\"" .. filename .. "\""
                end

                body = body .. "\r\nContent-Type: " .. ( mime or "text/plain" ) .. "; charset=utf-8"
                body = body .. "\r\n\r\n" .. value .. "\r\n"
            end

            body = body .. "--" .. self.boundary .. "--\r\n"

            return body
        end,

        GetHeaders = function( self )
            return {
                ["Content-Length"] = #self:Read(),
                ["Content-Type"] = "multipart/form-data; charset=utf-8; boundary=" .. self.boundary
            }
        end
    }
end
