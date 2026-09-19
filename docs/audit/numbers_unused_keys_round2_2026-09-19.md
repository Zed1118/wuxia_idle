# numbers.yaml 零引用 key 二轮对照单（2026-09-19）

- 审计基线：`5d9bbdeaf`（派单包 C 冻结基线；协调者自审，派单包 `docs/dispatch/2026-09-19_qoder_C_零引用key二轮对照单.md` 未派出，原因见日报）
- 扫描：`python3 tools/audit/numbers_key_usage.py --baseline 5d9bbdeaf --format json`，退出码 0
- 本单**只产建议，不动 `data/numbers.yaml` 一个字**；「删」「接线」均为 🔴/🟡 用户拍板项
- 证据规则：每叶按 key 名 + **值当领域词**双搜（`git grep -n -F '<值>' -- lib test`），只搜 key 名零命中不算证据；「删」类附 `git log -S`

## 1. 基线计数与守恒

| 口径 | 5A 对照单登记（C-A 后） | 本次 `5d9bbdeaf` 实测 |
|---|---|---|
| 零引用叶 | 60（已标 57 / 未标 3） | **59（已标 56 / 未标 3）** |
| 仅测试消费 / 疑似间接消费需人判 | — | 由 `usage_r2.json` `counts` 给出，本单不展开 |

守恒：60 → 59，差 1 叶 = `inheritance.unlock_rules.can_take_disciple_at`，由 `bc6cb8b8b 2026-09-18 让收徒门槛读 numbers.yaml can_take_disciple_at 并退役 tutorial 写死的一流(B2 复核 5A I-A′)` 接线（`git log -S'can_take_disciple_at' --oneline`；消费点 `lib/data/numbers_config.dart:529,4175`、`lib/features/seclusion/application/seclusion_service.dart:618`）。已标 57 → 56 同一叶。**守恒成立，无未解释差异。**

未标 3 叶（B2 原表 `:93-95` / `:976-995` 给了保留理由但未打 `UNUSED(` 标记）：三叶注释里都是 `⚠️ 未消费`/`# 由代码按…计算` 口径，扫描器 `unused_marked` 只认 `UNUSED(` 令牌，所以是**标记令牌不一致**而非漏审。头注文案建议（不写入 yaml，随拍板一起做）：
- `:743` 上一行加 `# UNUSED(2026-09-19 二轮·头注): max_level_formula 为公式名文档锚,上限规则写死 enhancement_service._enhanceLevelCap(min(49, absoluteLevel))。`
- `:765` 上一行加 `# UNUSED(2026-09-19 二轮·头注): success_formula 为公式文案,常量 0.50/0.02/19/0.30 写死 numbers_config._fallbackFormula(:1068-1072);改本行不生效。`
- `:845` 现有 `⚠️ 未消费` 两行改首词为 `UNUSED(2026-06-16 审计 M7·头注):`，其余原文保留。

## 2. 分段对照表（59 叶，yaml 行号升序）

分类只三种：**留**（设计指引/文档锚，头注即可）/ **删**（配置死叶，🔴）/ **接线**（有真消费点但值写死在 Dart 或读了别的 key）。「值搜」列 = 把值当领域词在 `lib test` 的命中（`.g.dart` 排除）。

### A · meta（1 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `meta.last_updated` | 35 | 2026-05-10 | M | 头注 UNUSED | **删** | key 名 lib/test 0 命中（只在 `tools/audit/*.py` 出现）；值是 4 个月前的存档时间戳，此后 numbers.yaml 共 179 个 commit 却从未更新（`git log --oneline 5d9bbdeaf -- data/numbers.yaml | wc -l` = 179）；`git log -S'last_updated'`：加入 `fb99985ae 2026-05-10`，最近 `8d6a00299 2026-09-17`（仅加头注）；GDD/data_schema 0 引用 | 删 1 行 + `numbers_key_usage.py:346,450` 终端名单同步（2 处字符串） |

**段推荐：删**——一个永远不更新的时间戳只会误导；真事实源是 git。

