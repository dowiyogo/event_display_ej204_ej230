#!/usr/bin/env bash
set -euo pipefail

exe=$1
macro=$2
outdir=$3
image_name=${4:-native_view.png}
keep_open=${KEEP_OPEN:-0}

display_num=${DISPLAY_NUM:-:120}
screen_geom=${SCREEN_GEOM:-1600x900x24}

mkdir -p "$outdir"
rm -f "$outdir/$image_name" "$outdir/run.log" "$outdir/viewer_windows.txt"

workdir=$(mktemp -d /tmp/event_display_native.XXXXXX)

cleanup() {
  if [[ "$keep_open" != "1" ]]; then
    rm -rf "$workdir"
    kill "$app_pid" >/dev/null 2>&1 || true
    kill "$xvfb_pid" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

mkdir -p "$workdir/macros"
cp "$macro" "$workdir/macros/vis.mac"

exe_dir=$(dirname "$exe")
for resource_dir in sslg4 data; do
  if [[ -d "$exe_dir/$resource_dir" ]]; then
    cp -R "$exe_dir/$resource_dir" "$workdir/"
  fi
done

Xvfb "$display_num" -screen 0 "$screen_geom" >/tmp/event_display_native_xvfb.log 2>&1 &
xvfb_pid=$!

export DISPLAY="$display_num"
export GEANT4_USE_X11=1
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe

(
  cd "$workdir"
  "$exe" > "$outdir/run.log" 2>&1
) &
app_pid=$!

find_viewer_window() {
  python3 - <<'PY'
import ctypes
import ctypes.util
import os
import re
import sys

libx11 = ctypes.cdll.LoadLibrary(ctypes.util.find_library('X11'))

libx11.XOpenDisplay.argtypes = [ctypes.c_char_p]
libx11.XOpenDisplay.restype = ctypes.c_void_p
libx11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
libx11.XDefaultRootWindow.restype = ctypes.c_ulong
libx11.XQueryTree.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.POINTER(ctypes.c_ulong)), ctypes.POINTER(ctypes.c_uint)]
libx11.XQueryTree.restype = ctypes.c_int
libx11.XFetchName.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_char_p)]
libx11.XFetchName.restype = ctypes.c_int
libx11.XGetWindowAttributes.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_void_p]
libx11.XGetWindowAttributes.restype = ctypes.c_int
libx11.XFree.argtypes = [ctypes.c_void_p]
libx11.XFree.restype = ctypes.c_int

class XWindowAttributes(ctypes.Structure):
  _fields_ = [
    ('x', ctypes.c_int),
    ('y', ctypes.c_int),
    ('width', ctypes.c_int),
    ('height', ctypes.c_int),
    ('border_width', ctypes.c_int),
    ('depth', ctypes.c_int),
    ('visual', ctypes.c_void_p),
    ('root', ctypes.c_ulong),
    ('class', ctypes.c_int),
    ('bit_gravity', ctypes.c_int),
    ('win_gravity', ctypes.c_int),
    ('backing_store', ctypes.c_int),
    ('backing_planes', ctypes.c_ulong),
    ('backing_pixel', ctypes.c_ulong),
    ('save_under', ctypes.c_int),
    ('colormap', ctypes.c_ulong),
    ('map_installed', ctypes.c_int),
    ('map_state', ctypes.c_int),
    ('all_event_masks', ctypes.c_long),
    ('your_event_mask', ctypes.c_long),
    ('do_not_propagate_mask', ctypes.c_long),
    ('override_redirect', ctypes.c_int),
    ('screen', ctypes.c_void_p),
  ]

display = libx11.XOpenDisplay(os.environ.get('DISPLAY', ':120').encode())
if not display:
    sys.exit(1)

root = libx11.XDefaultRootWindow(display)
root_return = ctypes.c_ulong()
parent_return = ctypes.c_ulong()
children_return = ctypes.POINTER(ctypes.c_ulong)()
nchildren = ctypes.c_uint()
if not libx11.XQueryTree(display, root, ctypes.byref(root_return), ctypes.byref(parent_return), ctypes.byref(children_return), ctypes.byref(nchildren)):
    sys.exit(1)

matches = []
for idx in range(nchildren.value):
  window = children_return[idx]
  name = ''
  name_ptr = ctypes.c_char_p()
  if libx11.XFetchName(display, window, ctypes.byref(name_ptr)) and name_ptr.value:
    name = name_ptr.value.decode(errors='replace')
  attrs = XWindowAttributes()
  if libx11.XGetWindowAttributes(display, window, ctypes.byref(attrs)):
    area = max(attrs.width, 0) * max(attrs.height, 0)
  else:
    area = 0
  matches.append((area, window, name, getattr(attrs, 'width', 0), getattr(attrs, 'height', 0)))

if children_return:
  libx11.XFree(children_return)

for area, window, name, width, height in sorted(matches, reverse=True):
  print(f"{window} {width}x{height} area={area} name={name}")
PY
}

until grep -q "Events run" "$outdir/run.log"; do
  if ! kill -0 "$app_pid" >/dev/null 2>&1; then
    break
  fi
done

viewer_info=""
for _ in $(seq 1 200); do
  viewer_info=$(find_viewer_window | head -1 || true)
  if [[ -n "$viewer_info" ]]; then
    break
  fi
done
printf '%s\n' "$viewer_info" > "$outdir/viewer_windows.txt"
window_id=${viewer_info%% *}

if [[ -z "${window_id:-}" ]]; then
  echo "ERROR: Could not locate viewer window" >&2
  exit 1
fi

timeout 20s import -window "$window_id" "$outdir/$image_name"

if [[ "$keep_open" == "1" ]]; then
  echo "Viewer left open on $display_num with pid $app_pid"
  exit 0
fi

wait "$app_pid" || true