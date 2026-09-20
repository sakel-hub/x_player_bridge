--- wieldview integration module for x_player_bridge
--- Dynamically suppresses legacy 2D hand texture compositing when 3D wield items are enabled.

local orig_wv_update = nil
local orig_wv_get_texture = nil
local hooks_initialized = false

---Capture original wieldview functions once available
local function init_wieldview_hooks()
	local wv = rawget(_G, "wieldview")
	if wv and not hooks_initialized then
		orig_wv_update = wv.update_wielded_item
		orig_wv_get_texture = wv.get_item_texture
		hooks_initialized = true
	end
end

---Synchronize 2D wieldview state with 3D wield item configuration
---@param enable_3d boolean Whether 3D wield items are enabled in x_player_api
---@param refresh_players? boolean Whether to refresh visuals across connected players
local function apply_wieldview_state(enable_3d, refresh_players)
	init_wieldview_hooks()
	local wv = rawget(_G, "wieldview")
	local armor_mod = rawget(_G, "armor")

	if enable_3d then
		-- Suppress legacy 2D wieldview compositing to prevent duplicate item rendering
		if wv then
			wv.update_wielded_item = function() end
			wv.get_item_texture = function() return "blank.png" end
		end
		if armor_mod and armor_mod.textures then
			for _, tex in pairs(armor_mod.textures) do
				if tex.wielditem and tex.wielditem ~= "blank.png" and tex.wielditem ~= "3d_armor_trans.png" then
					tex.wielditem = "blank.png"
				end
			end
		end
		-- Refresh visuals for connected players when toggled at runtime
		if refresh_players and armor_mod and armor_mod.update_player_visuals then
			for _, player in ipairs(core.get_connected_players()) do
				armor_mod:update_player_visuals(player)
			end
		end
	else
		-- Restore legacy 2D wieldview compositing when 3D wield items are disabled
		if wv and hooks_initialized then
			if orig_wv_update then
				wv.update_wielded_item = orig_wv_update
			end
			if orig_wv_get_texture then
				wv.get_item_texture = orig_wv_get_texture
			end
		end
		-- Update wielded items immediately for connected players when toggled at runtime
		if refresh_players and wv and wv.update_wielded_item then
			for _, player in ipairs(core.get_connected_players()) do
				wv.update_wielded_item(player)
			end
		end
	end
end

-- Expose apply function for testing and bridge inspection
x_player_bridge.apply_wieldview_state = apply_wieldview_state

x_player_bridge.register_module("wieldview", {
	description = "Suppresses 2D hand texture compositing when 3D wield items are enabled in x_player_api",
	any_mods = { "wieldview", "3d_armor" },
	setting = "x_player_bridge.enable_wieldview",
	default_enabled = true,
	priority = 85,

	init = function()
		init_wieldview_hooks()

		-- Hook into x_player_api runtime toggle
		local orig_set_wield_item_enabled = x_player_api.set_wield_item_enabled
		---Wrap set_wield_item_enabled to dynamically switch between 3D wield entities and 2D wieldview
		---@param enabled boolean Whether 3D wield item rendering is enabled
		function x_player_api.set_wield_item_enabled(enabled)
			orig_set_wield_item_enabled(enabled)
			apply_wieldview_state(enabled, true)
		end

		apply_wieldview_state(x_player_api.enable_wield_item == true, false)
		return true
	end,
})
