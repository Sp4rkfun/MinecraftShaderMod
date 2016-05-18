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
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
varying vec4 texcoord;
varying vec3 lightVectorS;
varying vec3 lightVectorM;
varying float weatherRatio;
varying vec3 lightVector;
varying vec3 upVec;
uniform float frameTimeCounter;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gcolor;
uniform sampler2D noisetex;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
float	comp			= 1.0 - near / far / far;
float	getDepth1		= texture2D(depthtex1, texcoord.xy).x;
bool	land2			= getDepth1 < comp;
float getlight = (eyeBrightness.y / 255.0);

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

vec2 newtc = texcoord.xy;
vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;
float pixeldepth = texture2D(depthtex0,texcoord.xy).x;


float sky_lightmap = pow(max(aux.r-1.5/16.,0.0)*(1/(1-1.5/16.)),1.3);
vec3 specular = texture2D(gaux3,texcoord.xy).rgb;


const float shadowDistance = 90;
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
//Water waves
float waterH(vec3 posxz) {
	float wave = 0.0;	
	float factor = 1.0;
	float amplitude = 0.8;
	float speed = 4.0;
	float size = 0.2;

	float px = posxz.x/50.0 + 250.0;
	float py = posxz.z/50.0  + 250.0;

	float fpx = abs(fract(px*20.0)-0.5)*2.0;
	float fpy = abs(fract(py*20.0)-0.5)*2.0;

	float d = length(vec2(fpx, fpy));

	for (int i = 0; i < 3; i++) {
		wave -= d * factor * cos( (1/factor) * px * py * size + 1.0*frameTimeCounter*speed);
		factor /= 2;
	}

	factor = 1.0;
	px = -posxz.x/50.0 + 250.0;
	py = -posxz.z/150.0 - 250.0;

	fpx = abs(fract(px*20.0)-0.5)*2.0;
	fpy = abs(fract(py*20.0)-0.5)*2.0;

	d = length(vec2(fpx, fpy));
	float wave2 = 0.0;
	for (int i = 0; i < 3; i++) {
		wave2 -= d * factor * cos((1/factor) * px * py * size + 1.0 * frameTimeCounter*speed);
	factor /= 2;
	}

	return amplitude * wave2 + amplitude * wave;
}

void main() {
	vec4 skyFragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 1.0f, 1.0f);
		skyFragposition /= skyFragposition.w;
	vec3 color = texture2D(gcolor, newtc.st).rgb;
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float tallgrass = float(aux.g > 0.42 && aux.g < 0.48);
	float shading = 0.0f;

	vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
	tpos = vec4(tpos.xyz / tpos.w, 1.0);
	vec2 pos1 = tpos.xy / tpos.z;
	vec2 lightPos = pos1 * 0.5 + 0.5;
	
	color = pow(color,vec3(2.2))*(1.0+translucent*0.3)*1.0;

	//Specular
	float roughness = mix(1.0-specular.b,0.005,iswater);
	if (specular.r+specular.g+specular.b < 1.0/255.0 && iswater < 0.09) roughness = 0.99;
	float fresnel_pow = pow(roughness,1.25*0.75)*5.0;
	if (iswater > 0.9){
		fresnel_pow=5.0;
	}
	//Positioning
	float NdotL = dot(lightVector,normal);
	float NdotUp = dot(normal,upVec);
	vec4 fragposition = gbufferProjectionInverse * vec4(newtc.s * 2.0f - 1.0f, newtc.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	vec4 worldposition = gbufferModelViewInverse * fragposition;
	float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
	float yDistanceSquared  = worldposition.y * worldposition.y;
	
	//Refraction
	vec3 uPos = vec3(0.0);
	float uDepth = texture2D(depthtex1,newtc.xy).x;
	if (iswater > 0.9) {
		vec3 posxz = worldposition.xyz+cameraPosition;
		posxz.x += sin(posxz.z+frameTimeCounter);
		posxz.z += cos(posxz.x+frameTimeCounter*0.5);

		float deltaPos = 0.4;
		float h0 = waterH(posxz);
		float h1 = waterH(posxz - vec3(deltaPos,0.0,0.0));
		float h2 = waterH(posxz - vec3(0.0,0.0,deltaPos));

		float dX = ((h0-h1))/deltaPos;
		float dY = ((h0-h2))/deltaPos;

		float nX = sin(atan(dX));
		float nY = sin(atan(dY));

		vec3 refract = normalize(vec3(nX,nY,1.0));
		float refMult = 0.005-dot(normal,normalize(fragposition).xyz)*0.003;

		float mask = texture2D(gaux1, newtc.st + refract.xy*refMult).g;
		mask =  float(mask > 0.04 && mask < 0.07);
		newtc = (newtc.st + refract.xy*refMult)*mask + texcoord.xy*(1-mask);

		color.rgb = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2));

		//uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(newtc.xy,uDepth) * 2.0 - 1.0));
	}
	
	if(land > 0.9){
		
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));
		
		//Shadows positioning
		worldposition = shadowModelView * worldposition;
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = length(worldposition.st);
		float distortFactor = mix(1.0,distb,0.80);
		worldposition.xy /= distortFactor;
		worldposition = worldposition * 0.5f + 0.5f;
		float diffthresh = (pow(distortFactor*1.2,2.0)*(0.2/148.0)*(tan(acos(abs(NdotL)))) + (0.02/148.0))*(1.0+iswater*2.0);
		diffthresh = mix(diffthresh,0.0005,translucent)*(1.*0.1*clamp(tan(acos(abs(NdotL))),0.0,2.));
		//Water
		vec4 uPosC = gbufferProjectionInverse * (vec4(newtc,uDepth,1.0) * 2.0 - 1.0);
		uPosC /= uPosC.w;

		vec4 uPosY = gbufferModelViewInverse*vec4(uPosC);
		vec3 pos2 = uPosY.xyz+vec3(sin(uPosY.z+cameraPosition.z+frameTimeCounter)*0.25,0.0,cos(uPosY.x+cameraPosition.x+frameTimeCounter*0.5)*0.25)+cameraPosition+sin(uPosY.y+cameraPosition.y);
		
		float caustics = waterH((pos2.xyz)*2.0)*0.5+2.5;
		
		if(getlight < 0.1);
		else if(iswater > 0.9 || isEyeInWater > 0.1)color *= caustics;
		
		float diffuse = max(dot(lightVector,normal),0.0);
		diffuse = mix(diffuse,1.0,translucent*0.8);
		float gfactor = mix(roughness*0.5+0.01,1.,iswater);
		//spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,shading*diffuse) * (1.0-isEyeInWater);
	}
	color = pow(color, vec3(1.0/2.2));
	
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
	
/* DRAWBUFFERS:4*/
	gl_FragData[0] = vec4(color, pow(getSkyMask(getCloudNoise(skyFragposition.xyz, 0), lightPos), 3.0));
	//gl_FragData[0] = color*getSkyMask(getCloudNoise(skyFragposition.xyz, 0), lightPos);
}