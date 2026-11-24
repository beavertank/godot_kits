// Lens depth of field, pass 2 of 2 (see lens_dof.gd).
// On a full-screen ColorRect: blurs the finished frame by the blur map from pass 1, with a
// golden-angle spiral of samples. A sample only counts if its own blur reaches this pixel,
// so sharp edges don't bleed out into the blurry background behind them.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D coc_tex : filter_linear;     // pass 1's blur map (lens_dof.gd sets it)
uniform float max_radius = 0.014;              // the most blur, as a share of the screen height
uniform float coc_gamma = 1.0;                 // undoes any encoding of the grey levels

const int TAPS = 48;

float coc_at(vec2 uv) {
	return pow(texture(coc_tex, uv).r, coc_gamma);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float px_h = 1.0 / SCREEN_PIXEL_SIZE.y;            // screen height in pixels
	float radius = coc_at(uv) * max_radius * px_h;     // this pixel's blur, in pixels
	vec3 col = texture(screen_tex, uv).rgb;
	if (radius > 0.6) {
		vec3 acc = col;
		float wsum = 1.0;
		float lod = clamp(log2(radius / 6.0), 0.0, 3.0);   // mipmaps make big blurs cheap
		for (int i = 0; i < TAPS; i++) {
			float a = float(i) * 2.39996;                   // golden angle: no rings
			float r = sqrt((float(i) + 0.5) / float(TAPS)) * radius;
			vec2 o = vec2(cos(a), sin(a)) * r * SCREEN_PIXEL_SIZE;
			float ri = coc_at(uv + o) * max_radius * px_h;
			float w = smoothstep(r - 1.5, r + 0.5, ri);     // does its own blur reach here?
			acc += textureLod(screen_tex, uv + o, lod).rgb * w;
			wsum += w;
		}
		col = acc / wsum;
	}
	COLOR = vec4(col, 1.0);
}
