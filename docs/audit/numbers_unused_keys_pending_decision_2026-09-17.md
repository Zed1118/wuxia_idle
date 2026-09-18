# numbers.yaml 待拍板路径方案对照（2026-09-17 · B2 复核 5A）

> 输入：`docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md` 「待拍板」23 路径 / 43 叶，加 4A 守卫测试时登记的装备命名奖励越阶 1 项。**全部 🔴 级（删配置字段 / 改 GDD 合同 / 动数值），本文件只列事实与选项，不动任何 yaml 值。** 事实全部本会话实测（行号见各段）。
>
> 用法：按段回「T-A / S-B …」即可；未回复的段保持现状（零引用、已有 ⚠️ UNUSED 段头注）。

## 现状快照（重扫 baseline `07aaa05a2`，`numbers_key_usage.py --baseline`，guard passed）

| 指标 | B2 复核时（链 tip `c64b16593`） | 3A+4A 后 |
|---|---:|---:|
| 零引用 叶 / 归一路径 / 末段 | 202 / 87 / 51 | **99 / 68 / 41** |
| 其中 头注 UNUSED（3A，`unused_marked`） | 0 | 53 叶 |
| 其中 本文件待拍板 | 43 叶 | 43 叶 |
| 保留（有合同）106 叶 | 零引用 | 已脱离零引用（`character.attributes` 四键 `lib/data/numbers_config.dart:680-683` 字面命中；equipment/techniques tiers 由 `test/data/numbers_tier_contract_guard_test.dart` 消费） |

## T · tower 旧段（9 路径 / 29 叶，`data/numbers.yaml:1500-1561`；行号为 3A 头注后现值，审计单 yaml_line 列为 3A 前旧值）

**事实**：段头已有 2026-07-03 ⚠️ UNUSED 注（:1495-1498）。内容是「30 层 / 每天 5 次 / Boss 位 5·10·15·20·25·30 / 6 段难度曲线 / `sync_to_supabase: true`」；生产事实是 `data/towers.yaml` 49 层（`floorIndex` 计 49）、Boss 位 14 个（`towers.yaml:20`）、GDD §8.2 明文「不做"每天 5 次"自然日挑战次数」（`GDD.md:606`）、「当前本地榜；云同步为未来方向」（`GDD.md:607`），排行榜 `LeaderboardSyncService` 为 Noop、0 Supabase 包。即：该段 9 路径中 8 路径与现行 GDD/生产**正面冲突**，`daily_attempts` 若实装还触 §5.1 反主流红线。

| 选项 | 一句话 | 代价 |
|---|---|---|
| **T-A（推荐）** | 整段删除，段头留 3 行「历史 30 层设计 → 见 towers.yaml / GDD §8.2」指针，`numbers_unused_keys_review.py --check` 冻结报告随之改判 | 删 29 叶（🔴）；无 lib/test 读方，零行为影响 |
| T-B | 保留并把 8 条冲突值改成现行事实（49 层、14 Boss 位、`sync_to_supabase: false`） | 仍零消费，只是把「错的死数据」改成「对的死数据」，下次审计再来一遍 |
| T-C | 维持现状（已有段头注） | 每次 B 类审计都要重新证明它不生效 |

## S · synergies 旧段（10 路径 / 10 叶，`data/numbers.yaml:1644-1668`）

**事实**：段头已有 2026-07-03 ⚠️ UNUSED 注（:1638-1641），明示真实数据源为 `data/synergies.yaml`（12 条、multipliers 格式，`game_repository.dart:373` 解析）。此段 5 组 `effect_values`（阴阳调和 / 丐帮传承 / 少林正宗 / 武当圆融 / 华山合璧）与 GDD §4.5 表（`GDD.md:278-282`）同源；但 `synergies.yaml` 12 条中只有「阴阳调和」同名，其余 4 组所依赖的心法（九阳/九阴/降龙十八掌/打狗棒/易筋经/太极/紫霞）不是本仓心法体系。即：**冲突的主从不是 numbers 段 vs synergies.yaml，而是 GDD §4.5 示例表 vs 生产。**

| 选项 | 一句话 | 代价 |
|---|---|---|
| **S-A（推荐）** | 删 numbers 段 10 叶 + GDD §4.5 表改为「生产 12 组见 synergies.yaml」并把现 5 行降为「早期示例（未实装）」 | 🔴 删字段 + `[GDD]` 改动；零行为影响 |
| S-B | 只删 numbers 段，GDD 表不动 | GDD 继续承诺 4 个不存在的组合 |
| S-C | 维持现状 | 同 T-C |

## C · character.attributes 分布参数（2 路径 / 2 叶，`data/numbers.yaml:1097-1098`）

