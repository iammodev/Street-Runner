shader_type spatial;
render_mode cull_front, unshaded; // Render front-facing polygons

uniform vec4 outline_color: source_color; // Outline color
uniform float outline_width: hint_range(0.0, 5.0) = 0.1;
uniform float fade_start: hint_range(0.0, 100.0) = 10.0;
uniform float fade_end: hint_range(0.0, 100.0) = 30.0;

uniform float outline_size = 10.0;

void vertex() {
	// Convert vertex position to space
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	// Transform normal to space
	vec3 clip_normal = mat3(PROJECTION_MATRIX * MODELVIEW_MATRIX) * NORMAL;
	
	// Calculate offset for outline expansion
	vec2 offset = normalize(clip_normal.xy) * outline_width * clip_position.w / VIEWPORT_SIZE;
	
	// Apply offset to create outline
	clip_position.xy += offset * outline_size;
	
	POSITION = clip_position;
}

void fragment() {
	// Get Camera Distance
	float camera_distance = length(VERTEX);
	
	// Calculate Fade factor based on camera_distance
	float fade = clamp(1.0 - (camera_distance - fade_start) / (fade_end - fade_start), 0.0, 1.0);
	
	ALBEDO = outline_color.rgb;
	// Multiply alpha by fade
	ALPHA = outline_color.a * fade;
}
