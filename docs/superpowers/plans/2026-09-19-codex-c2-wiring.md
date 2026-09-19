# C2 数值配置接线恢复点

- 分支：`codex/c2-wiring-20260919`。
- 基线：`36781fbbf1ca2336b8cf4ac1b94d6c1b71cf6730`。
- 目标：按派单顺序接入强化成功率、奇遇属性增量红线、闭关时段和五战例测试数据；生产数值保持不变。
- 范围：严格遵守派单精确白名单；不推送、不合并、不启动游戏、不接触真实存档。

## 验收与切片

1. 强化公式四字段必填，先红测后实现，独立结构提交后两向证红。
2. 奇遇增量上下限必填，加载期检验生产数据与越界夹具，独立提交后两向证红。
3. 闭关时段读取配置，覆盖八个边界和无效配置，独立提交后两向证红。
4. 五战例读取生产配置，保持现有伤害期望，独立提交后两向证红。
5. 六个定向文件及 `test/data/`、全量测试、静态分析、格式检查与逐叶审计；冻结实质提交 S，再单独提交收据 R。

## 当前恢复点

- 状态：四目标、双向证红、还原绿测、定向验收与逐叶解释已完成。最终全量及静态检查原文由随后独立收据保存；收据不存在时按下一步继续，不把本恢复点当作全量已通过的证明。
- 最后完成：四次目标提交与独立只读复核；六个定向文件逐个通过，共 179 条，test/data/ 共 1259 条通过；静态分析 0 issue，派单与 Gate 两种格式范围均 0 changed。
- 下一步：冻结本实质提交 S，在 S 上执行一次 flutter test --no-pub 及最终静态、格式检查；按实测生成独立包装提交 R，仅含收据。若 R 已存在且 head_sha 指向 S，则交协调者复跑 Gate；不推送或合并。
- 已跑验证：目标 1 初始红测 2 条失败；定向及还原均 29/29，移除实现 1 红、错配 YAML 2 红。目标 2 初始红测 8 条失败，实现及还原 9/9，移除实现 2 红、错配 YAML 4 红。目标 3 初始红测 13 条失败，实现及还原 22/22，移除实现 2 红、错配 YAML 1 红。目标 4 初始红测 11 条失败，实现后 62/62 通过。格式预检 lib/test/docs 共 1760 文件，0 changed。
- 阻塞项：无待扩围代码问题。计数 41 与指定命令实际结果不符的两层原因已在下文逐叶解释，未改工具或凑数；协调者复核时须保留此口径差异。
- 红线影响：仅接入现有配置，禁止变更数值、三系锁死、在线离线规则及玩家文案。
- 残留风险：本单不承担合并、发布、GUI、真人或 Windows 验收。最终全量是否成功以收据及原始日志终态为准。

- 时段构造兼容：两处白名单外 const RetreatConfig 仅测倍率和封顶。新增可空字段没有业务默认值，生产 fromYaml 必填解析，未提供时段的直接构造一旦查询时段即抛错，不能用于结算。
- 五战例边界：D/E 的 critical 原值分别为 2.0/2.5，只映射到 forceCritical；实际刚猛暴击倍率仍按生产规则为 1.5，已有伤害与其他行为保持原值。没有强塞倍率或修改生产公式。
- 收据格式：按 Gate 固定 schema 保留两个 direction 条目，各 mutation 字符串逐项列四目标的失败测试名和失败数，failed_count 写同方向四次实测之和。格式同时运行派单的 lib/test/docs 和 Gate 的整仓命令，收据采用 Gate 实测原文。

## 提交后破坏证红

| 目标 | 移除读取逻辑 | 临时修改 YAML | 完整还原复跑 |
| --- | --- | --- | --- |
| 高阶强化 | 恢复原公式常量，1 条失败 | floor_rate 改为 0.40，2 条失败 | 29/29 |
| 奇遇增量 | 校验边界改回 1/3，2 条失败 | bonus_per_event_max 改为 0，4 条失败 | 9/9 |
| 闭关时段 | 恢复固定小时判断，2 条失败 | 子时开始改为 22:00，1 条失败 | 22/22 |
| 五战例 | 恢复基线五个常量上下文，10 条失败 | A 修炼倍率改为 1.75，1 条失败 | 62/62 |

原始日志与逐条失败名称保存在工作树外 `/Users/a10506/Codex/2026-09-19/c2-wiring/target{1..4}_{red,green,remove_implementation,force_degenerate_value,restored}.log`，对应 `target{1..4}_break_red.json`。

## 批末定向验证

| 单独运行的路径 | 测试通过数 |
| --- | --- |
| `test/features/equipment/application/enhancement_service_test.dart` | 29 |
| `test/data/school_counter_v14_config_test.dart` | 3 |
| `test/features/seclusion/application/seclusion_time_of_day_test.dart` | 22 |
| `test/data/encounter_attribute_delta_red_line_test.dart` | 9 |
| `test/combat/damage_calculator_test.dart` | 62 |
| `test/features/seclusion/application/seclusion_service_test.dart` | 54 |
| `test/data/` | 1259 |

