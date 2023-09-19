# Styled's Networked Server Preferences 

A basic library that automatically synchronizes server values to all clients.

After calling `require( "styled_netprefs" )` on a shared environment (both *SERVER* and *CLIENT*), the table `NetPrefs` becomes available globally, and provides the following functions:

### NetPrefs.Set( key: string, value: string )

Available **only on the server**.

Sets a value on the server, and it will be available to everyone by using `NetPrefs.Get`. Theres a 32 character limit for `key`, and a 40kb (Stored as bytes on `NetPrefs.MAX_VALUE_SIZE`) size limit for `value`.

Example:

```lua
-- The key should not be a generic word since it can conflict with other addons,
-- so I recommend placing your addon name before the key name like on this example.
NetPrefs.Set( "myaddon.settings", util.TableToJSON( MyAddon.settings ) )
```

### value = NetPrefs.Get( key: string, default: string | nil )

Available **both on the client and server**.

Gets a `value` that was set on the server. If the value associated with this `key` does not exist or was not set/synchronized yet, returns `default` instead.

### size = NetPrefs.CalculateValueSize( value: string )

Available **both on the client and server**.

Calculates the size (in bytes) of `value` after being compressed. Can be used together with `NetPrefs.MAX_VALUE_SIZE` to test if your value can be used in `NetPrefs.Set`.

---

### Hooks

Everytime a value is set on the server or synchronized on the client, the hook `NetPrefs_OnChange` is called. Example:

```lua
if SERVER then
    -- my addon's settings will be available to all clients
    NetPrefs.Set( "myaddon.settings", util.TableToJSON( MyAddon.settings ) )
end

if CLIENT then
    hook.Add( "NetPrefs_OnChange", "MyAddon.OnServerSettingsChange", function( key, value )
        if key == "myaddon.settings" then
            -- now we know my addon's settings clientside
            MyAddon.settings = util.JSONToTable( value )
        end
    end )
end
```
