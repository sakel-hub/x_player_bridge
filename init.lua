local modname = core.get_current_modname() or "x_player_bridge"
local modpath = core.get_modpath(modname) or core.get_modpath("x_player_bridge")

core.log("action", "[" .. modname .. "] Initializing bridge to x_player_api")

---@class PlayerBridgeConfig
---@field enable_3d_armor boolean Whether 3d_armor dual-model integration is enabled
---@field enable_wieldview boolean Whether wieldview 2D suppression is enabled
---@field enable_skinsdb boolean Whether skinsdb model redirect is enabled
---@field enable_shields boolean Whether shields integration is enabled

---Global table exposing bridge configuration state and metadata
x_player_bridge = {
	config = {
		enable_3d_armor = core.settings:get_bool("x_player_bridge.enable_3d_armor", true),
		enable_wieldview = core.settings:get_bool("x_player_bridge.enable_wieldview", true),
		enable_skinsdb = core.settings:get_bool("x_player_bridge.enable_skinsdb", true),
		enable_shields = core.settings:get_bool("x_player_bridge.enable_shields", true),
	},
}

if x_player_bridge.config.enable_3d_armor then
	if core.get_modpath("3d_armor") then
		dofile(modpath .. "/3d_armor.lua")
	end
else
	core.log("action", "[" .. modname .. "] 3d_armor integration disabled via settings")
end

if x_player_bridge.config.enable_wieldview then
	if core.get_modpath("wieldview") or core.get_modpath("3d_armor") then
		dofile(modpath .. "/wieldview.lua")
	end
else
	core.log("action", "[" .. modname .. "] wieldview integration disabled via settings")
end

if x_player_bridge.config.enable_skinsdb then
	if core.get_modpath("skinsdb") then
		dofile(modpath .. "/skinsdb.lua")
	end
else
	core.log("action", "[" .. modname .. "] skinsdb integration disabled via settings")
end

if x_player_bridge.config.enable_shields then
	if core.get_modpath("shields") or core.get_modpath("3d_armor") then
		dofile(modpath .. "/shields.lua")
	end
else
	core.log("action", "[" .. modname .. "] shields integration disabled via settings")
end

