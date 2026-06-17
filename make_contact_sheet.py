#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT_DIR = Path("/home/reriosto/SHiP/event_display_ej204_ej230")
SUMMARY_DIR = ROOT_DIR / "summary"


def label(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str) -> None:
    draw.rectangle(box, outline="black", width=3)
    draw.text((box[0] + 12, box[1] + 12), text, fill="black")


def main() -> int:
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 26)
    except Exception:
        font = ImageFont.load_default()

    cell_w, cell_h = 1600, 900
    canvas = Image.new("RGB", (cell_w * 3, cell_h * 2 + 120), "white")
    draw = ImageDraw.Draw(canvas)
    positions = ["xm690", "xm400", "x0"]
    materials = ["ej204", "ej230"]
    for row, material in enumerate(materials):
        for col, pos in enumerate(positions):
            path = ROOT_DIR / "outputs" / material / pos / "event_full.png"
            box = (col * cell_w, row * cell_h + 60, (col + 1) * cell_w, (row + 1) * cell_h + 60)
            if path.exists():
                img = Image.open(path).convert("RGB").resize((cell_w, cell_h))
                canvas.paste(img, (col * cell_w, row * cell_h + 60))
            label(draw, box, f"{material.upper()} {pos}")

    draw.text((20, 10), "EJ-204 and EJ-230 EndTop event displays", fill="black", font=font)
    out = SUMMARY_DIR / "event_display_6panel.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
