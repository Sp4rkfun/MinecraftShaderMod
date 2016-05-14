#version 120

/* Vertex Attributes */
attribute vec4 mc_Entity; // This attribute holds fundamental information about the entity to which the vertex belongs. mc_Entity.x represents the item id. mc_Entity.y, mc_Entity.z, and mc_Entity.w are reserved. Currently it is only guaranteed to be valid for terrain.
attribute vec4 mc_midTexCoord;

/* gbuffers_textured_lit Uniforms */
uniform sampler2D texture; // A sampler2D referencing the geometry's base texture.
uniform sampler2D lightmap; // A sampler2D referencing the geometry's lighting texture.

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

varying vec4 color;
varying vec2 texcoord;
varying vec4 lmcoord;
varying float depth;
uniform float frameTimeCounter;

vec3 wind(vec3 pos){
	//Position is not the absolute position, moves based on camera
	float onGround 	= 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) onGround = 1.0;
	if (mc_Entity.x == 6.0 ||	// Saplings.
		mc_Entity.x == 31.0 ||	// Grass.
		mc_Entity.x == 37.0 ||	// Yellow flower.
		mc_Entity.x == 38.0 ||	// Red flower and others.
		mc_Entity.x == 59.0 ||	// Wheat.
		mc_Entity.x == 141.0 ||	// Carrots.
		mc_Entity.x == 142.0 ||	// Potatoes.
		mc_Entity.x == 161.0 // Acacia leaves.
		) {
		float res = 100;
		float speed = 4.0;
		float dir = sin(frameTimeCounter/speed/speed);
		float strength = abs(0.5*sin(worldTime/10000.0));
		float windX = sin(frameTimeCounter *speed+(pos.z+cameraPosition.z)*res)*max(0.1,sin(dir*3.14));
		float windZ = sin(frameTimeCounter *speed+(pos.x+cameraPosition.x)*res)*max(0.1,cos(dir*-3.14));
		if(onGround>0.9){ //Keeps the base in the same location
			pos.x += strength *windX;
			pos.z += strength*windZ;
		}
	}else if(
		mc_Entity.x == 106.0 ||// Vines. TODO
		mc_Entity.x == 18.0	//leaves.
	){
		float res = 100;
		float speed = 4.0;
		float dir = sin(frameTimeCounter/speed/speed);
		float strength = abs(0.1*sin(worldTime/10000.0));
		if(mc_Entity.x==106.0){
			strength = strength*0.5;
		}
		float windX = sin(frameTimeCounter *speed+(pos.z+cameraPosition.z)*res)*max(0.1,sin(dir*3.14));
		float windZ = sin(frameTimeCounter *speed+(pos.x+cameraPosition.x)*res)*max(0.1,cos(dir*-3.14));
		pos.x += strength *windX;
		pos.z += strength*windZ;
	}else if(
		mc_Entity.x == 83.0 //sugar cane
		||mc_Entity.x == 175.0 // Tall grass/flowers
	){
		float res = 100;
		float speed = 4.0;
		float dir = sin(frameTimeCounter/speed/speed);
		float strength = abs(0.1*sin(worldTime/10000.0));
		float windX = sin(frameTimeCounter *speed+(pos.y+cameraPosition.y)*res)*max(0.1,sin(dir*3.14));
		float windZ = sin(frameTimeCounter *speed+(pos.y+cameraPosition.y)*res)*max(0.1,cos(dir*-3.14));
		windX = windX*max(pos.y,0);
		windZ = windZ*max(pos.y,0);
		pos.x += strength *windX;
		pos.z += strength*windZ;
	}
	return pos;
}

void main() {
	
	vec4 position		= gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	//vec2 lmcoord		= (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	texcoord			= (gl_MultiTexCoord0).xy;
	color = gl_Color;
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	position.xyz = wind(position.xyz);
	

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	depth = length(position);
	
}