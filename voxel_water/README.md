# Stepped voxel water

Toy-like water: a grid of square cells that each sit level, one step up or one step down,
shifting as waves roll through, with white caps on the crests. More wind means more cells
stepping, faster waves and more white caps. Works on every renderer.

## Use it

1. Add a **MeshInstance3D** and attach `voxel_water.gd` (or add a **VoxelWater** node).
2. Set **Cells X / Z** and **Cell Size**, and **Wind** (0 calm to 1 strong) and its direction.
3. Colors and step height are on the shader material (**deep**, **crest**, **step_h**, **chop**).

For a sea bigger than the patch, keep the patch small and call `follow(camera_focus_point)` each
frame. It moves in whole cells, so the wave pattern (which lives in world space) never slides.

## How it works

- **The mesh trick.** Each cell is a top quad plus the two side faces the camera can see (+X and
  +Z; add the other two if your camera goes all the way round). **Every vertex stores its cell's
  centre in UV**, so the vertex shader computes one height per cell and the cell moves as a
  solid block. UV2 marks whether a vertex moves with the wave (the bottoms of the side faces
  don't) and whether it's on a side face (for shading).
- **The shader** adds up three sine waves at the cell's centre and **rounds** the result to −1, 0
  or +1 steps. White caps: raised cells where a second, faster pattern also peaks.
- **The wind clock runs on the CPU** (`voxel_water.gd` adds to it each frame) instead of
  `TIME * speed` in the shader. That way changing the wind speeds the waves up smoothly instead
  of making them jump.
