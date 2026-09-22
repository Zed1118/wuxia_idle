# 派单 G：断魂庄冷却检查点与在庄禁装卸恢复点

- 状态：`READY`；实质生产实现及完整自动验证通过，待 commit 后三向证红与包装。
- 日期：2026-09-22。目标：落实已批准 S1 秒制跨关冷却、S2 在庄禁手动装卸，存档升至 `0.51.0`。
- worktree：`/Users/a10506/Codex/2026-09-22/gauntlet-cooldown-checkpoint/wt`。
- 分支：`codex/gauntlet-cooldown-checkpoint-20260922`。
- `base_sha`：`5e032cb8a8de76069ea382f615e92aa70a2fec9d`；续作开局 tip `000672178`，工作区干净。
- 前次阻塞记录 S：`992da9bf147ae01508539ea71a47123af964940c`，仅恢复点；旧包装 R：`000672178`。两提交保留，不改写历史。
- 输入：`../input/m4.patch`，SHA-256 `2dce6a195d7ff0a7a4425527a14ac8bc275e0548ed371736da72b7a809565b87`；`../input/untracked/` 四文件。
- 合同：`docs/spec/2026-09-22-gauntlet-cooldown-checkpoint-design.md`（`APPROVED`）。原包与 G-续包从协调者 `dispatch-20260917` worktree 只读取得；以 G-续的完整白名单与订正为准。

## 当前恢复点

- 已完成：测试先行 RED、生产 patch、纯加法 schema 与版本戳、版本断言订正、parity 零删除补强、S2 两界面按成员灰显、中文化新增注释、逐文件定向、analyze/format。
- 当前恢复步骤：创建实质 S′，再三向证红并逐组精确还原重跑，最后仅收据与本恢复点包装 R′（`R′^ == S′`）。
- 当前无范围阻塞；不得将当前状态冒充协调者 Gate 或真人验收。

## 前次阻塞解除与静态复核原文

G-续已明确授权 `isar_missing_field_migration_test.dart:63` 与 `reward_claim_receipt_migration_test.dart:131/185/257` 的四处当前版本字面量替换。`build.yaml` 实际为 `generate_for.include`，夹具已加入生成列表，`.g.dart` 由生成器产出且保持 ignored。输入实际为 18 个获准跟踪文件 + 4 个新文件；四个新文件是三入口测试 + 一旧 schema 夹具，不把夹具冒充第四个独立测试入口。

以下保留前次静态复核段作证据，所列问题本轮均已处理：


1. 输入为 20 个跟踪文件 diff；剔除 `lib/shared/strings.dart` 与 `test/tools/compare_phase0a_headless_baseline_test.dart` 后实际为 18 个跟踪文件，加 4 个新文件共 22 个，不是派单写的 19 + 4。精确白名单优先。
2. 四个新文件实际是三个 `*_test.dart` 加一个旧 schema 夹具；夹具由兼容测试导入，不是第四个独立测试入口。
3. patch 的 `gauntlet_live_headless_parity_test.dart` 包含 74 个删除行，违反本单既有测试零删除要求。续作应保留原循环与原测试行，用新增断言、辅助方法或独立恢复场景补齐逐槽 parity。
4. patch 的 S2 仅在操作被拒后增加提示，未实现 UI 灰显。需在两个白名单界面消费既有活动庄局状态、按实际成员匹配，补灰显及预置 `UiStrings.gauntletSkillLoadoutOccupied`。`activeGauntletProvider` 位于 `gauntlet_providers.dart:36-43`。
5. patch 与新文件含新增英文注释，需转为简体中文。保留旧测试既有行，避免为翻译制造禁止的删除。
6. `applyAutoFill` 是既有自动补槽且首关装配也依赖，不能直接全局按在庄状态拒绝；本单手动装卸继续由服务写事务内守卫。


## 实现与生产接线

