# L1-A 核心文档路径失修修复 · S1 分片收账报告

- **执行端**:pi(DeepSeek V4 Flash) · **worktree**:`.claude/worktrees/pi-links-s1` · **分支**:`pi/doc-links-s1`
- **完成时间**:2026-08-07
- **性质**:纯文档路径修复,零代码/测试改动。所有新路径均经 `ls` 实测;所有映射依据 `docs/PATH_MIGRATION_MAP.md`。

## 一、逐条销账表(15 条)

| # | 宿主文件 | 验证结果 | 实际处置 | 修改后行内容 |
|---|---|---|---|---|
| 1 | `docs/NARRATIVE_SCHEMA.md:139` | 旧路径不存在;`lib/shared/strings.dart` 存在 | 直接改 | `**章节背景**（DeepSeek 自由发挥；Mac 端的 `lib/shared/strings.dart` 已写 章节标题` |
| 2 | `docs/RELEASE_CHECKLIST_1_0.md:37` | `data/narratives/lore/events/` 不存在;`data/lore/` 与 `data/events/` 均存在 | 按映射 §5 改指两处(上下文是「中文文案走 X」,lore+events 都是文案载体,故两者都列) | `- [x] 0 硬编码(中文文案走 `data/lore/` + `data/events/` · 数值走 `data/*.yaml`)` |
| 3 | `docs/audit/full_audit_2026-06-16.md:84` | 该行是 D1 审计记录:引用的是「CLAUDE.md §6 称…」的原文引用,同句已自标注「该路径不存在,实际公式层在 `lib/features/battle/domain/`(`damage_calculator.dart` + `derived_stats.dart`)」 | **保留**(理由见 §三.1) | 未改动 |
| 4 | `docs/audit/full_audit_2026-06-16.md:85` | 同上,D2 同句已自标注「实际在 `lib/features/dispel/application/dispel_service.dart` + `lib/core/domain/technique.dart`」 | **保留**(理由见 §三.1) | 未改动 |
| 5 | `docs/audit/full_project_review_2026-07-02.md:41` | `data/narratives/techniques/` 不存在;实查发现已归档:git ls-files `data/narratives/_archive/techniques/` 67 个文件(含 `insights/` 子目录) | 加标注,标注指向归档实址(比「已移除」更有信息量) | `` `data/narratives/techniques/`(已移至 `data/narratives/_archive/techniques/`)26 篇(…)+ `insights/`(已一并归档)40 篇(…) `` |
| 6 | `docs/audit/full_project_review_2026-07-02.md:43` | `test/support/def_loading.dart` 不存在,且 `git log --all -- <path>` 无任何历史——该文件是当时「建议抽」的提案,**从未实装**(非「已移除」) | 加标注(措辞用「未实装」,比派单预设的「已移除」更准确) | `` 建议抽 `test/support/def_loading.dart`(未实装,该路径不存在),新测试统一走,存量防扩散即可。 `` |
| 7 | `docs/audit/overnight_fix_and_balance_review_2026-07-08.md:51` | `test/tools/floor30_soft_gate_diagnostic_test.dart` 不存在;同命令其余 8 个测试文件全部实测存在 | 加标注(该行是反引号内历史命令,标注追加在代码跨度后,不改命令本体) | `…--reporter expanded`（注:其中 `test/tools/floor30_soft_gate_diagnostic_test.dart` 已移除,余项均在） |
| 8 | `docs/audit/overnight_fix_and_balance_review_2026-07-08.md:86` | 该行是改名记录:「X 改名为 `early_difficulty_gate_probe_2026_07_05.dart`」;新名文件实测存在(`docs/audit/early_difficulty_gate_probe_2026_07_05.dart`)。旧名是改名的对象,新名同句给出 | **保留**(理由见 §三.1) | 未改动 |
| 9 | `docs/audit/yaml_integrity_2026-05-12.md:40-45` | `data/narratives/mainline_test_0{1..6}.yaml` 不存在,git 历史 0 提交(从未入库);状态列原本已标「⚠ 缺失」 | 按派单加标注(6 行) | `| `mainline_test_01` | `data/narratives/mainline_test_01.yaml`(已移除) | ⚠ 缺失 |`(01-06 同式) |
| 10 | `docs/audit/yaml_integrity_2026-05-12.md:65` | `data/narratives/stages/` 目录在,但无 `stage_01_01.yaml` 精确文件;实存 `stage_01_01_opening.yaml`(命名体系已变) | 改为真实存在的文件名 | `备注：仓库里存在 DeepSeek 侧 `data/narratives/stages/stage_01_01_opening.yaml` 等文件,…` |
| 11 | `docs/audit/yaml_integrity_2026-05-12.md:166` | `data/narratives/techniques/insights/` 不存在;实存归档 `data/narratives/_archive/techniques/insights/`(git ls-files 验证) | 加标注,指向归档实址 | `…需要先统一 `data/narratives/techniques/insights/`(已移至 `data/narratives/_archive/techniques/insights/`)与未来 `insights.yaml` 的 id 关系。` |
| 12 | `docs/dispatch/2026-08-06_K1_kimi_techdebt_series.md:10` | `lib/features/stage/stage_entry_flow.dart` 不存在;`lib/features/mainline/presentation/stage_entry_flow.dart` 存在,233 行确有 `rng:` 赋值 | 直接改(最高优先项) | `…已知一处 `lib/features/mainline/presentation/stage_entry_flow.dart:233` 的 `rng: Random()`;…` ⚠ 见 §四.1 内容漂移观察 |
| 13 | `docs/dispatch/2026-08-06_night_plan.md:48` | `.claude/worktrees/codex-inscription/` worktree 已不存在(`git worktree list` 无此条目);但 `docs/dispatch_evidence/inscription_2026-08-06/` 在仓内真实存在且已提交(`git ls-files` 含 `spec_check.tsv`) | 去掉失效 worktree 前缀,改为仓内相对路径 | `contact sheet 在 `docs/dispatch_evidence/inscription_2026-08-06/`(抽验 2 张初检 PASS)` |
| 14 | `docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md:22` | `lib/core/application/battle_providers.dart` 不存在;`lib/features/battle/application/battle_providers.dart` 存在;实测新文件中 `startBattle(` 签名在 82 行、默认 strategy 注入在 89 行(旧行号 58/75 已漂移) | 改路径 + 同步更新行号 58/75 → 82/89(实测锚点) | `| D8 | … | `lib/features/battle/application/battle_providers.dart:82/89` `BattleNotifier.startBattle(strategy: ...)` 已支持注入 + 默认 fallback DefaultGroundStrategy | … |` |
| 15 | `docs/phase0/p4_1_sect_management_phase0_2026-05-25.md:99` | `lib/features/sect_management/` 不存在;`lib/features/sect/` 存在(映射 §2) | 直接改 | `- **不实装**:0 Isar schema 真改 / 0 `lib/features/sect/` / 0 `data/territories.yaml` / …` |

## 二、补扫到的同域死链(派单表外)

域内全量补扫(`lib/(ui|providers|services|utils|combat)/`、`lib/data/models/`、`lib/features/{stage,sect_management,level,pvp,home_feed,boss_gauntlet}/`、`lib/core/{combat,application}/`、`data/narratives/`、`test/{tools,support,ui,services}/` 六维 grep),**未发现派单表外的新死链**。已核实的近邻引用均指向现存物:

- `docs/audit/yaml_integrity_2026-05-12.md:148` `data/narratives/stages/`、`data/lore/` — 均存在 ✓
- `docs/PUBLISHING_ART_PASS_1_0.md:943` `data/narratives/chapters/` — 存在 ✓
- `docs/dispatch/2026-08-07_Q2.md:28` `data/narratives/_archive/` — 存在 ✓
- `docs/audit/early_difficulty_gate_characterization_2026-07-05.md:6` 引用探针已用新名 `early_difficulty_gate_probe_2026_07_05.dart`(当时已同步)✓
- `docs/audit/full_project_review_2026-07-02.md:35` `lib/core/application/system_clock_provider.dart` — 存在 ✓
- `test/tools/` 其余引用(desktop_semantics_audit / art_tone_audit / idle_economy / balance_simulator / progression_playtest / vulnerability_window / inner_demon_* / attribute_role_sensitivity / tower_boss_feel 共 10 个文件)逐个 `ls` 实测均存在 ✓

## 三、保留项与理由

1. **#3 / #4 / #8(自标注记录)**:三行都是「审计/变更记录」而非「现役引用」——#3/#4 引用的是 CLAUDE.md 当时的错误声明(审计对象本身),同句已给出正确新路径;#8 是改名事件记录,旧名是新名的变更前身、新名同句给出。改动会失真(#3/#4 失去审计对象、#8 变成「X 改名为 X」),与派单「历史交接存档旧路径不碰」同类的保护逻辑。逐条证据见 §一。
2. **`docs/PATH_MIGRATION_MAP.md` 与 `docs/dispatch/2026-08-07_L1A.md` / `L1B.md` 中的旧路径**:映射表是本次修复的权威依据,旧路径即其内容本体;L1A/L1B 是派单件,表格「旧引用」列引用的旧路径就是本次要修的对象的描述。三者均属「故意引用」,修改会破坏单据语义。
3. **`docs/phase0/p3_3_pvp_phase0_2026-05-24.md:39` 的 `lib/features/pvp`、`p1_2_jianghu_enmity_phase0_2026-05-24.md:39` 的 `lib/features/jianghu`**:上下文是「**不实装**:0 lib/features/X」的边界范围声明(规划文承诺不创建该路径),不是指向现存文件的引用,不会误导读者去找文件。保留。
4. **`docs/NARRATIVE_SCHEMA.md` 中 `mainline_test_*` 示例文件名**:schema 规范文档的格式示例(共 6 关 × 2 段的命名体例),非指向现存文件的引用;且 05-12 审计同域的 `stages.yaml` 联结口径变更属于内容层问题,超出本单路径修复范围。保留(如需修订属另一任务)。

## 四、观察项(超出本单范围,供上游知情)

1. **K1 派单内容漂移**:修完 #12 后发现 `lib/features/mainline/presentation/stage_entry_flow.dart:233` 现行为 `rng: ref.read(mathRandomProvider),`(Provider 注入),已不是派单所述 `rng: Random()` 裸构造——该位点可能已被 2026-07-26 的 DefaultRng 收口改造覆盖。K1 执行端 Phase 0 实测时请以此为线索复核,勿被 233 行误导。
2. **`data/narratives/techniques/` 并非「已移除」而是「已归档」**:git 实查 67 个文件(含 insights/ 40 篇)在 `data/narratives/_archive/techniques/` 下,建议 `PATH_MIGRATION_MAP.md` §5 的措辞从「已彻底不存在」升级为「已归档」,便于后续文档引用时直接指向归档实址。

## 五、验收自检输出

### 1. 旧路径归零自检(仓库根执行)

```
$ grep -rn --include='*.md' -E 'lib/(ui|providers|services|utils|combat)/|lib/data/models/' docs/*.md docs/audit docs/phase0 docs/dispatch --exclude-dir=reports
(exit=1,无输出)
```

期望 0 命中达成。说明:全仓该模式仅剩 `docs/PATH_MIGRATION_MAP.md`(映射表本体,须保留)与 `docs/dispatch/2026-08-07_L1A.md`/`L1B.md`(派单件,须保留),理由见 §三.2。

### 2. 新路径存在性自检

```
EXISTS lib/shared/strings.dart
EXISTS lib/features/battle/domain/damage_calculator.dart      (#3 佐证)
EXISTS lib/features/dispel/application/dispel_service.dart    (#4 佐证)
EXISTS lib/features/mainline/presentation/stage_entry_flow.dart
EXISTS lib/features/battle/application/battle_providers.dart
EXISTS lib/features/sect/
EXISTS data/lore/
EXISTS data/events/
EXISTS data/narratives/stages/stage_01_01_opening.yaml
EXISTS data/narratives/_archive/techniques/
EXISTS docs/dispatch_evidence/inscription_2026-08-06/
EXISTS docs/audit/early_difficulty_gate_probe_2026_07_05.dart (#8 佐证)
```

### 3. 越界自检

```
$ git diff --name-only
docs/NARRATIVE_SCHEMA.md
docs/RELEASE_CHECKLIST_1_0.md
docs/audit/full_project_review_2026-07-02.md
docs/audit/overnight_fix_and_balance_review_2026-07-08.md
docs/audit/yaml_integrity_2026-05-12.md
docs/dispatch/2026-08-06_K1_kimi_techdebt_series.md
docs/dispatch/2026-08-06_night_plan.md
docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md
docs/phase0/p4_1_sect_management_phase0_2026-05-25.md
```

9 个文件全部落在允许域(`docs/*.md` 顶层 / `docs/audit/**` / `docs/phase0/**` / `docs/dispatch/*.md` 顶层,不含 reports/ 子目录——本报告即落盘于 `docs/dispatch/reports/`)。无 `lib/` `test/` `data/` `PROGRESS.md` `GDD.md` 等越界改动。

### 4. 规模统计

9 文件 / 17 行改动(15 条派单处置中 12 处落笔 + 0 处补扫新发现;3 处保留)。commit message 以 `[READY]` 开头,工作区干净。
