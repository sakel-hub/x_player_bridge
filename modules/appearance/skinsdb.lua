--- skinsdb integration module for x_player_bridge
--- Registers transparent model redirects from skinsdb character meshes to the dual-format model
--- and normalizes skinsdb 4-slot texture arrays to the canonical 3-slot layout.

local adapted_set_textures

---Resolve composite base skin from 1.0 and 1.8 skin slots, clothing overlays, and capes
---@param player ObjectRef Target player
---@param v10 string Legacy 1.0 texture or cape overlay
---@param v18 string Modern 1.8 texture or clothing overlay
---@return string base_skin
local function resolve_base_skin(player, v10, v18)
	local has_v18 = v18 and v18 ~= "blank.png" and v18 ~= ""
	local has_v10 = v10 and v10 ~= "blank.png" and v10 ~= ""

	local skin_obj = skins and skins.get_player_skin and skins.get_player_skin(player)
	local ver = skin_obj and skin_obj.get_meta and skin_obj:get_meta("format")

	-- Seamlessly composite base skin, clothing overlays, and cape into the canonical base skin
	if ver == "1.8" or (has_v18 and not has_v10) then
		if has_v10 then
			return v18 .. "^" .. v10
		end
		return v18
	elseif ver == "1.0" or (has_v10 and not has_v18) then
		if has_v18 then
			return v10 .. "^" .. v18
		end
		return v10
	elseif has_v18 and has_v10 then
		if v10:find("cape", 1, true) or v18:find("character_", 1, true) then
			return v18 .. "^" .. v10
		else
			return v10 .. "^" .. v18
		end
	end
	return "character.png"
end

local function hook_skinsdb_textures()
	if x_player_api.set_textures == adapted_set_textures then
		return
	end

	local orig_set_textures = x_player_api.set_textures

	---Normalize skinsdb 4-slot texture tables into canonical 3-slot layout for 3d_armor models
	---@param player ObjectRef Target player
	---@param textures string[] List of texture filenames
	adapted_set_textures = function(player, textures)
		if textures and #textures >= 4 then
			local pdata = x_player_api.get_player_data(player)
			local model_name = pdata and pdata.model
			local model = model_name and x_player_api.get_model(model_name)

			local v10 = textures[1]
			local v18 = textures[2]
			local armor_tex = textures[3]
			local wield_tex = textures[4]
			local base_skin = resolve_base_skin(player, v10, v18)

			if model and model.textures and #model.textures == 1 then
				textures = { base_skin }
			else
				local final_armor = (armor_tex and armor_tex ~= "blank.png" and armor_tex) or "3d_armor_trans.png"
				local final_wield = (x_player_api.enable_wield_item and "blank.png")
					or (wield_tex and wield_tex ~= "blank.png" and wield_tex)
					or "blank.png"

				textures = { base_skin, final_armor, final_wield }
			end
		end
		return orig_set_textures(player, textures)
	end

	x_player_api.set_textures = adapted_set_textures
	if player_api then
		player_api.set_textures = adapted_set_textures
	end
end

x_player_bridge.register_module("skinsdb", {
	description = "Redirects skinsdb 3d_armor mesh identifiers to dual-format character models and normalizes textures",
	required_mods = { "skinsdb" },
	setting = "x_player_bridge.enable_skinsdb",
	default_enabled = true,
	priority = 80,

	init = function()
		-- Redirect skinsdb 3d_armor mesh identifiers to registered dual-model or standard character
		local has_3d_armor = x_player_bridge.is_module_active("3d_armor")
		local target_model = has_3d_armor and "3d_armor_character.b3d" or "character.b3d"

		x_player_api.register_model_redirect("skinsdb_3d_armor_character_5.b3d", target_model)
		x_player_api.register_model_redirect("skinsdb_3d_armor_character.b3d", target_model)
		x_player_api.register_model_redirect("skinsdb_3d_armor_character_5.glb", target_model)
		x_player_api.register_model_redirect("skinsdb_3d_armor_character.glb", target_model)

		hook_skinsdb_textures()
		core.register_on_mods_loaded(hook_skinsdb_textures)
		return true
	end,
})
