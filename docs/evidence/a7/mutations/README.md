# A7 mutations (run by Claude Code, 2026-11-20)

Each in a throwaway git worktree `../a7-mutate` made from `ddb88a0` (`git worktree add ../a7-mutate HEAD`), applied with one `sed`, run through `scripts/run-test.sh` at 60 fps, then discarded with `git checkout -- .`; the worktree was removed afterwards. The unmutated read-backs passed in that worktree first (exit 0 both).

| # | mutation (diff file) | test | exit | what failed |
|---|---|---|---|---|
| 1 | rig track `Body/Mag:position:y` → `Body/Mag:positon:y`, in `pistol_reload.tres` only (`m1.diff`) | `test_pistol_reload_readback.gd` | **1** | `track_problems`: "Node2D has no property 'positon'"; track missing from the table; RESET has no matching key; magazine pose at 0.5 s not 64 (4 FAIL) |
| 2 | `keycard_spin.tres` `loop_mode = 1` → `0` (LOOP_NONE) (`m2.diff`) | `test_keycard_spin_readback.gd` | **1** | `loop_mode = LOOP_LINEAR (0)`; played after the wrap the sprite holds cell 7 instead of returning to 0 (2 FAIL) |
| 3 | one frame key `7` → `8` (`m3.diff`) | `test_keycard_spin_readback.gd` | **1** | key values; "every frame key is inside the sheet … 8"; played, the sprite stays on cell 6 where 8 was keyed, and Godot prints `Index p_frame = 8 is out of bounds` (3 FAIL) |
| 4 | delete `godot/.godot`, `--headless --import`, re-run both read-backs (`m4_reimport.log`) | both read-backs | **0 / 0** | nothing: 32 and 57 PASS lines, identical to the unmutated runs |

Mutation 4 does not fail, and is not expected to: the rig is a keyed cutout, not an imported model. The clips are `.tres` resource text and `RESET` lives in `pistol_rig.tscn`; a reimport rebuilds only `.godot/imported/` (for A7, just `keycard_sheet.png-….ctex`), so `loop_mode`, `step`, key times and tracks are untouched. This is the brief's Brief answer 7, observed.

The fifth (AnimatedSprite2D) mutation does not apply: no `AnimatedSprite2D` is used.