- schema：`activity_member_snapshot.dart:41-43` 三新增字段默认 false/空；`:47` 校验标记、列表长度、键唯一与正有限秒数。保留旧回合字段，不换算、不回填。
- 两路共享：live `phase0a_gauntlet_battle_host.dart:104` 与 headless `phase0a_gauntlet_stage_runner.dart:114` 产同一结果；后者 `:47-60` 从真实终态提取槽冷却。`gauntlet_service.dart:675/867` 在既有写事务内调用 controller，`:824-830` 将检查点送入 CombatantSnapshot；`:1524-1526` 的成员复制保留新增字段。
- 落库与恢复：`gauntlet_controller.dart:76-79` 写关末秒制检查点；`combatant_snapshot.dart:103` 保留 `openingSlotCooldownSeconds`；`phase0a_stage_content_mapper.dart:158/:1170` 按运行槽恢复并拒未知槽、负数与非有限值。
- S2 服务：`skill_loadout_service.dart:74/:159`、`encounter_service.dart:510/:547` 在同一写事务内读取统一占用，按真实角色及 bossGauntlet 类型拒手动装卸。`applyAutoFill` 原样保留，首关装配仍可用。
- S2 UI：`cangjingge_screen.dart:231-238`、`encounter_skill_section.dart:76-83` 消费既有 activeGauntletProvider，以 members.characterId 匹配当前角色；loading/error 显式禁用。藏经阁槽 `:385`、两类武学行 `:680/:746`，奇遇装卸 `:108/:116` 将回调置 null；提示用预置 UiStrings。现有控件 API 为 onTap（InkWell/PlaqueButton），没有 onPressed；通过回调 null、disabled、焦点与语义实现合同要求。
- parity：保留原两个测试、原循环与所有断言，追加两周目新局与持久化恢复三例；`+121/-0`，逐槽核对开场与关末检查点，同时比较真实终态/事件/HP/真气。
- 数值/红线：秒数来自 reducer；`turns × 0.55s` 物化口径不变，不改 YAML、门票、奖励、周目、解锁、三系锁死、反主流边界。live/headless 共用检查点。

## RED 与输入应用

先 `git apply --3way` 仅取测试和 build.yaml，再复制四新文件，运行 `dart run build_runner build --delete-conflicting-outputs`，才逐文件跑三入口 RED；lib 当时保持基线。三份生成前置完成，失败原因都是本单新增 API 尚不存在，非缺 `.g.dart`。

| 入口 | RED reporter 原文 | 退出码 / [E] 块 |
| --- | --- | --- |
| `phase0a_gauntlet_cooldown_checkpoint_test.dart` | `00:00 +0 -1: Some tests failed.` | 1 / 1 |
| `gauntlet_skill_loadout_occupancy_test.dart` | `00:00 +0 -1: Some tests failed.` | 1 / 1 |
| `gauntlet_cooldown_compatibility_test.dart` | `00:00 +0 -1: Some tests failed.` | 1 / 1 |

原文：`../logs/red_*.log`；汇总 `../logs/initial_red.json`。之后只 apply 获准 lib hunk 并重新生成；两轮生成日志为 `../logs/build_red.log`、`../logs/build_green.log`。

无 3-way 冲突。第一次测试 apply 参数把 include 放在 exclude 前，发现 Git 按首个匹配生效后，立即从 HEAD 精确还原 parity 与 compare 文件及 index，再开始 RED。最终 lib 应用采用 exclude 优先；无关 `strings.dart`、compare 文件均零 diff，parity 用追加测试取代原 patch 的删除段。未用 stash 或破坏式恢复命令。

## saveVersion 断言改动清单

`lib/data/isar_setup.dart:252-253` 加 0.51.0 注释并升常量，`:709-711` 新增段 21 注释并沿用统一版本戳；无数据回填。下列 20 处只把 `'0.50.0'` 换成 `'0.51.0'`，夹具起始版本及历史中间版本不动：

