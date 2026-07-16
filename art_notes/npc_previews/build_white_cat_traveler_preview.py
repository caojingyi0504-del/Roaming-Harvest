import bpy
import math
from mathutils import Vector


OUTPUT_GLB = r"D:\桌面\Roaming Harvest\art_notes\npc_previews\white_cat_traveler_preview.glb"
OUTPUT_RENDER = r"D:\桌面\Roaming Harvest\art_notes\npc_previews\white_cat_traveler_preview.png"
OUTPUT_WALK = r"D:\桌面\Roaming Harvest\art_notes\npc_previews\white_cat_traveler_walk_preview.mp4"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.armatures, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def mat(name, color, roughness=0.82):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Roughness"].default_value = roughness
    return material


WHITE = mat("Fur_White", (0.78, 0.77, 0.75))
PINK = mat("Ear_Pink", (0.92, 0.48, 0.47))
DARK = mat("Eye_and_Nose", (0.095, 0.06, 0.04), 0.4)
COAT = mat("Outfit_Coat_Ochre", (0.57, 0.30, 0.09))
SCARF = mat("Outfit_Scarf_Cream", (0.88, 0.76, 0.56))


def apply_material(obj, material):
    obj.data.materials.append(material)


def low_sphere(name, location, scale, material, segments=12, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_material(obj, material)
    bpy.ops.object.shade_flat()
    return obj


def low_cone(name, location, radius1, radius2, depth, material, rotation=(0.0, 0.0, 0.0), vertices=8):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    apply_material(obj, material)
    bpy.ops.object.shade_flat()
    return obj


def low_cube(name, location, scale, material, bevel=0.06):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel_mod = obj.modifiers.new("LowPolyBevel", "BEVEL")
    bevel_mod.width = bevel
    bevel_mod.segments = 1
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel_mod.name)
    apply_material(obj, material)
    bpy.ops.object.shade_flat()
    return obj


