--- bows integration module for x_player_bridge
--- Connects TenPlus1's bows mod charging and shooting stages to x_player_api bow_aim and bow_shoot action tracks.

x_player_bridge.register_module("bows", {
	description = "Maps bows mod charging states and arrow release to x_player_api bow_aim and bow_shoot actions",
	required_mods = { "bows" },
	setting = "x_player_bridge.enable_bows",
	default_enabled = true,
	priority = 65,

	init = function()
		-- Register bows item classification
		x_player_api.register_item_action("bows:.*", {
			is_bow = true,
			action = "bow_aim",
			shoot_action = "bow_shoot",
		})

		return true
	end,
})
