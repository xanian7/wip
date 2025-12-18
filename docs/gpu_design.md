GPU Per-Pixel Simulation Design (Godot 4.4)
==========================================

Status: Design doc for Path A (fragment / ping-pong shaders). This file describes data layout, shader passes, Godot node architecture, persistence, collision extraction, debugging, and a concrete prototype plan.

Goals
-----
- Real-time 2D per-pixel simulation (Noita-like) using GPU ping-pong fragment shaders in Godot 4.4.
- Keep simulation on GPU as much as possible; minimize expensive readbacks.
- Provide a clear upgrade path to compute shaders or native GDExtension later.

Assumptions
-----------
- Target engine: Godot 4.4.
- Platform: desktop (Windows/macOS/Linux) with a GPU supporting floating-point textures and standard shader features.
- Determinism: not strictly required for first prototype (GPU FP ops may vary across drivers). If determinism becomes a hard requirement, we'll add a CPU fallback.
- Initial prototype resolution: 256×256 (configurable). We'll scale later.

Data layout
-----------
Primary simulation state: 2D texture (ping-pong A/B). Each texel stores the canonical per-cell state. Two main format options:

- RGBA32F (recommended for prototyping): float precision; easier math; higher memory cost.
  - R: material id (as float index: 0.0 = empty, 1.0 = sand, 2.0 = water, etc.)
  - G: mass / density (0..1)
  - B: temperature / energy (float)
  - A: flags / lifetime / misc (0..1)

- RGBA8 (space optimized): pack integers; requires careful encoding/decoding.

Auxiliary textures (optional):
- Velocity texture (RG16F / RG32F) for per-cell 2D velocity.
- Activity mask (R8): 0/1 per texel marking active cells.
- Palette (1D or small 2D) mapping material id -> color/visual params.
- Reaction LUTs (small textures) for pairwise interactions.

Memory example: 1024×1024 RGBA32F ~ 16 MB per texture; two ping-pong textures ~32 MB.

Shader pipeline (passes)
------------------------
A set of render-to-texture passes per timestep (each pass draws a fullscreen quad which reads from previous state textures and writes to the target ping texture):

1) Stamp / Input pass (optional)
   - Apply player/editor brushes, stamps or externally injected edits into the state texture.

2) Advection / Movement pass
   - Implements falling solids, liquid advection, or simple velocity advection rules.
   - Read neighbors and decide new material/mass per texel.

3) Diffusion / Heat pass
   - Diffuse temperature and energy fields; decay heat sources.

4) Reaction / Interaction pass
   - Resolve chemical reactions (e.g., water+lava -> steam) and create new materials and energy.

5) Phase / Constraint pass
   - Clamp mass, handle melting/solidification.

6) Activity mask pass (optional)
   - Update per-texel or per-chunk activity flags for selective updates.

7) Render pass
   - Map material id + properties to final color via palette texture, post-process for smoothing.

Important: ordering and update rules matter; consider checkerboard updating or alternating passes to reduce directional bias.

Godot integration (high-level)
------------------------------
- Implement ping-pong using two `Viewport` nodes (each acts as a render target). Each Viewport contains a `ColorRect` (or Sprite2D) sized to the sim resolution and using a `ShaderMaterial` that implements a pass. The Viewport's render target texture is passed as a uniform to the other pass's shader for sampling.
- A controller script (e.g., `scripts/simulator.gd`) orchestrates pass order, ping-pong swapping, brush injection, and debug visualization.
- Display: Render final state texture to a `Sprite2D`/`TextureRect` or as an overlay using a drawing node and shader.
- Brush/stamp: implement as an extra shader pass that blends a brush shape/ID into the state texture prior to simulation passes.

Collision & engine physics
--------------------------
- Keep GPU sim as authoritative for visuals. For physics interactions (rigidbodies, player collision):
  - Periodically (per-chunk) read back texel data for chunks that changed and run a convex/contour extractor (marching squares) on CPU to produce simplified polygons.
  - Create `CollisionPolygon2D`/`CollisionShape2D` nodes or `ConcavePolygonShape2D` where needed.
  - Do readbacks asynchronously and update collision geometry off the main thread where possible.

Persistence
-----------
- Save per-chunk textures or compact deltas. Use zlib compression; include version header.
- For large procedurally-generated base worlds, save only deltas relative to the base seed.

Performance strategies
----------------------
- Active-region simulation: maintain a per-chunk active flag (e.g., 64×64 chunks). Only run full passes for active chunks or sample their region.
- Multi-resolution: near-player area at full resolution; distant areas lower-res.
- Temporal spreading: update only a subset of heavy chunks per frame.
- Consider moving to compute shaders if fragment-based pipeline hits limits.

Determinism & portability
-------------------------
- GPU float ops and optimizations vary by driver/hardware; CPU fallback or recording of inputs may be necessary for exact replay or lockstep multiplayer.

Debugging aids
--------------
- Shader debug modes: expose flags to show material ids, temperature, activity, and intermediate pass textures.
- Visualization shaders to color-code materials and show deltas.

Prototype plan (concrete)
-------------------------
Phase 1 — Minimal working pipeline (Goal: visual, simple sand gravity)
- Resolution: 256×256
- Materials: 0 = empty, 1 = sand, 2 = water
- Implement one shader pass that implements a simple "sand falls" rule using neighbor sampling.
- Use two `Viewport` nodes for ping-pong and a `Sprite2D` to display the current texture.
- Implement brush input that writes material ids into the state texture as a stamp before the simulation pass.

Phase 2 — Additional passes
- Add diffusion/heat, reaction pass using LUTs, and activity mask.
- Add chunking logic and per-chunk active flags.

Phase 3 — Performance
- Profile; if CPU-GPU balance is insufficient, migrate heavy passes to compute shaders via GDExtension or engine's compute features.

Testing
-------
- Visual tests: place sand/water and observe expected behavior.
- Performance tests: measure ms per frame at multiple resolutions.
- Save/load round-trip tests for chunk persistence.

Open questions / decisions to make
---------------------------------
- Initial prototype resolution (I propose 256×256). Are you happy with that?
- Material set / initial behavior complexity (start small: sand + water + empty).
- Determinism requirement? (important for multiplayer or replay)

Next steps
----------
- Implement the Phase 1 scaffold (shader + simulator controller + simple brush) in the repo and iterate. This will be a GPU fragment shader, ping-pong pass implementation in Godot 4.4.

Notes about implementation in this workspace
-------------------------------------------
- I will add: `docs/gpu_design.md`, `shaders/sim_pass.shader`, `scripts/simulator.gd`, and modify `scripts/world.gd` to instantiate the simulator.
- I cannot run Godot here to verify behavior; the code is scaffolded and may need small tweaks when run in the engine. I will mark the exact assumptions in the commit comments.

