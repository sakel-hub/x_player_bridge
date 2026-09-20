--- 3d_armor_flyswim compatibility module for x_player_bridge
--- Intercepts legacy 3d_armor_character_sf model overrides to preserve modern glTF dual-model character.

x_player_bridge.register_module("flyswim_compat", {
	description = "Redirects 3d_armor_flyswim legacy model overrides to preserve dual-format GLB animations",
	required_mods = { "3d_armor_flyswim" },
	setting = "x_player_bridge.enable_flyswim_compat",
	default_enabled = true,
	priority = 50,

	init = function()
		-- Transparently redirect 3d_armor_flyswim mesh names to our registered dual-model character
		x_player_api.register_model_redirect("3d_armor_character_sf.b3d", "3d_armor_character.b3d")
		x_player_api.register_model_redirect("3d_armor_character_sf.glb", "3d_armor_character.b3d")

		return true
	end,
})
