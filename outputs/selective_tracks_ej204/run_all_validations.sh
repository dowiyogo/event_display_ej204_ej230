#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/home/reriosto/SHiP/event_display_ej204_ej230/outputs/selective_tracks_ej204"
BUILD_DIR="/home/reriosto/SHiP/builds/ej200_event_display_20260617_152315"
SIM="$BUILD_DIR/ej200_bar_sim"
TMP_DIR="$ROOT_DIR/.tmp_run"
mkdir -p "$TMP_DIR"

run_case() {
  local case_name="$1"
  local macro_name="$2"
  local case_dir="$ROOT_DIR/$case_name"
  local macro_src="$ROOT_DIR/macros/$macro_name"
  local macro_work="$BUILD_DIR/macros/vis.mac"
  local backup_vis="$TMP_DIR/vis.mac.backup"
  local run_dir="$TMP_DIR/$case_name"

  rm -f "$BUILD_DIR/photon_hits_run000.root" "$BUILD_DIR/scatter_points_event000.csv"
  rm -rf "$run_dir"
  mkdir -p "$run_dir"
  cp "$macro_src" "$run_dir/vis.mac"

  if [[ -e "$macro_work" ]]; then
    cp "$macro_work" "$backup_vis"
  else
    : > "$backup_vis"
  fi

  cp "$macro_src" "$macro_work"
  trap 'if [[ -e "$backup_vis" ]]; then cp "$backup_vis" "$macro_work"; fi' RETURN

  (cd "$BUILD_DIR" && "$SIM" -m "$run_dir/vis.mac" > "$run_dir/run.log" 2>&1)

  if [[ -f "$BUILD_DIR/photon_hits_run000.root" ]]; then
    cp "$BUILD_DIR/photon_hits_run000.root" "$case_dir/photon_hits_run000.root"
  fi
  if [[ -f "$BUILD_DIR/scatter_points_event000.csv" ]]; then
    cp "$BUILD_DIR/scatter_points_event000.csv" "$case_dir/scatter_points_event000.csv"
  fi
  cp "$run_dir/run.log" "$case_dir/run.log"
  cp "$macro_src" "$case_dir/macro_used.mac"

  if [[ -e "$backup_vis" && -s "$backup_vis" ]]; then
    cp "$backup_vis" "$macro_work"
  fi
  trap - RETURN
}

run_case xm690_n20 validate_xm690_n20.mac
run_case xm400_n20 validate_xm400_n20.mac
run_case x0_n5 validate_x0_n5.mac
run_case x0_n20 validate_x0_n20.mac
run_case x0_n100 validate_x0_n100.mac
