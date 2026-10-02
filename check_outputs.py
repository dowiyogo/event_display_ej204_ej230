#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path
import re
import sys

import uproot


ROOT_DIR = Path("/home/reriosto/SHiP/event_display_ej204_ej230")
OUTPUT_DIR = ROOT_DIR / "outputs"
SUMMARY_DIR = ROOT_DIR / "summary"

CASES = [
    ("ej204", "xm690", -690, 16, "OPSC-101", "feat/endtop-sslg4", "/home/reriosto/SHiP/ej200"),
    ("ej204", "xm400", -400, 31, "OPSC-101", "feat/endtop-sslg4", "/home/reriosto/SHiP/ej200"),
    ("ej204", "x0", 0, 51, "OPSC-101", "feat/endtop-sslg4", "/home/reriosto/SHiP/ej200"),
    ("ej230", "xm690", -690, 16, "OPSC-106", "feat/ej230-sslg4", "/home/reriosto/SHiP/ej230"),
    ("ej230", "xm400", -400, 31, "OPSC-106", "feat/ej230-sslg4", "/home/reriosto/SHiP/ej230"),
    ("ej230", "x0", 0, 51, "OPSC-106", "feat/ej230-sslg4", "/home/reriosto/SHiP/ej230"),
]


@dataclass
class CaseResult:
    material: str
    repository: str
    branch: str
    scintillator_code: str
    readout: str
    x_mm: int
    nearest_top_global_id: int
    seed1: int
    seed2: int
    events_run: int
    scint_photons_generated: int
    photons_detected_total: int
    photons_end_left: int
    photons_end_right: int
    photons_top: int
    root_entries: int
    unique_event_ids: int
    gun_x_min_mm: float
    gun_x_max_mm: float
    geometry_image: str
    event_full_image: str
    event_zoom_image: str
    run_log: str
    validation_status: str


def preflight() -> int:
    missing = []
    for material, name, *_ in CASES:
        macro = ROOT_DIR / "macros" / f"{material}_{name}.mac"
        if not macro.exists():
            missing.append(str(macro))
        elif "/run/beamOn 1" not in macro.read_text():
            missing.append(f"missing beamOn 1 in {macro}")
    if missing:
        print("Missing preflight requirements:", *missing, sep="\n - ", file=sys.stderr)
        return 2
    return 0


def parse_log(path: Path) -> dict[str, int]:
    text = path.read_text(errors="replace")
    patterns = {
        "events_run": r"Events run\s*[:=]\s*(\d+)",
        "scint_photons_generated": r"Scint photons generated\s*[:=]\s*(\d+)",
        "photons_detected_total": r"Total photons detected\s*[:=]\s*(\d+)",
        "photons_end_left": r"End-left\s+photons\s+:\s+(\d+)",
        "photons_end_right": r"End-right\s+photons\s+:\s+(\d+)",
        "photons_top": r"Top SiPM\s+photons\s+:\s+(\d+)",
    }
    data: dict[str, int] = {}
    for key, pattern in patterns.items():
        m = re.search(pattern, text)
        data[key] = int(m.group(1)) if m else 0
    return data


def validate_root(root_path: Path, gun_x: int) -> tuple[int, int, float, float, str]:
    with uproot.open(root_path) as f:
        if "sipm_hits" not in f:
            return 0, 0, 0.0, 0.0, "missing-tree"
        tree = f["sipm_hits"]
        arrays = tree.arrays(["event_id", "gun_x_mm", "x_mm", "y_mm", "z_mm"], library="np")
        event_ids = arrays["event_id"]
        gun_x_vals = arrays["gun_x_mm"]
        unique_event_ids = len(set(int(v) for v in event_ids.tolist()))
        entries = int(tree.num_entries)
        gun_min = float(gun_x_vals.min()) if len(gun_x_vals) else 0.0
        gun_max = float(gun_x_vals.max()) if len(gun_x_vals) else 0.0
        ok = unique_event_ids == 1 and (len(event_ids) == 0 or all(int(v) == 0 for v in event_ids.tolist()))
        if abs(gun_min - gun_x) > 1e-9 or abs(gun_max - gun_x) > 1e-9:
            ok = False
        status = "ok" if ok else "needs-review"
        return entries, unique_event_ids, gun_min, gun_max, status


