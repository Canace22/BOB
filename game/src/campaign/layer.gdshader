shader_type canvas_item;
uniform sampler2D classes : filter_nearest;
uniform sampler2D actor_holes : filter_nearest;
uniform sampler2D clean_plate : filter_linear;
uniform sampler2D far_plate : filter_linear;
uniform int layer_id = 0;
uniform vec2 source_size;
uniform vec2 patch0;
uniform vec2 patch1;
uniform vec2 patch2;
uniform vec2 patch3;
uniform vec4 remove0;
uniform vec4 remove1;
uniform vec4 remove2;
uniform vec4 remove3;
uniform int fallback_reward = -1;
uniform float clock = 0.0;
uniform float motion = 0.0;
uniform float membrane_drop = 0.0;
float rect_weight(vec2 p,vec4 r){return smoothstep(0.0,10.0,min(min(p.x-r.x,r.z-p.x),min(p.y-r.y,r.w-p.y)));}
void fragment(){
 vec2 uv=UV;
 if(layer_id==1){uv.x+=sin(clock*0.8+UV.x*16.0)*motion*1.4/source_size.x*smoothstep(0.05,0.40,UV.y)*(1.0-smoothstep(0.45,0.7,UV.y));}
 if(layer_id==2 && membrane_drop>0.0){float w=sin(clamp((UV.x*source_size.x-680.0)/320.0,0.0,1.0)*3.14159265);float vy=UV.y*source_size.y;uv.y-=membrane_drop*w*smoothstep(530.0,590.0,vy)*(1.0-smoothstep(690.0,740.0,vy))/source_size.y;}
 vec3 m=texture(classes,uv).rgb;
 int k=0; if(m.b>0.5)k=1; if(m.g>0.5)k=2; if(m.r>0.5)k=3;
 vec4 src=texture(TEXTURE,uv);vec4 far_color=texture(far_plate,uv);
 if(k==0 && src.r>src.b*0.85 && length(src.rgb-far_color.rgb)>0.12){k=uv.y>0.43?2:1;}
 vec4 c=texture(TEXTURE,uv);
 vec2 p=uv*source_size;
 float a0=rect_weight(p,remove0);float a1=rect_weight(p,remove1);float a2=rect_weight(p,remove2);float a3=rect_weight(p,remove3);
 vec4 cl=texture(clean_plate,uv);
 c=mix(c,fallback_reward==0?texture(TEXTURE,uv+patch0/source_size):cl,a0);
 c=mix(c,fallback_reward==1?texture(TEXTURE,uv+patch1/source_size):cl,a1);
 c=mix(c,fallback_reward==2?texture(TEXTURE,uv+patch2/source_size):cl,a2);
 c=mix(c,fallback_reward==3?texture(TEXTURE,uv+patch3/source_size):cl,a3);
 COLOR=vec4(c.rgb,c.a*float(k==layer_id));
}