def low_cylinder(name, location, radius, depth, material, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    apply_material(obj, material)
    bpy.ops.object.shade_flat()
    return obj


def bone_parent(obj, armature, bone_name):
    world_matrix = obj.matrix_world.copy()
    obj.parent = armature
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = world_matrix


def create_rig():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    armature = bpy.context.object
    armature.name = "WhiteCatTraveler_Rig"
    armature.data.name = "WhiteCatTraveler_Skeleton"
    edit_bones = armature.data.edit_bones
    edit_bones.remove(edit_bones[0])

    def add_bone(name, head, tail, parent=None):
        bone = edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        bone.parent = parent
        if parent:
            bone.use_connect = False
        return bone

    root = add_bone("root", (0, 0, 0), (0, 0, 0.65))
    spine = add_bone("spine", (0, 0, 0.65), (0, 0, 2.15), root)
    head = add_bone("head", (0, 0, 2.15), (0, 0, 3.1), spine)
    arm_l = add_bone("arm.L", (-0.46, 0, 2.05), (-0.82, 0, 1.18), spine)
    arm_r = add_bone("arm.R", (0.46, 0, 2.05), (0.82, 0, 1.18), spine)
    leg_l = add_bone("leg.L", (-0.25, 0, 0.85), (-0.25, 0, 0.08), root)
    leg_r = add_bone("leg.R", (0.25, 0, 0.85), (0.25, 0, 0.08), root)
    tail_a = add_bone("tail.01", (0, 0.28, 1.1), (0.56, 0.58, 1.02), spine)
    tail_b = add_bone("tail.02", (0.56, 0.58, 1.02), (0.92, 0.72, 1.28), tail_a)
    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    armature["outfit_slots"] = "coat, scarf, headwear"
    armature["preview_only"] = True
    return armature


def key_pose(armature, frame, walk=False):
    bpy.context.scene.frame_set(frame)
    pose = armature.pose.bones
    phase = 1.0 if frame in (1, 25) else -1.0
    if walk:
        pose["arm.L"].rotation_euler = (phase * 0.48, 0.0, 0.0)
        pose["arm.R"].rotation_euler = (-phase * 0.48, 0.0, 0.0)
        pose["leg.L"].rotation_euler = (-phase * 0.42, 0.0, 0.0)
        pose["leg.R"].rotation_euler = (phase * 0.42, 0.0, 0.0)
        pose["tail.01"].rotation_euler = (0.0, 0.0, phase * 0.26)
        pose["tail.02"].rotation_euler = (0.0, 0.0, phase * 0.18)
        pose["root"].location.z = 0.035 if phase > 0 else 0.0
    else:
        pose["head"].rotation_euler = (0.0, 0.0, math.sin(frame * 0.35) * 0.035)
        pose["tail.01"].rotation_euler = (0.0, 0.0, math.sin(frame * 0.3) * 0.16)
        pose["tail.02"].rotation_euler = (0.0, 0.0, math.sin(frame * 0.3 + 0.5) * 0.12)
        pose["root"].location.z = 0.02 if frame == 13 else 0.0
    for bone in pose:
        bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        bone.keyframe_insert(data_path="location", frame=frame)


def make_actions(armature):
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")

    idle = bpy.data.actions.new("Idle")
    armature.animation_data_create()
    armature.animation_data.action = idle
    for frame in (1, 13, 25):
        key_pose(armature, frame, False)
    idle.frame_range = (1, 25)

    walk = bpy.data.actions.new("Walk")
    armature.animation_data.action = walk
    for frame in (1, 13, 25):
        key_pose(armature, frame, True)
    walk.frame_range = (1, 25)
    armature.animation_data.action = idle
    bpy.ops.object.mode_set(mode="OBJECT")
    return idle, walk


def look_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def create_character():
    armature = create_rig()
    parts = []
    body = low_sphere("Body_Base", (0, 0.02, 1.58), (0.55, 0.40, 0.94), WHITE)
    parts.append((body, "spine"))
    head = low_sphere("Head_Base", (0, -0.04, 2.77), (0.69, 0.56, 0.64), WHITE)
    parts.append((head, "head"))
    for side in (-1, 1):
        ear = low_cone("Ear.L" if side < 0 else "Ear.R", (side * 0.42, -0.02, 3.38), 0.22, 0.02, 0.63, WHITE, rotation=(0.0, side * 0.12, side * 0.1))
        parts.append((ear, "head"))
        inner = low_cone("EarInner.L" if side < 0 else "EarInner.R", (side * 0.42, -0.175, 3.36), 0.12, 0.01, 0.37, PINK, rotation=(math.radians(82), 0.0, side * 0.1), vertices=6)
        parts.append((inner, "head"))
        eye = low_sphere("Eye.L" if side < 0 else "Eye.R", (side * 0.25, -0.555, 2.82), (0.09, 0.055, 0.10), DARK, 8, 4)
        parts.append((eye, "head"))
        whisker = low_cylinder("Whisker.L" if side < 0 else "Whisker.R", (side * 0.68, -0.57, 2.68), 0.018, 0.5, WHITE, rotation=(0.0, math.radians(82), side * 0.08))
        parts.append((whisker, "head"))
    nose = low_sphere("Nose", (0, -0.59, 2.66), (0.09, 0.045, 0.06), DARK, 6, 4)
    parts.append((nose, "head"))
    for side in (-1, 1):
        paw = low_sphere("Paw.L" if side < 0 else "Paw.R", (side * 0.27, -0.06, 0.34), (0.24, 0.25, 0.25), WHITE)
        parts.append((paw, "leg.L" if side < 0 else "leg.R"))
        hand = low_sphere("Hand.L" if side < 0 else "Hand.R", (side * 0.72, -0.02, 1.24), (0.18, 0.18, 0.26), WHITE)
        parts.append((hand, "arm.L" if side < 0 else "arm.R"))

    coat_back = low_cone("Outfit_Coat_Back", (0, 0.10, 1.48), 0.88, 0.54, 1.95, COAT, vertices=8)
    coat_back.scale.y = 0.72
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    parts.append((coat_back, "spine"))
    for side in (-1, 1):
        panel = low_cube("Outfit_Coat_Left" if side < 0 else "Outfit_Coat_Right", (side * 0.27, -0.43, 1.38), (0.30, 0.075, 0.98), COAT, 0.04)
        panel.rotation_euler.z = side * math.radians(4)
        parts.append((panel, "spine"))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.50, minor_radius=0.10, major_segments=10, minor_segments=4, location=(0, 0.0, 2.22))
    scarf = bpy.context.object
    scarf.name = "Outfit_Scarf"
    scarf.scale.y = 0.76
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_material(scarf, SCARF)
    bpy.ops.object.shade_flat()
    parts.append((scarf, "spine"))
    hat_slot = bpy.data.objects.new("Outfit_Headwear_Slot", None)
    bpy.context.collection.objects.link(hat_slot)
    hat_slot.empty_display_type = "CIRCLE"
    hat_slot.empty_display_size = 0.16
    hat_slot.location = (0, 0, 3.40)
    parts.append((hat_slot, "head"))

    tail_1 = low_cone("Tail_Base", (0.43, 0.48, 1.07), 0.16, 0.11, 0.70, WHITE, rotation=(0.0, math.radians(66), 0.0), vertices=8)
    tail_2 = low_cone("Tail_Tip", (0.82, 0.67, 1.28), 0.12, 0.07, 0.58, WHITE, rotation=(0.0, math.radians(46), 0.0), vertices=8)
    parts.append((tail_1, "tail.01"))
    parts.append((tail_2, "tail.02"))

    for obj, bone_name in parts:
        bone_parent(obj, armature, bone_name)

    slots = bpy.data.objects.new("OutfitSlots", None)
    bpy.context.collection.objects.link(slots)
    slots["coat"] = "Outfit_Coat_Back, Outfit_Coat_Left, Outfit_Coat_Right"
    slots["scarf"] = "Outfit_Scarf"
    slots["headwear"] = "Outfit_Headwear_Slot"
    slots.parent = armature
    return armature


