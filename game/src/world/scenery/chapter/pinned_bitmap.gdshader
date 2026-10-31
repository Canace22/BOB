shader_type canvas_item;
uniform float clock = 0.0;
uniform float amplitude = 5.0;
uniform float period = 8.0;
uniform float phase = 0.0;
uniform float pin_end = 0.18;
void vertex(){
 float t=clock*6.28318530718/period;
 float weight=smoothstep(pin_end,1.0,UV.y);
 float lag=UV.y*1.5;
 // Root fixed; downstream delay. Subtract rest phase to preserve reference at t=0.
 float swing=sin(t+phase-lag)-sin(phase-lag);
 float second=sin(t*2.0+phase+UV.x*2.0-lag)*0.16-sin(phase+UV.x*2.0-lag)*0.16;
 VERTEX.x+=(swing+second)*weight*amplitude;
 VERTEX.y+=(sin(t+phase-UV.y)-sin(phase-UV.y))*weight*weight*amplitude*0.035;
}
