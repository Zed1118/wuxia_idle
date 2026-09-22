# 派单 G：断魂庄冷却检查点与在庄禁装卸恢复点

- 状态：`BLOCKED`，在落 patch 前命中派单 §3 的白名单出口；不是已实现候选，不可合并。
- 日期：2026-09-22。
- 目标：按已批准合同实现 S1 按秒跨关恢复、S2 在庄禁止手动装卸，并将当前存档版本升至 `0.51.0`。
- 工作目录：`/Users/a10506/Codex/2026-09-22/gauntlet-cooldown-checkpoint/wt`。
- 分支：`codex/gauntlet-cooldown-checkpoint-20260922`。
- 派单基线：`5e032cb8a8de76069ea382f615e92aa70a2fec9d`；开局 HEAD 相同，工作区干净。
- 输入：`../input/m4.patch`，SHA-256 为 `2dce6a195d7ff0a7a4425527a14ac8bc275e0548ed371736da72b7a809565b87`；另有 `../input/untracked/` 四个文件。
- 合同：`docs/spec/2026-09-22-gauntlet-cooldown-checkpoint-design.md`，状态 `APPROVED`。不重议 S1/S2。

## 当前恢复点与硬阻塞

最后完成：只读核对分支、基线、输入摘要、规则、合同、生产调用路径、patch 和当前版本断言。尚未 apply patch、复制输入、修改生产代码或生成 Isar 文件。

以下两文件不在派单的精确白名单，却有必须随当前版本升级同步替换的四处断言：

| 基线位置 | 核实内容 | 需要的最小修改 |
| --- | --- | --- |
| `test/data/isar_missing_field_migration_test.dart:63` | 调用 `IsarSetup.init` 后断言 `currentSaveData().saveVersion` | 当前版本字面量 `0.50.0` → `0.51.0` |
| `test/data/reward_claim_receipt_migration_test.dart:131` | 迁移完成后读取实际存档版本 | 同上 |
| `test/data/reward_claim_receipt_migration_test.dart:185` | 各历史塔夹具迁移完成后读取实际存档版本 | 同上；不改夹具起始版本 |
| `test/data/reward_claim_receipt_migration_test.dart:257` | 修复旧塔墓碑迁移完成后读取实际存档版本 | 同上 |

证据链：`lib/data/isar_setup.dart:708-709` 在迁移末尾统一把 `_currentSaveVersion` 写入存档；上述四处断言期待迁移后的当前版本，不是历史夹具或中间版本。将常量升为 `0.51.0` 后，保留这些 `0.50.0` 断言无法满足全量全绿。本结论为源码核对，未伪称已实跑失败。四处均保持原样。

因此按用户派单 §0/§3“若确需改白名单外文件，停下打 `[BLOCKED]`”停止。恢复前需要将这两个路径加入白名单，权限仅限四处当前版本字面量替换。

另一处需澄清的实际冲突：派单和合同写“排除”旧 schema 夹具代码生成，但 `build.yaml:10-19` 实际为 `generate_for.include`；输入 patch 把 `legacy_gauntlet_cooldown.dart` 加入该 include 列表。新夹具第 3 行引用 `legacy_gauntlet_cooldown.g.dart`，输入未提供生成物，严格排除会缺少生成代码。已发出澄清问题，尚无答复；未擅自变更口径。

## 静态复核发现与续作要求

1. 输入为 20 个跟踪文件 diff；剔除 `lib/shared/strings.dart` 与 `test/tools/compare_phase0a_headless_baseline_test.dart` 后实际为 18 个跟踪文件，加 4 个新文件共 22 个，不是派单写的 19 + 4。精确白名单优先。
2. 四个新文件实际是三个 `*_test.dart` 加一个旧 schema 夹具；夹具由兼容测试导入，不是第四个独立测试入口。
3. patch 的 `gauntlet_live_headless_parity_test.dart` 包含 74 个删除行，违反本单既有测试零删除要求。续作应保留原循环与原测试行，用新增断言、辅助方法或独立恢复场景补齐逐槽 parity。
4. patch 的 S2 仅在操作被拒后增加提示，未实现 UI 灰显。需在两个白名单界面消费既有活动庄局状态、按实际成员匹配，补灰显及预置 `UiStrings.gauntletSkillLoadoutOccupied`。`activeGauntletProvider` 位于 `gauntlet_providers.dart:36-43`。
5. patch 与新文件含新增英文注释，需转为简体中文。保留旧测试既有行，避免为翻译制造禁止的删除。
6. `applyAutoFill` 是既有自动补槽且首关装配也依赖，不能直接全局按在庄状态拒绝；本单手动装卸继续由服务写事务内守卫。

