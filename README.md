# Event displays EJ-204 and EJ-230

This workspace generates professional Geant4 event displays for exactly one muon event per configuration, comparing the EndTop geometry for EJ-204 and EJ-230 at three longitudinal positions:

- x = -690 mm
- x = -400 mm
- x = 0 mm

Each case uses one Geant4 event and one primary muon. The display is meant to show the full simulated event: bar geometry, end SiPMs, top SiPMs, the muon track, optical photons, and relevant secondaries.

## Repositories used

- EJ-204: `/home/reriosto/SHiP/ej200`, branch `feat/endtop-sslg4`
- EJ-230: `/home/reriosto/SHiP/ej230`, branch `feat/ej230-sslg4`

The event-display files in this directory do not modify those repositories.

## Coordinate convention

The bar longitudinal axis is X. The muon travels vertically from +Z toward -Z.

The production convention confirmed in the existing macros is:

- `/gun/position 0 0 60 mm`
- `/gun/direction 0 0 -1`
- `/muon/angle 0`
- `/muon/gunX <X> mm`

This matches `PrimaryGeneratorAction.cc`: the gun position is initialized at `(0, 0, 60 mm)` and the angle command tilts the muon in the XZ plane around the vertical -Z direction.

## Confirmed code surface

The relevant executables are built from the two repositories as:

- EJ-204: `ej200_bar_sim`
- EJ-230: `ej200_bar_sim`

The code is compiled with Geant4 UI and visualization support through `find_package(Geant4 REQUIRED ui_all vis_all)`.

`G4OpticalPhysics` is registered in `main.cc`, and `G4OpticalParameters::Instance()->SetBoundaryInvokeSD(true)` is enabled.

Confirmed UI commands from the code:

- `/muon/gunX`
- `/muon/angle`
- `/sipm/jitterSigma`
- `/det/scintillator`
- `/det/readout`
- `/sipm/model`

The EJ-204 branch accepts `OPSC-101`, and the EJ-230 branch accepts `OPSC-106`. Both use the `EndTop` readout with the EndTop geometry.

Each event contains one primary muon because the gun is instantiated with a single particle and the macros use `/run/beamOn 1`.

## Outputs

The generated files live under:

`/home/reriosto/SHiP/event_display_ej204_ej230/`

The main deliverables are:

- `summary/event_display_6panel.png`
- `summary/event_display_summary.csv`
- `summary/validation_report.md`
- `summary/repository_status_before.txt`
- `summary/repository_status_after.txt`

Per case, the workflow stores:

- `geometry.png`
- `event_full.png`
- `event_zoom.png`
- `run.log`
- `photon_hits_run000.root`

## Regeneration

Run every case:

```bash
./run_all_event_displays.sh
```

Run one case only:

```bash
./run_all_event_displays.sh ej204 xm690
```

The accepted case names are:

- `ej204 xm690`
- `ej204 xm400`
- `ej204 x0`
- `ej230 xm690`
- `ej230 xm400`
- `ej230 x0`

## ROOT validation

The validation script checks that each ROOT file contains the `sipm_hits` TTree, that `event_id` only contains 0, and that `gun_x_mm` matches the requested position.

The ROOT files are validated with `uproot` because the local Python environment does not provide the PyROOT module.

## Geometry and display notes

The display uses a white background, stored trajectories, and a draw-by-particle-ID model with these colors:

- red: primary muon
- cyan: optical photons
- yellow/orange: electrons
- green: gammas

The geometry export files are kept separate for EJ-204 and EJ-230 even though the EndTop geometry is structurally the same; the split makes the material/executable provenance explicit.

## Limitations

If the local Geant4 viewer export command differs from the commands expected by the installed visualization driver, the scripts fall back to screen capture through `import` under `xvfb-run` when needed.
