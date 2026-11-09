"""Windows launcher for brutalist.art's remotion_scenes.py (unmodified).

remotion_scenes.py calls subprocess.run(["npx", ...]). On Windows npx is
npx.cmd, which CreateProcess does not find from the bare name ([WinError 2]).
This resolves "npx" to its full path and then runs the toolkit's own main().

  python run_remotion_win.py <REEL> --only B04 [--force]
"""
import shutil, subprocess, sys
from pathlib import Path

SCRIPTS = Path(r"C:\Users\sarth\brutalist.art\runtime\scripts")
sys.path.insert(0, str(SCRIPTS))
NPX = shutil.which("npx")
if not NPX:
    sys.exit("npx not on PATH (add C:\\Users\\sarth\\nodejs)")

_run = subprocess.run


def run(cmd, *a, **kw):
    if isinstance(cmd, list) and cmd and cmd[0] == "npx":
        cmd = [NPX] + cmd[1:]
    return _run(cmd, *a, **kw)


subprocess.run = run
import remotion_scenes  # noqa: E402

sys.argv = [str(SCRIPTS / "remotion_scenes.py")] + sys.argv[1:]
sys.exit(remotion_scenes.main())
