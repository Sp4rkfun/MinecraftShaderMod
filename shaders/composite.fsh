#version 120
#define MAX_COLOR_RANGE 1.0

const float shadowDistance = 90;
#define SHADOW_MAP_BIAS 0.85

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 upVec;
uniform sampler2D gdepth;
uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2DShadow shadow;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
uniform int worldTime;

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

vec3 color = texture2D(gcolor, newtc.st).rgb;
float sky_lightmap = pow(max(aux.r-1.5/16.,0.0)*(1/(1-1.5/16.)),1.3);
vec3 specular = texture2D(gaux3,texcoord.xy).rgb;

float Blinn_Phong(vec3 ppos, vec3 lvector, vec3 normal,float fpow, float gloss, float visibility)  {
	vec3 lightDir = vec3(lvector);

	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
	cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);

	vec3 viewDirection = normalize(-ppos);

	vec3 halfAngle = normalize(lightDir + viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);

	float normalDotEye = dot(normal, normalize(ppos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
	fresnel = fresnel*0.85 + 0.15 * (1.0-fresnel);
	float pi = 3.1415927;
	float n =  pow(2.0,gloss*8.0+log(1+length(ppos)/2.));
	return (pow(blinnTerm, n )*((n+8.0)/(8*pi)))*visibility;
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
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float tallgrass = float(aux.g > 0.42 && aux.g < 0.48);
	float shading = 0.0f;
	float spec = 0.0;

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

		vec4 rA = texture2D(gcolor, newtc.st + refract.xy*refMult);
		rA.rgb = pow(rA.rgb,vec3(2.2));
		vec4 rB = texture2D(gcolor, newtc.st);
		rB.rgb = pow(rB.rgb,vec3(2.2));

		float mask = texture2D(gaux1, newtc.st + refract.xy*refMult).g;
		mask =  float(mask > 0.04 && mask < 0.07);
		newtc = (newtc.st + refract.xy*refMult)*mask + texcoord.xy*(1-mask);

		color.rgb = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2));

		uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(newtc.xy,uDepth) * 2.0 - 1.0));
	}

	if(land > 0.9){
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));
		
		//Shadows positioning
		worldposition = shadowModelView * worldposition;
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = length(worldposition.st);
		float distortFactor = mix(1.0,distb,SHADOW_MAP_BIAS);
		worldposition.xy /= distortFactor;
		worldposition = worldposition * 0.5f + 0.5f;

		float diffthresh = (pow(distortFactor*1.2,2.0)*(0.2/148.0)*(tan(acos(abs(NdotL)))) + (0.02/148.0))*(1.0+iswater*2.0);
		diffthresh = mix(diffthresh,0.0005,translucent)*(1.*0.1*clamp(tan(acos(abs(NdotL))),0.0,2.));

		if (worldposition.s < 0.99 && worldposition.s > 0.01 && worldposition.t < 0.99 && worldposition.t > 0.01 ) {
			if ((NdotL < 0.0 && translucent < 0.1) || (sky_lightmap < 0.01 && eyeBrightness.y < 2)){
				shading = 0.0;
			}
			else {
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
			}
		} else {
			shading = 1.0;
		}
		if (sky_lightmap < 0.02 && eyeBrightness.y < 2){
			shading = 0.0;
		}

		//Water
		vec4 uPosC = gbufferProjectionInverse * (vec4(newtc,uDepth,1.0) * 2.0 - 1.0);
		uPosC /= uPosC.w;

		vec4 uPosY = gbufferModelViewInverse*vec4(uPosC);
		vec3 pos2 = uPosY.xyz+vec3(sin(uPosY.z+cameraPosition.z+frameTimeCounter)*0.25,0.0,cos(uPosY.x+cameraPosition.x+frameTimeCounter*0.5)*0.25)+cameraPosition+sin(uPosY.y+cameraPosition.y);

		float caustics = waterH((pos2.xyz)*2.0)*1.5+2.5;
		if(getlight < 0.1);
		else if(iswater > 0.9 || isEyeInWater > 0.1)color *= caustics;
		float diffuse = max(dot(lightVector,normal),0.0);
		diffuse = mix(diffuse,1.0,translucent*0.8);
		float gfactor = mix(roughness*0.5+0.01,1.,iswater);
		spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,shading*diffuse) * (1.0-isEyeInWater);
	}
	
	color = pow(color/MAX_COLOR_RANGE, vec3(1.0/2.2));
	/* DRAWBUFFERS:74 */
	float depth =texture2D(gdepth, texcoord.xy).x/10;
	//gl_FragData[7] = vec4(depth/10,depth/100,depth/1000,1);
	
	gl_FragData[0] = vec4(color, spec);
}
