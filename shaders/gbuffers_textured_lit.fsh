#version 120

/* gbuffers_textured_lit Uniforms */
uniform sampler2D texture; // A sampler2D referencing the geometry's base texture.
uniform sampler2D lightmap; // A sampler2D referencing the geometry's lighting texture.
uniform sampler2DShadow shadow;

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

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

varying vec4 color;
varying vec2 texcoord;
varying vec4 lmcoord;
varying float depth;

void main() {

	vec4 baseColor = texture2D(texture, texcoord.xy) * color;
	baseColor = baseColor*texture2D(lightmap, lmcoord.st);
	//vec4 fragposition	= gbufferProjectionInverse * (vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0) * 2.0 - 1.0);
	//vec4 worldposition	= gbufferModelViewInverse * fragposition;
	//float shading = shadow2D(shadow, worldposition.xyz).x;
	//texture2D(shadow, worldposition.xyz);
	//baseColor = vec4(baseColor.rgb*shading,baseColor.a);
	//baseColor = vec4(shading,shading,shading,1);

/* DRAWBUFFERS:01 */

	gl_FragData[0] = baseColor;
	gl_FragData[1] = vec4(depth, 1.0, 1.0, 1.0);	// gdepth
}
