--- i_have_hands integration module for x_player_bridge
--- Bridges KingTheGuy's i_have_hands container carrying mechanics into x_player_api
--- dual-model visual proxies and head-tracking system with calibrated 3D arm posture.

local PITCH = math.rad(118)
local YAW   = math.rad(4)
local ROLL  = math.rad(6)

-- GLB bone coordinate space: Positive X elevates arm forward/up
local ROT_R = { x =  PITCH, y = -YAW, z =  ROLL }
local ROT_L = { x =  PITCH, y =  YAW, z = -ROLL }

-- B3D bone coordinate space: Negative X elevates arm forward/up; Y and Z match wider GLB opening
local B3D_ROT_R = { x = -PITCH, y = -YAW, z =  ROLL }
local B3D_ROT_L = { x = -PITCH, y =  YAW, z = -ROLL }

local ZERO_ROT = { x = 0, y = 0, z = 0 }

---@type table<string, boolean>
local carrying_cache = {}

---Check whether a player is actively carrying a container entity from i_have_hands
---@nodiscard
---@param player ObjectRef Target player
---@return boolean is_carrying
local function is_carrying_block(player)
	if not player or not player:is_player() then
		return false
	end
	local name = player:get_player_name()
	if I_have_hands and I_have_hands.Player_data then
		local p_data = I_have_hands.Player_data[name]
		if p_data and p_data.held then
			return true
		end
	end
	if not player.get_children then
		return false
	end
	local children = player:get_children()
	if not children then
		return false
	end
	for i = 1, #children do
		local child = children[i]
		if child and child:is_valid() then
			local ent = child:get_luaentity()
			if ent and ent.name == "i_have_hands:held" then
				return true
			end
		end
	end
	return false
end

-- Expose utility function on bridge
x_player_bridge.is_carrying_block = is_carrying_block

---Apply dual-arm carrying posture to player proxies
---@param player ObjectRef Target player
local function apply_carrying_posture(player)
	x_player_api.set_bone_override(player, "Arm_Right", nil, ROT_R, true, 0.15, true, B3D_ROT_R)
	x_player_api.set_bone_override(player, "Arm_Left",  nil, ROT_L, true, 0.15, true, B3D_ROT_L)
end

---Reset player arms to resting bind pose
---@param player ObjectRef Target player
local function reset_carrying_posture(player)
	x_player_api.set_bone_override(player, "Arm_Right", nil, ZERO_ROT, true, 0.15, true, ZERO_ROT)
	x_player_api.set_bone_override(player, "Arm_Left",  nil, ZERO_ROT, true, 0.15, true, ZERO_ROT)
end

-- Expose postures for testing or external hooks
x_player_bridge.apply_carrying_posture = apply_carrying_posture
x_player_bridge.reset_carrying_posture = reset_carrying_posture

local function step_i_have_hands(player, _dtime, _semantic_state)
	if not player or not player:is_player() then return end
	local name = player:get_player_name()
	local active = x_player_bridge.is_module_active("i_have_hands")
	local carrying = active and is_carrying_block(player)
	local was_carrying = carrying_cache[name]

	if carrying then
		apply_carrying_posture(player)
		carrying_cache[name] = true
	elseif was_carrying then
		reset_carrying_posture(player)
		carrying_cache[name] = nil
	end
end

x_player_bridge._step_i_have_hands = step_i_have_hands

local function init_i_have_hands_hooks()
	-- Register action evaluator to route carrying into x_player_api semantic state
	x_player_api.register_action_evaluator(75, function(player, _ctx)
		if x_player_bridge.is_module_active("i_have_hands") and is_carrying_block(player) then
			return "carry"
		end
		return nil
	end)

	-- Wrap step_head_tracking to preserve arm posture without head-tracking clobbering
	if x_player_api.step_head_tracking and not x_player_api._i_have_hands_bridge_hooked then
		local orig_step_head_tracking = x_player_api.step_head_tracking
		x_player_api.step_head_tracking = function(player, dtime, semantic_state)
			local carrying = x_player_bridge.is_module_active("i_have_hands") and is_carrying_block(player)
			local ht_cfg = x_player_api.head_tracking and x_player_api.head_tracking.config
			local old_arm_tracking
			if carrying and ht_cfg then
				old_arm_tracking = ht_cfg.enable_arm_tracking
				ht_cfg.enable_arm_tracking = false
			end

			orig_step_head_tracking(player, dtime, semantic_state)

			if carrying and ht_cfg then
				ht_cfg.enable_arm_tracking = old_arm_tracking
			end

			if x_player_bridge and x_player_bridge._step_i_have_hands then
				x_player_bridge._step_i_have_hands(player, dtime, semantic_state)
			end
		end
		x_player_api._i_have_hands_bridge_hooked = true
	end
end

x_player_bridge.register_module("i_have_hands", {
	description = "Bridges i_have_hands container carrying into x_player_api with dual-model arm posture",
	required_mods = { "i_have_hands" },
	setting = "x_player_bridge.enable_i_have_hands",
	default_enabled = true,
	priority = 70,

	init = function()
		init_i_have_hands_hooks()
		return true
	end,

	on_leaveplayer = function(_self, player)
		if player and player:is_player() then
			carrying_cache[player:get_player_name()] = nil
		end
	end,

	on_dieplayer = function(_self, player)
		if player and player:is_player() then
			local name = player:get_player_name()
			if carrying_cache[name] or is_carrying_block(player) then
				reset_carrying_posture(player)
				carrying_cache[name] = nil
			end
		end
	end,

	on_respawnplayer = function(_self, player)
		if player and player:is_player() then
			local name = player:get_player_name()
			carrying_cache[name] = nil
			reset_carrying_posture(player)
		end
	end,
})
