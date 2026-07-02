# assets/ 说明（资产瘦身约定）

## `.png` 文件名 ≠ PNG 内容

本目录下多数 `*.png` 文件的**实际内容是 WebP 编码**（有损 q80），文件名仍保留 `.png`。

**为什么这么做**（2026-07-02 资产瘦身批，用户拍板方案 A）：
- 原始 PNG 分发包约 210MB，有损 WebP 可压到 ~65MB（省约 69%），画质肉眼无可辨损失（水墨/厚涂风格对有损压缩极友好）。
- Flutter 的 `AssetImage` 读取文件 bytes 后交 skia codec，**解码按内容 magic bytes 嗅探，不依赖扩展名**。故文件名保留 `.png`、内容换成 WebP，可正常解码。
- 好处：`lib/` 与 `data/` 中约 475 处 `.png` 引用及 `pubspec.yaml` 目录声明**零改动**，避免改扩展名带来的大面积漏改（漏改即运行期资产静默缺失）。

**验证守卫**：`test/data/webp_in_png_decode_test.dart` 端到端证明经 rootBundle 读到 WebP bytes 并被 skia 解出正确尺寸。

## 判断某张图是 PNG 还是 WebP 内容

```sh
file assets/characters/founder.png
# RIFF (little-endian) data, Web/P image, VP8 encoding, ... → 内容是 WebP
# PNG image data ...                                        → 内容是真 PNG（小图标转了反而变大，保持原样）
```

约 110 张小图标（转 WebP 无收益甚至变大）保持真 PNG 内容。

## 新增 / 更新大图资产

放入对应子目录后，用仓库脚本转码（幂等，已是 WebP 的会跳过，无收益的保持 PNG）：

```sh
python3 tool/convert_assets_webp.py
```

依赖 Python Pillow（`pip3 install Pillow`，已支持 WebP）。质量档 q80，只转有 ≥10% 收益的文件。
