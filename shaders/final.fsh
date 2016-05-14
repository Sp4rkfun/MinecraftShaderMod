#version 120

/* final Uniforms */
uniform mat4 gbufferProjection; // The 4x4 projection matrix that was used when the gbuffers were generated.
uniform mat4 gbufferProjectionInverse; // The inverse of gbufferProjection.
uniform mat4 gbufferPreviousProjection; // The 4x4 projection matrix that was used when the gbuffers were generated for the previous frame.
uniform mat4 gbufferPreviousModelView; // The 4x4 modelview matrix that was used after setting up the camera transformations when the gbuffers were generated for the previous frame.
uniform mat4 shadowProjection; // The 4x4 projection matrix that was used when the shadow map was generated.
uniform mat4 shadowProjectionInverse; // The inverse of shadowProjection.
uniform mat4 shadowModelView; // The 4x4 modelview matrix that was used when the shadow map was generated.
uniform mat4 shadowModelViewInverse; // The inverse of shadowModelView.
uniform sampler2D shadow; // The shadow map texture. Including this uniform declaration in a shader triggers the rendering of shadows to the shadow map.

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

uniform int isEyeInWater;

varying vec4 texcoord;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gaux1;
uniform sampler2D gaux4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

vec2 underwaterRefraction(vec2 tex){
	float scale = 0.001;
	if(isEyeInWater>0.9){
		return vec2(tex.x+scale*sin(1.0*worldTime), tex.y+scale*sin(1.0*worldTime));
	}

	return tex;
}

vec4 expFog(float distance,vec4 color){
	float attenuation = 0.05;
	vec3 fogColor = vec3(0.5,0.5,0.5+0.15*(1-(worldTime/24000.0)));
	float factor = exp(-distance*attenuation);
	return vec4(mix(color.xyz,fogColor,1.0-factor),color.w);	
}

float	getDepth		= texture2D(gdepth, texcoord.xy).x;
void main() {
	vec2 newTexcoord = underwaterRefraction(texcoord.xy);
	vec4 color = texture2D(gaux1, newTexcoord.xy);
	//if(fogMode>100)
	//	gl_FragColor = expFog(getDepth,color);
	//else
		gl_FragColor = color;
}