#version 120

/* composite Uniforms */
uniform mat4 gbufferProjection; // The 4x4 projection matrix that was used when the gbuffers were generated.
uniform mat4 gbufferProjectionInverse; // The inverse of gbufferProjection.
uniform mat4 gbufferPreviousProjection; // The 4x4 projection matrix that was used when the gbuffers were generated for the previous frame.
uniform mat4 gbufferPreviousModelView; // The 4x4 modelview matrix that was used after setting up the camera transformations when the gbuffers were generated for the previous frame.
uniform mat4 shadowProjection; // The 4x4 projection matrix that was used when the shadow map was generated.
uniform mat4 shadowProjectionInverse; // The inverse of shadowProjection.
uniform mat4 shadowModelView; // The 4x4 modelview matrix that was used when the shadow map was generated.
uniform mat4 shadowModelViewInverse; // The inverse of shadowModelView.
uniform sampler2DShadow shadow; // The shadow map texture. Including this uniform declaration in a shader triggers the rendering of shadows to the shadow map.

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

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gaux1;
uniform sampler2D gaux4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

vec3 normal_from_depth(vec2 tex) {
  
  vec2 offset1 = vec2(0.0,0.001);
  vec2 offset2 = vec2(0.001,0.0);
  float depth = texture2D(gdepth, tex.xy).x;
  float depth1 = texture2D(gdepth, tex.xy + offset1).x;
  float depth2 = texture2D(gdepth, tex.xy + offset2).x;
  
  vec3 p1 = vec3(offset1, depth1 - depth);
  vec3 p2 = vec3(offset2, depth2 - depth);
  
  vec3 normal = cross(p1, p2);
  normal.z = -normal.z;//???? dont get this step
  
  return normalize(normal);
}
int blurSize =5 ;
vec4 hblur(vec4 c){
	float blurOffset = 0.001;
	for(int i = -1*blurSize;i<blurSize;i++){
		c = c + texture2D(gaux1, texcoord.st+vec2(blurOffset*i,0));
	}
	return c /(blurSize*2+1);
	
}
vec4 vblur(vec4 c){
	float blurOffset = 0.001;
	for(int i = -1*blurSize;i<blurSize;i++){
		c = c + texture2D(gaux1, texcoord.st+vec2(0,blurOffset*i));
	}
	return c /(blurSize*2+1);
	
}

void main() {
	a
	// Get main color.
	vec4 color = texture2D(gaux1, texcoord.st);
/* DRAWBUFFERS:4 */
	
	float thresh = 0.9;
	//gl_FragData[0] = color;
	
	vec3 normal = normal_from_depth(texcoord.st);
	float ydot = dot(normal,vec3(0,1,0));
	float xdot = dot(normal,vec3(1,0,0));
	float zdot = dot(normal,vec3(0,0,1));
	if(abs(zdot)<thresh){
		color = vblur(color);
		color = hblur(color);
	}
	if(abs(xdot)<thresh){
		color = vblur(color);
	}
	if(abs(ydot)<thresh){
		color = hblur(color);
	}
	float occ = 0.2;
	if(color.x<occ){
		color=vec4(occ,occ,occ,1);
	}else{
		color=vec4(1,1,1,0);
	}
	
	gl_FragData[0] = color;

}