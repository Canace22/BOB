import bpy,json,math
from pathlib import Path
root=Path('G:/鲸落万物生/BOB/assets/source/baleen-blender')
bpy.ops.wm.open_mainfile(filepath=str(root/'blend/baleen-painted-animation.blend'))
results=[]
for scene in bpy.data.scenes:
 bpy.context.window.scene=scene
 ob=next(o for o in scene.objects if o.type=='MESH');group=ob.vertex_groups['Pinned_Roots'].index
 pins=[v.index for v in ob.data.vertices if any(g.group==group and g.weight>=.999999 for g in v.groups)]
 def verts(frame):
  scene.frame_set(frame);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=ob.evaluated_get(dg);m=ev.to_mesh();v=[x.co.copy() for x in m.vertices];ev.to_mesh_clear();return v
 first=verts(1);max_root=0;max_tip=0
 for frame in [19,37,55]:
  now=verts(frame);max_root=max(max_root,max((now[i]-first[i]).length for i in pins));max_tip=max(max_tip,max((a-b).length for a,b in zip(now,first)))
 last=verts(73);loop_error=max((a-b).length for a,b in zip(last,first))
 results.append({'id':scene.name,'pinned_vertices':len(pins),'root_error_px':max_root,'maximum_deformation_px':max_tip,'frame1_73_loop_error_px':loop_error,'pass':max_root<.001 and loop_error<.001 and max_tip>(.5 if 'DISTANT' in scene.name else 2)})
(root/'review/blender-geometry-checks.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print('BLENDER_GEOMETRY_CHECKS',json.dumps(results))