### B · combat 公式开关（6 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `combat.damage_formula.skill_multiplier_added` | 108 | true | M | 头注 UNUSED | **删** | `damage_formula` 块只被 `numbers_config.dart:1441` 整体读 Map，字段本身 0 读；加项语义已硬编码 damage_calculator（头注自述）；`git log -S`：加入 `fb99985ae`，最近 `8d6a00299`；GDD 0 引用 key 名 | 删 1 行 + 头注 1 行 |
| `combat.final_damage_formula.apply_cultivation_multiplier` | 116 | true | M | 头注 UNUSED | **删** | `final_damage_formula` key 名 lib/test **0 命中**（整块不解析）；damage_calculator 恒应用全部乘子，`true→false` 不生效（头注 :112-113 自述）；`git log -S'apply_realm_diff'`：加入 `fb99985ae`，此后无改动 | 删整块 7 行（含 2 行头注），公式说明保留 :110 一行注释 |
| `…apply_school_counter` | 117 | true | M | 同上 | **删** | 同上 | 同上 |
| `…apply_critical` | 118 | true | M | 同上 | **删** | 同上 | 同上 |
| `…apply_defense` | 119 | true | M | 同上 | **删** | 同上 | 同上 |
| `…apply_realm_diff` | 120 | true | M | 同上 | **删** | 同上 | 同上 |

**段推荐：删**——布尔开关形态但改了不生效，是最危险的一类死叶（5A 已为同类 tower/synergies 拍删）；公式结构在 :110 注释与 GDD §5.4 都有，不需要伪开关承载。

### C · equipment（3 叶，未标）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `equipment.enhancement.max_level_formula` | 743 | "absolute_level" | - | 保留（公式锚） | **留** | 值搜 `absolute_level`：仅 `game_repository.dart:769`（realms 表字段，非本 key）；规则写死 `enhancement_service.dart:290-294 _enhanceLevelCap = min(49, absoluteLevel)`。公式名字符串本身不可消费，只能作文档锚 | 头注 1 行。**附带发现（🟡）**：`_enhanceLevelCap` 的 `49` 是硬编码，而 `progression.release_cap.max_absolute_realm_level: 49`（:225，`progression_release_cap.dart:11` 真读）表达同一终点；若日后 cap 变动此处会静默脱节，建议单独立一条「强化上限读 realms 表绝对层数上限」微修 |
| `equipment.enhancement.success_curve[4].success_formula` | 765 | max(0.30, 0.50 - 0.02 * (level - 19)) | - | 保留（公式锚） | **接线** | 值搜 `0.50 - 0.02`：命中 `lib/data/numbers_config.dart:1068-1072 _fallbackFormula`，四个常量 0.50 / 0.02 / 19 / 0.30 **全部写死在 Dart**，yaml 只留公式文案；`success_rate: null` 触发回退（:1016-1020）。与 5A I 段 `yiLiu` 写死同型 | 把公式拆成数值字段（如 `formula_base: 0.50 / formula_step: 0.02 / formula_anchor_level: 19 / formula_floor: 0.30`）由 `EnhancementConfig` 解析并替换 `_fallbackFormula` 常量；约 25 行 lib + 1 个 targeted 测；`success_formula` 文案行可留作注释 |
| `equipment.resonance.new_owner_retention` | 845 | 0.0 | - | 保留（预埋） | **留** | 值搜 `retention`：lib 仅 `inheritance_retention`（:92,425）；`resonance` 在 lib 无 owner/transfer/reset 路径（`git grep -i -E 'resonance.*(reset|owner)' -- lib` 0 命中）；无玩家间换主功能 → 无处接线；`git log -S`：加入 `fb99985ae`，此后无改动；GDD §6.4 引用（B2 `GDD.md:469`） | 头注令牌改为 `UNUSED(` 即可 |

**段推荐：`success_formula` 接线、其余两叶留**——`success_formula` 是本轮唯一「同一门槛写死 Dart」的硬命中，接线后强化成功率完全可调；`max_level_formula` 附带的硬编码 49 建议另立微修单。

