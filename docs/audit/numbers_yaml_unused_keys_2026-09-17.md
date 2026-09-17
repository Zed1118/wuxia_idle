# numbers.yaml 零引用 key 清点（B-2）

基线：`c307b3ffcb155af58d4efb9179e36453297b1360`。本次读取现有工作树 `data/numbers.yaml`、`lib/`、`test/`，未读取 A 单文件。
输入联合 SHA-256：`4614f93d31786bf95570fd6c1ba7ac55d66deb45341b637537bc43f17cdca22a`；YAML SHA-256：`12a674b531cb525dd312ea00cc04bbfeba89fb01d4783eeee3d63e41bf7e7109`。

## 复跑命令与口径

```sh
python3 tools/audit/numbers_key_usage.py
python3 tools/audit/numbers_key_usage.py --format markdown
```

依赖当前已有 Python 3 与 PyYAML；不运行 Flutter、不安装依赖、不写配置。JSON 输出到 stdout；第二条同源生成本报告。
检索清单由 `git ls-files -z -- lib test` 固定，只读受版本管理文件；不纳入协调者 worktree 的未跟踪/ignored `.g.dart` 或构建产物。
本次实际为 **1796 个标量叶子**（数组展开为 `[0]`、`[1]`，含 null），索引归一后 **847 个路径**，末段去重 **497 个名字**。这些口径不同，不能将旧报告约 460 个 key 当作本表分母。重复 YAML 映射 key 会直接报错，数组中的同名字段分别保留。

| 判定 | 标量叶子数 |
|---|---:|
| 生产消费 | 233 |
| 仅测试消费 | 0 |
| 零引用 | 202 |
| 疑似间接消费需人判 | 1361 |

零引用的 202 个标量叶子对应 **87 个归一路径、51 个末段名**。待人判数量较大是因为同名键和列表字段不能仅凭一次字符串命中分配到具体 YAML 路径；本单不靠强行分类提高完成率。

判定是静态证据等级，不是运行覆盖率：

- 生产消费须同时具备唯一归一末段路径、已连接配置解析器的字段赋值、唯一 final 字段声明以及解析层外成员读取；JSON 列出两端 file:line。仍不证明该分支在当前玩家路径必达。
- 只命中 loader、注释、报错字符串、测试夹具或同名字段均留作疑似间接消费；未证明仅测试真实消费的条目不硬归为仅测试消费。
- 零引用要求受版本管理 lib 原始文本连注释也无末段命中，且 test Dart 字面量和完整路径片段均无命中；还须落入下文人工排除动态消费的组，且 lib 与审计基线一致。测试纯说明文字另列 raw 命中。
- 对所有叶子同时检索末段精确 Dart 字符串与含末段的完整/后缀路径片段；路径片段命中本身不提升为生产消费。JSON 同时输出原文次数、字面量次数、文件和行号，防止 grep 与词法计数混淆。
- 心魔、轻功、守城和里程碑授予 Map 容器显式标为待人判；其他动态容器也不因零字面量自动进入零引用。源码与基线不一致或候选落在未审计分组时，一律降为待人判。静态扫描不是 Dart AST/运行期追踪。

## 重点段交叉核对

以下计数也由本次 JSON 逐行归集；同名导致待人判不能反推该段已消费。

| 段 | 标量叶子 | 生产消费 | 仅测试消费 | 零引用 | 待人判 |
|---|---:|---:|---:|---:|---:|
| `tower` | 69 | 0 | 0 | 29 | 40 |
| `synergies` | 11 | 0 | 0 | 10 | 1 |
| `combat.final_damage_formula` | 5 | 0 | 0 | 5 | 0 |
| `validation_examples` | 66 | 0 | 0 | 20 | 46 |

## 动态消费排除证据

入口复核：`lib/data/game_repository.dart:219` 加载 numbers，`:226` 交给 NumbersConfig，`:227` 另取 realms。`NumbersConfig.raw` 的实际取值仅见 `lib/data/numbers_config.dart:340` 的 milestone_equipment_grants；`:538` 原样持有 Map 不视作消费。
可复核命令：`rg -n '\.raw\b|raw\[|numbersRaw\b' lib --glob '*.dart'`；`rg -n '\.entries|\.values|\.map\(|\[key\]' lib/data/numbers_config.dart`。命中的其他 raw 局部变量须按所在类区分，不能当作 NumbersConfig.raw。
另核对了开锋 bonus_value 的 entries（numbers_config.dart:1094）、动作链动态段（:2093）、招式按 key 获取（:1999）、周目 assignment 双层动态键（:3648）；这几组没有进入零引用清单。
基线保护实跑：`git diff --quiet c307b3ffcb155af58d4efb9179e36453297b1360 -- lib` 退出 `0`，受版本管理路径清单一致为 `true`。此保护失败时，以下人工排除结论不再用于自动判零。

