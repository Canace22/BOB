"""Packed 2D flipbook editing master. No skeletal or hand-painted-layer claim."""
import bpy, json, math
from pathlib import Path
base=Path(__file__).resolve().parent
runtime=base.parents[2]/'assets/runtime/sprites/tide-picker-locomotion-v02-video'
manifest=json.loads((runtime/'manifest.json').read_text(encoding='utf8'))
bpy.ops.wm.read_factory_settings(use_empty=True)
default=bpy.context.scene
for state,a in manifest['animations'].items():
    scene=bpy.data.scenes.new(state.upper());bpy.context.window.scene=scene
    scene.render.engine='CYCLES';scene.cycles.samples=1
    scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
    scene.render.fps=a['fps'];scene.frame_start=1;scene.frame_end=a['frame_count']
    scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    data=bpy.data.cameras.new(state+'_camera');cam=bpy.data.objects.new(state+'_camera',data);scene.collection.objects.link(cam)
    cam.location=(0,-10,2.56);cam.rotation_euler=(math.pi/2,0,0);data.type='ORTHO';data.ortho_scale=5.12;scene.camera=cam
    root=bpy.data.objects.new('GROUND_256_458',None);scene.collection.objects.link(root);root.location=(0,0,.54)
    for i,frame in enumerate(a['frames']):
        mesh=bpy.data.meshes.new(f'{state}_{i:04d}');mesh.from_pydata([(-2.56,0,-.54),(2.56,0,-.54),(2.56,0,4.58),(-2.56,0,4.58)],[],[(0,1,2,3)])
        uv=mesh.uv_layers.new()
        for j,co in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[j].uv=co
        ob=bpy.data.objects.new(f'{i+1:03d}_{frame["kind"]}',mesh);scene.collection.objects.link(ob);ob.parent=root
        ob['source_index']=-1 if frame['source_index'] is None else frame['source_index']
        mat=bpy.data.materials.new(ob.name);mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();l=mat.node_tree.links
        tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(runtime/frame['file']));tex.image.pack()
        em=n.new('ShaderNodeEmission');tr=n.new('ShaderNodeBsdfTransparent');mix=n.new('ShaderNodeMixShader');out=n.new('ShaderNodeOutputMaterial')
        l.new(tex.outputs['Color'],em.inputs['Color']);l.new(tex.outputs['Alpha'],mix.inputs[0]);l.new(tr.outputs[0],mix.inputs[1]);l.new(em.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],out.inputs[0]);mesh.materials.append(mat)
        for f,hidden in sorted({0:True,1:i!=0,i+1:False,i+2:True}.items()):
            ob.hide_render=hidden;ob.hide_viewport=hidden
            ob.keyframe_insert(data_path='hide_render',frame=f);ob.keyframe_insert(data_path='hide_viewport',frame=f)
        for curve in ob.animation_data.action.fcurves:
            for k in curve.keyframe_points:k.interpolation='CONSTANT'
    scene.timeline_markers.new('NATIVE_VIDEO_START',frame=1)
    scene.timeline_markers.new('OPTICAL_FLOW_BRIDGE_START',frame=a['native_frames']+1)
    scene['status']='Review candidate; see README for visual limitations'
    scene.frame_set(1);scene.render.filepath=str(base/'review'/f'blender-{state}.png');bpy.ops.render.render(write_still=True)
bpy.data.scenes.remove(default)
bpy.context.window.scene=bpy.data.scenes['IDLE']
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
note=bpy.data.texts.new('READ_ME');note.write('Three packed 2D flipbook scenes. Native video frames followed by a short optical-flow loop bridge. Source frame index stored on each card. All textures packed. No 3D rig and no editable paint layers. See selection.json, manifest.json and README.md for cadence and remaining review issues.')
bpy.ops.wm.save_as_mainfile(filepath=str(base/'tide-picker-video-v02.blend'))
print('BLENDER_MASTER_SAVED')