### D · skills.reference_multipliers（16 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `skills.reference_multipliers.power_skill.tier_1_2_range[0..1]` | 1075 | 1000 / 1800 | M | 头注 UNUSED | **删** | `reference_multipliers` 与 `tier_7_range` 在 lib/test **0 命中**；实装倍率来自 `data/skills.yaml`（`skills.yaml:8-12` 自述），红线只有全局 `skill_power_multiplier_max` ≤8000（`test/data/skill_multiplier_redline_test.dart`）。**本次实测区间已与生产脱节**：`skills.yaml` 带 `tier:` 字段的 50 个 `powerSkill` 中 **38 个越出**本区间（tier 4 实值 2700-4800 vs 参考 1500-2500；tier 6 实值 3800-6400 vs 2000-3000；tier 7 实值 4000-7800 vs 2500-3500），另 60 powerSkill / 55 ultimate 无 `tier` 字段无法对照（脚本 `tier_measure.py`，见 §6）；`git log -S'tier_7_range'`：加入 `fb99985ae`，此后只加头注 | 删 8 行 + 头注 2 行；GDD §5.3 同段数字同样过时，需 `[GDD]` 同步（🔴） |
| `…power_skill.tier_3_4_range[0..1]` | 1076 | 1500 / 2500 | M | 同上 | **删** | 同上 | — |
| `…power_skill.tier_5_6_range[0..1]` | 1077 | 2000 / 3000 | M | 同上 | **删** | 同上 | — |
| `…power_skill.tier_7_range[0..1]` | 1078 | 2500 / 3500 | M | 同上 | **删** | 同上 | — |
| `…ultimate.tier_1_2_range[0..1]` | 1080 | 3000 / 4500 | M | 同上 | **删** | 同上 | — |
| `…ultimate.tier_3_4_range[0..1]` | 1081 | 4500 / 6000 | M | 同上 | **删** | 同上 | — |
| `…ultimate.tier_5_6_range[0..1]` | 1082 | 5500 / 7000 | M | 同上 | **删** | 同上 | — |
| `…ultimate.tier_7_range[0..1]` | 1083 | 6500 / 8000 | M | 同上 | **删** | 同上 | — |

**段推荐：删（含 GDD §5.3 同步）**——量测结果否定了「接成 per-tier 红线」的路：按现值接红线会立刻红 38 条，而 skills.yaml 实值是当前生效的生产数字，参考区间自 `fb99985ae` 起一字未改（`git log -S`）。留着一份 76% 不符的「参考」比没有更误导。若用户想保留分阶指引，替代是按实测区间**重写**（🔴 数值拍板），不是原样留。

### E · character（4 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `character.attributes.distribution_mean` | 1105 | 5.5 | M | 5A C-A 头注 | **留** | 值搜 `5.5` lib：仅注释 `§5.5`；`stddev`/`gauss`/`normal` lib 0 命中 → 本仓无属性生成器，18 个角色 def 全静态（头注自述）；`git log -S`：`a27a7ed04 2026-09-18` 加头注 | 头注已有 |
| `character.attributes.distribution_stddev` | 1106 | 1.5 | M | 同上 | **留** | 同上 | — |
| `character.adventure_attribute_bonus.bonus_per_event_min` | 1159 | 1 | M | 头注 UNUSED | **接线（红线型）** | `bonus_per_event` lib/test 0 命中；真值是每条奇遇 outcome 自带的 `attributeDelta`（`encounter_def.dart:55,81` 默认 1；`data/encounters.yaml` 92 处，实值只有 1 和 2）→ 当前全部落在 [1,3] 内，但**没有任何守门**：某天写 `attributeDelta: 5` 也不会红。同段 `distribution/weights` 同样零消费（不在本 59 叶内，扫描器判「疑似间接」） | 在 `encounter_def` 加载期或红线 validator 加 `attributeDelta ∈ [min,max]` 断言（≈10 行 + 1 测）；`weights` 仍为设计参考 |
| `…bonus_per_event_max` | 1160 | 3 | M | 同上 | **接线（红线型）** | 同上 | 同上 |

**段推荐：distribution 两叶留；bonus_per_event 两叶接线（红线型）**——把「设计上限」变成加载期校验，成本一条断言，收益是 encounters.yaml 新增奇遇时不会悄悄越过 GDD §4.1 的 +3。

### F · retreat.time_of_day_bonus（5 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `retreat.time_of_day_bonus[0].time_range[0..1]` | 1392 | "23:00" / "01:00" | M | 头注 UNUSED | **接线** | `time_range`/`timeRange` lib 0 命中；`numbers_config.dart:2924` 只读 multiplier/effect/target_attribute/applies_to_school；同一时段写死 `seclusion_service.dart:797-800 _isZiShi: h == 23 \|\| h == 0`——值当领域词搜到**同门槛 Dart 常量**，与 5A I 段 `yiLiu` 同型 | 解析 `time_range` 为小时对（跨午夜用 `start ≤ h \|\| h < end`），`_isZiShi/_isZhengWu` 改读 config；约 30 行 + 1 个 targeted 测（跨午夜边界 23/0/1）|
| `…[1].time_range[0..1]` | 1396 | "11:00" / "13:00" | M | 同上 | **接线** | 写死 `seclusion_service.dart:804-807 _isZhengWu: h == 11 \|\| h == 12` | 同上 |
| `…[2].time_range` | 1403 | null | M | 同上 | **留**（随接线自然消费：`null` = 其他时段） | — | — |

