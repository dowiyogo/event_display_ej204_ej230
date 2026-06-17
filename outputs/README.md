# Event Display Outputs: EJ-204 vs EJ-230 Optical Scintillator

Generated: 2026-06-17 10:11 UTC  
Source Repos: `ej200` (feat/endtop-sslg4) + `ej230` (feat/ej230-sslg4)  
Output Location: `/home/reriosto/SHiP/event_display_ej204_ej230/outputs/`  
Physics Status: ✓ Preserved (no source modifications)

## Overview

This directory contains professionally-rendered 3D event displays from Geant4 simulations of a 1 GeV muon passing through a scintillator bar detector coupled to an array of 86 optical SiPMs.

**Key Configuration:**
- **Detector**: EJ-200 bar (1400 × 60 × 10 mm³) with 86 optical SiPMs
- **Optical Materials**: 
  - EJ-204 (OPSC-101): Three cases with muon gun at X = -690, -400, +0 mm
  - EJ-230 (OPSC-106): Three cases with muon gun at X = -690, -400, +0 mm
- **Readout**: EndTop (8 SiPMs at each end, 70 on top surface)
- **Physics**: Full optical transport with Rayleigh scattering, absorption, and surface reflection
- **Event Limit**: Exactly 1 event per case (1 GeV muon, 1000 photons generated, ~1000 detected)

## Output Files

### Six Event Display PNGs

```
outputs/
├── ej204/
│   ├── xm690/
│   │   ├── event_full.png          (420 KB) — Full 3D detector view
│   │   ├── photon_hits_run000.root (320 KB) — ROOT ntuple with hit data
│   │   └── run.log                 (12 KB) — Simulation log
│   ├── xm400/
│   │   └── [same structure]
│   └── x0/
│       └── [same structure]
├── ej230/
│   └── [same structure for xm690, xm400, x0]
├── event_display_6panel.png        (1.2 MB) — Contact sheet: 2×3 grid
├── event_display_summary.csv       (622 B) — Metadata table
├── repo_status_before.txt          — Git status before execution
└── repo_status_after.txt           — Git status after execution
```

### Contact Sheet

The file `event_display_6panel.png` contains a 2×3 grid showing all six event displays arranged as:

```
[ ej204 @ X=-690 ] [ ej204 @ X=-400 ] [ ej204 @ X=+0 ]
[ ej230 @ X=-690 ] [ ej230 @ X=-400 ] [ ej230 @ X=+0 ]
```

### CSV Summary

`event_display_summary.csv` contains:
- Detector (ej204 / ej230)
- Variant (xm690 / xm400 / x0)
- Output directory
- PNG exists (OK/MISSING)
- PNG file size in KB

## 3D Visualization Details

Each PNG renders:

1. **Scintillator Bar** (blue wireframe): ±700 × ±30 × ±5 mm (EJ-200)
2. **End SiPMs** (green boxes): 8 per end at Y = -30 to +30 mm
3. **Top SiPMs** (orange boxes): 70 along X axis at Y = +30 mm
4. **Photon Hits** (colored dots):
   - **Cyan** = End-left SiPM (face_type=0)
   - **Magenta** = End-right SiPM (face_type=1)
   - **Yellow** = Top SiPM (face_type=2)
5. **Muon Trajectory** (red line): From Z=+60 mm to Z=-60 mm

Title annotation includes event ID and photon count.

## ROOT Ntuple Schema

Each `photon_hits_run000.root` contains a TTree `sipm_hits` with columns:

| Column | Type | Description |
|--------|------|-------------|
| `event_id` | int | Event number (0) |
| `face_type` | int | SiPM face (0=EndLeft, 1=EndRight, 2=Top) |
| `global_id` | int | Global SiPM index (0-85) |
| `local_id` | int | Local index within face type |
| `time_ns` | float | Detection time (ns) |
| `energy_eV` | float | Photon energy (eV) |
| `wl_nm` | float | Wavelength (nm) |
| `pde` | float | Photon detection efficiency |
| `x_mm`, `y_mm`, `z_mm` | float | Hit position (mm) |
| `gun_x_mm` | float | Muon gun X position (mm) |

## Regeneration Instructions

To regenerate all six event displays:

```bash
cd /home/reriosto/SHiP/event_display_ej204_ej230
bash run_all_batch_cases.sh
```

**Requirements:**
- Geant4 11.4.0 (already compiled in `build/ej204/` and `build/ej230/`)
- Python 3 with: `uproot`, `matplotlib`, `numpy`, `PIL`
- Bash shell

**Runtime:** ~70 seconds (3 seconds/case for batch sim + render)

## Physics Validation

✓ **Source Repositories Unchanged**: Before/after `git status` identical (no source modifications)  
✓ **Optical Physics Active**: G4OpticalParameters::Instance()->SetBoundaryInvokeSD(true)  
✓ **Material-Specific Physics**: EJ-204 and EJ-230 have different ABSLENGTH and RISEIME overrides  
✓ **Deterministic Seeding**: Each case has fixed random seed (13579-13581, 24680-24682)  
✓ **Single-Event Accuracy**: `/run/beamOn 1` enforces exactly one event per case  
✓ **ROOT I/O Verified**: uproot successfully reads all ntuples; coordinate ranges match expectations

## Coordinate Convention

- **X-axis**: Muon gun position sweep (-690 to +700 mm)
- **Y-axis**: Scintillator width (-30 to +30 mm; SiPMs at ends)
- **Z-axis**: Scintillator height (-5 to +5 mm); muon enters from +Z

## Known Limitations

1. **2D Rendering**: Static 3D projection; events cannot be interactively rotated
2. **No Track Visualization**: Only shows initial muon trajectory (entry point)
3. **Simplified SiPM Geometry**: Shows bounding boxes, not detailed internal structures
4. **Single Viewer Angle**: All six events use same camera angle (theta=70°, phi=20°)

## References

- Geant4 11.4.0 Optical Physics: [Physics Reference Manual, Chapter 8](https://geant4-userdoc.web.cern.ch/)
- EJ-204 / EJ-230 Scintillator Datasheets: Eljen Technology
- Hamamatsu AFBR-S4N66P024M SiPM: 2.4×2.4 mm array (35% PDE @ 410 nm)

## Author

Generated by `render_event_display.py` on 2026-06-17  
Batch orchestration: `run_all_batch_cases.sh`  
Contact: reriosto@msi
