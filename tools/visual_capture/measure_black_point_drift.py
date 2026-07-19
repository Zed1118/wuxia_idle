#!/usr/bin/env python3
"""Sample one aligned standee across scene screenshots without background pixels."""

import argparse
import json
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

import numpy as np
from PIL import Image


def _luminance(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]


def stable_character_mask(
    images: Sequence[np.ndarray],
    max_channel_drift: float = 0.04,
    luminance_max: float = 0.55,
) -> np.ndarray:
    if len(images) < 2:
        raise ValueError("at least two aligned samples are required")
    stack = np.stack(images)
    stable = (stack.max(axis=0) - stack.min(axis=0)).max(axis=2) <= max_channel_drift
    return stable & (_luminance(stack[0]) < luminance_max)


def sample_black_points(
    images: Sequence[np.ndarray],
    mask: np.ndarray,
    percentile: float = 5,
) -> Dict[str, object]:
    if not mask.any():
        raise ValueError("stable character mask is empty")
    values = [float(np.percentile(_luminance(image)[mask], percentile)) for image in images]
    return {
        "percentile": percentile,
        "values": values,
        "drift": max(values) - min(values),
    }


def _sample(raw: str) -> Tuple[str, Path]:
    if "=" not in raw:
        raise argparse.ArgumentTypeError("sample must be NAME=PNG")
    name, path = raw.split("=", 1)
    return name, Path(path)


def _crop(raw: str) -> Tuple[int, int, int, int]:
    values = tuple(int(value) for value in raw.split(","))
    if len(values) != 4 or min(values[2:]) <= 0:
        raise argparse.ArgumentTypeError("crop must be X,Y,WIDTH,HEIGHT")
    x, y, width, height = values
    return x, y, x + width, y + height


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample", action="append", type=_sample, required=True)
    parser.add_argument("--crop", type=_crop, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-channel-drift", type=float, default=0.04)
    args = parser.parse_args()

    names: List[str] = []
    images: List[np.ndarray] = []
    for name, path in args.sample:
        names.append(name)
        crop = Image.open(path).convert("RGB").crop(args.crop)
        images.append(np.asarray(crop, dtype=np.float32) / 255.0)

    mask = stable_character_mask(
        images,
        max_channel_drift=args.max_channel_drift,
    )
    sampled = sample_black_points(images, mask)
    values = dict(zip(names, sampled["values"]))
    result = {
        "method": "aligned stable dark pixels, luminance p05",
        "crop": list(args.crop),
        "maxChannelDrift": args.max_channel_drift,
        "maskPixels": int(mask.sum()),
        "samples": values,
        "drift": sampled["drift"],
        "limit": 0.05,
        "passes": sampled["drift"] <= 0.05,
    }

    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "black_point_drift.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    Image.fromarray(mask.astype(np.uint8) * 255).save(
        args.output / "same_person_stable_mask.png"
    )
    separator = np.full((images[0].shape[0], 8, 3), 236, dtype=np.uint8)
    sample_strip = np.concatenate(
        [
            item
            for index, image in enumerate(images)
            for item in (
                ([separator] if index else [])
                + [(image * 255).round().astype(np.uint8)]
            )
        ],
        axis=1,
    )
    Image.fromarray(sample_strip).save(args.output / "same_person_samples.png")
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
