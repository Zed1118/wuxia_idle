#!/usr/bin/env python3
"""Crop a macOS window screenshot to its exact Flutter content viewport."""

import argparse
from pathlib import Path
from typing import Any, Dict

from PIL import Image


def crop_window_content(
    path: Path, *, logical_width: int, logical_height: int
) -> Dict[str, Any]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    pixel_width, pixel_height = image.size
    dpr = pixel_width / float(logical_width)
    if abs(dpr - round(dpr, 4)) > 0.001:
        raise ValueError("unable to infer stable DPR from screenshot width")
    target_height = round(logical_height * dpr)
    if pixel_height < target_height:
        raise ValueError(
            "window screenshot is smaller than requested content: "
            "%dx%d < %dx%d"
            % (pixel_width, pixel_height, pixel_width, target_height)
        )
    titlebar_pixels = pixel_height - target_height
    cropped = image.crop((0, titlebar_pixels, pixel_width, pixel_height))
    cropped.save(path)
    return {
        "dpr": dpr,
        "titlebar_pixels": titlebar_pixels,
        "pixel_width": pixel_width,
        "pixel_height": target_height,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Crop a captured NSWindow to an exact Flutter logical viewport."
    )
    parser.add_argument("image", type=Path)
    parser.add_argument("--logical-width", type=int, required=True)
    parser.add_argument("--logical-height", type=int, required=True)
    args = parser.parse_args()
    result = crop_window_content(
        args.image,
        logical_width=args.logical_width,
        logical_height=args.logical_height,
    )
    print(
        "VISUAL_CONTENT_CROP: dpr={dpr:g} titlebar_pixels={titlebar_pixels} "
        "pixels={pixel_width}x{pixel_height}".format(**result)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
