# 资产 WebP 转码试点(2026-07-10)

## 结论

不执行全量 PNG → WebP 转码。旧 backlog 的「210MB PNG / -85%」口径已失效:
当前 `assets/` 共约 74MB(含约 15MB 音频),383 个 `.png` 路径合计 58.0MB,
其中 272 个文件(44.7MB)的 magic bytes 已是 WebP RIFF,只是保留 `.png` 扩展名。

真正的 PNG 仅 111 个(13.3MB):

- `assets/equipment/`:110 个带 alpha 的装备图,合计 12.5MB。
- `assets/maps/taohuaIsland.png`:1 个不带 alpha 的地图,832,052 bytes。

推荐只把桃花岛列为单张 `q82` 候选;其余资产保持现状。272 个扩展名与
内容不一致的历史文件不批量改名,因为改 272 条引用没有包体收益,后续触达时再归一。

## 方法

运行:

```bash
brew install webp
tools/run_asset_webp_pilot.sh
```

脚本对 8 个生产引用样本生成 `q82`、`q88`、lossless 三档候选,输出:

- `build/asset_webp_pilot/results.csv`:体积、SSIM、alpha 精确性。
- `build/asset_webp_pilot/magic_inventory.csv`:全部 `.png` 路径的真实编码。
- `build/asset_webp_pilot/comparisons/`:PNG / q82 / q88 / lossless 四联图。

## 样本结果

| 样本 | 真实编码 | q82 / 原大小 | q88 / 原大小 | lossless / 原大小 | 判断 |
|---|---:|---:|---:|---:|---|
| first_disciple | WebP | 102.8% | 119.4% | 454.8% | 已是 WebP,不重压 |
| bandit_head | WebP | 101.2% | 119.3% | 474.6% | 已是 WebP,不重压 |
| accessory_liqi_hu_xin_jing_detail | WebP+alpha | 100.3% | 107.9% | 283.7% | 已是 WebP,不重压 |
| armor_baowu_wu_jin_zhan_jia_detail | PNG+alpha | 100.5% | 114.5% | 96.1% | 有损边缘破坏,lossless 收益太小 |
| taohuaIsland | PNG | **24.2%** | 32.8% | 87.0% | q82 候选 |
| battle_alley | WebP | 102.7% | 118.8% | 480.5% | 已是 WebP,不重压 |
| overlay_low_health_blend | WebP+alpha | 100.1% | 104.5% | 231.7% | 已是 WebP,不重压 |
| paper_bg | WebP | 106.6% | 123.4% | 443.8% | 已是 WebP,不重压 |

8 样本 q82 合计仅节省 15.8%,且收益几乎全部来自桃花岛。6 张地图复核中,
另外 5 张实际已是 WebP,重新 q82 后均为原大小的 99.2%-100.3%。

110 张真实 PNG 装备图的 lossless 全量探针从 12.49MB 降至 11.64MB,
只节省 0.85MB(6.8%);只转节省 ≥10% 的 20 张则仅省 0.16MB,不抵引用改动成本。

## 画质观察

- 桃花岛 q82 四联图肉眼无可见构图、色阶或水墨细节损失,SSIM=0.972005,
  832,052 → 201,722 bytes,节省 75.8%。仍需最终人工确认后才替换生产引用。
- 已转 WebP 的人物/敌人/场景再次编码没有体积收益,避免 generation loss。
- 带 alpha 装备图即使 alpha 哈希逐像素一致,有损 RGB 仍会在半透明笔触处形成
  明显浅色块与硬边;透明资产禁止有损 WebP。lossless 可保持画面,但整体收益过低。

## 决策

1. 关闭“全量转码”任务,不进行 383 文件机械替换。
2. 桃花岛 q82 保留为唯一生产候选,等待人工四联图目检确认。
3. 新增或替换资产时要求扩展名与 magic bytes 一致;历史 272 文件按触达迁移。
4. 不把 `build/asset_webp_pilot/` 对比图提交进 Git,防止验收图片再次污染历史。
