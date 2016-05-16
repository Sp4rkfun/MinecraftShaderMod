/* DRAWBUFFERS:0246 */

vec4 watercolor = vec4(0.1,0.2,.3,0.8);
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

uniform sampler2D texture;

void main() {	
	vec4 tex = vec4((watercolor * length(texture2D(texture, texcoord.xy).rgb)).rgb, watercolor.a);	
	gl_FragData[0] = tex;	
	gl_FragData[2] = vec4(lmcoord.t, mix(0.5,0.05, 1.0), lmcoord.s, 1.0);
}