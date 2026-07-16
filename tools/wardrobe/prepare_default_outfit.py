import bpy
from pathlib import Path


PROJECT = Path(r"D:\桌面\Roaming Harvest")
SOURCE = PROJECT / "3d建模" / "角色3d建模" / "779a7e05b34a2795208e39b6b4eb09be.glb"
OUTPUT = PROJECT / "assets" / "wardrobe" / "models" / "player_default_optimized.glb"
TARGET_FACE_COUNT = 30_000
TARGET_TEXTURE_SIZE = 1024


def largest_mesh():
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    return max(meshes, key=lambda obj: len(obj.data.polygons))


def simplify_material(mesh_obj):
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
        for link in base_color.links:
            image = getattr(link.from_node, "image", None)
            if image is not None and max(image.size) > TARGET_TEXTURE_SIZE:
                image.scale(TARGET_TEXTURE_SIZE, TARGET_TEXTURE_SIZE)


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    character = largest_mesh()
    for obj in list(bpy.context.scene.objects):
        if obj != character:
            bpy.data.objects.remove(obj, do_unlink=True)
    character.name = "PlayerDefaultOptimized"
    character.data.name = "PlayerDefaultOptimizedMesh"
    original_faces = len(character.data.polygons)
    if original_faces > TARGET_FACE_COUNT:
        bpy.context.view_layer.objects.active = character
        character.select_set(True)
        modifier = character.modifiers.new(name="WardrobeLowPoly", type="DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = max(TARGET_FACE_COUNT / float(original_faces), 0.001)
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    simplify_material(character)
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    bpy.context.view_layer.objects.active = character
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT),
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
    print(
        "WARDROBE_DEFAULT_READY",
        f"faces={len(character.data.polygons)}",
        f"vertices={len(character.data.vertices)}",
        f"path={OUTPUT}",
    )


if __name__ == "__main__":
    main()
