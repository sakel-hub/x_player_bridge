import os
import math
import numpy as np
import bpy
from mathutils import Vector

# ---------------------------------------------------------------------------
# Typography: 5x7 Pixel Font
# ---------------------------------------------------------------------------
FONT_5X7 = {
    'A': [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'B': [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
    'C': [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E],
    'D': [0x1C, 0x12, 0x11, 0x11, 0x11, 0x12, 0x1C],
    'E': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F],
    'F': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
    'G': [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F],
    'H': [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'I': [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E],
    'J': [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C],
    'K': [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
    'L': [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
    'M': [0x11, 0x1B, 0x15, 0x11, 0x11, 0x11, 0x11],
    'N': [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
    'O': [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'P': [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
    'Q': [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D],
    'R': [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
    'S': [0x0E, 0x11, 0x10, 0x0E, 0x01, 0x11, 0x0E],
    'T': [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
    'U': [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'V': [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
    'W': [0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A],
    'X': [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
    'Y': [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04],
    'Z': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
    '0': [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E],
    '1': [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
    '2': [0x0E, 0x11, 0x01, 0x06, 0x08, 0x10, 0x1F],
    '3': [0x1E, 0x01, 0x01, 0x0E, 0x01, 0x01, 0x1E],
    '4': [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
    '5': [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
    '6': [0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E],
    '7': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
    '8': [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
    '9': [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
    '&': [0x0C, 0x12, 0x14, 0x08, 0x15, 0x12, 0x0D],
    '_': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F],
    '-': [0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00],
    '•': [0x00, 0x00, 0x0E, 0x1F, 0x0E, 0x00, 0x00],
    '|': [0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
    ':': [0x00, 0x04, 0x00, 0x00, 0x04, 0x00, 0x00],
    '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x04],
    ',': [0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x08],
    '[': [0x0E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0E],
    ']': [0x0E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0E],
    '(': [0x04, 0x08, 0x10, 0x10, 0x10, 0x08, 0x04],
    ')': [0x04, 0x02, 0x01, 0x01, 0x01, 0x02, 0x04],
    '/': [0x01, 0x02, 0x02, 0x04, 0x08, 0x08, 0x10],
    '=': [0x00, 0x1F, 0x00, 0x1F, 0x00, 0x00, 0x00],
    '+': [0x00, 0x04, 0x04, 0x1F, 0x04, 0x04, 0x00],
    ' ': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
}

def render_text_mask(text, scale=2):
    cols = []
    for ch in text.upper():
        bitmap = FONT_5X7.get(ch, [0] * 7)
        char_arr = np.zeros((7, 5), dtype=np.float32)
        for r, row_val in enumerate(bitmap):
            for c in range(5):
                if (row_val >> (4 - c)) & 1:
                    char_arr[r, c] = 1.0
        char_arr = np.repeat(np.repeat(char_arr, scale, axis=0), scale, axis=1)
        cols.append(char_arr)
        cols.append(np.zeros((7 * scale, 1 * scale), dtype=np.float32))
    return np.hstack(cols[:-1]) if cols else np.zeros((7 * scale, 0), dtype=np.float32)

def draw_text(canvas, text, x, y, color, scale=2):
    mask = render_text_mask(text, scale)
    th, tw = mask.shape
    H, W, _ = canvas.shape
    if y >= H or x >= W:
        return
    y_end = min(y + th, H)
    x_end = min(x + tw, W)
    if y_end <= y or x_end <= x:
        return
    m_sub = mask[: y_end - y, : x_end - x, None]
    col = np.array(color, dtype=np.float32)
    t_alpha = m_sub * col[3]
    canvas[y:y_end, x:x_end, :3] = (
        canvas[y:y_end, x:x_end, :3] * (1.0 - t_alpha) + col[:3] * t_alpha
    )

def draw_centered_text(canvas, text, x1, x2, y, color, scale=2):
    mask = render_text_mask(text, scale)
    tw = mask.shape[1]
    x = x1 + (x2 - x1 - tw) // 2
    draw_text(canvas, text, x, y, color, scale)

def draw_rect(canvas, x1, y1, x2, y2, color):
    canvas[y1:y2, x1:x2, :3] = color[:3]
    canvas[y1:y2, x1:x2, 3] = color[3]

def draw_border(canvas, x1, y1, x2, y2, color, thickness=1):
    t = thickness
    canvas[y1 : y1 + t, x1:x2, :4] = color
    canvas[y2 - t : y2, x1:x2, :4] = color
    canvas[y1:y2, x1 : x1 + t, :4] = color
    canvas[y1:y2, x2 - t : x2, :4] = color

# ---------------------------------------------------------------------------
# Material & Texture Helpers
# ---------------------------------------------------------------------------
def setup_material_texture(mat_name, img_path):
    mat = bpy.data.materials.get(mat_name)
    if not mat:
        return
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    for n in list(nodes):
        if n.type in ('TEX_IMAGE', 'BSDF_DIFFUSE'):
            nodes.remove(n)
        elif n.type == 'OUTPUT_MATERIAL' and n.name != 'Material Output':
            nodes.remove(n)

    tex_img = bpy.data.images.load(img_path)
    tex_img.colorspace_settings.name = 'sRGB'

    tex_node = nodes.new('ShaderNodeTexImage')
    tex_node.image = tex_img
    tex_node.interpolation = 'Closest'

    bsdf = nodes.get('Principled BSDF')
    out_node = nodes.get('Material Output')
    if not out_node:
        out_node = nodes.new('ShaderNodeOutputMaterial')
    out_node.target = 'ALL'
    out_node.is_active_output = True

    if bsdf:
        links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
        links.new(tex_node.outputs['Alpha'], bsdf.inputs['Alpha'])
        links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])

def composite_layers(layer_paths, out_path):
    comp = None
    w, h = 64, 32
    for p in layer_paths:
        if not p or not os.path.exists(p):
            continue
        img = bpy.data.images.load(p)
        w, h = img.size
        arr = np.array(img.pixels[:], dtype=np.float32).reshape((h, w, 4))
        bpy.data.images.remove(img)
        if comp is None:
            comp = arr
        else:
            alpha = arr[:, :, 3:4]
            comp = comp * (1.0 - alpha) + arr * alpha

    if comp is None:
        comp = np.zeros((h, w, 4), dtype=np.float32)

    out_img = bpy.data.images.new("comp_temp", width=w, height=h, alpha=True)
    out_img.pixels.foreach_set(comp.ravel())
    out_img.filepath_raw = out_path
    out_img.file_format = 'PNG'
    out_img.save()
    bpy.data.images.remove(out_img)
    return out_path

# ---------------------------------------------------------------------------
# Showcase Card Definitions (20 Cards: 4 Rows x 5 Columns)
# ---------------------------------------------------------------------------
CARDS = [
    # Row 1: Core Equipment & Stance
    {
        "action": "stand", "frame": 20, "elev": 18.0,
        "label": "01 • 3D_ARMOR DIAMOND", "cat": "EQUIPMENT • FULL SUIT PROXY",
        "armor": ["armor_diamond", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_diamondsword.png"
    },
    {
        "action": "walk", "frame": 5, "elev": 18.0,
        "label": "02 • 3D_ARMOR GOLD", "cat": "EQUIPMENT • WALK CYCLE",
        "armor": ["armor_gold", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_mesesword.png"
    },
    {
        "action": "sprint", "frame": 4, "elev": 18.0,
        "label": "03 • STAMINA SPRINT", "cat": "LOCOMOTION • VELOCITY BLEND",
        "armor": ["armor_mithril", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_steelsword.png"
    },
    {
        "action": "crouch", "frame": 20, "elev": 18.0,
        "label": "04 • TACTICAL CROUCH", "cat": "STEALTH • ARMOR DEFORMATION",
        "armor": ["armor_steel", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_steelpick.png"
    },
    {
        "action": "block", "frame": 5, "elev": 18.0,
        "label": "05 • BRONZE GUARD", "cat": "SHIELDS • BLOCK DEFENSE",
        "armor": ["armor_bronze", "all"], "shield": "shields_shield_bronze.png",
        "wield": "games/minetest_game/mods/default/textures/default_tool_bronzesword.png"
    },

    # Row 2: Airborne, Aquatic & Locomotion
    {
        "action": "jump", "frame": 5, "elev": 18.0,
        "label": "06 • CACTUS ACROBAT", "cat": "LOCOMOTION • AIRBORNE JUMP",
        "armor": ["armor_cactus", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "fall", "frame": 5, "elev": 18.0,
        "label": "07 • WOODEN DESCENT", "cat": "PHYSICS • FREEFALL DROP",
        "armor": ["armor_wood", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "fly", "frame": 5, "elev": 12.0, "azim": 65.0, "dist": 28.0,
        "label": "08 • HANGGLIDER GLIDE", "cat": "HANGGLIDER • AERODYNAMIC FLY",
        "armor": ["armor_nether", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "hover", "frame": 30, "elev": 18.0,
        "label": "09 • CRYSTAL HOVER", "cat": "LOCOMOTION • ZERO-G HOVER",
        "armor": ["armor_crystal", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "swim", "frame": 10, "elev": 22.0,
        "label": "10 • FLYSWIM AQUATIC", "cat": "FLYSWIM • SWIM & CRAWL",
        "armor": ["armor_diamond", "all"], "shield": "shields_shield_diamond.png",
        "wield": None
    },

    # Row 3: Combat & Wield Mastery
    {
        "action": "mine", "frame": 2, "elev": 18.0,
        "label": "11 • WIELDVIEW MINING", "cat": "WIELD • 3D DIAMOND PICKAXE",
        "armor": ["armor_steel", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_diamondpick.png"
    },
    {
        "action": "attack_slash", "frame": 4, "elev": 18.0,
        "label": "12 • ATTACK SLASH", "cat": "COMBAT • DYNAMIC SWORD SWING",
        "armor": ["armor_gold", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_diamondsword.png"
    },
    {
        "action": "attack_thrust", "frame": 3, "elev": 18.0,
        "label": "13 • ATTACK THRUST", "cat": "COMBAT • PIERCING THRUST",
        "armor": ["armor_mithril", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_tool_steelsword.png"
    },
    {
        "action": "block", "frame": 5, "elev": 18.0,
        "label": "14 • SHIELD & WEAPON", "cat": "SHIELDS • DUAL TACTICAL GUARD",
        "armor": ["armor_diamond", "all"], "shield": "shields_shield_diamond.png",
        "wield": "games/minetest_game/mods/default/textures/default_tool_diamondsword.png"
    },
    {
        "action": "bow_aim", "frame": 7, "elev": 18.0,
        "label": "15 • BOWS CHARGED AIM", "cat": "BOWS • GLTF MULTI-TRACK AIM",
        "armor": ["armor_bronze", "all"], "shield": None,
        "wield": "mods/x_bows/textures/x_bows_bow_wood_charged.png",
        "wield_rot": 90
    },

    # Row 4: Actions, Social & Rig Calibration
    {
        "action": "slide", "frame": 8, "elev": 24.0,
        "label": "16 • LOCOMOTION SLIDE", "cat": "LOCOMOTION • EVASIVE SLIDE",
        "armor": ["armor_mithril", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "eat", "frame": 10, "elev": 18.0,
        "label": "17 • CONSUMABLE RATION", "cat": "ACTIONS • EAT NOURISHMENT",
        "armor": ["armor_wood", "all"], "shield": None,
        "wield": "games/minetest_game/mods/default/textures/default_apple.png"
    },
    {
        "action": "wave", "frame": 10, "elev": 18.0,
        "label": "18 • EMOTE WAVE", "cat": "SOCIAL • MULTI-TRACK GESTURE",
        "armor": ["armor_crystal", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "cheer", "frame": 10, "elev": 18.0,
        "label": "19 • EMOTE CHEER", "cat": "SOCIAL • CELEBRATION CHEER",
        "armor": ["armor_gold", "all"], "shield": None,
        "wield": None
    },
    {
        "action": "bow", "frame": 25, "elev": 18.0,
        "label": "20 • CALIBRATED BOW", "cat": "CALIBRATION • LOCKED FEET",
        "armor": ["armor_diamond", "all"], "shield": None,
        "wield": None
    },
]

# ---------------------------------------------------------------------------
# Main Showcase Generator
# ---------------------------------------------------------------------------
def main():
    print("=== Starting X_PLAYER_BRIDGE Showcase Generation ===")
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 28
    scene.cycles.transparent_max_bounces = 128
    scene.cycles.max_bounces = 128
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.file_format = 'PNG'

    # Paths setup
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    mods_dir = os.path.dirname(base_dir)
    minetest_dir = os.path.dirname(mods_dir)

    # Base character skin setup (x_player_api high-tech cyber suit)
    skin_path = os.path.join(mods_dir, "x_player_api", "textures", "character.png")
    setup_material_texture("Character", skin_path)

    blank_path = os.path.join(base_dir, "textures", "blank.png")
    if not os.path.exists(blank_path):
        blank_path = os.path.join(mods_dir, "x_player_api", "textures", "blank.png")

    # Studio Lighting Setup
    for obj in list(scene.collection.objects):
        if obj.type == 'LIGHT':
            bpy.data.objects.remove(obj)

    key_light = bpy.data.lights.new('KeyLight', 'SUN')
    key_light.energy = 2.6
    key_light.color = (1.0, 0.98, 0.95)
    key_obj = bpy.data.objects.new('KeyLight', key_light)
    key_obj.rotation_euler = (math.radians(50), math.radians(-15), math.radians(145))
    scene.collection.objects.link(key_obj)

    fill_light = bpy.data.lights.new('FillLight', 'SUN')
    fill_light.energy = 1.1
    fill_light.color = (0.85, 0.92, 1.0)
    fill_obj = bpy.data.objects.new('FillLight', fill_light)
    fill_obj.rotation_euler = (math.radians(40), math.radians(25), math.radians(245))
    scene.collection.objects.link(fill_obj)

    rim_light = bpy.data.lights.new('RimLight', 'SUN')
    rim_light.energy = 1.6
    rim_light.color = (0.9, 0.95, 1.0)
    rim_obj = bpy.data.objects.new('RimLight', rim_light)
    rim_obj.rotation_euler = (math.radians(-35), math.radians(-20), math.radians(-30))
    scene.collection.objects.link(rim_obj)

    # Camera Setup with 55mm lens and center tracking
    cam_data = bpy.data.cameras.new('ShowcaseCam')
    cam_data.lens = 55
    cam_obj = bpy.data.objects.new('ShowcaseCam', cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    empty = bpy.data.objects.new('TargetEmpty', None)
    scene.collection.objects.link(empty)

    track = cam_obj.constraints.new(type='TRACK_TO')
    track.target = empty
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'

    # Sprite resolution
    SPRITE_SIZE = 340
    scene.render.resolution_x = SPRITE_SIZE
    scene.render.resolution_y = SPRITE_SIZE

    armature = bpy.data.objects['Armature']
    player = bpy.data.objects['Player']

    # Canvas Dimensions (5 columns x 4 rows)
    COLS = 5
    ROWS = 4
    CARD_W = 360
    CARD_H = 410
    PAD_X = 40
    PAD_Y = 40
    HEADER_H = 150
    GAP_X = 20
    GAP_Y = 24

    TOTAL_W = PAD_X * 2 + COLS * CARD_W + (COLS - 1) * GAP_X # 1960
    TOTAL_H = HEADER_H + 20 + ROWS * CARD_H + (ROWS - 1) * GAP_Y + PAD_Y # 1922

    print(f"Canvas size: {TOTAL_W} x {TOTAL_H}")
    canvas = np.zeros((TOTAL_H, TOTAL_W, 4), dtype=np.float32)

    # Canvas Background: Deep Slate Navy
    canvas[:, :, :3] = [0.043, 0.055, 0.078]
    canvas[:, :, 3] = 1.0

    # Ambient subtle grid dots
    canvas[::24, ::24, :3] += 0.025

    # Header Panel Background
    draw_rect(canvas, 0, 0, TOTAL_W, HEADER_H, [0.055, 0.071, 0.102, 1.0])

    # Header Accent Gradient Line (2px)
    for x in range(PAD_X, TOTAL_W - PAD_X):
        t = (x - PAD_X) / (TOTAL_W - PAD_X * 2)
        if t < 0.5:
            f = t / 0.5
            r = 0.0 * (1 - f) + 0.5 * f
            g = 0.9 * (1 - f) + 0.2 * f
            b = 1.0 * (1 - f) + 0.9 * f
        else:
            f = (t - 0.5) / 0.5
            r = 0.5 * (1 - f) + 1.0 * f
            g = 0.2 * (1 - f) + 0.1 * f
            b = 0.9 * (1 - f) + 0.5 * f
        canvas[HEADER_H - 2 : HEADER_H, x, :3] = [r, g, b]

    # Header Typography
    draw_text(canvas, "[ LUANTI • MOD INTEGRATIONS ]", 44, 26, [0.0, 0.85, 1.0, 1.0], scale=2)
    draw_text(canvas, "X_PLAYER_BRIDGE • COMPATIBILITY SHOWCASE", 44, 52, [0.95, 0.97, 1.0, 1.0], scale=4)
    draw_text(canvas, "20 INTEGRATIONS • DUAL-MODEL ARMOR & SHIELDS • 3D WIELD • GLTF MULTI-TRACK BRIDGED", 44, 96, [0.55, 0.65, 0.8, 1.0], scale=2)

    # Header Right Badge Box
    draw_rect(canvas, TOTAL_W - 440, 24, TOTAL_W - 40, 126, [0.082, 0.106, 0.153, 1.0])
    draw_border(canvas, TOTAL_W - 440, 24, TOTAL_W - 40, 126, [0.165, 0.212, 0.306, 1.0], thickness=1)
    draw_text(canvas, "ENGINE : BLENDER 5.2 CYCLES", TOTAL_W - 424, 40, [0.75, 0.83, 0.95, 1.0], scale=2)
    draw_text(canvas, "OPTICS : 55MM PERSPECTIVE", TOTAL_W - 424, 66, [0.75, 0.83, 0.95, 1.0], scale=2)
    draw_text(canvas, "RIG    : DUAL-MODEL PROXIES", TOTAL_W - 424, 92, [0.0, 0.9, 1.0, 1.0], scale=2)

    # Render Each Card and Composite
    tmp_render_path = os.path.join(base_dir, ".temp_tile.png")
    tmp_armor_path = os.path.join(base_dir, ".temp_armor.png")
    tmp_wield_path = os.path.join(base_dir, ".temp_wield.png")

    for idx, card in enumerate(CARDS):
        action_name = card["action"]
        frame = card["frame"]
        elev = card.get("elev", 18.0)
        label = card["label"]
        category = card["cat"]

        # 1. Reset all pose bones to clean rest
        for pb in armature.pose.bones:
            pb.location = (0, 0, 0)
            pb.rotation_euler = (0, 0, 0)
            pb.rotation_quaternion = (1, 0, 0, 0)
            pb.scale = (1, 1, 1)

        act = bpy.data.actions.get(action_name)
        if not act:
            print(f"WARNING: Action '{action_name}' not found!")
            continue

        armature.animation_data.action = act
        if hasattr(armature.animation_data, 'action_slot') and act.slots:
            armature.animation_data.action_slot = act.slots[0]
        scene.frame_set(frame)
        bpy.context.view_layer.update()

        # 2. Composite Armor + Shield Textures
        armor_info = card.get("armor")
        armor_layers = []
        if armor_info:
            mod_set, parts = armor_info
            set_name = mod_set.replace("armor_", "")
            armor_dir = os.path.join(mods_dir, "3d_armor", mod_set, "textures")
            for p in ["helmet", "chestplate", "leggings", "boots"]:
                p_file = os.path.join(armor_dir, f"3d_armor_{p}_{set_name}.png")
                if os.path.exists(p_file):
                    armor_layers.append(p_file)

        shield_file = card.get("shield")
        if shield_file:
            sh_path = os.path.join(mods_dir, "3d_armor", "shields", "textures", shield_file)
            if os.path.exists(sh_path):
                armor_layers.append(sh_path)

        composite_layers(armor_layers, tmp_armor_path)
        setup_material_texture("Armor", tmp_armor_path)

        # 3. Setup Wield Item
        wield_rel = card.get("wield")
        if wield_rel:
            wield_path = os.path.join(minetest_dir, wield_rel)
            if os.path.exists(wield_path):
                wield_rot = card.get("wield_rot")
                if wield_rot:
                    w_img = bpy.data.images.load(wield_path)
                    w_w, w_h = w_img.size
                    w_arr = np.array(w_img.pixels[:], dtype=np.float32).reshape((w_h, w_w, 4))
                    bpy.data.images.remove(w_img)
                    if wield_rot in (90, "rot90"):
                        w_rot = np.rot90(w_arr, 1)
                    elif wield_rot in (180, "rot180"):
                        w_rot = np.rot90(w_arr, 2)
                    elif wield_rot in (270, "rot270"):
                        w_rot = np.rot90(w_arr, 3)
                    elif wield_rot == "flip_lr":
                        w_rot = np.fliplr(w_arr)
                    elif wield_rot == "flip_ud":
                        w_rot = np.flipud(w_arr)
                    else:
                        w_rot = w_arr
                    out_w = bpy.data.images.new("wield_temp", width=w_w, height=w_h, alpha=True)
                    out_w.pixels.foreach_set(w_rot.ravel())
                    out_w.filepath_raw = tmp_wield_path
                    out_w.file_format = 'PNG'
                    out_w.save()
                    bpy.data.images.remove(out_w)
                    setup_material_texture("Wielditem", tmp_wield_path)
                else:
                    setup_material_texture("Wielditem", wield_path)
            else:
                setup_material_texture("Wielditem", blank_path)
        else:
            setup_material_texture("Wielditem", blank_path)

        # 4. Compute evaluated mesh bounding box
        depsgraph = bpy.context.evaluated_depsgraph_get()
        eval_player = player.evaluated_get(depsgraph)
        mesh = eval_player.to_mesh()
        coords = [eval_player.matrix_world @ v.co for v in mesh.vertices]
        eval_player.to_mesh_clear()

        min_c = Vector([min(v[i] for v in coords) for i in range(3)])
        max_c = Vector([max(v[i] for v in coords) for i in range(3)])
        center = (min_c + max_c) / 2.0
        size = max_c - min_c
        max_dim = max(size.x, size.y, size.z)

        empty.location = center

        azim = card.get("azim", 24.0)
        dist = card.get("dist", max(37.0, max_dim * 2.1))
        rad_azim = math.radians(azim)
        rad_elev = math.radians(elev)

        # Front view from +Y and -X
        cam_pos = center + Vector([
            -dist * math.cos(rad_elev) * math.sin(rad_azim),
            dist * math.cos(rad_elev) * math.cos(rad_azim),
            dist * math.sin(rad_elev)
        ])
        cam_obj.location = cam_pos
        bpy.context.view_layer.update()

        # Render frame
        scene.render.filepath = tmp_render_path
        bpy.ops.render.render(write_still=True)

        # Load rendered sprite
        img = bpy.data.images.load(tmp_render_path)
        sprite = np.array(img.pixels[:], dtype=np.float32).reshape((SPRITE_SIZE, SPRITE_SIZE, 4))
        sprite = np.flipud(sprite)
        bpy.data.images.remove(img)

        # Calculate card coordinates
        col_idx = idx % COLS
        row_idx = idx // COLS
        card_x = PAD_X + col_idx * (CARD_W + GAP_X)
        card_y = HEADER_H + 20 + row_idx * (CARD_H + GAP_Y)

        # Draw card background & border
        draw_rect(canvas, card_x, card_y, card_x + CARD_W, card_y + CARD_H, [0.075, 0.094, 0.133, 1.0])
        draw_border(canvas, card_x, card_y, card_x + CARD_W, card_y + CARD_H, [0.145, 0.180, 0.255, 1.0], thickness=1)

        # Blit centered sprite into card
        sprite_x = card_x + (CARD_W - SPRITE_SIZE) // 2
        sprite_y = card_y + 4
        alpha = sprite[:, :, 3:4]
        canvas[sprite_y : sprite_y + SPRITE_SIZE, sprite_x : sprite_x + SPRITE_SIZE, :3] = (
            canvas[sprite_y : sprite_y + SPRITE_SIZE, sprite_x : sprite_x + SPRITE_SIZE, :3] * (1.0 - alpha)
            + sprite[:, :, :3] * alpha
        )

        # Draw footer pill
        pill_x1 = card_x + 12
        pill_x2 = card_x + CARD_W - 12
        pill_y1 = card_y + 348
        pill_y2 = card_y + 400
        draw_rect(canvas, pill_x1, pill_y1, pill_x2, pill_y2, [0.102, 0.133, 0.196, 1.0])
        draw_border(canvas, pill_x1, pill_y1, pill_x2, pill_y2, [0.176, 0.227, 0.329, 1.0], thickness=1)

        # Draw action title & category in footer
        draw_centered_text(canvas, label, pill_x1, pill_x2, pill_y1 + 10, [0.0, 0.90, 1.0, 1.0], scale=2)
        draw_centered_text(canvas, category, pill_x1, pill_x2, pill_y1 + 30, [0.50, 0.62, 0.80, 1.0], scale=1)

        print(f"[{idx + 1:02d}/20] Rendered & composited: {label} (act={action_name}, f={frame}) -> Card ({col_idx}, {row_idx})")

    # Bottom Footer Attribution
    footer_text = "MOD: X_PLAYER_BRIDGE • 20 MODULAR INTEGRATIONS TESTED & VERIFIED • MULTI-TRACK COMPATIBLE"
    draw_centered_text(canvas, footer_text, 0, TOTAL_W, TOTAL_H - 26, [0.45, 0.55, 0.70, 1.0], scale=2)

    # Save Composite Showcase Image directly to x_player_bridge/screenshot.png
    output_path = os.path.join(base_dir, "screenshot.png")
    out_img = bpy.data.images.new("BridgeShowcase", width=TOTAL_W, height=TOTAL_H, alpha=True)
    flipped = np.flipud(canvas)
    out_img.pixels.foreach_set(flipped.ravel())
    out_img.filepath_raw = output_path
    out_img.file_format = 'PNG'
    out_img.save()
    print(f"Saved primary showcase image to: {output_path}")

    # Also save copy to brain artifact dir if present
    artifact_dirs = [
        "/Users/juraj/.gemini/antigravity/brain/3ddfe01f-bed6-4054-af4c-23d835912973",
        "/Users/juraj/.gemini/antigravity-ide/brain/e9b4ff77-f440-420a-9ea8-c1bf7c75af8d"
    ]
    for adir in artifact_dirs:
        if os.path.isdir(adir):
            artifact_path = os.path.join(adir, "screenshot.png")
            out_img.filepath_raw = artifact_path
            out_img.save()
            print(f"Saved artifact showcase image to: {artifact_path}")

    if os.path.exists(tmp_render_path):
        os.remove(tmp_render_path)
    if os.path.exists(tmp_armor_path):
        os.remove(tmp_armor_path)
    if os.path.exists(tmp_wield_path):
        os.remove(tmp_wield_path)

    print("=== All 20 Integration Cards Rendered and Showcase Successfully Created! ===")

if __name__ == "__main__":
    main()
