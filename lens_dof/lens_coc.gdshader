// Lens depth of field, pass 1 of 2 (see lens_dof.gd).
// A full-screen quad, seen only by a hidden copy of the camera. It reads the depth buffer,
// works out how blurred each pixel would be through a real lens focused at `focus` (the
// "circle of confusion", 0 = sharp .. 1 = the most blur) and writes it as a grey level.
// Storing the blur amount rather than depth means an 8-bit target is plenty.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float focus = 10.0;        // distance in focus, in metres along the view
uniform float aperture = 0.7;      // how strongly things away from the focus blur (higher = wider open)
uniform float sharp = 0.06;        // a little depth either side that stays fully sharp
uniform float debug_value = -1.0;  // >= 0: write this instead (lens_dof.gd checks the encoding with it)

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);    // a 1x1 QuadMesh, stretched over the screen
}

void fragment() {
	float z = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z * 2.0 - 1.0);    // OpenGL: depth 0..1 -> -1..1
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z);                // Forward+ / Mobile: reversed Z
#endif
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float d = -view.z / view.w;                                  // linear distance from the camera
	// a thin lens: blur grows with |d - focus| / d, so it levels off far away and climbs
	// quickly in front of the focus
	float coc = clamp(aperture * (abs(d - focus) / max(d, 0.01) - sharp), 0.0, 1.0);
	if (debug_value >= 0.0) {
		coc = debug_value;
	}
	ALBEDO = vec3(coc);
	ALPHA = 1.0;    // (transparent pass: the depth texture is ready by then)
}
