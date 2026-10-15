"""Step 1 media for the A3 film: 4K captures of the showcase scene and the test
logs, each from an isolated copy of godot/ so the real project is never modified.

  python make_media.py SCRATCH_DIR [--only B11,B13,B16,B18,B19]

  B11  showcase, the scene's own camera, 8 s            -> media/action/B11.mp4
  B13  showcase_3d_test on HEAD                         -> logs/showcase_pass.log
  B16  showcase_3d_test with the hand-edit medkit.glb   -> logs/showcase_handedit_fail.log
  B18  scene camera at b74d239 vs HEAD, one 4K frame each -> captures/b18_*.png
  B19  capture-only orbit camera, 14 s                  -> media/action/B19.mp4

Writes captures/MEDIA-LEDGER.json (inputs, revisions, commands, sha256s).
"""
import hashlib, io, json, os, shutil, subprocess, sys, tarfile
from pathlib import Path

GODOT = r"C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64_console.exe"
ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
CAPS = FILM / "captures"
ACTION = FILM / "media" / "action"
LOGS = FILM / "logs"
SCRATCH = Path(sys.argv[1])
ONLY = set(sys.argv[sys.argv.index("--only") + 1].split(",")) if "--only" in sys.argv else None
HANDEDIT_GLB = CAPS / "medkit_handedit_scale_1.95508.glb"  # exported from Blender with scale 1.95508, not applied
FPS = 30


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def git(*args):
    return subprocess.run(["git", "-C", str(REPO), *args], capture_output=True, text=True, check=True).stdout.strip()


def run(args, env=None):
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace",
                       env=dict(os.environ, **(env or {})))
    for line in (r.stdout + r.stderr).splitlines():
        if "SCRIPT ERROR" in line or "Parse Error" in line or line.startswith("saved "):
            print("   ", line)
    return r


def rmtree(p):
    if p.exists():  # \\?\ prefix: the imported .godot cache has paths past MAX_PATH
        shutil.rmtree("\\\\?\\" + str(p.resolve()))


def isolated_copy(name, rev=None):
    """Copy godot/ (working tree, or a git revision) without the .godot cache, then import."""
    dst = SCRATCH / name
    rmtree(dst)
    if rev:
        tar = subprocess.run(["git", "-C", str(REPO), "archive", rev, "godot"], capture_output=True, check=True).stdout
        tarfile.open(fileobj=io.BytesIO(tar)).extractall(dst, filter="data")
        dst = dst / "godot"
    else:
        shutil.copytree(REPO / "godot", dst, ignore=shutil.ignore_patterns(".godot"))
    run([GODOT, "--headless", "--path", str(dst), "--import"])
    return dst


def capture(project, mode, frames, name):
    frames_dir = SCRATCH / f"frames_{name}"
    rmtree(frames_dir)
    cmd = [GODOT, "--path", str(project), "--fixed-fps", str(FPS), "-s", str(ROUTES / "showcase_capture.gd")]
    run(cmd, env={"MODE": mode, "FRAMES": str(frames), "OUT": str(frames_dir)})
    pngs = sorted(frames_dir.glob("f*.png"))
    assert len(pngs) == frames, (name, len(pngs), frames)
    return frames_dir, pngs, " ".join(["godot", "--path", "<isolated copy>", "--fixed-fps", str(FPS), "-s",
                                       "showcase_capture.gd", f"(MODE={mode} FRAMES={frames})"])


def encode(frames_dir, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(FPS), "-i", str(frames_dir / "f%05d.png"),
                    "-c:v", "libx264", "-preset", "slow", "-crf", "12", "-pix_fmt", "yuv420p", str(out)], check=True)


