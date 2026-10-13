--- Third-party sprinting and special movement integration module for x_player_bridge
--- Synchronizes xXOsielXx/sprinting, GunshipPenguin/sprint, sprint_lite, hbsprint, and sum_jetpack
--- with x_player_api locomotion and controls.

local function hook_sprinting_mods()
	local has_sprinting = core.get_modpath("sprinting") ~= nil
	local has_sprint = core.get_modpath("sprint") ~= nil
	local has_sprint_lite = core.get_modpath("sprint_lite") ~= nil
	local has_hbsprint = core.get_modpath("hbsprint") ~= nil
	local has_jetpack = core.get_modpath("sum_jetpack") ~= nil or core.get_modpath("jetpack") ~= nil

	-- 1. xXOsielXx/sprinting compatibility: disable AUX1 sprint if configured as double-tap only
	if has_sprinting then
		local use_aux1 = core.settings:get_bool("sprinting_use_aux1", true)
		if not use_aux1 then
			x_player_api.set_aux1_sprint_enabled(false)
		end
	end

	-- 2. GunshipPenguin/sprint compatibility: disable AUX1 sprint if SPRINT_METHOD = 0
	if has_sprint then
		local method_setting = core.settings:get("sprint_method") or core.settings:get("sprint.method")
		local method = rawget(_G, "SPRINT_METHOD")
		if method_setting == "0" or method_setting == "double_tap" or method == 0 then
			x_player_api.set_aux1_sprint_enabled(false)
		end
	end

	-- Airborne Jetpack flight and descent protection
	-- Evaluates above sprint evaluators so jetpack flight and descending via AUX1 in air
	-- displays hover locomotion instead of prone flight or sprint strides
	if has_jetpack then
		x_player_api.register_locomotion_evaluator(80, function(player, ctx)
			if not ctx.in_air then
				return nil
			end

			local is_flying = false
			local meta = player:get_meta()
			if meta:get_int("sum_jetpack:flying") == 1 or meta:get_string("sum_jetpack:status") == "flying" then
				is_flying = true
			else
				local sj = rawget(_G, "sum_jetpack")
				if sj and sj.is_flying and sj.is_flying(player) then
					is_flying = true
				else
					local attach = player:get_attach()
					if attach and attach:is_valid() then
						local luaentity = attach:get_luaentity()
						if luaentity and luaentity.name and luaentity.name:find("jetpack", 1, true) then
							is_flying = true
						end
					end
				end
			end

			if is_flying then
				return "hover"
			end

			return nil
		end)
	end

	-- 4. Third-party sprint state evaluator (Priority 70)
	if has_sprint or has_sprint_lite or has_sprinting or has_hbsprint then
		x_player_api.register_locomotion_evaluator(70, function(player, ctx)
			local name = player:get_player_name()

			-- GunshipPenguin / hbsprint state tracking
			if has_sprint or has_hbsprint then
				local sprint_mod = rawget(_G, "sprint")
				if sprint_mod and sprint_mod.players then
					local pdata = sprint_mod.players[name]
					if pdata then
						if pdata.moving or (pdata.state and pdata.state > 0) then
							return "sprint"
						elseif ctx.is_sprinting or ctx.loco == "sprint" then
							return ctx.is_moving and "walk" or "stand"
						end
					end
				end
			end

			-- sprint_lite stamina and sprinting status
			if has_sprint_lite then
				local sprint_lite = rawget(_G, "sprint_lite")
				if sprint_lite then
					if sprint_lite.is_sprinting and sprint_lite.is_sprinting(name) then
						return "sprint"
					elseif sprint_lite.get_stamina then
						local stam = sprint_lite.get_stamina(name)
						if stam and stam <= 0 and (ctx.is_sprinting or ctx.loco == "sprint") then
							return ctx.is_moving and "walk" or "stand"
						end
					end
				end
			end

			-- xXOsielXx / hbsprint physics speed override
			-- Only check if holding forward on ground/water to avoid get_physics_override() table churn
			if (has_sprinting or has_hbsprint) and not ctx.is_sprinting and ctx.is_moving
					and not ctx.in_air and ctx.controls and ctx.controls.up then
				local phys = player:get_physics_override()
				if phys.speed >= 1.25 then
					return "sprint"
				end
			end

			return nil
		end)
	end
end

x_player_bridge.register_module("sprinting", {
	description = "Synchronizes third-party sprint and flight mods with x_player_api locomotion",
	any_mods = { "sprinting", "sprint", "sprint_lite", "hbsprint", "sum_jetpack", "jetpack" },
	setting = "x_player_bridge.enable_sprinting",
	default_enabled = true,
	priority = 59,

	init = function()
		hook_sprinting_mods()
		return true
	end,
})
