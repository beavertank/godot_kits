# Lens depth of field (works on Compatibility)

Blurs the view by distance from a focus point, like a real camera lens wide open. Godot's
Compatibility renderer has no depth of field built in; this adds it. It also works on Mobile and
Forward+ if you want this look rather than the built-in one.

## Use it

1. Copy this folder into your project.
2. Add a **Node** to your scene and attach `lens_dof.gd` (or add a **LensDOF** node).
3. Set **Camera** (blank = the current camera) and either **Focus Target** (a node to keep sharp)
   or **Focus Distance**.

| Setting | What it does |
|---|---|
| Aperture | How quickly things blur away from the focus. Higher = wider open, shallower focus |
| Sharp Zone | A little depth either side of the focus that stays fully sharp |
| Max Blur | The most blur, as a share of the screen height (0.014 is about 15 px at 1080p) |
| Focus Speed | How fast the focus eases onto a moving target (0 = instantly) |
| Render Layer | A layer nothing else in your game uses (default 20) |
| Canvas Layer | Where the blur draws. Keep it below your UI's CanvasLayers so the UI stays sharp |

## How it works

Two passes, because Compatibility can't do it in one:

1. **A blur map.** A hidden `SubViewport` (sharing your world) holds a copy of your camera. That
   copy sees one extra object, a full-screen quad on its own render layer. The quad's shader
   (`lens_coc.gdshader`) reads the depth buffer, turns it into a distance, and writes how blurred
   that pixel would be through a thin lens: `aperture × (|distance − focus| / distance − sharp)`.
2. **The blur.** A full-screen `ColorRect` (`lens_blur.gdshader`) takes 48 samples of the finished
   frame in a golden-angle spiral, using mipmaps for wide blurs. A sample only counts if its own
   blur reaches this pixel, so sharp objects don't smear into the blurry background behind them.

Why not a single full-screen 3D quad? In 3D, the screen texture is copied *before* transparent
objects draw, so a quad that rewrites the image would paint over your smoke, glass and particles.
The 2D pass sees the finished frame.

## Good to know

- **Cost:** the scene renders twice. Fine for cut-scenes, photo modes and recorded trailers; think
  twice before using it in normal play on low-end hardware.
- **Transparent things** don't write depth, so they take the blur of whatever's behind them.
- The blur map stores the blur amount (0–1), not depth. That's why an 8-bit SubViewport is
  enough. On start, the node writes a known grey and reads it back to check the encoding.
- The shader picks the right depth conversion for the renderer (`CURRENT_RENDERER`).
