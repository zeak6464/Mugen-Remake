shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(0.15, 0.85, 0.35, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.65;
uniform float roughness : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	ALBEDO = albedo_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
