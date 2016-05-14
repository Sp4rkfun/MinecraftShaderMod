#version 120
#define MAX_COLOR_RANGE 48.0

varying vec4 texcoord;

uniform sampler2D gaux2;
uniform int isEyeInWater;
uniform float frameTimeCounter;

//vec3 color = vec3(0.0);
void main() {
/* 	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * isEyeInWater*0.25;

	color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;
	gl_FragColor = vec4(color,1.0); */
}
