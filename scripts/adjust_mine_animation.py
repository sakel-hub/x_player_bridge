import bpy
import math
import os
from mathutils import Euler

def adjust_mine():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    blend_path = os.path.join(base_dir, "assets", "3d_armor_character.blend")
    print(f"Loading {blend_path}...")
    bpy.ops.wm.open_mainfile(filepath=blend_path)

    arm = bpy.data.objects.get("Armature")
    if not arm:
        raise RuntimeError("Armature object not found in 3d_armor_character.blend")

    # 1. Adjust 'mine' action:
    # Frame 2: arm held high and sideways (Euler 130, 0, 22 deg)
    act_mine = bpy.data.actions.get("mine")
    if not act_mine:
        raise RuntimeError("Action 'mine' not found")

    q_mine_2 = Euler((math.radians(130.0), 0.0, math.radians(22.0)), 'XYZ').to_quaternion()
    for l in act_mine.layers:
        for s in l.strips:
            for cb in s.channelbags:
                for fc in cb.fcurves:
                    if 'Arm_Right' in fc.data_path and 'rotation_quaternion' in fc.data_path:
                        idx = fc.array_index
                        for kp in fc.keyframe_points:
                            if round(kp.co[0]) == 2:
                                kp.co[1] = q_mine_2[idx]

    # 2. Adjust 'walk_mine' action:
    # Frames 1, 2, 3 (first swing) and 11, 12, 13 (second swing)
    act_wm = bpy.data.actions.get("walk_mine")
    if act_wm:
        q_peak = Euler((math.radians(130.0), 0.0, math.radians(22.0)), 'XYZ').to_quaternion()
        q_up = Euler((math.radians(105.0), 0.0, math.radians(10.0)), 'XYZ').to_quaternion()
        q_down = Euler((math.radians(97.3), 0.0, math.radians(8.0)), 'XYZ').to_quaternion()
        q_map = {1: q_up, 2: q_peak, 3: q_down, 11: q_up, 12: q_peak, 13: q_down}

        for l in act_wm.layers:
            for s in l.strips:
                for cb in s.channelbags:
                    for fc in cb.fcurves:
                        if 'Arm_Right' in fc.data_path and 'rotation_quaternion' in fc.data_path:
                            idx = fc.array_index
                            for kp in fc.keyframe_points:
                                kf = round(kp.co[0])
                                if kf in q_map:
                                    kp.co[1] = q_map[kf][idx]

    # Reset pose bones to rest pose and restore active action to stand
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)

    act_stand = bpy.data.actions.get("stand")
    if act_stand:
        arm.animation_data.action = act_stand

    # Save updated 3d_armor_character.blend
    print(f"Saving updated {blend_path}...")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print("3d_armor_character.blend saved successfully!")

    # Export 3d_armor_character.glb
    glb_path = os.path.join(base_dir, "models", "3d_armor_character.glb")
    print(f"Exporting multi-track glTF to {glb_path}...")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        export_animations=True,
        export_force_sampling=False,
        export_optimize_animation_keep_anim_armature=False,
    )
    print(f"3d_armor_character.glb exported successfully! File size: {os.path.getsize(glb_path)} bytes.")

if __name__ == "__main__":
    adjust_mine()
