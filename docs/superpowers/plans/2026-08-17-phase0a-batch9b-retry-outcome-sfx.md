# Phase 0A Batch 9B：终局重试入口 + 胜负 jingle

**日期**：2026-08-17
**基线**：`main@66c6f1d7`
**分支**：`feat/phase0a-batch9b-retry-outcome-sfx`
**来源**：BACKLOG 二#13 ② + Batch 9A 冻结遗留（victory/defeat jingle 归本批）

## 目标

终局（破阵/败退封签落下）后玩家可以原地「再战」，不必退出重进；
终局瞬间播放胜利/败北 jingle，与旧 3v3 战斗听感对齐。

## 冻结范围

1. **终局 jingle**：`Phase0aBattleVictory → SfxId.victory`，
   `Phase0aBattleDefeat → SfxId.defeat`（资产均已在库，旧战斗同语义先例
   `battle_screen.dart:561-563`）。翻转 9A 的两条静默断言。
2. **重试入口**：终局封签下方出现「再战」纸签按钮 + Enter 键同效。
   - `Phase0aBattleController.restart(newFlow)`：换入全新 flow、重建
     sequencer/VFX 控制器（VFX `_sealed` 终局后不可逆，必须重建）、
     清空 pending/事件/反馈缓存。表现层职责，domain/reducer/flow 零改动。
   - `Phase0aBattleScreen` 新增可选 `retryFlowBuilder`
     （`Future<Phase0aWaveBattleFlow> Function()?`）：为 null 时按钮不出现
     （静态验收三路保留纯展示语义）。重试点击播 `SfxId.uiTap`。
   - debug 可玩路由接线：`retryFlowBuilder` = 重载
     `Phase0aDebugBattleFixture.load` 取新 flow（同 seed 同规格新会话）。
3. 重试后局部表现态全清（held feedback/命中闪白/血条强调/累加器），
   焦点归还屏幕 FocusNode，autoStep 语义不变。

## 禁止项

- 不改 domain/reducer/flow 源码任何规则与数值（restart 只换实例）。
- 不接终局下游（奖励/掉落/成长/存档），不接 BGM，不新增 SfxId/资产。
- 不做键盘焦点遍历/Tab 导航（那是 ③）。
- 不修改旧 3v3 战斗。
- 「再战」文案进 `UiStrings`，按钮尺寸进 `Phase0aPresentationTokens`，
  不散写。

## 验收

- sfx 映射单测更新：victory/defeat 正向断言（原静默断言翻转）。
- controller 单测：打到 victory → restart → outcome=ongoing、tick/seq 回
  初始、首波敌人全量恢复、新事件流被接受（sequencer 不吞 seq）。
- widget 测：终局后按钮可见、点击后封签消失且 state 复位再战；
  `retryFlowBuilder == null` 时按钮不出现；Enter 键触发同效。
- 9A 音效接线红测、8A/8B 全部表现层测试零回归。
- `flutter analyze --no-pub` 0 issue；`dart format` 门禁净；全量逐值吻合。

## 恢复点

- RP0：计划冻结。
- RP1：jingle 映射 + controller.restart + 屏幕重试实装，测试绿。
- GATE：破坏证红 + 全量 + 合入 main + 收账。
