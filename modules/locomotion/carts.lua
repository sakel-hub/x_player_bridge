--- carts integration module for x_player_bridge
--- Preserves upright standing posture when player rides in a cart.

---Check whether a player is currently attached to a cart or rail vehicle
---@nodiscard
---@param player ObjectRef Target player
---@return boolean in_cart Whether player is inside a cart
local function is_player_in_cart(player)
	if not player or not player:is_player() then
		return false
	end

	local parent = player:get_attach()
	if not parent then
		return false
	end

	local luaentity = parent:get_luaentity()
	if not luaentity then
		return false
	end

	local name = luaentity.name or ""
	if name == "carts:cart"
			or name:find(":cart", 1, true)
			or name:find("cart:", 1, true)
			or name:find("minecart", 1, true)
			or luaentity.railtype ~= nil
			or luaentity.is_cart == true then
		return true
	end

	return false
end

-- Expose utility function on bridge
x_player_bridge.is_player_in_cart = is_player_in_cart

x_player_bridge.register_module("carts", {
	description = "Preserves upright standing posture when riding in minecarts and rail vehicles",
	any_mods = { "carts", "boost_cart", "minecart" },
	setting = "x_player_bridge.enable_carts",
	default_enabled = true,
	priority = 70,

	init = function()
		x_player_api.register_locomotion_evaluator(70, function(player, _context)
			if is_player_in_cart(player) then
				return "stand"
			end
			return nil
		end)
		return true
	end,
})
