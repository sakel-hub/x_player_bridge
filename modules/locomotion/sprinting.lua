--- Third-party sprinting and special movement integration module for x_player_bridge
--- Synchronizes xXOsielXx/sprinting, GunshipPenguin/sprint, sprint_lite, hbsprint, and sum_jetpack
--- with x_player_api locomotion and controls.

local function hook_sprinting_mods()
	-- 1. xXOsielXx/sprinting compatibility
	if core.get_modpath("sprinting") then
		local use_aux1 = core.settings:get_bool("sprinting_use_aux1", true)
		if not use_aux1 then
			x_player_api.set_aux1_sprint_enabled(false)
		end
	end

	-- 2. GunshipPenguin/sprint compatibility
	if core.get_modpath("sprint") then
		local method_setting = core.settings:get("sprint_method") or core.settings:get("sprint.method")
		local method = rawget(_G, "SPRINT_METHOD")
		-- SPRINT_METHOD: 0 = double-tap forward only, 1 = aux1 key
		if method_setting == "0" or method_setting == "double_tap" or method == 0 then
			x_player_api.set_aux1_sprint_enabled(false)
		end
	end

	-- 3. Register unified locomotion evaluator for third-party sprint and flight equipment
	x_player_api.register_locomotion_evaluator(70, function(player, ctx)
		if not player or not player:is_player() then
			return nil
		end

		local name = player:get_player_name()

		-- Check Jetpack (sum_jetpack) flight status:
		-- When flying/descending with a jetpack using AUX1 in the air, ensure locomotion is fly/hover, never sprint
		if ctx.in_air and ctx.controls and ctx.controls.aux1 then
			local has_jetpack = false
			local meta = player:get_meta()
			if meta and (meta:get_int("sum_jetpack:flying") == 1 or meta:get_string("sum_jetpack:status") == "flying") then
				has_jetpack = true
			elseif rawget(_G, "sum_jetpack") then
				local sj = rawget(_G, "sum_jetpack")
				if sj.is_flying and sj.is_flying(player) then
					has_jetpack = true
				end
			end

			-- Also detect attached jetpack entity if metadata is not used
			if not has_jetpack then
				local attach = player:get_attach()
				if attach and attach:is_valid() then
					local luaentity = attach:get_luaentity()
					if luaentity and luaentity.name and luaentity.name:find("jetpack") then
						has_jetpack = true
					end
				end
			end

			if has_jetpack then
				local horiz_speed_sq = (ctx.vel.x * ctx.vel.x) + (ctx.vel.z * ctx.vel.z)
				if horiz_speed_sq > 0.08 then
					return "fly"
				else
					return "hover"
				end
			end
		end

		-- Check GunshipPenguin sprint mod / hbsprint state
		local sprint_mod = rawget(_G, "sprint")
		if sprint_mod and sprint_mod.players and sprint_mod.players[name] then
			local pdata = sprint_mod.players[name]
			if pdata.moving or (pdata.state and pdata.state > 0) then
				return "sprint"
			elseif ctx.is_sprinting or ctx.loco == "sprint" then
				return ctx.is_moving and "walk" or "stand"
			end
		end

		-- Check sprint_lite stamina threshold or is_sprinting
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

		-- Check active physics speed multiplier from external sprint mods (xXOsielXx, hbsprint, etc.)
		-- If external mod applied speed >= 1.25x and player is moving forward on ground/water
		if not ctx.is_sprinting and ctx.is_moving and not ctx.in_air then
			local phys = player.get_physics_override and player:get_physics_override()
			if phys and phys.speed and phys.speed >= 1.25 and ctx.controls and ctx.controls.up then
				return "sprint"
			end
		end

		return nil
	end)
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
