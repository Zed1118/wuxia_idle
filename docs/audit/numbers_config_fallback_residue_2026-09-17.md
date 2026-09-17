# 数值配置兜底残留登记（2026-09-17）

本登记依据夜批单 A-1，只收口 `numbers_config.dart` 与 `stage_def.dart` 的数值字面量兜底及相关布尔开关。生产 YAML 不作修改；下列生产缺省或显式空值保留原行为，后续处理须另行拍板。

链 tip 的数值字面量兜底共 98 处：`numbers_config.dart` 97 处，`stage_def.dart` 1 处；其中 2 处跨行，派单的单行 grep 口径合计为 96。收口后数值残留恰为下表 2 行；相关布尔残留另列，不混入数值计数。

## 数值残留（2 行）

| key 路径 | 原样保留的兜底值 | 解析位置与消费者 | 生产事实与建议 |
|---|---|---|---|
| 🔴 `numbers.yaml: realms.level_diff_modifier.diff_3_or_more.attacker` | `1.0` | `lib/data/numbers_config.dart:2564`；`lib/shared/battle_shared/derived_stats.dart:45` | YAML 明确为 `null`，既有语义是跨三阶已碾压、攻击无需继续放大，数据层以单位元参与公式。不能在本单强制非空；后续拍板是否在 YAML 显式写出单位元并取消双源。 |
| 🔴 `stages.yaml: stages[stage_01_05..stage_06_05].bossRecruit.baseProbability` | `0.40` | `lib/data/defs/stage_def.dart:210`；`lib/features/mainline/application/mainline_settlement.dart:223`；`lib/features/sect/presentation/stage_boss_recruit_hook.dart:174` | 6 个招降关卡均只配置 `candidateRef`，没有 `baseProbability`。来源是 `stages.yaml`，并非 `numbers.yaml`；后续拍板是否让缺省概率统一消费已存在的 `sect_management.recruit.stage_boss_recruit_prob`。 |

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
- Boss 概率业务读方确为 `mainline_settlement.dart:223` 与 `stage_boss_recruit_hook.dart:174`；另有 `lineage_recruit_red_lines_validator.dart:447` 范围校验，实施时需同步适配可空字段。同名 encounter 概率不属于本次消费链。
- 独立分支 `codex/numbers-fallback-residue-20260917` 基于 `9879e833abe18b9fbba0c9c57758700ec0bf979d`；指定 worktree 已完成主仓 dylib 拷贝、pub get、build_runner。主仓快进及 64 条无 worktree 本地分支清理已先行完成。
- 原始基线：`flutter test --no-pub test/features/sect/stage_boss_recruit_test.dart` 末行 `00:02 +12: All tests passed!`；`flutter test --no-pub test/data/game_repository_test.dart --plain-name LevelDiffModifier` 末行 `00:00 +1: All tests passed!`；均退出 0，使用临时测试存档。
- 阻塞提交 `3d03993a` 保留历史，不 amend/rebase。解除后继续实施两处收口，四向证红与批末全量完成后再更新上表。证据与逐条分支清单：`/Users/a10506/Documents/Codex/2026-09-17/residue/evidence/delivery-report.md`。