| 零引用候选组 | 本次叶子数 | 排除动态消费的理由 | 固定基线证据 |
|---|---:|---|---|
| 元数据 | 1 | NumbersConfig 只从 meta 取 version；其余未透传到字段。 | `lib/data/numbers_config.dart:346`；`lib/data/numbers_config.dart:353` |
| 基础公式文档开关 | 1 | DamageFormula 只按字段取两个系数，没有整表遍历。 | `lib/data/numbers_config.dart:2282` |
| 最终公式文档开关 | 5 | CombatNumbers 构造器逐段解析，没有 final_damage_formula 入口。 | `lib/data/numbers_config.dart:1310` |
| 装备阶模板 | 91 | NumbersConfig 的 equipment 读取是强化、开锋、共鸣、遗物与处置；实装装备定义来自独立 equipment.yaml。 | `lib/data/numbers_config.dart:376`；`lib/data/game_repository.dart:220`；`lib/data/game_repository.dart:228` |
| 强化公式文档 | 2 | 强化入口逐字段解析；success_curve 循环只取 level_range/success_rate/material_penalty，公式走 _fallbackFormula。 | `lib/data/numbers_config.dart:876`；`lib/data/numbers_config.dart:947`；`lib/data/numbers_config.dart:952` |
| 共鸣换主预留 | 1 | 共鸣只取已列明的 stages、inheritance_retention、seclusion_battle_count_per_hour；stages 逐字段解析。 | `lib/data/numbers_config.dart:404`；`lib/data/numbers_config.dart:617` |
| 心法阶名称 | 7 | tiers 遍历只取 tier 和 speed_bonus；不遍历行内所有 key/value。 | `lib/data/numbers_config.dart:551` |
| 招式参考倍率 | 16 | NumbersConfig 无 skills 入口；实装 SkillDef 来自独立 skills.yaml。 | `lib/data/numbers_config.dart:345`；`lib/data/game_repository.dart:222`；`lib/data/game_repository.dart:238` |
| 角色设计与事件范围 | 9 | character 只取 lifetime_cap_per_character 和 rarity_distribution，未整表或动态取这些零命中字段。 | `lib/data/numbers_config.dart:492`；`lib/data/numbers_config.dart:502` |
| 时段文档锚 | 5 | 按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。 | `lib/data/numbers_config.dart:2682`；`lib/data/numbers_config.dart:2744` |
| 旧塔配置段 | 29 | NumbersConfig 无 tower 入口；实际楼层由独立 towers.yaml 读取，原始 Map 未被遍历消费。 | `lib/data/numbers_config.dart:345`；`lib/data/game_repository.dart:224`；`lib/data/game_repository.dart:270` |
| 传承预留字段 | 5 | inheritance 只接祖师 buff 和 HeritageItems；后者逐个读取六个字段，没有通用 Map 遍历。 | `lib/data/numbers_config.dart:428`；`lib/data/numbers_config.dart:771` |
| 旧相生数值段 | 10 | NumbersConfig 无 synergies 入口；实际相生定义来自独立 synergies.yaml，原始 Map 未被遍历消费。 | `lib/data/numbers_config.dart:345`；`lib/data/game_repository.dart:373` |
| 手工公式战例 | 20 | NumbersConfig 无 validation_examples 解析入口；raw 仅持有数据不构成消费。 | `lib/data/numbers_config.dart:345`；`lib/data/numbers_config.dart:538` |

## 零引用逐条表

所有行建议只供用户拍板；没有删除任何配置。数组逐元素列出，所在源行可重复。

