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
	---and map 3-slot equipment textures to native 4-slot layout on skinsdb 1.8 custom model
	---@param player ObjectRef Target player
	---@param textures string[] List of texture filenames
	adapted_set_textures = function(player, textures)
		if not textures or not player then
			return orig_set_textures(player, textures)
		end

		local model_name = x_player_api.get_model_name(player)
		local model = model_name and x_player_api.get_model(model_name)

		local is_skinsdb_custom_model = model_name == "skinsdb_3d_armor_character_5.b3d"
			or (model and model.mesh and model.mesh:find("skinsdb_3d_armor_character_5", 1, true))

		if is_skinsdb_custom_model then
			-- Native 4-slot layout for 1.8 3D custom model:
			-- Slot 1: Format10 (legacy 1.0 skin or cape)
			-- Slot 2: Format18 (modern 1.8 skin with 3D outer layers)
			-- Slot 3: Armor
			-- Slot 4: Wielditem
			local v10, v18, armor_tex, wield_tex
			if #textures >= 4 then
				v10 = textures[1]
				v18 = textures[2]
				armor_tex = textures[3]
				wield_tex = textures[4]
			elseif #textures == 2 or #textures == 3 then
				local skin = textures[1]
				armor_tex = textures[2]
				wield_tex = textures[3]

				local skin_obj = rawget(_G, "skins") and skins.get_player_skin and skins.get_player_skin(player)
				if (not skin or skin == "" or skin == "blank.png") and skin_obj and skin_obj.get_texture then
					skin = skin_obj:get_texture()
				end

				local ver = skin_obj and skin_obj.get_meta and skin_obj:get_meta("format")
				if ver == "1.8" or (skin and skin:find("_18", 1, true)) then
					v18 = skin
					v10 = "blank.png"
				else
					v10 = skin
					v18 = "blank.png"
				end
			elseif #textures == 1 then
				local skin = textures[1]
				local skin_obj = rawget(_G, "skins") and skins.get_player_skin and skins.get_player_skin(player)
				if (not skin or skin == "" or skin == "blank.png") and skin_obj and skin_obj.get_texture then
					skin = skin_obj:get_texture()
				end

				local ver = skin_obj and skin_obj.get_meta and skin_obj:get_meta("format")
				if ver == "1.8" or (skin and skin:find("_18", 1, true)) then
					v18 = skin
					v10 = "blank.png"
				else
					v10 = skin
					v18 = "blank.png"
				end
				armor_tex = "3d_armor_trans.png"
				wield_tex = "blank.png"
			end

			local final_armor = (armor_tex and armor_tex ~= "blank.png" and armor_tex) or "3d_armor_trans.png"
			local final_wield = (x_player_api.enable_wield_item and "blank.png")
				or (wield_tex and wield_tex ~= "blank.png" and wield_tex)
				or "blank.png"

			local final_v10 = (v10 and v10 ~= "" and v10) or "blank.png"
			local final_v18 = (v18 and v18 ~= "" and v18) or "blank.png"
			textures = { final_v10, final_v18, final_armor, final_wield }
		elseif #textures >= 4 then
			local v10 = textures[1]
			local v18 = textures[2]
			local armor_tex = textures[3]
			local wield_tex = textures[4]

			local final_armor = (armor_tex and armor_tex ~= "blank.png" and armor_tex) or "3d_armor_trans.png"
			local final_wield = (x_player_api.enable_wield_item and "blank.png")
				or (wield_tex and wield_tex ~= "blank.png" and wield_tex)
				or "blank.png"

			if model and model.textures and #model.textures == 1 then
				local base_skin = resolve_base_skin(player, v10, v18)
				textures = { base_skin }
			else
				-- Fallback for 3-slot models (e.g. 3d_armor_character.b3d)
				local base_skin = resolve_base_skin(player, v10, v18)
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
	description = "Registers skinsdb 1.8 3D character models with animations and normalizes 4-slot textures",
	required_mods = { "skinsdb" },
	setting = "x_player_bridge.enable_skinsdb",
	default_enabled = true,
	priority = 80,

	init = function()
		local base_char = x_player_api.registered_models and x_player_api.registered_models["character.b3d"]

		-- Register modern dual-model with full 1.8 3D mesh and all x_player_api animations
		x_player_api.register_model("skinsdb_3d_armor_character_5.b3d", {
			base_model = "character.b3d",
			mesh = "skinsdb_3d_armor_character_5.b3d",
			mesh_glb = "skinsdb_3d_armor_character_5.glb",
			use_texture_alpha = false,
			override_animations = true,
			animations = base_char and table.copy(base_char.animations) or nil,
			animations_glb = base_char and table.copy(base_char.animations_glb) or nil,
			textures = {
				"blank.png", -- Slot 1: Format10 (legacy 1.0 skin or cape)
				"blank.png", -- Slot 2: Format18 (modern 1.8 skin with 3D outer layers)
				"blank.png", -- Slot 3: Armor
				"blank.png", -- Slot 4: Wielditem
			},
		})

		-- Redirect modern GLB identifier and legacy aliases to registered dual-model
		x_player_api.register_model_redirect("skinsdb_3d_armor_character_5.glb", "skinsdb_3d_armor_character_5.b3d")
		x_player_api.register_model_redirect("skinsdb_3d_armor_character.b3d", "skinsdb_3d_armor_character_5.b3d")
		x_player_api.register_model_redirect("skinsdb_3d_armor_character.glb", "skinsdb_3d_armor_character_5.b3d")

		hook_skinsdb_textures()
		core.register_on_mods_loaded(hook_skinsdb_textures)
		return true
	end,
})
