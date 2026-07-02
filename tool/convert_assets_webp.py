#!/usr/bin/env python3
"""资产瘦身：把 assets/ 下的 PNG 有损转 WebP（保留 .png 文件名）。

见 assets/README.md 的方案说明。要点：
- 文件名保留 .png，内容替换为 WebP（q80）；Flutter 按内容嗅探解码，引用零改动。
- 幂等：已是 WebP 内容的文件跳过；转后无 ≥10% 收益的保持原 PNG（小图标转了反变大）。

用法：python3 tool/convert_assets_webp.py [--dry-run]
依赖：Pillow（已支持 WebP）。
"""
import glob
import io
import os
import sys

from PIL import Image

QUALITY = 80
METHOD = 6
GAIN_THRESHOLD = 0.90  # 转后须 < 原始 * 0.90 才落盘

# 仓库根 = 本脚本上一级目录
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def is_webp(path):
    with open(path, "rb") as fh:
        head = fh.read(12)
    return head[:4] == b"RIFF" and head[8:12] == b"WEBP"


def mb(n):
    return f"{n / 1048576:.1f}M"


def main():
    dry_run = "--dry-run" in sys.argv
    pngs = sorted(glob.glob(os.path.join(ROOT, "assets", "**", "*.png"), recursive=True))
    converted = skipped_nogain = already = 0
    saved = 0
    for p in pngs:
        if is_webp(p):
            already += 1
            continue
        ps = os.path.getsize(p)
        img = Image.open(p)
        buf = io.BytesIO()
        img.save(buf, "WEBP", quality=QUALITY, method=METHOD)
        ws = buf.tell()
        if ws < ps * GAIN_THRESHOLD:
            if not dry_run:
                with open(p, "wb") as fh:
                    fh.write(buf.getvalue())
            converted += 1
            saved += ps - ws
        else:
            skipped_nogain += 1
    verb = "将转码" if dry_run else "已转码"
    print(f"{verb} {converted} 张 / 保持PNG(无收益) {skipped_nogain} 张 / 已是WebP跳过 {already} 张")
    print(f"节省 {mb(saved)}")


if __name__ == "__main__":
    main()
