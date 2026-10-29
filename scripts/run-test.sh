#!/usr/bin/env bash
# scripts/run-test.sh <test-file> <fps>
# The assignment's wrapper, adapted for this Windows machine (Git Bash):
#  - Godot isn't on PATH, so GODOT defaults to the local install.
#  - .tscn tests (the earlier suites are scenes) run as scenes;
#    .gd tests (extends SceneTree) run with --script, as in the original.
# Otherwise unchanged: timeout, pinned frame rate, a kept log, and a
# failure on SHADER ERROR / SCRIPT ERROR lines. Exit status 124 = hung.
set -o pipefail
GODOT="${GODOT:-/c/Users/sarth/GotDot/Godot_v4.7.2-stable_win64.exe}"
mkdir -p logs
name="$(basename "$1")"
log="logs/${name%.*}_${2}fps.log"
case "$1" in
  *.tscn) target=("res://tests/$1") ;;
  *)      target=(--script "res://tests/$1") ;;
esac
timeout 120 "$GODOT" --headless --path godot "${target[@]}" --fixed-fps "$2" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
