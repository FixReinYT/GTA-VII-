shader_type spatial;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float random_tile(vec2 point){return fract(sin(dot(point,vec2(127.1,311.7)))*4375.5453);}
float noise_field(vec2 p){
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(random_tile(i),random_tile(i+vec2(1,0)),f.x),mix(random_tile(i+vec2(0,1)),random_tile(i+vec2(1,1)),f.x),f.y);
}
void fragment(){
	float coarse=noise_field(world_pos.xz*0.37);
	float grain=noise_field(world_pos.xz*6.0);
	float ice=smoothstep(0.50,0.90,coarse+0.12*grain);
	ALBEDO=mix(vec3(0.10,0.135,0.18),vec3(0.39,0.45,0.53),ice)+grain*0.035;
	float lamps=exp(-abs(abs(world_pos.x)-6.6)*1.65)*pow(.5+.5*cos((world_pos.z+78.)*.41888),4.);
	float frontage=exp(-abs(world_pos.x+6.)*.62-abs(world_pos.z+24.)*.18);
	EMISSION=vec3(.41,.17,.055)*(lamps+frontage)*(grain*.7+.25)*smoothstep(-82.,-77.,world_pos.z)*(1.-smoothstep(6.,12.,world_pos.z));
	ROUGHNESS=mix(0.82,0.21,ice);
}
