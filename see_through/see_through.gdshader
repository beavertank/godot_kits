// See-through where it matters: an object (a pillar, a crane leg, a tree) goes see-through
// only where it's in front of something important, so the player can always read it.
// Works on every renderer. see_through_boxes.gd feeds it the important things' bounding boxes
// each frame; every pixel casts a ray toward them along the view and tests each box.
shader_type spatial;
render_mode cull_back, depth_draw_always;

#define MAX_BOXES 32

uniform vec4 albedo : source_color = vec4(0.95, 0.75, 0.1, 1.0);
uniform float roughness = 0.6;
uniform float see_through_alpha = 0.3;   // how solid it is where it covers something
uniform float below_height = 1.0e9;      // only object-local heights below this go see-through
uniform int box_count = 0;
uniform vec4 box_lo[MAX_BOXES];          // world AABB corners. vec4 (xyz used), not vec3:
uniform vec4 box_hi[MAX_BOXES];          // arrays of vec4 lay out the same on every renderer

varying vec3 world_pos;
varying float local_y;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_y = VERTEX.y;
}

// The ray o + t*d (t > 0) against each box: the classic slab test.
bool covers_box(vec3 o, vec3 d) {
	vec3 inv = 1.0 / d;
	for (int i = 0; i < MAX_BOXES; i++) {
		if (i >= box_count) {
			break;
		}
		vec3 t0 = (box_lo[i].xyz - o) * inv;
		vec3 t1 = (box_hi[i].xyz - o) * inv;
		vec3 tmin = min(t0, t1);
		vec3 tmax = max(t0, t1);
		float t_in = max(max(tmin.x, tmin.y), tmin.z);
		float t_out = min(min(tmax.x, tmax.y), tmax.z);
		if (t_out > max(t_in, 0.0)) {
			return true;
		}
	}
	return false;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	float a = 1.0;
	if (local_y < below_height && box_count > 0) {
		// the direction we're looking through this pixel: one direction for the whole screen
		// with an orthographic camera, from the camera through the pixel with a perspective one
		bool ortho = PROJECTION_MATRIX[3][3] == 1.0;
		vec3 dir = ortho ? -normalize(INV_VIEW_MATRIX[2].xyz) : normalize(world_pos - CAMERA_POSITION_WORLD);
		if (covers_box(world_pos, dir)) {
			a = see_through_alpha;
		}
	}
	ALPHA = albedo.a * a;
}
