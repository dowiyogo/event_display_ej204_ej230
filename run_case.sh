#!/usr/bin/env bash
set -euo pipefail

exe=$1
macro=$2
outdir=$3

DISPLAY_NUM=:99
SCREEN_GEOM=1600x900x24

rm -f "$outdir/run.log" "$outdir/geometry.png" "$outdir/event_full.png" "$outdir/event_zoom.png"
: > "$outdir/run.log"

workdir=$(mktemp -d /tmp/event_display_ej204_ej230.XXXXXX)
trap 'rm -rf "$workdir"; kill "$xvfb_pid" >/dev/null 2>&1 || true' EXIT

mkdir -p "$workdir/macros"
cp "$macro" "$workdir/macros/vis.mac"

Xvfb "$DISPLAY_NUM" -screen 0 "$SCREEN_GEOM" >/tmp/event_display_xvfb.log 2>&1 &
xvfb_pid=$!

export DISPLAY="$DISPLAY_NUM"
export GEANT4_USE_X11=1

fifo="/tmp/event_display_ej204_ej230_$$.fifo"
rm -f "$fifo"
mkfifo "$fifo"

find_viewer_window() {
  python3 - <<'PY'
import ctypes
import ctypes.util
import os
import sys

libx11 = ctypes.cdll.LoadLibrary(ctypes.util.find_library('X11'))

libx11.XOpenDisplay.argtypes = [ctypes.c_char_p]
libx11.XOpenDisplay.restype = ctypes.c_void_p
libx11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
libx11.XDefaultRootWindow.restype = ctypes.c_ulong
libx11.XQueryTree.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.POINTER(ctypes.c_ulong)), ctypes.POINTER(ctypes.c_uint)]
libx11.XQueryTree.restype = ctypes.c_int
libx11.XFree.argtypes = [ctypes.c_void_p]
libx11.XFree.restype = ctypes.c_int

display = libx11.XOpenDisplay(os.environ.get('DISPLAY', ':99').encode())
if not display:
  sys.exit(1)
root = libx11.XDefaultRootWindow(display)
root_return = ctypes.c_ulong()
parent_return = ctypes.c_ulong()
children_return = ctypes.POINTER(ctypes.c_ulong)()
nchildren = ctypes.c_uint()
if not libx11.XQueryTree(display, root, ctypes.byref(root_return), ctypes.byref(parent_return), ctypes.byref(children_return), ctypes.byref(nchildren)):
  sys.exit(1)

best = children_return[0] if nchildren.value > 0 else 0

if children_return:
  libx11.XFree(children_return)

if best:
  print(best)
PY
}

(
  cd "$workdir"
  "$exe" > "$outdir/run.log" 2>&1 < "$fifo"
) &
app_pid=$!

exec 3>"$fifo"
case_name=$(basename "$macro")
if [[ "$case_name" == geometry_* ]]; then
  until grep -q "Checking overlaps for volume" "$outdir/run.log"; do :; done
  printf '/vis/viewer/refresh\n' >&3
  printf '/vis/viewer/flush\n' >&3
  window_id=$(find_viewer_window)
  printf '%s\n' "$window_id" > "$outdir/window_id.txt"
  timeout 20s import -window "$window_id" "$outdir/geometry.png" || true
  printf 'exit\n' >&3
else
  until grep -q "=== EJ Scintillator Bar Run Summary ===" "$outdir/run.log"; do :; done
  printf '/vis/viewer/refresh\n' >&3
  printf '/vis/viewer/flush\n' >&3
  window_id=$(find_viewer_window)
  printf '%s\n' "$window_id" > "$outdir/window_id.txt"
  timeout 20s import -window "$window_id" "$outdir/event_full.png" || true
  printf '/vis/viewer/set/viewpointThetaPhi 55 20\n' >&3
  printf '/vis/viewer/zoom 1.8\n' >&3
  printf '/vis/viewer/refresh\n' >&3
  printf '/vis/viewer/flush\n' >&3
  window_id=$(find_viewer_window)
  printf '%s\n' "$window_id" > "$outdir/window_id_zoom.txt"
  timeout 20s import -window "$window_id" "$outdir/event_zoom.png" || true
  printf 'exit\n' >&3
fi

exec 3>&-
wait "$app_pid"
rm -f "$fifo"
