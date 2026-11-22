"""Windows launcher for brutalist.art's compile.py (unmodified).

The --review cut burns a running timecode with ffmpeg drawtext, passing the
font as fontfile=C:\\...; the drive-letter colon breaks ffmpeg's filtergraph
parser on Windows. This makes compile.py's own has_drawtext() report False,
so it takes its existing no-drawtext path: no timecode clock, everything else
(beat labels, audio assembly, preserve beats, QC sheet) unchanged.

--low-mem (A7, Claude Code): the final 4K concat encode (libx264 -preset slow
-crf 16 over the whole film) took about 7 GB on this 16 GB machine and was
stopped at 387 MB free. With --low-mem, that one ffmpeg command (the one that
reads the concat list and uses -preset slow) gets
  -threads 4 -x264-params rc-lookahead=20
inserted before the output; CRF, preset, pixel format and audio are unchanged.
Per-beat clip encodes and every other command are untouched.
That still peaked at ~5 GB (stopped at 2026 MB free), so:
--low-mem-tight: decoder -threads 2 (before the concat input) and encoder
  -threads 2 -x264-params rc-lookahead=10; -preset slow, CRF 16 unchanged.
--preset-medium: the same caps plus -preset medium (CRF 16 unchanged); the one
  allowed fallback if --low-mem-tight is also stopped below 2 GB free.

  python run_compile_win.py <REEL> --review --fps 30 --height 1080
  python run_compile_win.py <REEL> --height 2160 --fps 30 --out exports/landscape --low-mem-tight
"""
import sys
from pathlib import Path

SCRIPTS = Path(r"C:\Users\sarth\brutalist.art\runtime\scripts")
sys.path.insert(0, str(SCRIPTS))
import compile as compile_mod  # noqa: E402  (brutalist.art/runtime/scripts/compile.py)

compile_mod.has_drawtext = lambda: False

LOW_MEM = "--low-mem" in sys.argv
TIGHT = "--low-mem-tight" in sys.argv
MEDIUM = "--preset-medium" in sys.argv
args = [a for a in sys.argv[1:] if a not in ("--low-mem", "--low-mem-tight", "--preset-medium")]

if LOW_MEM or TIGHT or MEDIUM:
    _sh = compile_mod.sh

    def sh(cmd, **kw):
        c = [str(x) for x in cmd]
        if "concat" in c and "-preset" in c and c[c.index("-preset") + 1] == "slow" and "-crf" in c:
            cmd = list(cmd)
            note = []
            if TIGHT or MEDIUM:
                # decoder side: before the first input (the concat list)
                j = c.index("-i")
                cmd = cmd[:j] + ["-threads", "2"] + cmd[j:]
                c = [str(x) for x in cmd]
                enc = ["-threads", "2", "-x264-params", "rc-lookahead=10"]
                note.append("decoder -threads 2; encoder -threads 2 -x264-params rc-lookahead=10")
            else:
                enc = ["-threads", "4", "-x264-params", "rc-lookahead=20"]
                note.append("encoder -threads 4 -x264-params rc-lookahead=20")
            if MEDIUM:
                cmd[c.index("-preset") + 1] = "medium"
                note.append("-preset medium (CRF 16 unchanged)")
            i = c.index("-crf") + 2
            cmd = cmd[:i] + enc + cmd[i:]
            print("[low-mem] final encode: " + "; ".join(note), flush=True)
        return _sh(cmd, **kw)

    compile_mod.sh = sh

sys.argv = [str(SCRIPTS / "compile.py")] + args
sys.exit(compile_mod.main())
