# Shader and script kits from Quayside

Small, standalone pieces from Quayside, a cozy container-port game made in Godot 4 on the
Compatibility renderer. Every kit works on all three renderers (Compatibility, Mobile, Forward+),
and each folder has an `example.tscn` you can open and run.

| Folder | What it is | Files |
|---|---|---|
| `lens_dof/` | Depth of field, including on Compatibility (which has none built in) | `lens_dof.gd`, `lens_coc.gdshader`, `lens_blur.gdshader` |
| `tilt_shift/` | The "miniature" tilt-shift look, with an optional helper that aims the band at your world | `tilt_shift.gdshader`, `tilt_shift_band.gd` |
| `voxel_water/` | Water that moves in whole voxel steps, with white caps and wind | `voxel_water.gdshader`, `voxel_water.gd` |
| `see_through/` | Objects that go see-through only where they'd hide something important | `see_through.gdshader`, `see_through_boxes.gd` |
| `trailer_follow/` | Trailers that are dragged, not steered, so they cut corners like real ones | `trailer_chain.gd` |

**Using one:** copy its folder into your project. The scripts load their shaders by relative
path, so any location works. The `example_*.gd` files and `example.tscn` are only for the demo.

Made with Godot 4.7. Licence: *(add yours here, e.g. CC0 or MIT)*.
