#!/usr/bin/env bash
set -euo pipefail

# Master event display runner: all six cases + assembly

ROOT_DIR="/home/reriosto/SHiP"
OUTPUT_DIR="$ROOT_DIR/event_display_ej204_ej230/outputs"
BATCH_RUNNER="$ROOT_DIR/event_display_ej204_ej230/batch_run_case.sh"
RENDERER="$ROOT_DIR/event_display_ej204_ej230/render_event_display.py"

EJ204_EXE="$ROOT_DIR/event_display_ej204_ej230/build/ej204/ej200_bar_sim"
EJ230_EXE="$ROOT_DIR/event_display_ej204_ej230/build/ej230/ej200_bar_sim"

mkdir -p "$OUTPUT_DIR/ej204" "$OUTPUT_DIR/ej230"

# Capture repo status before
echo "=== Repo Status Before ===" > "$OUTPUT_DIR/repo_status_before.txt"
git -C "$ROOT_DIR/ej200" status >> "$OUTPUT_DIR/repo_status_before.txt" 2>&1 || true
git -C "$ROOT_DIR/ej230" status >> "$OUTPUT_DIR/repo_status_before.txt" 2>&1 || true

# Run all six cases
declare -a cases=(
  "ej204:xm690:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej204_xm690.mac"
  "ej204:xm400:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej204_xm400.mac"
  "ej204:x0:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej204_x0.mac"
  "ej230:xm690:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej230_xm690.mac"
  "ej230:xm400:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej230_xm400.mac"
  "ej230:x0:/home/reriosto/SHiP/event_display_ej204_ej230/macros/batch_ej230_x0.mac"
)

for case_spec in "${cases[@]}"; do
  IFS=':' read -r detector variant macro <<< "$case_spec"
  
  exe=$([[ "$detector" == "ej204" ]] && echo "$EJ204_EXE" || echo "$EJ230_EXE")
  outdir="$OUTPUT_DIR/$detector/$variant"
  
  mkdir -p "$outdir"
  echo "[$(date)] Running $detector $variant"
  
  "$BATCH_RUNNER" "$exe" "$macro" "$outdir" || {
    echo "ERROR in $detector $variant"
    exit 1
  }
done

# Capture repo status after
echo "=== Repo Status After ===" > "$OUTPUT_DIR/repo_status_after.txt"
git -C "$ROOT_DIR/ej200" status >> "$OUTPUT_DIR/repo_status_after.txt" 2>&1 || true
git -C "$ROOT_DIR/ej230" status >> "$OUTPUT_DIR/repo_status_after.txt" 2>&1 || true

# Generate summary and contact sheet
echo "[$(date)] Generating summary and contact sheet"
python3 - <<'PYSCRIPT'
import os, glob, csv, subprocess
from PIL import Image

OUTPUT_DIR = "/home/reriosto/SHiP/event_display_ej204_ej230/outputs"

# Create summary CSV
summary_rows = []
for detector in ["ej204", "ej230"]:
  for variant in ["xm690", "xm400", "x0"]:
    outdir = f"{OUTPUT_DIR}/{detector}/{variant}"
    png_path = f"{outdir}/event_full.png"
    log_path = f"{outdir}/run.log"
    
    exists = os.path.exists(png_path)
    status = "OK" if exists else "MISSING"
    
    summary_rows.append({
      "detector": detector,
      "variant": variant,
      "output_dir": outdir,
      "png_exists": status,
      "png_size_kb": os.path.getsize(png_path) / 1024 if exists else 0,
    })

# Write CSV
with open(f"{OUTPUT_DIR}/event_display_summary.csv", "w") as f:
  writer = csv.DictWriter(f, fieldnames=["detector", "variant", "output_dir", "png_exists", "png_size_kb"])
  writer.writeheader()
  writer.writerows(summary_rows)

print(f"Summary: {len(summary_rows)} cases")
for row in summary_rows:
  print(f"  {row['detector']}/{row['variant']}: {row['png_exists']}")

# Create 6-panel contact sheet
images = []
for row in summary_rows:
  png_path = f"{row['output_dir']}/event_full.png"
  if os.path.exists(png_path):
    images.append(Image.open(png_path))

if len(images) == 6:
  # Arrange 2 rows x 3 columns
  img_width, img_height = images[0].size
  canvas = Image.new('RGB', (img_width * 3, img_height * 2), 'white')
  
  for i, img in enumerate(images):
    row = i // 3
    col = i % 3
    canvas.paste(img, (col * img_width, row * img_height))
  
  canvas.save(f"{OUTPUT_DIR}/event_display_6panel.png")
  print(f"Contact sheet: {OUTPUT_DIR}/event_display_6panel.png")

PYSCRIPT

echo "[$(date)] All complete"
ls -lh "$OUTPUT_DIR"/*.png "$OUTPUT_DIR"/*.csv 2>/dev/null || true
