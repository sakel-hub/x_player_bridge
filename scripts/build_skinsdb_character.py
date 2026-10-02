#!/usr/bin/env python3
"""
Build skinsdb 1.8 3D custom player model (.glb and .b3d) for x_player_bridge.
- Copies Format18 (and Format10, Armor, Wielditem) mesh geometry from skinsdb
- Binds to x_player_bridge Armature containing all 29 athletic animations
- Saves separate assets/skinsdb_3d_armor_character_5.blend
- Exports models/skinsdb_3d_armor_character_5.glb (multi-track glTF 2.0)
- Bakes contiguous timeline and exports models/skinsdb_3d_armor_character_5.b3d (Blitz3D)
"""

import sys
import os
import math
import subprocess
import struct
import json

def patch_glb_materials(glb_path):
    with open(glb_path, 'rb') as f:
        data = f.read()
    magic, version, _ = struct.unpack_from('<4sII', data, 0)
    chunk_len, chunk_type = struct.unpack_from('<II', data, 12)
    json_bytes = data[20:20+chunk_len]
    json_data = json.loads(json_bytes.decode('utf-8'))

    modified = False
    for mat in json_data.get('materials', []):
        if mat.get('alphaMode') != 'MASK' or mat.get('alphaCutoff') != 0.5:
            mat['alphaMode'] = 'MASK'
            mat['alphaCutoff'] = 0.5
            modified = True

    if modified:
        new_json_str = json.dumps(json_data, separators=(',', ':'))
        new_json_bytes = new_json_str.encode('utf-8')
        pad_len = (4 - (len(new_json_bytes) % 4)) % 4
        new_json_bytes += b' ' * pad_len
        new_chunk_len = len(new_json_bytes)

        bin_chunk = data[20+chunk_len:]
        new_total_len = 12 + 8 + new_chunk_len + len(bin_chunk)
        new_header = struct.pack('<4sII', magic, version, new_total_len)
        new_chunk_header = struct.pack('<II', new_chunk_len, chunk_type)

        with open(glb_path, 'wb') as f:
            f.write(new_header)
            f.write(new_chunk_header)
            f.write(new_json_bytes)
            f.write(bin_chunk)
        print(f"Patched {glb_path} materials to alphaMode: MASK (cutoff: 0.5)")

