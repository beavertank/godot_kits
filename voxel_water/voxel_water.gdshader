// Stepped voxel water: a flat grid of cells that bob up and down in whole steps, with white
// caps on the crests. Works on every renderer. Use it with voxel_water.gd, which builds the
// mesh this expects and feeds the wind:
//   UV  = the cell's centre (mesh-local xz), the same for every vertex of a cell, so the whole
//         cell moves together and stays a square block
//   UV2 = (moves with the wave 1/0, is a side face 1/0)
shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep : source_color = vec4(0.08, 0.40, 0.78, 1.0);
uniform vec4 crest : source_color = vec4(0.82, 0.93, 1.0, 1.0);
uniform float step_h = 0.25;        // one step of height
uniform float chop = 1.45;          // > 1: shorter, busier waves
// fed every frame by voxel_water.gd: the clock and drift add up on the CPU, so changing the
// wind speeds the waves up smoothly instead of making them jump
uniform float wave_t = 0.0;
uniform vec2 drift = vec2(0.0);     // how far the pattern has travelled downwind
uniform float wind = 0.5;           // 0 calm .. 1 strong

varying float v_level;              // -1, 0 or +1
varying float v_cap;                // 1 on a white crest
varying float v_side;

float wave(vec2 c, float t) {
	float a = sin(c.x * 0.30 + t + sin(c.y * 0.37 + t * 0.4) * 1.6);
	float b = sin(c.y * 0.46 - t * 0.7 + c.x * 0.13);
	float d = sin((c.x + c.y) * 0.21 + t * 0.55);
	return a * 0.5 + b * 0.32 + d * 0.18;
}

void vertex() {
	vec2 c = (MODEL_MATRIX * vec4(UV.x, 0.0, UV.y, 1.0)).xz;   // the cell's centre in the world
	vec2 p = c - drift;
	float w = wave(p * chop, wave_t);
	// calm: most cells stay level; windy: nearly every cell steps up or down
	float level = clamp(round(w * (1.1 + 1.1 * wind)), -1.0, 1.0);
	VERTEX.y += level * step_h * UV2.x;
	v_level = level;
	// white caps: raised cells where a second, faster pattern also peaks (more in a wind)
	vec2 q = c - drift * 1.3;
	float w2 = sin(q.x * 0.71 + q.y * 0.53 + wave_t * 0.8) * sin(q.y * 0.9 - q.x * 0.2 - wave_t * 0.5);
	v_cap = (level > 0.5 && w2 > 0.84 - 0.32 * wind) ? 1.0 : 0.0;
	v_side = UV2.y;
}

void fragment() {
	vec3 col = deep.rgb * (1.0 + v_level * 0.09);   // higher cells a touch lighter
	col = mix(col, crest.rgb, v_cap * 0.85);
	col *= 1.0 - v_side * 0.12;                      // side faces a little darker
	ALBEDO = col;
	ROUGHNESS = 0.55;
	SPECULAR = 0.25;
}
