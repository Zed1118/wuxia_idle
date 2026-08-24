# P2 M6 U02/U03：主线叙事去阻塞与章节卷轴搬迁

## 基线与边界

- semantic base：`693ed157071e8242dc44ef81b9bae7d289809e58`（产品冻结方案来源）。
- patch base：`a6a373e137f72a69040199eb9431052f8095d1e1`（本 source patch 精确 diff 基线）。
- branch：`codex/phase2-m6-u02-u03-mainline-narrative-deblocking-20260824`。
- 不修改 main；不修改 registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`data/stages.yaml`、`data/narratives/chapters/**`、boss gauntlet 或 save schema。
- 额外授权范围：同步新冻结合同所取代的 3 个既有测试，以及仅同步 `stage_victory_dialog.dart` 过时注释；不改变其行为。

## 冻结产品合同

- 全部 105 个 `StageType.mainline` 关卡（含所有章中 Boss 与章末 Boss）不自动 push opening、victory、defeat `NarrativeReaderScreen`。
- `innerDemon`、`lightFoot`、`massBattle` 等特殊模式保留原三类 narrative flow。
- Boss 失败惩罚仍先原子结算；主线用独立事实弹层展示实际 `DefeatLossEntry`，不承载叙事、不做失败建议或配装建议。
- 保留全部旧叙事资产。manifest 精确覆盖 105 opening + 105 victory + 42 defeat = 252 个唯一 ID，本批 252 条全部 `migrate`。
- 可选阅读只复用现有 `_ChapterStageTimeline`，不增加一级入口，不增加已读/失败证据字段，不做 save migration。
- opening 以 `stageAvailable` 解锁；victory 以周目无关 `clearedStageIds` 解锁；defeat 因缺少持久失败证据，保守使用同一 `stageCleared` 证据。

## 实现切片

1. 新增 `data/narratives/mainline_narrative_manifest.yaml` 与严格 application loader。
2. loader 校验 schema version、root/entry unknown keys、必填字段类型与空白、枚举、重复 narrative ID、目标/trigger 与现有主线 stage 精确相等；生产 validation 拒绝任何非 `migrate` disposition。
3. `runStageFlow` 以唯一 `StageType.mainline` 判据关闭三类自动 reader；特殊模式不变。
4. 主线 Boss defeat 固定顺序：惩罚结算 → provider invalidate → 事实弹层 → 原收降 hook；无损失 entry 不弹。
5. `_ChapterStageTimeline` 用 manifest 决定可读项；opening 读当前可用状态，victory/defeat 只读 `clearedStageIds`，不受二周目视图重锁。
6. TextButton 保留桌面原生 focus/keyboard 行为，并添加精确 Semantics label；1280×720 与 1440×900 widget smoke 无 overflow。

## Qoder CLI 只读设计审查

- CLI：`/Users/a10506/.local/bin/qoderclicn`
- version：`1.1.28`
- model：`Qwen3.8-Max`（`--list-models` 精确列名）
- reasoning：`--reasoning-effort high`
- permissions：`--permission-mode dont_ask --tools ''`（零内置工具，仅附件）
- 首次参数探测：11 个附件超过 CLI 上限 5，退出码 1；未进入模型、未产生审查结论、未写文件。
- 有效设计审查：5 个关键附件 + 内嵌冻结合同，退出码 0。
- 原始分级：P0=2、P1=5、P2=4。
- triage：
  - P0 旧测试不在 owned scope：主控随后显式扩权，已解除。
  - P0 manifest asset：`pubspec.yaml` 已声明 `data/narratives/` 根，且 rootBundle 测试通过，无需越界改 pubspec。
  - P1 cycle 解锁漂移：已采用周目无关 `clearedStageIds`。
  - P1 UI/manifest 双真相：控件只消费已 validation 的 manifest `migrate` entry。
  - P1 defeat 时序：已固定为结算、invalidate、事实弹层、hook，并有 widget 回归。
  - P1 特殊模式：已枚举真实 `runStageFlow` 调用面并覆盖三类特殊模式。
  - P1 parser：已补严格 schema/重复 ID/孤儿与目标漂移测试。
  - P2 基线：本恢复点明确区分 semantic base 与 patch base。

## 已跑验证（implementation candidate）

以下命令均逐文件独立运行并出现 `All tests passed`：

- `flutter test --no-pub test/data/mainline_narrative_manifest_test.dart`：9 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_test.dart`：9 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_branches_test.dart`：5 pass。
- `flutter test --no-pub test/features/mainline/presentation/mainline_narrative_deblocking_test.dart`：3 pass。
- `flutter test --no-pub test/features/mainline/presentation/mainline_chapter_scroll_test.dart`：4 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart`：14 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_cycle_test.dart`：6 pass。
- `flutter test --no-pub test/features/mainline/mainline_narrative_completeness_test.dart`：4 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_pure_test.dart`：20 pass。
- `flutter test --no-pub test/features/mainline/presentation/defeat_loss_banner_residue_test.dart`：3 pass。
- `flutter test --no-pub test/features/mainline/inner_demon_defeat_summary_test.dart`：7 pass。
- `flutter test --no-pub test/features/mainline/presentation/phase0a_mainline_wiring_test.dart`：17 pass。
- targeted total：101 pass。
- manifest 独立核验：252 entries / 252 unique IDs / 252 migrate。
- `flutter analyze --no-pub`（13 个 changed/scoped Dart items）：0 issue。

## 已知限制与红线影响

- YAML backend 对同一 mapping 内 duplicate key 的报告能力未被本任务宣称；本 loader 明确拦截 list 中重复 narrative ID，checked-in manifest 再由 252 unique 与 stage set equality 守卫。若未来要求 duplicate mapping-key 级诊断，应在共享 YAML loader 单独立项。
- 无数值、公式、三系、在线/离线、内容资产、save schema/saveVersion 变化。
- 新 Dart 中文仅进入 `UiStrings`；manifest 只存 ID/枚举/去向，不存新叙事文案。
- 未执行全量测试：本 source patch 是 mainline 表现层 + manifest 的自包含改动；按 `CLAUDE.md §8.0` 由集成批末统一跑全量。

## 当前恢复点

- 状态：implementation candidate 已完成，等待主 agent diff 审查、implementation commit 与 Qoder actual-diff 终审。
- 最后完成：101 targeted pass、13-item scoped analyze 0 issue。
- 下一步：format check → diff check → commit implementation → Qoder `Qwen3.8-Max/high` 只读终审该 commit → 写回终审分级 → READY commit。
- 阻塞项：无。
