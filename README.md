# Luanti mod: x_player_bridge

![x_player_bridge Rig Animation Showcase](screenshot.png)

Showcase bridge mod demonstrating seamless integration between `x_player_api`'s dual-model visual architecture and popular third-party player visual and equipment mods such as `3d_armor`, `wieldview`, and `skinsdb`.

---

## Overview

`x_player_api` introduces a dual-model architecture serving modern glTF multi-track animations (`.glb`) to Luanti 5.17.0+ clients while seamlessly falling back to legacy single-timeline Blitz3D models (`.b3d`) for older clients on the same multiplayer server.

Because legacy mods historically assume hardcoded `.b3d` meshes and single-timeline animation ranges, `x_player_bridge` serves as an integration pattern demonstrating how to:
- Register dual-model definitions that provide both modern `.glb` multi-track configurations and legacy `.b3d` frame mappings, inheriting animations and hitboxes from `character.b3d`.
- Hook third-party visual update pipelines (`armor.update_player_visuals`) to ensure composited armor textures and attachments correctly resolve to the dual visual proxy entities (`x_player_api:visual_glb` and `x_player_api:visual_b3d`).
- Leverage model redirects (`x_player_api.register_model_redirect`) for transparent mapping without monkey-patching core functions.
- Maintain a clean, modular structure where each third-party mod integration is isolated in its own file and can be toggled on or off via configuration settings.

---

## Architecture & File Structure

The mod is structured with dedicated modules per third-party mod integration:

* `init.lua`: Main entry point. Reads configuration settings, exposes the `x_player_bridge` global state table, and conditionally loads active integration modules.
* `3d_armor.lua`: Registers `3d_armor_character.b3d` with `base_model = "character.b3d"` and hooks `armor.update_player_visuals` to preserve dual visual proxies.
* `wieldview.lua`: Suppresses legacy 2D wieldview compositing to avoid duplicate item rendering when `x_player_api`'s 3D wield items are enabled.
* `skinsdb.lua`: Registers model redirect from `skinsdb_3d_armor_character_5.b3d` to the dual-model `3d_armor_character.b3d`.
* `settingtypes.txt`: Exposes toggles in the Luanti Settings menu to enable or disable individual integrations.

---

## Configuration Settings

Each mod integration can be independently enabled or disabled. This allows server administrators or upstream mod authors to disable specific bridge hooks if an upstream mod implements `x_player_api` support natively.

| Setting | Type | Default | Description |
|---|---|---|---|
| `x_player_bridge.enable_3d_armor` | bool | `true` | Enable `3d_armor` dual-model registration and visual hook |
| `x_player_bridge.enable_wieldview` | bool | `true` | Enable `wieldview` 2D compositing suppression hook |
| `x_player_bridge.enable_skinsdb` | bool | `true` | Enable `skinsdb` model redirect to dual-model character |

Settings can also be configured directly in `luanti.conf`:
```conf
# Disable 3D Armor bridge if 3d_armor implements x_player_api directly
x_player_bridge.enable_3d_armor = false

# Disable Wieldview bridge
x_player_bridge.enable_wieldview = false

# Disable SkinsDB bridge
x_player_bridge.enable_skinsdb = false
```

---

## Supported Integrations

### `3d_armor` (`3d_armor.lua`)
When `3d_armor` is installed and `x_player_bridge.enable_3d_armor = true`:
* Bundles `3d_armor_character.b3d` and `3d_armor_character.glb` inside `models/` so `x_player_api` remains completely mod-agnostic.
* Registers a dual-model definition for `3d_armor_character.b3d` mapping `mesh = "3d_armor_character.b3d"` and `mesh_glb = "3d_armor_character.glb"`.
* Inherits all 28 character animation tracks and physical parameters from `character.b3d` via `base_model = "character.b3d"`.
* Hooks `armor.update_player_visuals` so that worn armor textures and models update across both visual proxies simultaneously.

### `wieldview` (`wieldview.lua`)
When `wieldview` is installed and `x_player_bridge.enable_wieldview = true`:
* Texture updates triggered via `player_api.set_texture()` are automatically dual-dispatched by `x_player_api` to both visual proxies.
* Automatically suppresses legacy 2D wieldview compositing on the player mesh (`wv.update_wielded_item` and armor texture layering) to prevent duplicate item rendering when `x_player_api`'s native 3D wield items are enabled.
* Wraps `player_api.set_wield_item_enabled` to maintain suppression whenever 3D wield items are toggled.

### `skinsdb` (`skinsdb.lua`)
When `skinsdb` is installed and `x_player_bridge.enable_skinsdb = true`:
* Transparently redirects `skinsdb_3d_armor_character_5.b3d` requests to the dual-model `3d_armor_character.b3d`, ensuring skinsdb users automatically receive modern glTF multi-track animations on 5.17.0+ clients.

---

## How to Add New Mod Bridges

To bridge additional third-party character or equipment mods, create a new module (e.g., `my_mod.lua`):

```lua
-- Check if target mod is active
if core.get_modpath("my_equipment_mod") then
    -- Register dual-model definition inheriting animations and physics from character.b3d
    x_player_api.register_model("my_custom_model.b3d", {
        base_model = "character.b3d",
        mesh = "my_custom_model.b3d",
        mesh_glb = "my_custom_model.glb",
        textures = {"character.png", "my_equipment_overlay.png"},
    })

    -- Register a model redirect if the external mod requests the legacy model name
    x_player_api.register_model_redirect("my_custom_model.b3d", "my_custom_model.b3d")
end
```

Then add the corresponding setting to `settingtypes.txt` and load the module conditionally in `init.lua`.

---

## License

See `license.txt` for license details (LGPLv2.1+ code, CC BY-SA 3.0 media).
