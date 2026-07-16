import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


VIEWS = {"front": 0.0, "left": -90.0, "right": 90.0, "back": 180.0}


def bounds(meshes):
    corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    return (
        Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners))),
        Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners))),
    )


def look_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def main():
    args = sys.argv[sys.argv.index("--") + 1 :]
    source = Path(args[0]).resolve()
    output_dir = Path(args[1]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]

    root = bpy.data.objects.new("PreviewRoot", None)
    bpy.context.scene.collection.objects.link(root)
    top_level = [obj for obj in bpy.context.scene.objects if obj != root and obj.parent is None and obj.type not in {"CAMERA", "LIGHT"}]
    for obj in top_level:
        matrix = obj.matrix_world.copy()
        obj.parent = root
        obj.matrix_world = matrix
    minimum, maximum = bounds(meshes)
    center = (minimum + maximum) * 0.5
    root.location = Vector((-center.x, -center.y, -minimum.z))
    bpy.context.view_layer.update()
    minimum, maximum = bounds(meshes)
    dimensions = maximum - minimum
    height = max(dimensions.z, 0.1)
    width = max(dimensions.x, dimensions.y, 0.1)

    world = bpy.data.worlds.new("PreviewWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.79, 0.80, 0.76, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.75
    bpy.context.scene.world = world

    bpy.ops.object.light_add(type="AREA", location=(-2.3, -3.1, height * 2.2))
    key = bpy.context.object
    key.data.energy = 420.0
    key.data.color = (1.0, 0.88, 0.70)
    key.data.size = 4.0
    look_at(key, (0.0, 0.0, height * 0.5))
    bpy.ops.object.light_add(type="AREA", location=(2.2, -0.8, height * 1.4))
    fill = bpy.context.object
    fill.data.energy = 220.0
    fill.data.color = (0.68, 0.78, 0.82)
    fill.data.size = 3.0
    look_at(fill, (0.0, 0.0, height * 0.5))

    bpy.ops.object.camera_add(location=(0.0, -max(width * 7.0, 3.0), height * 0.52))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(height * 1.24, width * 1.35)
    look_at(camera, (0.0, 0.0, height * 0.5))
    bpy.context.scene.camera = camera

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.look = "AgX - Medium High Contrast"
    for view_name, angle in VIEWS.items():
        root.rotation_euler.z = math.radians(angle)
        scene.render.filepath = str(output_dir / f"{view_name}.png")
        bpy.ops.render.render(write_still=True)
    print(f"GLB_PREVIEW_READY file={source.name} path={output_dir}")


if __name__ == "__main__":
    main()
