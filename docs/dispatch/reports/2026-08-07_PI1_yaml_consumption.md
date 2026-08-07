# REPORT_PI1 · data/ yaml 配置字段消费情况扫描

- **性质**:只读扫描 + 报告,零代码改动(试跑单 PI1)
- **时间**:2026-08-07
- **基线**:branch `pi/trial-yaml-audit` @ `75730b70`(worktree 干净)
- **范围**:`data/` 全部 668 个 .yaml 的**顶层 + 二级字段名** × `lib/` grep 消费

---

## 一、扫描范围统计

| 指标 | 数值 |
|---|---|
| 扫描 yaml 文件数 | 668(data/ 递归全量,含 `_archive/`、`_templates/`) |
| 唯一字段名(去重) | 361 |
| 字段-文件对数(去重前) | 3,137 |
| lib/ 有 grep 命中 | 336 个字段名(92.0%) |
| **lib/ 零命中(疑似未消费)** | **25 个字段名** |
| yaml 解析失败文件 | 0 |

消费载体核对:`lib/data/numbers_config.dart` 等 `fromYaml` 以 `y['字段名']` 字面量取值
(例:`lib/data/defs/item_def.dart:48`),grep 字段名字面量可覆盖主消费路径。

## 二、方法说明

1. **提取**:python3 `yaml.safe_load_all` 解析每个文件;一级 = 根 map key;
   二级 = 根 value 为 dict 时取其 key、为 list 时取 list 元素 dict 的 key
   (例:`enemy_teams:` → `gauntlet_su_wujiu`;`stages:` 列表元素 → `role`/`enemy_team_id`)。
   取到二级为止,不深入第三层(嵌套 key 如 `combat.max_hp_formula.internal_force_factor`
   只算到 `max_hp_formula`)。
2. **grep**:`grep -row`(词边界、大小写敏感、逐匹配计数)+ `grep -rnw -m 1` 取首个消费点,范围仅 `lib/`。
3. **bundle 核对**:`pubspec.yaml:55-68` 逐个声明 data 子目录,`data/narratives/_archive/`、
   `data/events/_archive/`、`data/lore/_archive/` **未声明 → 不进 asset bundle → lib 端永不加载**。
4. 零命中字段全部经人工二次核实(出现文件、行号、上下文字面证据,见下表)。

## 三、疑似未消费字段清单(grep 命中数 = 0)

### 3.1 numbers.yaml 文档/废弃/未接线段(16 个字段名)

| yaml 文件 | 字段 | grep 命中数 | 上下文证据(文件内自证) |
|---|---|---|---|
| data/numbers.yaml:31 | `last_updated` | 0 | `meta` 元数据;NumbersConfig 只消费 `meta.version` |
| data/numbers.yaml:32 | `notes` | 0 | 同上,`meta` 元数据 |
| data/numbers.yaml:109 | `final_damage_formula` | 0 | 头注 107-108 自证:「NumbersConfig 不解析此块…改 true→false 不生效,勿误用」 |
| data/numbers.yaml:904 | `reference_multipliers` | 0 | 注释自证:「用于 SkillDef.powerMultiplier 字段配置时的指导值」(纯文档) |
| data/numbers.yaml:942 | `rarity_distribution` | 0 | 6 档稀有度概率;lib 收徒处固定 `RarityTier.biaoZhun`(`recruitment_service.dart:99`) |
| data/numbers.yaml:1319 | `daily_attempts` | 0 | tower 段;1311-1314 自证 UNUSED:「每日 5 次限制未实装」 |
| data/numbers.yaml:1320 | `refresh_at` | 0 | 同上,「UNUSED…保留作 GDD §8.2 设计锚」 |
| data/numbers.yaml:1330 | `difficulty_curve` | 0 | 同上 |
| data/numbers.yaml:1363 | `boss_layers` | 0 | 同上 |
| data/numbers.yaml:1389 | `unlock_rules` | 0 | inheritance 段(收徒/传位解锁节奏);注意 `recruit_candidates.yaml` 头注引用了它,但 lib 零命中 |
| data/numbers.yaml:1444 | `effect_values` | 0 | synergies 段;1438-1440 自证 UNUSED:「真实数据源是 data/synergies.yaml…此处 5 条为历史残留」 |
| data/numbers.yaml:1481 | `example_a` | 0 | `validation_examples` 段;仅 `test/combat/damage_calculator_test.dart:17` 注释引用(test 手算对照,非 lib 消费) |
| data/numbers.yaml | `example_b` | 0 | 同上 |
| data/numbers.yaml | `example_c` | 0 | 同上 |
| data/numbers.yaml | `example_d` | 0 | 同上 |
| data/numbers.yaml | `example_e` | 0 | 同上 |