def create_render_setup():
    bpy.ops.object.camera_add(location=(5.2, -9.0, 4.4))
    camera = bpy.context.object
    camera.name = "PreviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4.75
    look_at(camera, (0, 0, 1.75))
    bpy.context.scene.camera = camera

    bpy.ops.object.light_add(type="AREA", location=(-3.5, -4.0, 6.5))
    key = bpy.context.object
    key.data.energy = 850
    key.data.shape = "DISK"
    key.data.size = 4.5
    look_at(key, (0, 0, 1.6))
    bpy.ops.object.light_add(type="AREA", location=(3.5, -1.5, 4.0))
    fill = bpy.context.object
    fill.data.energy = 380
    fill.data.size = 3.5
    look_at(fill, (0, 0, 1.7))

    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    floor = bpy.context.object
    floor.name = "PreviewFloor"
    apply_material(floor, mat("PreviewFloorMat", (0.82, 0.78, 0.70)))


def main():
    clear_scene()
    armature = create_character()
    idle, walk = make_actions(armature)
    create_render_setup()
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = OUTPUT_RENDER
    scene.render.film_transparent = False
    scene.world.color = (0.055, 0.05, 0.042)
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_GLB.replace(".glb", ".blend"))
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT_GLB,
        export_format="GLB",
        export_apply=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_yup=True,
        export_materials="EXPORT",
    )
    bpy.ops.render.render(write_still=True)
    armature.animation_data.action = walk
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.filepath = OUTPUT_WALK
    scene.render.fps = 12
    scene.frame_start = 1
    scene.frame_end = 25
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    bpy.ops.render.render(animation=True)
    armature.animation_data.action = idle


if __name__ == "__main__":
    main()
