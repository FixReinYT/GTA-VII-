shader_type spatial;
uniform sampler2D palette : source_color, filter_linear;
varying vec3 wp;
varying vec3 wn;
void vertex(){
	wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
	vec3 base=texture(palette,UV).rgb;
	vec2 uv=vec2(abs(wn.x)>abs(wn.z)?wp.z:wp.x,wp.y);
	float row=floor(uv.y*3.4);
	vec2 cell=fract(vec2(uv.x*1.75+mod(row,2.0)*0.5,uv.y*3.4));
	float seam=1.0-smoothstep(0.015,0.072,min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
	float detail=1.0-smoothstep(20.0,72.0,distance(wp,CAMERA_POSITION_WORLD));
	float wall=(1.0-abs(wn.y))*detail;
	base=mix(vec3(dot(base,vec3(.28,.58,.14))),base,0.65);
	ALBEDO=mix(base,vec3(.75,.82,.89),smoothstep(.87,.99,wn.y)*.72)*(1.0-wall*seam*.28);
	ROUGHNESS=.84;
}
