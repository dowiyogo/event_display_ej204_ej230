#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {x0_n5|x0_n20|x0_n100|xm400_n20|xm690_n20}" >&2
  exit 1
fi

case_name="$1"
root_dir="/home/reriosto/SHiP/event_display_ej204_ej230/outputs/selective_tracks_ej204"
build_dir="/home/reriosto/SHiP/builds/ej200_event_display_20260617_152315"
sim="$build_dir/ej200_bar_sim"
macro_src="$root_dir/macros/display_${case_name}.mac"
case_dir="$root_dir/$case_name"
vis_mac="$build_dir/macros/vis.mac"
backup_vis="$build_dir/macros/vis.mac.selective_backup"

[[ -d "$case_dir" ]] || { echo "Unknown case: $case_name" >&2; exit 1; }
[[ -x "$sim" ]] || { echo "Missing executable: $sim" >&2; exit 1; }
[[ -f "$macro_src" ]] || { echo "Missing macro: $macro_src" >&2; exit 1; }
[[ -e "$vis_mac" ]] || { echo "Missing target vis macro: $vis_mac" >&2; exit 1; }

case "$case_name" in
  xm690_n20) x_pos="-690" ;;
  xm400_n20) x_pos="-400" ;;
  x0_n5|x0_n20|x0_n100) x_pos="0" ;;
  *) echo "Unknown case: $case_name" >&2; exit 1 ;;
esac

stored_n="${case_name##*_n}"

echo "Case: $case_name"
echo "x position: $x_pos mm"
echo "stored optical trajectories: $stored_n"
echo "physical photons are NOT reduced: yes"
echo "muon color: red"
echo "optical tracks: cyan"
echo
printf '%s\n' '/vis/viewer/zoom 2' '/vis/viewer/refresh' '/vis/viewer/flush'
printf '%s\n' '/vis/viewer/zoom 0.5' '/vis/viewer/set/targetPoint 0 0 0 mm' '/vis/viewer/refresh'

cp "$vis_mac" "$backup_vis"
trap 'cp "$backup_vis" "$vis_mac"' EXIT
cp "$macro_src" "$vis_mac"

(cd "$build_dir" && "$sim")

if [[ -f "$build_dir/photon_hits_run000.root" ]]; then
  cp "$build_dir/photon_hits_run000.root" "$case_dir/photon_hits_run000.root"
fi
if [[ -f "$build_dir/scatter_points_event000.csv" ]]; then
  cp "$build_dir/scatter_points_event000.csv" "$case_dir/scatter_points_event000.csv"
fi
if [[ -f "$build_dir/run.log" ]]; then
  cp "$build_dir/run.log" "$case_dir/run.log"
fi
cp "$macro_src" "$case_dir/macro_used.mac"
