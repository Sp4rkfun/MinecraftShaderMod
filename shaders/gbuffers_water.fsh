/* DRAWBUFFERS:0246 */

vec4 watercolor = vec4(0.1,0.2,.3,0.8);

const float PI = 3.1415927;
varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 binormal;
varying vec3 normal;
varying float iswater;

uniform sampler2D texture;

void main() {	
	vec4 tex = vec4((watercolor * length(texture2D(texture, texcoord.xy).rgb*0.3)*color).rgb, watercolor.a);
	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);	
		
	gl_FragData[0] =tex;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}