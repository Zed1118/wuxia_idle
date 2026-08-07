# REPORT_Q1 · PI1 疑似未消费字段深核(25 项)

- **性质**:只读深核 + 报告,零代码改动(试跑单 Q1)
- **时间**:2026-08-07
- **基线**:branch `qoder/trial-field-verify`(worktree `.claude/worktrees/qoder-verify`,git status 干净)
- **上游**:`docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md` §三(25 个 lib/ grep 零命中字段)

## 一、深核方法(针对 grep 假阴)

逐字段排查四类非字面量消费路径:

1. **raw 整表取值**:全 lib 扫 `raw[` / `.raw`,`NumbersConfig.raw` 唯一取值点为
   `lib/data/numbers_config.dart:310`(`milestone_equipment_grants`,不在本表)→ numbers.yaml
   16 个字段均无 raw 旁路。
2. **动态 key / map 遍历**:逐个 loader 核对 `entries` / `keys` 循环(命中 1 处:
   `boss_gauntlet_config.dart:66-73` 遍历 `enemy_teams` 全部 key,见 §二 假阴组)。
3. **泛型 fromYaml 整段读入**:numbers.yaml 强类型入口 `NumbersConfig.fromYaml`
   (`numbers_config.dart:315`)只解析 meta/combat/realms/equipment/techniques 等段,
   `tower:` / `synergies:` / `validation_examples:` / `inheritance.unlock_rules` 均不进解析。
4. **asset 枚举加载**:lib/ 无 `AssetManifest` / 目录枚举式加载;lore/narratives 全为
   单一路径按需 load(`lore_loader.dart:107` 等)→ `_templates` 文件虽进 bundle 但无 loader。

## 二、逐字段判定表(25/25)

判定三态:**真未消费** = lib 无任何运行时消费;**假阴** = 消费链路成立(附 file:line);
**存疑** = 证据不足。本批无存疑项。

### 2.1 numbers.yaml 段(16 项 · 全部真未消费)

| # | 字段 | 所在 yaml | 判定 | 一句话依据 |
|---|---|---|---|---|
| 1 | `last_updated` | numbers.yaml:31(meta) | 真未消费 | `NumbersConfig.fromYaml` 只取 `meta['version']`(`numbers_config.dart:316,323`),meta 其余 key 无读取 |
| 2 | `notes` | numbers.yaml:32(meta) | 真未消费 | 同上;lib 内 `\bnotes\b` 零命中(`event_notes` 为另一字段,子串不算) |
| 3 | `final_damage_formula` | numbers.yaml:109 | 真未消费 | yaml 头注(:107-108)自证纯文档;damage_calculator 恒应用全部乘子,无 flag 读取;raw 旁路仅 :310 一处非本字段 |
| 4 | `reference_multipliers` | numbers.yaml:904 | 真未消费 | skills 段设计参考表(yaml :902-903 自证「配置时的指导值」);`y['skills']` 未被 NumbersConfig 解析 |
| 5 | `rarity_distribution` | numbers.yaml:942 | 真未消费 | lib 全部 RarityTier 赋值硬编码(`recruitment_service.dart:99`、`sect_recruit_handler.dart:110`、`master_builder.dart:53` 均 biaoZhun),无概率解析;**上游 §五 存疑点已闭合:sect 招募亦固定 biaoZhun,无替代概率路径** |
| 6 | `daily_attempts` | numbers.yaml:1319 | 真未消费 | `tower:` 整段不进 `NumbersConfig.fromYaml`(无 `y['tower']` 取值);yaml :1311-1314 注释自证 UNUSED;每日次数限制未实装 |
| 7 | `refresh_at` | numbers.yaml:1320 | 真未消费 | 同上(tower 段整段未解析) |
| 8 | `difficulty_curve` | numbers.yaml:1330 | 真未消费 | 同上;爬塔实际层定义/难度走独立文件 towers.yaml(`main_menu.dart:707`、`tower_progress_service.dart:85` 注释口径) |
| 9 | `boss_layers` | numbers.yaml:1363 | 真未消费 | 同上(tower 段整段未解析) |
| 10 | `unlock_rules` | numbers.yaml:1389(inheritance) | 真未消费 | NumbersConfig 解析 inheritance 仅取 `founder_ancestor_buff`(`numbers_config.dart:399`)与 `heritage_items`(:404);收徒门槛走 recruitmentOffered 事件流(`recruitment_service.dart:79,172`),飞升门槛走 ascend_service 固定条件,均不读本字段 |
| 11 | `effect_values` | numbers.yaml:1444(synergies) | 真未消费 | `synergies:` 段不进解析;真实数据源 data/synergies.yaml(`game_repository.dart:375-379`);yaml :1438-1440 自证历史残留 |
| 12 | `example_a` | numbers.yaml:1481(validation_examples) | 真未消费 | 段不进解析;lib/data/validation/ 全部是已解析配置对象的红线校验器,不读 yaml 战例;仅 `test/combat/damage_calculator_test.dart:16-17` 注释提及(对照值测试内手写,非 yaml 加载) |
| 13 | `example_b` | numbers.yaml(validation_examples) | 真未消费 | 同 example_a |
| 14 | `example_c` | numbers.yaml(validation_examples) | 真未消费 | 同 example_a |
| 15 | `example_d` | numbers.yaml(validation_examples) | 真未消费 | 同 example_a |
| 16 | `example_e` | numbers.yaml(validation_examples) | 真未消费 | 同 example_a(战例 E 无 calculated_damage,test 单列压力测试) |

