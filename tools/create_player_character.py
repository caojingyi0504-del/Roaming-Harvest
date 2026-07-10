"""Build a low-poly, wardrobe-ready player character for Roaming Harvest.

The generated character deliberately keeps every wardrobe piece separate, while
the base body and clothing are skinned to the same armature.  It exports a
portable GLB with a looping walk action and saves the editable Blender file.
"""

from pathlib import Path
from math import radians, sin, pi

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "3d建模" / "角色3d建模"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
BLEND_PATH = MODEL_DIR / "roaming_player_v1.blend"
GLB_PATH = MODEL_DIR / "roaming_player_v1.glb"
PREVIEW_PATH = ROOT / "art_notes" / "roaming_player_v1_preview.png"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        # Keep built-in data that may be shared; orphan purge at the end clears the rest.
        for item in list(datablocks):
            if item.users == 0:
                datablocks.remove(item)


def material(name, color, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


SKIN = HAIR = TOP = TOP_TRIM = PANTS = SHOES = EYE = METAL = GROUND = None


def create_materials():
    global SKIN, HAIR, TOP, TOP_TRIM, PANTS, SHOES, EYE, METAL, GROUND
    SKIN = material("M_Skin", (0.96, 0.63, 0.46))
    HAIR = material("M_Hair", (0.17, 0.075, 0.035))
    TOP = material("M_Top_Sage", (0.25, 0.52, 0.42))
    TOP_TRIM = material("M_Top_Cream", (0.95, 0.82, 0.54))
    PANTS = material("M_Pants_Rust", (0.48, 0.24, 0.15))
    SHOES = material("M_Shoes", (0.18, 0.12, 0.07))
    EYE = material("M_Eyes", (0.10, 0.06, 0.03), 0.35)
    METAL = material("M_Buckle", (0.86, 0.63, 0.18), 0.35)
    GROUND = material("M_PreviewGround", (0.18, 0.26, 0.20))


def link_to(collection, obj):
    for old_collection in list(obj.users_collection):
        old_collection.objects.unlink(obj)
    collection.objects.link(obj)


def assign_material(obj, mat):
    obj.data.materials.append(mat)


def add_skinned_object(obj, armature, bone_name, collection, wardrobe_slot=""):
    link_to(collection, obj)
    # glTF requires the armature to own every skinned mesh for the skin and
    # animation data to survive export into Godot.
    obj.parent = armature
    obj.matrix_parent_inverse = armature.matrix_world.inverted()
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Armature", "ARMATURE")
    modifier.object = armature
    obj["wardrobe_slot"] = wardrobe_slot
    obj["replaceable"] = bool(wardrobe_slot)
    return obj


def add_uv_sphere(name, location, scale, mat, armature, bone_name, collection, wardrobe_slot=""):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, mat)
    return add_skinned_object(obj, armature, bone_name, collection, wardrobe_slot)


def add_box(name, location, scale, mat, armature, bone_name, collection, wardrobe_slot=""):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Soft edges", "BEVEL")
    bevel.width = 0.045
    bevel.segments = 2
    assign_material(obj, mat)
    return add_skinned_object(obj, armature, bone_name, collection, wardrobe_slot)


def add_cone(name, location, radius_bottom, radius_top, depth, mat, armature, bone_name, collection, wardrobe_slot=""):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius_bottom, radius2=radius_top, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat)
    return add_skinned_object(obj, armature, bone_name, collection, wardrobe_slot)


def add_limb(name, start, end, radius, mat, armature, bone_name, collection, wardrobe_slot=""):
    start = Vector(start)
    end = Vector(end)
    midpoint = (start + end) * 0.5
    direction = end - start
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius, radius2=radius * 0.90, depth=direction.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=False)
    assign_material(obj, mat)
    return add_skinned_object(obj, armature, bone_name, collection, wardrobe_slot)


