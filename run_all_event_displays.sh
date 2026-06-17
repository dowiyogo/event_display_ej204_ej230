#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=/home/reriosto/SHiP/event_display_ej204_ej230
EJ200_REPO=/home/reriosto/SHiP/ej200
EJ230_REPO=/home/reriosto/SHiP/ej230
EJ204_BUILD="$ROOT_DIR/build/ej204"
EJ230_BUILD="$ROOT_DIR/build/ej230"
MACRO_DIR="$ROOT_DIR/macros"
SUMMARY_DIR="$ROOT_DIR/summary"
OUTPUT_DIR="$ROOT_DIR/outputs"
GEOM_DIR="$OUTPUT_DIR/geometry"
RENDERER="$ROOT_DIR/render_event_display.py"
CASE_RUNNER="$ROOT_DIR/batch_run_case.sh"

mkdir -p "$EJ204_BUILD" "$EJ230_BUILD" "$SUMMARY_DIR" "$OUTPUT_DIR" "$GEOM_DIR"

write_status() {
  {
    echo "# Repository status snapshot"
    echo
    git -C "$EJ200_REPO" status --short --branch
    echo
    git -C "$EJ230_REPO" status --short --branch
    echo
    git -C "$ROOT_DIR/../ej200_edge_scan" status --short --branch
    echo
    git -C "$ROOT_DIR/../ej200_endonly" status --short --branch
    echo
    git -C "$ROOT_DIR/../ej230_endonly_mylar" status --short --branch
    echo
    git -C "$ROOT_DIR/../orchestrator" status --short --branch
  } > "$1"
}

write_status "$SUMMARY_DIR/repository_status_before.txt"

cmake -S "$EJ200_REPO" -B "$EJ204_BUILD"
cmake -S "$EJ230_REPO" -B "$EJ230_BUILD"
cmake --build "$EJ204_BUILD" --parallel
cmake --build "$EJ230_BUILD" --parallel

run_geometry() {
  local exe=$1
  local macro=$2
  local outdir=$3
  mkdir -p "$outdir"
  "$ROOT_DIR/run_case.sh" "$exe" "$macro" "$outdir"
}

if [[ "${RUN_GEOMETRY:-0}" == "1" ]]; then
  run_geometry "$EJ204_BUILD/ej200_bar_sim" "$MACRO_DIR/geometry_ej204_endtop.mac" "$GEOM_DIR/ej204"
  run_geometry "$EJ230_BUILD/ej200_bar_sim" "$MACRO_DIR/geometry_ej230_endtop.mac" "$GEOM_DIR/ej230"
fi

if [[ $# -eq 2 ]]; then
  cases=("$1:$2")
else
  cases=(
    "ej204:xm690"
    "ej204:xm400"
    "ej204:x0"
    "ej230:xm690"
    "ej230:xm400"
    "ej230:x0"
  )
fi

python3 "$ROOT_DIR/check_outputs.py" --preflight

for case in "${cases[@]}"; do
  material=${case%%:*}
  name=${case##*:}
  case_dir="$OUTPUT_DIR/$material/$name"
  mkdir -p "$case_dir"
  rm -f "$case_dir/photon_hits_run000.root"
  if [[ "$material" == "ej204" ]]; then
    exe="$EJ204_BUILD/ej200_bar_sim"
    macro="$MACRO_DIR/batch_ej204_${name}.mac"
  else
    exe="$EJ230_BUILD/ej200_bar_sim"
    macro="$MACRO_DIR/batch_ej230_${name}.mac"
  fi
  [[ -x "$exe" ]]
  [[ -f "$macro" ]]
  "$CASE_RUNNER" "$exe" "$macro" "$case_dir"
done

python3 "$ROOT_DIR/check_outputs.py" --summarize
python3 "$ROOT_DIR/make_contact_sheet.py"
write_status "$SUMMARY_DIR/repository_status_after.txt"
