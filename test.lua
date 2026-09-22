-- Unit Test Runner for x_player_bridge
-- Tests modular mod overrides and settings toggles

package.path = "../x_player_api/?.lua;../x_player_api/?/init.lua;./?.lua;" .. package.path

local framework = require("tests.framework")
local mock_env = require("tests.mock_env")

mock_env.init()
framework.expose_globals()

describe("x_player_bridge Modular Architecture", function()
	local orig_get_modname = core.get_current_modname
	local orig_get_modpath = core.get_modpath

	local function reset_bridge_env()
		core.get_current_modname = function() return "x_player_bridge" end
		core.get_modpath = function(mod)
			if mod == "x_player_bridge" then
				return "."
			elseif mod == "x_player_api" or mod == "player_api" then
				return "../x_player_api"
			end
			if core._enabled_mods[mod] then
				return "/mods/" .. mod
			end
			return nil
		end
		core.settings._values = {}
		core._on_mods_loaded = {}
		rawset(_G, "armor", {
			update_player_visuals = function() end,
			load_armor_inventory = function() end,
			set_player_armor = function() end,
			textures = {},
		})
		rawset(_G, "wieldview", {
			update_wielded_item = function() end,
			get_item_texture = function() return "item.png" end,
		})
		rawset(_G, "x_player_bridge", nil)
	end

	it("loads 3d_armor integration when enabled and mod is present", function()
		reset_bridge_env()
		core._enabled_mods["3d_armor"] = true

		local player = mock_env.create_player("Sam")
		dofile("init.lua")

		assert.is_not_nil(x_player_bridge)
		assert.is_true(x_player_bridge.config.enable_3d_armor)

		-- Verify 3d_armor_character.b3d was registered with base_model inheritance
		local model = player_api.registered_models["3d_armor_character.b3d"]
		assert.is_not_nil(model)
		assert.equal("3d_armor_character.b3d", model.mesh)
		assert.equal("3d_armor_character.glb", model.mesh_glb)
		assert.equal("character.b3d", model.base_model)
		assert.is_not_nil(model.animations["walk"])
		assert.equal("3d_armor_character.b3d", player_api.resolve_model("3d_armor_character.glb"))

		-- Verify armor.update_player_visuals intercepts and sets model (colon syntax)
		for _, fn in ipairs(core._on_mods_loaded or {}) do fn() end
		armor.update_player_visuals(armor, player)
		local current_model = player_api.get_animation(player).model
		assert.equal("3d_armor_character.b3d", current_model)

		-- Verify dot-syntax calling convention armor.update_player_visuals(player)
		local received_self, received_player
		armor.update_player_visuals = function(s, p)
			received_self = s
			received_player = p
		end
		-- Re-wrap with 3d_armor module hook
		dofile("modules/equipment/3d_armor.lua")
		local mod_def = x_player_bridge.registered_modules["3d_armor"]
		if mod_def then
			mod_def:init()
			x_player_bridge.active_modules["3d_armor"] = mod_def
		end
		for _, fn in ipairs(core._on_mods_loaded or {}) do fn() end

		player_api.set_model(player, "character.b3d")
		armor.update_player_visuals(player)
		assert.equal("3d_armor_character.b3d", player_api.get_animation(player).model)
		assert.equal(armor, received_self)
		assert.equal(player, received_player)
	end)

	it("synchronizes armor inventory and visuals on player reconnect", function()
		reset_bridge_env()
		core._enabled_mods["3d_armor"] = true

		local loaded_player = nil
		local set_player = nil
		armor.load_armor_inventory = function(_self, p)
			loaded_player = p
		end
		armor.set_player_armor = function(_self, p)
			set_player = p
		end

		dofile("init.lua")

		local player = mock_env.join_player("Reconnector")
		assert.is_not_nil(player)
		assert.equal(player, loaded_player)
		assert.equal(player, set_player)
	end)

	it("retains GLB mesh and multitrack animations when 3d_armor registers before bridge", function()
		reset_bridge_env()
		core._enabled_mods["3d_armor"] = true

		-- Simulate 3d_armor loading first (as resolved by mod.conf dependency)
		player_api.register_model("3d_armor_character.b3d", {
			animation_speed = 30,
			textures = {"character.png", "blank.png", "blank.png"},
			animations = {
				stand = {x = 0, y = 79},
				walk = {x = 168, y = 187},
				wave = {x = 192, y = 196, override_local = true},
				point = {x = 196, y = 196, override_local = true},
			},
		})

		-- Bridge loads next
		dofile("init.lua")

		local model = player_api.registered_models["3d_armor_character.b3d"]
		assert.is_not_nil(model)
		assert.equal("3d_armor_character.b3d", model.mesh)
		assert.equal("3d_armor_character.glb", model.mesh_glb)
		assert.is_not_nil(model.animations_glb["walk"])
		assert.is_true(model.is_multitrack)

		-- Assert canonical emote frames from character.b3d overwrite 3d_armor's dummy mining downstroke ranges
		assert.equal(516, model.animations.wave.x)
		assert.equal(536, model.animations.wave.y)
		assert.equal(541, model.animations.point.x)
		assert.equal(556, model.animations.point.y)
		assert.equal(561, model.animations.cheer.x)
		assert.equal(581, model.animations.cheer.y)

		local player = mock_env.join_player("Alex")
		player_api.set_model(player, "3d_armor_character.b3d")
		player_api.set_animation(player, "walk")

		local proxies = player_api.get_visual_proxies(player)
		assert.is_not_nil(proxies)
		local played = proxies.glb._played_animations
		assert.is_true(#played > 0)
		assert.equal("walk", played[#played].track)
	end)

	it("skips 3d_armor integration when setting is disabled", function()
		reset_bridge_env()

		core._enabled_mods["3d_armor"] = true
		core.settings:set_bool("x_player_bridge.enable_3d_armor", false)

		-- Clear previous model if any
		player_api.registered_models["3d_armor_character.b3d"] = nil

		dofile("init.lua")

		assert.is_false(x_player_bridge.config.enable_3d_armor)
		assert.is_nil(player_api.registered_models["3d_armor_character.b3d"])
	end)

	it("loads wieldview integration and dynamically toggles 2D compositing based on enable_wield_item", function()
		reset_bridge_env()
		core._enabled_mods["wieldview"] = true
		player_api.enable_wield_item = true

		dofile("init.lua")
		for _, fn in ipairs(core._on_mods_loaded or {}) do fn() end

		assert.is_true(x_player_bridge.config.enable_wieldview)

		-- When 3D wield items are enabled, 2D wieldview compositing is suppressed to blank.png
		assert.equal("blank.png", wieldview.get_item_texture())

		-- When 3D wield items are disabled, 2D wieldview compositing is restored
		player_api.set_wield_item_enabled(false)
		assert.equal("item.png", wieldview.get_item_texture())

		-- When 3D wield items are re-enabled, 2D wieldview is suppressed again
		player_api.set_wield_item_enabled(true)
		assert.equal("blank.png", wieldview.get_item_texture())
	end)

	it("skips wieldview integration when setting is disabled", function()
		reset_bridge_env()
		core._enabled_mods["wieldview"] = true
		core.settings:set_bool("x_player_bridge.enable_wieldview", false)
		player_api.enable_wield_item = true

		dofile("init.lua")

		assert.is_false(x_player_bridge.config.enable_wieldview)
		assert.equal("item.png", wieldview.get_item_texture())
	end)

	it("loads skinsdb integration and registers redirect when enabled", function()
		reset_bridge_env()
		core._enabled_mods["skinsdb"] = true

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_skinsdb)
		local resolved = player_api.resolve_model("skinsdb_3d_armor_character_5.b3d")
		assert.equal("3d_armor_character.b3d", resolved)
		local legacy_resolved = player_api.resolve_model("skinsdb_3d_armor_character.b3d")
		assert.equal("3d_armor_character.b3d", legacy_resolved)
		assert.equal("3d_armor_character.b3d", player_api.resolve_model("skinsdb_3d_armor_character_5.glb"))
		assert.equal("3d_armor_character.b3d", player_api.resolve_model("skinsdb_3d_armor_character.glb"))

		-- Test 1.8 skin normalization (blank.png on slot 1, skin on slot 2, armor on slot 3, wield on slot 4)
		local player = mock_env.join_player("SkinsUser")
		x_player_api.set_model(player, "3d_armor_character.b3d")
		x_player_api.enable_wield_item = true

		player_api.set_textures(player, {
			"blank.png",
			"character_steve18.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})

		local textures = player_api.get_textures(player)
		assert.equal("character_steve18.png", textures[1])
		assert.equal("3d_armor_chestplate.png", textures[2])
		assert.equal("blank.png", textures[3]) -- Wield slot is blanked for 3D wield items, NEVER armor!

		-- Test 1.0 skin normalization (skin on slot 1, blank.png on slot 2)
		player_api.set_textures(player, {
			"character_alex10.png",
			"blank.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})

		local tex10 = player_api.get_textures(player)
		assert.equal("character_alex10.png", tex10[1])
		assert.equal("3d_armor_chestplate.png", tex10[2])
		assert.equal("blank.png", tex10[3])

		-- Test composite 1.8 skin with cape on slot 1
		player_api.set_textures(player, {
			"clothing_cape.png",
			"character_steve18.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})
		local tex_cape = player_api.get_textures(player)
		assert.equal("character_steve18.png^clothing_cape.png", tex_cape[1])
		assert.equal("3d_armor_chestplate.png", tex_cape[2])
		assert.equal("blank.png", tex_cape[3])

		-- Test composite 1.0 skin with clothing overlay on slot 2
		player_api.set_textures(player, {
			"character_alex10.png",
			"clothing_shirt.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})
		local tex_shirt = player_api.get_textures(player)
		assert.equal("character_alex10.png^clothing_shirt.png", tex_shirt[1])
		assert.equal("3d_armor_chestplate.png", tex_shirt[2])
		assert.equal("blank.png", tex_shirt[3])

		-- Test 2D wield item preservation when enable_wield_item is false
		x_player_api.enable_wield_item = false
		player_api.set_textures(player, {
			"blank.png",
			"character_steve18.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})
		local tex_2d = player_api.get_textures(player)
		assert.equal("character_steve18.png", tex_2d[1])
		assert.equal("3d_armor_chestplate.png", tex_2d[2])
		assert.equal("wieldview_sword.png", tex_2d[3])
		x_player_api.enable_wield_item = true

		-- Test 1-slot model normalization (e.g. character.b3d)
		x_player_api.set_model(player, "character.b3d")
		player_api.set_textures(player, {
			"blank.png",
			"character_steve18.png",
			"3d_armor_chestplate.png",
			"wieldview_sword.png",
		})
		local tex_single = player_api.get_textures(player)
		assert.equal(1, #tex_single)
		assert.equal("character_steve18.png", tex_single[1])
	end)

	it("redirects skinsdb models to character.b3d when 3d_armor is not loaded", function()
		reset_bridge_env()
		core._enabled_mods["3d_armor"] = nil
		core._enabled_mods["skinsdb"] = true

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_skinsdb)
		assert.equal("character.b3d", player_api.resolve_model("skinsdb_3d_armor_character_5.b3d"))
		assert.equal("character.b3d", player_api.resolve_model("skinsdb_3d_armor_character.b3d"))
		assert.equal("character.b3d", player_api.resolve_model("skinsdb_3d_armor_character_5.glb"))
	end)

	it("skips skinsdb integration when setting is disabled", function()
		reset_bridge_env()
		core._enabled_mods["skinsdb"] = true
		core.settings:set_bool("x_player_bridge.enable_skinsdb", false)

		-- Clear redirect mapping
		player_api.model_redirects["skinsdb_3d_armor_character_5.b3d"] = nil

		dofile("init.lua")

		assert.is_false(x_player_bridge.config.enable_skinsdb)
		local resolved = player_api.resolve_model("skinsdb_3d_armor_character_5.b3d")
		assert.equal("skinsdb_3d_armor_character_5.b3d", resolved)
	end)

	it("loads shields integration and registers blocking predicate when enabled", function()
		reset_bridge_env()
		core._enabled_mods["shields"] = true
		core._enabled_mods["3d_armor"] = true

		local player = mock_env.join_player("ShieldKnight")
		armor.get_weared_armor_elements = function(_self, p)
			if p == player then
				return {shield = "shields:shield_wood"}
			end
			return {}
		end

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_shields)
		assert.is_not_nil(x_player_bridge.is_shield_equipped)
		assert.is_true(x_player_bridge.is_shield_equipped(player))

		-- Player holding a pickaxe (not a shield item) still blocks when RMB is pressed with equipped shield
		player.get_wielded_item = function()
			return {get_name = function() return "default:pick_steel" end}
		end
		player.get_player_control = function()
			return {RMB = true}
		end

		local state = player_api.get_player_state(player)
		assert.is_true(state.blocking)
		assert.equal("block", state.action)
	end)

	it("skips shields integration when setting is disabled", function()
		reset_bridge_env()
		core._enabled_mods["shields"] = true
		core.settings:set_bool("x_player_bridge.enable_shields", false)

		dofile("init.lua")

		assert.is_false(x_player_bridge.config.enable_shields)
	end)

	it("registers, orders, and queries modules in x_player_bridge registry", function()
		reset_bridge_env()
		dofile("init.lua")

		assert.is_not_nil(x_player_bridge.modules)
		assert.is_not_nil(x_player_bridge.register_module)
		assert.is_not_nil(x_player_bridge.get_module)

		-- Verify default modules are registered
		assert.is_not_nil(x_player_bridge.get_module("3d_armor"))
		assert.is_not_nil(x_player_bridge.get_module("wieldview"))
		assert.is_not_nil(x_player_bridge.get_module("skinsdb"))
		assert.is_not_nil(x_player_bridge.get_module("shields"))
		assert.is_not_nil(x_player_bridge.get_module("simple_skins"))
		assert.is_not_nil(x_player_bridge.get_module("clothing"))
		assert.is_not_nil(x_player_bridge.get_module("wield3d"))
		assert.is_not_nil(x_player_bridge.get_module("bows"))
		assert.is_not_nil(x_player_bridge.get_module("stamina"))
		assert.is_not_nil(x_player_bridge.get_module("hangglider"))
		assert.is_not_nil(x_player_bridge.get_module("flyswim_compat"))
		assert.is_not_nil(x_player_bridge.get_module("emote"))

		-- Test registering a custom module
		local custom_inited = false
		local registered = x_player_bridge.register_module({
			id = "test_module",
			description = "Test Module",
			priority = 10,
			init = function()
				custom_inited = true
				return true
			end,
		})
		assert.is_true(registered)
		assert.is_not_nil(x_player_bridge.get_module("test_module"))
		x_player_bridge.init_modules()
		assert.is_true(custom_inited)

		-- Test duplicate registration prevention
		local dup = x_player_bridge.register_module({ id = "test_module" })
		assert.is_false(dup)
	end)

	it("integrates wield3d and suppresses external entity updates when native 3D wield items are enabled", function()
		reset_bridge_env()
		core._enabled_mods["wield3d"] = true

		local updated_entity = false
		rawset(_G, "wield3d", {
			update_entity = function(_player)
				updated_entity = true
			end,
		})

		player_api.enable_wield_item = true
		dofile("init.lua")
		for _, fn in ipairs(core._on_mods_loaded or {}) do fn() end

		assert.is_true(x_player_bridge.config.enable_wield3d)
		local player = mock_env.create_player("Wielder")

		-- Calling wield3d.update_entity while native 3D is active should be suppressed
		wield3d.update_entity(player)
		assert.is_false(updated_entity)

		-- Disabling native 3D should restore external update
		player_api.set_wield_item_enabled(false)
		wield3d.update_entity(player)
		assert.is_true(updated_entity)
	end)

	it("integrates simple_skins and synchronizes proxy textures on join", function()
		reset_bridge_env()
		core._enabled_mods["simple_skins"] = true

		rawset(_G, "skins", {
			skins = { ["SkinUser"] = "character_1" },
			get_skin_texture = function(_self, _name)
				return "character_1.png"
			end,
		})

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_simple_skins)
		local player = mock_env.join_player("SkinUser")
		assert.is_not_nil(player)
	end)

	it("integrates clothing mod and synchronizes composite wardrobe textures", function()
		reset_bridge_env()
		core._enabled_mods["clothing"] = true

		rawset(_G, "clothing", {
			player_textures = { ["Tailor"] = "clothing_shirt.png" },
		})

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_clothing)
		local player = mock_env.join_player("Tailor")
		assert.is_not_nil(player)
	end)

	it("integrates external bows mod and registers aiming and shoot actions", function()
		reset_bridge_env()
		core._enabled_mods["bows"] = true

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_bows)
		local player = mock_env.join_player("Archer")
		player.get_wielded_item = function()
			return { get_name = function() return "bows:bow_wood" end }
		end
		player.get_player_control = function()
			return { RMB = true }
		end

		local state = player_api.get_player_state(player)
		assert.is_true(state.aiming_bow)
		assert.equal("bow_aim", state.action)
	end)

	it("integrates stamina mod and maps sprint animation state", function()
		reset_bridge_env()
		core._enabled_mods["stamina"] = true

		rawset(_G, "stamina", {
			is_sprinting = function(player)
				return player:get_player_name() == "Sprinter"
			end,
		})

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_stamina)
		local player = mock_env.join_player("Sprinter")
		player.get_player_control = function()
			return { up = true }
		end

		local state = player_api.get_player_state(player)
		assert.equal("sprint", state.locomotion)
	end)

	it("integrates hangglider mod and triggers glide animation state", function()
		reset_bridge_env()
		core._enabled_mods["hangglider"] = true

		rawset(_G, "hangglider", {
			gliding = { ["Pilot"] = true },
		})

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_hangglider)
		local player = mock_env.join_player("Pilot")

		local state = player_api.get_player_state(player)
		assert.is_true(state.gliding)
	end)

	it("integrates emote mod and maps emote gestures to x_player_api actions", function()
		reset_bridge_env()
		core._enabled_mods["emote"] = true

		rawset(_G, "emote", {
			action = function(_player, _anim) end,
		})

		dofile("init.lua")

		assert.is_true(x_player_bridge.config.enable_emote)
		local player = mock_env.join_player("Socialite")

		emote.action(player, "wave")
		local state = player_api.get_player_state(player)
		assert.equal("wave", state.action)
	end)

	it("verifies 3d_armor_character.glb bow animation keeps Body translation locked and counter-rotates legs", function()
		local f = io.open("models/3d_armor_character.glb", "rb")
		assert.is_not_nil(f, "models/3d_armor_character.glb must be readable")
		local data = f:read("*all")
		f:close()

		local json_len = mock_env.read_u32_le(data, 13)
		assert.is_true(json_len > 0, "JSON length must be positive")
		local json_str = data:sub(21, 20 + json_len)
		local parsed = core.parse_json(json_str)
		assert.is_not_nil(parsed, "Failed to parse 3d_armor_character.glb JSON chunk")

		local bin_data_start = 21 + json_len + 8

		local bow_anim
		for _, a in ipairs(parsed.animations or {}) do
			if a.name == "bow" then
				bow_anim = a
				break
			end
		end
		assert.is_not_nil(bow_anim, "bow animation not found in 3d_armor_character.glb")

		local body_trans_ch, leg_r_rot_ch, leg_l_rot_ch
		for _, ch in ipairs(bow_anim.channels) do
			local node_name = parsed.nodes[ch.target.node + 1].name
			local path = ch.target.path
			if node_name == "Body" and path == "translation" then
				body_trans_ch = ch
			elseif node_name == "Leg_Right" and path == "rotation" then
				leg_r_rot_ch = ch
			elseif node_name == "Leg_Left" and path == "rotation" then
				leg_l_rot_ch = ch
			end
		end

		assert.is_not_nil(body_trans_ch, "Body translation channel missing in bow")
		assert.is_not_nil(leg_r_rot_ch, "Leg_Right rotation channel missing in bow")
		assert.is_not_nil(leg_l_rot_ch, "Leg_Left rotation channel missing in bow")

		-- Body translation locked to 6.75
		local bt_sampler = bow_anim.samplers[body_trans_ch.sampler + 1]
		local bt_acc = parsed.accessors[bt_sampler.output + 1]
		local bt_bv = parsed.bufferViews[bt_acc.bufferView + 1]
		local bt_offset = bin_data_start + (bt_bv.byteOffset or 0) + (bt_acc.byteOffset or 0)
		assert.equal(4, bt_acc.count, "Body translation should have 4 keyframes")

		for k = 0, bt_acc.count - 1 do
			local x = mock_env.read_f32_le(data, bt_offset + k * 12)
			local y = mock_env.read_f32_le(data, bt_offset + k * 12 + 4)
			local z = mock_env.read_f32_le(data, bt_offset + k * 12 + 8)
			assert.is_true(math.abs(x - 0.0) < 1e-4, "Body translation x must be 0.0")
			assert.is_true(math.abs(y - 6.75) < 1e-3, "Body translation y must be locked to 6.75")
			assert.is_true(math.abs(z - 0.0) < 1e-4, "Body translation z must be 0.0")
		end

		-- Legs counter-rotation
		local function verify_leg_rot(ch, leg_name)
			local sampler = bow_anim.samplers[ch.sampler + 1]
			local acc = parsed.accessors[sampler.output + 1]
			local bv = parsed.bufferViews[acc.bufferView + 1]
			local offset = bin_data_start + (bv.byteOffset or 0) + (acc.byteOffset or 0)
			assert.equal(4, acc.count, leg_name .. " should have 4 rotation keyframes")

			for _, k in ipairs({0, 3}) do
				local x = mock_env.read_f32_le(data, offset + k * 16)
				local y = mock_env.read_f32_le(data, offset + k * 16 + 4)
				local z = mock_env.read_f32_le(data, offset + k * 16 + 8)
				local w = mock_env.read_f32_le(data, offset + k * 16 + 12)
				assert.is_true(math.abs(math.abs(x) - 1.0) < 1e-4, leg_name .. " rest rot x must be 1.0 at key " .. k)
				assert.is_true(math.abs(y - 0.0) < 1e-4, leg_name .. " rest rot y must be 0.0 at key " .. k)
				assert.is_true(math.abs(z - 0.0) < 1e-4, leg_name .. " rest rot z must be 0.0 at key " .. k)
				assert.is_true(math.abs(w - 0.0) < 1e-4, leg_name .. " rest rot w must be 0.0 at key " .. k)
			end

			for _, k in ipairs({1, 2}) do
				local x = mock_env.read_f32_le(data, offset + k * 16)
				local y = mock_env.read_f32_le(data, offset + k * 16 + 4)
				local z = mock_env.read_f32_le(data, offset + k * 16 + 8)
				local w = mock_env.read_f32_le(data, offset + k * 16 + 12)
				assert.is_true(math.abs(math.abs(x) - 0.965926) < 1e-3, leg_name .. " counter rot x mismatch at key " .. k)
				assert.is_true(math.abs(y - 0.0) < 1e-4, leg_name .. " counter rot y mismatch at key " .. k)
				assert.is_true(math.abs(z - 0.0) < 1e-4, leg_name .. " counter rot z mismatch at key " .. k)
				assert.is_true(math.abs(math.abs(w) - 0.258819) < 1e-3, leg_name .. " counter rot w mismatch at key " .. k)
				assert.is_true(x * w < 0, leg_name .. " counter rot pitch sign must be opposite at key " .. k)
			end
		end

		verify_leg_rot(leg_r_rot_ch, "Leg_Right")
		verify_leg_rot(leg_l_rot_ch, "Leg_Left")
	end)

	-- Restore original environment
	core.get_current_modname = orig_get_modname
	core.get_modpath = orig_get_modpath
end)

local ok = framework.run()
if not ok then
	os.exit(1)
end