| 文件:行 | 理由 |
| --- | --- |
| `test/data/expedition_milestone_record_migration_test.dart:33` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/expedition_milestone_record_migration_test.dart:51` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/gauntlet_run_serial_migration_test.dart:65` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/isar_missing_field_migration_test.dart:63` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/isar_slot_open_error_test.dart:52` | 受支持的当前版本字面量 |
| `test/data/mainline_settlement_journal_migration_test.dart:41` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/player_yield_migration_test.dart:271` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/player_yield_migration_test.dart:391` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/player_yield_migration_test.dart:441` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/progressive_unlock_migration_test.dart:41` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/reward_claim_receipt_migration_test.dart:131` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/reward_claim_receipt_migration_test.dart:185` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/reward_claim_receipt_migration_test.dart:257` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/save_migration_version_gate_test.dart:253` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/sect_member_count_repair_test.dart:175` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/sect_member_count_repair_test.dart:410` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/sect_member_count_repair_test.dart:423` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/tower_personal_record_migration_test.dart:40` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/data/tower_personal_record_migration_test.dart:78` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |
| `test/features/tower/presentation/tower_historical_tombstone_settlement_test.dart:281` | 迁移完成后的当前版本或当前版本 getter 断言；历史起始版本不动 |

白名单外追加：无。`git grep -n "'0.50.0'" test lib` 仅剩 isar_setup 旧 0.50.0 迁移段比较条件。

## 自动验证

- 每个文件单独 `flutter test --no-pub <file>`：61 文件、512 用例全绿。含断魂庄目录（除另跑的占用测试）、activity、battle_shared 全目录，所有 12 个版本文件，mapper、兼容测试、truth guard、pubspec assets、原 compare 测试。每文件命令、末行、退出码与耗时见 `../logs/targeted_results.json`；路径清单 `../logs/targeted_files.json`。
- 占用文件另跑：`flutter test --no-pub test/features/boss_gauntlet/gauntlet_skill_loadout_occupancy_test.dart` → `00:09 +28: All tests passed!`。20 服务用例 + 8 widget 场景；日志 `../logs/ui-occupancy-targeted.log`。合计 62 入口文件、540 用例。
- UI widget：两个界面各 1280×720 / 1440×900 在庄灰显+文案/非成员可用，以及初始 loading/error fail closed；检查槽回调/focus、按钮 disabled/语义，布局无异常。刷新保留旧数据由显式 isLoading/hasError 静态复核，未冒充动态测试。未进行截图目检或真人游戏 GUI 验收。
- `flutter analyze --no-pub lib test tool` → `No issues found! (ran in 20.4s)`。
- `NO_COLOR=1 dart format --output=none --set-exit-if-changed .` → `Formatted 1871 files (0 changed) in 5.07 seconds.`
- 前台全量 `flutter test --no-pub` → `08:35 +7080: All tests passed!`，退出码 0，`[E]` 块数 0；墙钟 517 秒。完整日志 `../full_test.log`，起止/退出证据 `../logs/full.start`、`full.end`、`full.exit`。
- 三向破坏证红：待 S′ 后执行，脚本 `../logs/run_mutations.py` 精确备份还原，不使用 stash/checkout/revert。

## 范围核对与残留验收

白名单 37 路径，当前差异均在白名单。parity 删除 0 行；整个测试树仅 20 处当前版本字面量替换，其他既有测试零删除。`.g.dart` 无跟踪且旧夹具生成物被 gitignore，新增注释均为简体中文。没有追加白名单豁免。

合同“真机一次”未做，按原派单不启动游戏 GUI、不触碰真实存档。协调者 Gate、main 集成/CI、Windows 与真人验收仍由协调者分别处理；合同中夹具“排除”旧口径及 GDD 同步由协调者收账。未 push/merge/rebase/revert/amend/stash；未修改其他 worktree 或 `~/Documents/Codex/**`。CodeGraph 未初始化，使用原生搜索。

提交过程记录：准备 S′ 时，本机 Python 不接受 ISO 时间末尾 Z，记录脚本先失败；后续 shell 未停止，产生中间提交 `349856ca6`（仅已暂存 patch，树仍脏，虽有 READY 前缀但不具备交付资格）。未 amend/revert/rebase；将所有已完整验证的余项另行提交为最终 S′。最终收据仅指向完整且树干净的 S′，不是此中间提交。
