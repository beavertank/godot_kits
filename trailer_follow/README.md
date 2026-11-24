# Trailers that cut corners

Trucks, tractors, wagons, trains of carts: trailers that follow the way real ones do. On a turn
they swing inside the tractor's path, then straighten out after. No physics, fully
deterministic, a few lines.

## Use it

1. Move your tractor any way you like: a `PathFollow3D`, a `CharacterBody3D`, your own code.
2. Make each trailer a **Node3D whose origin is its kingpin** (where it hitches on), with its body
   extending backwards (+Z, since Godot's forward is −Z).
3. Add a **Node** with `trailer_chain.gd` (or a **TrailerChain** node). Set **Tractor**,
   **Trailers** (in order), **Hitch Offset** (the tractor's hitch, in its local space),
   **Axle Length** (kingpin to rear axle) and **Hitch Back** (kingpin to the next trailer's kingpin).

**Wheels:** `rolled[i]` is how far part *i* has rolled (0 = the tractor, then each trailer). Set a
wheel's rotation to `rolled[i] / wheel_radius`. Trailer wheels roll less on the inside of a turn,
like the real thing.

## How it works

Every frame, each trailer turns to point **from its rear axle toward its hitch**, and the axle is
put back at a fixed distance behind the hitch along that line:

```gdscript
var dir := (hitch - axle).normalized()     # point at the hitch
axle = hitch - dir * axle_length           # keep the axle at its length behind it
trailer.global_transform = Transform3D(Basis.looking_at(dir), hitch)
hitch -= dir * hitch_back                  # the next trailer hitches on here
```

The curve the axle traces is a **tractrix**, the path of something dragged on a rope. It cuts
inside the tractor's path on every turn. With two trailers the second cuts in further.

## Why not the obvious ways?

- **A `PathFollow3D` for each trailer, a set distance behind:** every trailer runs on the
  tractor's exact line, like carriages on rails. On a corner the back slides sideways. It looks
  wrong straight away.
- **Physics** (a `VehicleBody3D` and a joint): you do get real corner-cutting, but it's jittery at
  low speed, hard to stop exactly where you want, and different every run.

**One thing to plan for:** a trailer sweeps a wider area than its tractor. Anything that avoids
the vehicle (other traffic, pedestrians) has to check each trailer's own box, not just the path.
