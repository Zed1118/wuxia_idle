# 数值配置兜底残留登记（2026-09-17）

本登记依据夜批单 A-1，只收口 `numbers_config.dart` 与 `stage_def.dart` 的数值字面量兜底及相关布尔开关。夜批阶段未修改生产 YAML；本次经协调者批准，只将 numbers.yaml 第 245 行显式写为单位元，并让缺省招降概率统一消费 numbers，保持既有数值行为。

链 tip 的数值字面量兜底共 98 处：`numbers_config.dart` 97 处，`stage_def.dart` 1 处；其中 2 处跨行，派单的单行 grep 口径合计为 96。夜批结束时数值残留为下表 2 行；本次两行均已收口，范围内数值残留归零；相关布尔残留另列，不混入数值计数。

## 数值残留收口记录（2 行已收口）

| key 路径 | 原兜底值 | 解析位置与消费者 | 收口结果与证据 |
|---|---|---|---|
| 已收口 @76031a91b `numbers.yaml: realms.level_diff_modifier.diff_3_or_more.attacker` | 原 `1.0` | `lib/data/numbers_config.dart`；`lib/shared/battle_shared/derived_stats.dart` | YAML 显式单位元 `1.0`；缺 key/null 拒绝加载并报完整路径。公式可执行源码未改；战斗 1245、境界差加载 1、派生 6、伤害 10 条前后计数一致。提交后 YAML 改回 null 红 1 条，loader 加回 `?? 1.0` 红 2 条；均精确还原。 |
| 已收口 @76031a91b `stages.yaml: stages[stage_01_05..stage_06_05].bossRecruit.baseProbability` | 原 `0.40` | `lib/data/defs/stage_def.dart`；`stage_boss_recruit_probability.dart`；主线结算与招降 hook | 配置字段改可空，两个业务消费点共用生产解析函数，缺省只取 numbers 的既有 `stage_boss_recruit_prob`。6 关与 `0.40` 未改，显式覆盖和越界校验保留。提交后 numbers 临改 `0.99` 红 2 条，stage loader 加回 `?? 0.40` 红 2 条；均精确还原。 |

## 布尔开关补充登记（不计入数值 grep 表）

- 🔴 `enemy.guardInterceptsInterrupt`：原样保留 `false`。解析位置 `lib/data/defs/stage_def.dart:353`，消费者 `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:2020`、`:2288`。敌人来源中的缺键数：`stages.yaml` 135/135、`towers.yaml` 115/116、`boss_gauntlets.yaml` 7/7、`expeditions.yaml` 9/9。强制配置须跨这些生产文件补齐；本单保留缺省关闭，后续另行拍板。
- 🔴 `enemy.isBoss`：原样保留 `false`。解析位置 `lib/data/defs/stage_def.dart:382`，消费者 `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:255`。敌人来源中的缺键数：`stages.yaml` 91/135、`towers.yaml` 102/116、`boss_gauntlets.yaml` 4/7、`expeditions.yaml` 9/9。普通敌人目前省略此标记；本单保留，后续拍板是否要求生产敌人逐项显式标记。

`stage_def.dart` 中 `hasChargePhase` 的可空列表判定仍保留 `?? false`。它表示不存在相位列表时不存在蓄力相位，是已有可选结构的谓词结果，不读取数值配置 key，也不是可配置开关。

## 已核对范围

- `combat.red_lines` 的 8 个 key 均显式存在且非空，全部收口。
- 非红线已收口 94 处，其中数值 88 处、布尔开关 6 处；`StageDef.isBossStage` 额外收口 1 处布尔开关，生产 122 个关卡均已显式配置。
- 数组逐项核对：`equipment.forging.slots` 3 项的 `fucai_cost`、`equipment.resonance.stages` 4 项的 `unlocks_joint_skill` 与 `has_sword_song_effect` 均无局部缺键。
- 守卫基于生产 YAML 复制后删除 key，覆盖红线 8 项、非红线 94 条路径（数组逐项扩展为 102 项）及普通/Boss 关卡开关；完整生产数值与关卡均经过加载断言。
- `test/data/numbers_config_required_keys_test.dart` 单跑末行：`00:00 +114: All tests passed!`。原始输出：`/Users/a10506/Documents/Codex/2026-09-16/night-A/logs/A-1_required_keys_targeted.log`。

既有整段缺省对象、非数值枚举/字符串缺省，以及本范围外配置类不在本单字面量兜底整改范围内，未扩大改动。

## 2026-09-17 收口恢复点（已解除：协调者 2026-09-17 授权断言等价替换）

- 用户已批准两处按行为等价、单一事实源收口：境界差攻击单位元在 YAML 显式写 `1.0` 并强制加载；Boss 招降省略概率时由两处业务消费点读取 numbers 的既有 `0.40`。
- 实施前核对发现测试约束冲突：`test/features/sect/stage_boss_recruit_test.dart:120`、`:142` 均直接断言省略概率时字段为 `0.40`。字段改为可空后必须替换这些断言及旧描述，Git 会记为删除行，与本次“test/ 删除行数必须为 0”冲突。协调者已授权仅替换两条旧断言及紧邻注释：保留 null 断言，并通过两个消费点共用的生产解析函数断言有效概率等于 numbers 值；不得删除测试用例或削弱覆盖，其他测试文件仍只新增。
- Boss 概率业务读方确为 `mainline_settlement.dart:223` 与 `stage_boss_recruit_hook.dart:174`；另有 `lineage_recruit_red_lines_validator.dart:447` 范围校验，现已同步适配可空字段。同名 encounter 概率不属于本次消费链。
- 独立分支 `codex/numbers-fallback-residue-20260917` 基于 `9879e833abe18b9fbba0c9c57758700ec0bf979d`；指定 worktree 已完成主仓 dylib 拷贝、pub get、build_runner。主仓快进及 64 条无 worktree 本地分支清理已先行完成。
- 原始基线：`flutter test --no-pub test/features/sect/stage_boss_recruit_test.dart` 末行 `00:02 +12: All tests passed!`；`flutter test --no-pub test/data/game_repository_test.dart --plain-name LevelDiffModifier` 末行 `00:00 +1: All tests passed!`；均退出 0，使用临时测试存档。
- 阻塞提交 `3d03993a` 保留历史，不 amend/rebase。实现提交为 `76031a91b938155ccf0b265af5fa2315cf8e0cca`；提交后四向证红、还原复验和批末全量均已完成，上表已更新。证据与逐条分支清单：`/Users/a10506/Documents/Codex/2026-09-17/residue/evidence/delivery-report.md`。

## 本次收口验收

- 逐行测试替换、四向证红原始命令/失败数/精确还原哈希、前后计数及全量证据见 [residue receipt](../dispatch/reports/2026-09-17_residue_receipt.yaml)。测试删除仅获准 4 行（2 条断言、2 行注释），均有等价或更强替换；其余测试文件删除 0 行。
- format：`Formatted 1754 files (0 changed) in 3.93 seconds.`；analyze：`No issues found! (ran in 3.2s)`。
- 批末全量仅运行一次：`09:02 +6948: All tests passed!`；`[E]` 计数 0，`done.success=true`，退出 0，失败/跳过均为 0；墙钟 545.138 秒。
- 仅工程待评，未合并；未触碰真实存档、saveVersion/schema、stages.yaml、sect_candidates.yaml、PROGRESS.md、GDD.md、strings.dart、pubspec.yaml。布尔开关残留维持原登记。
