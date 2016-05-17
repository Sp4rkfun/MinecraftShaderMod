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
varying vec3 lightVectorS;
varying vec3 lightVectorM;
varying float weatherRatio;
uniform float frameTimeCounter;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
float	comp			= 1.0 - near / far / far;
float	getDepth1		= texture2D(depthtex1, texcoord.xy).x;
bool	land2			= getDepth1 < comp;


uniform sampler2D gcolor;
uniform sampler2D noisetex;

bool sunset = (worldTime>=11500&&worldTime < 12500);
vec3 sunsetC  = vec3(243, 169, 25)/255.0;
bool day = (worldTime > 2500 && worldTime < 11500);
vec3 dayC = vec3(255, 255, 77)/255.0;
bool sunrise = (worldTime > 23500 || worldTime < 2500);
vec3 sunriseC = vec3(255, 102, 0)/255.0;
bool moonrise = (worldTime >= 12700 && worldTime < 15700);
vec3 moonriseC = vec3(243, 218, 25)/255.0;
vec3 moonC = vec3(248, 243, 236)/255.0;

vec3 getMoonColor(){
	if(moonrise)return mix(moonriseC,moonC,0.0003333*(worldTime-12700.0));
	return moonC;
}
//255, 255, 153 peak
vec3 getSunColor(){
	if(sunrise){
		if(worldTime >= 23500) 
			return mix(sunriseC,dayC,log2(1.0+0.000333*(worldTime-23500.0)));
		else 
			return mix(sunriseC,dayC,log2(1.0+0.000333*(500.0+worldTime)));
	}
	else if (sunset){
		return mix(dayC,sunsetC,log2(1.0+0.001*(worldTime-11500.0)));
	}
	else if (day)return dayC;
	else if (worldTime >22000.0)return sunriseC;
	else return sunsetC;
}

float getCloudNoise(vec3 fragpos, int integer_i) {

	float cloudWindSpeed 	= 0.09;
	float cloudCover 		= 0.7;
	
	float noise = 0.0;

		vec2 wind[4] = vec2[4](vec2(abs(frameTimeCounter/1000.-0.5), abs(frameTimeCounter/1000.-0.5))+vec2(0.5),
							   vec2(-abs(frameTimeCounter/1000.-0.5), abs(frameTimeCounter/1000.-0.5)),
							   vec2(-abs(frameTimeCounter/1000.-0.5), -abs(frameTimeCounter/1000.-0.5)),
							   vec2(abs(frameTimeCounter/1000.-0.5), -abs(frameTimeCounter/1000.-0.5)));

		vec3 tpos			= vec3(gbufferModelViewInverse * vec4(fragpos.xyz, 1.0));
		vec3 wVector		= normalize(tpos);
		vec3 intersection	= wVector * ((-300.0) / (wVector.y));

		float curvedCloudsPlane = pow(0.89, distance(vec2(0.0), intersection.xz) / 100);

		intersection = wVector * ((-cameraPosition.y + 500.0 - integer_i * 3. * (1.0 + curvedCloudsPlane * curvedCloudsPlane * 2.0) + 300 * sqrt(curvedCloudsPlane)) / (wVector.y));
		vec2 getCoord = (intersection.xz + cameraPosition.xz) / 1000.0 / 180. + wind[0] * cloudWindSpeed;
		vec2 coord = fract(getCoord / 2.0);

		noise += texture2D(noisetex, coord - wind[0] * cloudWindSpeed).x;
		noise += texture2D(noisetex, coord * 3.5	- wind[0] * cloudWindSpeed).x / 3.5;
		noise += texture2D(noisetex, coord * 12.25	- wind[0] * cloudWindSpeed).x / 12.25;
		noise += texture2D(noisetex, coord * 42.87	- wind[0] * cloudWindSpeed).x / 42.87;
		  
	cloudCover = mix(cloudCover, 0.1, weatherRatio);

	return max(noise - cloudCover, 0.0);

}

