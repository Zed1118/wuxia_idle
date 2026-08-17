# Phase 0A Batch 9A：战斗音效接线

**日期**：2026-08-17
**基线**：`main@0ad4c869`
**分支**：`feat/phase0a-batch9a-sfx-wiring`
**来源**：BACKLOG 二#13 ①（Batch 8B 合入后解锁）

## 目标

Phase 0A 单角色水墨战斗屏复用正式 `shared/audio` 语义播放战斗音效，
消除「静默打斗」观感。只接线，不改任何战斗规则与数值。

## 冻结范围

事件 → 音效映射（只用磁盘上已有资产的既有 SfxId / 变体，不新增无资产槽位）：

| 事件 | 音效 | 依据 |
| --- | --- | --- |
| `Phase0aHitLanded` 普攻命中 | `battleHitAssetPath(teamSide, 0)` 按出手方选边 | 旧战斗 `battle_playback_controller` 同体例 |
| `Phase0aHitLanded` 暴击 | `SfxId.battleCrit` | `sfxForAction` 优先级:大招 > 暴击 > 命中 |
| `Phase0aHitLanded` isUltimate | `SfxId.battleUlt` | 同上 |
| `Phase0aGatherStarted`（Q） | `SfxId.battleChargeStart` | 力场起手预警为全库语义最接近的既有资产；用户可否决 |
| `Phase0aClearStarted`（R） | `SfxId.battleUlt` | 清场 = 大招语义 |
| `Phase0aEnemyDefeated` | **静默** | `battleDeath.mp3` 资产不存在，受「不新增无资产 SfxId」约束；待资产或拍板 |
| 其余（波次/终局/可用性） | 静默 | victory/defeat jingle 归 Batch 9B 终局重试入口一并评估 |

## 禁止项

- 不改 domain/reducer/flow 任何战斗规则，不改 `numbers.yaml`。
- 不新增 SfxId 枚举值，不新增音频资产，不接 BGM。
- 不做胜利/败北 jingle（留给 9B 终局批一并拍）。
- 不修改旧 3v3 战斗接线。
- 音效只在表现层消费事件流触发，不回写 state。

## 实现契约

- 新文件 `lib/features/battle/presentation/phase0a/phase0a_sfx.dart`：
  `String? phase0aSfxAssetForEvent(Phase0aEvent, {required String playerId})`
  纯映射，返回统一 asset 路径；无映射返回 null。
- 接线点在 `Phase0aBattleScreen._refresh()`（controller 事件消费唯一入口），
  逐事件 `SoundManager.instance.playSfxPath`，天然继承静音/音量设置与缺资产 guard。
- 测试用 recording `AudioBackend` 替换 `SoundManager.instance`，tearDown 还原。

## 验收

- 映射单测覆盖：普攻双边变体/暴击/大招/Q/R/死亡静默/波次终局静默。
- widget 测：真 fixture 驱动，普攻/J/Q/R 各触发预期资产路径恰好一次；
  终局后 step 零音效。
- `flutter analyze --no-pub` 0 issue；相关测试全绿；`dart format` 门禁净。
- 全量测试基线 5142 + 新增逐值吻合。

## 恢复点

- RP0：计划冻结。
- RP1：映射 + 接线完成，单测/widget 测绿。
- GATE：全量 + format + analyze 全绿，合入 main。