def make_rig(collection):
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    armature = bpy.context.object
    armature.name = "PlayerRig"
    armature.data.name = "PlayerRig"
    link_to(collection, armature)
    armature.show_in_front = True
    edit_bones = armature.data.edit_bones
    edit_bones.remove(edit_bones[0])

    def bone(name, head, tail, parent=None):
        item = edit_bones.new(name)
        item.head = head
        item.tail = tail
        if parent:
            item.parent = edit_bones[parent]
        return item

    bone("Root", (0, 0, 0), (0, 0, 0.85))
    bone("Hips", (0, 0, 0.85), (0, 0, 1.06), "Root")
    bone("Spine", (0, 0, 1.06), (0, 0, 1.38), "Hips")
    bone("Chest", (0, 0, 1.38), (0, 0, 1.60), "Spine")
    bone("Neck", (0, 0, 1.60), (0, 0, 1.75), "Chest")
    bone("Head", (0, 0, 1.75), (0, 0, 2.10), "Neck")
    bone("UpperArm.L", (0.30, 0, 1.52), (0.57, 0, 1.29), "Chest")
    bone("LowerArm.L", (0.57, 0, 1.29), (0.70, 0, 1.06), "UpperArm.L")
    bone("UpperArm.R", (-0.30, 0, 1.52), (-0.57, 0, 1.29), "Chest")
    bone("LowerArm.R", (-0.57, 0, 1.29), (-0.70, 0, 1.06), "UpperArm.R")
    bone("UpperLeg.L", (0.18, 0, 0.99), (0.18, 0, 0.55), "Hips")
    bone("LowerLeg.L", (0.18, 0, 0.55), (0.18, -0.015, 0.14), "UpperLeg.L")
    bone("Foot.L", (0.18, -0.015, 0.14), (0.18, -0.22, 0.08), "LowerLeg.L")
    bone("UpperLeg.R", (-0.18, 0, 0.99), (-0.18, 0, 0.55), "Hips")
    bone("LowerLeg.R", (-0.18, 0, 0.55), (-0.18, -0.015, 0.14), "UpperLeg.R")
    bone("Foot.R", (-0.18, -0.015, 0.14), (-0.18, -0.22, 0.08), "LowerLeg.R")
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def build_character(armature, body_collection, clothes_collection):
    # Base body is retained beneath wardrobe items so any future outfit can be swapped safely.
    add_cone("Body_Base", (0, 0, 1.34), 0.31, 0.25, 0.59, SKIN, armature, "Chest", body_collection)
    add_uv_sphere("Head_Base", (0, -0.01, 2.00), (0.34, 0.30, 0.36), SKIN, armature, "Head", body_collection)
    add_uv_sphere("Ear.L", (0.34, 0, 2.00), (0.045, 0.035, 0.065), SKIN, armature, "Head", body_collection)
    add_uv_sphere("Ear.R", (-0.34, 0, 2.00), (0.045, 0.035, 0.065), SKIN, armature, "Head", body_collection)

    add_limb("UpperArm_Base.L", (0.30, 0, 1.52), (0.57, 0, 1.29), 0.11, SKIN, armature, "UpperArm.L", body_collection)
    add_limb("LowerArm_Base.L", (0.57, 0, 1.29), (0.70, 0, 1.06), 0.09, SKIN, armature, "LowerArm.L", body_collection)
    add_limb("UpperArm_Base.R", (-0.30, 0, 1.52), (-0.57, 0, 1.29), 0.11, SKIN, armature, "UpperArm.R", body_collection)
    add_limb("LowerArm_Base.R", (-0.57, 0, 1.29), (-0.70, 0, 1.06), 0.09, SKIN, armature, "LowerArm.R", body_collection)
    add_uv_sphere("Hand.L", (0.71, 0, 1.02), (0.105, 0.09, 0.12), SKIN, armature, "LowerArm.L", body_collection)
    add_uv_sphere("Hand.R", (-0.71, 0, 1.02), (0.105, 0.09, 0.12), SKIN, armature, "LowerArm.R", body_collection)

    add_limb("Leg_Base.L", (0.18, 0, 0.99), (0.18, 0, 0.14), 0.135, SKIN, armature, "UpperLeg.L", body_collection)
    add_limb("Leg_Base.R", (-0.18, 0, 0.99), (-0.18, 0, 0.14), 0.135, SKIN, armature, "UpperLeg.R", body_collection)

    # Hair is also separate, allowing hats and alternate haircuts to use the Head wardrobe socket.
    add_uv_sphere("Hair_Cap", (0, 0.05, 2.22), (0.36, 0.32, 0.19), HAIR, armature, "Head", clothes_collection, "hair")
    add_box("Hair_Fringe", (0, -0.285, 2.13), (0.24, 0.045, 0.095), HAIR, armature, "Head", clothes_collection, "hair")
    add_uv_sphere("Eye.L", (0.12, -0.286, 2.01), (0.040, 0.022, 0.058), EYE, armature, "Head", body_collection)
    add_uv_sphere("Eye.R", (-0.12, -0.286, 2.01), (0.040, 0.022, 0.058), EYE, armature, "Head", body_collection)

    add_cone("Top_Base", (0, 0, 1.35), 0.35, 0.29, 0.60, TOP, armature, "Chest", clothes_collection, "top")
    add_cone("Top_Hem", (0, 0, 1.08), 0.365, 0.35, 0.07, TOP_TRIM, armature, "Chest", clothes_collection, "top")
    add_limb("Sleeve.L", (0.31, 0, 1.51), (0.50, 0, 1.34), 0.135, TOP, armature, "UpperArm.L", clothes_collection, "top")
    add_limb("Sleeve.R", (-0.31, 0, 1.51), (-0.50, 0, 1.34), 0.135, TOP, armature, "UpperArm.R", clothes_collection, "top")
    add_cone("Pants.L", (0.18, 0, 0.62), 0.16, 0.145, 0.73, PANTS, armature, "UpperLeg.L", clothes_collection, "bottom")
    add_cone("Pants.R", (-0.18, 0, 0.62), 0.16, 0.145, 0.73, PANTS, armature, "UpperLeg.R", clothes_collection, "bottom")
    add_box("Shoe.L", (0.18, -0.10, 0.105), (0.16, 0.25, 0.105), SHOES, armature, "Foot.L", clothes_collection, "shoes")
    add_box("Shoe.R", (-0.18, -0.10, 0.105), (0.16, 0.25, 0.105), SHOES, armature, "Foot.R", clothes_collection, "shoes")
    add_box("Belt_Buckle", (0, -0.33, 1.10), (0.08, 0.025, 0.06), METAL, armature, "Hips", clothes_collection, "accessory")