float getSkyMask(float cloudMask, vec2 lPos) {

	float gr	= 0.0;
	float depth	= texture2D(depthtex0, texcoord.xy).x;

		gr = float(depth > comp);

	// Calculate sun occlusion (only on one pixel).
	if (texcoord.x < 0.002 && texcoord.y < 0.002) {
		for (int i = -6; i < 7;i++) {
			for (int j = -6; j < 7 ;j++) {
				vec2 ij = vec2(i, j);
				float temp = texture2D(depthtex0, lPos + sign(ij) * sqrt(abs(ij)) * vec2(0.002)).x;
					gr += float(temp > comp);
			}
		}

		gr /= 144.0;

	}

	return gr;

}

vec3 drawSun(vec3 color ,vec3 sunColor,vec3 sky,vec3 light){
	float sunVector = max(dot(normalize(sky), light), 0.0);
	// Calculate sun.pow(sunVector, 100.0) * 2.0
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		 tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		 //lightPos = (lightPos + 1.0f)/2.0f;
	vec2 dist = vec2(texcoord.x*2.0-1.0,texcoord.y*2.0-1.0)-lightPos;
	float theta = atan(abs(dist.y/dist.x));
	
	if(dist.x < 0){
		if (dist.y > 0) theta = 3.1415-theta;
		else theta += 3.1415;
	}else if(dist.y < 0) theta = 6.283-theta;
	theta *= sin(worldTime/100.0);
	float val = sin(theta)*0.1+0.9;
	float sun = clamp(pow(sunVector,230.0+3.5*sin(worldTime/20.0))*4.0, 0.0, 1.0);
	return mix(color, sunColor,sun);
}

vec3 drawMoon(vec3 color ,vec3 sunColor,vec3 sky,vec3 light){
	float sunVector = max(dot(normalize(sky), light), 0.0);
	// Calculate sun.pow(sunVector, 100.0) * 2.0
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		 tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		 //lightPos = (lightPos + 1.0f)/2.0f;
	vec2 dist = vec2(texcoord.x*2.0-1.0,texcoord.y*2.0-1.0)-lightPos;
	float sun = clamp(pow(sunVector,500.0)*4.0, 0.0, 1.0);
	return mix(color, sunColor,sun);
}

void main() {
	vec4 skyFragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 1.0f, 1.0f);
		skyFragposition /= skyFragposition.w;
	vec3 color = texture2D(gcolor, texcoord.st).xyz;
	vec3 sunCol = vec3(255, 102, 0)/255.0;//vec3(0.7+0.2*(worldTime/24000.0),0.4,0.35);
	if(!land2){ 
	if (worldTime < 12700 || worldTime > 23250)
		color = drawSun(color,getSunColor(),skyFragposition.xyz,lightVectorS);
	else
		color = drawMoon(color,getMoonColor(),skyFragposition.xyz,lightVectorM);
	if(worldTime >= 12700 && worldTime < 13500)
		color = drawSun(color,sunsetC,skyFragposition.xyz,lightVectorS);
	if(worldTime > 12000 && worldTime <= 12700)
		color = drawMoon(color,moonriseC,skyFragposition.xyz,lightVectorM);
	if(worldTime > 22450 && worldTime <= 23250) 
		color = drawSun(color,getSunColor(),skyFragposition.xyz,lightVectorS);
	else if(worldTime > 23250 && worldTime < 23600)
		color = drawMoon(color,getMoonColor(),skyFragposition.xyz,lightVectorM);
	}
	vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
	tpos = vec4(tpos.xyz / tpos.w, 1.0);
	vec2 pos1 = tpos.xy / tpos.z;
	vec2 lightPos = pos1 * 0.5 + 0.5;
/* DRAWBUFFERS:4 */
	gl_FragData[0] = vec4(color, pow(getSkyMask(getCloudNoise(skyFragposition.xyz, 0), lightPos), 3.0));
	//gl_FragData[0] = color*getSkyMask(getCloudNoise(skyFragposition.xyz, 0), lightPos);
}