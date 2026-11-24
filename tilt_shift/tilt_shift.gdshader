// Tilt-shift "miniature" look, as one screen shader. Works on every renderer.
// Put it on a full-screen ColorRect (anchors: full rect, mouse filter: ignore) in a CanvasLayer
// under your UI. A band across the screen stays sharp; the blur ramps up either side of it.
// Set the band by hand, or let tilt_shift_band.gd aim it at things in your world every frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 band_center = vec2(0.5, 0.55);   // a point (screen UV) the sharp band runs through
uniform float band_angle = 0.0;               // degrees: 0 = level across the screen
uniform float band_half_width = 0.12;         // half the sharp band's width, in screen heights
uniform float falloff = 0.22;                 // how far (screen heights) the blur takes to ramp up
uniform float max_radius = 10.0;              // the most blur, in pixels
uniform float saturation = 1.15;              // miniatures look extra saturated (1 = off)
uniform float vignette = 0.3;                 // 0 = off

const int TAPS = 24;

void fragment() {
	vec2 uv = SCREEN_UV;
	// "aspect space": x stretched by width/height, so distances are in screen heights and a
	// tilted band is the same width on any screen shape
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = (uv - band_center) * vec2(aspect, 1.0);
	float a = radians(band_angle);
	vec2 n = vec2(-sin(a), cos(a));                // across the band
	float outside = max(abs(dot(p, n)) - band_half_width, 0.0);
	float amt = smoothstep(0.0, falloff, outside);
	vec3 col = texture(screen_tex, uv).rgb;
	if (amt > 0.002) {
		vec3 acc = vec3(0.0);
		float radius = amt * max_radius;
		float lod = amt * 2.2;                     // a blurrier mip further out: wide and cheap
		for (int i = 0; i < TAPS; i++) {
			float ga = float(i) * 2.39996;         // golden angle spiral
			float r = sqrt((float(i) + 0.5) / float(TAPS)) * radius;
			acc += textureLod(screen_tex, uv + vec2(cos(ga), sin(ga)) * r * SCREEN_PIXEL_SIZE, lod).rgb;
		}
		col = acc / float(TAPS);
	}
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	vec2 q = uv - 0.5;
	col *= 1.0 - dot(q, q) * vignette;
	COLOR = vec4(col, 1.0);
}
