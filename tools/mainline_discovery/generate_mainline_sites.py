import bpy
import math
import os
from mathutils import Vector


OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "3d建模", "主线委托"))


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def material(name, color, roughness=0.82, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 2.6
    return mat


def apply_mat(obj, mat):
    obj.data.materials.append(mat)
    return obj


def cube(name, loc, scale, mat, bevel=0.08, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("SoftLowPolyEdges", "BEVEL")
        mod.width = bevel
        mod.segments = 1
    apply_mat(obj, mat)
    obj.parent = parent
    return obj


def cylinder(name, loc, radius, depth, mat, vertices=8, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    apply_mat(obj, mat)
    obj.parent = parent
    return obj


def sphere(name, loc, scale, mat, parent=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_mat(obj, mat)
    obj.parent = parent
    return obj


def cone(name, loc, r1, r2, depth, mat, vertices=8, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    apply_mat(obj, mat)
    obj.parent = parent
    return obj


def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def palette():
    return {
        "wood": material("WarmWood", (0.34, 0.18, 0.08)),
        "wood_light": material("HoneyWood", (0.62, 0.37, 0.16)),
        "linen": material("WarmLinen", (0.91, 0.82, 0.61)),
        "cream": material("Cream", (0.92, 0.86, 0.70)),
        "leaf": material("LeafGreen", (0.30, 0.47, 0.20)),
        "leaf_light": material("YoungLeaf", (0.52, 0.65, 0.27)),
        "orange": material("CarrotOrange", (0.93, 0.38, 0.10)),
        "red": material("TomatoRed", (0.82, 0.18, 0.10)),
        "teal": material("WindTeal", (0.17, 0.52, 0.52)),
        "blue": material("LakeBlue", (0.22, 0.47, 0.61)),
        "purple": material("NightPurple", (0.39, 0.27, 0.52)),
        "stone": material("SoftStone", (0.48, 0.50, 0.45)),
        "fur": material("WarmFur", (0.70, 0.58, 0.43)),
        "fur_dark": material("DarkFur", (0.35, 0.28, 0.22)),
        "gold": material("LanternGlow", (0.96, 0.60, 0.13), emission=(1.0, 0.42, 0.08)),
        "white": material("RabbitWhite", (0.85, 0.82, 0.75)),
    }


def table(root, p, m, full=False):
    x, y = p
    cube("TableTop", (x, y, 0.82), (1.25, 0.56, 0.10), m["wood_light"], parent=root)
    for sx in (-0.88, 0.88):
        cylinder("TableLeg", (x + sx, y, 0.39), 0.09, 0.78, m["wood"], parent=root)
    if full:
        for sx in (-0.66, 0.0, 0.66):
            cylinder("Plate", (x + sx, y, 0.95), 0.23, 0.04, m["cream"], vertices=12, parent=root)
            sphere("Food", (x + sx, y, 1.03), (0.16, 0.16, 0.11), m["orange"], parent=root)


def crate(root, p, m, accent=None):
    x, y, z = p
    cube("ProduceCrate", (x, y, z), (0.52, 0.42, 0.35), m["wood_light"], parent=root)
    for sx in (-0.34, 0.0, 0.34):
        cube("CrateSlat", (x + sx, y - 0.43, z), (0.035, 0.025, 0.31), m["wood"], bevel=0.015, parent=root)
    if accent:
        for i in range(5):
            sphere("Produce", (x - 0.3 + (i % 3) * 0.3, y, z + 0.43 + (i // 3) * 0.16), (0.14, 0.14, 0.14), accent, parent=root)


def banner_arch(root, m, accent, width=5.2, y=2.6):
    for x in (-width / 2, width / 2):
        cylinder("BannerPost", (x, y, 1.45), 0.10, 2.9, m["wood"], parent=root)
        cone("PostCap", (x, y, 2.98), 0.18, 0.02, 0.34, m["wood_light"], parent=root)
    cube("BannerBeam", (0, y, 2.65), (width / 2 + 0.12, 0.08, 0.09), m["wood"], parent=root)
    for i in range(9):
        x = -width / 2 + 0.34 + i * (width - 0.68) / 8
        cone("FestivalFlag", (x, y, 2.34 - 0.08 * (i % 2)), 0.22, 0.0, 0.44, accent, vertices=3, parent=root, rot=(math.pi, 0, 0))


def lantern(root, p, m):
    x, y, z = p
    cylinder("LanternCap", (x, y, z + 0.28), 0.22, 0.08, m["wood"], parent=root)
    sphere("LanternGlow", (x, y, z), (0.27, 0.27, 0.34), m["gold"], parent=root)
    cylinder("LanternTassel", (x, y, z - 0.34), 0.025, 0.22, m["red"], parent=root)


def rabbit(root, p, m, coat="white"):
    x, y = p
    body = sphere("RabbitBody", (x, y, 0.62), (0.42, 0.34, 0.58), m[coat], parent=root)
    sphere("RabbitHead", (x, y, 1.18), (0.35, 0.32, 0.34), m[coat], parent=root)
    for sx in (-0.14, 0.14):
        sphere("RabbitEar", (x + sx, y, 1.66), (0.10, 0.10, 0.42), m[coat], parent=root)
    sphere("RabbitTail", (x, y + 0.31, 0.64), (0.18, 0.18, 0.18), m["cream"], parent=root)
    return body


def hedgehog(root, p, m):
    x, y = p
    sphere("HedgehogSpines", (x, y, 0.62), (0.50, 0.40, 0.58), m["fur_dark"], parent=root)
    sphere("HedgehogFace", (x, y - 0.24, 0.75), (0.34, 0.28, 0.35), m["fur"], parent=root)
    cone("HedgehogNose", (x, y - 0.58, 0.77), 0.16, 0.02, 0.42, m["fur_dark"], vertices=8, parent=root, rot=(math.pi / 2, 0, 0))


def traveler(root, p, m, color):
    x, y = p
    cone("TravelerCoat", (x, y, 0.67), 0.48, 0.24, 1.30, color, vertices=8, parent=root)
    sphere("TravelerHead", (x, y, 1.46), (0.30, 0.28, 0.30), m["fur"], parent=root)
    for sx in (-0.18, 0.18):
        cone("TravelerEar", (x + sx, y, 1.79), 0.13, 0.0, 0.38, m["fur_dark"], vertices=4, parent=root)


def windmill(root, p, m):
    x, y = p
    cone("WindmillTower", (x, y, 1.36), 0.78, 0.48, 2.72, m["cream"], vertices=8, parent=root)
    cylinder("WindmillHub", (x, y - 0.54, 2.42), 0.25, 0.28, m["wood_light"], vertices=10, parent=root, rot=(math.pi / 2, 0, 0))
    for angle in (0, math.pi / 2, math.pi, math.pi * 1.5):
        dx, dz = math.cos(angle), math.sin(angle)
        cube("WindmillBlade", (x + dx * 0.9, y - 0.70, 2.42 + dz * 0.9), (0.78, 0.08, 0.14), m["wood"], bevel=0.035, parent=root, rot=(0, -angle, 0))


def regular_group(root):
    group = empty("RegularOnly", root)
    return group


def build_rabbit(m):
    root = empty("RabbitPicnicCommission")
    cube("PicnicBlanket", (0, 0.6, 0.04), (1.75, 1.25, 0.04), m["red"], bevel=0.03, parent=root)
    banner_arch(root, m, m["orange"], y=2.8)
    table(root, (-2.7, 0.2), m)
    table(root, (2.7, 0.2), m)
    rabbit(root, (-0.75, 0.1), m)
    rabbit(root, (0.85, 0.35), m, "cream")
    crate(root, (-3.4, 2.0, 0.36), m, m["orange"])
    crate(root, (3.4, 2.0, 0.36), m, m["leaf"])
    for i in range(7):
        sphere("RabbitFootprint", (-3.5 + i * 0.48, -2.4 + i * 0.14, 0.035), (0.11, 0.17, 0.035), m["cream"], parent=root)
    reg = regular_group(root)
    table(reg, (-2.7, 0.2), m, True)
    table(reg, (2.7, 0.2), m, True)
    for x in (-2.0, 0.0, 2.0):
        lantern(reg, (x, 2.8, 2.05), m)
    return root


def build_wind(m):
    root = empty("WindmillLunchCommission")
    windmill(root, (0, 2.35), m)
    banner_arch(root, m, m["teal"], width=5.8, y=2.9)
    table(root, (-2.9, 0.0), m)
    table(root, (2.9, 0.0), m)
    traveler(root, (-0.75, 0.0), m, m["teal"])
    traveler(root, (0.78, 0.20), m, m["cream"])
    crate(root, (-3.7, 2.0, 0.36), m)
    crate(root, (3.7, 2.0, 0.36), m)
    for x in (-3.7, 3.7):
        cylinder("WindChimePost", (x, -1.1, 1.2), 0.07, 2.4, m["wood"], parent=root)
        for j in range(3):
            cone("WindChime", (x - 0.2 + j * 0.2, -1.1, 2.05 - j * 0.12), 0.10, 0.04, 0.26, m["gold"], vertices=8, parent=root)
    reg = regular_group(root)
    table(reg, (-2.9, 0.0), m, True)
    table(reg, (2.9, 0.0), m, True)
    return root


def build_garden(m):
    root = empty("HedgehogHarvestCommission")
    banner_arch(root, m, m["red"], width=5.8, y=2.8)
    for x in (-2.7, 2.7):
        cylinder("VinePost", (x, 2.5, 1.25), 0.11, 2.5, m["wood"], parent=root)
        for j in range(5):
            sphere("VineLeaf", (x + (0.20 if j % 2 else -0.18), 2.5, 0.45 + j * 0.42), (0.22, 0.10, 0.14), m["leaf"], parent=root)
            if j % 2 == 0:
                sphere("Tomato", (x - 0.26, 2.46, 0.62 + j * 0.40), (0.14, 0.14, 0.14), m["red"], parent=root)
    hedgehog(root, (-0.75, 0.0), m)
    hedgehog(root, (0.80, 0.20), m)
    table(root, (-2.8, 0.1), m)
    table(root, (2.8, 0.1), m)
    crate(root, (-3.5, 1.65, 0.36), m, m["red"])
    crate(root, (3.5, 1.65, 0.36), m, m["red"])
    cylinder("CartWheelL", (-3.4, -1.35, 0.48), 0.50, 0.12, m["wood"], vertices=10, parent=root, rot=(math.pi / 2, 0, 0))
    cube("GardenCart", (-2.8, -1.35, 0.75), (0.95, 0.50, 0.23), m["wood_light"], parent=root)
    reg = regular_group(root)
    table(reg, (-2.8, 0.1), m, True)
    table(reg, (2.8, 0.1), m, True)
    return root


def build_night(m):
    root = empty("LakesideTroupeCommission")
    banner_arch(root, m, m["purple"], width=6.2, y=2.9)
    cube("TentBody", (-3.2, 1.8, 1.0), (1.25, 1.0, 1.0), m["purple"], parent=root, rot=(0, 0, 0.02))
    cone("TentRoof", (-3.2, 1.8, 2.25), 1.65, 0.0, 1.55, m["cream"], vertices=4, parent=root, rot=(0, 0, math.pi / 4))
    cube("MarketStall", (3.1, 1.7, 0.75), (1.35, 0.65, 0.75), m["wood_light"], parent=root)
    cube("StallCanopy", (3.1, 1.7, 1.75), (1.55, 0.85, 0.11), m["blue"], parent=root, rot=(0.05, 0, 0))
    traveler(root, (-0.7, 0.0), m, m["blue"])
    traveler(root, (0.8, 0.2), m, m["purple"])
    table(root, (-2.4, -0.65), m)
    table(root, (2.4, -0.65), m)
    for x in (-2.5, -1.25, 0.0, 1.25, 2.5):
        lantern(root, (x, 2.9, 2.15 + 0.08 * (1 if int(x * 2) % 2 else 0)), m)
    for x in (-3.7, 3.7):
        sphere("Pumpkin", (x, 0.3, 0.30), (0.34, 0.34, 0.30), m["orange"], parent=root)
        cylinder("PumpkinStem", (x, 0.3, 0.61), 0.05, 0.20, m["leaf"], parent=root)
    reg = regular_group(root)
    table(reg, (-2.4, -0.65), m, True)
    table(reg, (2.4, -0.65), m, True)
    return root


def export_scene(filename, builder):
    reset_scene()
    mats = palette()
    builder(mats)
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
    )
    print("EXPORTED", path)


def main():
    export_scene("兔子野餐邀请_v1.glb", build_rabbit)
    export_scene("风车工匠午餐_v1.glb", build_wind)
    export_scene("刺猬园丁丰收席_v1.glb", build_garden)
    export_scene("湖畔旅团夜宴_v1.glb", build_night)


if __name__ == "__main__":
    main()
