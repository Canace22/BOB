import bpy, math, json, sys
from pathlib import Path
ROOT=Path('G:/鲸落万物生/BOB/assets/source/baleen-blender')
jobs=json.loads((ROOT/'jobs.json').read_text(encoding='utf-8'))
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
preview='--preview' in args
# Fresh background process only; never edits the user's live Blender document.
for sc in list(bpy.data.scenes):
 if sc!=bpy.context.scene:bpy.data.scenes.remove(sc)
base=bpy.context.scene
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
roots=[(0,180),(180,155),(275,104),(440,55),(595,40),(742,18),(900,0),(1040,5),(1160,65),(1280,240)]
def root_y(x):
 for (a,b),(c,d) in zip(roots,roots[1:]):
  if x<=c:return b+(d-b)*max(0,min(1,(x-a)/(c-a)))
 return 240
stats=[]
for index,job in enumerate(jobs):
 sc=base if index==0 else bpy.data.scenes.new(job['id'])
 sc.name=job['id'];bpy.context.window.scene=sc
 ox,oy,w,h=job['rect'];nx=math.ceil(w/7);ny=math.ceil(h/6)
 vertices=[(x*w/nx,-y*h/ny,0) for y in range(ny+1) for x in range(nx+1)]
 faces=[]
 for y in range(ny):
  for x in range(nx):
   a=y*(nx+1)+x;faces.append((a,a+1,a+nx+2,a+nx+1))
 mesh=bpy.data.meshes.new(job['id']+'_paint_grid');mesh.from_pydata(vertices,[],faces);mesh.update()
 ob=bpy.data.objects.new(job['id']+'_painted_curtain',mesh);sc.collection.objects.link(ob)
 uv=mesh.uv_layers.new(name='OriginalPaintUV')
 for poly in mesh.polygons:
  for li in poly.loop_indices:
   v=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(v.x/w,1+v.y/h)
 mat=bpy.data.materials.new(job['id']+'_paint');mat.use_nodes=True
 nodes=mat.node_tree.nodes;nodes.clear();links=mat.node_tree.links
 tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'paint'/f"{job['id']}.png"));tex.image.pack();tex.interpolation='Linear';tex.extension='CLIP';nodes.active=tex;tex.select=True
 emission=nodes.new('ShaderNodeEmission');links.new(tex.outputs['Color'],emission.inputs['Color'])
 transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader');links.new(tex.outputs['Alpha'],mix.inputs[0]);links.new(transparent.outputs[0],mix.inputs[1]);links.new(emission.outputs[0],mix.inputs[2]);output=nodes.new('ShaderNodeOutputMaterial');links.new(mix.outputs[0],output.inputs['Surface']);mat.surface_render_method='DITHERED'
 ob.data.materials.append(mat)
 ob.shape_key_add(name='Paint_Basis')
 rootgroup=ob.vertex_groups.new(name='Pinned_Roots');flexgroup=ob.vertex_groups.new(name='Flexible_Tips')
 weights=[]
 for i,(x,y,z) in enumerate(vertices):
  gx,gy=x+ox,-y+oy
  if index<3:
   start=root_y(gx)+24;end=[300,170,290][index]
   weight=max(0,min(1,(gy-start)/max(25,end-start)))**1.55
   a,b=job['partition'];edge=max(0,math.sin(math.pi*max(0,min(1,(gx-a)/(b-a)))))**.45
   weight*=edge
  else:
   weight=max(0,min(1,(gy-168)/190))**1.5
   weight*=max(0,min(1,(gx-880)/28,(1050-gx)/28,(385-gy)/30))
  weights.append(weight)
  rootgroup.add([i],1-weight,'REPLACE');flexgroup.add([i],weight,'REPLACE')
 for harmonic,component in [(1,'Sine'),(1,'Cosine'),(2,'Sine'),(2,'Cosine')]:
  key=ob.shape_key_add(name=f'Current_{harmonic}_{component}');key.slider_min=-2;key.slider_max=2
  for i,(x,y,z) in enumerate(vertices):
   phi=job['phase']+(x+ox)*.014-(-y)*.004
   v=math.cos(phi) if component=='Sine' else math.sin(phi)
   dx=job['amplitude']*weights[i]*v*(.83 if harmonic==1 else .17)
   key.data[i].co.x=x+dx
  for frame in range(1,74):
   angle=(frame-1)*2*math.pi/72*harmonic
   key.value=math.sin(angle) if component=='Sine' else math.cos(angle)-1
   key.keyframe_insert('value',frame=frame)
 for fc in ob.data.shape_keys.animation_data.action.fcurves:
  for kp in fc.keyframe_points:kp.interpolation='LINEAR'
  fc.modifiers.new('CYCLES')
 camera_data=bpy.data.cameras.new(job['id']+'_ortho');camera=bpy.data.objects.new(job['id']+'_camera',camera_data);sc.collection.objects.link(camera);camera.location=(w/2,-h/2,100);camera_data.type='ORTHO';camera_data.sensor_fit='HORIZONTAL';camera_data.ortho_scale=w;camera_data.clip_end=1000;sc.camera=camera
 anchor=bpy.data.objects.new('ROOT_ANCHOR__DO_NOT_MOVE',None);anchor.location=(w/2,-24,0);anchor.hide_render=True;sc.collection.objects.link(anchor)
 sc.render.engine='BLENDER_EEVEE_NEXT';sc.eevee.taa_render_samples=16;sc.render.film_transparent=True;sc.render.resolution_x=w;sc.render.resolution_y=h;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA';sc.render.image_settings.color_depth='8';sc.render.dither_intensity=0
 sc.view_settings.view_transform='Standard';sc.view_settings.look='None';sc.view_settings.exposure=0;sc.view_settings.gamma=1
 sc.render.fps=12;sc.frame_start=1;sc.frame_end=72;sc.frame_set(1)
 sc['Description']='Painted 2D cutout, pinned roots, four cyclic shape-key channels. No scene-wide displacement.';sc['Reference_rect']=job['rect'];sc['Atlas_grid']=[8,9];sc['Loop_seconds']=6
 for o in sc.objects:o.select_set(False)
 ob.select_set(True);bpy.context.view_layer.objects.active=ob
 # Texture Paint canvas is the packed source image; mesh/UV and keys remain editable.
 for area in bpy.context.screen.areas:
  if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
 stats.append({'id':job['id'],'vertices':len(vertices),'pinned_vertices':sum(v==0 for v in weights),'max_amplitude':job['amplitude'],'frames':72,'size':[w,h]})
bpy.context.window.scene=bpy.data.scenes['BALEEN-LEFT']
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blend/baleen-painted-animation.blend'))
(ROOT/'blend/build-report.json').write_text(json.dumps({'blender':bpy.app.version_string,'jobs':stats,'method':'Painted texture grids with editable cyclic shape keys; Standard color transform, RGBA rendering'},indent=2),encoding='utf-8')
for job in jobs:
 only=next((arg.split('=',1)[1] for arg in args if arg.startswith('--only=')),None)
 if only and job['id']!=only:continue
 sc=bpy.data.scenes[job['id']];bpy.context.window.scene=sc;dest=ROOT/'frames'/job['id'];dest.mkdir(exist_ok=True)
 for frame in ([1,19,37,55] if preview else range(1,73)):
  sc.frame_set(frame);sc.render.filepath=str(dest/f'{frame-1:03d}.png');bpy.ops.render.render(write_still=True)
 print('BALEEN_RENDERED',job['id'],flush=True)
