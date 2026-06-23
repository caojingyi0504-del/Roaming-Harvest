import bpy
import math
from mathutils import Vector

model_path = r'C:\Users\Administrator\Desktop\Roaming Harvest\3d建模\角色3d建模\779a7e05b34a2795208e39b6b4eb09be.glb'
out_path = r'C:\Users\Administrator\Desktop\Roaming Harvest\shadow_preview_blender.png'

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

bpy.ops.import_scene.gltf(filepath=model_path)
model_objs = [obj for obj in bpy.context.scene.objects if obj.type in {'MESH', 'ARMATURE', 'EMPTY'}]
root = bpy.data.objects.new('CharacterRoot', None)
bpy.context.collection.objects.link(root)
for obj in model_objs:
    if obj.parent is None:
        obj.parent = root

# Godot scene uses about 2.35x visual scale.
root.scale = (2.35, 2.35, 2.35)
root.rotation_euler = (0, 0, 0)

# Put model on the ground by bounding box.
bpy.context.view_layer.update()
mins = []
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        for corner in obj.bound_box:
            mins.append((obj.matrix_world @ Vector(corner)).z)
min_z = min(mins) if mins else 0
root.location.z -= min_z

bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
plane = bpy.context.object
plane.name = 'ShadowGround'
mat = bpy.data.materials.new('mat_ground')
mat.diffuse_color = (0.76, 0.74, 0.67, 1)
plane.data.materials.append(mat)

# Low, directional sun similar to Godot. Rotation chosen for a visible elongated cast shadow.
bpy.ops.object.light_add(type='SUN', location=(0, 0, 5))
sun = bpy.context.object
sun.name = 'PreviewSun'
sun.rotation_euler = (math.radians(52), 0, math.radians(-38))
sun.data.energy = 3.2
sun.data.angle = math.radians(1.2)

bpy.ops.object.camera_add(location=(0, -7.0, 4.2), rotation=(math.radians(62), 0, 0))
bpy.context.scene.camera = bpy.context.object

bpy.context.scene.render.engine = 'CYCLES'
bpy.context.scene.cycles.samples = 64
bpy.context.scene.view_settings.view_transform = 'Filmic'
bpy.context.scene.view_settings.look = 'Medium High Contrast'
bpy.context.scene.render.resolution_x = 900
bpy.context.scene.render.resolution_y = 900
bpy.context.scene.world.color = (0.78, 0.88, 1.0)

for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        obj.visible_shadow = True

bpy.ops.render.render(write_still=False)
bpy.data.images['Render Result'].save_render(filepath=out_path)
print(out_path)
