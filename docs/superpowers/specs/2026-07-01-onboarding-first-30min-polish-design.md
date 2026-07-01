# 新手前 30 分钟体验打磨 · 设计

> 日期：2026-07-01 · 分支：worktree-onboarding-30min-polish
> 阶段：1.0 长线打磨期 · 模型：opus xhigh
> 诊断依据：`docs/audit/onboarding_30min_audit_v2_2026-06-30.md`（S1–S5）+ 本会话 2 轮只读子代理现查核实（行号已核，非转抄旧文档）

## 目标

不加教程弹窗（守 GDD §5.7），只优化「解锁顺序 / 默认目标 / 初期掉落 / 首失败点 / 首成长反馈」的可读性。全部改动为**纯展示层 / 文案 / 显示条件**：零碰 numbers.yaml / 结算 / saveVer / schema / 三系锁死 / 在线=离线 / §5.1 反主流不做项。新增中文一律进 `lib/shared/strings.dart`（`UiStrings`）。两套色板按各处现状不混（深底 `WuxiaColors.text*` / 浅纸底 `WuxiaUi.ink/muted`）。

## 5 个切片

### S1 · 祖师塑形确认区补决策可逆说明
- **现状**：`founder_creation_screen.dart:427` 确认区仅显 `founderCreateConfirmLine`（`strings.dart:1901`，"流派 · 出身 · 命盘"三连），确认前无决策边界说明，新玩家易纠结。
- **改动**：不改现有三连串。在其下（Column 内 `SizedBox(height:8)` 后）加一个新 `Text`，用新增 `UiStrings.founderCreateReversibleHint`，意「起手选择只影响前几关手感，日后可用装备、修炼补足，不必纠结」。
- **色板**：该确认区在深底 UI（现行用 `WuxiaColors.resultHighlight`），新提示行用深底次要色（`WuxiaColors.textSecondary` 一类，实装现查该文件既有次要色 token）。
- **红线**：纯文案，零逻辑/数值。

### S3 · 普通关失败弹框补非教学化短诊断
- **现状**：`stage_entry_flow.dart:427` `_showStageRetryDialog`（普通关专用；Boss 失败走 defeat narrative + 损失结算，不经此路径）。body 固定 `stageRetryPrompt`（"这一战未能取胜。要再试一次吗？"），失败后不给新玩家任何补强方向。
- **改动**：body 在现有 prompt 下追加一句 hint（新增 `UiStrings.stageRetryHintLine`），意「可回行囊换装备，或先去别处历练再来」。统一加，不按首胜/非首胜细分。是失败反馈的一句自然提示，非弹出式教程。
- **色板**：`PaperDialog` 浅纸底，hint 用 `WuxiaUi.muted`。
- **红线**：纯文案 + body 组装，零结算改动。

### S5 · 掉落结算材料行显具体道具名 —— ❌ 前提证伪，本轮不做
- **审计原说法**：`stage_victory_dialog.dart:385` 只显品类名"材料 xN"，应改具体道具名。
- **证伪（现读代码）**：`ItemType.fromDefId`（`enums.dart:347`）把所有已知材料映射到具名枚举——`item_mojianshi`→`ItemType.moJianShi`，`EnumL10n.itemType`（`enum_localizations.dart:201`）返回"磨剑石"；心血结晶/经验丹/秘籍/银两同理各有具名。仅未知 defId 兜底 `miscMaterial`→"杂项材料"（也非裸"材料"）。**新手期每个材料掉落本就显具名**。
- **铁证**：`stage_victory_dialog_test.dart:199` 已断言 `find.textContaining('磨剑石 ×2')` findsOneWidget 且 `item_mojianshi` 裸串 findsNothing，基线全绿。
- **结论**：审计 S5 说法错误。改用 `itemDefs[defId].name` 仅对 miscMaterial 项有边际差异（新手期无此路径），且给当前纯 widget 引入 `GameRepository` 耦合，弊大于利。**本轮不做**。

