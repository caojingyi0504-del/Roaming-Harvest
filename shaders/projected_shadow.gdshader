shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;

uniform vec3 light_direction = vec3(-0.62, -0.42, -0.66);
uniform float ground_y = 0.0;
uniform float ground_lift = 0.035;
uniform vec4 shadow_color : source_color = vec4(0.025, 0.032, 0.025, 0.42);

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 light_dir = normalize(light_direction);
	float denom = min(light_dir.y, -0.05);
	float travel = (world_pos.y - ground_y) / -denom;
	vec3 projected = world_pos + light_dir * travel;
	projected.y = ground_y + ground_lift;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(projected, 1.0)).xyz;
}

void fragment() {
	ALBEDO = shadow_color.rgb;
	ALPHA = shadow_color.a;
}
