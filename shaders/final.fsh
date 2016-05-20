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
varying vec3 lightVector;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
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
	float attenuation = 0.03;
	vec3 fogColor = vec3(0.5,0.5,0.5+0.15*(1-(worldTime/24000.0)));
	float factor = exp(-distance*attenuation);
	return vec4(mix(color.xyz,fogColor,1.0-factor),color.w);	
}
//https://www.shadertoy.com/view/ldSXWK
vec3 lensflare(vec3 color, vec2 uv,vec2 pos,vec3 fragpos)
{
	float sunlight = dot(normalize(fragpos), lightVector);
	if (sunlight < 0.2) return color;
    float intensity = 2.2;
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv));

	vec2 uvx = mix(uv,uvd,-0.4);
	
	float f1 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*2.0;
	float f12 = max(0.01-pow(length(uvx+0.55*pos),2.4),.0)*3.0;
	float f13 = max(0.01-pow(length(uvx+0.6*pos),2.4),.0)*1.5;

	uvx = mix(uv,uvd,-0.3);
	
	float f2 = max(0.01-pow(length(uvx+0.2*pos),3.5),.0)*2.0;
	float f22 = max(0.01-pow(length(uvx+0.4*pos),3.5),.0)*2.0;
	float f23 = max(0.01-pow(length(uvx+0.45*pos),3.5),.0)*2.0;
	
	uvx = mix(uv,uvd,-0.5);
	
	float f3 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
	float f32 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
	float f33 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
	
	vec3 c = vec3(0.0);
	
	c.r+=f1+f2+f3; c.g+=f12+f22+f32; c.b+=f13+f23+f33;
	c =max( c*1.2 - vec3(length(uvd)*.04),0.0);
	
	return color + vec3(1.6,1.2,1.4)*c*intensity;
}

vec3 renderGodrays(vec3 clr, vec3 sunClr, vec3 fragpos, vec2 lPos) {

	float	godraysIntensity		= 0.3;
	float	godraysExposure			= 2.0;
	int		godraysSamples			= 50;
	float	godraysDensity			= 1.4;
	float	godraysMipmapping		= 2.0;

		float grSample = 0.0;

		vec2 grCoord			= texcoord.st;
		vec2 deltaTextCoord		= vec2(texcoord.st - lPos.xy);
			 deltaTextCoord	   *= (1.0 / float(godraysSamples) )* godraysDensity;

		for(int i = 0; i < godraysSamples; i++) {
			grCoord		-= deltaTextCoord;
			grSample	+= texture2D(gaux1, grCoord, godraysMipmapping).a;
		}

		// Decrease godray intensity at night.
		if(worldTime > 12700 && worldTime < 23250)
		godraysIntensity = mix(godraysIntensity, godraysIntensity / 4.0, 
			log2(1+ 0.00009478672*(worldTime-12700.0)));

		grSample /= float(godraysSamples) / godraysIntensity;

		float sunlight = max(dot(normalize(fragpos.xyz), lightVector), 0.0);
		float calcSun	= pow(sunlight, 7.5);
		
		return mix(clr, sunClr*godraysExposure , grSample*calcSun);
}

float	getDepth = texture2D(depthtex0, texcoord.xy).x;
void main() {
	const bool gaux1MipmapEnabled		= true;
	vec2 newTexcoord = underwaterRefraction(texcoord.xy);
	vec4 color = texture2D(gaux1, newTexcoord.xy);
	if(fogMode>0)
		gl_FragColor = expFog(getDepth,color);
	else
		gl_FragColor = color;
	
	vec3 ray_color = vec3(200, 150, 50)/255.0; //vec3(1.0,0.5,1.0);
		// Set up positions.
	vec4 skyFragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f,
	texcoord.t * 2.0f - 1.0f, 2.0f * getDepth - 1.0f, 1.0f);
	skyFragposition /= skyFragposition.w;
	
	vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
	tpos = vec4(tpos.xyz / tpos.w, 1.0);
	vec2 pos1 = tpos.xy / tpos.z;
	vec2 lightPos = pos1 * 0.5 + 0.5;
		color.rgb = renderGodrays(color.rgb, ray_color, skyFragposition.xyz, lightPos);
	if((worldTime < 12700 || worldTime > 23250) && 	(texture2D(gaux1, lightPos).a>0)){
		color.rgb = lensflare(color.rgb,newTexcoord*2.0-1.0,pos1,skyFragposition.xyz);
	}
	gl_FragColor = color;//*texture2D(gaux1, pos1).a;
}