import sys
from pathlib import Path

import bpy
from mathutils import Vector


TARGET_TRIANGLES = 30_000
TARGET_TEXTURE_SIZE = 1024
TARGET_HEIGHT = 1.14425


def world_bounds(obj):
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    return minimum, maximum


def largest_mesh():
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("The source GLB has no mesh")
    return max(meshes, key=lambda obj: len(obj.data.polygons))


def simplify_material(mesh_obj):
    kept_images = set()
    for material in mesh_obj.data.materials:
        if material is None or not material.use_nodes:
            continue
        principled = next(
            (node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
            None,
        )
        if principled is None:
            continue
        principled.inputs["Metallic"].default_value = 0.0
        principled.inputs["Roughness"].default_value = 0.88
        for input_name in ("Metallic", "Roughness", "Normal"):
            socket = principled.inputs.get(input_name)
            if socket is not None:
                for link in list(socket.links):
                    material.node_tree.links.remove(link)
        base_color = principled.inputs.get("Base Color")
        if base_color is None:
            continue
        for link in list(base_color.links):
            image = getattr(link.from_node, "image", None)
            if image is None:
                continue
            kept_images.add(image)
            if max(image.size) > TARGET_TEXTURE_SIZE:
                image.scale(TARGET_TEXTURE_SIZE, TARGET_TEXTURE_SIZE)
    return kept_images


def main():
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 3:
        raise SystemExit("Usage: prepare_outfit.py SOURCE OUTPUT OBJECT_NAME")
    source = Path(args[0]).resolve()
    output = Path(args[1]).resolve()
    object_name = args[2]

    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    character = largest_mesh()
    for obj in list(bpy.context.scene.objects):
        if obj != character:
            bpy.data.objects.remove(obj, do_unlink=True)

    character.name = object_name
    character.data.name = object_name + "Mesh"
    minimum, maximum = world_bounds(character)
    source_height = maximum.z - minimum.z
    if source_height <= 0.0:
        raise RuntimeError("The source mesh has no height")
    scale_factor = TARGET_HEIGHT / source_height
    character.scale *= scale_factor

    original_triangles = sum(max(len(poly.vertices) - 2, 1) for poly in character.data.polygons)
    if original_triangles > TARGET_TRIANGLES:
        bpy.context.view_layer.objects.active = character
        character.select_set(True)
        modifier = character.modifiers.new(name="WardrobeLowPoly", type="DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = max(TARGET_TRIANGLES / float(original_triangles), 0.001)
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)

    simplify_material(character)
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    bpy.context.view_layer.objects.active = character
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_texcoords=True,
        export_normals=True,
        export_tangents=False,
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )
    minimum, maximum = world_bounds(character)
    print(
        "WARDROBE_OUTFIT_READY",
        f"source={source.name}",
        f"output={output.name}",
        f"triangles={sum(max(len(poly.vertices) - 2, 1) for poly in character.data.polygons)}",
        f"height={maximum.z - minimum.z:.5f}",
        f"bytes={output.stat().st_size}",
    )


if __name__ == "__main__":
    main()
