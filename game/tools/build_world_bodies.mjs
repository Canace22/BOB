// Native bitmap volume below frozen footing; no collision or new walking tops.
export function buildBodies(scene,recipe,kit,art,catalog,unit,vec,ratio) {
  for (const cap of recipe.platforms) {
    if (cap.w<4.5) continue;
    const x=cap.x*unit,y=cap.y*unit,width=cap.w*unit;
    let depth=240;
    for (const other of [...recipe.platforms,...(recipe.beds??[])]) {
      if (other.y>cap.y && other.x<cap.x+cap.w && other.x+other.w>cap.x) depth=Math.min(depth,(other.y-cap.y)*unit-110);
    }
    if (depth<55) continue;
    const piece=art(kit.bed.art,1280);
    const scale=width*1.65/(piece.x1-piece.x0);
    const h=catalog.get(piece.id).height*piece.shrink;
    const material=scene.material('res://src/world/scenery/layout/native_foundation.gdshader',{bounds:`Vector4(${[x+8,y+16,width-16,depth].map(v=>Math.round(v*10)/10).join(',')})`});
    scene.sprite('World/Art',`${cap.id}_NativeVolume`,piece.id,{position:vec(x+width*.5-piece.width*scale*.5,y-h*.34*scale),scale:ratio(scale),centered:'false',z_index:-3,material,modulate:'Color(0.68,0.74,0.78,1)'});
  }
}
