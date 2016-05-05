#version 120

/* Vertex Attributes */
attribute vec4 mc_Entity; // This attribute holds fundamental information about the entity to which the vertex belongs. mc_Entity.x represents the item id. mc_Entity.y, mc_Entity.z, and mc_Entity.w are reserved. Currently it is only guaranteed to be valid for terrain.

/* Common Uniforms */
uniform int heldItemId; // An integer indicating the id of the currently held item or -1 if there is none.
uniform int heldBlockLightValue; // An integer indicating the light emission value of the held block. Typically ranges from 0 to 15.
uniform int fogMode; // An integer indicating the type of fog (usually linear or exponential) or 0 if there is no fog. Equivalent to glGetInteger(GL_FOG_MODE).
uniform int worldTime; // An integer indicating the current world time. For the over-world this number ranges from 0 to 24000 and loops.
uniform float viewWidth; // A float indicating the width of the viewport.
uniform float viewHeight; // A float indicating the height of the viewport.
uniform float aspectRatio; // A float derived from viewWidth / viewHeight.
uniform float near; // A float indicating the near viewing plane distance.
uniform float far; // A float indicating the far viewing plane distance.
uniform float rainStrength; // A float indicating the strength of the rain (or in cold biomes, snow).
uniform vec3 sunPosition; // A vec3 indicating the position of the sun in eye space.
uniform vec3 moonPosition; // A vec3 indicating the position of the moon in eye space.
uniform vec3 cameraPosition; // A vec3 indicating the position in world space of the entity to which the camera is attached.
uniform vec3 previousCameraPosition; // A vec3 indicating the position in world space of the entity to which the camera was attached during the previous frame.
uniform mat4 gbufferModelView; // The 4x4 modelview matrix after setting up the camera transformations. This uniform previously had a slightly different purpose in mind, so the name is a bit ambiguous.
uniform mat4 gbufferModelViewInverse; // The inverse of gbufferModelView.

varying vec4 texcoord;
varying vec4 color;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

float shadowMapBias = 0.75;	

void main() {

	color = gl_Color;

	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;
	
	vec4 position = gl_Position;
		 position = shadowProjectionInverse * position;
		 position = shadowModelViewInverse * position;
	
	texcoord = gl_MultiTexCoord0;
	
	position = shadowModelView * position;
	position = shadowProjection * position;
	
	gl_Position = position;
	
	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = (1.0f - shadowMapBias) + dist * shadowMapBias;
	gl_Position.xy *= 1.0f /distortFactor;
	
	// Make it possible, to cast shadows underwater.
	if (mc_Entity.x == 8.0 || mc_Entity.x == 9.0) gl_Position.xy *= 0.0;

	gl_FrontColor = gl_Color;
	
}