**事实**：`distribution_mean: 5.5` / `distribution_stddev: 1.5` 描述 GDD §4.1「按正态分布生成」（`GDD.md:209`）；本仓 18 个角色 def 为手写静态 profile，lib 无任何生成器（4A 已核：唯一消费属性区间的是校验器）。同段 `rarity_distribution.probability` 列 2026-08-08 已拍板「静态 profile 不受概率表约束，仅作未来程序化生成指引保留」（`lib/data/numbers_config.dart:232-236` 注）。

| 选项 | 一句话 | 代价 |
|---|---|---|
| **C-A（推荐）** | 与 probability 列同口径：两键保留，加 `# UNUSED(设计指引·无生成器)` 头注（与 3A 同格式），并入 `unused_marked` | 🟢 只加注释；下次 B 类审计自动归「已标注」 |
| C-B | 删除两键，GDD §4.1 「正态分布」句改为「静态资质表」 | 🔴 + `[GDD]`；关掉未来程序化生成的门 |
| C-C | 实装生成器消费之 | 无产品需求（18 角色全手写），不推荐 |

## I · inheritance.unlock_rules 收徒门槛（2 路径 / 2 叶，`data/numbers.yaml:1588-1589`）

**事实**：`can_take_disciple_at: yiLiu` / `disciple_can_take_grand_disciple_at: jueDing` 对应 GDD §7.1「一流可收徒 / 绝顶可收徒孙」（`GDD.md:503-504`）；实装的收徒是一次性剧情事件（`lib/features/recruitment/application/recruitment_service.dart` 走 `SaveData.recruitmentOffered`，段内 2026-08-07 注已写明「完全没有境界门禁」，`numbers.yaml:1577-1586`）。`data/recruit_candidates.yaml:2` 头注仍引用此键作依据。同块第 3 键 `can_pass_legacy_at` 已在 3A 头注（活配置在 `ascension.unlock_triggers`）。

| 选项 | 一句话 | 代价 |
|---|---|---|
| **I-A（推荐）** | 把「一流可收徒」从死配置变成守卫：`enforceRecruitCandidateRedLines` 读此键，断言收徒事件所在关卡（`lineage_onboarding.disciple_joins` 的 stage）对应境界 ≥ `can_take_disciple_at`；`grand_disciple` 键同法挂到二代收徒事件，若无二代事件则头注 UNUSED | 🟡 新增校验（不改数值）；需先量现有收徒关卡境界是否满足，不满足即回到拍板 |
| I-B | 两键删除 + GDD §7.1 表两行改为「收徒 = 剧情事件（第 N 章）」+ `recruit_candidates.yaml:2` 头注同改 | 🔴 + `[GDD]` |
| I-C | 头注 UNUSED（与 can_pass_legacy_at 同处理） | 🟢；GDD 与生产继续分叉 |

## E · 装备命名奖励越阶（4A 守卫新登记 · 3 件，`data/equipment.yaml` 断魂庄三选一段）

**事实**：`weapon_haojiahuo_suo_mai_nang` attack 360–490（好家伙武器区间 320–450）、`armor_haojiahuo_zhen_yue_tie_yi` hp 640–800（450–750）、`accessory_haojiahuo_she_hun_ling` attack 130–190 / hp 280–400 / speed 18–30（100–160 / 200–350 / 10–25），均由 commit `10297311d`（2026-07-19「数值锚好家伙(二流)阶顶守全局 attack≤2000」）有意写入作为「命名奖励溢价」；武器 attack 上界 490 落在好家伙 450 与利器下界 480 之间，不属任一单阶区间。80/83 其余装备全部在阶。4A 守卫以白名单钉包络「≥ 本阶 min、≤ 下一阶 max」，防溢价再涨。

| 选项 | 一句话 | 代价 |
|---|---|---|
| **E-A（推荐）** | 承认「命名奖励溢价」为规则：`equipment.tiers` 段头加一句「命名奖励可越本阶上界、不得越下一阶上界」，白名单转为 yaml 字段（如 `namedReward: true`）由守卫读取，不再硬编码 3 个 id | 🟡 加一个布尔字段 + 守卫改读；数值不动 |
| E-B | 三件拉回好家伙区间 | 🔴 `[balance]`，断魂庄首通奖励手感变弱 |
| E-C | 三件改标 liQi 阶 | 🔴 触三系锁死（二流境界拿到利器不可装备），不推荐 |

## 回复格式

`T-A S-A C-A I-A E-A`（推荐全选）或逐段改；I-A 执行前我会先量收徒关卡境界并回报，不满足再退 I-B/I-C。

## 拍板结果（2026-09-18 用户「按推荐执行」）