def main():
    bridge_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    mods_dir = os.path.dirname(bridge_dir)
    api_dir = os.path.join(mods_dir, "x_player_api")
    skinsdb_dir = os.path.join(mods_dir, "skinsdb")

    source_bridge_blend = os.path.join(bridge_dir, "assets", "3d_armor_character.blend")
    skinsdb_source_blend = os.path.join(skinsdb_dir, "models", "skinsdb_3d_armor_character_5.blend")

    dest_blend = os.path.join(bridge_dir, "assets", "skinsdb_3d_armor_character_5.blend")
    dest_glb = os.path.join(bridge_dir, "models", "skinsdb_3d_armor_character_5.glb")
    dest_b3d = os.path.join(bridge_dir, "models", "skinsdb_3d_armor_character_5.b3d")

    # Add x_player_api/assets to sys.path for export_b3d and build_character_b3d
    api_assets_dir = os.path.join(api_dir, "assets")
    if api_assets_dir not in sys.path:
        sys.path.append(api_assets_dir)

    import bpy
    import build_character_b3d
    import export_b3d

    print("==================================================")
    print(f"Loading base bridge blend: {source_bridge_blend}")
    bpy.ops.wm.open_mainfile(filepath=source_bridge_blend)

    # 1. Load Player mesh from skinsdb
    print(f"Importing 1.8 Player mesh from: {skinsdb_source_blend}")
    with bpy.data.libraries.load(skinsdb_source_blend) as (data_from, data_to):
        data_to.objects = ['Player']

    skins_player = data_to.objects[0]
    bpy.context.collection.objects.link(skins_player)

    # 2. Remove old player mesh
    orig_player = bpy.data.objects.get('Player')
    if orig_player:
        bpy.data.objects.remove(orig_player, do_unlink=True)

    # 3. Setup skins_player under Armature
    skins_player.name = 'Player'
    arm = bpy.data.objects.get('Armature')
    if not arm:
        raise RuntimeError("Armature not found in 3d_armor_character.blend")
    orig_inv = skins_player.matrix_parent_inverse.copy()
    skins_player.parent = arm
    skins_player.matrix_parent_inverse = orig_inv
    bpy.context.view_layer.update()

    mod = skins_player.modifiers.get('Armature')
    if not mod:
        mod = skins_player.modifiers.new(name='Armature', type='ARMATURE')
    mod.object = arm

    # 4. Canonicalize 4-slot materials
    # Slot 0: Format10
    # Slot 1: Format18
    # Slot 2: Armor
    # Slot 3: Wielditem
    mat_armor = bpy.data.materials.get('Armor')
    mat_wield = bpy.data.materials.get('Wielditem')
    old_armor = skins_player.data.materials[2]
    old_wield = skins_player.data.materials[3]

    if mat_armor:
        skins_player.data.materials[2] = mat_armor
    if mat_wield:
        skins_player.data.materials[3] = mat_wield

    if old_armor and old_armor != mat_armor:
        bpy.data.materials.remove(old_armor)
    if old_wield and old_wield != mat_wield:
        bpy.data.materials.remove(old_wield)

    print("Canonical material slots:", [m.name for m in skins_player.data.materials if m])

    # 5. Save the separate .blend file for skinsdb
    print(f"Saving separate skinsdb blend file: {dest_blend}")
    bpy.ops.wm.save_as_mainfile(filepath=dest_blend)

    # 6. Export GLB (multi-track animations)
    print(f"Exporting multi-track glTF: {dest_glb}")
    build_character_b3d.isolate_upper_body_actions(arm)
    bpy.ops.export_scene.gltf(
        filepath=dest_glb,
        export_format='GLB',
        export_animations=True,
        export_force_sampling=False,
        export_optimize_animation_keep_anim_armature=False,
    )
    print(f"GLB export finished. Size: {os.path.getsize(dest_glb)} bytes.")
    patch_glb_materials(dest_glb)

    # 7. Add walk_eat generator to ANIM_DEFS if not present
    if "walk_eat" not in build_character_b3d.ANIM_DEFS:
        def eval_walk_eat(t, dur):
            walk_pose = build_character_b3d.eval_walk(t % 20, 20)
            eat_pose = build_character_b3d.eval_eat(t % 20, 20)
            pose = dict(walk_pose)
            pose['Arm_Right'] = eat_pose['Arm_Right']
            pose['Head'] = eat_pose['Head']
            return pose
        build_character_b3d.register_anim('walk_eat', 746, 765, eval_walk_eat)

    # 8. Bake master contiguous timeline for B3D export
    print("Baking master contiguous timeline for B3D export...")
    build_character_b3d.bake_b3d_contiguous_timeline(arm)

    # 9. Export B3D
    print(f"Exporting Blitz3D: {dest_b3d}")
    settings = {
        'use_local_transform': False,
        'export_ambient': False,
        'enable_mipmaps': False,
        'use_selection': False,
        'use_visible': True,
        'use_collection': False,
        'object_mesh': True,
        'object_armature': True,
        'object_light': False,
        'object_camera': False,
        'export_texcoords': True,
        'export_materials': True,
        'export_normals': True,
    }
    export_b3d.save(None, bpy.context, dest_b3d, settings)
    print(f"B3D export finished. Size: {os.path.getsize(dest_b3d)} bytes.")

    # 10. Post-process B3D with wiggle_b3d.py
    wiggle_script = os.path.join(api_dir, "scripts", "wiggle_b3d.py")
    if os.path.isfile(wiggle_script):
        print(f"Applying Irrlicht rotation wiggler to {dest_b3d}...")
        subprocess.run([sys.executable, wiggle_script, dest_b3d], check=True)
        print("Wiggler applied successfully.")

    print("\nSkinsdb 1.8 model build completed successfully!")

if __name__ == "__main__":
    main()
