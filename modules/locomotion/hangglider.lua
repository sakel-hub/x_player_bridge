--- hangglider integration module for x_player_bridge
--- Engages x_player_api aerodynamic fly posture when a hangglider is deployed in flight.

---Check whether a player is currently gliding with an active hangglider
---@nodiscard
---@param player ObjectRef Target player
---@return boolean is_gliding
local function is_hangglider_active(player)
	if not player or not player:is_player() then
		return false
	end

	local hg = rawget(_G, "hangglider")
	if not hg then
		return false
	end

	local name = player:get_player_name()
	if hg.deployed and hg.deployed[name] then
		return true
	end
	if hg.gliding and hg.gliding[name] then
		return true
	end

	local meta = player.get_meta and player:get_meta()
	if meta and meta.get_int and meta:get_int("hangglider_deployed") == 1 then
		return true
	end

	return false
end

-- Expose utility function on bridge
x_player_bridge.is_hangglider_active = is_hangglider_active

x_player_bridge.register_module("hangglider", {
	description = "Engages x_player_api aerodynamic fly glide posture when hang glider is deployed",
	required_mods = { "hangglider" },
	setting = "x_player_bridge.enable_hangglider",
	default_enabled = true,
	priority = 55,

	init = function()
		x_player_api.register_locomotion_evaluator(60, function(player, _context)
			if is_hangglider_active(player) then
				local name = player:get_player_name()
				local states = x_player_api.controls.player_states
				local pstate = states and states[name]
				if pstate and pstate.semantic_state then
					pstate.semantic_state.gliding = true
				end
				return "fly"
			end
			return nil
		end)
		return true
	end,
})
