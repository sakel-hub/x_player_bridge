local modname = core.get_current_modname()
core.log("action", "[" .. modname .. "] Initializing skinsdb model redirect for 3d_armor character")

-- Redirect skinsdb 3d_armor mesh identifiers to our registered dual-model character
x_player_api.register_model_redirect("skinsdb_3d_armor_character_5.b3d", "3d_armor_character.b3d")
x_player_api.register_model_redirect("skinsdb_3d_armor_character.b3d", "3d_armor_character.b3d")
x_player_api.register_model_redirect("skinsdb_3d_armor_character_5.glb", "3d_armor_character.b3d")
x_player_api.register_model_redirect("skinsdb_3d_armor_character.glb", "3d_armor_character.b3d")
