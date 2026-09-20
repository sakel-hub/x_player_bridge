--- emote integration module for x_player_bridge
--- Maps sofar/emote calls and commands to x_player_api multi-track action layers and postures.


local function hook_emote()
	local emote_mod = rawget(_G, "emote")
	if not emote_mod or emote_mod._x_player_bridge_wrapped then
		return
	end

	local function trigger_emote(player, anim_name)
		if not player or not player:is_player() then
			return false
		end

		x_player_api.play_emote(player, anim_name)
		return true
	end

	if emote_mod.start then
		local orig_start = emote_mod.start
		emote_mod.start = function(player, anim_name)
			if trigger_emote(player, anim_name) then
				return true
			end
			return orig_start(player, anim_name)
		end
	end

	if emote_mod.action then
		local orig_action = emote_mod.action
		emote_mod.action = function(player, anim_name)
			if trigger_emote(player, anim_name) then
				return true
			end
			return orig_action(player, anim_name)
		end
	end

	emote_mod._x_player_bridge_wrapped = true
end

x_player_bridge.register_module("emote", {
	description = "Routes emote mod animations into x_player_api multi-track action and posture layers",
	required_mods = { "emote" },
	setting = "x_player_bridge.enable_emote",
	default_enabled = true,
	priority = 45,

	init = function()
		hook_emote()
		return true
	end,
})
