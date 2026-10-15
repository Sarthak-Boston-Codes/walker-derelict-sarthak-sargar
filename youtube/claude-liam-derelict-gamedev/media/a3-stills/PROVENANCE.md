# a3-stills — provenance

Real engine images from the Assignment 3 build session (2026-10-15), copied unchanged (byte-identical) from where they were first written. Stills, not video. Files 01–06 are captures of the build as it happened; file 07 and its paired "before" are a **staged reconstruction** (see below).

Blender 5.2.2 LTS (build hash d13f752e3b9c), Godot 4.7.2.stable.official.ed1daf0bf.

| File | Size | sha256 | What it shows | How it was made | Original location |
|---|---|---|---|---|---|
| `blender_01_crate_before_srgb_fix.png` | 644×644 | `41a6f6d9d50554a2442b2fb0d4937fdd47ae6a9a20b03ca4dc59309293982c0c` | SupplyCrate, first build: brief colours entered as linear values, so the wood reads light tan | MCP `look`, angles front/right/top/three-quarter, Material Preview | Claude Code session tool-results, `mcp-blender-blob-1792088349464-7vu3b5.png` |
| `blender_02_crate_after_srgb_fix.png` | 644×644 | `eb11465a51800b32ff77c972da781ff855239ee1cd915027af178487ef5efe50` | SupplyCrate after sRGB → linear conversion: darker wood-brown, near-black straps | Same | `mcp-blender-blob-1792089059748-mwk5tl.png` |
| `blender_03_barrel.png` | 644×644 | `fc29f587aaa83fb1cda8946ddcd77212ce61ead334cef3b6e45e2aabaf791bca` | RustedBarrel, 12-sided cylinder, rust colour | Same | `mcp-blender-blob-1792089331829-dj8pyd.png` |
| `blender_04_medkit_original_cross.png` | 644×644 | `0c258d242e6b1e69dc46bef814e1114786bb61dd7d50b22a17c64aac373fe746` | Medkit, first build: cross arms 0.12 × 0.04 m | Same | `mcp-blender-blob-1792089722615-ei88um.png` |
| `blender_05_medkit_enlarged_cross.png` | 516×256 | `259f15b521e7ced99c66dcfaf3e41997c7f1828c878154f489513c142a61c784` | Medkit after the cross was enlarged to 0.14 × 0.045 m | MCP `look`, angles top/three-quarter only, Material Preview | `mcp-blender-blob-1792090544243-vey1k4.png` |
| `godot_06_showcase_final.png` | 1280×720 | `c04c3293cc6f406a052e2606b12c14408c0d093162cf9e944331421c3975269b` | Godot showcase scene, final camera (0, 1.6, 2.0) at −35°: crate, barrel, medkit with readable cross | Windowed run of `res://tests/showcase_3d_test.tscn -- --shot=<png>` (viewport capture after 5 frames); same run reported PASS, 0 failures | Claude Code session scratchpad, `showcase.png` |

## Hand-edit — STAGED RECONSTRUCTION (not a live capture of the original moment)

The author's original hand-edit (logged in FRICTIONAL.md, 2026-10-15: Medkit scaled 1.95508×, location unchanged) was measured and reverted, and no image of it was taken. This before/after pair stages that edit again so it can be shown. Label both on screen as a reconstruction.

| Role | File | Size | sha256 | What it shows | Source |
|---|---|---|---|---|---|
| Before | `design/blender/my_session.png` (repo path; not copied here) | 1917×1025 | `7a9c34411aedcaa4cd4df4876a02c79fb58075826b682b0064ee40b33d673fc7` | Author's Blender session, Medkit selected at Scale 1.000, location 0 m, Object Mode dropdown open | Author's own screenshot, committed in 2dcdcfb |
| After | `blender_07_handedit_after.png` | 1917×1023 | `9e06db79fd5e0135fdd9382e426e270eb81ee2c85e7b349930cb5b67aae9efa4` | Medkit after a staged S-key resize: Scale 1.897 on all axes, location still 0 m, "Resize" operator panel at bottom-left | Author's own screenshot, `Screenshot 2026-10-15 160246.png` (Windows Screenshots folder) |

Reconstruction limits:
- The staged scale (1.897067, measured via the MCP afterwards) is not the original 1.95508. Narrate the logged FRICTIONAL.md value, not the number visible in this still.
- The "before" was a real screenshot taken earlier, before the original hand-edit, not staged for this pair. It's used here as the reconstruction's starting state.
- The staged resize was confirmed, not cancelled. It was reset afterwards the same way as the original: scale set directly to 1,1,1 (not applied), 0.3 × 0.2 × 0.15 m on the ground, `medkit.glb` re-exported byte-identical to the committed version, `showcase_3d_test` PASS with 0 failures.
- In the "after" still the timeline is playing (frame 185, Anim Player). Medkit has no animation, so this doesn't affect what's shown.

## Limits
- Blender images 01–05 are viewport Material Preview captures with Blender's built-in preview lighting and the AgX view transform — not final renders. AgX shifts on-screen colour slightly from the stored material values.
- The showcase screenshot was overwritten on each run, so only the final state survives. The earlier screenshots (camera pointing at the sky; the original −20° camera with the small cross) no longer exist.
- Files 01–06 don't show the author's hand-edit. Only the staged reconstruction above does.
