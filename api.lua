--- x_player_bridge: Central API, Module Registry & Lifecycle Dispatcher
--- Provides an extensible architecture connecting x_player_api with ecosystem mods.

---@class BridgeModuleDefinition
---@field name string Unique module identifier
---@field description string Description of the module
---@field required_mods? string[] List of required mods (all must be present)
---@field any_mods? string[] List of alternative mods (at least one must be present)
---@field optional_mods? string[] Optional mods that provide extra functionality
---@field setting string Configuration key in settingtypes.txt or luanti.conf
---@field default_enabled boolean Default state if configuration is unset
---@field priority? number Execution priority (higher initializes earlier, default 100)
---@field init fun(self: BridgeModuleDefinition): boolean? Main initialization hook
---@field on_joinplayer? fun(self: BridgeModuleDefinition, player: ObjectRef) Player join hook
---@field on_leaveplayer? fun(self: BridgeModuleDefinition, player: ObjectRef) Player leave hook

---Global namespace for x_player_bridge
---@class PlayerBridgeAPI
---@field registered_modules table<string, BridgeModuleDefinition>
---@field active_modules table<string, BridgeModuleDefinition>
---@field config table<string, boolean>
x_player_bridge = rawget(_G, "x_player_bridge") or {
	registered_modules = {},
	active_modules = {},
	config = {},
}
x_player_bridge.modules = x_player_bridge.registered_modules

---Register an ecosystem integration module
---@param name string|BridgeModuleDefinition Unique module identifier or definition table
---@param def? BridgeModuleDefinition Module specification table
---@return boolean success
function x_player_bridge.register_module(name, def)
	if type(name) == "table" and def == nil then
		def = name
		name = def.name or def.id
	end
	if not name or type(name) ~= "string" or name == "" then
		core.log("error", "[x_player_bridge] Attempted to register module with invalid name")
		return false
	end
	if not def or type(def) ~= "table" then
		core.log("error", "[x_player_bridge] Module definition for '" .. name .. "' must be a table")
		return false
	end
	if x_player_bridge.registered_modules[name] then
		return false
	end

	def.name = name
	def.id = name
	def.priority = def.priority or 100
	if def.default_enabled == nil then
		def.default_enabled = true
	end

	x_player_bridge.registered_modules[name] = def
	return true
end

---Check whether a specific integration module is currently active
---@nodiscard
---@param name string Unique module identifier
---@return boolean is_active
function x_player_bridge.is_module_active(name)
	return x_player_bridge.active_modules[name] ~= nil
end

---Retrieve a registered module definition
---@nodiscard
---@param name string Unique module identifier
---@return BridgeModuleDefinition|nil
function x_player_bridge.get_module(name)
	return x_player_bridge.registered_modules[name]
end

---Initialize all registered modules based on mod presence and configuration
function x_player_bridge.init_modules()
	local sorted_modules = {}
	for _, mod_def in pairs(x_player_bridge.registered_modules) do
		table.insert(sorted_modules, mod_def)
	end

	table.sort(sorted_modules, function(a, b)
		return (a.priority or 100) > (b.priority or 100)
	end)

	for _, mod_def in ipairs(sorted_modules) do
		local name = mod_def.name
		local is_enabled = true

		if mod_def.setting and mod_def.setting ~= "" then
			is_enabled = core.settings:get_bool(mod_def.setting, mod_def.default_enabled)
		end

		x_player_bridge.config["enable_" .. name] = is_enabled
		x_player_bridge.config[name] = is_enabled

		if not is_enabled then
			core.log("action", "[x_player_bridge] Module '" .. name .. "' disabled via configuration")
		else
			local mods_present = true

			if mod_def.required_mods then
				for _, req in ipairs(mod_def.required_mods) do
					if not core.get_modpath(req) then
						mods_present = false
						break
					end
				end
			end

			if mods_present and mod_def.any_mods and #mod_def.any_mods > 0 then
				local any_found = false
				for _, req in ipairs(mod_def.any_mods) do
					if core.get_modpath(req) then
						any_found = true
						break
					end
				end
				if not any_found then
					mods_present = false
				end
			end

			if mods_present and not x_player_bridge.active_modules[name] then
				local success = true
				if mod_def.init then
					local res = mod_def:init()
					if res == false then
						success = false
					end
				end

				if success then
					x_player_bridge.active_modules[name] = mod_def
					core.log("action", "[x_player_bridge] Module '" .. name .. "' successfully initialized")
				else
					core.log("warning", "[x_player_bridge] Module '" .. name .. "' returned initialization failure")
				end
			end
		end
	end
end

---Lifecycle dispatch for player join
core.register_on_joinplayer(function(player)
	if not x_player_bridge or not x_player_bridge.active_modules then
		return
	end
	for _, mod_def in pairs(x_player_bridge.active_modules) do
		if mod_def.on_joinplayer then
			mod_def:on_joinplayer(player)
		end
	end
end)

---Lifecycle dispatch for player leave
core.register_on_leaveplayer(function(player)
	if not x_player_bridge or not x_player_bridge.active_modules then
		return
	end
	for _, mod_def in pairs(x_player_bridge.active_modules) do
		if mod_def.on_leaveplayer then
			mod_def:on_leaveplayer(player)
		end
	end
end)