每次均执行 `flutter test --no-pub <路径>`，分别确认末行为 `All tests passed!` 且退出码 0；完整末行见工作树外 `targeted_results.json`。静态预检末行 `No issues found! (ran in 273.5s)`；格式预检末行分别为 `Formatted 1760 files (0 changed) in 30.43 seconds.` 与 `Formatted 1862 files (0 changed) in 73.96 seconds.`。最终收据使用 S 上复跑的原始末行，不沿用预检时间。

## 引用计数逐叶对账

指定命令 `python3 tools/audit/numbers_key_usage.py --baseline 36781fbbf --format json` 已实跑，原始结果为 **零引用 0**，不是 41。JSON 保存在 `/Users/a10506/Codex/2026-09-19/c2-wiring/usage_after.json`，总叶数 1719。

第一层原因：工具第 323–327 行要求 `lib_baseline_matches` 才能判“零引用”；本单必须修改 lib，实际保护命令退出 1，路径清单仍相同。故所有仍无引用的叶子均改标“疑似间接消费需人判”。工具虽声明“仅测试消费”标签，实际没有赋此标签的分支；11 个战例目标叶也标为“疑似间接消费需人判”，它们的真实消费由本单测试及双向破坏证明。没有修改工具或伪造输出。

第二层原因：原 59 叶中，强化公式文案转注释 1 叶、奇遇上下限 2 叶、时段 5 叶、战例 11 叶，共处理 **19** 叶，剩余 **40**。派单的 18/41 漏计了 `retreat.time_of_day_bonus[2].time_range: null`；此叶与其他时段一起必填解析，不能为凑 41 把它算回未读。

时段 5 叶具体为：`retreat.time_of_day_bonus[0].time_range[0]`、`retreat.time_of_day_bonus[0].time_range[1]`、`retreat.time_of_day_bonus[1].time_range[0]`、`retreat.time_of_day_bonus[1].time_range[1]`、`retreat.time_of_day_bonus[2].time_range`。战例 11 叶为五例各自的 `attacker.cultivation_multiplier` 与 `attacker.school_counter`，以及 C 的 `attacker.realm_diff_modifier`。

以下 40 叶逐一满足：生产原始文本无末段命中、测试字面量及路径片段无命中、无生产或动态遍历证据、存在原零引用分组；它们在原命令中的实际标签全部为“疑似间接消费需人判”，共同原因均为上述基线保护，而非本单将它们接线。该清单仅作逐叶解释，不宣称原命令输出 40 或 41。

| 序号 | 保留叶子 |
| --- | --- |
| 1 | `meta.last_updated` |
| 2 | `combat.damage_formula.skill_multiplier_added` |
| 3 | `combat.final_damage_formula.apply_cultivation_multiplier` |
| 4 | `combat.final_damage_formula.apply_school_counter` |
| 5 | `combat.final_damage_formula.apply_critical` |
| 6 | `combat.final_damage_formula.apply_defense` |
| 7 | `combat.final_damage_formula.apply_realm_diff` |
| 8 | `equipment.enhancement.max_level_formula` |
| 9 | `equipment.resonance.new_owner_retention` |
| 10 | `skills.reference_multipliers.power_skill.tier_1_2_range[0]` |
| 11 | `skills.reference_multipliers.power_skill.tier_1_2_range[1]` |
| 12 | `skills.reference_multipliers.power_skill.tier_3_4_range[0]` |
| 13 | `skills.reference_multipliers.power_skill.tier_3_4_range[1]` |
| 14 | `skills.reference_multipliers.power_skill.tier_5_6_range[0]` |
| 15 | `skills.reference_multipliers.power_skill.tier_5_6_range[1]` |
| 16 | `skills.reference_multipliers.power_skill.tier_7_range[0]` |
| 17 | `skills.reference_multipliers.power_skill.tier_7_range[1]` |
| 18 | `skills.reference_multipliers.ultimate.tier_1_2_range[0]` |
| 19 | `skills.reference_multipliers.ultimate.tier_1_2_range[1]` |
| 20 | `skills.reference_multipliers.ultimate.tier_3_4_range[0]` |
| 21 | `skills.reference_multipliers.ultimate.tier_3_4_range[1]` |
| 22 | `skills.reference_multipliers.ultimate.tier_5_6_range[0]` |
| 23 | `skills.reference_multipliers.ultimate.tier_5_6_range[1]` |
| 24 | `skills.reference_multipliers.ultimate.tier_7_range[0]` |
| 25 | `skills.reference_multipliers.ultimate.tier_7_range[1]` |
| 26 | `character.attributes.distribution_mean` |
| 27 | `character.attributes.distribution_stddev` |
| 28 | `inheritance.unlock_rules.disciple_can_take_grand_disciple_at` |
| 29 | `inheritance.unlock_rules.can_pass_legacy_at` |
| 30 | `inheritance.heritage_items.auto_buff_internal_force_max` |
| 31 | `inheritance.heritage_items.resonance_retention` |
| 32 | `validation_examples.example_a.calculated_damage` |
| 33 | `validation_examples.example_a.expected_outcome` |
| 34 | `validation_examples.example_b.calculated_damage` |
| 35 | `validation_examples.example_b.expected_outcome` |
| 36 | `validation_examples.example_c.calculated_damage` |
| 37 | `validation_examples.example_c.expected_outcome` |
| 38 | `validation_examples.example_d.calculated_damage` |
| 39 | `validation_examples.example_d.expected_outcome` |
| 40 | `validation_examples.example_e.expected_outcome` |
