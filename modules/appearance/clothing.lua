--- clothing integration module for x_player_bridge
--- Ensures layered clothing composite textures synchronize with visual proxies.

local function hook_clothing()
	local clothing_mod = rawget(_G, "clothing")
	if not clothing_mod or clothing_mod._x_player_bridge_wrapped then
		return
	end

	local function on_clothing_update(player)
		if not player or not player:is_player() then
			return
		end

		-- Check if 3d_armor is already managing composite layers
		local armor_mod = rawget(_G, "armor")
		if armor_mod and armor_mod.update_player_visuals then
			armor_mod:update_player_visuals(player)
		end
	end

	-- Register via official callback if available
	if clothing_mod.register_on_update then
		clothing_mod:register_on_update(on_clothing_update)
	end

	-- Also intercept direct clothing update calls
	if clothing_mod.update_player then
		local orig_update_player = clothing_mod.update_player
		clothing_mod.update_player = function(self, player)
			orig_update_player(self, player)
			on_clothing_update(player)
		end
	end

	clothing_mod._x_player_bridge_wrapped = true
end

x_player_bridge.register_module("clothing", {
	description = "Synchronizes clothing layered composite textures with x_player_api visual proxies",
	required_mods = { "clothing" },
	setting = "x_player_bridge.enable_clothing",
	default_enabled = true,
	priority = 70,

	init = function()
		hook_clothing()
		return true
	end,
})
