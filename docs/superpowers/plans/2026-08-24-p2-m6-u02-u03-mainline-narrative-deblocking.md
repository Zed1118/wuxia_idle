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
6. manifest provider 仍严格 fail-fast，但其 loading/error 只局部隐藏可选旧卷，不阻断关卡列表、选关或开战。
7. TextButton 保留桌面原生 focus/keyboard 行为；唯一 Semantics 节点同时带 label、button flag 与真实 tap action，语义点按/鼠标点按均只打开 reader，不冒泡到关卡行开战。
8. 1280×720 最密 Boss 三链接行与 1440×900 widget smoke 无 overflow。

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

## a1d68a4b 中间树审查与回源

- implementation commit：`a1d68a4bb39d0c096cffd9eea23f49ae28206308`（NOT READY）。
- 第一次 actual-diff CLI 尝试：`--tools ''`，退出码 0，但只输出未执行的 `Read` tool call，未形成结论。
- 第二次只开放 `Read`，退出码 0；模型披露 diff 附件被权限拒绝、改读 HEAD，因此不是绑定 actual diff 的有效终审，不作 READY 证据。其输出 P0=0/P1=0/P2=3，must-fix 仅命中 manifest EOF 空白行。
- 独立 Codex actual-diff 审查另报 3 个 P1 + 1 个 P2，已全部回源：
  - manifest loading/error 不再替换整个 `StageListScreen` body；链接局部降级，选关与开战保持。
  - Semantics 节点具有真实 tap action 且排除重复子语义；语义与鼠标均以“仅新增一条 reader route”证明不触发 battle。
  - 完整性测试非递归扫描 `data/narratives/`、`stages/`、`ascension/` 三个 `NarrativeLoader` 物理目录，校验 252 source 与 stage-pattern asset set 相等、stem/YAML id 自洽、每 ID 恰一个路径（0 orphan/0 shadow）。
  - 1280×720 显式覆盖已解锁 Boss opening/victory/defeat 三链接最密行。
  - manifest EOF 额外空白行已删除。

- 测试隔离根因：初版在同一 widget 文件内连续多次打开真实 reader，前一用例留下导航/语义异步状态，使后续交互产生顺序依赖。最终语义+键盘合并为一次受控 reader 生命周期并显式 pop/settle；鼠标不冒泡复用另一授权文件的现有真实点击用例。没有污染 asset messenger、没有新增静态 cache，也没有降低并发度。

## 最终 Qoder actual-diff 终审

- final code commit：`2272def524beb439a36a61610a8ee966df17f490`；patch range：`a6a373e137f72a69040199eb9431052f8095d1e1..2272def524beb439a36a61610a8ee966df17f490`。
- CLI/version/model/reasoning：`/Users/a10506/.local/bin/qoderclicn` / `1.1.28` / `Qwen3.8-Max` / `high`。
- 精确工具与权限参数：`--print --no-session-persistence --model Qwen3.8-Max --reasoning-effort high --permission-mode dont_ask --tools Read --allowed-tools Read --disallowed-tools Write --disallowed-tools Edit --disallowed-tools Bash --max-output-tokens 8000`。
- 附件参数：`--attachment .qoder-p2-m6-u02-u03-2272def5.diff --attachment docs/superpowers/plans/2026-08-24-p2-m6-u02-u03-mainline-narrative-deblocking.md --attachment docs/dispatch/phase0a_overhaul/task_registry.yaml --attachment CLAUDE.md --attachment GDD.md`。临时 diff 附件未提交，终审后已删除。
- 退出码：0。模型明确证明完整读取 2378 行 actual diff，首文件为 manifest，末文件为 `stage_list_screen_test.dart`，并明确绑定 `2272def5`。
- 终审结论：READY candidate；P0=0，P1=0，P2=2，must-fix=0。
- P2 triage：
  - “修改 5 个旧测试”不越界：2 个 flow 测试在原 registry owned scope，另 3 个 completeness/stage-list/cycle 测试是主控后续显式扩权；source plan 的“额外授权 3 个”口径正确。
  - YAML duplicate mapping key 是已披露、未声称覆盖的底层限制；列表级 duplicate ID、252 set equality 与三物理目录唯一性已覆盖本批合同。

## 已跑验证（post-review candidate）

各文件计数如下；最终以同一默认并发命令联合运行：

- `flutter test --no-pub test/data/mainline_narrative_manifest_test.dart`：9 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_test.dart`：9 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_branches_test.dart`：5 pass。
- `flutter test --no-pub test/features/mainline/presentation/mainline_narrative_deblocking_test.dart`：3 pass。
- `flutter test --no-pub test/features/mainline/presentation/mainline_chapter_scroll_test.dart`：5 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart`：14 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_cycle_test.dart`：6 pass。
- `flutter test --no-pub test/features/mainline/mainline_narrative_completeness_test.dart`：5 pass。
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_pure_test.dart`：20 pass。
- `flutter test --no-pub test/features/mainline/presentation/defeat_loss_banner_residue_test.dart`：3 pass。
- `flutter test --no-pub test/features/mainline/inner_demon_defeat_summary_test.dart`：7 pass。
- `flutter test --no-pub test/features/mainline/presentation/phase0a_mainline_wiring_test.dart`：17 pass。
- 上述 12 文件以默认并发的同一 `flutter test --no-pub ...` 命令连续运行两次，均为 103/103 pass；未使用 `--concurrency=1`。
- manifest 独立核验：252 entries / 252 unique IDs / 252 migrate。
- `flutter analyze --no-pub`（13 个 changed/scoped Dart items）：0 issue。

## 已知限制与红线影响

- YAML backend 对同一 mapping 内 duplicate key 的报告能力未被本任务宣称；本 loader 明确拦截 list 中重复 narrative ID，checked-in manifest 再由 252 unique 与 stage set equality 守卫。若未来要求 duplicate mapping-key 级诊断，应在共享 YAML loader 单独立项。
- 无数值、公式、三系、在线/离线、内容资产、save schema/saveVersion 变化。
- 新 Dart 中文仅进入 `UiStrings`；manifest 只存 ID/枚举/去向，不存新叙事文案。
- 未执行全量测试：本 source patch 是 mainline 表现层 + manifest 的自包含改动；按 `CLAUDE.md §8.0` 由集成批末统一跑全量。

## 当前恢复点

- 状态：READY；实现提交 `a1d68a4b`，审查修复/final code commit `2272def5`，本文档随后一条 `[READY][CODEX][P2-M6-U02-U03]` 证据提交固化。
- 最后完成：默认并发 103 targeted pass 连续两次、13-item scoped analyze 0 issue、format 0 change、base-to-code-tree diff-check 通过；Qoder final actual-diff P0=0/P1=0/must-fix=0。
- 工作区：最终证据提交后 `git status --short` 必须为空；临时 Qoder 附件已删除且不进入提交。
- 阻塞项：无。