def add_wardrobe_slots(armature, collection):
    slots = {
        "Socket_Hat": ("Head", (0.0, 0.0, 2.34)),
        "Socket_Top": ("Chest", (0.0, 0.0, 1.42)),
        "Socket_Back": ("Chest", (0.0, 0.18, 1.45)),
        "Socket_Bottom": ("Hips", (0.0, 0.0, 0.98)),
        "Socket_Accessory": ("Hips", (0.0, -0.34, 1.10)),
    }
    for name, (bone_name, location) in slots.items():
        bpy.ops.object.empty_add(type="CUBE", location=location)
        slot = bpy.context.object
        slot.name = name
        slot.empty_display_size = 0.08
        slot.empty_display_type = "CUBE"
        slot.parent = armature
        slot.parent_type = "BONE"
        slot.parent_bone = bone_name
        slot["purpose"] = "Wardrobe attachment socket"
        link_to(collection, slot)


def add_walk_action(armature):
    if armature.animation_data is None:
        armature.animation_data_create()
    action = bpy.data.actions.new("Walk_Natural_Loop")
    armature.animation_data.action = action
    pose = armature.pose.bones
    for item in pose:
        item.rotation_mode = "XYZ"

    frames = (1, 7, 13, 19, 25)
    stride = (1.0, 0.0, -1.0, 0.0, 1.0)
    for frame, phase in zip(frames, stride):
        pose["UpperLeg.L"].rotation_euler = (radians(24.0) * phase, 0.0, 0.0)
        pose["UpperLeg.R"].rotation_euler = (-radians(24.0) * phase, 0.0, 0.0)
        pose["LowerLeg.L"].rotation_euler = (radians(-13.0) * max(phase, 0.0), 0.0, 0.0)
        pose["LowerLeg.R"].rotation_euler = (radians(-13.0) * max(-phase, 0.0), 0.0, 0.0)
        pose["Foot.L"].rotation_euler = (radians(-8.0) * phase, 0.0, 0.0)
        pose["Foot.R"].rotation_euler = (-radians(-8.0) * phase, 0.0, 0.0)
        pose["UpperArm.L"].rotation_euler = (-radians(18.0) * phase, 0.0, radians(3.0) * phase)
        pose["UpperArm.R"].rotation_euler = (radians(18.0) * phase, 0.0, -radians(3.0) * phase)
        pose["LowerArm.L"].rotation_euler = (radians(-9.0) * phase, 0.0, 0.0)
        pose["LowerArm.R"].rotation_euler = (radians(9.0) * phase, 0.0, 0.0)
        pose["Hips"].rotation_euler = (0.0, radians(2.0) * phase, radians(2.5) * phase)
        pose["Spine"].rotation_euler = (0.0, radians(-1.5) * phase, radians(-2.0) * phase)
        pose["Chest"].rotation_euler = (0.0, radians(-2.0) * phase, radians(-2.0) * phase)
        pose["Head"].rotation_euler = (0.0, radians(1.0) * phase, 0.0)
        pose["Root"].location = (0.0, 0.0, 0.018 + 0.012 * (1.0 - abs(phase)))
        for bone_name in ("UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R", "Foot.L", "Foot.R", "UpperArm.L", "UpperArm.R", "LowerArm.L", "LowerArm.R", "Hips", "Spine", "Chest", "Head"):
            pose[bone_name].keyframe_insert(data_path="rotation_euler", frame=frame)
        pose["Root"].keyframe_insert(data_path="location", frame=frame)

    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER"
        curve.modifiers.new("CYCLES")
    action["loop"] = True
    action["description"] = "Natural 24-frame walk cycle: opposite arm/leg swing, knee flex, hip sway, and head stability."
    return action