## 生产接线证据（基线静态定位，尚未落实现）

- live：`lib/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart:54` 准备参战快照，`:57` 映射运行态，`:104` 返回阶段结果；`lib/features/boss_gauntlet/presentation/gauntlet_entry_flow.dart:76` 传递共享结算，`:78` 调服务推进。
- headless：`lib/features/boss_gauntlet/application/gauntlet_service.dart:593` 准备快照、`:598` 调 runner、`:608` 传递阶段结算，`:675` 经 controller 推进；live 服务推进位置为同文件 `:864`。
- patch 计划让两路共用 `lib/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart:47` 的结果检查点 getter，再经 `GauntletController` 关末写入。恢复共用 `gauntlet_service.dart:818` 的快照装配与 mapper 的玩家槽位映射。以上是输入审阅，不是已落地验证。
- 手动装卸真实入口：`lib/features/cangjingge/presentation/cangjingge_screen.dart:420`、`:498`、`:757`；`lib/features/character_panel/presentation/encounter_skill_section.dart:147`、`:168`。patch 在服务写事务内读取统一 `CharacterOccupancyService`，庄局占用来源为 `lib/features/activity/application/character_occupancy_service.dart:48-54`。
- 当前需补灰显的入口：`cangjingge_screen.dart:349`、`:619`、`:683`，以及 `encounter_skill_section.dart:90-98`。

## 验收标准与任务切片

1. 解除白名单及夹具生成口径阻塞后，先只落测试部分（剔除指定无关 hunk）与四个新文件，满足生成前置后逐文件取得三组 RED 原文；禁止 stash。
2. 落生产实现并重生成 Isar；逐条落实 S1/S2、非法槽值拒绝、旧档不回填和同路 parity。补 UI 灰显、保留旧测试全部行、中文化新增注释。
3. 仅升 `saveVersion` 和增加纯加法迁移段；对所有允许变更的当前版本断言逐处记最终 `file:line` 与理由，保留历史版本。
4. 按派单和合同逐文件定向验证，再做 analyze 0 issue、整仓 format 0 changed、一次前台全量。记录 reporter 原文与 `[E]` 块数，未跑不得记 0。
5. 创建真正实质实现 commit S；按三方向证红、精确还原并逐组重跑绿。最后创建仅收据与恢复点的包装 R，验证 `R^ == S`、白名单、测试删除行、无生成物入库和工作区干净。

## 当前验证与变更清单

- 已完成：Git 基线/状态核对，输入 SHA-256 核对，只读差异和版本断言上下文核对；两路独立静态审阅已收口。
- CodeGraph：当前 worktree 未初始化；未创建索引，使用原生读取。
- RED 失败计数及原文：未运行，空值；不是“RED 已证实”。
- 3-way 冲突与解法：未 apply，因此未发生冲突；没有手工解决记录。
- saveVersion 断言实际改动清单：空；白名单内外测试均未修改。上表是恢复所需权限，不是已完成改动。
- 定向、build_runner、analyze、format、全量、三向破坏证红：均未运行，因派单规定提前停止。
- 本次提交仅保存白名单内恢复点和阻塞收据；不构成代码或 schema 交付。

## 红线影响与残留风险

当前零生产变更，不影响数值硬红线、三系锁死、在线=离线、反主流约束及文案/数值归集。续作按合同 §5：秒数来自 reducer，保留 `turns × 0.55s` 既有物化口径，不改 YAML、奖励、门票、周目或解锁；旧档只读缺字段默认值，不推断历史冷却。GDD 修改被本派单精确白名单禁止，留协调者处理。

S1/S2 未实现、未自动验证；旧 schema 生成口径待明确，UI 和测试删除问题待处理。合同 §6 的“真机一次”未做，未启动游戏 GUI；没有真人验收、协调者 Gate、集成或发布证据。未触碰真实存档、其他 worktree、`main`、原 m4 目录及 `~/Documents/Codex/**`；未安装软件、push、merge、rebase、revert、amend 或 stash。
