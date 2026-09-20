# X Player Bridge [x_player_bridge]

[![ContentDB](https://content.luanti.org/packages/SaKeL/x_player_bridge/shields/title/)](https://content.luanti.org/packages/SaKeL/x_player_bridge/)
[![ContentDB Downloads](https://content.luanti.org/packages/SaKeL/x_player_bridge/shields/downloads/)](https://content.luanti.org/packages/SaKeL/x_player_bridge/)
[![License: LGPL 2.1](https://img.shields.io/badge/License-LGPL_v2.1-blue.svg)](license.txt)
[![Media License: CC-BY 4.0](https://img.shields.io/badge/Media-CC_BY_4.0-lightgrey.svg)](license.txt)

Showcase bridge mod providing seamless integration between `x_player_api`'s dual-model visual architecture and popular player equipment, skin, and weapon mods such as `3d_armor`, `wieldview`, `skinsdb`, and `shields`.

![x_player_bridge Rig Animation Showcase](screenshot.png)

---

## Overview

`x_player_api` introduces an innovative dual-model architecture serving modern glTF multi-track animations (`.glb`) to Luanti 5.17.0+ clients while seamlessly falling back to legacy single-timeline Blitz3D models (`.b3d`) for older clients on the same multiplayer server.

Because legacy ecosystem mods historically assume hardcoded `.b3d` meshes and single-timeline animation ranges, `x_player_bridge` serves as an official integration layer that:
- **Preserves Multi-Track GLB Animations**: Prevents `3d_armor` and other visual mods from clobbering glTF named animation tracks and GPU bone blending on modern clients.
- **Synchronizes Dual Visual Proxies**: Automatically mirrors composited armor layers, skins, and textures across both `x_player_api:visual_glb` and `x_player_api:visual_b3d` child entities.
- **Includes Armor Character Models**: Bundles `3d_armor_character.glb` (with locked-feet bow animation) and `3d_armor_character.b3d` inside `models/` with canonical armor UV layout mapping.
- **Prevents Render Conflicts**: Dynamically disables redundant 2D wieldview hand compositing when `x_player_api`'s native 3D wield items are active.
- **Connects Combat Defenses**: Maps shield blocking mechanics (`shields` mod) into `x_player_api`'s upper-body defensive guard action (`block`).
- **Supports Transparent Redirection**: Maps legacy model names (e.g. `skinsdb_3d_armor_character_5.b3d`) to registered dual-format definitions without monkey-patching core engine functions.

---

## Supported Integrations

### 1. 3D Armor (`3d_armor.lua`)
When `3d_armor` is installed and `x_player_bridge.enable_3d_armor = true`:
* Registers `3d_armor_character.b3d` as a dual-model definition (`mesh = "3d_armor_character.b3d"`, `mesh_glb = "3d_armor_character.glb"`).
* Inherits all 28 character animation tracks, eye heights, and hitboxes directly from `character.b3d` via `base_model = "character.b3d"`.
* Intercepts `armor:update_player_visuals` to ensure composited armor textures (helmet, chestplate, leggings, boots) are synchronized to both visual proxies without dropping multi-track animation states.
* Synchronizes armor visuals automatically upon player reconnect.

### 2. Shields (`shields.lua`)
When `shields` is installed and `x_player_bridge.enable_shields = true`:
* Integrates shield defense mechanics into `x_player_api`'s action layer.
* When a player raises a shield to guard against incoming attacks, triggers the upper-body `block` action animation seamlessly while locomotion continues on the legs.

### 3. Wieldview (`wieldview.lua`)
When `wieldview` is installed and `x_player_bridge.enable_wieldview = true`:
* When `x_player_api.enable_wield_item = true`, automatically suppresses legacy 2D hand texture compositing on the player model to eliminate z-fighting, flickering, and duplicate rendered items.
* Dynamically re-enables 2D compositing if 3D wield items are toggled off in settings.

### 4. SkinsDB (`skinsdb.lua`)
When `skinsdb` is installed and `x_player_bridge.enable_skinsdb = true`:
* Transparently registers a model redirect from `skinsdb_3d_armor_character_5.b3d` to `3d_armor_character.b3d`.
* Ensures players selecting custom skins in SkinsDB receive high-fidelity glTF multi-track animations on modern clients and fallback single-timeline B3D animations on legacy clients.

---

## 3D Models & Locked-Foot Bow Animation

`x_player_bridge` bundles custom-rigged 3D character models in `models/` with standard 6-bone armatures and 3D Armor UV unwrapping:
- **`models/3d_armor_character.glb`**: Binary glTF 2.0 multi-track character model with separate bone-masked animation channels.
  - **Calibrated Bow Animation**: The `bow` animation track keeps pelvis root translation locked at `(0, 0, 0)` while counter-rotating leg bones by `+30°`. When bowing, the character's upper body bends respectfully while both feet remain firmly anchored to the floor without shifting, sliding, or hovering.
- **`models/3d_armor_character.b3d`**: Legacy Blitz3D single-timeline model for older client compatibility.
- **`assets/3d_armor_character.blend`**: Master Blender authoring file.
- **`scripts/adjust_bow_animation.py`**: Automated headless Blender script used to export the locked-foot bow animation to glTF.

---

## Configuration Settings

Each integration can be independently enabled or disabled via the in-game Settings menu (**Settings -> All Settings -> Mods -> x_player_bridge**) or directly in `luanti.conf`:

| Setting | Type | Default | Description |
|---|---|---|---|
| `x_player_bridge.enable_3d_armor` | bool | `true` | Enable `3d_armor` dual-model registration and texture interception |
| `x_player_bridge.enable_wieldview` | bool | `true` | Enable `wieldview` 2D compositing suppression hook |
| `x_player_bridge.enable_skinsdb` | bool | `true` | Enable `skinsdb` model redirect to dual-model character |
| `x_player_bridge.enable_shields` | bool | `true` | Enable `shields` defensive blocking action mapping |

Example `luanti.conf`:
```conf
# Disable 3D Armor bridge if 3d_armor implements x_player_api directly
x_player_bridge.enable_3d_armor = true

# Disable Wieldview bridge
x_player_bridge.enable_wieldview = true

# Disable SkinsDB bridge
x_player_bridge.enable_skinsdb = true

# Enable Shields bridge
x_player_bridge.enable_shields = true
```

---

## Testing & Quality Assurance

`x_player_bridge` includes a modular BDD unit test suite verifying all bridge hooks, lifecycle events, and binary GLB animation curve constraints.

To run the test suite:
```bash
lua test.lua
```

### Verified Test Matrix
- `3d_armor` integration loading and player visual texture synchronization.
- Player reconnect inventory and visual state restoration.
- GLB mesh and multi-track animation retention when `3d_armor` registers before bridge.
- Dynamic 2D wieldview compositing suppression when 3D wield items are active.
- `skinsdb` model redirection and fallback handling.
- `shields` blocking predicate registration.
- Disabling integrations via configuration settings.
- Binary GLB curve evaluation confirming `3d_armor_character.glb` keeps `Body` translation locked to zero and counter-rotates legs during the bow animation.

---

## Installation

### From ContentDB
Search for **X Player Bridge** in the Luanti online content repository and click **Install**.

### From Git
Clone into your Luanti `mods/` directory:
```bash
git clone https://github.com/sakel-hub/x_player_bridge.git
```

Ensure `x_player_api` is installed and enabled in your world.

---

## License

- **Code**: LGPL-2.1-or-later (see `license.txt`)
- **Media & Models**: CC-BY-4.0 (see `license.txt`)
