--- wield3d and visible_wielditem integration module for x_player_bridge
--- Suppresses redundant standalone 3D wield entities when x_player_api native 3D wield items are enabled.

local orig_wield3d_update = nil
local orig_vw_set_player = nil
local hooks_initialized = false

---Capture and wrap wield3d and visible_wielditem functions
local function init_wield_hooks()
	if hooks_initialized then
		return
	end

	local w3d = rawget(_G, "wield3d")
	if w3d and w3d.update_entity then
		orig_wield3d_update = w3d.update_entity
	end

	local vw_entity = core.registered_entities and core.registered_entities["visible_wielditem:visible_wielditem"]
	if vw_entity and vw_entity._set_player then
		orig_vw_set_player = vw_entity._set_player
	end

	hooks_initialized = true
end

---Synchronize external 3D wield entity suppression with x_player_api configuration
---@param enable_native_3d boolean Whether x_player_api native 3D wield items are active
local function apply_wield3d_suppression(enable_native_3d)
	init_wield_hooks()
	local w3d = rawget(_G, "wield3d")
	local vw_entity = core.registered_entities and core.registered_entities["visible_wielditem:visible_wielditem"]

	if enable_native_3d then
		-- Suppress wield3d entity updates and hide existing entities
		if w3d and orig_wield3d_update then
			w3d.update_entity = function(_self, player)
				if player and w3d.wielded_item and w3d.wielded_item[player:get_player_name()] then
					local item_ent = w3d.wielded_item[player:get_player_name()]
					if item_ent and item_ent.object and item_ent.object:is_valid() then
						item_ent.object:set_properties({ is_visible = false })
					end
				end
			end
		end

		-- Suppress visible_wielditem entity attachments
		if vw_entity and orig_vw_set_player then
			vw_entity._set_player = function(self, player)
				orig_vw_set_player(self, player)
				if self.object and self.object:is_valid() then
					self.object:set_properties({ is_visible = false })
				end
			end
		end
	else
		-- Restore external 3D wield handlers when native wield items are toggled off
		if w3d and orig_wield3d_update then
			w3d.update_entity = orig_wield3d_update
		end
		if vw_entity and orig_vw_set_player then
			vw_entity._set_player = orig_vw_set_player
		end
	end
end

x_player_bridge.register_module("wield3d", {
	description = "Suppresses duplicate standalone 3D wield items when x_player_api native 3D items are active",
	any_mods = { "wield3d", "visible_wielditem" },
	setting = "x_player_bridge.enable_wield3d",
	default_enabled = true,
	priority = 84,

	init = function()
		init_wield_hooks()

		-- Hook into x_player_api runtime toggle
		local orig_set_wield_item_enabled = x_player_api.set_wield_item_enabled
		function x_player_api.set_wield_item_enabled(enabled)
			orig_set_wield_item_enabled(enabled)
			apply_wield3d_suppression(enabled == true)
		end

		apply_wield3d_suppression(x_player_api.enable_wield_item == true)
		return true
	end,
})
