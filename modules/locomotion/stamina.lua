--- stamina integration module for x_player_bridge
--- Synchronizes stamina sprint status with x_player_api athletic locomotion and stamina exhaustion.

local function hook_stamina()
	local stamina_mod = rawget(_G, "stamina")
	if not stamina_mod or stamina_mod._x_player_bridge_wrapped then
		return
	end

	-- Helper to query setting from stamina_mod table or core.settings
	local function get_stamina_flag(key, setting_key)
		if stamina_mod[key] ~= nil then
			return stamina_mod[key]
		elseif stamina_mod.settings and stamina_mod.settings[key] ~= nil then
			return stamina_mod.settings[key]
		end
		return core.settings:get_bool(setting_key, true)
	end

	local sprint_enabled = get_stamina_flag("sprint", "stamina.sprint")
	if stamina_mod.enable_sprint ~= nil then
		sprint_enabled = stamina_mod.enable_sprint
	end
	local sprint_aux = get_stamina_flag("sprint_aux", "stamina.sprint_aux")

	-- If sprint is disabled completely or AUX1 sprint is disabled in stamina mod,
	-- dynamically disable AUX1 sprinting in x_player_api so AUX1 can be used for other mods
	if not sprint_enabled then
		x_player_api.set_aux1_sprint_enabled(false)
		x_player_api.set_double_tap_sprint_enabled(false)
	elseif not sprint_aux then
		x_player_api.set_aux1_sprint_enabled(false)
	end

	local player_states = x_player_api.controls.player_states

	-- Register callback with stamina to synchronize sprint state
	if stamina_mod.register_on_sprinting then
		stamina_mod.register_on_sprinting(function(player, sprinting)
			if not player:is_player() then
				return
			end
			local name = player:get_player_name()
			local pstate = player_states[name]
			if pstate and not sprinting and pstate.double_tap_sprint then
				pstate.double_tap_sprint = false
			end
		end)
	end

	-- Register locomotion evaluator: stamina is authoritative on whether player is sprinting
	x_player_api.register_locomotion_evaluator(75, function(player, ctx)
		if not stamina_mod.is_sprinting then
			return nil
		end

		if stamina_mod.is_sprinting(player) then
			return "sprint"
		elseif ctx and (ctx.is_sprinting or ctx.loco == "sprint") then
			-- Stamina mod reports player is NOT sprinting (e.g. exhausted or sprint disabled)
			-- Suppress x_player_api sprint animation and drop back to normal walking
			local name = player:get_player_name()
			local pstate = player_states[name]
			if pstate then
				pstate.double_tap_sprint = false
			end
			return ctx.is_moving and "walk" or "stand"
		end
		return nil
	end)

	stamina_mod._x_player_bridge_wrapped = true
end

x_player_bridge.register_module("stamina", {
	description = "Synchronizes stamina sprinting states with x_player_api sprint locomotion and exhaustion",
	required_mods = { "stamina" },
	setting = "x_player_bridge.enable_stamina",
	default_enabled = true,
	priority = 60,

	init = function()
		hook_stamina()
		return true
	end,
})