def create_preview_scene(character_collection):
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "Preview_Ground"
    assign_material(ground, GROUND)

    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.5, 5.5))
    key = bpy.context.object
    key.name = "Preview_KeyLight"
    key.data.energy = 850
    key.data.shape = "DISK"
    key.data.size = 4.0
    key.rotation_euler = (radians(28), 0, radians(35))

    bpy.ops.object.light_add(type="AREA", location=(-3.5, -1.5, 3.0))
    fill = bpy.context.object
    fill.name = "Preview_FillLight"
    fill.data.energy = 450
    fill.data.size = 3.0

    bpy.ops.object.camera_add(location=(3.6, -6.2, 2.8))
    camera = bpy.context.object
    camera.name = "Preview_Camera"
    direction = Vector((0, 0, 1.15)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 700
    scene.render.resolution_y = 700
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.film_transparent = False
    scene.world.color = (0.06, 0.10, 0.08)
    scene.render.image_settings.color_mode = "RGBA"


def export_character(armature, character_collection, sockets_collection):
    bpy.ops.object.select_all(action="DESELECT")
    for collection in (character_collection, sockets_collection):
        for obj in collection.objects:
            obj.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    try:
        bpy.ops.export_scene.gltf(
            filepath=str(GLB_PATH),
            export_format="GLB",
            use_selection=True,
            export_animations=True,
            export_force_sampling=True,
            export_nla_strips=True,
        )
    except TypeError:
        bpy.ops.export_scene.gltf(filepath=str(GLB_PATH), export_format="GLB", use_selection=True)


def main():
    clear_scene()
    create_materials()
    scene_collection = bpy.context.scene.collection
    character_collection = bpy.data.collections.new("PlayerCharacter")
    body_collection = bpy.data.collections.new("Body")
    clothes_collection = bpy.data.collections.new("Wardrobe_Base")
    sockets_collection = bpy.data.collections.new("Wardrobe_Sockets")
    scene_collection.children.link(character_collection)
    character_collection.children.link(body_collection)
    character_collection.children.link(clothes_collection)
    character_collection.children.link(sockets_collection)

    armature = make_rig(character_collection)
    build_character(armature, body_collection, clothes_collection)
    add_wardrobe_slots(armature, sockets_collection)
    add_walk_action(armature)
    create_preview_scene(character_collection)

    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    bpy.context.scene.render.filepath = str(PREVIEW_PATH)
    bpy.ops.render.render(write_still=True)
    export_character(armature, character_collection, sockets_collection)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    print("PLAYER_CHARACTER_COMPLETE")
    print(BLEND_PATH)
    print(GLB_PATH)
    print(PREVIEW_PATH)


if __name__ == "__main__":
    main()
