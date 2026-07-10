"""Create the two low-poly story NPCs used by Chapter One and export Godot-ready GLBs."""

from pathlib import Path
from math import radians
import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "3d建模" / "角色3d建模"
OUT.mkdir(parents=True, exist_ok=True)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def mat(name, hex_color):
    color = tuple(int(hex_color[i:i + 2], 16) / 255.0 for i in (1, 3, 5))
    value = bpy.data.materials.new(name)
    value.diffuse_color = (*color, 1.0)
    value.use_nodes = True
    value.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*color, 1.0)
    value.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.82
    return value


CREAM = None


def finish(obj, name, material):
    obj.name = name
    obj.data.materials.append(material)
    return obj


def sphere(name, location, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, location=location)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material)


def cone(name, location, radius1, radius2, depth, material, rotation=None):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius1, radius2=radius2, depth=depth, location=location)
    obj = bpy.context.object
    if rotation:
        obj.rotation_euler = rotation
    return finish(obj, name, material)


def cube(name, location, scale, material):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("soft_edges", "BEVEL")
    bevel.width = 0.04
    bevel.segments = 1
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return finish(obj, name, material)


def limb(name, start, end, radius, material):
    from mathutils import Vector
    a, b = Vector(start), Vector(end)
    delta = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius, radius2=radius * 0.88, depth=delta.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    return finish(obj, name, material)


def export(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(OUT / f"{name}.glb"), export_format="GLB", use_selection=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / f"{name}.blend"))


def fox_traveler():
    fur = mat("Fox_Fur", "#c96f3a")
    muzzle = mat("Fox_Cream", "#f4e5c9")
    cape = mat("Traveler_Moss", "#718264")
    cloth = mat("Traveler_Cream", "#efe5ce")
    pants = mat("Traveler_Cinnamon", "#946347")
    bag = mat("Traveler_Coral", "#c97961")
    boot = mat("Traveler_Boot", "#70513c")
    dark = mat("Eyes", "#39281e")
    brass = mat("Brass", "#caa35a")
    sphere("Body", (0, 0, 1.15), (0.38, 0.29, 0.52), cloth)
    sphere("Head", (0, -0.02, 1.93), (0.48, 0.38, 0.44), fur)
    sphere("Muzzle", (0, -0.36, 1.82), (0.34, 0.10, 0.17), muzzle)
    for x in (-0.18, 0.18):
        sphere("Eye", (x, -0.40, 1.98), (0.052, 0.025, 0.07), dark)
    sphere("Nose", (0, -0.46, 1.84), (0.05, 0.035, 0.04), dark)
    cone("EarL", (0.28, 0, 2.28), 0.14, 0.02, 0.42, fur, (0, radians(-12), radians(-12)))
    cone("EarR", (-0.28, 0, 2.28), 0.14, 0.02, 0.42, fur, (0, radians(12), radians(12)))
    cone("Cape", (0, 0.05, 1.42), 0.56, 0.34, 0.60, cape)
    sphere("CapeClasp", (0, -0.36, 1.58), (0.065, 0.025, 0.065), brass)
    for x in (-0.19, 0.19):
        cone("Shorts", (x, 0, 0.66), 0.18, 0.16, 0.48, pants)
        cube("Boot", (x, -0.10, 0.22), (0.17, 0.24, 0.13), boot)
    limb("ArmL", (0.34, 0, 1.37), (0.55, -0.08, 1.02), 0.12, fur)
    limb("ArmR", (-0.34, 0, 1.37), (-0.52, -0.12, 1.10), 0.12, fur)
    cube("SeedSatchel", (0.39, -0.32, 0.98), (0.22, 0.09, 0.22), bag)
    limb("SatchelStrap", (-0.25, -0.25, 1.48), (0.39, -0.32, 1.12), 0.026, bag)
    cone("Map", (-0.54, -0.14, 1.12), 0.055, 0.055, 0.35, cloth, (radians(82), 0, 0))
    cone("Tail", (0.48, 0.18, 0.78), 0.18, 0.08, 0.76, fur, (radians(72), radians(20), radians(-18)))
    export("young_traveler_fox_v1")


def otter_sifter():
    fur = mat("Otter_Fur", "#805d42")
    muzzle = mat("Otter_Cream", "#e5c99d")
    shirt = mat("Sifter_Oat", "#dfd2b7")
    apron = mat("Sifter_Sage", "#84947a")
    cap = mat("Sifter_Blue", "#75898e")
    wood = mat("Willow", "#9a7048")
    dark = mat("OtterEyes", "#39281e")
    sphere("Body", (0, 0, 1.08), (0.45, 0.32, 0.56), shirt)
    sphere("Head", (0, -0.02, 1.88), (0.46, 0.38, 0.42), fur)
    sphere("Muzzle", (0, -0.36, 1.78), (0.34, 0.10, 0.16), muzzle)
    for x in (-0.17, 0.17):
        sphere("Eye", (x, -0.40, 1.93), (0.052, 0.025, 0.07), dark)
    sphere("Nose", (0, -0.45, 1.80), (0.05, 0.035, 0.04), dark)
    for x in (-0.35, 0.35):
        sphere("Ear", (x, 0.0, 2.03), (0.10, 0.08, 0.10), fur)
    sphere("Cap", (0, 0.0, 2.18), (0.47, 0.39, 0.12), cap)
    cube("CapBill", (0, -0.35, 2.12), (0.28, 0.11, 0.045), cap)
    cube("Apron", (0, -0.33, 1.08), (0.36, 0.035, 0.50), apron)
    for x in (-0.22, 0.22):
        cube("Wader", (x, 0, 0.55), (0.18, 0.19, 0.34), fur)
        cube("Boot", (x, -0.10, 0.18), (0.19, 0.25, 0.12), fur)
    limb("ArmL", (0.38, 0, 1.36), (0.64, -0.35, 1.15), 0.13, fur)
    limb("ArmR", (-0.38, 0, 1.36), (-0.64, -0.35, 1.15), 0.13, fur)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.045, major_segments=12, minor_segments=5, location=(0, -0.52, 1.10), rotation=(radians(78), 0, 0))
    finish(bpy.context.object, "SeedSieve", wood)
    cone("Tail", (0.42, 0.22, 0.68), 0.17, 0.07, 0.76, fur, (radians(72), radians(18), radians(-14)))
    export("seed_sifter_otter_v1")


clear()
fox_traveler()
clear()
otter_sifter()
print("STORY_NPCS_COMPLETE")
