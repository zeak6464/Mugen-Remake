shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, hint_default_white;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(0.1, 20.0) = 7.5;
uniform float edge_width : hint_range(0.001, 0.3) = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float edge_emission : hint_range(0.0, 12.0) = 2.2;

varying vec3 world_pos;

float hash31(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453123);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex = texture(base_texture, UV);
	vec4 color = tex * base_color;
	float n = hash31(world_pos * noise_scale + vec3(UV, 0.0));
	if (n < dissolve_progress) {
		discard;
	}
	float edge = 1.0 - smoothstep(dissolve_progress, dissolve_progress + edge_width, n);
	ALBEDO = mix(color.rgb, edge_color.rgb, edge);
	EMISSION = edge_color.rgb * edge * edge_emission;
	ALPHA = 1.0;
}
