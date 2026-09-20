--- stamina integration module for x_player_bridge
--- Synchronizes stamina sprint status with x_player_api athletic locomotion and stamina exhaustion.

local function hook_stamina()
	local stamina_mod = rawget(_G, "stamina")
	if not stamina_mod or stamina_mod._x_player_bridge_wrapped then
		return
	end

	-- Register callback with stamina to synchronize sprint state
	if stamina_mod.register_on_sprinting then
		stamina_mod.register_on_sprinting(function(player, sprinting)
			if not player or not player:is_player() then
				return
			end
			local name = player:get_player_name()
			local states = x_player_api.controls.player_states
			local pstate = states and states[name]
			if pstate and not sprinting and pstate.double_tap_sprint then
				pstate.double_tap_sprint = false
			end
		end)
	end

	-- Register locomotion evaluator if stamina reports sprinting
	x_player_api.register_locomotion_evaluator(75, function(player, _ctx)
		if stamina_mod and stamina_mod.is_sprinting and stamina_mod.is_sprinting(player) then
			local name = player:get_player_name()
			local states = x_player_api.controls.player_states
			local pstate = states and states[name]
			if pstate then
				pstate.double_tap_sprint = true
				if pstate.semantic_state then
					pstate.semantic_state.sprinting = true
				end
			end
			return "sprint"
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
