#!/usr/bin/env python3
"""Replay the saved power-chart calibration without downloading or editing data.

This checks transcription and arithmetic, not whether a pixel follows the right
trace. Visual source review is still required. Uses only the Python standard
library; --root allows checking an isolated copy of the evidence inputs.
"""

import argparse
import json
import math
from pathlib import Path
import sys


INPUTS = (
    "adventure-expansion.json",
    "dual-sport-expansion.json",
    "ktm390-expansion.json",
    "catalog-expansion.json",
    "tuning-expansion.json",
)


def finite_number(value):
    return type(value) in (int, float) and math.isfinite(value)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def verify(root):
    configs = {}
    for name in INPUTS:
        data = json.loads((root / "docs" / name).read_text())
        if isinstance(data, dict):
            data = data.get("entries", data.get("configurations", []))
        for config in data:
            config_id = config["id"]
            require(config_id not in configs, f"duplicate configuration: {config_id}")
            configs[config_id] = config

    ledger = json.loads((root / "docs/dyno-sampling.json").read_text())
    require(isinstance(ledger, list) and ledger, "sampling ledger must be a nonempty list")
    seen = set()
    point_count = 0
    for sample in ledger:
        config_id = sample["configurationId"]
        require(config_id not in seen, f"duplicate ledger configuration: {config_id}")
        seen.add(config_id)
        require(config_id in configs, f"unknown ledger configuration: {config_id}")
        config = configs[config_id]
        require(sample["chart"] and sample["color"], f"{config_id}: missing trace identity")
        asset = sample["asset"]
        require(asset == config["source"]["asset"], f"{config_id}: asset differs from source")
        require((root / asset).is_file(), f"{config_id}: missing asset {asset}")
        canvas = sample["canvas"]
        require(len(canvas) == 2 and all(finite_number(n) and n > 0 for n in canvas),
                f"{config_id}: invalid canvas")
        axis = sample["axis"]
        require(len(axis) == 7 and all(finite_number(n) for n in axis),
                f"{config_id}: invalid calibration")
        x0, rpm0, x1, rpm1, y_zero, y_reference, reference_power = axis
        require(x1 > x0 and rpm1 > rpm0 and y_zero > y_reference and reference_power > 0,
                f"{config_id}: calibration must use increasing RPM and upward power")
        factor = sample["powerToMechanicalHp"]
        require(finite_number(factor) and factor > 0, f"{config_id}: invalid power factor")
        pixels, points = sample["pixels"], config["points"]
        require(len(pixels) == len(points) and len(points) >= 2,
                f"{config_id}: pixel/point counts differ or curve is incomplete")
        previous_rpm = 0
        for index, (pixel, point) in enumerate(zip(pixels, points)):
            context = f"{config_id} sample {index + 1}"
            require(len(pixel) == 3 and all(finite_number(n) for n in pixel),
                    f"{context}: invalid pixel sample")
            require(len(point) == 3 and all(finite_number(n) for n in point),
                    f"{context}: invalid source point")
            rpm, x_pixel, y_pixel = pixel
            require(rpm > previous_rpm and rpm0 <= rpm <= rpm1,
                    f"{context}: RPM is unordered or outside calibration")
            previous_rpm = rpm
            require(0 <= x_pixel < canvas[0] and 0 <= y_pixel < canvas[1],
                    f"{context}: pixel is outside sampling canvas")
            expected_x = x0 + (rpm - rpm0) * (x1 - x0) / (rpm1 - rpm0)
            require(abs(x_pixel - expected_x) <= 0.51,
                    f"{context}: X differs from calibrated RPM by more than half a pixel")
            hp = round((y_zero - y_pixel) * reference_power
                       / (y_zero - y_reference) * factor, 1)
            torque_nm = hp * 7120.9092 / rpm
            require(hp >= 0 and point[0] == rpm,
                    f"{context}: negative power or mismatched RPM")
            require(math.isclose(point[1], hp, rel_tol=0, abs_tol=1e-9),
                    f"{context}: stored HP {point[1]} differs from replay {hp}")
            require(math.isclose(point[2], torque_nm, rel_tol=1e-10, abs_tol=1e-9),
                    f"{context}: stored torque differs from HP-derived torque")
            point_count += 1
    print(f"Verified {len(ledger)} sampled curves / {point_count} points. "
          "Trace identity and calibration still require visual review.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent,
                        help="project root containing docs/ and assets/")
    args = parser.parse_args()
    try:
        verify(args.root)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Sampling verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
