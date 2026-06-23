shader_type spatial;
render_mode cull_disabled, shadows_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.24, 0.42, 0.24);
uniform vec3 mid_color : source_color = vec3(0.50, 0.68, 0.34);
uniform vec3 tip_color : source_color = vec3(0.82, 0.88, 0.50);
uniform float wind_strength = 0.38;
uniform float wind_speed = 1.4;
uniform float wind_scale = 0.12;
uniform vec2 wind_direction = vec2(1.0, 0.18);
uniform vec3 player_position = vec3(0.0);
uniform float player_push_radius = 2.2;
uniform float player_push_strength = 0.55;

varying float blade_height;
varying float color_noise;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	blade_height = clamp(UV.y, 0.0, 1.0);

	vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec2 wind_dir = normalize(wind_direction);
	vec3 local_wind = normalize((inverse(MODEL_MATRIX) * vec4(wind_dir.x, 0.0, wind_dir.y, 0.0)).xyz);
	vec3 local_cross = normalize((inverse(MODEL_MATRIX) * vec4(-wind_dir.y, 0.0, wind_dir.x, 0.0)).xyz);
	float along_wind = dot(world_origin.xz, wind_dir);
	float across_wind = dot(world_origin.xz, vec2(-wind_dir.y, wind_dir.x));
	float phase_offset = hash12(floor(world_origin.xz * 0.32)) * 0.65;
	float gust = sin(TIME * wind_speed + along_wind * wind_scale + phase_offset);
	float ripple = sin(TIME * (wind_speed * 1.18) + along_wind * wind_scale * 2.15 + across_wind * 0.025);
	float noise = hash12(floor(world_origin.xz * 0.45));
	float bend = (gust * 0.72 + ripple * 0.28) * wind_strength * blade_height * blade_height;

	VERTEX += local_wind * bend * (0.9 + noise * 0.16);
	VERTEX += local_cross * sin(TIME * wind_speed + phase_offset) * 0.006 * blade_height;

	vec2 from_player = world_origin.xz - player_position.xz;
	float player_distance = length(from_player);
	float push_mask = smoothstep(player_push_radius, 0.0, player_distance) * blade_height * blade_height;
	if (player_distance > 0.001) {
		vec2 push_dir = from_player / player_distance;
		vec3 local_push = normalize((inverse(MODEL_MATRIX) * vec4(push_dir.x, 0.0, push_dir.y, 0.0)).xyz);
		VERTEX += local_push * push_mask * player_push_strength;
	}
	color_noise = noise;
}

void fragment() {
	vec3 lower = mix(base_color, mid_color, blade_height);
	vec3 upper = mix(lower, tip_color, smoothstep(0.45, 1.0, blade_height));
	vec3 clump_tint = mix(vec3(1.0), COLOR.rgb, 0.72);
	float soft_variation = 0.86 + color_noise * 0.22;
	ALBEDO = upper * clump_tint * soft_variation;
	ROUGHNESS = 0.92;
	SPECULAR = 0.08;
}
