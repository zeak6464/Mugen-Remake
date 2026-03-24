shader_type spatial;
render_mode unshaded;

uniform sampler2D matcap : filter_linear, repeat_disable;
uniform sampler2D normal_map : hint_normal, filter_linear;

void fragment(){
	vec4 normal = (texture(normal_map, UV) * 2.0 - 1.0);
	vec3 normalV = mat3(TANGENT, BINORMAL, NORMAL) * normal.xyz;
	vec2 uv = normalV.xy * vec2(0.49, -0.49) + 0.5;
	ALBEDO = texture(matcap, uv).rgb;
}