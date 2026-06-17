#!/usr/bin/env python3
"""
Render event displays from ROOT ntuple data.

Usage:
    render_event_display.py <root_file> <output_png> [event_id]

Renders a 3D plot of the EJ-200/EJ-230 scintillator bar detector and detected
photon hits from the sipm_hits TTree.
"""

import sys
import numpy as np
import uproot
import matplotlib
matplotlib.use('Agg')  # Headless backend
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D


# Detector geometry constants (mm)
BAR_HALF_X = 700.0   # Total length: 1400 mm
BAR_HALF_Y = 30.0    # Total width: 60 mm
BAR_HALF_Z = 5.0     # Total height: 10 mm

END_HALF_X = 0.25    # Thickness (±X)
END_HALF_Y = 3.0     # 6 mm in Y
END_HALF_Z = 3.0     # 6 mm in Z
END_PITCH = 2 * END_HALF_Y + 1.5  # 7.5 mm spacing

TOP_HALF_X = 3.0     # 6 mm in X
TOP_HALF_Y = 0.25    # Thickness (±Y)
TOP_HALF_Z = 3.0     # 6 mm in Z


def plot_box(ax, cx, cy, cz, hx, hy, hz, **kwargs):
    """Plot a wireframe box centered at (cx, cy, cz) with half-widths (hx, hy, hz)."""
    # Corners
    x = [-hx, hx]
    y = [-hy, hy]
    z = [-hz, hz]
    
    # 12 edges: 4 per direction (X, Y, Z)
    edges = [
        # X-parallel edges
        [[-hx, hx], [-hy, -hy], [-hz, -hz]],
        [[-hx, hx], [hy, hy], [-hz, -hz]],
        [[-hx, hx], [-hy, -hy], [hz, hz]],
        [[-hx, hx], [hy, hy], [hz, hz]],
        # Y-parallel edges
        [[-hx, -hx], [-hy, hy], [-hz, -hz]],
        [[hx, hx], [-hy, hy], [-hz, -hz]],
        [[-hx, -hx], [-hy, hy], [hz, hz]],
        [[hx, hx], [-hy, hy], [hz, hz]],
        # Z-parallel edges
        [[-hx, -hx], [-hy, -hy], [-hz, hz]],
        [[hx, hx], [-hy, -hy], [-hz, hz]],
        [[-hx, -hx], [hy, hy], [-hz, hz]],
        [[hx, hx], [hy, hy], [-hz, hz]],
    ]
    
    for ex, ey, ez in edges:
        ax.plot([cx + ex[0], cx + ex[1]], [cy + ey[0], cy + ey[1]], [cz + ez[0], cz + ez[1]], **kwargs)


def render_event(root_file, output_png, event_id=0, figsize=(12, 10)):
    """
    Render a 3D event display from ROOT ntuple.
    
    Args:
        root_file: Path to ROOT file with sipm_hits TTree
        output_png: Output PNG file path
        event_id: Event number to display (default 0)
        figsize: Figure size (width, height) in inches
    """
    
    # Open ROOT file and read data
    with uproot.open(root_file) as f:
        tree = f['sipm_hits']
        
        # Read all columns
        data = tree.arrays(['event_id', 'face_type', 'global_id', 'x_mm', 'y_mm', 'z_mm', 
                           'energy_eV', 'wl_nm', 'pde'], library='np')
        
        # Filter to the requested event
        mask = data['event_id'] == event_id
        if not mask.any():
            print(f"Event {event_id} not found in {root_file}")
            return False
        
        event_data = {k: v[mask] for k, v in data.items()}
        
    # Create figure
    fig = plt.figure(figsize=figsize)
    ax = fig.add_subplot(111, projection='3d')
    
    # Plot bar (translucent blue)
    plot_box(ax, 0, 0, 0, BAR_HALF_X, BAR_HALF_Y, BAR_HALF_Z, 
             color='blue', linewidth=1.5, alpha=0.3, label='Scintillator bar')
    
    # Plot End SiPMs (left and right)
    # End-left SiPMs (face_type=0): at x = -700 + 0.25
    for i in range(8):
        y_c = -30 + 1.5 + i * 7.5
        plot_box(ax, -(BAR_HALF_X - END_HALF_X), y_c, 0, END_HALF_X, END_HALF_Y, END_HALF_Z,
                 color='green', linewidth=0.8, alpha=0.5)
    
    # End-right SiPMs (face_type=1): at x = +700 - 0.25
    for i in range(8):
        y_c = -30 + 1.5 + i * 7.5
        plot_box(ax, +(BAR_HALF_X - END_HALF_X), y_c, 0, END_HALF_X, END_HALF_Y, END_HALF_Z,
                 color='green', linewidth=0.8, alpha=0.5)
    
    # Plot Top SiPMs (face_type=2)
    # These are positioned along X with varying pitch (see DetectorConstruction.cc)
    for i in range(70):
        if i < 35:
            x_c = -692.0 + 20.0 * i
        else:
            x_c = 12.0 + 20.0 * (i - 35)
        plot_box(ax, x_c, BAR_HALF_Y - TOP_HALF_Y, 0, TOP_HALF_X, TOP_HALF_Y, TOP_HALF_Z,
                 color='orange', linewidth=0.8, alpha=0.5)
    
    # Plot detected photons as scatter points, colored by face type
    face_types = event_data['face_type']
    x_hits = event_data['x_mm']
    y_hits = event_data['y_mm']
    z_hits = event_data['z_mm']
    
    # Map face type to color: 0=end-left (cyan), 1=end-right (magenta), 2=top (yellow)
    colors = np.array(['cyan' if f == 0 else 'magenta' if f == 1 else 'yellow' for f in face_types])
    
    ax.scatter(x_hits, y_hits, z_hits, c=colors, s=10, alpha=0.6, edgecolors='none', label='Detected photons')
    
    # Add 1 GeV muon trajectory from +Z to -Z at gun position
    gun_x = float(event_data['x_mm'][0])  # Assume same for all hits in one event
    ax.plot([gun_x, gun_x], [0, 0], [60, -60], 'r-', linewidth=2, alpha=0.7, label='Muon trajectory (1 GeV)')
    
    # Labels and formatting
    ax.set_xlabel('X (mm)', fontsize=10)
    ax.set_ylabel('Y (mm)', fontsize=10)
    ax.set_zlabel('Z (mm)', fontsize=10)
    ax.set_xlim(-750, 750)
    ax.set_ylim(-100, 100)
    ax.set_zlim(-100, 100)
    
    title = f"Event {event_id}: {len(x_hits)} photons detected\n"
    title += f"Gun X = {gun_x:.1f} mm | Scint: OPSC-101 | Readout: EndTop"
    ax.set_title(title, fontsize=12, fontweight='bold')
    ax.legend(loc='upper left', fontsize=9)
    
    # Save figure
    plt.tight_layout()
    plt.savefig(output_png, dpi=150, bbox_inches='tight')
    plt.close()
    
    return True


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    root_file = sys.argv[1]
    output_png = sys.argv[2]
    event_id = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    
    success = render_event(root_file, output_png, event_id)
    sys.exit(0 if success else 1)
