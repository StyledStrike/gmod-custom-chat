---------------------------------------------------
-- Everything here is temporary, to migrate
-- existing server/client data into the new format.
-- It will stay here for a month or two.
---------------------------------------------------

local migration = {}

if SERVER then
    migration = {
        {
            oldFile = "schat_server_theme.json",
            newFile = "server_theme.json",
            transform = function( data )
                return {
                    font = data.font,
                    font_shadow = data.font_shadow,
                    animate = data.slide_anim,
                    blur = data.blur,
                    corner_radius = data.corner,
                    padding = data.pad,

                    bg_r = data.background.r,
                    bg_g = data.background.g,
                    bg_b = data.background.b,
                    bg_a = data.background.a,

                    input_r = data.input.r,
                    input_g = data.input.g,
                    input_b = data.input.b,
                    input_a = data.input.a,

                    input_bg_r = data.input_bg.r,
                    input_bg_g = data.input_bg.g,
                    input_bg_b = data.input_bg.b,
                    input_bg_a = data.input_bg.a,

                    scroll_bar_r = data.scroll_thumb.r,
                    scroll_bar_g = data.scroll_thumb.g,
                    scroll_bar_b = data.scroll_thumb.b,
                    scroll_bar_a = data.scroll_thumb.a,

                    scroll_bg_r = data.scroll_bg.r,
                    scroll_bg_g = data.scroll_bg.g,
                    scroll_bg_b = data.scroll_bg.b,
                    scroll_bg_a = data.scroll_bg.a,

                    highlight_r = data.highlight.r,
                    highlight_g = data.highlight.g,
                    highlight_b = data.highlight.b,
                    highlight_a = data.highlight.a
                }
            end
        },
        {
            oldFile = "schat_server_emojis.json",
            newFile = "server_emojis.json",
            transform = function( data )
                local newData = {}

                for _, emoji in ipairs( data ) do
                    newData[#newData + 1] = {
                        id = emoji[1],
                        url = emoji[2]
                    }
                end

                return newData
            end
        },
        {
            oldFile = "schat_server_tags.json",
            newFile = "server_tags.json"
        }
    }
end

if CLIENT then
    migration = {
        {
            oldFile = "schat_theme.json",
            newFile = "themes/old_theme.json",
            transform = function( data )
                migration[1].themeId = "old_theme"

                return {
                    name = CustomChat.GetLanguageText( "migration.old_theme_name" ),
                    description = CustomChat.GetLanguageText( "migration.old_theme_description" ),

                    font = data.font,
                    font_shadow = data.font_shadow,
                    animate = data.slide_anim,
                    blur = data.blur,
                    corner_radius = data.corner,
                    padding = data.pad,

                    bg_r = data.background.r,
                    bg_g = data.background.g,
                    bg_b = data.background.b,
                    bg_a = data.background.a,

                    input_r = data.input.r,
                    input_g = data.input.g,
                    input_b = data.input.b,
                    input_a = data.input.a,

                    input_bg_r = data.input_bg.r,
                    input_bg_g = data.input_bg.g,
                    input_bg_b = data.input_bg.b,
                    input_bg_a = data.input_bg.a,

                    scroll_bar_r = data.scroll_thumb.r,
                    scroll_bar_g = data.scroll_thumb.g,
                    scroll_bar_b = data.scroll_thumb.b,
                    scroll_bar_a = data.scroll_thumb.a,

                    scroll_bg_r = data.scroll_bg.r,
                    scroll_bg_g = data.scroll_bg.g,
                    scroll_bg_b = data.scroll_bg.b,
                    scroll_bg_a = data.scroll_bg.a,

                    highlight_r = data.highlight.r,
                    highlight_g = data.highlight.g,
                    highlight_b = data.highlight.b,
                    highlight_a = data.highlight.a
                }
            end
        },
        {
            oldFile = "schat.json",
            newFile = "client_config.json",
            transform = function( data )
                -- make sure to use the custom theme right away
                if migration[1].themeId then
                    data.theme_id = migration[1].themeId
                end

                return data
            end
        }
    }
end

CustomChat.EnsureDataDir()

for _, m in ipairs( migration ) do
    local newPath = CustomChat.DATA_DIR .. m.newFile

    -- only migrate if the new file does not exist already
    if not file.Exists( newPath, "DATA" ) and file.Exists( m.oldFile, "DATA" ) then
        CustomChat.PrintF( "Migrating old data file: '%s'", m.oldFile )

        local data = CustomChat.Unserialize( file.Read( m.oldFile, "DATA" ) )

        if table.IsEmpty( data ) then
            CustomChat.PrintF( "Nevermind, old data file '%s' is empty.", m.oldFile )
        else
            if m.transform then
                data = m.transform( data )
            end

            file.Write( newPath, CustomChat.Serialize( data ) )

            if file.Exists( newPath, "DATA" ) then
                CustomChat.PrintF( "Successfully migrated '%s' to '%s'", m.oldFile, newPath )
            end
        end
    end
end
