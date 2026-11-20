shader_type spatial;
varying vec3 p;
varying vec3 n;
void vertex(){
	p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
float seed(vec2 v){return fract(sin(dot(v,vec2(35.7,121.6)))*4375.8);}
void fragment(){
	vec2 cell=vec2(abs(n.x)>.5?p.z:p.x,p.y)/vec2(1.45,2.65);
	vec2 f=fract(cell);
	float pane=step(.19,f.x)*step(f.x,.75)*step(.20,f.y)*step(f.y,.72)*(1.-abs(n.y));
	float lit=step(.57,seed(floor(cell)+floor(p.xz*.027)));
	vec3 light=mix(vec3(.33,.44,.65),vec3(1.,.63,.29),seed(floor(cell)*.78));
	ALBEDO=mix(vec3(.095,.12,.17),vec3(.25,.31,.39),pane);
	EMISSION=light*pane*lit*.88;
}
