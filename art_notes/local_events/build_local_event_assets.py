import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "3d建模", "地方事件")
PREVIEW_DIR = os.path.join(ROOT, "art_notes", "local_events")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(PREVIEW_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def material(name, color, emission=0.0, roughness=0.78):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color[:3], color[3] if len(color) > 3 else 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = mat.diffuse_color
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = mat.diffuse_color
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def apply(obj, mat):
    if obj.data and hasattr(obj.data, "materials"):
        obj.data.materials.append(mat)
    return obj


def cube(name, location, scale, mat, bevel=0.08, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("SoftBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return apply(obj, mat)


def cylinder(name, location, radius, depth, mat, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return apply(obj, mat)


def cone(name, location, radius1, radius2, depth, mat, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return apply(obj, mat)


def ico(name, location, scale, mat, subdivisions=1, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return apply(obj, mat)


def torus(name, location, major_radius, minor_radius, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius, major_segments=12, minor_segments=6, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return apply(obj, mat)


def add_sign(text_name, x, y, z, wood, cream):
    cube(text_name + "PostsL", (x - 0.72, y, z + 0.62), (0.09, 0.09, 0.72), wood, 0.03)
    cube(text_name + "PostsR", (x + 0.72, y, z + 0.62), (0.09, 0.09, 0.72), wood, 0.03)
    cube(text_name + "Board", (x, y, z + 1.12), (0.92, 0.12, 0.36), cream, 0.09)


def add_lantern(location, frame, glow, scale=1.0):
    cylinder("LanternTop", (location[0], location[1], location[2] + 0.28 * scale), 0.16 * scale, 0.08 * scale, frame, 8)
    ico("LanternGlow", location, (0.25 * scale, 0.25 * scale, 0.34 * scale), glow, 1)
    cylinder("LanternBottom", (location[0], location[1], location[2] - 0.28 * scale), 0.15 * scale, 0.08 * scale, frame, 8)


def add_flag_line(points, wood, colors):
    for p in (points[0], points[-1]):
        cylinder("FlagPole", (p[0], p[1], 1.55), 0.055, 3.1, wood, 8)
    start, end = Vector(points[0]), Vector(points[-1])
    for idx in range(9):
        t = idx / 8.0
        p = start.lerp(end, t)
        p.z = 2.55 - 0.22 * math.sin(math.pi * t)
        cone("PartyFlag", p, 0.20, 0.0, 0.44, colors[idx % len(colors)], 3, rotation=(math.pi / 2, 0, 0))


def add_carrot(location, orange, green, scale=1.0):
    cone("Carrot", location, 0.13 * scale, 0.015, 0.55 * scale, orange, 8, rotation=(math.pi, 0, 0))
    for idx in range(3):
        leaf = ico("CarrotLeaf", (location[0], location[1], location[2] + 0.30 * scale), (0.05, 0.04, 0.24 * scale), green, 1)
        leaf.rotation_euler[2] = idx * math.tau / 3.0


def add_basket(location, wood, dark, contents=None):
    cube("BasketBase", location, (0.52, 0.38, 0.18), wood, 0.09)
    torus("BasketHandle", (location[0], location[1], location[2] + 0.35), 0.42, 0.045, dark, rotation=(math.pi / 2, 0, 0))
    if contents:
        for idx in range(5):
            add_carrot((location[0] - 0.28 + idx * 0.14, location[1], location[2] + 0.30), contents[0], contents[1], 0.56)


def add_rabbit(location, fur, inner, cloth, yaw=0.0):
    root = bpy.data.objects.new("RabbitRoot", None)
    bpy.context.collection.objects.link(root)
    root.location = location
    root.rotation_euler[2] = yaw
    body = ico("RabbitBody", (0, 0, 0.62), (0.48, 0.38, 0.67), cloth, 2)
    head = ico("RabbitHead", (0, 0, 1.38), (0.43, 0.39, 0.42), fur, 2)
    for obj in (body, head):
        obj.parent = root
    for side in (-1, 1):
        ear = ico("RabbitEar", (0.18 * side, 0, 1.92), (0.13, 0.10, 0.52), fur, 1, rotation=(0, side * 0.12, side * 0.08))
        ear.parent = root
        ear_in = ico("RabbitEarInner", (0.18 * side, -0.09, 1.94), (0.055, 0.03, 0.37), inner, 1, rotation=(0, side * 0.12, side * 0.08))
        ear_in.parent = root
        eye = ico("RabbitEye", (0.15 * side, -0.35, 1.46), (0.045, 0.035, 0.055), material("Eye", (0.07, 0.045, 0.025, 1)), 1)
        eye.parent = root
    nose = ico("RabbitNose", (0, -0.40, 1.32), (0.06, 0.04, 0.045), inner, 1)
    nose.parent = root
    tail = ico("RabbitTail", (0, 0.40, 0.72), (0.20, 0.18, 0.20), fur, 2)
    tail.parent = root
    return root


def common_materials():
    return {
        "wood": material("WarmWood", (0.34, 0.19, 0.08, 1)),
        "wood_light": material("LightWood", (0.62, 0.39, 0.17, 1)),
        "cream": material("PaintedSign", (0.84, 0.71, 0.47, 1)),
        "green": material("LeafGreen", (0.24, 0.53, 0.18, 1)),
        "orange": material("CarrotOrange", (0.94, 0.34, 0.06, 1)),
        "red": material("FestivalRed", (0.74, 0.12, 0.08, 1)),
        "yellow": material("FestivalGold", (0.96, 0.68, 0.16, 1)),
        "teal": material("FestivalTeal", (0.12, 0.55, 0.50, 1)),
        "lantern": material("LanternGlow", (1.0, 0.47, 0.10, 1), 3.6),
    }


def build_rabbit_party():
    mats = common_materials()
    blanket_a = material("BlanketCream", (0.88, 0.70, 0.43, 1))
    blanket_b = material("BlanketRed", (0.66, 0.16, 0.10, 1))
    fur = material("RabbitFur", (0.78, 0.70, 0.58, 1))
    pink = material("RabbitInner", (0.90, 0.52, 0.55, 1))
    cube("PicnicBlanket", (0, 0, 0.035), (2.35, 1.65, 0.035), blanket_a, 0.02)
    for idx in range(-4, 5):
        cube("BlanketStripe", (idx * 0.52, 0, 0.075), (0.10, 1.64, 0.015), blanket_b, 0.01)
    add_rabbit((-1.20, -0.25, 0), fur, pink, material("ApronGreen", (0.31, 0.56, 0.24, 1)), 0.18)
    add_rabbit((0.15, 0.35, 0), fur, pink, material("ApronOchre", (0.78, 0.47, 0.16, 1)), -0.22)
    add_rabbit((1.35, -0.10, 0), fur, pink, material("ApronBlue", (0.24, 0.46, 0.62, 1)), 0.08)
    add_basket((-2.55, 1.30, 0.34), mats["wood_light"], mats["wood"], (mats["orange"], mats["green"]))
    add_basket((2.55, 1.15, 0.34), mats["wood_light"], mats["wood"], (mats["orange"], mats["green"]))
    add_sign("RabbitParty", 0, 2.6, 0, mats["wood"], mats["cream"])
    add_flag_line(((-3.8, -2.2, 0), (3.8, -2.2, 0)), mats["wood"], [mats["red"], mats["yellow"], mats["teal"]])
    for idx, p in enumerate([(-3.2, 1.9, 1.65), (3.2, 1.9, 1.65), (-3.4, -1.6, 1.65), (3.4, -1.6, 1.65)]):
        add_lantern(p, mats["wood"], mats["lantern"], 1.0 + idx * 0.04)
    # Southeast side stays deliberately empty as a visually readable camper bay.
    cube("ParkingGuideLeft", (4.7, -0.9, 0.06), (0.12, 1.6, 0.06), mats["cream"], 0.02)
    cube("ParkingGuideRight", (7.1, -0.9, 0.06), (0.12, 1.6, 0.06), mats["cream"], 0.02)
    return mats


def build_bird_market():
    mats = common_materials()
    blue = material("MarketBlue", (0.20, 0.48, 0.68, 1))
    grain = material("GrainGold", (0.88, 0.66, 0.20, 1))
    for x in (-1.8, 1.8):
        cube("MarketCounter", (x, 0, 0.72), (1.3, 0.58, 0.72), mats["wood_light"], 0.08)
        cube("MarketAwning", (x, 0, 2.0), (1.55, 0.82, 0.10), blue, 0.04, rotation=(0.12, 0, 0))
        for side in (-1, 1):
            cylinder("AwningPost", (x + side * 1.2, 0.45, 1.25), 0.055, 2.5, mats["wood"], 8)
    for idx in range(7):
        ico("GrainSack", (-2.4 + idx * 0.8, -1.2 + (idx % 2) * 0.35, 0.30), (0.34, 0.25, 0.42), grain, 1)
    bird = material("BirdFeather", (0.40, 0.48, 0.58, 1))
    for idx in range(4):
        x = -1.5 + idx
        ico("MarketBird", (x, 0.05, 1.45), (0.28, 0.22, 0.34), bird, 1)
        cone("BirdBeak", (x, -0.25, 1.46), 0.08, 0, 0.24, mats["yellow"], 4, rotation=(math.pi / 2, 0, 0))
    add_sign("BirdMarket", 0, 2.6, 0, mats["wood"], mats["cream"])
    add_flag_line(((-3.8, -2.0, 0), (3.8, -2.0, 0)), mats["wood"], [blue, mats["yellow"]])
    return mats


def build_forest_market():
    mats = common_materials()
    moss = material("Moss", (0.20, 0.46, 0.25, 1))
    glow = material("MushroomGlow", (0.25, 0.72, 0.86, 1), 3.2)
    spirit = material("ForestSpirit", (0.42, 0.68, 0.39, 1))
    for x in (-2.0, 0.0, 2.0):
        cylinder("StumpStall", (x, 0, 0.58), 0.75, 1.15, mats["wood_light"], 10)
        ico("StumpMoss", (x, 0, 1.18), (0.82, 0.62, 0.18), moss, 1)
    for idx in range(12):
        angle = idx * math.tau / 12.0
        radius = 2.7 + (idx % 3) * 0.25
        cylinder("MushroomStem", (math.cos(angle) * radius, math.sin(angle) * radius, 0.24), 0.09, 0.48, mats["cream"], 8)
        ico("MushroomCap", (math.cos(angle) * radius, math.sin(angle) * radius, 0.53), (0.30, 0.30, 0.16), glow, 1)
    for idx in range(3):
        ico("TreeSpirit", (-1.2 + idx * 1.2, -0.6, 1.35), (0.38, 0.30, 0.58), spirit, 1)
    add_sign("ForestMarket", 0, 2.7, 0, mats["wood"], mats["cream"])
    return mats


def build_campfire():
    mats = common_materials()
    ember = material("Ember", (1.0, 0.18, 0.03, 1), 4.0)
    flame = material("Flame", (1.0, 0.62, 0.08, 1), 5.0)
    pumpkin = material("Pumpkin", (0.88, 0.34, 0.05, 1))
    for idx in range(8):
        angle = idx * math.tau / 8.0
        cylinder("StoryLog", (math.cos(angle) * 2.6, math.sin(angle) * 2.6, 0.34), 0.22, 1.45, mats["wood"], 8, rotation=(math.pi / 2, angle, 0))
    for idx in range(5):
        angle = idx * math.tau / 5.0
        cube("FireLog", (math.cos(angle) * 0.38, math.sin(angle) * 0.38, 0.24), (0.65, 0.13, 0.13), mats["wood"], 0.08, rotation=(0, 0, angle))
    cone("FireOuter", (0, 0, 0.88), 0.66, 0.05, 1.45, ember, 7)
    cone("FireInner", (0, 0, 0.84), 0.38, 0.02, 1.08, flame, 7)
    for idx in range(5):
        angle = idx * math.tau / 5.0
        ico("StoryPumpkin", (math.cos(angle) * 3.5, math.sin(angle) * 3.5, 0.36), (0.48, 0.48, 0.38), pumpkin, 1)
        cylinder("PumpkinStem", (math.cos(angle) * 3.5, math.sin(angle) * 3.5, 0.72), 0.07, 0.22, mats["green"], 7)
    add_sign("CampfireStory", 0, 3.2, 0, mats["wood"], mats["cream"])
    for p in [(-3.3, -1.8, 1.65), (3.3, -1.8, 1.65), (-3.3, 1.8, 1.65), (3.3, 1.8, 1.65)]:
        add_lantern(p, mats["wood"], mats["lantern"], 0.9)
    return mats


def export_event(filename, builder, save_blend=False):
    clear_scene()
    builder()
    root = bpy.data.objects.new("LocalEventRoot", None)
    bpy.context.collection.objects.link(root)
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.parent is None:
            obj.parent = root
    root.rotation_euler[2] = 0.0
    bpy.ops.object.select_all(action="SELECT")
    glb_path = os.path.join(OUT_DIR, filename + ".glb")
    bpy.ops.export_scene.gltf(filepath=glb_path, export_format="GLB", use_selection=True, export_yup=True)
    if save_blend:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, filename + ".blend"))
    return root


def render_rabbit_preview():
    world = bpy.context.scene.world
    world.color = (0.035, 0.05, 0.08)
    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (11.5, -13.0, 9.2)
    direction = Vector((0.7, 0.0, 1.0)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 52
    bpy.context.scene.camera = camera
    key_data = bpy.data.lights.new("WarmKey", "AREA")
    key_data.energy = 950
    key_data.color = (1.0, 0.68, 0.38)
    key_data.shape = "DISK"
    key_data.size = 7.0
    key = bpy.data.objects.new("WarmKey", key_data)
    bpy.context.collection.objects.link(key)
    key.location = (3.0, -5.0, 9.0)
    fill_data = bpy.data.lights.new("MoonFill", "AREA")
    fill_data.energy = 620
    fill_data.color = (0.42, 0.58, 1.0)
    fill_data.size = 8.0
    fill = bpy.data.objects.new("MoonFill", fill_data)
    bpy.context.collection.objects.link(fill)
    fill.location = (-7.0, 4.0, 6.0)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 540
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(PREVIEW_DIR, "rabbit_lantern_party_preview.png")
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)


export_event("兔子灯笼聚会_v1", build_rabbit_party, save_blend=True)
render_rabbit_preview()
export_event("候鸟谷物集市_v1", build_bird_market)
export_event("林荫树精菌市_v1", build_forest_market)
export_event("湖畔篝火故事会_v1", build_campfire)
print("LOCAL_EVENT_ASSETS_READY", OUT_DIR)
