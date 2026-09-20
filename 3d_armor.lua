local modname = core.get_current_modname()
core.log("action", "[" .. modname .. "] Initializing 3d_armor dual-model registration and visual hook")

local base_char = x_player_api.registered_models and x_player_api.registered_models["character.b3d"]
-- Register dual-model definition inheriting animations, hitboxes, and locomotion parameters from character.b3d
x_player_api.register_model("3d_armor_character.b3d", {
	base_model = "character.b3d",
	mesh = "3d_armor_character.b3d",
	mesh_glb = "3d_armor_character.glb",
	override_animations = true,
	animations = base_char and table.copy(base_char.animations) or nil,
	animations_glb = base_char and table.copy(base_char.animations_glb) or nil,
	textures = {
		"character.png",
		"blank.png",
		"blank.png",
	},
})

-- Redirect modern GLB model identifier to our registered dual-model character
x_player_api.register_model_redirect("3d_armor_character.glb", "3d_armor_character.b3d")

local function hook_3d_armor()
	local armor_mod = rawget(_G, "armor")
	if not armor_mod or armor_mod.update_player_visuals == armor_mod._x_player_bridge_wrapped then
		return
	end

	local old_update_player_visuals = armor_mod.update_player_visuals
	---Intercept 3d_armor visual updates to route textures to x_player_api proxies and maintain dual-model mesh
	---@param self table|ObjectRef Armor mod table instance or player when invoked via dot syntax
	---@param player? ObjectRef Target player
	local function bridge_update_visuals(self, player)
		local target_player = player
		local armor_obj = self
		if not target_player and self and (type(self) == "userdata" or type(self) == "table") and self.get_player_name then
			target_player = self
			armor_obj = armor_mod
		end

		-- If 3D wield items are active, ensure slot 3 (2D quad) remains blank to prevent duplicate rendering
		if x_player_api and x_player_api.enable_wield_item and target_player then
			local name = target_player:get_player_name()
			if armor_obj and armor_obj.textures and armor_obj.textures[name] then
				armor_obj.textures[name].wielditem = "blank.png"
			end
		end

		-- Call original to handle setting player_api textures, which will route to proxies
		old_update_player_visuals(armor_obj, target_player)

		-- Ensure the model is forced to the dual model we registered
		if target_player then
			x_player_api.set_model(target_player, "3d_armor_character.b3d")
		end
	end
	armor_mod._x_player_bridge_wrapped = bridge_update_visuals
	armor_mod.update_player_visuals = bridge_update_visuals
end

core.register_on_mods_loaded(hook_3d_armor)

---Synchronize armor state on player join after Luanti client connection settles
---@param player ObjectRef Connecting player
local function sync_armor(player)
	local armor_mod = rawget(_G, "armor")
	if player and player:is_valid() and player:is_player() and armor_mod then
		armor_mod:load_armor_inventory(player)
		armor_mod:set_player_armor(player)
	end
end

core.register_on_joinplayer(function(player)
	core.after(0.2, sync_armor, player)
end)
