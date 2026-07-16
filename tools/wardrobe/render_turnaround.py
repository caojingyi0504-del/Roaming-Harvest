import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


VIEWS = {
    "front": 0.0,
    "left": -90.0,
    "right": 90.0,
    "back": 180.0,
}

PALETTES = {
    "olive_gardener": {
        "main": (0.37, 0.45, 0.27, 1.0),
        "light": (0.72, 0.72, 0.51, 1.0),
        "accent": (0.48, 0.34, 0.22, 1.0),
    },
    "terracotta_cook": {
        "main": (0.71, 0.35, 0.24, 1.0),
        "light": (0.89, 0.84, 0.70, 1.0),
        "accent": (0.39, 0.29, 0.21, 1.0),
    },
    "mist_lakeside": {
        "main": (0.35, 0.52, 0.56, 1.0),
        "light": (0.69, 0.76, 0.72, 1.0),
        "accent": (0.29, 0.37, 0.39, 1.0),
    },
    "old_road_traveler": {
        "main": (0.40, 0.31, 0.23, 1.0),
        "light": (0.61, 0.52, 0.39, 1.0),
        "accent": (0.31, 0.35, 0.28, 1.0),
    },
}


def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = next(node for node in mat.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 0.9
    return mat


def add_cube(parent, name, location, scale, mat, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("SoftFacets", "BEVEL")
    modifier.width = bevel
    modifier.segments = 1
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def add_cone(parent, name, location, radius_top, radius_bottom, depth, mat, vertices=8):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius_bottom, radius2=radius_top, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def add_cylinder(parent, name, location, radius, depth, mat, vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def add_outfit(root, variant):
    if variant not in PALETTES:
        return
    palette = PALETTES[variant]
    main = material(f"{variant}_main", palette["main"])
    light = material(f"{variant}_light", palette["light"])
    accent = material(f"{variant}_accent", palette["accent"])

    if variant == "olive_gardener":
        add_cone(root, "OliveCape", (0.0, 0.0, 0.58), 0.18, 0.27, 0.52, main)
        add_cube(root, "GardenApron", (0.0, -0.225, 0.47), (0.15, 0.024, 0.23), light, 0.018)
        add_cube(root, "ApronPocket", (0.0, -0.258, 0.39), (0.075, 0.018, 0.055), accent, 0.014)
        add_cylinder(root, "SoftGardenHat", (0.0, 0.0, 1.08), 0.19, 0.055, light, 10)
    elif variant == "terracotta_cook":
        add_cone(root, "CreamCookCoat", (0.0, 0.0, 0.55), 0.18, 0.245, 0.50, light)
        add_cube(root, "TerracottaApron", (0.0, -0.225, 0.46), (0.145, 0.025, 0.225), main, 0.018)
        add_cube(root, "Neckerchief", (0.0, -0.24, 0.79), (0.12, 0.022, 0.055), main, 0.018)
        add_cylinder(root, "CookCapBand", (0.0, 0.0, 1.055), 0.15, 0.07, light, 10)
        add_cone(root, "CookCapTop", (0.0, 0.0, 1.145), 0.12, 0.16, 0.13, light, 10)
    elif variant == "mist_lakeside":
        add_cone(root, "MistCape", (0.0, 0.0, 0.61), 0.19, 0.285, 0.58, main)
        add_cone(root, "CapeHood", (0.0, 0.0, 0.93), 0.16, 0.21, 0.22, light, 10)
        add_cube(root, "WaterproofBootLeft", (-0.09, -0.01, 0.13), (0.07, 0.10, 0.14), accent, 0.025)
        add_cube(root, "WaterproofBootRight", (0.09, -0.01, 0.13), (0.07, 0.10, 0.14), accent, 0.025)
        add_cube(root, "LakesidePouch", (0.20, -0.08, 0.42), (0.085, 0.045, 0.105), light, 0.022)
    elif variant == "old_road_traveler":
        add_cone(root, "OldRoadCoat", (0.0, 0.0, 0.53), 0.18, 0.275, 0.68, main)
        add_cube(root, "CoatPatch", (-0.11, -0.244, 0.38), (0.065, 0.018, 0.07), light, 0.012)
        add_cube(root, "TravelSatchel", (0.23, 0.02, 0.48), (0.105, 0.07, 0.14), accent, 0.025)
        add_cube(root, "RoadScarf", (0.0, -0.225, 0.80), (0.15, 0.024, 0.055), light, 0.018)
        add_cylinder(root, "RoadCap", (0.0, 0.0, 1.065), 0.17, 0.06, accent, 10)


def look_at(camera, target):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def main():
    args = sys.argv[sys.argv.index("--") + 1 :]
    source = Path(args[0])
    output_dir = Path(args[1])
    variant = args[2]
    output_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    character = max((obj for obj in bpy.context.scene.objects if obj.type == "MESH"), key=lambda obj: len(obj.data.polygons))
    character.rotation_euler = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    corners = [character.matrix_world @ Vector(corner) for corner in character.bound_box]
    center = sum(corners, Vector()) / 8.0
    min_z = min(corner.z for corner in corners)
    character.location -= Vector((center.x, center.y, min_z))

    root = bpy.data.objects.new("TurnaroundRoot", None)
    bpy.context.scene.collection.objects.link(root)
    character.parent = root
    add_outfit(root, variant)

    world = bpy.data.worlds.new("WarmGrayWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.79, 0.80, 0.76, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.72
    bpy.context.scene.world = world

    bpy.ops.object.light_add(type="AREA", location=(-2.2, -3.0, 4.0))
    key = bpy.context.object
    key.data.energy = 380.0
    key.data.color = (1.0, 0.88, 0.69)
    key.data.shape = "DISK"
    key.data.size = 4.0
    look_at(key, (0.0, 0.0, 0.55))
    bpy.ops.object.light_add(type="AREA", location=(2.4, -1.0, 2.4))
    fill = bpy.context.object
    fill.data.energy = 220.0
    fill.data.color = (0.68, 0.79, 0.82)
    fill.data.size = 3.0
    look_at(fill, (0.0, 0.0, 0.55))

    bpy.ops.object.camera_add(location=(0.0, -4.0, 0.58))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.42
    look_at(camera, (0.0, 0.0, 0.57))
    bpy.context.scene.camera = camera

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"

    for view_name, angle in VIEWS.items():
        root.rotation_euler.z = math.radians(angle)
        scene.render.filepath = str(output_dir / f"{view_name}.png")
        bpy.ops.render.render(write_still=True)
    print(f"TURNAROUND_READY variant={variant} path={output_dir}")


if __name__ == "__main__":
    main()
