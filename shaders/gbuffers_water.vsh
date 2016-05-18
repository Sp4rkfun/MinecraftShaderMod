varying vec4 color;
varying vec4 lmcoord;
varying vec3 normal;
varying vec3 worldpos;
varying vec4 texcoord;
varying float iswater;

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {
	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	iswater = 0.0f;
	vec4 viewpos = gbufferModelViewInverse * position;
	worldpos = viewpos.xyz + cameraPosition;
	
	if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
		iswater = 1.0;
	}
	texcoord			= (gl_MultiTexCoord0);
	viewpos = gbufferModelView * viewpos;
	gl_Position = gl_ProjectionMatrix * viewpos;	
	color = gl_Color;
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));



}