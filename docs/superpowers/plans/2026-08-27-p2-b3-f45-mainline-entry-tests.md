# P2 批三 B1 主线入口真实接线测试计划

## 目标与边界

- 目标：把 F4/F5 两处读取 Dart 源码并做 `contains(...)` 的假绿合同，替换为从真实 `StageListScreen` 点击进入的生产入口测试。
- 分支：`codex/p2-b3-f45-mainline-entry-tests-20260827`。
- 基线：`6d59c895dd5922adde1b64c50b3895c52d7926e9`。
- 唯一写 worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-f45-mainline`。
- 只改 `test/`、本计划与审计 `receipt.yaml`；`lib/` 零最终 diff，不改产品入口、UI 文案、数值、schema、存档语义、main，不 push/merge/revert。

## 固定验收标准（CLAUDE.md §8.2 + 冻结派单）

1. 从 `StageListScreen` 点击已通关关卡，选择可见重打及门人；以 `gameplaySettingsProvider` override 选择 bot，真实 `Phase0aMainlineBattleHost` 必须消费 `ActivityController.playerBot`、realtime 参与政策与同一门人 snapshot，真实 `Phase0aBattleScreen` roster 与 bot command builder 必须匹配。
2. 从同一生产入口选择快速重演；入口创建的真实 `MainlineHeadlessReplayUnit` 必须运行同核 headless runner，并返回当前掌门的 `expectedParticipantId`、姓名与同一 participant settlement。
3. 从 `StageListScreen` 点击首周目首次可挑战关；真实连续 run 必须把 `continueFirstClearRun` 锁定的同一 participant snapshot 传给 `Phase0aMainlineBattleHost` 与真实 battle controller roster。
4. 若完成上述任一项必须修改 `lib/` 或暴露生产私有 API，立即 `[BLOCKED]`；当前调研确认已有公开 widget/property 足够，未命中阻塞条件。
5. 提交后按固定顺序做两向破坏证红：
   - `remove_implementation`：临时把 `stage_entry_flow.dart` 的 `playerSnapshot: launch.playerSnapshot` 精确替换为 `playerSnapshot: null`；连续 run 新测试必须变红。
   - `force_degenerate_value`：临时把 `stage_list_screen.dart` 的 `visibleReplayController` 退化为恒 `ActivityController.human`；可见 bot 新测试必须变红。
   - 每向均保存完整 targeted 日志、读取 reporter 末行与 `[E]`，记录失败数，再用精确反向补丁恢复；严禁 reset/checkout/revert。
6. 恢复后依次运行两份 targeted（逐文件确认各自 `All tests passed!`）、`flutter analyze --no-pub lib test`、`dart format --output=none --set-exit-if-changed .`、带 `~/.claude/locks/wuxia_full_test.lock` 的一次 `flutter test --no-pub`、`git diff --check base..head`。
7. 审计单 `receipt.yaml` 的 `break_red` 保持空；只写一个 `audit_verification`，三条 last line 抄原文，changed_files 字节序升序去重。
8. 最终禁区与 `lib/` 零 diff、工作树 clean，tip 前缀 `[READY]`；任何破坏方向不红则真实 `[BLOCKED]`。

## test_deletions 明示例外表

以下 37 条是本任务必要删除的原始测试行。它们全部属于“读取生产源码文本并匹配符号”的错误断言；删除是为了换成真实入口驱动，不为 Gate 伪装纯追加。空白分隔行也单列，保证与 `git diff --unified=0` 的 `^-` 行逐条对应。

| # | 被删原行 | 删除原因 |
|---:|---|---|
| 1 | `test('生产入口把全局自动设置、前台 bot 与快速重演接到既有同核组件', () {` | 删除源码文本测试外壳，改为两条真实 widget/runner 入口测试。 |
| 2 | `final stageList = File(` | 删除源文件读取。 |
| 3 | `'lib/features/mainline/presentation/stage_list_screen.dart',` | 删除源文件路径。 |
| 4 | `).readAsStringSync();` | 删除同步源码读取。 |
| 5 | `final host = File(` | 删除源文件读取。 |
| 6 | `'lib/features/mainline/presentation/phase0a_mainline_battle_host.dart',` | 删除源文件路径。 |
| 7 | `).readAsStringSync();` | 删除同步源码读取。 |
| 8 | `final runner = File(` | 删除源文件读取。 |
| 9 | `'lib/features/sweep/application/phase0a_sweep_headless_runner.dart',` | 删除源文件路径。 |
| 10 | `).readAsStringSync();` | 删除同步源码读取。 |
| 11 | 空白分隔行 | 源码文本测试块删除后的结构性空行。 |
| 12 | `expect(stageList, contains('gameplaySettingsProvider.future'));` | 字符串存在不证明 provider 被生产入口消费。 |
| 13 | `expect(stageList, contains('ActivityController.playerBot'));` | 字符串存在不证明真实 host controller 为 bot。 |
| 14 | `expect(stageList, contains('MainlineHeadlessReplayUnit'));` | 字符串存在不证明点击入口创建并运行该 unit。 |
| 15 | `expect(host, contains('Phase0aPlayerBotAdapter'));` | 字符串存在不证明 bot adapter 进入真实 screen。 |
| 16 | `expect(host, contains('botCommandBuilder:'));` | 字符串存在不证明 command builder 非空。 |
| 17 | `expect(runner, contains('ActivityClock.headless'));` | 字符串存在不证明 headless 请求与 snapshot 被消费。 |
| 18 | `expect(runner, contains('MainlineParticipantSnapshotService'));` | 字符串存在不证明同一 participant settlement。 |
| 19 | `test('生产入口只对首次可挑战关启用，宿主优先消费 run 锁定快照', () {` | 删除第二个源码文本测试外壳，改为真实首次入口 widget 测试。 |
| 20 | `final stageListSource = File(` | 删除源文件读取。 |
| 21 | `'lib/features/mainline/presentation/stage_list_screen.dart',` | 删除源文件路径。 |
| 22 | `).readAsStringSync();` | 删除同步源码读取。 |
| 23 | `final flowSource = File(` | 删除源文件读取。 |
| 24 | `'lib/features/mainline/presentation/stage_entry_flow.dart',` | 删除源文件路径。 |
| 25 | `).readAsStringSync();` | 删除同步源码读取。 |
| 26 | `final hostSource = File(` | 删除源文件读取。 |
| 27 | `'lib/features/mainline/presentation/phase0a_mainline_battle_host.dart',` | 删除源文件路径。 |
| 28 | `).readAsStringSync();` | 删除同步源码读取。 |
| 29 | `expect(stageListSource, contains('continueFirstClearRun:'));` | 字符串存在不证明首次可挑战点击实际选择连续 run。 |
| 30 | `expect(stageListSource, contains('targetCycle == 1'));` | 字符串存在不证明首周目条件被真实入口消费。 |
| 31 | `expect(stageListSource, contains('StageStatus.available'));` | 字符串存在不证明 available 状态进入 host。 |
| 32 | `expect(flowSource, contains('playerSnapshot: launch.playerSnapshot'));` | 字符串存在不证明锁定 snapshot 到达真实 host。 |
| 33 | `expect(flowSource, contains('loadExactRoster([participantId])'));` | 字符串存在不证明同一 participant roster 被 controller 消费。 |
| 34 | `hostSource,` | 删除跨行源码字符串断言参数。 |
| 35 | `contains(` | 删除跨行源码字符串 matcher。 |
| 36 | `'widget.playerSnapshot ??\n'` | 字符串存在不证明 production snapshot 优先级实际执行。 |
| 37 | `'            widget.playerSnapshotForTest ??',` | 同上；真实 host property 与 roster 断言取代。 |

> 注：冻结派单预告“必要删除行”，实际 `git diff --unified=0` 得到 37 条非 header 删除记录（其中 1 条为空白），故以实测 37 条为准，不伪报 32。

## 八步收工记录

1. 实现并 commit：待填。
2. 两向破坏证红：待填原始命令、reporter 末行、`[E]` 与失败数。
3. targeted：待填，两文件逐文件运行。
4. analyze：待填。
5. format：待填。
6. 带锁全量：待填。
7. diff check：待填。
8. receipt + tip：待填。

## 当前恢复点

- 状态：WIP；真实入口测试已落地，开发期逐文件结果为连续 run `+2`、全模式 `+6`，均 `All tests passed!`，尚未 commit，尚未执行正式两向破坏证红与八步 Gate。
- 最后完成：确认无需修改生产入口；三条路径均从 `StageListScreen` 点击进入并消费真实 host/unit/snapshot。
- 下一步：复核 diff 与明示删除表，提交中文动宾实现 commit，然后按固定顺序执行两向破坏证红。
- 已跑验证：开发期 `flutter test --no-pub test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart` → `+2`；`flutter test --no-pub test/features/mainline/presentation/mainline_all_mode_consistency_test.dart` → `+6`。
- 红线影响：只改测试/计划；不触及数值、三系、在线=离线、反主流项、UI 文案、schema/saveVersion。
- 残留风险：正式 mutation、analyze、整仓 format、全量、receipt 尚未执行。
- 阻塞项：无。
