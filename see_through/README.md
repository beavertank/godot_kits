# See-through where it matters

Objects (pillars, crane legs, trees, walls) that go see-through **only where they'd hide
something important**, and stay solid everywhere else. In Quayside the crane's legs fade where
they'd cover a container, so the player can always read the stacks. Works on every renderer,
with perspective or orthographic cameras.

## Use it

1. Give each object that might get in the way (an *occluder*) a **ShaderMaterial** with
   `see_through.gdshader` as its **material_override**. Set its color there.
2. Add a **Node** with `see_through_boxes.gd` (or a **SeeThroughBoxes** node). Add your occluders
   to **Occluders**, and the things that must stay visible to **Targets**.
3. Optional: **below_height** (object-local) limits the effect to part of the object, such as
   the legs of a crane but not its top.

Up to 32 targets (`MAX_BOXES`; change it in both files).

## How it works

Every frame the script sends each target's **world bounding box** to the occluders' material.
In the fragment shader, each pixel of an occluder casts a ray along the view toward the targets
and runs the classic **slab test** against each box. If the ray hits one, that pixel's alpha
drops to `see_through_alpha`.

```glsl
vec3 t0 = (box_lo - o) / d;   vec3 t1 = (box_hi - o) / d;
float t_in  = max(max(min(t0, t1).x, min(t0, t1).y), min(t0, t1).z);
float t_out = min(min(max(t0, t1).x, max(t0, t1).y), max(t0, t1).z);
bool hit = t_out > max(t_in, 0.0);
```

- **The view direction:** with an orthographic camera every pixel looks the same way, the
  camera's forward (`INV_VIEW_MATRIX[2]`). With perspective it's from the camera through the pixel.
  The shader checks the projection matrix to tell which.
- **The arrays are `vec4`, not `vec3`.** Arrays of `vec4` lay out the same on every renderer.

This is the opposite of the usual "show the player through walls" effect: here the object in
front only fades where it would get in the way.