**段推荐：接线**——头注把它定性为「固定传统时辰、非平衡项」，但 yaml 里已经写着范围、Dart 里又写一遍，两处 drift 无人守；接线后 yaml 成唯一事实源。若用户坚持「时辰不可调」，退而求其次是**删 3 条 `time_range`**（保留 period 注释），不建议维持现状。

### G · inheritance（4 叶）

| key | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `inheritance.unlock_rules.disciple_can_take_grand_disciple_at` | 1531 | jueDing | M | 5A I-A′ 头注 | **留** | `grand_disciple`/`grandDisciple` 值搜：`enums.dart:180 LineageRole.grandDisciple`、`character_panel_screen.dart:518,871` UI 串、`lineage_recruit_red_lines_validator.dart:59`「不允许 grandDisciple（Demo 不做徒孙）」→ 枚举与文案已预埋、功能被红线明禁，无消费点可接；`git log -S`：加入 `fb99985ae`，`13ce2300f 2026-08-07` 注释 | 头注已有 |
| `inheritance.unlock_rules.can_pass_legacy_at` | 1532 | wuSheng | M | 头注 UNUSED | **删** | 值搜 `wuSheng` in ascension：`ascend_service.dart:61 numbers.ascension.requiredRealmTier ?? RealmTier.wuSheng`——活门槛是 `ascension.unlock_triggers.required_realm`；本叶是头注 :1523-1526 自述的「重复声明同一门槛、且本处是死的那份」；`git log -S`：加入 `fb99985ae`，`13ce2300f`、`8d6a00299` 只改注释；GDD 0 引用 key 名 | 删 1 行 + 头注 2 行；`:1532` 长注释里的 Ch19-21 史料迁到 ascension 段或 GDD |
| `inheritance.heritage_items.auto_buff_internal_force_max` | 1548 | 0.05 | M | 头注 UNUSED | **删** | 活值 = `equipment.lineage_heritage.internal_force_max_bonus: 0.05`（:880；`numbers_config.dart:101`、`derived_stats.dart:275` 真读）→ 同值双写、本叶为死副本；`HeritageItems.fromYaml` 只读其余六字段；`git log -S`：加入 `fb99985ae`，后仅 `8d6a00299` 加头注 | 删 1 行 |
| `inheritance.heritage_items.resonance_retention` | 1549 | 0.7 | M | 头注 UNUSED | **删** | 活值 = `equipment.resonance.inheritance_retention: 0.7`（:842；`numbers_config.dart:92,425`、`equipment.dart:138` 真读）→ 同值双写、死副本；证据同上 | 删 1 行 |

**段推荐：三删一留**——三条都是同一门槛/同一数值的死副本，留着的唯一后果是有人改错那一份；`grand_disciple` 留作徒孙功能锚。

### H · validation_examples（20 叶；同段另 46 叶判「疑似间接消费」）

| key（×5 战例） | 行 | 值 | 标 | B2 原判 | 本次 | 证据 | 代价 |
|---|---|---|---|---|---|---|---|
| `example_{a..e}.attacker.cultivation_multiplier` | 1605/1624/1643/1663/1683 | 1.0/1.75/1.3/1.75/3.0 | M | 头注 UNUSED | **接线（测试数据化）** | `validation_examples`/`example_a` lib/test 0 命中；`test/combat/damage_calculator_test.dart:36-75` 五战例**手写** ctx 与期望值（`_ctxA()…`、`expect(r.finalDamage, 826)`），yaml 只在注释被提及；yaml 与测试已经出现漂移（战例 B yaml 注 4889 / 测试 4879，战例 C 1972 / 1995） | 测试改为读 `numbers.raw['validation_examples']` 逐例构 ctx 并断言 ≤5% 误差；≈40 行测试改动，lib 零改；同段 46 叶「疑似间接」一并变真消费 |
| `example_{a..e}.attacker.school_counter` | 1606/1625/1644/1664/1684 | 1.0/1.0/1.0/1.25/1.0 | M | 同上 | **接线（测试数据化）** | 同上 | 同上 |
| `example_c.attacker.realm_diff_modifier` | 1646 | 0.7 | M | 同上 | **接线（测试数据化）** | 测试 `:73 expect(r.realmDiffDefenderMod, 0.7)` 手写同值 | 同上 |
| `example_{a..d}.calculated_damage` | 1612/1631/1651/1670 | 公式串 | M | 同上 | **留** | 手算过程文案，不可消费 | — |
| `example_{a..e}.expected_outcome` | 1613/1632/1652/1671/1691 | 文案 | M | 同上 | **留** | 设计叙述，不可消费 | — |