### 2.2 boss_gauntlets.yaml 敌队 id key(3 项 · 全部假阴)

| # | 字段 | 所在 yaml | 判定 | 一句话依据(消费链路 file:line) |
|---|---|---|---|---|
| 17 | `gauntlet_su_wujiu` | boss_gauntlets.yaml:35 | **假阴** | `boss_gauntlet_config.dart:66-73` 遍历 `enemy_teams` 全部 key 解析为 EnemyDef;`data/boss_gauntlets.yaml:12` 以 `enemy_team_id` 值引用;`:62` 读引用、`:52-53` 动态查表;运行端 `gauntlet_loadout_screen.dart:233,469` 消费,加载校验 `game_repository.dart:1092,1100` |
| 18 | `gauntlet_shi_zhenyue` | boss_gauntlets.yaml:80 | **假阴** | 同上链路(`data/boss_gauntlets.yaml:13` 引用);立绘 token `wuxia_tokens.dart:335` / `character_avatar.dart:1357` 另有硬编码映射 |
| 19 | `gauntlet_wen_jiuzhen` | boss_gauntlets.yaml:126 | **假阴** | 同上链路(`data/boss_gauntlets.yaml:14` 引用) |

### 2.3 lore 写作模板(3 项 · 全部真未消费)

| # | 字段 | 所在 yaml | 判定 | 一句话依据 |
|---|---|---|---|---|
| 20 | `template_id` | data/lore/_templates/*.yaml(7 文件) | 真未消费 | lib 零命中;lore 加载仅 `data/lore/$loreId.yaml`(`lore_loader.dart:107`)与 `data/lore/sect_event/…`(`sect_event_dialog.dart:57`)两条路径,`_templates/` 无 loader;虽声明进 bundle(`pubspec.yaml:59`)但无代码加载(无 asset 枚举路径) |
| 21 | `trigger_event` | 同上 | 真未消费 | 同上 |
| 22 | `placeholders` | 同上 | 真未消费 | 同上 |

### 2.4 已归档文案(3 项 · 全部真未消费,不进 bundle 为预期)

| # | 字段 | 所在 yaml | 判定 | 一句话依据 |
|---|---|---|---|---|
| 23 | `moves` | data/narratives/_archive/techniques/*.yaml(26 文件) | 真未消费 | `_archive` 目录未在 pubspec assets 声明(已复核 pubspec 无 `_archive` 条目)→ 不进 asset bundle → rootBundle 永不加载 |
| 24 | `prerequisite_hint` | data/narratives/_archive/techniques/insights/*.yaml(40 文件) | 真未消费 | 同上 |
| 25 | `mantra` | data/narratives/_archive/techniques/*.yaml(7 文件) | 真未消费 | 同上 |

## 三、汇总

| 判定 | 数量 | 字段 |
|---|---|---|
| 真未消费 | 22 | §2.1 全部 16 项 + §2.3 模板 3 项 + §2.4 归档 3 项 |
| 假阴(消费链路成立) | 3 | `gauntlet_su_wujiu` / `gauntlet_shi_zhenyue` / `gauntlet_wen_jiuzhen` |
| 存疑 | 0 | — |

上游报告 §五 两个存疑点处置:
- `rarity_distribution`:已闭合——全 lib RarityTier 赋值点逐一核对,均为硬编码枚举值,无概率分布消费路径。
- `unlock_rules`:已闭合——收徒/飞升门槛实际判断路径已追踪(§二 #10),均不读该 yaml 段。
- `_templates` 口径:技术结论 = 进 bundle 但无 loader,永不加载;「写作辅助、永不加载」是否符合项目设计意图,仍属项目口径问题,不在本单判定范围。

## 四、局限声明

1. 判定口径 = **lib/ 运行时消费**。`example_a..e` 在 test/ 被注释性引用(对照值手写于测试内,
   非加载 yaml),若按「全仓含 test 口径」需另评。
2. 「真未消费」指该字段值不参与任何运行时行为;其中多项为 yaml 注释自证的**有意保留**
   (设计锚/纯文档/元数据),真未消费 ≠ 应删除——删除与否需拍板,不在本单权限。
3. 假阴组 3 项的字段名(敌队 id)虽不以字面量出现在 lib/,但作为 map key 被整体遍历解析,
   属完整消费;后续同类「值引用型 key」扫描建议以 yaml 内交叉引用(值 → map key)补强。