### S2 · 首胜装备掉落后整备轻提示
- **现状**：`stage_victory_dialog.dart:242` 装备段展示掉落装备，但掉落后无任何"去整备"衔接。
- **改动**：装备段末尾，当 `drops.equipments` 非空时加一行轻提示（新增 `UiStrings.stageVictoryEquipmentHint`），措辞「可回行囊查看 / 整备新装备」——含"查看"，避免对超阶不可装备品的"穿戴"误导。**简化取舍**（用户拍板）：不引入 canEquip 判定，掉装备即显。
- **约束**：一次性即时提示，无按钮、无路由跳转、不做推送/留存焦虑（守 §5.1）。
- **色板**：浅纸底 `WuxiaUi.muted`。
- **红线**：纯展示层，零路由/状态流改动。

### S4 · 选关页对新档隐藏 replay reward 提示行（门槛 = 通关 stage_01_05）
- **前提证伪（写 plan 前现读代码核实）**：审计称"扫荡/周目/刷点三工具对新档过早出现"，实际核查 `stage_list_screen.dart`：
  - **扫荡 Sweep + 周目选择 `CycleSelectControl`**：都在 `_StageActionBand`（line 224 `showSweep = eligible || everCleared`）内，章级门控——`everCleared`/`eligible` 对第一章均要求整章通关（含 stage_01_05），**新档 mid-ch1 本就隐藏，不过早**。**无需改动**。
  - **刷点推荐 `_ReplayRewardRouteLine`**（line 991 `if (cleared)`）：`cleared`=**单关**状态（line 843 `status == StageStatus.cleared`），故**每通一关即在该关行显 replay 提示**——从刚通的 stage_01_01 起就出现，这才是真"过早"。
- **改动（仅此一处）**：line 991 门控 `if (cleared)` → `if (cleared && replayRewardUnlocked)`，`replayRewardUnlocked = progress.clearedStageIds.contains('stage_01_05')`。bool 照 `goalGuidance` 同链透传：`_ChapterStageTimeline`(390) → `_TimelineStageStop`(488) → `_StageRow`(817)。通关第一章末 Boss 后所有 replay 行自然展现。
- **去魔法串**：抽共享常量承载 `'stage_01_05'` 新手门槛（实装现查 `main_menu.dart:125` `_socialUnlockStage` 能否提取共享；否则新建常量）。
- **红线**：纯显示条件门控，零结算/解锁数值改动；replay 功能本身不动，仅隐藏其提示行至门槛达成。

## 验收标准

- `flutter analyze lib/ test/` **0**。
- 全量 `flutter test --no-pub -j1` 全绿（基线 3525 passed/1 skip/0 fail，新增 widget/单测后净增）。
- 每切片配 targeted 测：
  - S1：确认区渲染含新提示串。
  - S3：普通关失败弹框 body 含 hint 串。
  - ~~S5~~：证伪已删，无 targeted 测。
  - S2：`drops.equipments` 非空时提示串出现、空时不出现。
  - S4：已通某关但未通 `stage_01_05` 时该关行 replay 提示不渲染、通关 `stage_01_05` 后渲染（复用现有 progress fixture）。
- UI 改动跑 1280×720 / 1440×900 常规视口 smoke（禁只超高视口）。
- 红线守门：无中文散写进 Dart（全进 `UiStrings`）；`stage_victory_dialog` / `PaperDialog` 浅纸底色板、`founder_creation_screen` 深底色板不混。

## 非目标（YAGNI / 本轮不做）

- 不加教程弹窗、任务系统、每日任务、登录奖励等（§5.1 / §5.7 永久红线）。
- S2 不做 canEquip 精判、不做"去行囊"跳转按钮、不做主菜单临时状态条（用户已否决交互重方案）。
- 不动前 5 关难度数值 / 掉落率 / 经济曲线（爬塔 3 观察点等数值项属另一轴，需用户单独拍板）。
- 不重排主菜单信息密度（"当前要事"面板已缓解，审计 P3-1 判无需升级）。
