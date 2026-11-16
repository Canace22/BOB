// Source-native stationary framing, independent of every collision/walking top.
export function buildFraming(scene,recipe,art,catalog,unit,vec,ratio) {
  scene.node('Framing','Node2D','.');
  for (const [i,item] of (recipe.framing??[]).entries()) {
    const piece=art(item.art,item.max??1280);
    const extent=piece.axis==='height'?piece.y1-piece.y0:piece.x1-piece.x0;
    const scale=item.units*unit/extent;
    const parent=`Framing/Piece${i}`;
    const layer={z_index:item.z??-12};
    if (item.parallax!==undefined) Object.assign(layer,{script:scene.ext('Script','res://src/world/scenery/kit/kit_parallax.gd'),factor:item.parallax,room_center:vec(recipe.size[0]*unit*.5,recipe.size[1]*unit*.5)});
    scene.node(`Piece${i}`,'Node2D','Framing',layer);
    const motion=item.motion?{script:scene.ext('Script','res://src/world/scenery/kit/kit_reference_motion_sprite.gd'),motion_kind:JSON.stringify(item.motion),phase:i*0.83,amplitude_pixels:item.amplitude??4,external_clock:'true'}:{};
    scene.sprite(parent,'Art',item.art,{position:vec(item.at[0]*unit-piece.pivot[0]*scale,item.at[1]*unit-piece.pivot[1]*scale),scale:ratio(scale),centered:'false',flip_h:item.flip_h,rotation:item.rotation,modulate:`Color(1,1,1,${item.opacity??1})`,...motion});
  }
}
