#!/usr/bin/env bash
set -euo pipefail

# Simplified event display runner: batch simulation + static rendering
# Usage: batch_run_case.sh <exe> <macro> <outdir>

exe=$1
macro=$2
outdir=$3

mkdir -p "$outdir"
rm -f "$outdir/run.log" "$outdir/event_full.png"

# Run batch simulation
echo "[$(date)] Running batch simulation for $(basename "$macro")"
exe_dir=$(dirname "$exe")
cd "$exe_dir"
"$exe" -m "$macro" > "$outdir/run.log" 2>&1

# Locate the produced ROOT file
root_file=$(cd "$(dirname "$exe")" && ls -1t photon_hits_run*.root 2>/dev/null | head -1)
if [[ -z "$root_file" ]]; then
  echo "ERROR: No ROOT output found in $(dirname "$exe")"
  exit 1
fi

# Copy ROOT file to output directory
root_path="$(dirname "$exe")/$root_file"
cp "$root_path" "$outdir/$root_file"
echo "[$(date)] Rendering event display"
python3 /home/reriosto/SHiP/event_display_ej204_ej230/render_event_display.py \
  "$outdir/$root_file" "$outdir/event_full.png" 0

echo "[$(date)] Complete: $outdir/event_full.png"
