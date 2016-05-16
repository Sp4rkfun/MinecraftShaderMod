varying vec4 lmcoord;
varying vec3 normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {
	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	vec4 viewpos = gbufferModelViewInverse * position;
	viewpos = gbufferModelView * viewpos;
	
	gl_Position = gl_ProjectionMatrix * viewpos;	
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));
}