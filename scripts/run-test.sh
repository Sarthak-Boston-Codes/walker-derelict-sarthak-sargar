#!/usr/bin/env bash
# scripts/run-test.sh <test-file> <fps|realtime> [timeout-seconds]
# The assignment's wrapper, adapted for this Windows machine (Git Bash):
#  - Godot is not on PATH, so GODOT defaults to the local install.
#  - .tscn tests (the earlier suites are scenes) run as scenes; .gd tests
#    (extends SceneTree) run with --script, as in the original.
# Otherwise unchanged: realtime mode (no --fixed-fps), optional timeout,
# a kept log, and a failure on SHADER ERROR / SCRIPT ERROR lines.
set -o pipefail
GODOT="${GODOT:-/c/Users/sarth/GotDot/Godot_v4.7.2-stable_win64.exe}"
mkdir -p logs
if [ "$2" = "realtime" ]; then
	fps_args=(); tag="realtime"
else
	fps_args=(--fixed-fps "$2"); tag="${2}fps"
fi
name="$(basename "$1")"
log="logs/${name%.*}_${tag}.log"
case "$1" in
	*.tscn) target=("res://tests/$1") ;;
	*)      target=(--script "res://tests/$1") ;;
esac
timeout "${3:-120}" "$GODOT" --headless "${fps_args[@]}" --path godot "${target[@]}" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
