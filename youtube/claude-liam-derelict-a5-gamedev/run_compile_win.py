"""Windows launcher for brutalist.art's compile.py (unmodified).

The --review cut burns a running timecode with ffmpeg drawtext, passing the
font as fontfile=C:\\...; the drive-letter colon breaks ffmpeg's filtergraph
parser on Windows. This makes compile.py's own has_drawtext() report False,
so it takes its existing no-drawtext path: no timecode clock, everything else
(beat labels, audio assembly, preserve beats, QC sheet) unchanged.

  python run_compile_win.py <REEL> --review --fps 30 --height 1080
"""
import sys
from pathlib import Path

SCRIPTS = Path(r"C:\Users\sarth\brutalist.art\runtime\scripts")
sys.path.insert(0, str(SCRIPTS))
import compile as compile_mod  # noqa: E402  (brutalist.art/runtime/scripts/compile.py)

compile_mod.has_drawtext = lambda: False
sys.argv = [str(SCRIPTS / "compile.py")] + sys.argv[1:]
sys.exit(compile_mod.main())
