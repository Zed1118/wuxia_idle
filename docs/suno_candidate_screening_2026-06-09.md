# Suno 候选音乐下载与初筛记录

> 日期：2026-06-09
> 来源：Suno Pro，Chrome 已登录账号生成。
> 保存目录：`assets/audio/_suno_candidates/`
> 说明：本记录只做客观初筛（是否下载成功、时长、体积、是否明显偏离目标时长）。最终采用哪一版仍需人工试听。

## 1. 下载结果

- 槽位数：16
- 每槽候选：2
- 文件数：32
- 总体积：约 87 MB
- 直接接线槽位：`mainMenu`、`battle`、`seclusion`
- 扩展 BGM：`mainline`、`tower`、`boss`、`innerDemon`、`lightFoot`、`massBattle`、`lineage`、`baike`
- 短音乐 jingle：`victoryJingle`、`defeatJingle`、`bossBreakJingle`、`rareDropJingle`、`realmAdvanceJingle`

## 2. 客观初筛

| 槽位 | 候选 | 时长 | 体积 | 初筛 |
|---|---|---:|---:|---|
| baike | `baike_candidate_01.mp3` | 177.0s | 4.1M | 可试听 |
| baike | `baike_candidate_02.mp3` | 179.0s | 4.0M | 可试听 |
| battle | `battle_candidate_01.mp3` | 122.3s | 3.1M | 可试听，时长更合适 |
| battle | `battle_candidate_02.mp3` | 49.9s | 2.0M | 偏短，备选 |
| boss | `boss_candidate_01.mp3` | 124.8s | 3.0M | 可试听 |
| boss | `boss_candidate_02.mp3` | 123.6s | 3.1M | 可试听 |
| bossBreakJingle | `bossBreakJingle_candidate_01.mp3` | 46.3s | 2.0M | 过长，只适合剪片段 |
| bossBreakJingle | `bossBreakJingle_candidate_02.mp3` | 64.8s | 2.0M | 过长，只适合剪片段 |
| defeatJingle | `defeatJingle_candidate_01.mp3` | 22.8s | 532K | 偏长，可剪片段 |
| defeatJingle | `defeatJingle_candidate_02.mp3` | 106.5s | 3.0M | 过长，不建议直接用 |
| innerDemon | `innerDemon_candidate_01.mp3` | 84.0s | 2.0M | 略短，可试听 |
| innerDemon | `innerDemon_candidate_02.mp3` | 26.2s | 588K | 过短，备选片段 |
| lightFoot | `lightFoot_candidate_01.mp3` | 92.0s | 3.0M | 可试听 |
| lightFoot | `lightFoot_candidate_02.mp3` | 131.5s | 3.1M | 可试听 |
| lineage | `lineage_candidate_01.mp3` | 97.7s | 3.0M | 可试听 |
| lineage | `lineage_candidate_02.mp3` | 120.8s | 3.1M | 可试听 |
| mainMenu | `mainMenu_candidate_01.mp3` | 188.8s | 5.0M | 稍长，可试听 |
| mainMenu | `mainMenu_candidate_02.mp3` | 132.9s | 3.0M | 可试听，时长更合适 |
| mainline | `mainline_candidate_01.mp3` | 153.0s | 4.1M | 可试听 |
| mainline | `mainline_candidate_02.mp3` | 168.6s | 4.0M | 可试听 |
| massBattle | `massBattle_candidate_01.mp3` | 174.4s | 4.1M | 可试听 |
| massBattle | `massBattle_candidate_02.mp3` | 180.0s | 5.1M | 可试听，略大 |
| rareDropJingle | `rareDropJingle_candidate_01.mp3` | 12.8s | 296K | 可剪片段 |
| rareDropJingle | `rareDropJingle_candidate_02.mp3` | 13.2s | 320K | 可剪片段 |
| realmAdvanceJingle | `realmAdvanceJingle_candidate_01.mp3` | 9.4s | 220K | 可剪片段 |
| realmAdvanceJingle | `realmAdvanceJingle_candidate_02.mp3` | 13.2s | 276K | 可剪片段 |
| seclusion | `seclusion_candidate_01.mp3` | 209.7s | 5.0M | 偏长但可用于闭关 |
| seclusion | `seclusion_candidate_02.mp3` | 187.9s | 5.1M | 稍长，可试听 |
| tower | `tower_candidate_01.mp3` | 159.8s | 4.1M | 可试听 |
| tower | `tower_candidate_02.mp3` | 164.3s | 4.0M | 可试听 |
| victoryJingle | `victoryJingle_candidate_01.mp3` | 14.5s | 328K | 可剪片段 |
| victoryJingle | `victoryJingle_candidate_02.mp3` | 12.8s | 292K | 可剪片段 |

## 3. 初步建议

按客观时长优先试听：

- `mainMenu`：先听 `candidate_02`。
- `battle`：先听 `candidate_01`。
- `seclusion`：两条都偏长，先听 `candidate_02`。
- `mainline`：两条都可听。
- `tower`：两条都可听。
- `boss`：两条都可听。
- `innerDemon`：先听 `candidate_01`。
- `lightFoot`：两条都可听。
- `massBattle`：先听 `candidate_01`。
- `lineage`：两条都可听。
- `baike`：两条都可听。

Jingle 结论：

- `victoryJingle`、`rareDropJingle`、`realmAdvanceJingle` 时长仍偏长，但可从前 1-3 秒剪出可用片段。
- `defeatJingle_candidate_01` 可尝试剪片段；`candidate_02` 太长。
- `bossBreakJingle` 两条都明显过长，不建议直接用，后续更适合用专门 SFX 工具生成。

## 4. 后续入库步骤

人工试听拍板后：

1. 将被选中的 3 个当前接线 BGM 复制为：
   - `assets/audio/bgm/mainMenu.mp3`
   - `assets/audio/bgm/battle.mp3`
   - `assets/audio/bgm/seclusion.mp3`
2. 对 jingle 先剪辑到 1-3 秒，再考虑接线。
3. 扩展 BGM 需要先在 `BgmTrack` 加 enum 和 hook，再复制到 `assets/audio/bgm/`。
4. 建议后期统一响度，BGM 目标约 -18 LUFS，jingle 约 -16 LUFS。

