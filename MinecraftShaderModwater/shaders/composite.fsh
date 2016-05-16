varying vec4 texcoord;

uniform sampler2D gcolor;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

vec2 tex = texcoord.xy;
vec3 waterCheck = texture2D(gaux1, texcoord.st).rgb;
vec3 color = texture2D(gcolor, tex.st).rgb;

//Waves
float waveCal(vec3 xzPostion) {
	float factor = 1.5;
	
	float py = -xzPostion.z - 75;
	float posXFloat = abs(fract(-xzPostion.x));
	float posYFloat = abs(fract(py * 20.0) - 0.5) * 2.0;

	float d = length(vec2(posXFloat, posYFloat));
	float wave = 0.0;
	for (int i = 0; i < 3; i++) {
		wave += d * factor * cos(-xzPostion.x * posYFloat * .1);
	factor /= 2;
	}

	return .3 * wave;
}

void main() {
	float iswater = float(waterCheck.g > 0.005 && waterCheck.g < 0.07);
	color = pow(color, vec3(2.1));

	float depth = texture2D(depthtex1,tex.xy).x;
	vec4 uPosC = gbufferProjectionInverse * (vec4(tex, depth, 1.0));
	uPosC /= uPosC.w;

	vec4 yPosition = gbufferModelViewInverse * vec4(uPosC);
	vec3 pos = yPosition.xyz + vec3(sin(yPosition.z + frameTimeCounter),0.0, cos(yPosition.x + frameTimeCounter));

	float waveShadows = waveCal(pos.xyz / 25) + 2;
	if(iswater == 1){
		color /= waveShadows / 2;
	}	
	
	color = color * 6.5;
	gl_FragData[0] = vec4(color, 0);
}