def case_paths(material: str, name: str) -> dict[str, Path]:
    case_dir = OUTPUT_DIR / material / name
    geometry = OUTPUT_DIR / "geometry" / material / f"geometry_{material}_endtop.png"
    return {
        "case_dir": case_dir,
        "log": case_dir / "run.log",
        "root": case_dir / "photon_hits_run000.root",
        "geometry": geometry,
        "full": case_dir / "event_full.png",
        "zoom": case_dir / "event_zoom.png",
    }


def summarize() -> int:
    rows: list[CaseResult] = []
    for material, name, x_mm, top_id, scint, branch, repo in CASES:
        paths = case_paths(material, name)
        if not paths["log"].exists() or not paths["root"].exists():
            print(f"Missing outputs for {material}/{name}", file=sys.stderr)
            return 3
        log_data = parse_log(paths["log"])
        if log_data["events_run"] != 1 or log_data["scint_photons_generated"] <= 0 or log_data["photons_detected_total"] <= 0:
            print(f"Run-log validation failed for {material}/{name}", file=sys.stderr)
            return 4
        entries, unique_event_ids, gun_min, gun_max, status = validate_root(paths["root"], x_mm)
        if status != "ok":
            print(f"ROOT validation failed for {material}/{name}", file=sys.stderr)
            return 5
        rows.append(
            CaseResult(
                material=material,
                repository=repo,
                branch=branch,
                scintillator_code=scint,
                readout="EndTop",
                x_mm=x_mm,
                nearest_top_global_id=top_id,
                seed1={-690: 13579, -400: 13580, 0: 13581}[x_mm],
                seed2={-690: 24680, -400: 24681, 0: 24682}[x_mm],
                events_run=int(log_data["events_run"]),
                scint_photons_generated=int(log_data["scint_photons_generated"]),
                photons_detected_total=int(log_data["photons_detected_total"]),
                photons_end_left=int(log_data["photons_end_left"]),
                photons_end_right=int(log_data["photons_end_right"]),
                photons_top=int(log_data["photons_top"]),
                root_entries=entries,
                unique_event_ids=unique_event_ids,
                gun_x_min_mm=gun_min,
                gun_x_max_mm=gun_max,
                geometry_image=str(paths["geometry"].relative_to(ROOT_DIR)),
                event_full_image=str(paths["full"].relative_to(ROOT_DIR)),
                event_zoom_image=str(paths["zoom"].relative_to(ROOT_DIR)),
                run_log=str(paths["log"].relative_to(ROOT_DIR)),
                validation_status=status,
            )
        )

    SUMMARY_DIR.mkdir(parents=True, exist_ok=True)
    csv_path = SUMMARY_DIR / "event_display_summary.csv"
    with csv_path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(CaseResult.__annotations__.keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow(row.__dict__)

    report = [
        "# Validation report",
        "",
        "## Summary",
        f"Generated cases: {len(rows)}",
        "",
        "## Case checks",
    ]
    for row in rows:
        report.append(
            f"- {row.material} x={row.x_mm}: events={row.events_run}, gun_x=[{row.gun_x_min_mm}, {row.gun_x_max_mm}], entries={row.root_entries}, status={row.validation_status}"
        )
    report.append("")
    report.append("## Git status before/after")
    before = (SUMMARY_DIR / "repository_status_before.txt").read_text(errors="replace") if (SUMMARY_DIR / "repository_status_before.txt").exists() else ""
    after = (SUMMARY_DIR / "repository_status_after.txt").read_text(errors="replace") if (SUMMARY_DIR / "repository_status_after.txt").exists() else ""
    report.append("### Before")
    report.append(before.strip() or "(missing)")
    report.append("### After")
    report.append(after.strip() or "(missing)")
    (SUMMARY_DIR / "validation_report.md").write_text("\n".join(report) + "\n")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preflight", action="store_true")
    parser.add_argument("--summarize", action="store_true")
    args = parser.parse_args()
    if args.preflight:
        return preflight()
    if args.summarize:
        return summarize()
    parser.error("expected --preflight or --summarize")


if __name__ == "__main__":
    raise SystemExit(main())
