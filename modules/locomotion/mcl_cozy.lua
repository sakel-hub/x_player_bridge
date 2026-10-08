--- mcl_cozy integration module for x_player_bridge
--- Bridges mcl_cozy and mcl_decor sitting and laying states to x_player_api visual proxies.

---Hook mcl_cozy functions to synchronize with x_player_api visual proxies and state machine
local function hook_mcl_cozy()
	local cozy = rawget(_G, "mcl_cozy")
	if not cozy or cozy._x_player_bridge_wrapped then
		return
	end

	-- Locomotion evaluator for mcl_cozy sitting/laying postures
	x_player_api.register_locomotion_evaluator(85, function(player, _ctx)
		if not player or not player:is_player() then return nil end
		local name = player:get_player_name()
		local cozy_entry = cozy.players and cozy.players[name]
		if cozy_entry then
			local action = cozy_entry[2]
			return action or "sit"
		end
		return nil
	end)

	-- Hook mcl_cozy actions (sit, lay)
	local function hook_action(action_name)
		local orig_fn = cozy[action_name]
		if orig_fn then
			cozy[action_name] = function(pos, node, player)
				orig_fn(pos, node, player)
				if player and player:is_player() then
					local name = player:get_player_name()
					if cozy.players and cozy.players[name] then
						if x_player_api.player_attached then
							x_player_api.player_attached[name] = action_name
						end
						x_player_api.set_animation(player, action_name)
					end
				end
			end
		end
	end

	hook_action("sit")
	hook_action("lay")

	-- Hook mcl_cozy.stand_up
	local orig_stand_up = cozy.stand_up
	if orig_stand_up then
		cozy.stand_up = function(player)
			orig_stand_up(player)
			if player and player:is_player() then
				local name = player:get_player_name()
				if x_player_api.player_attached then
					x_player_api.player_attached[name] = nil
				end
				x_player_api.set_animation(player, "stand")
			end
		end
	end

	-- Reconcile /sit and /lay chatcommands to invoke mcl_cozy when available
	if core.override_chatcommand then
		if core.registered_chatcommands and core.registered_chatcommands["sit"] then
			core.override_chatcommand("sit", {
				description = "Sit down",
				func = function(name)
					local player = core.get_player_by_name(name)
					if not player then return end
					if cozy.sit then
						cozy.sit(nil, nil, player)
					else
						x_player_api.play_emote(player, "sit", -1)
					end
				end,
			})
		end
		if core.registered_chatcommands and core.registered_chatcommands["lay"] then
			core.override_chatcommand("lay", {
				description = "Lie down",
				func = function(name)
					local player = core.get_player_by_name(name)
					if not player then return end
					if cozy.lay then
						cozy.lay(nil, nil, player)
					else
						x_player_api.play_emote(player, "lay", -1)
					end
				end,
			})
		end
	end

	-- If mcl_player is loaded, bridge player_set_animation calls to x_player_api
	local mcl_p = rawget(_G, "mcl_player")
	if mcl_p and mcl_p.player_set_animation and not mcl_p._x_player_bridge_hooked then
		local orig_mcl_anim = mcl_p.player_set_animation
		mcl_p.player_set_animation = function(player, anim_name, speed)
			orig_mcl_anim(player, anim_name, speed)
			if player and player:is_player() and x_player_api.set_animation then
				x_player_api.set_animation(player, anim_name, speed)
			end
		end
		mcl_p._x_player_bridge_hooked = true
	end

	cozy._x_player_bridge_wrapped = true
end

x_player_bridge.register_module("mcl_cozy", {
	description = "Bridges mcl_cozy and mcl_decor sitting and laying states to x_player_api visual proxies",
	any_mods = { "mcl_cozy" },
	setting = "x_player_bridge.enable_mcl_cozy",
	default_enabled = true,
	priority = 85,

	init = function()
		hook_mcl_cozy()
		return true
	end,

	on_leaveplayer = function(_self, player)
		if player and player:is_player() and x_player_api.player_attached then
			x_player_api.player_attached[player:get_player_name()] = nil
		end
	end,

	on_dieplayer = function(_self, player)
		if player and player:is_player() and x_player_api.player_attached then
			x_player_api.player_attached[player:get_player_name()] = nil
		end
	end,

	on_respawnplayer = function(_self, player)
		if player and player:is_player() and x_player_api.player_attached then
			x_player_api.player_attached[player:get_player_name()] = nil
		end
	end,
})