**段推荐：11 叶接线（测试数据化）、9 叶留**——五战例是 GDD §5 的验收样例，现状是 yaml 一份、测试再抄一份且已漂移；让测试直接吃 yaml，`validation_examples` 从「注释」变成真正的验证样例。

## 3. 段级汇总与回复格式

| 段 | 叶数 | 推荐 | 级别 |
|---|---|---|---|
| A meta | 1 | 删 | 🔴 |
| B combat 开关 | 6 | 删 | 🔴 |
| C equipment | 3 | `success_formula` 接线；2 留（头注令牌）；附 🟡 硬编码 49 微修 | 🟡/🔴 |
| D reference_multipliers | 16 | 删（实测 38/50 越界，附 GDD §5.3 同步） | 🔴 |
| E character | 4 | 2 留；`bonus_per_event_*` 接线（红线型） | 🟡 |
| F time_of_day | 5 | 接线（次选：删 3 条 time_range） | 🟡 |
| G inheritance | 4 | 3 删 1 留 | 🔴 |
| H validation_examples | 20 | 11 接线（测试数据化）9 留 | 🟡 |

合计：删 26 / 接线 18 / 留 15（= 59）。

**回复格式**（按段给字母-动作，未提及的段按本单推荐执行）：`A-删 B-删 C-接线 D-删 E-接线 F-接线 G-删 H-接线`；要偏离推荐写成如 `F-删` / `B-留`。拍板后由协调者拆成实装单（删类合一单、接线按段各一单）。

## 4. `--check` 重锚（目标 3）结论：不适合重锚，不硬改

`tools/audit/numbers_unused_keys_review.py --check` 当前失败原文：`RuntimeError: 审计源相对派单基线变化；需重新人工复核，不能复用本单语义结论`（`build()` :137-139 `git diff --quiet <baseline> -- lib test data GDD.md CLAUDE.md data_schema.md` 非零即抛）。冻结机制有三层，重锚只能解开第一层：
1. 冻结基线常量 `BASELINE = "c64b16593…"` 在 `numbers_key_usage.py:17`（派单包禁改文件），`review.py:142` 要求 `baseline == usage.BASELINE`；
2. `review.py:146-149` 要求当前零引用集合 == B2 原表 `## 零引用逐条表` 的 key 集合（99 叶）；现在是 59 叶，重锚后必然 `候选集合变化` 抛错；
3. `--check` 逐字节比对 B2 报告全文（`:390-392`）。

即 `--check` 锁的是「B2 那一单的语义结论」，设计上就不该跨拍板复用。**替代方案（🟡）**：把 `--check` 明确定性为 B2 历史冻结校验（README 一句话），活的守恒检查改用 `numbers_key_usage.py --baseline <tip> --format json` 的 `counts` 与本单 §1 表对撞；若要二轮也可机器复跑，另写 `numbers_unused_keys_round2.py` 生成本单 §2 表（新工具属 🟡）。

## 5. 未能判定

- D 段 `ultimate` 四组区间未能对照：`skills.yaml` 55 个 `ultimate` 全部无 `tier` 字段（60 个 powerSkill 亦无），只有 50 个 powerSkill 可量；`ultimate` 区间按 powerSkill 同段漂移推定同样过时，但无实测，拍板时按「删 8 组」一并处理或先补 tier 字段再量。
- C 段 `_enhanceLevelCap` 的 49 应读哪张表（`realms` 绝对层数上限 vs `release_cap`）：两者当前同值 49，语义上前者更对，留给微修单确认。

## 6. 独立复核命令

```bash
python3 tools/audit/numbers_key_usage.py --baseline 5d9bbdeaf --format json | python3 -c "import json,sys;d=json.load(sys.stdin);z=[r for r in d['rows'] if r['verdict']=='零引用'];print(len(z),sum(1 for r in z if r['unused_marked']))"   # 期望 59 56
git grep -n -F '0.50 - 0.02' -- lib            # 期望 lib/data/numbers_config.dart:1070
git grep -n -E 'h == 23 \|\| h == 0|h == 11 \|\| h == 12' -- lib   # 期望 seclusion_service.dart:799,806
git grep -n -F 'internal_force_max_bonus' -- lib data/numbers.yaml
git log -S'can_pass_legacy_at' --format='%h %ad %s' --date=short -- data/numbers.yaml
python3 docs/audit/scripts/skills_tier_vs_reference_2026-09-19.py   # D 段量测(仓库根目录运行);期望 violations: 38
```
