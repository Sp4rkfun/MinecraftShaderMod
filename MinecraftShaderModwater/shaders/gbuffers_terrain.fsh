/* DRAWBUFFERS:0246 */

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;
varying float mat;
varying vec3 normal;

uniform sampler2D texture;

void main() {
	//Draw textures, colors
	gl_FragData[0] = texture2D(texture, texcoord)*color;
	//Keep lighting intact
	gl_FragData[1] = vec4(normal*0.5+0.5, 1.0f);
	gl_FragData[2] = vec4((lmcoord.t), .1, lmcoord.s, 1.0);
}
