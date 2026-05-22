# chapter narrative 0 引用半完成 audit(2026-05-22)

> 派单方:Mac Opus 4.7(3h 托管 A1 批次)
> 发现:Ch1-4 chapter_X.yaml prologue/epilogue **在 lib/ 0 引用**(半完成 / 维度 D UI widget 未建)

## TL;DR

`data/narratives/chapters/chapter_{01,02,03,04}.yaml` 共 4 文件 / ~3,500 字章首尾文案,**lib/ 0 caller** ⚠ — memory `feedback_phase0_grep_two_axes` 维度 B「半完成」+ 维度 D「UI widget 未建」复合格子。**stage narrative(opening/victory/defeat)消费正常** ✅(`stage_entry_flow.dart` + `tower_entry_flow.dart` 走 NarrativeLoader.load),chapter 体例独立无 widget 显示。

## grep 验证

```bash
$ grep -rn "prologue\|epilogue\|chapterContent\|chapter_narrative\|chapterId" lib/
# 0 命中

$ grep -rn "chapter_0\|narratives/chapter" lib/
# 0 命中

$ grep -rln "narratives/chapters\|chapters/chapter_" lib/
# 0 命中
```

stage narrative 消费(对照,正常):
```bash
$ grep -rn "NarrativeLoader.load\|narrativeOpeningId\|narrativeVictoryId\|narrativeDefeatId" lib/
# 命中 stage_entry_flow.dart L66/L107/L156 + tower_entry_flow.dart L66
```

## 挂账方案(不动 lib/)

| 项 | 处理 |
|---|---|
| 4 文件 ~3,500 字章首尾文案 | **保留**(文化承载创作输出,Ch4 epilogue「已知不足顿悟」+ chapter_03 epilogue「师父遗言」均为剧情核心节点) |
| lib/ widget 接入 | **挂账 1.0 P2 P3 UI 完善阶段**(参 P1.3 美术线 round 1 模式 — 89 张 assets 归位先,UI widget 留 1.0 P2 P3 完善) |
| 推荐 UI 接入位置 | ① ChapterListScreen 章卡 tap 进入 ChapterIntroScreen 显 prologue ② 章末关战胜后(stage_X_05_victory 后)push ChapterEpilogueScreen 显 epilogue |

## 与已知模式关系

- memory `feedback_phase0_grep_two_axes` 维度 B(半完成):chapter narrative 是典型 yaml 占位 + 0 caller
- memory `feedback_phase0_grep_two_axes` 维度 D(UI widget 未建):chapter intro/outro 也无 widget,与 P1.3 美术 round 1 同类格子
- memory `feedback_extension_hardcode_audit` 周期清账:chapter narrative 不属此格(不是 extension on 硬编码)

## 不挂账理由

- **不破代码**:chapter 0 caller 不抛错,只是缺 UI 接入
- **不破测试**:1178 pass 不动(chapter narrative 不在 NarrativeLoader.load 调用路径)
- **不破玩家体验**:Demo 阶段玩家通关 Ch1-3 无 chapter intro/outro,跟 GDD §10.3「让玩家先感受问题再给答案」一致(章首尾叙事可延后)

## 后续

1.0 P2 P3 UI 完善阶段触发时,**预估 ~30-45min** 加 ChapterIntroScreen + ChapterEpilogueScreen + chapter loader(沿 NarrativeLoader.load 体例,扫描 `data/narratives/chapters/chapter_<N>.yaml`)+ stage_entry_flow.dart 增加 chapter intro/outro 触发节点。