def test_log(project, out, label):
    r = subprocess.run([GODOT, "--headless", "--path", str(project), "res://tests/showcase_3d_test.tscn"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    body = "\n".join(l for l in r.stdout.splitlines() if l.strip() and not l.startswith("Godot Engine"))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(f"# {label}\n$ godot --headless --path godot res://tests/showcase_3d_test.tscn\n{body}\n"
                   f"[exit code {r.returncode}]\n", encoding="utf-8")
    print(f"    {out.name}: exit {r.returncode}")
    return r.returncode


def want(b):
    return ONLY is None or b in ONLY


ledger_path = CAPS / "MEDIA-LEDGER.json"
ledger = json.loads(ledger_path.read_text(encoding="utf-8")) if ledger_path.exists() else {}
ledger.update({"godot": "4.7.2.stable.official.ed1daf0bf", "repo_head": git("rev-parse", "--short", "HEAD"),
               "capture_size": "3840x2160 SubViewport (window is capped at the 1920x1080 screen)",
               "fps": FPS})
SCRATCH.mkdir(parents=True, exist_ok=True)
head = isolated_copy("iso_head") if any(want(b) for b in ("B11", "B13", "B18", "B19")) else SCRATCH / "iso_head"

if want("B11"):
    d, pngs, cmd = capture(head, "scene", 8 * FPS, "B11")
    encode(d, ACTION / "B11.mp4")
    ledger["B11"] = {"media": "media/action/B11.mp4", "sha256": sha(ACTION / "B11.mp4"), "source": "iso_head",
                     "revision": ledger["repo_head"], "camera": "scene Camera3D (0, 1.6, 2.0) at -35 deg",
                     "frames": len(pngs), "seconds": len(pngs) / FPS, "command": cmd,
                     "note": "static scene: nothing animates; the clip shows the scene as it runs"}

if want("B13"):
    code = test_log(head, LOGS / "showcase_pass.log", f"HEAD {ledger['repo_head']}, isolated copy")
    ledger["B13"] = {"log": "logs/showcase_pass.log", "sha256": sha(LOGS / "showcase_pass.log"),
                     "exit_code": code, "source": "iso_head", "revision": ledger["repo_head"]}

if want("B16"):
    hand = isolated_copy("iso_handedit")
    shutil.copyfile(HANDEDIT_GLB, hand / "assets" / "3d" / "medkit.glb")
    run([GODOT, "--headless", "--path", str(hand), "--import"])
    code = test_log(hand, LOGS / "showcase_handedit_fail.log",
                    "isolated copy, medkit.glb replaced by a Blender export at scale 1.95508 (not applied)")
    ledger["B16"] = {"log": "logs/showcase_handedit_fail.log", "sha256": sha(LOGS / "showcase_handedit_fail.log"),
                     "exit_code": code, "source": "iso_handedit (HEAD copy + hand-edit medkit.glb)",
                     "handedit_glb": {"path": "captures/medkit_handedit_scale_1.95508.glb", "sha256": sha(HANDEDIT_GLB),
                                      "made": "Blender MCP: Medkit scale set to 1.95508 (FRICTIONAL.md value), "
                                              "exported, scale reset to 1; .blend not saved"},
                     "label": "DEMONSTRATION on an isolated copy, not the shipped build"}

if want("B18"):
    old = isolated_copy("iso_b74d239", "b74d239")
    for tag, proj in (("before_b74d239", old), ("after_head", head)):
        d, pngs, cmd = capture(proj, "scene", 1, f"B18_{tag}")
        shutil.copyfile(pngs[0], CAPS / f"b18_{tag}.png")
        ledger[f"B18_{tag}"] = {"still": f"captures/b18_{tag}.png", "sha256": sha(CAPS / f"b18_{tag}.png"),
                                "revision": "b74d239" if tag.startswith("before") else ledger["repo_head"],
                                "command": cmd}

if want("B19"):
    d, pngs, cmd = capture(head, "orbit", 14 * FPS, "B19")
    encode(d, ACTION / "B19.mp4")
    ledger["B19"] = {"media": "media/action/B19.mp4", "sha256": sha(ACTION / "B19.mp4"), "source": "iso_head",
                     "revision": ledger["repo_head"], "frames": len(pngs), "seconds": len(pngs) / FPS,
                     "camera": "CaptureCamera added by showcase_capture.gd: one turn at 28 deg, then 60 deg more "
                               "dipping to -12 deg (below the floor). Not the scene's camera.", "command": cmd}

ledger_path.write_text(json.dumps(ledger, indent=2), encoding="utf-8")
print("ledger:", {k: v.get("exit_code", v.get("sha256", "")[:12]) for k, v in ledger.items() if isinstance(v, dict)})