| key | 叶子值 | YAML 行 | 所在段已标 UNUSED | 建议 |
|---|---|---:|---|---|
| `meta.last_updated` | "2026-05-10" | 34 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.damage_formula.skill_multiplier_added` | true | 106 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.final_damage_formula.apply_cultivation_multiplier` | true | 113 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.final_damage_formula.apply_school_counter` | true | 114 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.final_damage_formula.apply_critical` | true | 115 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.final_damage_formula.apply_defense` | true | 116 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `combat.final_damage_formula.apply_realm_diff` | true | 117 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `equipment.tiers[0].tier_name` | "寻常货" | 681 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].weapon.attack_min` | 100 | 682 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].weapon.hp_min` | 0 | 682 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].weapon.speed_min` | 0 | 682 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].weapon.speed_max` | 10 | 682 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].armor.attack_min` | 0 | 683 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].armor.hp_min` | 100 | 683 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].armor.speed_min` | 0 | 683 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].armor.speed_max` | 5 | 683 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].accessory.attack_min` | 20 | 684 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].accessory.hp_min` | 50 | 684 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].accessory.speed_min` | 0 | 684 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[0].accessory.speed_max` | 8 | 684 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].tier_name` | "像样货" | 688 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].weapon.attack_min` | 180 | 689 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].weapon.hp_min` | 0 | 689 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].weapon.speed_min` | 5 | 689 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].weapon.speed_max` | 20 | 689 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].armor.attack_min` | 0 | 690 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].armor.hp_min` | 250 | 690 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].armor.speed_min` | 0 | 690 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].armor.speed_max` | 10 | 690 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].accessory.attack_min` | 50 | 691 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].accessory.hp_min` | 100 | 691 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].accessory.speed_min` | 5 | 691 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[1].accessory.speed_max` | 15 | 691 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].tier_name` | "好家伙" | 695 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].weapon.attack_min` | 320 | 696 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].weapon.hp_min` | 0 | 696 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].weapon.speed_min` | 10 | 696 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].weapon.speed_max` | 30 | 696 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].armor.attack_min` | 0 | 697 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].armor.hp_min` | 450 | 697 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].armor.speed_min` | 5 | 697 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].armor.speed_max` | 15 | 697 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].accessory.attack_min` | 100 | 698 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].accessory.hp_min` | 200 | 698 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].accessory.speed_min` | 10 | 698 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[2].accessory.speed_max` | 25 | 698 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].tier_name` | "利器" | 702 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].weapon.attack_min` | 480 | 703 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].weapon.hp_min` | 0 | 703 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].weapon.speed_min` | 20 | 703 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].weapon.speed_max` | 45 | 703 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].armor.attack_min` | 0 | 704 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].armor.hp_min` | 700 | 704 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].armor.speed_min` | 10 | 704 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].armor.speed_max` | 25 | 704 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].accessory.attack_min` | 180 | 705 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].accessory.hp_min` | 350 | 705 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].accessory.speed_min` | 20 | 705 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[3].accessory.speed_max` | 35 | 705 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].tier_name` | "重器" | 709 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].weapon.attack_min` | 700 | 710 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].weapon.hp_min` | 50 | 710 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].weapon.speed_min` | 30 | 710 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].weapon.speed_max` | 60 | 710 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].armor.attack_min` | 0 | 711 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].armor.hp_min` | 1100 | 711 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].armor.speed_min` | 15 | 711 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].armor.speed_max` | 35 | 711 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].accessory.attack_min` | 280 | 712 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].accessory.hp_min` | 550 | 712 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].accessory.speed_min` | 30 | 712 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[4].accessory.speed_max` | 50 | 712 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].tier_name` | "宝物" | 718 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].weapon.attack_min` | 1000 | 719 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].weapon.hp_min` | 100 | 719 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].weapon.speed_min` | 45 | 719 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].weapon.speed_max` | 75 | 719 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].armor.attack_min` | 0 | 720 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].armor.hp_min` | 1400 | 720 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].armor.speed_min` | 25 | 720 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].armor.speed_max` | 50 | 720 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].accessory.attack_min` | 420 | 721 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].accessory.hp_min` | 750 | 721 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].accessory.speed_min` | 45 | 721 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[5].accessory.speed_max` | 70 | 721 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].tier_name` | "神物" | 727 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].weapon.attack_min` | 1500 | 728 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].weapon.hp_min` | 150 | 728 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].weapon.speed_min` | 65 | 728 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].weapon.speed_max` | 100 | 728 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].armor.attack_min` | 0 | 729 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].armor.hp_min` | 1750 | 729 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].armor.speed_min` | 40 | 729 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].armor.speed_max` | 70 | 729 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].accessory.attack_min` | 600 | 730 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].accessory.hp_min` | 1000 | 730 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].accessory.speed_min` | 65 | 730 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.tiers[6].accessory.speed_max` | 95 | 730 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.enhancement.max_level_formula` | "absolute_level" | 735 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.enhancement.success_curve[4].success_formula` | "max(0.30, 0.50 - 0.02 * (level - 19))" | 757 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `equipment.resonance.new_owner_retention` | 0.0 | 837 | 否 | 待拍板：原注释要求保留换主语义锚；当前零引用不能替代设计决定。 |
| `techniques.tiers[0].tier_name` | "入门功" | 898 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[1].tier_name` | "常练功" | 904 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[2].tier_name` | "名家功" | 910 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[3].tier_name` | "门派绝学" | 916 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[4].tier_name` | "江湖秘传" | 922 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[5].tier_name` | "失传神功" | 928 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `techniques.tiers[6].tier_name` | "传说神功" | 934 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_1_2_range[0]` | 1000 | 1065 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_1_2_range[1]` | 1800 | 1065 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_3_4_range[0]` | 1500 | 1066 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_3_4_range[1]` | 2500 | 1066 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_5_6_range[0]` | 2000 | 1067 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_5_6_range[1]` | 3000 | 1067 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_7_range[0]` | 2500 | 1068 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.power_skill.tier_7_range[1]` | 3500 | 1068 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_1_2_range[0]` | 3000 | 1070 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_1_2_range[1]` | 4500 | 1070 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_3_4_range[0]` | 4500 | 1071 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_3_4_range[1]` | 6000 | 1071 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_5_6_range[0]` | 5500 | 1072 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_5_6_range[1]` | 7000 | 1072 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_7_range[0]` | 6500 | 1073 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `skills.reference_multipliers.ultimate.tier_7_range[1]` | 8000 | 1073 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.point_per_attribute_min` | 1 | 1087 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.point_per_attribute_max` | 10 | 1088 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.total_points_min` | 16 | 1089 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.total_points_max` | 24 | 1090 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.distribution_mean` | 5.5 | 1092 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.distribution_stddev` | 1.5 | 1093 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.attributes.rerollable` | false | 1094 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.adventure_attribute_bonus.bonus_per_event_min` | 1 | 1145 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `character.adventure_attribute_bonus.bonus_per_event_max` | 3 | 1146 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `retreat.time_of_day_bonus[0].time_range[0]` | "23:00" | 1377 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `retreat.time_of_day_bonus[0].time_range[1]` | "01:00" | 1377 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `retreat.time_of_day_bonus[1].time_range[0]` | "11:00" | 1381 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `retreat.time_of_day_bonus[1].time_range[1]` | "13:00" | 1381 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `retreat.time_of_day_bonus[2].time_range` | null | 1388 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `tower.daily_attempts` | 5 | 1496 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.refresh_at` | "00:00" | 1497 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[0].difficulty_range[0]` | 1.0 | 1510 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[0].difficulty_range[1]` | 1.2 | 1510 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[0].recommended_realm` | "erLiu" | 1512 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[1].difficulty_range[0]` | 1.25 | 1514 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[1].difficulty_range[1]` | 1.5 | 1514 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[1].recommended_realm` | "erLiu" | 1516 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[2].difficulty_range[0]` | 1.6 | 1520 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[2].difficulty_range[1]` | 2.0 | 1520 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[2].recommended_realm` | "yiLiu" | 1522 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[3].difficulty_range[0]` | 2.1 | 1524 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[3].difficulty_range[1]` | 2.6 | 1524 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[3].recommended_realm` | "yiLiu" | 1526 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[4].difficulty_range[0]` | 2.8 | 1530 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[4].difficulty_range[1]` | 3.4 | 1530 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[4].recommended_realm` | "yiLiu" | 1532 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[5].difficulty_range[0]` | 3.55 | 1534 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[5].difficulty_range[1]` | 4.2 | 1534 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.difficulty_curve[5].recommended_realm` | "jueDing" | 1536 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.small_boss_layers[0]` | 5 | 1541 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.small_boss_layers[1]` | 15 | 1541 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.small_boss_layers[2]` | 25 | 1541 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.big_boss_layers[0]` | 10 | 1542 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.big_boss_layers[1]` | 20 | 1542 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.big_boss_layers[2]` | 30 | 1542 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.small_boss_multiplier` | 1.5 | 1543 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.boss_layers.big_boss_multiplier` | 2.0 | 1544 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `tower.leaderboard.sync_to_supabase` | true | 1554 | 是：1488 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `inheritance.unlock_rules.can_take_disciple_at` | "yiLiu" | 1579 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `inheritance.unlock_rules.disciple_can_take_grand_disciple_at` | "jueDing" | 1580 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `inheritance.unlock_rules.can_pass_legacy_at` | "wuSheng" | 1581 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `inheritance.heritage_items.auto_buff_internal_force_max` | 0.05 | 1595 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `inheritance.heritage_items.resonance_retention` | 0.7 | 1596 | 否 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.yin_yang_he.effect_type` | "all_attr_pct" | 1636 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.yin_yang_he.effect_value` | 0.2 | 1637 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.gai_bang_chuan_cheng.effect_type` | "unlock_skill_crit" | 1641 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.gai_bang_chuan_cheng.target_skill_id` | "skill_kang_long_you_hui" | 1642 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.shao_lin_zheng_zong.effect_type` | "internal_force_growth_pct" | 1647 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.shao_lin_zheng_zong.effect_value` | 0.3 | 1648 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.wu_dang_yuan_rong.effect_type` | "reflect_pct" | 1652 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.wu_dang_yuan_rong.effect_value` | 0.15 | 1653 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.hua_shan_he_bi.effect_type` | "crit_dmg_pct" | 1657 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `synergies.effect_values.hua_shan_he_bi.effect_value` | 0.5 | 1658 | 是：1627 | 删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。 |
| `validation_examples.example_a.attacker.cultivation_multiplier` | 1.0 | 1682 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_a.attacker.school_counter` | 1.0 | 1683 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_a.calculated_damage` | "(600*0.4 + 130*1.0 + 500) * 1.0 * 1.0 * 1.0 * (1-0.05) * 1.0 = 826" | 1689 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_a.expected_outcome` | "约 4 击致死，节奏适合新手期教学战斗 ✓" | 1690 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_b.attacker.cultivation_multiplier` | 1.75 | 1701 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_b.attacker.school_counter` | 1.0 | 1702 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_b.calculated_damage` | "(3000*0.4 + 580 + 1500) * 1.75 * 1.0 * 1.0 * 0.85 * 1.0 = 4889" | 1708 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_b.expected_outcome` | "在 2000-8000 红线内 ✓；约 2 击致死，强力技能节奏合理" | 1709 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_c.attacker.cultivation_multiplier` | 1.3 | 1720 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_c.attacker.school_counter` | 1.0 | 1721 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_c.attacker.realm_diff_modifier` | 0.7 | 1723 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_c.calculated_damage` | "(2000*0.4 + 280 + 1500) * 1.30 * 1.0 * 1.0 * 0.85 * 0.7 = 1972" | 1728 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_c.expected_outcome` | "勉强达到普通伤害下限 2000；约 4 击致死，三流挑战二流确实吃力 ✓" | 1729 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_d.attacker.cultivation_multiplier` | 1.75 | 1740 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_d.attacker.school_counter` | 1.25 | 1741 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_d.calculated_damage` | "(5000*0.4 + 600 + 5500) * 1.75 * 1.25 * 2.0 * 0.80 * 1.0 = 28525" | 1747 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_d.expected_outcome` | "破万达成（28525），符合 GDD §5.2 大招暴击'上万'目标 ✓；一击秒杀" | 1748 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_e.attacker.cultivation_multiplier` | 3.0 | 1760 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_e.attacker.school_counter` | 1.0 | 1761 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |
| `validation_examples.example_e.expected_outcome` | "约 19500 / 19500 几乎一击致死，符合武圣对决'电光石火'氛围 ✓；血量未超 20000 红线 ✓" | 1768 | 否 | 保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。 |

## 独立复核命令

以下 8 个末段覆盖元数据、公式、换主预留与塔段；`git grep` 应退出 1 且输出 0 行。本次另用 `grep -rnF` 独立检查，同为 8/8 零命中。

```sh
for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do
  git grep -n -F -- "$key" -- lib; printf '%s grep_exit=%s\n' "$key" "$?"
done
```

生产样本同时复核解析和消费，两端都须存在：

```sh
rg -n "opening_qi|openingQi" lib/data/numbers_config.dart lib/shared/battle_shared/player_combatant_snapshot_builder.dart
rg -n "equipment_attack_factor|equipmentAttackFactor" lib/data/numbers_config.dart lib/features/combat_shared/domain/damage_calculator.dart
rg -n "constitution_factor|constitutionFactor" lib/data/numbers_config.dart lib/shared/battle_shared/derived_stats.dart
```

本次脚本每次独立调用 grep 的实际结果：零引用 **8/8**（输出 0 行、退出 1）；生产两端命中 **3/3**。完整命令、退出码与消费行见 JSON 的 `sample_verification`。

## 限制与建议

零引用并不自动等于可删。UNUSED 仅表示 YAML 原注释标注，不能替代本次检索；纯文档段、设计锚和动态读取分别保留。
优先人工核对动态 Map 与同名字段，再判断是否删除或将说明锚迁入文档；任何删除配置字段都需用户拍板。
本单仅审计 YAML 有而代码引用不明确的方向；不读取、不合并、不覆盖 A 单的兜底残留报告。
