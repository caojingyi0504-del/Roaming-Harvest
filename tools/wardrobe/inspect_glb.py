import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def world_bounds(meshes):
    corners = []
    for obj in meshes:
        corners.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if not corners:
        return Vector(), Vector()
    return (
        Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners))),
        Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners))),
    )


def main():
    source = Path(sys.argv[sys.argv.index("--") + 1])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    minimum, maximum = world_bounds(meshes)
    images = []
    materials = []
    for obj in meshes:
        for material in obj.data.materials:
            if material is None:
                continue
            materials.append(material.name)
            if not material.use_nodes:
                continue
            for node in material.node_tree.nodes:
                image = getattr(node, "image", None)
                if image is not None:
                    images.append({"name": image.name, "size": list(image.size)})
    report = {
        "file": source.name,
        "bytes": source.stat().st_size,
        "objects": len(bpy.context.scene.objects),
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "faces": sum(len(obj.data.polygons) for obj in meshes),
        "triangles": sum(sum(max(len(poly.vertices) - 2, 1) for poly in obj.data.polygons) for obj in meshes),
        "materials": sorted(set(materials)),
        "images": images,
        "animations": [action.name for action in bpy.data.actions],
        "bounds_min": [round(v, 5) for v in minimum],
        "bounds_max": [round(v, 5) for v in maximum],
        "dimensions": [round(v, 5) for v in (maximum - minimum)],
        "object_details": [
            {
                "name": obj.name,
                "vertices": len(obj.data.vertices),
                "faces": len(obj.data.polygons),
                "parent": obj.parent.name if obj.parent else "",
                "dimensions": [round(v, 5) for v in obj.dimensions],
            }
            for obj in meshes
        ],
    }
    print("GLB_INSPECTION=" + json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
