# Tilt-shift (miniature look)

A sharp band across the screen with the blur ramping up either side of it, plus a little extra
saturation and a vignette. It makes a 3D scene look like a model. One screen shader; works on
every renderer.

## Use it

1. Add a **CanvasLayer** (below your UI's layer), and in it a **ColorRect** set to *Full Rect*
   with *Mouse Filter: Ignore*.
2. Give the ColorRect a **ShaderMaterial** with `tilt_shift.gdshader`.
3. Set the band by hand (**band_center**, **band_angle**, **band_half_width**)...
4. ...or add a **Node** with `tilt_shift_band.gd` to aim it for you. Place four `Marker3D`s: two
   along the line the band should follow (a road, a shoreline) and one at each edge of what should
   be sharp. It re-aims every frame, so the band stays on them however the camera moves.

| Uniform | What it does |
|---|---|
| band_center | A point (screen UV) the band runs through |
| band_angle | Degrees; 0 = level across the screen |
| band_half_width | Half the sharp band's width, in screen heights |
| falloff | How far (screen heights) the blur takes to reach full strength |
| max_radius | The most blur, in pixels |
| saturation, vignette | 1 and 0 to turn them off |

## How it works

- Distances are measured in **"aspect space"** (UV with x multiplied by width/height), so a tilted
  band is the same width on any screen shape.
- Outside the band: 24 samples in a golden-angle spiral, read from a **blurrier mip level** further
  out (`hint_screen_texture, filter_linear_mipmap` + `textureLod`). The mips do most of the work,
  so a wide blur stays cheap.
- `tilt_shift_band.gd` projects your markers with `Camera3D.unproject_position` and turns them into
  a centre, an angle and a width.

Why not depth of field? Distance blur makes a band in the camera's terms. Tilt-shift wants the
band to follow something in the scene, which may run diagonally across the screen.
