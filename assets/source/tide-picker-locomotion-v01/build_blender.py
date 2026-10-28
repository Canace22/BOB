"""Blender 4.2 editable cutout sequence master, not a skeletal/3D character rig."""
import bpy, json, os, math
from pathlib import Path
base=Path(__file__).resolve().parent
runtime=base.parents[1]/'runtime'/'sprites'/'tide-picker-locomotion-v01'
manifest=json.loads((runtime/'manifest.json').read_text(encoding='utf-8'))
bpy.ops.wm.read_factory_settings(use_empty=True)
for state,anim in manifest['animations'].items():
    scene=bpy.data.scenes.new(state.upper())
    bpy.context.window.scene=scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=1
    scene.render.resolution_x=512
    scene.render.resolution_y=512
    scene.render.resolution_percentage=100
    scene.render.fps=anim['fps']
    scene.frame_start=1;scene.frame_end=8
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    camera=bpy.data.cameras.new(state+'_camera')
    cam=bpy.data.objects.new(state+'_camera',camera)
    scene.collection.objects.link(cam)
    cam.location=(0,-10,2.56)
    cam.rotation_euler=(math.pi/2,0,0)
    camera.type='ORTHO';camera.ortho_scale=5.12;scene.camera=cam
    root=bpy.data.objects.new(state+'_ROOT_ground_256_460',None)
    root.location=(0,0,.52)
    scene.collection.objects.link(root)
    for i,frame in enumerate(anim['frames']):
        mesh=bpy.data.meshes.new(f'{state}_{i:02d}_mesh')
        mesh.from_pydata([(-2.56,0,-.52),(2.56,0,-.52),(2.56,0,4.6),(-2.56,0,4.6)],[],[(0,1,2,3)])
        uv=mesh.uv_layers.new()
        for j,co in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[j].uv=co
        ob=bpy.data.objects.new(f'{state}_{i:02d}',mesh);scene.collection.objects.link(ob);ob.parent=root
        mat=bpy.data.materials.new(f'{state}_{i:02d}_ink');mat.use_nodes=True
        nodes=mat.node_tree.nodes;nodes.clear()
        tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(runtime/frame['file']),check_existing=True);tex.image.pack()
        emission=nodes.new('ShaderNodeEmission');transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader');output=nodes.new('ShaderNodeOutputMaterial')
        links=mat.node_tree.links
        links.new(tex.outputs['Color'],emission.inputs['Color']);links.new(tex.outputs['Alpha'],mix.inputs[0]);links.new(transparent.outputs[0],mix.inputs[1]);links.new(emission.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs[0]);mesh.materials.append(mat)
        for f in range(1,9):
            ob.hide_render=f!=i+1;ob.hide_viewport=f!=i+1
            ob.keyframe_insert(data_path='hide_render',frame=f);ob.keyframe_insert(data_path='hide_viewport',frame=f)
        if ob.animation_data and ob.animation_data.action:
            for curve in ob.animation_data.action.fcurves:
                for point in curve.keyframe_points:point.interpolation='CONSTANT'
        scene.timeline_markers.new(f'{state.upper()}_{i:02d}',frame=i+1)
    scene['asset_status']='candidate / near-far gait identity needs refinement'
    scene['source']='imagegen drawings; per-frame visibility authored in Blender'
    scene['pivot_pixels']='256,460'
    scene.frame_set(1)
    scene.render.filepath=str(base/'review'/f'blender-{state}-01.png')
    bpy.ops.render.render(write_still=True)
bpy.data.scenes.remove(bpy.data.scenes['Scene'])
bpy.context.window.scene=bpy.data.scenes['IDLE']
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.shading.type='MATERIAL'
text=bpy.data.texts.new('READ_ME')
text.write('Three 2D animation scenes: IDLE 6fps, WALK 10fps, RUN 14fps. Each timeline: frames 1-8, loop. Packed PNG textures. Constant visibility keys select drawings. Root is the fixed foot-ground anchor. This is an editable sprite sequence timing master, not a 3D rig or editable paint layers. Candidate artwork; see README.md for gait limitations.')
bpy.ops.wm.save_as_mainfile(filepath=str(base/'tide-picker-locomotion.blend'))
print('LOCOMOTION_MASTER_SAVED',bpy.data.filepath)