| 段 | 拍板 | 落地 commit | 结果 |
|---|---|---|---|
| T | T-A | `583e54f99` | `tower:` 29 叶整段删除，段头留指针；`leaderboard_sync_service.dart` 两处注释不再引用已删键。lib/test 零残留引用。 |
| S | S-A | `49cf33494` | `synergies.effect_values` 10 叶删除；GDD 升 v1.77，§4.5 改为 `synergies.yaml` 12 组口径，原 5 行降为早期示例。 |
| C | C-A | `a27a7ed04` | `distribution_mean/stddev` 加 UNUSED 头注，`numbers_key_usage.py` 实测两键 `unused_marked=true`。 |
| E | E-A | `ffd6167e0` | `EquipmentDef.isNamedReward`（缺省 false，不进 Isar）；三件标 true；`equipment.tiers` 段头 + `data_schema.md §5.1` 明文规则；守卫删硬编码 id 集改读字段，新增「神物阶不得标记」断言。四向 mutation（摘标记 / 普通件标 true / 神物标 true / 神物越阶+标 true）各精确 1 条失败并还原。 |
| I | I-A′（用户「继续推进」取推荐） | `bc6cb8b8b` | `NumbersConfig.canTakeDiscipleAt`（必填、非法名 fail-fast）；`TutorialService.advanceForRealmBreakthrough` 改 `required threshold`，闭关升层/战斗结算两处生产调用方传 `numbers.canTakeDiscipleAt`；值 yiLiu 不变、行为 0 变。tutorial 测试改从生产配置取阈值 + 阈值参数化用例；新增源码契约测试（不写死 yiLiu / 两调用方接线 / 解析与 yaml 一致）。`grand_disciple` 键头注 UNUSED。四向 mutation（hook 回写死 yiLiu / 调用方传常量 / yaml 删键 / yaml 非法名）各红并还原。 |

重扫（`numbers_key_usage.py --baseline HEAD`，C-A 后）：零引用 99 叶 → **60 叶**（= 99 − 29 tower − 10 synergies，守恒），其中已标注 57、未标注 3（`equipment.enhancement.max_level_formula` / `success_curve[4].success_formula` / `equipment.resonance.new_owner_retention`，均为 B2 审计单原「保留理由」行，不在 5A 范围）。

### I 段：前置量测不满足 + 新事实，需重新拍板

**量测**：`lineage_onboarding.disciple_joins` 两条均在 `stage_06_05`（`numbers.yaml` lineage_onboarding 段），该关 `requiredRealm: sanLiu`（`data/stages.yaml:1509`）；主线 `requiredRealm` 梯度为每 3 章一阶（Ch1–3 xueTu / Ch4–6 sanLiu / Ch7–9 erLiu / Ch10–12 yiLiu …），`yiLiu` 首见于 Ch10。即命名弟子拜入（Ch6 终局）比 `can_take_disciple_at: yiLiu` 早两阶，**I-A 原形状「断言拜入关境界 ≥ 一流」对现行生产必红**，按对照单约定不执行。

**新事实（2026-08-07 注「完全没有境界门禁」不准确）**：`recruit_candidates`（云寒青/柳拂陻/马智远）这条收徒路径的入口是 tutorial step 6 banner → `RecruitmentDialog`（`lib/features/recruitment/application/recruitment_providers.dart:19-22`），而 step 6 由 `TutorialService.advanceForRealmBreakthrough` 推进，**硬编码 `RealmTier.yiLiu`**（`lib/features/tutorial/application/tutorial_service.dart:100`；调用方 `seclusion_service.dart:620` 与 `combat_progression_settlement_service.dart:123`）。也就是说「一流可收徒」在生产里是**真门禁**，只是门禁值写死在 Dart 里、没读 numbers.yaml。2026-08-07 的注只看了 `recruitment_service.dart`。

| 选项 | 一句话 | 代价 |
|---|---|---|
| **I-A′（推荐）** | `can_take_disciple_at` 接入生产：`TutorialService.advanceForRealmBreakthrough` 改读 `NumbersConfig`（新增 `inheritance.unlockRules.canTakeDiscipleAt` 解析），`RealmTier.yiLiu` 硬编码退役；现有 3 条 tutorial 测试改从配置取阈值；`disciple_can_take_grand_disciple_at` 无二代收徒事件 → 头注 UNUSED；numbers.yaml 2026-08-07 注改写为「命名弟子拜入=剧情事件（Ch6）无门禁；候选收徒=tutorial step 6 一流门禁，读本键」 | 🟡 lib 改动（值 yiLiu→yiLiu 不变，行为 0 变）；消除 CLAUDE.md §5.6「Dart 不写数值常量」的一处存量违例 |
| I-A″ | I-A′ + 同时把 `disciple_joins` 关卡境界也纳入本键守卫（即把命名弟子拜入推迟到 ≥ 一流关，Ch10+） | 🔴 改玩法节奏（2026-06-27 spec A 拍板「终局 Ch6 一并拜入」被推翻），不推荐 |
| I-B | 两键删除 + GDD §7.1 改「收徒=剧情事件」 | 🔴 + `[GDD]`；但与 tutorial step 6 真门禁矛盾，**基于错误前提，不再推荐** |
| I-C | 头注 UNUSED | 🟢；继续让 Dart 硬编码与 yaml 死键并存 |

**已按 I-A′ 落地（`bc6cb8b8b`，见上表）。五段全部闭环。**

