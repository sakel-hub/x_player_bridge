--- simple_skins integration module for x_player_bridge
--- Ensures player skin selections from simple_skins synchronize cleanly with visual proxies.

---Wrap simple_skins setter to forward texture changes to x_player_api proxies
local function hook_simple_skins()
	local skins_mod = rawget(_G, "skins")
	if not skins_mod or skins_mod._x_player_bridge_wrapped then
		return
	end

	if skins_mod.set_player_skin then
		local orig_set_player_skin = skins_mod.set_player_skin
		skins_mod.set_player_skin = function(player, skin)
			orig_set_player_skin(player, skin)

			if not player or not player:is_player() then
				return
			end

			local name = player:get_player_name()
			local armor_mod = rawget(_G, "armor")

			-- If 3d_armor is present, armor visual handler updates composite textures
			if armor_mod and armor_mod.update_player_visuals then
				if armor_mod.textures and armor_mod.textures[name] then
					armor_mod.textures[name].skin = skin
				end
				armor_mod:update_player_visuals(player)
			else
				-- Direct update to proxies for standalone simple_skins
				x_player_api.set_textures(player, { skin })
			end
		end
		skins_mod._x_player_bridge_wrapped = true
	end
end

x_player_bridge.register_module("simple_skins", {
	description = "Synchronizes simple_skins player skin selections with x_player_api visual proxies",
	required_mods = { "simple_skins" },
	setting = "x_player_bridge.enable_simple_skins",
	default_enabled = true,
	priority = 75,

	init = function()
		hook_simple_skins()
		return true
	end,

	on_joinplayer = function(_self, player)
		local skins_mod = rawget(_G, "skins")
		if not skins_mod or not player or not player:is_player() then
			return
		end
		local name = player:get_player_name()
		local skin = skins_mod.skins and skins_mod.skins[name]
		if skin and skin ~= "" then
			core.after(0.2, function()
				if player:is_valid() then
					local armor_mod = rawget(_G, "armor")
					if not armor_mod then
						x_player_api.set_textures(player, { skin })
					end
				end
			end)
		end
	end,
})
