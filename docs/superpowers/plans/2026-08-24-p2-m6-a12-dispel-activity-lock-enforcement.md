# P2-M6-A12 Dispel Activity Lock Enforcement

## 任务元数据

- taskId: `P2-M6-A12-DISPEL-ACTIVITY-LOCK-ENFORCEMENT`
- milestone: `M6`
- priority: `P2`
- source base: `8296db0c033b64faa1eb09b24f2f22269f281363`
- branch: `codex/phase2-m6-a12-dispel-activity-lock-enforcement-20260824`
- owned files:
  - `lib/features/dispel/application/dispel_service.dart`
  - `test/features/dispel/application/dispel_persist_test.dart`
  - `lib/features/technique_panel/presentation/technique_panel_screen.dart`
  - `test/features/technique_panel/presentation/technique_panel_screen_test.dart`
  - `docs/superpowers/plans/2026-08-24-p2-m6-a12-dispel-activity-lock-enforcement.md`
- forbidden files: registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md` 及白名单外全部文件

## 目标与边界

用原子 ID API `DispelService.dispelAndPersist` 取代 UI 先原地 `dispel`、再持久化 live
对象的双阶段路径。单一 Isar 权威事务内依次读取 canonical occupancy、fresh-read
Character/旧主修/候选辅修 exact tuple、执行既有纯散功、写入三个 canonical 对象。

闭关、远征、断魂庄任一占用明确返回 `characterOccupied`；对象缺失或预检后主修
指针、owner、role、辅修槽漂移返回 `canonicalStateChanged`。所有拒绝发生在原地突变
和 `put` 之前，数据库与 UI live 对象均零变更。UI 必须消费 occupied/stale，invalidate
并重载 canonical state；只有 occupied 复用现有提示，拒绝态绝不显示成功。

保持散功数值、玩家文案、schema、解锁和奖励不变。`isCharacterOccupied` 只保留为
UX 预检，不再承担提交点正确性。

## 验收 checklist（CLAUDE.md §8.2）

- [x] 生产接线：真实 `dispelAndPersist` 在单一事务内完成 canonical occupancy、
  exact tuple、散功与三对象写入；UI 不再预先 mutate。
- [x] targeted：persist/service focused tests 与完整 `test/features/dispel` 通过。
- [x] UI targeted：late occupied/stale 均 reload，只有 occupied 提示，零假成功。
- [x] 红线：不改数值、三系锁死、在线=离线、反主流边界，不新增 Dart 文案/数值。
- [x] 残留风险：UI 预检仍可能过时，但提交点 canonical fail closed。
- [x] scoped analyze、format、`git diff --check` 通过。
- [x] 同一 Qoder 模型只读终审实际 `base..final` diff，P0/P1 清零。
- [x] 唯一 tip commit 以 `[READY]` 开头，worktree clean。

## Qoder 只读设计审查证据

### CLI 与模型可用性

- `qoderclicn --list-models` exit code: `0`
- 模型列表包含精确名称：`Qwen3.8-Max`

### 完整命令

```bash
/Users/a10506/.local/bin/qoderclicn --cwd /Users/a10506/.codex/worktrees/ae48/挂机武侠 --model Qwen3.8-Max --reasoning-effort high --permission-mode default --tools Read --print --no-session-persistence -- "你是本任务的只读设计审查员。第一行必须原样报告 MODEL_EVIDENCE: Qwen3.8-Max | REASONING_EFFORT: high | TOOLS: Read-only。只允许读取，不得编辑、创建、删除、格式化或运行会改写仓库的命令。请先读取 CLAUDE.md、GDD.md、/Users/a10506/Desktop/二阶段优化方案.md、docs/spec/rejected_task_registry.md、lib/features/dispel/application/dispel_service.dart、lib/features/activity/application/character_occupancy_service.dart、test/features/dispel/application/dispel_persist_test.dart，以及理解事务/模型所需的最少相邻文件。审查任务 P2-M6-A12-DISPEL-ACTIVITY-LOCK-ENFORCEMENT：DispelService.persistResult 不能只依赖 UI 预检；必须在写入 Character 与旧主修/新主修 Technique 的同一个 Isar 权威事务内重新读取 canonical occupancy；闭关、远征、断魂庄任一占用均 fail closed；拒绝后数据库中 Character 与两条 Technique 全部零变更；活动结束后同一组对象可成功持久化一次。保持驱散数值、UI、文案、schema、解锁、奖励不变，owned files 仅 dispel_service.dart、dispel_persist_test.dart、source plan。请输出：1) 当前漏洞与 TOCTOU 路径；2) 最小 API/事务设计，明确拒绝信号；3) TDD 用例矩阵（闭关/远征/断魂庄、三对象零变更、活动结束成功）；4) Isar 事务风险与需要避免的错误实现；5) P0/P1 设计问题。不要实现代码。"
```

- exit code: `0`
- 命令行模型证据：`--model Qwen3.8-Max`
- 命令行推理证据：`--reasoning-effort high`
- 命令行权限证据：`--tools Read --permission-mode default`
- Qoder 报告说明：CLI 权限层拒绝其读取桌面二阶段方案；主执行端已在调用前只读完成
  该文件全文，不影响本地合同核验。

### 审查结论与主审 triage

Qoder 确认现有 UI 预检与 `persistResult` 之间存在真实 TOCTOU 窗口，要求占用查询
位于同一 `writeTxn` 内且早于全部 `put`；闭关、远征、断魂庄均需专项测试，拒绝态
需关闭重开 Isar 后验证三对象零变化，活动解除后再验证成功。

Qoder 另指出 UI 在事务前调用静态 `dispel` 会先污染 live 对象，且旧对象直接 `put`
可能覆盖 canonical 并发变化。主控随后将 UI 及其测试加入 owned files，因此该 P0/P1
建议已转为本任务必做：采用返回明确 occupied/stale outcome 的原子 ID API，事务内
fresh-read 并执行纯散功；UI 只消费结果，不再预先 mutate。

## 扩权后 Qoder 只读设计复核证据

### 完整命令

```bash
/Users/a10506/.local/bin/qoderclicn --cwd /Users/a10506/.codex/worktrees/ae48/挂机武侠 --model Qwen3.8-Max --reasoning-effort high --permission-mode default --tools Read --print --no-session-persistence -- "你是 P2-M6-A12-DISPEL-ACTIVITY-LOCK-ENFORCEMENT 的扩权后只读设计审查员。第一行必须原样输出 MODEL_EVIDENCE: Qwen3.8-Max | REASONING_EFFORT: high | TOOLS: Read-only。只允许使用 Read，不得编辑、创建、删除、格式化、提交或运行任何会改写仓库的命令。必须读取并审查以下扩权后完整范围：lib/features/dispel/application/dispel_service.dart、test/features/dispel/application/dispel_persist_test.dart、lib/features/technique_panel/presentation/technique_panel_screen.dart、test/features/technique_panel/presentation/technique_panel_screen_test.dart、docs/superpowers/plans/2026-08-24-p2-m6-a12-dispel-activity-lock-enforcement.md；同时读取 lib/features/activity/application/character_occupancy_service.dart 及理解 Isar 模型所需的最少相邻文件。目标约束：UI 不得在持久化前原地修改 live Character/Technique；原子 ID API 必须在同一 writeTxn 内先重新读取 canonical occupancy，闭关、远征、断魂庄对目标角色任一占用均明确 characterOccupied 且零写；然后 fresh-read canonical Character、旧主修、新辅修并校验 expected main id、owner、role exact tuple，漂移或缺失明确 canonicalStateChanged 且零写；其他角色占用不误锁；活动结束同一操作仅成功一次；UI 对 occupied/stale 均 invalidate/reload canonical state，occupied 只显示既有 dispelOccupiedSnack，任何拒绝绝不显示 success。保持数值、文案、schema、解锁、奖励不变。请按 P0/P1/P2 输出设计与当前实现审查，重点检查事务边界、对象原地变更、tuple 完整性、拒绝后数据库和 live UI 状态、测试矩阵缺口。不要实现代码。"
```

- exit code: `0`
- 命令行模型证据：`--model Qwen3.8-Max`
- 命令行推理证据：`--reasoning-effort high`
- 命令行权限证据：`--tools Read --permission-mode default`
- Qoder 自报限制：其输出说明 QoderCN 不自行声明底层模型标识；本次模型、推理和
  只读权限以 CLI 完整命令及退出码为可复核证据。
- 复核范围：扩权后的 4 个代码/测试文件、source plan、occupancy service 及最少相邻
  Isar 模型文件。

### 复核结论与 triage

- P0：`0`
- P1：`0`
- 已确认：单一 `writeTxn` 内 occupancy → fresh tuple → 纯散功 → 三 put；所有拒绝
  位于字段突变和 put 前；UI 仅传 ID、统一 invalidate，occupied/stale 均无假成功。
- 采纳直接加强验收证据的 P2：late occupied 也断言 Character/两 Technique provider
  reload；活动解除成功后同一 tuple 再提交返回 `canonicalStateChanged` 且零写；三对象
  快照补齐两条 Technique 的 owner/role/layer/progress/wasMainBeforeReset 等受影响字段。
- 其余 P2（例如预检分支、公开静态纯函数可见性）不影响本任务合同，不扩展生产范围。

## TDD 切片

1. RED：为闭关、远征、断魂庄建立真实 canonical occupancy，要求原子 API 返回
   `characterOccupied`，关闭重开后逐字段比对三对象；活动解除后成功。
2. RED：覆盖其他角色占用不误锁、主修指针/旧主修/候选三类 stale、三个 missing ID，
   全部零补写。
3. GREEN：事务内 occupancy → fresh get exact tuple → 既有纯 `dispel` → 三 put。
4. RED/GREEN UI：fake service 模拟预检后 late occupied/stale；断言 live 对象零污染、
   providers reload、occupied 复用既有提示、stale 静默 reload、两者无 success snack。

## 验证命令

```bash
flutter test --no-pub test/features/dispel/application/dispel_persist_test.dart
flutter test --no-pub test/features/dispel/application/dispel_service_test.dart
flutter test --no-pub test/features/technique_panel/presentation/technique_panel_screen_test.dart
flutter test --no-pub test/features/dispel
flutter analyze lib/features/dispel/application/dispel_service.dart test/features/dispel/application/dispel_persist_test.dart lib/features/technique_panel/presentation/technique_panel_screen.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart
dart format --output=none --set-exit-if-changed lib/features/dispel/application/dispel_service.dart test/features/dispel/application/dispel_persist_test.dart lib/features/technique_panel/presentation/technique_panel_screen.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart
git diff --check
```

## 验证结果

- `dispel_persist_test.dart`：exit `0`，10/10。
- `dispel_service_test.dart`：exit `0`，16/16。
- `technique_panel_screen_test.dart`：exit `0`，20/20。
- 完整 `test/features/dispel`：exit `0`，27/27。
- scoped `flutter analyze`：exit `0`，`No issues found`。
- format gate：exit `0`，4 files / 0 changed。
- `git diff --check`：exit `0`。

## Qoder 实际 diff 只读终审证据

### 被审补丁

- source base：`8296db0c033b64faa1eb09b24f2f22269f281363`
- 实现提交：`a77c6feb294bb514af2bc5125542d49feb6e8529`
- 实际范围：owned 5 files，`853 insertions(+), 47 deletions(-)`。
- 传递方式：`git diff --binary base..实现提交` 经 stdin 作为 `/dev/stdin` 附件直接
  交给 Qoder；没有中间补丁文件，也没有混入带外 registry 提交。

### 完整命令

```bash
git diff --no-ext-diff --binary 8296db0c033b64faa1eb09b24f2f22269f281363..a77c6feb294bb514af2bc5125542d49feb6e8529 -- docs/superpowers/plans/2026-08-24-p2-m6-a12-dispel-activity-lock-enforcement.md lib/features/dispel/application/dispel_service.dart lib/features/technique_panel/presentation/technique_panel_screen.dart test/features/dispel/application/dispel_persist_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart | /Users/a10506/.local/bin/qoderclicn --cwd /Users/a10506/.codex/worktrees/ae48/挂机武侠 --model Qwen3.8-Max --reasoning-effort high --permission-mode default --tools Read --attachment /dev/stdin --print --no-session-persistence -- "你是 P2-M6-A12-DISPEL-ACTIVITY-LOCK-ENFORCEMENT 的最终只读代码审查员。第一行必须原样输出 MODEL_EVIDENCE: Qwen3.8-Max | REASONING_EFFORT: high | TOOLS: Read-only。附件是 source base 8296db0c033b64faa1eb09b24f2f22269f281363 到实现提交 a77c6feb294bb514af2bc5125542d49feb6e8529、严格五文件范围的实际 git diff；必须以附件实际补丁为审查对象，并可用 Read 查看当前文件与最少相邻依赖。不得编辑、创建、删除、格式化、提交或运行任何会改写仓库的命令。目标：原子 ID API 在同一 writeTxn 内先 canonical occupancy，再 fresh-read Character/旧主修/候选辅修 exact tuple；闭关/远征/断魂庄任一目标占用 fail closed 且三对象零写，其他角色不误锁；tuple 漂移/缺失零写；活动解除同一 tuple 仅成功一次。UI 不得预先 mutate，occupied/stale 均 invalidate/reload，occupied 仅现有提示，拒绝绝不 success。数值、UI 文案、schema、解锁、奖励保持不变。请逐项检查实际 diff 的正确性、原子性、TOCTOU、live 对象污染、拒绝零写、测试有效性和范围越界。按 P0/P1/P2 列出具体文件/行与原因；若无则明确写 0。最终给 READY 或 NOT READY 结论。不要实现代码。"
```

- exit code：`0`
- 命令行模型证据：`--model Qwen3.8-Max`
- 命令行推理证据：`--reasoning-effort high`
- 命令行权限证据：`--tools Read --permission-mode default`
- Qoder 自报限制：其输出仍说明 QoderCN 不自行声明底层模型标识；模型与推理证据以
  完整 CLI 命令为准。
- P0：`0`
- P1：`0`
- 最终结论：`READY`。
- P2：仅可选测试证据增强（闭关字段快照、stale 关闭重开等），Qoder 明确不影响
  本合同且不阻塞 READY；生产路径未发现正确性问题。

## 红线与迁移影响

- 数值硬红线：不触及。
- 三系锁死：不触及。
- 在线=离线：强化活动期间不可换主辅修的一致性，不改收益。
- 反主流边界：不触及。
- Dart 中文/数值：不新增玩家文案或玩法数值；occupied 复用 `UiStrings` 既有文案。
- schema/saveVersion：零变化。

## 当前恢复点

- 状态：实现、扩权设计复核、本地验证和 `base..实现提交` 终审均完成，准备 READY
  tip 提交与 clean 检查。
- 最后完成：事务内 canonical guard/fresh tuple/散功/三 put；UI 去除预先 mutate 并
  消费 occupied/stale；扩权 Qoder 设计复核 P0/P1 清零；全部规定门禁通过。
- 下一步：提交本终审证据为唯一 `[READY]` tip commit，并确认分支与 worktree clean。
- 阻塞项：无。
