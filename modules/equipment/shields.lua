--- shields integration module for x_player_bridge
--- Bridges shield defense mechanics into x_player_api blocking guard posture.

---Check whether player has a shield equipped in their armor inventory
---@nodiscard
---@param player ObjectRef Target player
---@return boolean is_equipped Whether an active shield is equipped
local function is_shield_equipped(player)
	if not player then
		return false
	end

	local armor_mod = rawget(_G, "armor")
	if not armor_mod then
		return false
	end

	-- Check 3d_armor element map if available
	if armor_mod.get_weared_armor_elements then
		local worn = armor_mod:get_weared_armor_elements(player)
		if worn and worn.shield then
			return true
		end
	end

	-- Check armor definition cache for player
	if armor_mod.def then
		local name = player:get_player_name()
		local pdef = armor_mod.def[name]
		if pdef and pdef.shield and pdef.shield > 0 then
			return true
		end
	end

	return false
end

-- Expose utility function on bridge table for inspections or external integrations
x_player_bridge.is_shield_equipped = is_shield_equipped

x_player_bridge.register_module("shields", {
	description = "Maps shield equip checks to x_player_api defensive block action posture",
	any_mods = { "shields", "3d_armor" },
	setting = "x_player_bridge.enable_shields",
	default_enabled = true,
	priority = 90,

	init = function()
		x_player_api.register_blocking_predicate(function(player, _wield_name, _item_info)
			return is_shield_equipped(player)
		end)
		return true
	end,
})
