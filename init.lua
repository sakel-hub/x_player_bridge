local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

core.log("action", "[" .. modname .. "] Initializing modular bridge to x_player_api")

-- Load core API, registry and lifecycle dispatcher
dofile(modpath .. "/api.lua")

-- Load modular ecosystem integrations
dofile(modpath .. "/modules/equipment/3d_armor.lua")
dofile(modpath .. "/modules/equipment/shields.lua")
dofile(modpath .. "/modules/wield/wieldview.lua")
dofile(modpath .. "/modules/wield/wield3d.lua")
dofile(modpath .. "/modules/appearance/skinsdb.lua")
dofile(modpath .. "/modules/appearance/simple_skins.lua")
dofile(modpath .. "/modules/appearance/clothing.lua")
dofile(modpath .. "/modules/combat/bows.lua")
dofile(modpath .. "/modules/locomotion/stamina.lua")
dofile(modpath .. "/modules/locomotion/hangglider.lua")
dofile(modpath .. "/modules/locomotion/flyswim_compat.lua")
dofile(modpath .. "/modules/social/emote.lua")

-- Initialize active modules immediately at load time
x_player_bridge.init_modules()

-- Also finalize active modules once all mods have finished loading
core.register_on_mods_loaded(x_player_bridge.init_modules)
