# 挂机武侠 Suno 音乐素材包说明

> 桌面文件夹：`~/Desktop/挂机武侠_音乐素材_Suno_20260609`
> 生成来源：Suno Pro
> 生成日期：2026-06-09
> 文件数：32 个 mp3

## 命名规则

- `推荐`：按用途和时长客观筛选后优先试听。
- `备选`：同槽位第二候选，或时长略不理想但仍可试听。
- `需剪辑`：Suno 生成得比目标 jingle 长，需要剪到 1-3 秒再入库。
- `不建议直接用`：明显过长或用途偏离，保留做参考/采样，不建议直接放游戏。
- `当前接线`：当前 Flutter 工程已经能直接识别的 BGM 槽位。
- `扩展BGM`：后续需要先加 `BgmTrack` enum 和播放 hook。
- `Jingle`：短音乐提示，不是普通按钮/命中 SFX。

## 优先试听顺序

当前工程可直接接线的 3 首：

1. `01_推荐_当前接线_mainMenu_主菜单_candidate02_132s.mp3`
2. `03_推荐_当前接线_battle_战斗_candidate01_122s.mp3`
3. `05_推荐_当前接线_seclusion_闭关_candidate02_188s_稍长.mp3`

扩展 BGM：

1. `07_推荐_扩展BGM_mainline_主线_candidate01_153s.mp3`
2. `09_推荐_扩展BGM_tower_爬塔_candidate01_160s.mp3`
3. `11_推荐_扩展BGM_boss_Boss战_candidate01_125s.mp3`
4. `13_推荐_扩展BGM_innerDemon_心魔_candidate01_084s_略短.mp3`
5. `15_推荐_扩展BGM_lightFoot_轻功_candidate02_132s.mp3`
6. `17_推荐_扩展BGM_massBattle_守城_candidate01_174s.mp3`
7. `19_推荐_扩展BGM_lineage_师徒传承_candidate02_121s.mp3`
8. `21_推荐_扩展BGM_baike_江湖见闻录_candidate01_177s.mp3`

Jingle：

- 先听 `23_需剪辑_Jingle_victory_胜利_candidate02_013s.mp3`。
- 先听 `25_需剪辑_Jingle_defeat_失败_candidate01_023s.mp3`。
- 先听 `29_需剪辑_Jingle_rareDrop_珍稀掉落_candidate01_013s.mp3`。
- 先听 `31_需剪辑_Jingle_realmAdvance_境界突破_candidate01_009s.mp3`。
- `bossBreak` 两条都过长，不建议直接用，后续更适合专门 SFX 工具重做。

## 入库建议

人工试听拍板后，把最终选中的当前接线 BGM 复制到：

```text
assets/audio/bgm/mainMenu.mp3
assets/audio/bgm/battle.mp3
assets/audio/bgm/seclusion.mp3
```

不要直接把扩展 BGM 放进正式路径，除非代码已经新增对应 `BgmTrack`。

Jingle 需要先剪辑、统一响度，再考虑加入 `SfxId`。

