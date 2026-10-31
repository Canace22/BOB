shader_type canvas_item;
uniform sampler2D silhouette : filter_linear;
uniform sampler2D clean_plate : filter_linear;
uniform vec2 source_size;
uniform vec4 bounds;
uniform bool recover_edges=false;
uniform sampler2D exclude_mask : filter_linear;
uniform bool has_exclusion=false;
void fragment(){vec4 c=texture(TEXTURE,UV);float a=texture(silhouette,UV).r;
 if(recover_edges){vec2 p=UV*source_size;float inside=step(bounds.x,p.x)*step(bounds.y,p.y)*step(p.x,bounds.z)*step(p.y,bounds.w);float d=length(c.rgb-texture(clean_plate,UV).rgb);a=max(a,inside*smoothstep(0.18,0.40,d));}
 if(has_exclusion)a*=1.0-texture(exclude_mask,UV).r;
 c.a*=a; COLOR=c;}
