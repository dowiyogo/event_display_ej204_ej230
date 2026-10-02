#!/usr/bin/env python3
"""Render event displays from ROOT ntuple data.

Usage:
    render_event_display.py <root_file> <output_dir> [event_id]

Produces two PNGs in the output directory:
- event_full.png
- event_zoom.png
"""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import uproot


BAR_HALF_X = 700.0
BAR_HALF_Y = 30.0
BAR_HALF_Z = 5.0

END_HALF_X = 0.25
END_HALF_Y = 3.0
END_HALF_Z = 3.0

TOP_HALF_X = 3.0
TOP_HALF_Y = 0.25
TOP_HALF_Z = 3.0

MATERIALS = {
    "ej204": {
        "scintillator_code": "OPSC-101",
        "scintillator_name": "EJ-204",
        "color": "#005b96",
    },
    "ej230": {
        "scintillator_code": "OPSC-106",
        "scintillator_name": "EJ-230",
        "color": "#0f7b6c",
    },
}


def plot_box(ax, cx, cy, cz, hx, hy, hz, **kwargs):
    edges = [
        [[-hx, hx], [-hy, -hy], [-hz, -hz]],
        [[-hx, hx], [hy, hy], [-hz, -hz]],
        [[-hx, hx], [-hy, -hy], [hz, hz]],
        [[-hx, hx], [hy, hy], [hz, hz]],
        [[-hx, -hx], [-hy, hy], [-hz, -hz]],
        [[hx, hx], [-hy, hy], [-hz, -hz]],
        [[-hx, -hx], [-hy, hy], [hz, hz]],
        [[hx, hx], [-hy, hy], [hz, hz]],
        [[-hx, -hx], [-hy, -hy], [-hz, hz]],
        [[hx, hx], [-hy, -hy], [-hz, hz]],
        [[-hx, -hx], [hy, hy], [-hz, hz]],
        [[hx, hx], [hy, hy], [-hz, hz]],
    ]

    for ex, ey, ez in edges:
        ax.plot([cx + ex[0], cx + ex[1]], [cy + ey[0], cy + ey[1]], [cz + ez[0], cz + ez[1]], **kwargs)


def infer_material(root_file: Path, output_dir: Path) -> tuple[str, dict[str, str]]:
    segments = {part.lower() for part in output_dir.parts}
    if "ej230" in segments:
        return "ej230", MATERIALS["ej230"]
    return "ej204", MATERIALS["ej204"]


def detector_limits(zoom: float) -> tuple[tuple[float, float], tuple[float, float], tuple[float, float]]:
    x_half = BAR_HALF_X * zoom
    y_half = 45.0 * zoom
    z_half = 35.0 * zoom
    return (-x_half, x_half), (-y_half, y_half), (-z_half, z_half)


