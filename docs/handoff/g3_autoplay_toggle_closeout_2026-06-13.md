# 半手动战斗 P0 步骤5-G3:选关屏 per-stage 自动/手动开关 UI · closeout

日期: 2026-06-13(用户外出 2h 自主推进波)
分支: `worktree-g3-autoplay-toggle-ui`(**未合 main** — UI 改合 main 前须过 Codex 视觉 + 用户确认)
基线: main `02c4ece7`,全量 2054 测 → 本波 **2066 测**(+12)/ analyze 0

## 背景

步骤5 数据层(`autoPlayOverride` bool? 每关记忆 + `resolveAutoPlayMode` 4 态真相表
+ `setAutoPlayOverride` service)上波已全建全测,仅差 UI 暴露。本波纯 UI 层,
0 改 numbers.yaml / schema / 战斗内核 / 红线。

## 自主拍板的交互方案(用户可改)

- **三态 toggle**:`null` 跟随全局(显示生效模式 +「随设置」弱标记)/ `true` 自动 / `false` 手动。
- **PopupMenu 三选项**(跟随设置 / 自动战斗 / 手动战斗):省 tile 空间、三态清晰、可测;
  内部用 `_AutoPlayChoice` 枚举作 value 规避 PopupMenuButton 对 `null` value 丢回调的哨兵问题。
- **仅已通关关显示**;迁移豁免关(已通关无 record,autoFallback)→ 灰显锁定 + tooltip「重打一次记录后可切换」。

## 实装(5 文件新增 + 8 文件改)

- 新 `lib/shared/widgets/auto_play_toggle.dart` — 纯展示三态 toggle(6 widget 测)。
- 新 `lib/features/battle/application/.../stageAutoPlayStateProvider` family — by battleKey 读 override+hasRecord(3 测)。
- 新 `lib/features/battle/presentation/stage_auto_play_control.dart` — ConsumerWidget,5 屏复用单元:watch provider+全局设置→toggle,onChanged 落 `setAutoPlayOverride`+invalidate(3 测)。
- **5 屏接线**:
  - mainline `stage_list_screen` `_StageRow`、心魔 `_InnerDemonRow`、轻功 `_LightFootRow`、群战 `_MassBattleRow`:cleared tile 副标题下挂 inline toggle(battleKey=`stageBattleKey(def.id)`)。
  - 爬塔 `tower_floor_card`:塔身 plaque 固定高(76/86 + timeline 82/92),内联会溢出 → toggle 放进**已通关层重打确认 dialog**(契合 tower 既有 dialog 门,零布局风险;battleKey=`towerBattleKey(floorIndex)`)。
- 群战注:autoReplay 降级 autoFallback(formation 未入 seed+ops),toggle 仍控自动/手动意图,首通有 record → enabled。
- 文案 8 key 入 `UiStrings`。
- 验收 route `stageListAutoPlay`(`VISUAL_ROUTE=stage_list_autoplay`):seed 01_01..04 通关 + 01_01 录记录(跟随=自动随设置)+ 01_02 pin 手动。

## 测试边界(诚实标注)

- 写路径(选项→setAutoPlayOverride **writeTxn**)在 testWidgets pump 周期内会 Isar 死锁
  (memory `feedback_isar_widget_test_deadlock`)→ 写路径由 provider plain `test()` 覆盖;
  control 测试用 **provider override** 喂态只验读路径。
- `_StageRow` 的 `if(cleared)` gate 需 Isar 写种子(同死锁)→ 改由 **Codex 视觉验收**覆盖(本波加了专属 route)。

## 闸门

- `flutter analyze`:**No issues found**(穷尽 switch 已纳新 route)。
- 全量 `flutter test`:**2066 passed / 1 skip / EXIT 0**(基线 2054 + 12 新)。

## 待办(留用户回来)

1. **Codex 视觉验收**:`docs/_archive/codex_dispatch/codex_dispatch_g3_autoplay_toggle_2026-06-13.md`(route `stage_list_autoplay` + `tower_floor_list`)。
2. 真玩:全局开关改了之后,跟随态(override=null)关卡是否随之联动(数据层逻辑已对,验体感)。
3. Codex PASS + 用户确认后 `git merge --ff-only` 合 main。