### 3.2 boss_gauntlets.yaml 敌队 id 型 key(3 个字段名)——grep 假阴样板

| yaml 文件 | 字段 | grep 命中数 | 上下文证据 |
|---|---|---|---|
| data/boss_gauntlets.yaml:35 | `gauntlet_su_wujiu` | 0(字段名) | `enemy_teams` map 的 key;被 `stages[].enemy_team_id` **值引用**(12-14 行),lib 侧 `boss_gauntlet_config.dart:62` 读 `enemy_team_id`、`:53` `enemyTeams[teamId]` 动态查表(循环 `rawTeams.entries` 在 `:66-68`)→ **消费链路成立,但字段名不在 lib 字面出现** |
| data/boss_gauntlets.yaml:80 | `gauntlet_shi_zhenyue` | 0(字段名) | 同上(值字符串 `enemy_gauntlet_shi_zhenyue.png` 见 `wuxia_tokens.dart:335`) |
| data/boss_gauntlets.yaml:126 | `gauntlet_wen_jiuzhen` | 0(字段名) | 同上 |

### 3.3 lore 写作模板字段(3 个字段名 × 7 个文件)

| yaml 文件 | 字段 | grep 命中数 | 说明 |
|---|---|---|---|
| data/lore/_templates/*.yaml(7 文件) | `template_id` | 0 | 写作模板元数据,非运行配置 |
| data/lore/_templates/*.yaml(7 文件) | `trigger_event` | 0 | 同上 |
| data/lore/_templates/*.yaml(7 文件) | `placeholders` | 0 | 同上 |

### 3.4 已归档文案字段(3 个字段名)——不进 bundle,零消费为预期

| yaml 文件 | 字段 | grep 命中数 | 说明 |
|---|---|---|---|
| data/narratives/_archive/techniques/*.yaml(26 文件) | `moves` | 0 | `_archive` 目录未在 pubspec 声明 → 不进 asset bundle → lib 永不加载 |
| data/narratives/_archive/techniques/insights/*.yaml(40 文件) | `prerequisite_hint` | 0 | 同上 |
| data/narratives/_archive/techniques/*.yaml(7 文件) | `mantra` | 0 | 同上 |

> 注:lib/ 零命中字段**无一是非 ASCII / 非词字符 key**,全部可正常 grep。

## 四、局限声明(必读)

1. **grep 假阴(疑似 ≠ 未消费)**:消费可能走动态 key / 值引用 / 字符串拼接,字段名不
   以字面量出现在 lib/。§3.2 的 3 个敌队 key 即为实锤假阴——字段名零命中但消费链路完整
   (`enemy_team_id` 值 → map 查表)。其余零命中字段不排除同类情况。
2. **raw 整表保留**:`NumbersConfig.raw` 持有 numbers.yaml 全量 map(`numbers_config.dart`),
   但 lib 侧 `raw[` 取值仅 1 处(`milestone_equipment_grants`,非本表字段);本表字段无 raw 读取。
3. **grep 范围仅 lib/**:`validation_examples` 被 `test/` 注释引用,不算 lib 消费;
   若以「全仓消费」口径,该组字段应另行评估。
4. **假阳方向**:有命中的 336 个字段名未逐个人工核验,可能存在「仅注释/文档提及」的消费;
   本报告只保证零命中清单的完整性,不保证命中清单的纯度。
5. **§3.1 标注「UNUSED」为 yaml 自身注释原话引用,非本扫描结论**;字段是否真废弃
   需以运行时行为为准,不在本单权限内(本单只读)。

## 五、存疑/待人工确认点

- `rarity_distribution`(6 档概率):lib 侧收徒固定 `RarityTier.biaoZhun`,
  enum `RarityTier.yongCai` 存在于 `lib/core/domain/enums.dart:151`——概率分布
  是否存在其他实现路径(如 sect 招募),未在本单确认。
- `unlock_rules`:yaml 内被 `recruit_candidates.yaml` 头注引用,lib 零命中;
  收徒/传位门槛的实际判断路径未追踪。
- `_templates` 已声明进 bundle(与 `_archive` 不同),但确认无 loader 按文件枚举加载;
  模板是否属「写作辅助、永不加载」由项目口径定,非本单结论。