def render_axes(ax, material_cfg: dict[str, str], event_data: dict[str, np.ndarray], event_id: int, zoom: float) -> None:
    plot_box(ax, 0, 0, 0, BAR_HALF_X, BAR_HALF_Y, BAR_HALF_Z, color=material_cfg["color"], linewidth=1.5, alpha=0.25)

    for i in range(8):
        y_c = -30.0 + 1.5 + i * 7.5
        plot_box(ax, -(BAR_HALF_X - END_HALF_X), y_c, 0, END_HALF_X, END_HALF_Y, END_HALF_Z, color="#2ca02c", linewidth=0.8, alpha=0.5)
        plot_box(ax, +(BAR_HALF_X - END_HALF_X), y_c, 0, END_HALF_X, END_HALF_Y, END_HALF_Z, color="#2ca02c", linewidth=0.8, alpha=0.5)

    for i in range(70):
        x_c = -692.0 + 20.0 * i if i < 35 else 12.0 + 20.0 * (i - 35)
        plot_box(ax, x_c, BAR_HALF_Y - TOP_HALF_Y, 0, TOP_HALF_X, TOP_HALF_Y, TOP_HALF_Z, color="#ff8c00", linewidth=0.8, alpha=0.5)

    face_types = event_data["face_type"]
    x_hits = event_data["x_mm"]
    y_hits = event_data["y_mm"]
    z_hits = event_data["z_mm"]
    gun_x_vals = event_data["gun_x_mm"]

    if len(gun_x_vals) == 0:
        raise ValueError(f"event {event_id} has no gun_x_mm values")

    unique_gun_x = np.unique(gun_x_vals.astype(float))
    if unique_gun_x.size != 1:
        raise ValueError(f"gun_x_mm is not constant for event {event_id}: {unique_gun_x.tolist()}")

    gun_x = float(unique_gun_x[0])
    colors = np.array(["#00bcd4" if f == 0 else "#ff4dd2" if f == 1 else "#ffd200" for f in face_types])
    ax.scatter(x_hits, y_hits, z_hits, c=colors, s=12, alpha=0.72, edgecolors="none", label="photon detection hits")
    ax.plot([gun_x, gun_x], [0.0, 0.0], [60.0, -60.0], color="#b2182b", linewidth=2.2, alpha=0.85, label="nominal primary-muon path")

    (x_min, x_max), (y_min, y_max), (z_min, z_max) = detector_limits(zoom)
    ax.set_xlim(x_min, x_max)
    ax.set_ylim(y_min, y_max)
    ax.set_zlim(z_min, z_max)
    ax.view_init(elev=70 if zoom == 1.0 else 55, azim=20)
    ax.set_box_aspect((2.2, 1.0, 0.7))
    ax.set_xlabel("X (mm)")
    ax.set_ylabel("Y (mm)")
    ax.set_zlabel("Z (mm)")

    title = (
        f"Event {event_id} | {material_cfg['scintillator_name']} / {material_cfg['scintillator_code']} | "
        f"gun_x_mm = {gun_x:.1f} mm | {len(x_hits)} photon detection hits"
    )
    subtitle = "Full view" if zoom == 1.0 else "Zoomed view"
    ax.set_title(f"{title}\n{subtitle}", fontsize=11, fontweight="bold")
    ax.legend(loc="upper left", fontsize=8)


def render_event(root_file: Path, output_dir: Path, event_id: int = 0) -> bool:
    output_dir.mkdir(parents=True, exist_ok=True)
    material_key, material_cfg = infer_material(root_file, output_dir)

    with uproot.open(root_file) as root_handle:
        tree = root_handle["sipm_hits"]
        data = tree.arrays(
            ["event_id", "face_type", "global_id", "x_mm", "y_mm", "z_mm", "gun_x_mm", "energy_eV", "wl_nm", "pde"],
            library="np",
        )

    mask = data["event_id"] == event_id
    if not mask.any():
        print(f"Event {event_id} not found in {root_file}")
        return False

    event_data = {key: value[mask] for key, value in data.items()}
    event_ids = np.unique(event_data["event_id"].astype(int))
    if event_ids.size != 1 or int(event_ids[0]) != event_id:
        print(f"Unexpected event_id values in {root_file}: {event_ids.tolist()}")
        return False

    for zoom, output_name in ((1.0, "event_full.png"), (1.8, "event_zoom.png")):
        fig = plt.figure(figsize=(12, 10))
        ax = fig.add_subplot(111, projection="3d")
        render_axes(ax, material_cfg, event_data, event_id, zoom)
        plt.tight_layout()
        fig.savefig(output_dir / output_name, dpi=150, bbox_inches="tight")
        plt.close(fig)

    print(f"Rendered {material_key} event {event_id} -> {output_dir / 'event_full.png'} and event_zoom.png")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    root_file = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    event_id = int(sys.argv[3]) if len(sys.argv) > 3 else 0

    success = render_event(root_file, output_dir, event_id)
    sys.exit(0 if success else 1)
