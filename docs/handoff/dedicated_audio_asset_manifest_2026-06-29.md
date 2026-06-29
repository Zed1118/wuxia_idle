# 专属战斗音频素材 Manifest

> 日期：2026-06-29  
> 用途：记录 `battleUlt` / `battleChargeStart` 专属素材缺口、当前转用状态和安全替换计划。

## 当前结论

仓库与主项目 `_suno_candidates` 均未发现可直接入库的 `battleUlt` / `battleChargeStart` 专属候选。当前正式路径里有可播放 mp3，但它们是临时转用裁切素材：

| 槽位 | 正式路径 | 当前状态 | 当前来源 | 目标时长 | 专属方向 |
|---|---|---|---|---:|---|
| `battleUlt` | `assets/audio/sfx/battleUlt.mp3` | `temporaryBorrowed` | `realmAdvance` 裁切 | 0.8-1.6s | 大招/绝技释放，琴弦聚势 + 钟磬 + 气劲 |
| `battleChargeStart` | `assets/audio/sfx/battleChargeStart.mp3` | `temporaryBorrowed` | `defeat` 裁切 | 0.5-1.2s | Boss 蓄力预警，低弦绷紧 + 气息聚拢 |

## 工程护栏

- 播放路径不变：`sfxAssetPath(SfxId.battleUlt)` / `sfxAssetPath(SfxId.battleChargeStart)` 仍指向正式 mp3。
- `SoundManager` 缺素材仍静默 no-op，不破坏现有战斗播放。
- 新增 `dedicatedSfxAssetStatus` 只读表，CI 可识别这两个槽位当前不是最终专属素材。
- `audio_assets_test.dart` 仍保证“接线文件存在”；`dedicated_audio_assets_test.dart` 负责保证“专属状态不被误判”。

## 替换计划

1. 用 `docs/_archive/suno/suno_dedicated_battle_sfx_prompts_2026-06-29.md` 生成每槽 3-4 个候选。
2. 候选先放入非正式目录，不直接覆盖正式路径。
3. 技术筛选：可解码、非静音、时长合格、峰值不超过 -3 dB 左右。
4. 人工试听：`battleUlt` 不像 `realmAdvance` / `victory`；`battleChargeStart` 不像 `defeat`。
5. 替换正式 mp3。
6. 将 `dedicated_audio_assets.dart` 对应状态改为 `finalAsset`，清空 `borrowedFrom`。
7. 跑 targeted audio tests、`flutter analyze`，再真机听感复核。
