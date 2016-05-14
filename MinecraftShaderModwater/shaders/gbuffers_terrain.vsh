varying vec2 texcoord;
varying vec4 color;
varying vec2 lmcoord;

varying vec3 normal;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform sampler2D gaux1;

void main() {
	texcoord = (gl_MultiTexCoord0).xy;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
}
