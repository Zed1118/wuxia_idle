# REPORT_B1 · docs/ 内部引用死链扫描

> 试跑单 B1 · codebuddy 首单 · 2026-08-07
> 仓库:挂机武侠 · 分支:`cb/trial-doc-links` · worktree:`.claude/worktrees/cb-linkscan`
> 性质:只读扫描 + 写报告,零代码改动(硬边界)
> 工具:Python 3 脚本逐行扫描(脚本放 /tmp,不入仓)

## 0. 结论速览(TL;DR)

| 指标 | 值 |
|---|---:|
| 扫描 md 文件数(docs/**,排除 _archive) | 1204 |
| 权威引用总数(md 链接 + 反引号路径) | 8114 |
| └ md 链接引用 / 死链 | 33 / 19 |
| └ 反引号路径引用 / 死链 | 8081 / 1073 |
| **权威死链总数** | **1092** |
| 去重死链行(按 md 文件 × 目标) | 913 |
| 唯一死链目标 | 692 |
| 跳过类(不计入) | 417 |
| 补充:非反引号裸路径死链线索(高误报) | 244 |

**要点**

- 死链高度集中于 `docs/handoff`(720 / 2455 引用,历史交接存档)与 `docs/superpowers`(145 / 3649,实施计划);这两类含大量历史路径提及,多为代码重构后的历史快照,非「文档互链失修」。
- 「文档互链失修」性质的核心区相对克制:`docs/audit` 19/229、`docs/spec` 128/1375、`docs/dispatch` 2/28、`docs`(顶层) 8/93。
- 死链主因三股:代码路径重构/搬迁(499)、截图/生成物不入库(327 + 40 + 28)、文档/数据移除改名(99 + 60)。
- 真值得修的「文档互链死链」(去除外库不入库物后)集中在:已搬迁的 `lib/ui/*`→`lib/shared/*` 与 `lib/features/*` 重排、`lib/providers/` 整目录移除、`data/narratives/mainline_test_0*.yaml` 测试叙事移除、`docs/handoff/*_visual_check_screenshots/` 截图目录清理等。

## 1. 扫描范围与方法

### 1.1 范围
- `docs/**/*.md`,排除 `docs/_archive/`;共 **1204** 文件。
- 不含 `_archive`、不含非 md 文件。

### 1.2 采集对象(任务定义)
1. **md 链接**:`[text](path)` 与 `![alt](path)` 的 path 部分。
2. **反引号路径**:正文反引号 token 内形如 `docs/...` `lib/...` `test/...` `data/...` 的路径(允许可选 `./` `../` 前缀)。

### 1.3 清洗与存在性判定
- 清洗:剥 `#anchor`;剥 `:行号` / `:行-行` / `:行,行` / `:行+`;剥已知扩展名后的字段后缀(如 `data/skills.yaml.powerMultiplier` → `data/skills.yaml`);剥尾标点(`)。,；：) 等。
- 存在性:对清洗后路径,分别以 **md 文件所在目录** 与 **repo 根** 两种基准 `os.path.exists` 解析;任一命中(文件或目录)算**存活**;都不中→**死链**。
- md 链接 path 须通过「路径形态」过滤(ASCII 路径字符 + `./`/`../`/已知顶级目录前缀/已知扩展名/尾斜杠之一),以排除 `[15,30](27h/54h)` 这类「范围+括注」被误判为链接。

### 1.4 跳过类(不计入引用与死链)

| 跳过类 | 条数 | 说明 |
|---|---:|---|
| 通配 `* ? {}` | 374 | 如 `docs/handoff/*dispatch*.md`(docs/dispatch/README.md:10) |
| 模板 `<>`/`...` | 20 | 如 `<date>_<单号>_<端>_<域>.md`(docs/dispatch/README.md:7) |
| 范围简写 `a..b` | 2 | 如 `r4_01..r4_12.png`(docs/RELEASE_CHECKLIST_1_0.md:119) |
| 日期模板 | 3 | 如 `docs/sessions/YYYY-MM-DD_HHMM_<主题>.md`(docs/handoff/README.md:11) |
| 前缀简写 | 18 | 末段无扩展名且以 `_` 结尾,如 `docs/handoff/visual_capture_` |
| **小计** | **417** | |

### 1.5 不扫的形式
- 代码围栏(``` ``` / ~~~)内部。
- URL(`http(s)://`、`mailto:`、`ftp://` 等)、纯锚点(`#section`)。
- 非反引号包裹的裸文本路径(任务主范围外);另作**补充线索**见 §6,不入权威计数。

## 2. 统计

### 2.1 子目录分布

| docs 子目录 | 扫描引用数 | 死链数 |
|---|---:|---:|
| `(top)` | 93 | 8 |
| `art` | 2 | 0 |
| `audit` | 229 | 19 |
| `dispatch` | 28 | 2 |
| `handoff` | 2455 | 720 |
| `phase0` | 39 | 2 |
| `sessions` | 244 | 68 |
| `spec` | 1375 | 128 |
| `superpowers` | 3649 | 145 |
| **合计** | **8114** | **1092** |

### 2.2 死链按目标前缀

| 目标前缀 | 死链数 |
|---|---:|
| `docs/` | 449 |
| `lib/` | 301 |
| `test/` | 226 |
| `data/` | 60 |
| `../` | 23 |
| `(other)` | 17 |
| `/` | 16 |

### 2.3 死链按判定/类别

| 判定/类别 | 死链数 |
|---|---:|
| 代码路径(疑重构/移走) | 499 |
| 截图/图片(多不入库) | 327 |
| 文档路径(疑移走/删除) | 99 |
| 数据路径(疑移除/改名) | 60 |
| 截图目录(多不入库) | 40 |
| 生成物(不入库) | 28 |
| 相对父目录(边界) | 21 |
| 其他 | 16 |
| 出 repo 边界 | 2 |

## 3. 死链清单(权威)

> 按 **md 文件 × 目标(清洗后)** 去重,同文件内多次引用合并为一行(列「次数」),「行」为首次出现行号。
> 判定/类别含义见 §2.3。「生成物/截图」类为不入库物,列示但非文档失修;「代码/数据/文档路径」类为真死链候选。

| md 文件 | 行(首次) | 次数 | 引用原文 | 目标(清洗后) | 判定/类别 |
|---|---:|---:|---|---|---|
| `docs/NARRATIVE_SCHEMA.md` | 139 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/PUBLISHING_ART_PASS_1_0.md` | 1052 | 1 | `test/tools/output/asset_audit.md` | `test/tools/output/asset_audit.md` | 生成物(不入库) |
| `docs/RELEASE_CHECKLIST_1_0.md` | 37 | 1 | `data/narratives/lore/events/` | `data/narratives/lore/events/` | 数据路径(疑移除/改名) |
| `docs/RELEASE_CHECKLIST_1_0.md` | 110 | 1 | `docs/handoff/r3_visual_check_screenshots/` | `docs/handoff/r3_visual_check_screenshots/` | 截图目录(多不入库) |
| `docs/RELEASE_CHECKLIST_1_0.md` | 100 | 1 | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | 截图目录(多不入库) |
| `docs/RELEASE_CHECKLIST_1_0.md` | 228 | 1 | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png` | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png` | 截图/图片(多不入库) |
| `docs/RELEASE_CHECKLIST_1_0.md` | 74 | 1 | `test/tools/output/idle_economy_2026-05-29.md` | `test/tools/output/idle_economy_2026-05-29.md` | 生成物(不入库) |
| `docs/ROADMAP_1_0.md` | 76 | 1 | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | 截图目录(多不入库) |
| `docs/audit/full_audit_2026-06-16.md` | 84 | 1 | `lib/core/combat/formulas.dart` | `lib/core/combat/formulas.dart` | 代码路径(疑重构/移走) |
| `docs/audit/full_audit_2026-06-16.md` | 85 | 1 | `lib/features/cultivation/domain/dispel_cultivation.dart` | `lib/features/cultivation/domain/dispel_cultivation.dart` | 代码路径(疑重构/移走) |
| `docs/audit/full_project_review_2026-07-02.md` | 41 | 1 | `data/narratives/techniques/` | `data/narratives/techniques/` | 数据路径(疑移除/改名) |
| `docs/audit/full_project_review_2026-07-02.md` | 43 | 1 | `test/support/def_loading.dart` | `test/support/def_loading.dart` | 代码路径(疑重构/移走) |
| `docs/audit/long_balance_audit_2026-06-28.md` | 12 | 1 | `test/tools/output/idle_economy_2026-05-29.md` | `test/tools/output/idle_economy_2026-05-29.md` | 生成物(不入库) |
| `docs/audit/overnight_fix_and_balance_review_2026-07-08.md` | 86 | 1 | `docs/audit/early_difficulty_gate_probe_2026-07-05.dart` | `docs/audit/early_difficulty_gate_probe_2026-07-05.dart` | 文档路径(疑移走/删除) |
| `docs/audit/overnight_fix_and_balance_review_2026-07-08.md` | 51 | 1 | `test/tools/floor30_soft_gate_diagnostic_test.dart` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/audit/self_review_2026-07-09.md` | 38 | 1 | `test/tools/output/readable_first_clear_tempo_2026-07-09.csv` | `test/tools/output/readable_first_clear_tempo_2026-07-09.csv` | 生成物(不入库) |
| `docs/audit/self_review_2026-07-09.md` | 37 | 1 | `test/tools/output/readable_first_clear_tempo_2026-07-09.md` | `test/tools/output/readable_first_clear_tempo_2026-07-09.md` | 生成物(不入库) |
| `docs/audit/stage_review_2026-06-28.md` | 18 | 2 | `test/tools/output/art_tone_audit.md` | `test/tools/output/art_tone_audit.md` | 生成物(不入库) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 40 | 1 | `data/narratives/mainline_test_01.yaml` | `data/narratives/mainline_test_01.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 41 | 1 | `data/narratives/mainline_test_02.yaml` | `data/narratives/mainline_test_02.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 42 | 1 | `data/narratives/mainline_test_03.yaml` | `data/narratives/mainline_test_03.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 43 | 1 | `data/narratives/mainline_test_04.yaml` | `data/narratives/mainline_test_04.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 44 | 1 | `data/narratives/mainline_test_05.yaml` | `data/narratives/mainline_test_05.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 45 | 1 | `data/narratives/mainline_test_06.yaml` | `data/narratives/mainline_test_06.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 65 | 1 | `data/narratives/stages/stage_01_01.yaml` | `data/narratives/stages/stage_01_01.yaml` | 数据路径(疑移除/改名) |
| `docs/audit/yaml_integrity_2026-05-12.md` | 166 | 1 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/dispatch/2026-08-06_K1_kimi_techdebt_series.md` | 10 | 1 | `lib/features/stage/stage_entry_flow.dart:233` | `lib/features/stage/stage_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/dispatch/2026-08-06_night_plan.md` | 48 | 1 | `/docs/dispatch_evidence/inscription_2026-08-06/` | `/docs/dispatch_evidence/inscription_2026-08-06/` | 其他 |
| `docs/handoff/afk_batch_closeout_2026-08-01.md` | 36 | 1 | `data/ranks.yaml` | `data/ranks.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/art_assets_integration_closeout_2026-05-20.md` | 71 | 1 | `lib/features/home_feed/presentation/home_feed_screen.dart` | `lib/features/home_feed/presentation/home_feed_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/art_assets_integration_closeout_2026-05-20.md` | 48 | 1 | `lib/features/seclusion/domain/seclusion_map_def.dart` | `lib/features/seclusion/domain/seclusion_map_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/art_assets_integration_spec_2026-05-20.md` | 35 | 2 | `lib/features/seclusion/domain/seclusion_map_def.dart` | `lib/features/seclusion/domain/seclusion_map_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/art_stage3_phase0_reality_check_2026-05-21.md` | 177 | 1 | `data/chapters.yaml` | `data/chapters.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/b_cover_visual_2026-05-31/closeout.md` | 8 | 1 | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_1280x720.png` | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/closeout.md` | 7 | 1 | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_bottom.png` | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_bottom.png` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/closeout.md` | 6 | 1 | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_full.png` | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_full.png` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/closeout.md` | 5 | 1 | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_top.png` | `docs/handoff/b_cover_visual_2026-05-31/technique_panel_top.png` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31_r3/closeout.md` | 11 | 1 | `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_full_max.png` | `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_full_max.png` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31_r3/closeout.md` | 12 | 1 | `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_seal.png` | `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_seal.png` | 截图/图片(多不入库) |
| `docs/handoff/ch4_lore_equipment_skill_audit_2026-05-22.md` | 59 | 2 | `data/inventory.yaml` | `data/inventory.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md` | 52 | 1 | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1280x720.png` | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md` | 53 | 1 | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1920x1080.png` | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md` | 47 | 1 | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1280x720.png` | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md` | 48 | 1 | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1920x1080.png` | `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_console_visual_2026-06-12.md` | 13 | 2 | `docs/handoff/codex_batch3_console_visual_2026-06-12/` | `docs/handoff/codex_batch3_console_visual_2026-06-12/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_batch3_console_visual_2026-06-12.md` | 22 | 1 | `docs/handoff/codex_batch3_console_visual_2026-06-12/t1_charge_break.png` | `docs/handoff/codex_batch3_console_visual_2026-06-12/t1_charge_break.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_console_visual_r2_2026-06-12.md` | 14 | 1 | `docs/handoff/codex_batch3_console_visual_r2_2026-06-12/` | `docs/handoff/codex_batch3_console_visual_r2_2026-06-12/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 13 | 1 | `docs/handoff/batch3_visual_2026-05-30/` | `docs/handoff/batch3_visual_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 29 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_01_transition_button.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_01_transition_button.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 30 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_02_drop_tier.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_02_drop_tier.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 31 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_03a_battlelog.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_03a_battlelog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 32 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_03b_summary.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_03b_summary.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 33 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_04_refine_button.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_04_refine_button.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 34 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_05a_picker_close.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_05a_picker_close.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 35 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_05b_picker_empty.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_05b_picker_empty.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 36 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_05c_picker_empty_closed.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_05c_picker_empty_closed.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_visual_2026-05-30.md` | 37 | 1 | `docs/handoff/batch3_visual_2026-05-30/batch3_05d_picker_worn_by_other.png` | `docs/handoff/batch3_visual_2026-05-30/batch3_05d_picker_worn_by_other.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_battle_ui_stage_2026-07-16.md` | 57 | 1 | `docs/equip-baicao-orchestration@25221323` | `docs/equip-baicao-orchestration@25221323` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_battle_victory_ui_kit_2026-06-06.md` | 22 | 1 | `docs/handoff/codex_battle_victory_ui_kit_2026-06-06/01_battle_victory_paper_report.png` | `docs/handoff/codex_battle_victory_ui_kit_2026-06-06/01_battle_victory_paper_report.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 35 | 1 | `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png` | `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 29 | 1 | `docs/handoff/codex_t11_inventory_fix_2026-06-05/05_inventory_full_after_divider.png` | `docs/handoff/codex_t11_inventory_fix_2026-06-05/05_inventory_full_after_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 30 | 1 | `docs/handoff/codex_t11_inventory_fix_2026-06-05/06_shead_weapon_after_divider.png` | `docs/handoff/codex_t11_inventory_fix_2026-06-05/06_shead_weapon_after_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 31 | 1 | `docs/handoff/codex_t11_inventory_fix_2026-06-05/07_shead_armor_after_divider.png` | `docs/handoff/codex_t11_inventory_fix_2026-06-05/07_shead_armor_after_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 32 | 1 | `docs/handoff/codex_t11_inventory_fix_2026-06-05/08_shead_accessory_after_divider.png` | `docs/handoff/codex_t11_inventory_fix_2026-06-05/08_shead_accessory_after_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 33 | 1 | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/01_inventory_polished.png` | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/01_inventory_polished.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md` | 34 | 1 | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/04_equipment_detail_screen_polished.png` | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/04_equipment_detail_screen_polished.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 27 | 1 | `docs/handoff/codex_break_feel_20260610_170446/` | `docs/handoff/codex_break_feel_20260610_170446/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 50 | 1 | `docs/handoff/codex_break_feel_20260610_170446/after_click_probe.png` | `docs/handoff/codex_break_feel_20260610_170446/after_click_probe.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 46 | 1 | `docs/handoff/codex_break_feel_20260610_170446/charge_building.png` | `docs/handoff/codex_break_feel_20260610_170446/charge_building.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 48 | 1 | `docs/handoff/codex_break_feel_20260610_170446/charge_building_static.png` | `docs/handoff/codex_break_feel_20260610_170446/charge_building_static.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 47 | 1 | `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption.png` | `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 49 | 1 | `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption_static.png` | `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption_static.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 53 | 1 | `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_charge_break_1280x720.png` | `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_charge_break_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 54 | 1 | `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_interrupt_caption_1280x720.png` | `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_interrupt_caption_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446.md` | 55 | 1 | `docs/handoff/visual_capture_4d370db0_20260610_170843/manifest.txt` | `docs/handoff/visual_capture_4d370db0_20260610_170843/manifest.txt` | 截图目录(多不入库) |
| `docs/handoff/codex_character_header_polish_2026-06-07.md` | 28 | 1 | `docs/handoff/codex_character_header_polish_2026-06-07/01_character_header_portrait_plaque.png` | `docs/handoff/codex_character_header_polish_2026-06-07/01_character_header_portrait_plaque.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md` | 29 | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/01_character_panel.png` | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/01_character_panel.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md` | 30 | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/02_character_panel_encounter_skill.png` | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/02_character_panel_encounter_skill.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md` | 31 | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/03_character_panel_slots.png` | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/03_character_panel_slots.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md` | 32 | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/04_character_panel_readability.png` | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/04_character_panel_readability.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md` | 33 | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/05_character_panel_profile_header.png` | `docs/handoff/codex_character_panel_ui_polish_2026-06-06/05_character_panel_profile_header.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07.md` | 33 | 1 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png` | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07.md` | 34 | 1 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png` | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_claude_resume_ui_progress_2026-06-07.md` | 114 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_d_progress_stage_row_2026-06-12.md` | 17 | 2 | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_d_progress_stage_row_2026-06-12_closeout.md` | 5 | 1 | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md` | 161 | 1 | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md` | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_battle_b1_2026-06-01.md` | 20 | 1 | `docs/handoff/codex_visual_battle_b1_2026-06-01/` | `docs/handoff/codex_visual_battle_b1_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_battle_b2_2026-06-01.md` | 28 | 1 | `docs/handoff/codex_visual_battle_b2_2026-06-01/` | `docs/handoff/codex_visual_battle_b2_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_battle_scene_longtail_2026-06-02.md` | 32 | 1 | `docs/handoff/codex_visual_battle_scene_2026-06-02/` | `docs/handoff/codex_visual_battle_scene_2026-06-02/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_ch4_visual_check_2026-05-22.md` | 60 | 1 | `docs/handoff/ch4_visual_check_closeout_2026-05-22.md` | `docs/handoff/ch4_visual_check_closeout_2026-05-22.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_chapter_cover_2026-06-01.md` | 19 | 1 | `docs/handoff/codex_visual_chapter_cover_2026-06-01/` | `docs/handoff/codex_visual_chapter_cover_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_chapter_cover_recheck_2026-06-01.md` | 25 | 1 | `docs/handoff/codex_visual_chapter_cover_recheck_2026-06-01/` | `docs/handoff/codex_visual_chapter_cover_recheck_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_char_panel_profile_2026-06-01.md` | 26 | 1 | `docs/handoff/codex_visual_char_panel_profile_2026-06-01/` | `docs/handoff/codex_visual_char_panel_profile_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_narrative_scene_2026-06-02.md` | 34 | 1 | `docs/handoff/codex_visual_narrative_scene_2026-06-02/` | `docs/handoff/codex_visual_narrative_scene_2026-06-02/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_phase5_aoe_reverify_2026-06-17.md` | 37 | 1 | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17/` | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_phase5_mainline1_reverify_2026-06-17.md` | 42 | 1 | `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/` | `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_phase5_mainline3_loot_dialog_2026-06-18.md` | 42 | 1 | `docs/handoff/codex_loot_dialog_2026-06-18/` | `docs/handoff/codex_loot_dialog_2026-06-18/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md` | 64 | 1 | `docs/handoff/p4_1_1_screenshots_r2/` | `docs/handoff/p4_1_1_screenshots_r2/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md` | 84 | 1 | `docs/handoff/pen_visual_verify_p4_1_1_round2_2026-05-27.md` | `docs/handoff/pen_visual_verify_p4_1_1_round2_2026-05-27.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_r4_p2_1_content_drop_2026-05-28.md` | 16 | 1 | `docs/handoff/r4_visual_check_screenshots/r4_10_skill_description.png` | `docs/handoff/r4_visual_check_screenshots/r4_10_skill_description.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_r4_p2_1_content_drop_2026-05-28.md` | 17 | 1 | `docs/handoff/r4_visual_check_screenshots/r4_12_synergy_no_crash.png` | `docs/handoff/r4_visual_check_screenshots/r4_12_synergy_no_crash.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_treasure_glow_2026-06-13.md` | 64 | 1 | `docs/handoff/codex_treasure_glow_acceptance_2026-06-13_closeout.md` | `docs/handoff/codex_treasure_glow_acceptance_2026-06-13_closeout.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_w14_3_round2_2026-05-15.md` | 104 | 1 | `lib/ui/character_panel/character_panel_screen.dart` | `lib/ui/character_panel/character_panel_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w14_3c_2026-05-14.md` | 109 | 1 | `lib/ui/character_panel/encounter_skill_section.dart` | `lib/ui/character_panel/encounter_skill_section.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w14_3c_2026-05-14.md` | 94 | 1 | `lib/ui/theme/colors.dart` | `lib/ui/theme/colors.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_dialog_round3_2026-05-15.md` | 131 | 1 | `docs/screenshots/w15_round3/` | `docs/screenshots/w15_round3/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w15_dialog_round3_2026-05-15.md` | 57 | 1 | `lib/ui/debug/encounter_debug_picker.dart` | `lib/ui/debug/encounter_debug_picker.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md` | 104 | 1 | `docs/screenshots/w15_equipment_detail/` | `docs/screenshots/w15_equipment_detail/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md` | 84 | 1 | `docs/screenshots/w15_equipment_detail/01_inventory.png` | `docs/screenshots/w15_equipment_detail/01_inventory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md` | 22 | 1 | `lib/ui/enhancement/enhance_dialog.dart` | `lib/ui/enhancement/enhance_dialog.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md` | 21 | 1 | `lib/ui/inventory/equipment_detail_screen.dart` | `lib/ui/inventory/equipment_detail_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md` | 23 | 1 | `lib/ui/inventory/inventory_screen.dart` | `lib/ui/inventory/inventory_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md` | 91 | 1 | `docs/screenshots/w15_equipment_detail_round2/` | `docs/screenshots/w15_equipment_detail_round2/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md` | 67 | 1 | `docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png` | `docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md` | 24 | 1 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md` | 115 | 1 | `docs/screenshots/w15_resonance/` | `docs/screenshots/w15_resonance/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md` | 92 | 1 | `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md` | 29 | 1 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_stage_drop_visual_2026-05-16.md` | 89 | 1 | `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_dispatch_w15_stage_drop_visual_2026-05-16.md` | 27 | 1 | `lib/ui/main_menu.dart:47` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_w15_victory_dialog_2026-05-16.md` | 149 | 2 | `docs/screenshots/w15_victory_dialog/` | `docs/screenshots/w15_victory_dialog/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w15_victory_dialog_round2_2026-05-16.md` | 170 | 2 | `docs/screenshots/w15_victory_dialog_round2/` | `docs/screenshots/w15_victory_dialog_round2/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w16_festival_chip_visual_check_2026-05-16.md` | 117 | 1 | `docs/screenshots/w16/` | `docs/screenshots/w16/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w17_festival_chip_extend_visual_check_2026-05-17.md` | 113 | 1 | `docs/screenshots/w17/` | `docs/screenshots/w17/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w17_lineage_panel_visual_check_2026-05-17.md` | 169 | 1 | `docs/screenshots/w17/` | `docs/screenshots/w17/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w18_a1_synergy_visual_check_2026-05-17.md` | 211 | 1 | `docs/screenshots/w18/` | `docs/screenshots/w18/` | 截图目录(多不入库) |
| `docs/handoff/codex_dispatch_w7_w11_2026-05-13.md` | 149 | 1 | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md` | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_encounter_outcome_banner_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_encounter_outcome_banner_2026-06-07/01_encounter_outcome_skill_1280x720.png` | `docs/handoff/codex_encounter_outcome_banner_2026-06-07/01_encounter_outcome_skill_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 21 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/00_contact_sheet_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/00_contact_sheet_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 22 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/01_main_menu_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/01_main_menu_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 23 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/02_battle_in_progress_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/02_battle_in_progress_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 24 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/03_battle_victory_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/03_battle_victory_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 25 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/04_character_panel_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/04_character_panel_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 26 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/05_inventory_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/05_inventory_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 27 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/06_equipment_detail_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/06_equipment_detail_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 28 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/07_technique_panel_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/07_technique_panel_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/08_mainline_stage_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/08_mainline_stage_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 30 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/09_tower_map_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/09_tower_map_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 31 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/10_seclusion_map_1280x720.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/10_seclusion_map_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 35 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/00_contact_sheet_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/00_contact_sheet_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 36 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/01_main_menu_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/01_main_menu_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 37 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/02_battle_in_progress_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/02_battle_in_progress_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 38 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/03_battle_victory_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/03_battle_victory_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 39 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/04_character_panel_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/04_character_panel_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 40 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/05_inventory_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/05_inventory_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 41 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/06_equipment_detail_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/06_equipment_detail_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 42 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/07_technique_panel_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/07_technique_panel_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 43 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/08_mainline_stage_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/08_mainline_stage_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 44 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/09_tower_map_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/09_tower_map_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md` | 45 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/10_seclusion_map_1920x1080.png` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/10_seclusion_map_1920x1080.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_growth_ceremony_victory_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_growth_ceremony_victory_2026-06-07/01_victory_growth_ceremony_1280x720.png` | `docs/handoff/codex_growth_ceremony_victory_2026-06-07/01_victory_growth_ceremony_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_inventory_layout_redesign_2026-06-06.md` | 19 | 1 | `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png` | `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_icons_2026-06-07.md` | 28 | 1 | `docs/handoff/codex_main_menu_icons_2026-06-07/01_main_menu_icons_1280x720.png` | `docs/handoff/codex_main_menu_icons_2026-06-07/01_main_menu_icons_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_second_pass_2026-06-06.md` | 23 | 1 | `docs/handoff/codex_main_menu_second_pass_2026-06-06/01_main_menu_three_columns.png` | `docs/handoff/codex_main_menu_second_pass_2026-06-06/01_main_menu_three_columns.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_status_2026-06-07.md` | 33 | 1 | `docs/handoff/codex_main_menu_status_2026-06-07/01_main_menu_status_1280x720.png` | `docs/handoff/codex_main_menu_status_2026-06-07/01_main_menu_status_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mainline_route_visual_2026-06-07.md` | 30 | 1 | `docs/handoff/codex_mainline_route_visual_2026-06-07/01_chapter_route_full.png` | `docs/handoff/codex_mainline_route_visual_2026-06-07/01_chapter_route_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mainline_route_visual_2026-06-07.md` | 31 | 1 | `docs/handoff/codex_mainline_route_visual_2026-06-07/02_chapter_route_1280x720.png` | `docs/handoff/codex_mainline_route_visual_2026-06-07/02_chapter_route_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_asset_integration_2026-06-07.md` | 31 | 1 | `docs/handoff/codex_mj_asset_integration_2026-06-07/01_main_menu_mj_assets.png` | `docs/handoff/codex_mj_asset_integration_2026-06-07/01_main_menu_mj_assets.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_asset_integration_2026-06-07.md` | 33 | 1 | `docs/handoff/codex_mj_asset_integration_2026-06-07/02_main_menu_mj_assets_clean_bg.png` | `docs/handoff/codex_mj_asset_integration_2026-06-07/02_main_menu_mj_assets_clean_bg.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07.md` | 49 | 1 | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/01_battle_boss_fx_overlay.png` | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/01_battle_boss_fx_overlay.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07.md` | 50 | 1 | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/02_battle_boss_fx_overlay_restart.png` | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/02_battle_boss_fx_overlay_restart.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07.md` | 35 | 1 | `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07/01_battle_boss_frame_victory_title.png` | `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07/01_battle_boss_frame_victory_title.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md` | 52 | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/battle_victory_first_clear_ceremony_full.png` | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/battle_victory_first_clear_ceremony_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md` | 51 | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/seclusion_result_ceremony_full.png` | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/seclusion_result_ceremony_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md` | 53 | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/technique_refine_insight_dialog_ceremony_full.png` | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/technique_refine_insight_dialog_ceremony_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07.md` | 33 | 1 | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/01_main_menu_gate_bg.png` | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/01_main_menu_gate_bg.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07.md` | 35 | 1 | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/02_main_menu_gate_bg_clean.png` | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/02_main_menu_gate_bg_clean.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_red_seal_integration_2026-06-07.md` | 28 | 1 | `docs/handoff/codex_mj_red_seal_integration_2026-06-07/01_first_clear_red_seal.png` | `docs/handoff/codex_mj_red_seal_integration_2026-06-07/01_first_clear_red_seal.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_red_seal_integration_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_mj_red_seal_integration_2026-06-07/02_battle_victory_red_seal.png` | `docs/handoff/codex_mj_red_seal_integration_2026-06-07/02_battle_victory_red_seal.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md` | 11 | 1 | `docs/handoff/codex_p0_break_ui_visual_2026-06-09_assets/` | `docs/handoff/codex_p0_break_ui_visual_2026-06-09_assets/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md` | 9 | 1 | `docs/handoff/visual_capture_05adb81_20260609_212740/` | `docs/handoff/visual_capture_05adb81_20260609_212740/` | 截图目录(多不入库) |
| `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md` | 10 | 1 | `docs/handoff/visual_capture_05adb81_20260609_214413/character_panel_1280x720.png` | `docs/handoff/visual_capture_05adb81_20260609_214413/character_panel_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md` | 54 | 1 | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17/` | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md` | 35 | 1 | `test/combat/battle_engine_test.dart` | `test/combat/battle_engine_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md` | 34 | 1 | `test/features/battle/presentation/battle_drag_skill_test.dart` | `test/features/battle/presentation/battle_drag_skill_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17.md` | 47 | 1 | `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/` | `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_phase5_mainline1_visual_2026-06-17.md` | 10 | 1 | `docs/handoff/codex_phase5_mainline1_visual_2026-06-17/` | `docs/handoff/codex_phase5_mainline1_visual_2026-06-17/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_refine_insight_dialog_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_refine_insight_dialog_2026-06-07/01_refine_insight_dialog_1280x720.png` | `docs/handoff/codex_refine_insight_dialog_2026-06-07/01_refine_insight_dialog_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 13 | 1 | `docs/screenshots/round2_01_main_menu_mountain.png` | `docs/screenshots/round2_01_main_menu_mountain.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 14 | 1 | `docs/screenshots/round2_02_chapter_list.png` | `docs/screenshots/round2_02_chapter_list.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 15 | 1 | `docs/screenshots/round2_03_inventory_equipment.png` | `docs/screenshots/round2_03_inventory_equipment.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 16 | 1 | `docs/screenshots/round2_04_equipment_detail.png` | `docs/screenshots/round2_04_equipment_detail.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 17 | 1 | `docs/screenshots/round2_05_inventory_material.png` | `docs/screenshots/round2_05_inventory_material.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 18 | 1 | `docs/screenshots/round2_06_lineage_panel.png` | `docs/screenshots/round2_06_lineage_panel.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 19 | 1 | `docs/screenshots/round2_07_technique_panel.png` | `docs/screenshots/round2_07_technique_panel.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 20 | 1 | `docs/screenshots/round2_08_seclusion_meditation.png` | `docs/screenshots/round2_08_seclusion_meditation.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` | 21 | 1 | `docs/screenshots/round2_09_home_feed_seal_baseline.png` | `docs/screenshots/round2_09_home_feed_seal_baseline.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_route_map_first_slice_2026-06-06.md` | 31 | 1 | `docs/handoff/codex_route_map_first_slice_2026-06-06/01_mainline_route_map.png` | `docs/handoff/codex_route_map_first_slice_2026-06-06/01_mainline_route_map.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_route_map_first_slice_2026-06-06.md` | 32 | 1 | `docs/handoff/codex_route_map_first_slice_2026-06-06/02_tower_spine.png` | `docs/handoff/codex_route_map_first_slice_2026-06-06/02_tower_spine.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06.md` | 18 | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06/01_seclusion_map_list.png` | `docs/handoff/codex_seclusion_map_visual_2026-06-06/01_seclusion_map_list.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06.md` | 19 | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06/02_seclusion_setup.png` | `docs/handoff/codex_seclusion_map_visual_2026-06-06/02_seclusion_setup.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06.md` | 20 | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06/03_active_retreat.png` | `docs/handoff/codex_seclusion_map_visual_2026-06-06/03_active_retreat.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06.md` | 21 | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06/04_retreat_result.png` | `docs/handoff/codex_seclusion_map_visual_2026-06-06/04_retreat_result.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_stage_journey_visual_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_stage_journey_visual_2026-06-07/01_stage_journey_1280x720.png` | `docs/handoff/codex_stage_journey_visual_2026-06-07/01_stage_journey_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_closeout_2026-06-06.md` | 50 | 1 | `docs/handoff/codex_t11_inventory_fix_2026-06-05/` | `docs/handoff/codex_t11_inventory_fix_2026-06-05/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_t5_result_2026-06-09.md` | 11 | 2 | `docs/handoff/visual_capture_981085a_20260609_115936/` | `docs/handoff/visual_capture_981085a_20260609_115936/` | 截图目录(多不入库) |
| `docs/handoff/codex_t9_result_2026-06-09.md` | 57 | 1 | `docs/handoff/visual_capture_e711a5b_20260609_153133/` | `docs/handoff/visual_capture_e711a5b_20260609_153133/` | 截图目录(多不入库) |
| `docs/handoff/codex_t9_result_2026-06-09.md` | 3 | 1 | `docs/handoff/visual_capture_f771ab7_20260609_131615/` | `docs/handoff/visual_capture_f771ab7_20260609_131615/` | 截图目录(多不入库) |
| `docs/handoff/codex_t9_result_2026-06-09.md` | 4 | 1 | `docs/handoff/visual_capture_f771ab7_20260609_131615/manifest.txt` | `docs/handoff/visual_capture_f771ab7_20260609_131615/manifest.txt` | 截图目录(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 15 | 4 | `01_baseline_1280x720.png` | `01_baseline_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 17 | 1 | `02_swap_dialog_1280x720.png` | `02_swap_dialog_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 17 | 1 | `03_swapped_and_confirmed_1280x720.png` | `03_swapped_and_confirmed_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 18 | 1 | `04_disciple_dispatch_1280x720.png` | `04_disciple_dispatch_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 18 | 1 | `05_founder_dispatch_1280x720.png` | `05_founder_dispatch_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 19 | 1 | `06_block_no_main_snackbar_1280x720.png` | `06_block_no_main_snackbar_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 19 | 1 | `07_block_retreat_snackbar_1280x720.png` | `07_block_retreat_snackbar_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 20 | 1 | `08_empty_seat_1280x720.png` | `08_empty_seat_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 17 | 1 | `09_insert_into_empty_dialog_1280x720.png` | `09_insert_into_empty_dialog_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 15 | 2 | `10_baseline_1440x900.png` | `10_baseline_1440x900.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 26 | 1 | `12_hover_active_card_1280x720.png` | `12_hover_active_card_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md` | 22 | 2 | `13_hover_bench_card_1280x720.png` | `13_hover_bench_card_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_technique_school_matrix_2026-06-07.md` | 29 | 1 | `docs/handoff/codex_technique_school_matrix_2026-06-07/01_technique_school_matrix_1280x720.png` | `docs/handoff/codex_technique_school_matrix_2026-06-07/01_technique_school_matrix_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 197 | 1 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png` | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 198 | 1 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png` | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 200 | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/` | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 206 | 1 | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/` | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 204 | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/` | `docs/handoff/codex_mj_ceremony_integration_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md` | 202 | 1 | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/` | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_tower_visual_second_pass_2026-06-06.md` | 26 | 1 | `docs/handoff/codex_tower_visual_second_pass_2026-06-06/01_tower_stepped_spine.png` | `docs/handoff/codex_tower_visual_second_pass_2026-06-06/01_tower_stepped_spine.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_equipment_line_polish_2026-06-06.md` | 16 | 1 | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/01_inventory_polished.png` | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/01_inventory_polished.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_equipment_line_polish_2026-06-06.md` | 17 | 1 | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/04_equipment_detail_screen_polished.png` | `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/04_equipment_detail_screen_polished.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 18 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/` | 截图目录(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 31 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_battle_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_battle_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 34 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_narrative_dialog_gallery_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_narrative_dialog_gallery_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 33 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_seclusion_equipment_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_seclusion_equipment_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 30 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_sheet_27_routes_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_sheet_27_routes_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 32 | 1 | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_systems_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_systems_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 22 | 1 | `docs/handoff/visual_capture_5cdd696e_20260613_004017/` | `docs/handoff/visual_capture_5cdd696e_20260613_004017/` | 截图目录(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 24 | 1 | `docs/handoff/visual_capture_5cdd696e_20260613_004658/` | `docs/handoff/visual_capture_5cdd696e_20260613_004658/` | 截图目录(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 26 | 1 | `docs/handoff/visual_capture_5cdd696e_20260613_011907/` | `docs/handoff/visual_capture_5cdd696e_20260613_011907/` | 截图目录(多不入库) |
| `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md` | 28 | 1 | `docs/handoff/visual_capture_5cdd696e_20260613_011907/_before_after_ui_polish_3_routes_1280x720.png` | `docs/handoff/visual_capture_5cdd696e_20260613_011907/_before_after_ui_polish_3_routes_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_victory_first_clear_2026-06-07.md` | 17 | 1 | `docs/handoff/codex_victory_first_clear_2026-06-07/01_boss_first_clear_banner_1280x720.png` | `docs/handoff/codex_victory_first_clear_2026-06-07/01_boss_first_clear_banner_1280x720.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_char_panel_bc_2026-06-04.md` | 38 | 1 | `docs/handoff/codex_vis_char_panel_bc_2026-06-04_closeout.md` | `docs/handoff/codex_vis_char_panel_bc_2026-06-04_closeout.md` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_enemy_equipment_2026-06-04.md` | 5 | 1 | `docs/handoff/codex_visual_art_2026-06-04/` | `docs/handoff/codex_visual_art_2026-06-04/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 39 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 40 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel_1920.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel_1920.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 41 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 42 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero_1920.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero_1920.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 44 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 43 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1280_top.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1280_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 45 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_2.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_2.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 46 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_3.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_3.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 47 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_4.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_4.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 37 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 38 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory_1920.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory_1920.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md` | 36 | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_main_menu_smoke_1280.png` | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_main_menu_smoke_1280.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_rerun_2026-06-04.md` | 5 | 1 | `docs/handoff/codex_vis_rerun_2026-06-04/` | `docs/handoff/codex_vis_rerun_2026-06-04/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05.md` | 6 | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05/` | `docs/handoff/codex_vis_t11_inventory_2026-06-05/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05.md` | 55 | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05/01_inventory_full.png` | `docs/handoff/codex_vis_t11_inventory_2026-06-05/01_inventory_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05.md` | 56 | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05/02_shead_weapon.png` | `docs/handoff/codex_vis_t11_inventory_2026-06-05/02_shead_weapon.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05.md` | 57 | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05/03_shead_armor.png` | `docs/handoff/codex_vis_t11_inventory_2026-06-05/03_shead_armor.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05.md` | 58 | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05/04_shead_accessory.png` | `docs/handoff/codex_vis_t11_inventory_2026-06-05/04_shead_accessory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 6 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 76 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/01_inventory.png` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/01_inventory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 77 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/02_equipment_detail.png` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/02_equipment_detail.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 78 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/03_technique_panel.png` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/03_technique_panel.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 79 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/04_battle_victory.png` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/04_battle_victory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md` | 80 | 1 | `docs/handoff/codex_vis_textscale_mj_2026-06-07/05_main_menu.png` | `docs/handoff/codex_vis_textscale_mj_2026-06-07/05_main_menu.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_battle_b1_2026-06-01.md` | 3 | 1 | `docs/handoff/codex_visual_battle_b1_2026-06-01/` | `docs/handoff/codex_visual_battle_b1_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_battle_b2_2026-06-01.md` | 3 | 1 | `docs/handoff/codex_visual_battle_b2_2026-06-01/` | `docs/handoff/codex_visual_battle_b2_2026-06-01/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_battle_scene_2026-06-02.md` | 7 | 1 | `docs/handoff/codex_visual_battle_scene_2026-06-02/` | `docs/handoff/codex_visual_battle_scene_2026-06-02/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_chapter_cover_2026-06-01.md` | 8 | 1 | `docs/handoff/codex_visual_chapter_cover_2026-06-01/01_chapter_list_top.png` | `docs/handoff/codex_visual_chapter_cover_2026-06-01/01_chapter_list_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_chapter_cover_2026-06-01.md` | 9 | 1 | `docs/handoff/codex_visual_chapter_cover_2026-06-01/02_chapter_list_scroll.png` | `docs/handoff/codex_visual_chapter_cover_2026-06-01/02_chapter_list_scroll.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_check_p5_p4_1_2026-05-25.md` | 126 | 1 | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | 截图目录(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 22 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_bottom_fullscreen.png` | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_bottom_fullscreen.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 21 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_lower_fullscreen.png` | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_lower_fullscreen.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 20 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_mid_fullscreen.png` | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_mid_fullscreen.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 19 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_top_fullscreen.png` | `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_top_fullscreen.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 34 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_main_debug_entry.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_main_debug_entry.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 60 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_portrait_asset_contact_sheet.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_portrait_asset_contact_sheet.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 47 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_bottom.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_bottom.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 46 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_top.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 35 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_candidate_debug_list_no_portraits.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_candidate_debug_list_no_portraits.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 59 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_bottom.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_bottom.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 58 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_top.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 36 | 1 | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_recruit_dialog_no_portrait.png` | `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_recruit_dialog_no_portrait.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531.md` | 17 | 1 | `docs/handoff/visual_capture_manual_33265c8_20260531_165322/` | `docs/handoff/visual_capture_manual_33265c8_20260531_165322/` | 截图目录(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 21 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_member_row_closeup.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_member_row_closeup.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 20 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 23 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom_r2.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom_r2.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 19 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 22 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top_r2.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top_r2.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 24 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_force_recruit_list.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_force_recruit_list.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md` | 25 | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_recruit_confirm_dialog.png` | `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_recruit_confirm_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 38 | 2 | `docs/screenshots/w14_3_round2_disciple1_bottom_sheet.png` | `docs/screenshots/w14_3_round2_disciple1_bottom_sheet.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 42 | 2 | `docs/screenshots/w14_3_round2_disciple1_equip_new.png` | `docs/screenshots/w14_3_round2_disciple1_equip_new.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 37 | 2 | `docs/screenshots/w14_3_round2_disciple1_slot_filled.png` | `docs/screenshots/w14_3_round2_disciple1_slot_filled.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 41 | 2 | `docs/screenshots/w14_3_round2_disciple1_unequip.png` | `docs/screenshots/w14_3_round2_disciple1_unequip.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 39 | 2 | `docs/screenshots/w14_3_round2_disciple2_more_locks.png` | `docs/screenshots/w14_3_round2_disciple2_more_locks.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 40 | 2 | `docs/screenshots/w14_3_round2_founder_fewer_locks.png` | `docs/screenshots/w14_3_round2_founder_fewer_locks.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md` | 26 | 1 | `test/services/phase2_seed_service_test.dart` | `test/services/phase2_seed_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 42 | 2 | `docs/screenshots/w14_3a_encounter_skill_section_empty.png` | `docs/screenshots/w14_3a_encounter_skill_section_empty.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 43 | 2 | `docs/screenshots/w14_3a_encounter_skill_section_in_layout.png` | `docs/screenshots/w14_3a_encounter_skill_section_in_layout.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 38 | 2 | `docs/screenshots/w14_3c_dialog_opening_fadein.png` | `docs/screenshots/w14_3c_dialog_opening_fadein.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 39 | 2 | `docs/screenshots/w14_3c_dialog_opening_full.png` | `docs/screenshots/w14_3c_dialog_opening_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 41 | 2 | `docs/screenshots/w14_3c_dialog_outcome_crossfade.png` | `docs/screenshots/w14_3c_dialog_outcome_crossfade.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | 40 | 2 | `docs/screenshots/w14_3c_dialog_outcome_full.png` | `docs/screenshots/w14_3c_dialog_outcome_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 20 | 1 | `docs/screenshots/w15_round3/r3-1a_opening.png` | `docs/screenshots/w15_round3/r3-1a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 20 | 1 | `docs/screenshots/w15_round3/r3-1b_outcome.png` | `docs/screenshots/w15_round3/r3-1b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 21 | 1 | `docs/screenshots/w15_round3/r3-2a_opening.png` | `docs/screenshots/w15_round3/r3-2a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 21 | 1 | `docs/screenshots/w15_round3/r3-2b_outcome.png` | `docs/screenshots/w15_round3/r3-2b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 22 | 1 | `docs/screenshots/w15_round3/r3-3a_opening.png` | `docs/screenshots/w15_round3/r3-3a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 22 | 1 | `docs/screenshots/w15_round3/r3-3b_outcome.png` | `docs/screenshots/w15_round3/r3-3b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 23 | 1 | `docs/screenshots/w15_round3/r3-4a_opening.png` | `docs/screenshots/w15_round3/r3-4a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 23 | 1 | `docs/screenshots/w15_round3/r3-4b_outcome.png` | `docs/screenshots/w15_round3/r3-4b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 24 | 1 | `docs/screenshots/w15_round3/r3-5a_opening.png` | `docs/screenshots/w15_round3/r3-5a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 24 | 1 | `docs/screenshots/w15_round3/r3-5b_outcome.png` | `docs/screenshots/w15_round3/r3-5b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 25 | 1 | `docs/screenshots/w15_round3/r3-6a_opening.png` | `docs/screenshots/w15_round3/r3-6a_opening.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md` | 25 | 1 | `docs/screenshots/w15_round3/r3-6b_outcome.png` | `docs/screenshots/w15_round3/r3-6b_outcome.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 17 | 1 | `docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png` | `docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 18 | 1 | `docs/screenshots/w15_equipment_detail_round2/02_shenwu_tian_wen_jian.png` | `docs/screenshots/w15_equipment_detail_round2/02_shenwu_tian_wen_jian.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 19 | 1 | `docs/screenshots/w15_equipment_detail_round2/03_shenwu_kun_lun_pei.png` | `docs/screenshots/w15_equipment_detail_round2/03_shenwu_kun_lun_pei.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 20 | 1 | `docs/screenshots/w15_equipment_detail_round2/04_baowu_chang_hong_jian.png` | `docs/screenshots/w15_equipment_detail_round2/04_baowu_chang_hong_jian.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 21 | 1 | `docs/screenshots/w15_equipment_detail_round2/05_baowu_jin_si_jia.png` | `docs/screenshots/w15_equipment_detail_round2/05_baowu_jin_si_jia.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 22 | 1 | `docs/screenshots/w15_equipment_detail_round2/06_zhongqi_qing_xu_jian.png` | `docs/screenshots/w15_equipment_detail_round2/06_zhongqi_qing_xu_jian.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 23 | 1 | `docs/screenshots/w15_equipment_detail_round2/07_zhongqi_yin_lin_jia.png` | `docs/screenshots/w15_equipment_detail_round2/07_zhongqi_yin_lin_jia.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 24 | 1 | `docs/screenshots/w15_equipment_detail_round2/08_enhance_open.png` | `docs/screenshots/w15_equipment_detail_round2/08_enhance_open.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md` | 25 | 1 | `docs/screenshots/w15_equipment_detail_round2/09_enhance_plus1.png` | `docs/screenshots/w15_equipment_detail_round2/09_enhance_plus1.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 21 | 1 | `docs/screenshots/w15_equipment_detail/01_inventory.png` | `docs/screenshots/w15_equipment_detail/01_inventory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 22 | 1 | `docs/screenshots/w15_equipment_detail/02_liqi_long_quan.png` | `docs/screenshots/w15_equipment_detail/02_liqi_long_quan.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 23 | 1 | `docs/screenshots/w15_equipment_detail/03_haojiahuo_qing_feng_jian.png` | `docs/screenshots/w15_equipment_detail/03_haojiahuo_qing_feng_jian.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 24 | 1 | `docs/screenshots/w15_equipment_detail/04_xiangyang_gang_dao.png` | `docs/screenshots/w15_equipment_detail/04_xiangyang_gang_dao.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 25 | 1 | `docs/screenshots/w15_equipment_detail/05_xunchang_bu_yi.png` | `docs/screenshots/w15_equipment_detail/05_xunchang_bu_yi.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 26 | 1 | `docs/screenshots/w15_equipment_detail/06_enhance_tab.png` | `docs/screenshots/w15_equipment_detail/06_enhance_tab.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md` | 27 | 1 | `docs/screenshots/w15_equipment_detail/07_forging_tab.png` | `docs/screenshots/w15_equipment_detail/07_forging_tab.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 14 | 1 | `docs/screenshots/w15_resonance/` | `docs/screenshots/w15_resonance/` | 截图目录(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 21 | 1 | `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 22 | 1 | `docs/screenshots/w15_resonance/02_xunchang_shengshu_plus0.png` | `docs/screenshots/w15_resonance/02_xunchang_shengshu_plus0.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 23 | 1 | `docs/screenshots/w15_resonance/03_xiangyang_chenshou_plus5.png` | `docs/screenshots/w15_resonance/03_xiangyang_chenshou_plus5.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 24 | 1 | `docs/screenshots/w15_resonance/04_haojiahuo_moqi_plus10.png` | `docs/screenshots/w15_resonance/04_haojiahuo_moqi_plus10.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 25 | 1 | `docs/screenshots/w15_resonance/05_liqi_xinjian_plus15_heritage.png` | `docs/screenshots/w15_resonance/05_liqi_xinjian_plus15_heritage.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 26 | 1 | `docs/screenshots/w15_resonance/06_zhongqi_moqi_plus19.png` | `docs/screenshots/w15_resonance/06_zhongqi_moqi_plus19.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 27 | 1 | `docs/screenshots/w15_resonance/07_shenwu_xinjian_plus0.png` | `docs/screenshots/w15_resonance/07_shenwu_xinjian_plus0.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 28 | 1 | `docs/screenshots/w15_resonance/08_aperture_zero_slots.png` | `docs/screenshots/w15_resonance/08_aperture_zero_slots.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 29 | 1 | `docs/screenshots/w15_resonance/09_aperture_one_slot_attack.png` | `docs/screenshots/w15_resonance/09_aperture_one_slot_attack.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 30 | 1 | `docs/screenshots/w15_resonance/10_aperture_two_slots.png` | `docs/screenshots/w15_resonance/10_aperture_two_slots.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md` | 31 | 1 | `docs/screenshots/w15_resonance/11_aperture_three_slots_full.png` | `docs/screenshots/w15_resonance/11_aperture_three_slots_full.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md` | 18 | 1 | `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md` | 19 | 1 | `docs/screenshots/w15_stage_drop/02_inventory_after_drop.png` | `docs/screenshots/w15_stage_drop/02_inventory_after_drop.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md` | 20 | 1 | `docs/screenshots/w15_stage_drop/03_materials_mojianshi.png` | `docs/screenshots/w15_stage_drop/03_materials_mojianshi.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 29 | 1 | `docs/screenshots/w15_victory_dialog_round2/A1_mainline_01_01_dialog_localized.png` | `docs/screenshots/w15_victory_dialog_round2/A1_mainline_01_01_dialog_localized.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 30 | 1 | `docs/screenshots/w15_victory_dialog_round2/A2_mainline_01_01_narrative_after_dialog.png` | `docs/screenshots/w15_victory_dialog_round2/A2_mainline_01_01_narrative_after_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 31 | 1 | `docs/screenshots/w15_victory_dialog_round2/B1_mainline_01_02_dialog_advancement.png` | `docs/screenshots/w15_victory_dialog_round2/B1_mainline_01_02_dialog_advancement.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 32 | 1 | `docs/screenshots/w15_victory_dialog_round2/C1_tower_floor1_firstclear_advancement.png` | `docs/screenshots/w15_victory_dialog_round2/C1_tower_floor1_firstclear_advancement.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 33 | 1 | `docs/screenshots/w15_victory_dialog_round2/D1_inventory_material_tab_fresh.png` | `docs/screenshots/w15_victory_dialog_round2/D1_inventory_material_tab_fresh.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 34 | 1 | `docs/screenshots/w15_victory_dialog_round2/D2_inventory_material_tab_accumulated.png` | `docs/screenshots/w15_victory_dialog_round2/D2_inventory_material_tab_accumulated.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md` | 28 | 1 | `docs/screenshots/w15_victory_dialog_round2/seed_precheck_vc15_fresh_main_technique_r2.png` | `docs/screenshots/w15_victory_dialog_round2/seed_precheck_vc15_fresh_main_technique_r2.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 21 | 1 | `docs/screenshots/w15_victory_dialog/A1_mainline_01_01_dialog.png` | `docs/screenshots/w15_victory_dialog/A1_mainline_01_01_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 22 | 1 | `docs/screenshots/w15_victory_dialog/A2_mainline_01_01_narrative_after_dialog.png` | `docs/screenshots/w15_victory_dialog/A2_mainline_01_01_narrative_after_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 23 | 1 | `docs/screenshots/w15_victory_dialog/B1_mainline_01_02_dialog.png` | `docs/screenshots/w15_victory_dialog/B1_mainline_01_02_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 24 | 1 | `docs/screenshots/w15_victory_dialog/C1_tower_floor2_firstclear_actual.png` | `docs/screenshots/w15_victory_dialog/C1_tower_floor2_firstclear_actual.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 25 | 1 | `docs/screenshots/w15_victory_dialog/C2_tower_floor2_replay_actual.png` | `docs/screenshots/w15_victory_dialog/C2_tower_floor2_replay_actual.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 20 | 1 | `docs/screenshots/w16_festival_chip_visual_check/` | `docs/screenshots/w16_festival_chip_visual_check/` | 截图目录(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 31 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chongYang.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chongYang.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 26 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chunJie.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chunJie.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 32 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_cleared.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_cleared.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 28 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_duanWu.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_duanWu.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 29 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_qiXi.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_qiXi.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 27 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_yuanXiao.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_yuanXiao.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md` | 30 | 1 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_zhongQiu.png` | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_zhongQiu.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md` | 20 | 1 | `docs/screenshots/w17/` | `docs/screenshots/w17/` | 截图目录(多不入库) |
| `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md` | 26 | 1 | `docs/screenshots/w17/w17_festival_chip_chuXi.png` | `docs/screenshots/w17/w17_festival_chip_chuXi.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md` | 27 | 1 | `docs/screenshots/w17/w17_festival_chip_qingMingJie.png` | `docs/screenshots/w17/w17_festival_chip_qingMingJie.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md` | 28 | 1 | `docs/screenshots/w17/w17_festival_dialog_9_options.png` | `docs/screenshots/w17/w17_festival_dialog_9_options.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md` | 25 | 1 | `docs/screenshots/w17_lineage_panel/w17_lineage_main_menu_9buttons.png` | `docs/screenshots/w17_lineage_panel/w17_lineage_main_menu_9buttons.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md` | 26 | 1 | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_empty.png` | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_empty.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md` | 27 | 1 | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_full_after_p5.png` | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_full_after_p5.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 34 | 1 | `docs/screenshots/w18/w18_a1_battle_stage_01_05_injection.png` | `docs/screenshots/w18/w18_a1_battle_stage_01_05_injection.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 29 | 1 | `docs/screenshots/w18/w18_a1_chip_01_yinyang.png` | `docs/screenshots/w18/w18_a1_chip_01_yinyang.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 30 | 1 | `docs/screenshots/w18/w18_a1_chip_02_gangrou.png` | `docs/screenshots/w18/w18_a1_chip_02_gangrou.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 31 | 1 | `docs/screenshots/w18/w18_a1_chip_03_yinying.png` | `docs/screenshots/w18/w18_a1_chip_03_yinying.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 32 | 1 | `docs/screenshots/w18/w18_a1_chip_04_tongpai.png` | `docs/screenshots/w18/w18_a1_chip_04_tongpai.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 33 | 1 | `docs/screenshots/w18/w18_a1_chip_05_tongbei.png` | `docs/screenshots/w18/w18_a1_chip_05_tongbei.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md` | 28 | 1 | `docs/screenshots/w18/w18_a1_phase2menu_13buttons.png` | `docs/screenshots/w18/w18_a1_phase2menu_13buttons.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-14-v4.md` | 13 | 1 | `lib/ui/mainline/stage_entry_flow.dart` | `lib/ui/mainline/stage_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-14-v4.md` | 13 | 1 | `lib/ui/tower/tower_entry_flow.dart` | `lib/ui/tower/tower_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 62 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_main_menu.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_main_menu.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 61 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_start.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_start.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 63 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A1_chapterlist.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A1_chapterlist.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 65 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_scrolled.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_scrolled.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 64 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_top.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_top.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 66 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_phase2_menu.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_phase2_menu.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 67 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_after_seed_target.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_after_seed_target.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 68 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_chapterlist.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_chapterlist.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 69 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B2_chapterlist.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B2_chapterlist.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 70 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B3_chapterlist.png` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B3_chapterlist.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 43 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.err.log` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.err.log` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_whitescreen_repro_2026-05-30.md` | 42 | 1 | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.out.log` | `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.out.log` | 文档路径(疑移走/删除) |
| `docs/handoff/deepseek_p1_42_phase2_p1z_codex_dispatch_2026-05-18.md` | 115 | 1 | `data/codex/` | `data/codex/` | 数据路径(疑移除/改名) |
| `docs/handoff/deepseek_p1_44_continued_lore_dispatch_2026-05-19.md` | 326 | 1 | `docs/handoff/deepseek_p1_44_continued_lore_closeout_2026-05-19.md` | `docs/handoff/deepseek_p1_44_continued_lore_closeout_2026-05-19.md` | 文档路径(疑移走/删除) |
| `docs/handoff/deepseek_w15_34_insight_mapping_2026-05-15.md` | 22 | 3 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/handoff/deepseek_w15_35_lore_closeout_2026-05-15.md` | 54 | 1 | `test/data/lore_yaml_test.dart` | `test/data/lore_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md` | 55 | 1 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/handoff/deepseek_w16_festival_closeout_2026-05-16.md` | 95 | 1 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/deepseek_w16_festival_dispatch_2026-05-16.md` | 212 | 1 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/deepseek_w18_a2_event_yaml_dispatch_2026-05-17.md` | 234 | 1 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/g3_autoplay_toggle_closeout_2026-06-13.md` | 24 | 1 | `lib/features/battle/presentation/stage_auto_play_control.dart` | `lib/features/battle/presentation/stage_auto_play_control.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/g3_autoplay_toggle_closeout_2026-06-13.md` | 22 | 1 | `lib/shared/widgets/auto_play_toggle.dart` | `lib/shared/widgets/auto_play_toggle.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/h1_onboarding_audit_2026-05-29.md` | 47 | 1 | `docs/handoff/pen_visual_root_cause_a/` | `docs/handoff/pen_visual_root_cause_a/` | 文档路径(疑移走/删除) |
| `docs/handoff/lib_structure_audit_2026-05-19.md` | 63 | 1 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/m15_5h_autonomous_handoff_2026-05-29.md` | 13 | 1 | `test/tools/output/balance_simulation_2026-05-29.csv` | `test/tools/output/balance_simulation_2026-05-29.csv` | 生成物(不入库) |
| `docs/handoff/nightshift_20260520_handoff.md` | 24 | 1 | `data/narratives/techniques/` | `data/narratives/techniques/` | 数据路径(疑移除/改名) |
| `docs/handoff/nightshift_20260520_handoff.md` | 22 | 1 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/handoff/p0_40_local_leaderboard_spec.md` | 344 | 1 | `lib/features/main_menu/presentation/main_menu_screen.dart` | `lib/features/main_menu/presentation/main_menu_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_40_local_leaderboard_spec.md` | 102 | 1 | `lib/features/tower/domain/tower_progress.g.dart` | `lib/features/tower/domain/tower_progress.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_40_local_leaderboard_spec.md` | 368 | 1 | `test/features/debug/phase2_test_menu_test.dart` | `test/features/debug/phase2_test_menu_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_40_local_leaderboard_spec.md` | 367 | 1 | `test/features/main_menu/main_menu_screen_test.dart` | `test/features/main_menu/main_menu_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md` | 47 | 2 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md` | 40 | 2 | `lib/features/battle/domain/battle_engine.dart` | `lib/features/battle/domain/battle_engine.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 40 | 2 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 44 | 1 | `lib/core/application/battle_providers.dart:70/93` | `lib/core/application/battle_providers.dart:70/93` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 15 | 3 | `lib/features/battle/domain/battle_engine.dart` | `lib/features/battle/domain/battle_engine.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 50 | 1 | `lib/features/battle/presentation/battle_demo.dart:189` | `lib/features/battle/presentation/battle_demo.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 343 | 1 | `test/balance/battle_strategy_e2e_mainline_test.dart` | `test/balance/battle_strategy_e2e_mainline_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 343 | 1 | `test/balance/battle_strategy_e2e_tower_test.dart` | `test/balance/battle_strategy_e2e_tower_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p0_battle_strategy_spec.md` | 59 | 3 | `test/combat/battle_engine_test.dart` | `test/combat/battle_engine_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_a1_recruitment_audit_2026-05-21.md` | 239 | 1 | `lib/features/recruitment/domain/` | `lib/features/recruitment/domain/` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_a3_resonance_closeout_2026-05-21.md` | 60 | 1 | `test/combat/battle_engine_test.dart` | `test/combat/battle_engine_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_a3_resonance_phase0_audit_2026-05-21.md` | 29 | 1 | `lib/features/resonance/` | `lib/features/resonance/` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_a4_forging_phase0_audit_2026-05-21.md` | 138 | 1 | `test/data/equipment_def_test.dart` | `test/data/equipment_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_candidate5_claudemd_align_closeout_2026-05-21.md` | 20 | 1 | `lib/data/enum_localizations.dart:39` | `lib/data/enum_localizations.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_mac_handoff_2026-05-12.md` | 141 | 1 | `data/narratives/foo.yaml` | `data/narratives/foo.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p1_1_mac_handoff_2026-05-12.md` | 219 | 1 | `lib/services/mainline_progress_service.dart` | `lib/services/mainline_progress_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_mac_handoff_2026-05-12.md` | 220 | 1 | `lib/ui/mainline/stage_entry_flow.dart` | `lib/ui/mainline/stage_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_1_mac_handoff_2026-05-12.md` | 221 | 1 | `lib/ui/narrative/narrative_reader_screen.dart` | `lib/ui/narrative/narrative_reader_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md` | 26 | 1 | `test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart` | `test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md` | 25 | 1 | `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md` | 24 | 1 | `test/features/home_feed/presentation/home_feed_screen_time_format_test.dart` | `test/features/home_feed/presentation/home_feed_screen_time_format_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 216 | 1 | `lib/core/domain/game_event_summary.dart` | `lib/core/domain/game_event_summary.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 172 | 1 | `lib/features/event/application/game_event_service.g.dart` | `lib/features/event/application/game_event_service.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 173 | 1 | `lib/features/event/domain/game_event_summary.dart` | `lib/features/event/domain/game_event_summary.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 203 | 1 | `lib/features/home_feed/` | `lib/features/home_feed/` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 143 | 1 | `lib/features/home_feed/presentation/home_feed_screen.dart` | `lib/features/home_feed/presentation/home_feed_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 294 | 1 | `test/features/event/application/game_event_service_lore_hook_test.dart` | `test/features/event/application/game_event_service_lore_hook_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 228 | 1 | `test/features/home_feed/application/home_feed_providers_test.dart` | `test/features/home_feed/application/home_feed_providers_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 223 | 1 | `test/features/home_feed/presentation/home_feed_screen_test.dart` | `test/features/home_feed/presentation/home_feed_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md` | 27 | 1 | `lib/features/tutorial/application/tutorial_providers.g.dart` | `lib/features/tutorial/application/tutorial_providers.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md` | 26 | 1 | `lib/core/domain/save_data.g.dart` | `lib/core/domain/save_data.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1y_bubble_hint_spec.md` | 77 | 1 | `lib/core/domain/save_data.g.dart` | `lib/core/domain/save_data.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md` | 100 | 1 | `data/codex/` | `data/codex/` | 数据路径(疑移除/改名) |
| `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md` | 24 | 1 | `lib/features/codex/domain/codex_category.dart` | `lib/features/codex/domain/codex_category.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md` | 26 | 1 | `lib/features/codex/domain/codex_entry.dart` | `lib/features/codex/domain/codex_entry.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md` | 25 | 1 | `lib/features/codex/domain/codex_index.dart` | `lib/features/codex/domain/codex_index.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 18 | 4 | `data/codex/` | `data/codex/` | 数据路径(疑移除/改名) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 91 | 1 | `lib/features/codex/domain/codex_category.dart` | `lib/features/codex/domain/codex_category.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 92 | 2 | `lib/features/codex/domain/codex_entry.dart` | `lib/features/codex/domain/codex_entry.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 231 | 1 | `lib/features/codex/domain/codex_index.dart` | `lib/features/codex/domain/codex_index.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_p2_reality_check_2026-05-18.md` | 61 | 1 | `lib/features/codex/domain/codex_category.dart` | `lib/features/codex/domain/codex_category.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_p2_spec.md` | 11 | 2 | `lib/features/codex/domain/codex_category.dart` | `lib/features/codex/domain/codex_category.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_p2_spec.md` | 68 | 1 | `lib/features/codex/domain/codex_entry.dart` | `lib/features/codex/domain/codex_entry.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_p2_spec.md` | 13 | 2 | `lib/features/codex/domain/codex_index.dart` | `lib/features/codex/domain/codex_index.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_p2_workflow_reflection_2026-05-18.md` | 25 | 1 | `test/features/X/` | `test/features/X/` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md` | 49 | 2 | `../../.claude/projects/-Users-a10506/memory/feedback_audit_report_phase0_verify.md` | `../../.claude/projects/-Users-a10506/memory/feedback_audit_report_phase0_verify.md` | 出 repo 边界 |
| `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md` | 58 | 1 | `data/events/_archive/yu_zhong_qiao_men.yaml` | `data/events/_archive/yu_zhong_qiao_men.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md` | 51 | 1 | `lib/features/encounter/domain/encounter_progress.g.dart` | `lib/features/encounter/domain/encounter_progress.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md` | 91 | 1 | `lib/features/encounter/domain/encounter_progress.g.dart` | `lib/features/encounter/domain/encounter_progress.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_3_ascension_closeout_2026-05-24.md` | 37 | 1 | `test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart` | `test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_mainline_audit_2026-05-21.md` | 196 | 1 | `data/narratives/chapters/chapter_04/05/06.yaml` | `data/narratives/chapters/chapter_04/05/06.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p2_x_chapter6_phase0_reality_check_2026-05-22.md` | 35 | 1 | `test/features/chapter_list_screen_test.dart` | `test/features/chapter_list_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md` | 51 | 1 | `lib/features/inner_demon/domain/inner_demon_def.dart` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_x_inner_demon_implementation_closeout_2026-05-22.md` | 39 | 1 | `lib/features/inner_demon/domain/inner_demon_def.dart` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_x_inner_demon_phase0_reality_check_2026-05-22.md` | 59 | 1 | `docs/handoff/p3_x_inner_demon_spec_2026-05-22.md` | `docs/handoff/p3_x_inner_demon_spec_2026-05-22.md` | 文档路径(疑移走/删除) |
| `docs/handoff/p2_x_inner_demon_spec_2026-05-22.md` | 142 | 1 | `lib/features/inheritance/founder_buff_service.dart` | `lib/features/inheritance/founder_buff_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_1_lightfoot_closeout_2026-05-23.md` | 58 | 1 | `lib/features/light_foot/domain/light_foot_def.dart` | `lib/features/light_foot/domain/light_foot_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_2_c_fix_1_numerical_overhaul_2026-05-24.md` | 33 | 1 | `lib/features/mass_battle/domain/mass_battle_def.dart` | `lib/features/mass_battle/domain/mass_battle_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_2b_residual_hp_closeout_2026-05-24.md` | 25 | 1 | `lib/features/mass_battle/domain/mass_battle_def.dart` | `lib/features/mass_battle/domain/mass_battle_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_tech_debt_closeout_2026-05-25.md` | 49 | 1 | `test/data/numbers_config_pvp_def_test.dart` | `test/data/numbers_config_pvp_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_tech_debt_closeout_2026-05-25.md` | 57 | 1 | `test/features/pvp/pvp_service_test.dart` | `test/features/pvp/pvp_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p4_1_b1_schema_closeout_2026-05-25.md` | 15 | 1 | `lib/features/sect/domain/sect_rank.dart` | `lib/features/sect/domain/sect_rank.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p4_1_b1_schema_closeout_2026-05-25.md` | 16 | 1 | `lib/features/sect/domain/territory_def.dart` | `lib/features/sect/domain/territory_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 17 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_01_main_menu.png` | `docs/handoff/h1_visual_check_screenshots/h1_01_main_menu.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 18 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_02_lategame_locked.png` | `docs/handoff/h1_visual_check_screenshots/h1_02_lategame_locked.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 19 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_03_pvp_locked.png` | `docs/handoff/h1_visual_check_screenshots/h1_03_pvp_locked.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 20 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_04_social_locked.png` | `docs/handoff/h1_visual_check_screenshots/h1_04_social_locked.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 21 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_05_equip_picker_open.png` | `docs/handoff/h1_visual_check_screenshots/h1_05_equip_picker_open.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 22 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_06_equipped.png` | `docs/handoff/h1_visual_check_screenshots/h1_06_equipped.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 23 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_07_realm_locked.png` | `docs/handoff/h1_visual_check_screenshots/h1_07_realm_locked.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 24 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_08_unequip.png` | `docs/handoff/h1_visual_check_screenshots/h1_08_unequip.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 26 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_10_chapter_transition_button.png` | `docs/handoff/h1_visual_check_screenshots/h1_10_chapter_transition_button.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 27 | 1 | `docs/handoff/h1_visual_check_screenshots/h1_11_battle.png` | `docs/handoff/h1_visual_check_screenshots/h1_11_battle.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 13 | 1 | `docs/handoff/p4_1_1_screenshots/step0_game_onboarding_window.png` | `docs/handoff/p4_1_1_screenshots/step0_game_onboarding_window.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 14 | 1 | `docs/handoff/p4_1_1_screenshots/step0_main_loaded.png` | `docs/handoff/p4_1_1_screenshots/step0_main_loaded.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 29 | 1 | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_after_outcome_no_confirm.png` | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_after_outcome_no_confirm.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 28 | 2 | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_confirm_dialog.png` | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_confirm_dialog.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 27 | 1 | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_opening_options.png` | `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_opening_options.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 45 | 1 | `docs/handoff/p4_1_1_screenshots/step2_chapter1_stage_list.png` | `docs/handoff/p4_1_1_screenshots/step2_chapter1_stage_list.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 47 | 1 | `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_after_wait.png` | `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_after_wait.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 46 | 1 | `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_battle_or_result.png` | `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_battle_or_result.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 63 | 1 | `docs/handoff/p4_1_1_screenshots/step3_character_panel_lineage_sect_membership.png` | `docs/handoff/p4_1_1_screenshots/step3_character_panel_lineage_sect_membership.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 80 | 1 | `docs/handoff/p4_1_1_screenshots/step4_desert_opening_options.png` | `docs/handoff/p4_1_1_screenshots/step4_desert_opening_options.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 81 | 1 | `docs/handoff/p4_1_1_screenshots/step4_desert_outcome_body.png` | `docs/handoff/p4_1_1_screenshots/step4_desert_outcome_body.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md` | 82 | 1 | `docs/handoff/p4_1_1_screenshots/step4_mountain_outcome_or_phase2.png` | `docs/handoff/p4_1_1_screenshots/step4_mountain_outcome_or_phase2.png` | 截图/图片(多不入库) |
| `docs/handoff/pen_visual_verify_r4_p2_1_content_drop_2026-05-28.md` | 5 | 1 | `docs/handoff/r4_visual_check_screenshots/` | `docs/handoff/r4_visual_check_screenshots/` | 截图目录(多不入库) |
| `docs/handoff/session_closeout_2026-05-25_v2.2_warmup_cleanup.md` | 31 | 3 | `lib/foo.dart` | `lib/foo.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/session_closeout_2026-05-25_v2.2_warmup_cleanup.md` | 32 | 1 | `test/foo_test.dart` | `test/foo_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/session_p2_audit_closeout_2026-05-21.md` | 77 | 1 | `data/narratives/chapters/chapter_p2_01.yaml` | `data/narratives/chapters/chapter_p2_01.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/stage_audit_2026-05-21.md` | 146 | 1 | `docs/handoff/_archived_phase5/` | `docs/handoff/_archived_phase5/` | 文档路径(疑移走/删除) |
| `docs/handoff/steam_store_page_2026-06-09.md` | 3 | 1 | `docs/handoff/visual_capture_e711a5b_20260609_153133/` | `docs/handoff/visual_capture_e711a5b_20260609_153133/` | 截图目录(多不入库) |
| `docs/handoff/t52_visual_check_spec_2026-05-12.md` | 7 | 1 | `docs/screenshots/phase3_w3_seclusion/` | `docs/screenshots/phase3_w3_seclusion/` | 截图目录(多不入库) |
| `docs/handoff/t58_visual_check_spec_2026-05-13.md` | 7 | 1 | `docs/screenshots/phase3_w4/` | `docs/screenshots/phase3_w4/` | 截图目录(多不入库) |
| `docs/handoff/t62_visual_check_spec_2026-05-13.md` | 7 | 2 | `docs/screenshots/phase3_w5/` | `docs/screenshots/phase3_w5/` | 截图目录(多不入库) |
| `docs/handoff/week10_phase4_defeat_resolution_2026-05-13.md` | 111 | 1 | `lib/providers/battle_providers.dart:108` | `lib/providers/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week11_victory_resolution_2026-05-13.md` | 75 | 1 | `lib/services/battle_resolution.dart` | `lib/services/battle_resolution.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week11_victory_resolution_2026-05-13.md` | 99 | 1 | `lib/ui/mainline/stage_entry_flow.dart` | `lib/ui/mainline/stage_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week11_victory_resolution_2026-05-13.md` | 106 | 1 | `lib/ui/tower/tower_entry_flow.dart` | `lib/ui/tower/tower_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week11_victory_resolution_2026-05-13.md` | 112 | 1 | `test/services/battle_resolution_test.dart` | `test/services/battle_resolution_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md` | 54 | 1 | `lib/data/models/skill_usage_entry.dart:29` | `lib/data/models/skill_usage_entry.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md` | 114 | 1 | `test/services/phase2_seed_service_test.dart` | `test/services/phase2_seed_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md` | 62 | 2 | `test/services/skill_usage_persist_test.dart` | `test/services/skill_usage_persist_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 35 | 1 | `lib/data/models/encounter_progress.dart` | `lib/data/models/encounter_progress.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 72 | 1 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 41 | 1 | `lib/services/encounter_service.dart` | `lib/services/encounter_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 51 | 1 | `lib/ui/encounter/encounter_dialog.dart` | `lib/ui/encounter/encounter_dialog.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 58 | 1 | `lib/ui/mainline/stage_entry_flow.dart` | `lib/ui/mainline/stage_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 81 | 1 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md` | 80 | 1 | `test/services/encounter_service_test.dart` | `test/services/encounter_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 47 | 1 | `lib/data/models/encounter_progress.dart` | `lib/data/models/encounter_progress.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 31 | 1 | `lib/data/models/enums.dart` | `lib/data/models/enums.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 77 | 1 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 55 | 1 | `lib/services/encounter_service.dart` | `lib/services/encounter_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 60 | 1 | `lib/services/seclusion_service.dart` | `lib/services/seclusion_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 67 | 1 | `lib/ui/encounter/encounter_hook.dart` | `lib/ui/encounter/encounter_hook.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 72 | 1 | `lib/ui/seclusion/active_retreat_screen.dart` | `lib/ui/seclusion/active_retreat_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 142 | 2 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 143 | 1 | `test/data/seclusion_map_def_test.dart` | `test/data/seclusion_map_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 140 | 1 | `test/services/encounter_service_test.dart` | `test/services/encounter_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md` | 141 | 1 | `test/services/seclusion_service_test.dart` | `test/services/seclusion_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 49 | 1 | `lib/combat/battle_state.dart` | `lib/combat/battle_state.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 34 | 1 | `lib/data/models/character.dart` | `lib/data/models/character.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 72 | 1 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 40 | 1 | `lib/services/encounter_service.dart` | `lib/services/encounter_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 63 | 1 | `lib/ui/character_panel/encounter_skill_section.dart` | `lib/ui/character_panel/encounter_skill_section.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 116 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 97 | 1 | `test/data/encounter_skills_yaml_test.dart` | `test/data/encounter_skills_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` | 98 | 1 | `test/services/encounter_service_test.dart` | `test/services/encounter_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_4_deepseek_audit_dispatch_2026-05-15.md` | 17 | 2 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 78 | 1 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 84 | 1 | `lib/ui/debug/encounter_debug_picker.dart` | `lib/ui/debug/encounter_debug_picker.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 57 | 1 | `lib/ui/encounter/encounter_dialog.dart` | `lib/ui/encounter/encounter_dialog.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 193 | 1 | `test/data/encounter_skills_yaml_test.dart` | `test/data/encounter_skills_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 192 | 1 | `test/data/encounter_yaml_test.dart` | `test/data/encounter_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 194 | 1 | `test/services/encounter_service_test.dart` | `test/services/encounter_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 195 | 1 | `test/services/phase2_seed_service_test.dart` | `test/services/phase2_seed_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week14_full_closeout_2026-05-15.md` | 196 | 1 | `test/ui/main_menu/phase2_test_menu_test.dart` | `test/ui/main_menu/phase2_test_menu_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase2_consumption_layer_2026-05-16.md` | 31 | 1 | `lib/core/domain/character.g.dart` | `lib/core/domain/character.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase2_consumption_layer_2026-05-16.md` | 34 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_advancement_2026-05-16.md` | 60 | 1 | `lib/features/tower/domain/tower_floor_def.dart` | `lib/features/tower/domain/tower_floor_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_advancement_2026-05-16.md` | 61 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_followup_inventory_material_tab_2026-05-16.md` | 41 | 1 | `lib/core/application/inventory_providers.g.dart` | `lib/core/application/inventory_providers.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_followup_inventory_material_tab_2026-05-16.md` | 39 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_followup_victory_dialog_2026-05-16.md` | 34 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_followup_victory_dialog_round2_2026-05-16.md` | 35 | 1 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_phase3_followup_victory_dialog_round2_2026-05-16.md` | 39 | 2 | `test/ui/main_menu/phase2_test_menu_test.dart` | `test/ui/main_menu/phase2_test_menu_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_seclusion_dimensions_closeout_2026-05-15.md` | 21 | 2 | `lib/services/seclusion_service.dart` | `lib/services/seclusion_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_seclusion_dimensions_closeout_2026-05-15.md` | 23 | 2 | `test/data/seclusion_map_def_test.dart` | `test/data/seclusion_map_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_30_seclusion_dimensions_closeout_2026-05-15.md` | 22 | 2 | `test/services/seclusion_service_test.dart` | `test/services/seclusion_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_audit_c2_closeout_2026-05-15.md` | 70 | 1 | `data/narratives/techniques/insights/` | `data/narratives/techniques/insights/` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_audit_c2_closeout_2026-05-15.md` | 32 | 1 | `lib/ui/encounter/encounter_dialog.dart` | `lib/ui/encounter/encounter_dialog.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_audit_c2_closeout_2026-05-15.md` | 27 | 1 | `lib/ui/encounter/encounter_outcome_banner_test.dart` | `lib/ui/encounter/encounter_outcome_banner_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_audit_c2_closeout_2026-05-15.md` | 91 | 1 | `test/ui/encounter/encounter_outcome_banner_test.dart` | `test/ui/encounter/encounter_outcome_banner_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_deepseek_dispatch_35_lore_2026-05-15.md` | 292 | 1 | `test/data/lore_yaml_test.dart` | `test/data/lore_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_full_closeout_2026-05-15.md` | 30 | 1 | `docs/screenshots/w15_equipment_detail/` | `docs/screenshots/w15_equipment_detail/` | 截图目录(多不入库) |
| `docs/handoff/week15_full_closeout_2026-05-15.md` | 30 | 1 | `docs/screenshots/w15_round3/` | `docs/screenshots/w15_round3/` | 截图目录(多不入库) |
| `docs/handoff/week15_full_closeout_2026-05-15.md` | 25 | 1 | `lib/ui/inventory/equipment_detail_screen.dart` | `lib/ui/inventory/equipment_detail_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_full_closeout_2026-05-15.md` | 26 | 1 | `test/ui/inventory/equipment_detail_screen_test.dart` | `test/ui/inventory/equipment_detail_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_g_pen_t64_crlf_fix_2026-05-16.md` | 40 | 1 | `test/features/tower/domain/tower_floor_def_test.dart:218/235/266` | `test/features/tower/domain/tower_floor_def_test.dart:218/235/266` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_loreloader_接入_2026-05-15.md` | 45 | 2 | `lib/data/models/lore.dart` | `lib/data/models/lore.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_open_session_closeout_2026-05-15.md` | 51 | 2 | `test/data/encounter_skills_yaml_test.dart` | `test/data/encounter_skills_yaml_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 213 | 1 | `lib/data/models/retreat_session.dart` | `lib/data/models/retreat_session.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 46 | 2 | `lib/features/README.md` | `lib/features/README.md` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 77 | 1 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 213 | 1 | `lib/services/seclusion_service.dart` | `lib/services/seclusion_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 76 | 1 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 66 | 1 | `lib/ui/seclusion/` | `lib/ui/seclusion/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 66 | 1 | `test/ui/seclusion/` | `test/ui/seclusion/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 60 | 3 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 63 | 1 | `lib/services/drop_service.dart` | `lib/services/drop_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 97 | 2 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 64 | 1 | `lib/services/stage_battle_setup.dart` | `lib/services/stage_battle_setup.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 249 | 1 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 134 | 1 | `lib/ui/character_panel/encounter_skill_section.dart` | `lib/ui/character_panel/encounter_skill_section.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 135 | 1 | `lib/ui/debug/encounter_debug_picker.dart` | `lib/ui/debug/encounter_debug_picker.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 124 | 1 | `lib/ui/encounter` | `lib/ui/encounter` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 59 | 2 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 92 | 1 | `lib/ui/mainline` | `lib/ui/mainline` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 56 | 1 | `lib/ui/tower` | `lib/ui/tower` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 102 | 3 | `test/services/phase2_seed_service_test.dart` | `test/services/phase2_seed_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 124 | 1 | `test/ui/encounter` | `test/ui/encounter` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 92 | 1 | `test/ui/mainline` | `test/ui/mainline` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 56 | 1 | `test/ui/tower` | `test/ui/tower` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 201 | 1 | `data/models/` | `data/models/` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 148 | 1 | `lib/combat/` | `lib/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 44 | 1 | `lib/features/character_panel/domain/character.dart` | `lib/features/character_panel/domain/character.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 148 | 1 | `lib/ui/battle/` | `lib/ui/battle/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 113 | 1 | `lib/ui/debug/encounter_debug_picker.dart` | `lib/ui/debug/encounter_debug_picker.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 151 | 1 | `lib/ui/effects/` | `lib/ui/effects/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 149 | 1 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 151 | 1 | `lib/ui/theme/` | `lib/ui/theme/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 205 | 1 | `/data/models/` | `/data/models/` | 其他 |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 251 | 2 | `lib/combat/` | `lib/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 313 | 1 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 310 | 1 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 99 | 1 | `lib/services/battle_resolution.dart` | `lib/services/battle_resolution.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 100 | 1 | `lib/services/cultivation_service.dart` | `lib/services/cultivation_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 101 | 1 | `lib/services/dispel_service.dart` | `lib/services/dispel_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 107 | 1 | `lib/services/drop_service.dart` | `lib/services/drop_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 311 | 1 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 252 | 2 | `lib/ui/battle/` | `lib/ui/battle/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 94 | 1 | `lib/ui/debug/battle_test_menu.dart:8` | `lib/ui/debug/battle_test_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 77 | 1 | `lib/ui/debug` | `lib/ui/debug` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 13 | 2 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 92 | 1 | `lib/ui/debug/battle_test_menu.dart` | `lib/ui/debug/battle_test_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 88 | 1 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 103 | 1 | `test/services` | `test/services` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 13 | 2 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 89 | 1 | `test/ui/main_menu/phase2_test_menu_test.dart` | `test/ui/main_menu/phase2_test_menu_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 65 | 2 | `../data/X` | `../data/X` | 相对父目录(边界) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 208 | 1 | `lib/features/X/application/` | `lib/features/X/application/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 327 | 1 | `lib/features/service_providers.dart` | `lib/features/service_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 208 | 1 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 288 | 1 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 289 | 1 | `test/ui/enhancement/` | `test/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 144 | 1 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 64 | 2 | `../data/X` | `../data/X` | 相对父目录(边界) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 46 | 1 | `lib/features/technique_panel/application/` | `lib/features/technique_panel/application/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 37 | 1 | `lib/fixtures/phase2_seed_service.dart` | `lib/fixtures/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 13 | 2 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 116 | 1 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 54 | 3 | `../data/models/X.dart` | `../data/models/X.dart` | 相对父目录(边界) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 55 | 1 | `../data/numbers_config.dart` | `../data/numbers_config.dart` | 相对父目录(边界) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 54 | 3 | `/data/models/` | `/data/models/` | 其他 |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 54 | 1 | `/data/models/X.dart` | `/data/models/X.dart` | 其他 |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 163 | 2 | `data/models/` | `data/models/` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 116 | 1 | `lib/combat/` | `lib/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 13 | 2 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 13 | 3 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 116 | 1 | `lib/ui/battle/` | `lib/ui/battle/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 117 | 1 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 17 | 1 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 20 | 1 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 22 | 1 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 92 | 1 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 93 | 1 | `lib/ui/narrative/narrative_reader_screen.dart` | `lib/ui/narrative/narrative_reader_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 23 | 1 | `lib/utils/` | `lib/utils/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_resonance_closeout_2026-05-15.md` | 87 | 1 | `docs/screenshots/w15_resonance/` | `docs/screenshots/w15_resonance/` | 截图目录(多不入库) |
| `docs/handoff/week15_resonance_closeout_2026-05-15.md` | 41 | 1 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_resonance_closeout_2026-05-15.md` | 100 | 1 | `lib/ui/inventory/equipment_detail_screen.dart:148` | `lib/ui/inventory/equipment_detail_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_section12_7_school_extra_effects_2026-05-16.md` | 64 | 1 | `lib/features/battle/domain/battle_engine.dart` | `lib/features/battle/domain/battle_engine.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_section12_7_school_extra_effects_2026-05-16.md` | 73 | 1 | `test/combat/battle_engine_test.dart` | `test/combat/battle_engine_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_section12_closeout_2026-05-15.md` | 36 | 1 | `lib/data/enum_localizations.dart:39` | `lib/data/enum_localizations.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week4_d_minimal_spec_2026-05-13.md` | 99 | 1 | `data/lineage_heritages.yaml` | `data/lineage_heritages.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/week4_d_minimal_spec_2026-05-13.md` | 55 | 2 | `data/lore/masters/` | `data/lore/masters/` | 数据路径(疑移除/改名) |
| `docs/handoff/week4_t53_t55_closeout_2026-05-13.md` | 132 | 1 | `lib/ui/main_menu.dart:77-78` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week9_a_audit_closeout_2026-05-13.md` | 39 | 1 | `lib/providers/tower_providers.dart` | `lib/providers/tower_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week9_a_audit_closeout_2026-05-13.md` | 35 | 1 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week9_a_audit_closeout_2026-05-13.md` | 38 | 2 | `lib/ui/tower/tower_entry_flow.dart` | `lib/ui/tower/tower_entry_flow.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week9_a_audit_closeout_2026-05-13.md` | 37 | 1 | `lib/ui/tower/tower_floor_card.dart` | `lib/ui/tower/tower_floor_card.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week9_a_audit_closeout_2026-05-13.md` | 36 | 1 | `lib/ui/tower/tower_floor_list_screen.dart` | `lib/ui/tower/tower_floor_list_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/wf_audit_pilot_2026-05-29.md` | 19 | 1 | `lib/features/codex/domain/codex_category.dart:36` | `lib/features/codex/domain/codex_category.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/wf_audit_pilot_2026-05-29.md` | 47 | 1 | `lib/features/mass_battle/domain/mass_battle_def.dart:90` | `lib/features/mass_battle/domain/mass_battle_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_d3_plugin_enable_dry_run_2026-05-17.md` | 19 | 1 | `test/features/tower/presentation/tower_entry_flow_test.dart:53:9` | `test/features/tower/presentation/tower_entry_flow_test.dart:53` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 145 | 2 | `lib/data/enum_localizations.dart` | `lib/data/enum_localizations.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 127 | 1 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 125 | 1 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 126 | 1 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 123 | 1 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md` | 124 | 1 | `lib/utils/` | `lib/utils/` | 代码路径(疑重构/移走) |
| `docs/handoff/wuxia_orphan_events_rematch_prep_2026-05-17.md` | 71 | 1 | `data/events/_archive/huang_yuan_yi_zhong.yaml` | `data/events/_archive/huang_yuan_yi_zhong.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md` | 78 | 1 | `lib/features/character_panel/presentation/lineage_panel.dart` | `lib/features/character_panel/presentation/lineage_panel.dart` | 代码路径(疑重构/移走) |
| `docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md` | 22 | 1 | `lib/core/application/battle_providers.dart:58/75` | `lib/core/application/battle_providers.dart:58/75` | 代码路径(疑重构/移走) |
| `docs/phase0/p4_1_sect_management_phase0_2026-05-25.md` | 99 | 1 | `lib/features/sect_management/` | `lib/features/sect_management/` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-05-29_1355_review红线公式收敛.md` | 33 | 1 | `lib/core/combat/formulas.dart` | `lib/core/combat/formulas.dart` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-05-29_1906_经济曲线验证与红线统一.md` | 10 | 1 | `test/tools/output/idle_economy_2026-05-29.md` | `test/tools/output/idle_economy_2026-05-29.md` | 生成物(不入库) |
| `docs/sessions/2026-05-30_0053_数值平衡与H1上手polish.md` | 14 | 1 | `docs/handoff/pen_visual_root_cause_a/` | `docs/handoff/pen_visual_root_cause_a/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-05-30_1319_Codex验收triage与清理.md` | 14 | 1 | `docs/handoff/codex_visual_r5_2026-05-30/` | `docs/handoff/codex_visual_r5_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-05-30_1516_4决策第三层.md` | 12 | 1 | `test/tools/output/balance_summary_2026-05-29.md` | `test/tools/output/balance_summary_2026-05-29.md` | 生成物(不入库) |
| `docs/sessions/2026-05-30_2256_V3神物金验收.md` | 10 | 1 | `docs/handoff/v3_shenwu_drop_2026-05-30/` | `docs/handoff/v3_shenwu_drop_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-05-30_2323_§9视觉验收收口.md` | 12 | 1 | `docs/handoff/v3_checklist_s9_2026-05-30/` | `docs/handoff/v3_checklist_s9_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-05-31_0023_G4验收闭环.md` | 15 | 1 | `docs/handoff/g4_narrative_tap_2026-05-30/` | `docs/handoff/g4_narrative_tap_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-05-31_1507_出版美术心法面板.md` | 11 | 1 | `lib/shared/widgets/wuxia_paper_panel.dart` | `lib/shared/widgets/wuxia_paper_panel.dart` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-02_1925_窗口验收Pen修复性能验证.md` | 10 | 1 | `docs/handoff/window_min_size_2026-06-02/` | `docs/handoff/window_min_size_2026-06-02/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-02_2104_P0缺图门禁.md` | 29 | 1 | `test/tools/output/stress_2026-06-02.md` | `test/tools/output/stress_2026-06-02.md` | 生成物(不入库) |
| `docs/sessions/2026-06-04_1529_角色面板心魔与主修hero.md` | 14 | 1 | `docs/handoff/vis_char_panel_bc_2026-06-04/` | `docs/handoff/vis_char_panel_bc_2026-06-04/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-09_2206_可玩性P0破招与音频.md` | 53 | 1 | `test/tools/output/stress_2026-06-02.md` | `test/tools/output/stress_2026-06-02.md` | 生成物(不入库) |
| `docs/sessions/2026-06-09_2354_可玩性P1a与音频体检.md` | 30 | 1 | `test/tools/output/stress_2026-06-02.md` | `test/tools/output/stress_2026-06-02.md` | 生成物(不入库) |
| `docs/sessions/2026-06-10_0947_可玩性P1a养成内核.md` | 33 | 1 | `test/tools/output/stress_2026-06-02.md` | `test/tools/output/stress_2026-06-02.md` | 生成物(不入库) |
| `docs/sessions/2026-06-12_1750_D进度组件_E音频摸底.md` | 24 | 1 | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-13_半手动P0步骤5全闭环.md` | 11 | 1 | `docs/superpowers/plans/2026-06-13-semi-manual-step5-full-closeout.md` | `docs/superpowers/plans/2026-06-13-semi-manual-step5-full-closeout.md` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-14_1816_红线收口.md` | 25 | 1 | `docs/acceptance_screenshots/` | `docs/acceptance_screenshots/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-14_1936_软红线放宽诊断.md` | 24 | 1 | `docs/demos/` | `docs/demos/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-14_1936_软红线放宽诊断.md` | 24 | 1 | `docs/demos/battle_skill_status_ui_demo.html` | `docs/demos/battle_skill_status_ui_demo.html` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-14_1936_软红线放宽诊断.md` | 25 | 1 | `test/tools/output/extreme_cycle_diagnosis_2026-06-14.md` | `test/tools/output/extreme_cycle_diagnosis_2026-06-14.md` | 生成物(不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 8 | 1 | `docs/reviews/l1_acceptance/` | `docs/reviews/l1_acceptance/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 37 | 1 | `docs/reviews/l1_acceptance/f11_after.png` | `docs/reviews/l1_acceptance/f11_after.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 36 | 1 | `docs/reviews/l1_acceptance/f11_before.png` | `docs/reviews/l1_acceptance/f11_before.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 17 | 1 | `docs/reviews/l1_acceptance/fullscreen_off.png` | `docs/reviews/l1_acceptance/fullscreen_off.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 16 | 1 | `docs/reviews/l1_acceptance/fullscreen_on.png` | `docs/reviews/l1_acceptance/fullscreen_on.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 49 | 1 | `docs/reviews/l1_acceptance/m2_recap_card.png` | `docs/reviews/l1_acceptance/m2_recap_card.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 27 | 1 | `docs/reviews/l1_acceptance/res_1080.png` | `docs/reviews/l1_acceptance/res_1080.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 25 | 1 | `docs/reviews/l1_acceptance/res_720.png` | `docs/reviews/l1_acceptance/res_720.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 26 | 1 | `docs/reviews/l1_acceptance/res_900.png` | `docs/reviews/l1_acceptance/res_900.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 28 | 1 | `docs/reviews/l1_acceptance/res_dropdown_disabled_in_fullscreen.png` | `docs/reviews/l1_acceptance/res_dropdown_disabled_in_fullscreen.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 43 | 1 | `docs/reviews/l1_acceptance/restart_restored.png` | `docs/reviews/l1_acceptance/restart_restored.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 82 | 1 | `docs/reviews/l1_acceptance/round2/r2_after_gocollect.png` | `docs/reviews/l1_acceptance/round2/r2_after_gocollect.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 69 | 1 | `docs/reviews/l1_acceptance/round2/r2_altenter_after.png` | `docs/reviews/l1_acceptance/round2/r2_altenter_after.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 68 | 1 | `docs/reviews/l1_acceptance/round2/r2_altenter_before.png` | `docs/reviews/l1_acceptance/round2/r2_altenter_before.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_l1_display_codex_acceptance.md` | 81 | 1 | `docs/reviews/l1_acceptance/round2/r2_recap_card.png` | `docs/reviews/l1_acceptance/round2/r2_recap_card.png` | 截图/图片(多不入库) |
| `docs/sessions/2026-06-15_overnight_autonomous_handoff.md` | 11 | 1 | `docs/spec/2026-06-15-m2-offline-recap-design-DRAFT.md` | `docs/spec/2026-06-15-m2-offline-recap-design-DRAFT.md` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-18_1243_掉落传闻UI.md` | 25 | 1 | `docs/handoff/codex_loot_dialog_2026-06-18/` | `docs/handoff/codex_loot_dialog_2026-06-18/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-26_1115_交接_菜单与扫荡bug.md` | 21 | 1 | `lib/features/home_feed/` | `lib/features/home_feed/` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-28_1325_睡觉模式集成.md` | 25 | 1 | `data/narratives/retreat/` | `data/narratives/retreat/` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-06-28_1505_战前情报optin.md` | 37 | 1 | `data/narratives/retreat/` | `data/narratives/retreat/` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-06-30_1252_视觉验收修复.md` | 28 | 1 | `docs/handoff/visual_acceptance_2026-06-30/` | `docs/handoff/visual_acceptance_2026-06-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-30_1326_维护轮清债.md` | 25 | 1 | `docs/handoff/visual_acceptance_2026-06-30/` | `docs/handoff/visual_acceptance_2026-06-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-30_2133_视觉验收重验收口.md` | 23 | 1 | `docs/handoff/visual_acceptance_2026-06-30/` | `docs/handoff/visual_acceptance_2026-06-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-06-30_2133_视觉验收重验收口.md` | 10 | 1 | `docs/handoff/visual_acceptance_rerun_2026-06-30/rerun_triage_report.md` | `docs/handoff/visual_acceptance_rerun_2026-06-30/rerun_triage_report.md` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-01_1637_爬塔复核.md` | 25 | 1 | `test/tools/output/tower_boss_feel_2026-07-01.md` | `test/tools/output/tower_boss_feel_2026-07-01.md` | 生成物(不入库) |
| `docs/sessions/2026-07-01_tap两段点选+纸底夜间合并push.md` | 24 | 1 | `docs/handoff/visual_acceptance_2026-06-30/` | `docs/handoff/visual_acceptance_2026-06-30/` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-06_night_挂机夜批.md` | 28 | 1 | `test/tools/early_difficulty_gate_probe_test.dart` | `test/tools/early_difficulty_gate_probe_test.dart` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-06_night_视觉收口.md` | 24 | 1 | `docs/audit/full_project_review_2026-07-06.md` | `docs/audit/full_project_review_2026-07-06.md` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-14_1026_心法合并收环.md` | 13 | 1 | `lib/shared/audio/audio_assets.dart:54/57` | `lib/shared/audio/audio_assets.dart:54/57` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-14_2223_编成拍板.md` | 5 | 1 | `docs/team-lineup-spec` | `docs/team-lineup-spec` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1007_编成实装.md` | 51 | 1 | `docs/baicao-spec-revision` | `docs/baicao-spec-revision` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1104_双批就绪.md` | 12 | 1 | `docs/baicao-spec-revision` | `docs/baicao-spec-revision` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1550_装备副本文档编排批1.md` | 5 | 3 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1610_codex战斗界面环境整备.md` | 5 | 2 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1640_装备副本文档编排批2.md` | 5 | 1 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-15_1715_装备副本编排收尾.md` | 5 | 2 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-16_1456_batch3联合经济探针.md` | 25 | 1 | `test/tools/output/joint_economy_probe_2026-07-16.md` | `test/tools/output/joint_economy_probe_2026-07-16.md` | 生成物(不入库) |
| `docs/sessions/2026-07-16_1847_断魂庄C1.md` | 23 | 1 | `test/tools/output/joint_economy_probe_2026-07-16.md` | `test/tools/output/joint_economy_probe_2026-07-16.md` | 生成物(不入库) |
| `docs/sessions/2026-07-16_1952_断魂庄qi_drain.md` | 25 | 1 | `test/tools/output/joint_economy_probe_2026-07-16.md` | `test/tools/output/joint_economy_probe_2026-07-16.md` | 生成物(不入库) |
| `docs/sessions/2026-07-16_2334_断魂庄C1闭环.md` | 27 | 1 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-17_0109_战斗界面阶段一合并.md` | 28 | 1 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/sessions/2026-07-17_0156_断魂庄C2.1入场扣帖.md` | 26 | 1 | `lib/features/gauntlet/` | `lib/features/gauntlet/` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-24_1851_三批收账.md` | 47 | 1 | `data/defs/stage_def.dart` | `data/defs/stage_def.dart` | 数据路径(疑移除/改名) |
| `docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md` | 39 | 1 | `data/proficiency.yaml` | `data/proficiency.yaml` | 数据路径(疑移除/改名) |
| `docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md` | 42 | 1 | `lib/core/combat/formulas.dart` | `lib/core/combat/formulas.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline2-batch24-impact-feel-plan.md` | 27 | 3 | `lib/features/battle/presentation/camera_shake.dart` | `lib/features/battle/presentation/camera_shake.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-design.md` | 10 | 1 | `lib/core/application/battle_providers.dart:81` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-design.md` | 41 | 1 | `test/features/battle/presentation/battle_drag_skill_test.dart` | `test/features/battle/presentation/battle_drag_skill_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-plan.md` | 24 | 3 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-plan.md` | 31 | 4 | `test/features/battle/presentation/battle_drag_skill_test.dart` | `test/features/battle/presentation/battle_drag_skill_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase5-mainline3-loot-rumors-plan.md` | 19 | 1 | `lib/features/tower/domain/tower_floor_def.dart` | `lib/features/tower/domain/tower_floor_def.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase6-coop-break-window-plan.md` | 25 | 2 | `lib/features/battle/domain/battle_action.dart` | `lib/features/battle/domain/battle_action.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md` | 425 | 1 | `../data/game_repository.dart` | `../data/game_repository.dart` | 相对父目录(边界) |
| `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md` | 153 | 3 | `test/data/numbers_config_test.dart` | `test/data/numbers_config_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md` | 625 | 3 | `test/features/equipment/treasure_highlight_test.dart` | `test/features/equipment/treasure_highlight_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md` | 180 | 3 | `test/data/defs/stage_def_test.dart` | `test/data/defs/stage_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md` | 325 | 1 | `test/features/battle/weakness_hit_glyph_test.dart` | `test/features/battle/weakness_hit_glyph_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md` | 407 | 1 | `test/features/cultivation/skill_treasure_overlay_test.dart` | `test/features/cultivation/skill_treasure_overlay_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md` | 421 | 1 | `test/features/mainline/stage_skill_drop_wiring_test.dart` | `test/features/mainline/stage_skill_drop_wiring_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-19-phase7-batch3-team-growth-plan.md` | 28 | 1 | `data/narrative_loader.dart` | `data/narrative_loader.dart` | 数据路径(疑移除/改名) |
| `docs/spec/2026-06-19-phase7-batch3-team-growth-plan.md` | 122 | 1 | `test/core/domain/save_data_test.dart` | `test/core/domain/save_data_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-20-p4-weapon-codex-plan.md` | 746 | 1 | `test/redlines/` | `test/redlines/` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-lineage-codex-plan.md` | 49 | 3 | `test/features/character_panel/lineage_panel_screen_test.dart` | `test/features/character_panel/lineage_panel_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-balance-plan.md` | 30 | 3 | `test/data/defs/item_def_test.dart` | `test/data/defs/item_def_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-balance-plan.md` | 192 | 5 | `test/data/drop_table_test.dart` | `test/data/drop_table_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p1-plan.md` | 45 | 2 | `test/features/battle/enum_localizations_test.dart` | `test/features/battle/enum_localizations_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p1-plan.md` | 85 | 3 | `test/features/equipment/drop_service_test.dart` | `test/features/equipment/drop_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p1-plan.md` | 241 | 2 | `test/features/inventory/inventory_screen_test.dart` | `test/features/inventory/inventory_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p1-plan.md` | 241 | 2 | `test/features/main_menu/main_menu_test.dart` | `test/features/main_menu/main_menu_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p1-plan.md` | 67 | 2 | `test/features/seclusion/seclusion_service_test.dart` | `test/features/seclusion/seclusion_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-21-p4-material-economy-p2-plan.md` | 255 | 1 | `/data/game_repository.dart` | `/data/game_repository.dart` | 其他 |
| `docs/spec/2026-06-22-p4-martial-codex-plan.md` | 405 | 1 | `../data/numbers_config.dart` | `../data/numbers_config.dart` | 相对父目录(边界) |
| `docs/spec/2026-06-22-p4-martial-codex-plan.md` | 1034 | 1 | `/data/numbers_config.dart` | `/data/numbers_config.dart` | 其他 |
| `docs/spec/2026-06-22-p4-martial-codex-plan.md` | 632 | 1 | `lib/features/baike/application/martial_codex_provider.g.dart` | `lib/features/baike/application/martial_codex_provider.g.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-23-battle-pacing-readability-plan.md` | 17 | 2 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md` | 444 | 4 | `test/features/ascension/ascend_milestone_grant_test.dart` | `test/features/ascension/ascend_milestone_grant_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md` | 186 | 3 | `test/features/equipment/milestone_equipment_grant_service_test.dart` | `test/features/equipment/milestone_equipment_grant_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md` | 324 | 4 | `test/features/equipment/milestone_grant_hook_test.dart` | `test/features/equipment/milestone_grant_hook_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-24-b1-sect-event-game-loop-wiring-design.md` | 108 | 1 | `lib/features/home_feed/presentation/home_feed_screen.dart` | `lib/features/home_feed/presentation/home_feed_screen.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-24-b1-sect-event-game-loop-wiring-design.md` | 107 | 1 | `lib/features/sect/application/sect_monthly_tick_gate.dart` | `lib/features/sect/application/sect_monthly_tick_gate.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md` | 580 | 1 | `../data/game_repository.dart` | `../data/game_repository.dart` | 相对父目录(边界) |
| `docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md` | 77 | 1 | `/data/defs/drop_entry.dart` | `/data/defs/drop_entry.dart` | 其他 |
| `docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md` | 19 | 2 | `lib/features/seclusion/domain/seclusion_map_def.dart` | `lib/features/seclusion/domain/seclusion_map_def.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-25-combat-tension-loop-plan.md` | 43 | 2 | `lib/features/injury/domain/injury_config.dart` | `lib/features/injury/domain/injury_config.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-25-taohua-island-phase1-plan.md` | 23 | 2 | `lib/features/taohua_island/domain/island_building_state.dart` | `lib/features/taohua_island/domain/island_building_state.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-25-taohua-island-phase1-plan.md` | 21 | 2 | `lib/features/taohua_island/domain/island_building_type.dart` | `lib/features/taohua_island/domain/island_building_type.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-25-taohua-island-phase1-plan.md` | 22 | 2 | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/features/taohua_island/domain/taohua_island_config.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md` | 22 | 2 | `lib/features/equipment/presentation/equipment_detail_screen.dart` | `lib/features/equipment/presentation/equipment_detail_screen.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md` | 20 | 2 | `lib/features/level/domain/level_config.dart` | `lib/features/level/domain/level_config.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md` | 610 | 1 | `test/features/level/` | `test/features/level/` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md` | 598 | 1 | `test/features/level/level_service_test.dart` | `test/features/level/level_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-26-equip-slot-dialog-redesign-plan.md` | 20 | 3 | `test/features/character_panel/equip_slot_dialog_test.dart` | `test/features/character_panel/equip_slot_dialog_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-06-27-taohua-island-zangjuange-design.md` | 38 | 1 | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/features/taohua_island/domain/taohua_island_config.dart` | 代码路径(疑重构/移走) |
| `docs/spec/2026-08-01-tower-extension-design.md` | 68 | 1 | `data/ranks.yaml` | `data/ranks.yaml` | 数据路径(疑移除/改名) |
| `docs/spec/P0_手动Boss战破招_落地方案_2026-06-09.md` | 183 | 1 | `data/narratives/lore/events` | `data/narratives/lore/events` | 数据路径(疑移除/改名) |
| `docs/spec/dispatch_templates/codex_art_task.md` | 45 | 1 | `docs/superpowers/plans/[日期]-[任务名].md` | `docs/superpowers/plans/[日期]-[任务名].md` | 文档路径(疑移走/删除) |
| `docs/spec/dispatch_templates/codex_presentation_task.md` | 36 | 1 | `docs/superpowers/plans/[日期]-[任务名].md` | `docs/superpowers/plans/[日期]-[任务名].md` | 文档路径(疑移走/删除) |
| `docs/spec/dispatch_templates/kimi_code_task.md` | 46 | 1 | `docs/superpowers/plans/[日期]-[任务名].md` | `docs/superpowers/plans/[日期]-[任务名].md` | 文档路径(疑移走/删除) |
| `docs/spec/full_review_2026-07-02_followup_backlog.md` | 20 | 1 | `data/narratives/techniques/` | `data/narratives/techniques/` | 数据路径(疑移除/改名) |
| `docs/spec/h_polish_ux_spec_2026-05-29.md` | 30 | 2 | `docs/UX_GUIDELINES.md` | `docs/UX_GUIDELINES.md` | 文档路径(疑移走/删除) |
| `docs/spec/h_polish_ux_spec_2026-05-29.md` | 38 | 1 | `docs/handoff/h1_onboarding_audit.md` | `docs/handoff/h1_onboarding_audit.md` | 文档路径(疑移走/删除) |
| `docs/spec/m15_e_audio_spec_2026-05-29.md` | 16 | 2 | `lib/core/audio/sound_manager.dart` | `lib/core/audio/sound_manager.dart` | 代码路径(疑重构/移走) |
| `docs/spec/m15_f_steam_spec_2026-05-29.md` | 71 | 1 | `docs/handoff/m15_f1_steam_signup_guide.md` | `docs/handoff/m15_f1_steam_signup_guide.md` | 文档路径(疑移走/删除) |
| `docs/spec/m15_g_legal_spec_2026-05-29.md` | 41 | 2 | `docs/legal/ai_disclosure.md` | `docs/legal/ai_disclosure.md` | 文档路径(疑移走/删除) |
| `docs/spec/m15_g_legal_spec_2026-05-29.md` | 49 | 1 | `docs/legal/audio_license.md` | `docs/legal/audio_license.md` | 文档路径(疑移走/删除) |
| `docs/spec/m15_g_legal_spec_2026-05-29.md` | 47 | 1 | `docs/legal/font_license.md` | `docs/legal/font_license.md` | 文档路径(疑移走/删除) |
| `docs/spec/overnight_v3_2026-05-24/A_ch4_5_yiliu_words.md` | 28 | 1 | `data/narratives/chapters/chapter_0[4-5].yaml` | `data/narratives/chapters/chapter_0[4-5].yaml` | 数据路径(疑移除/改名) |
| `docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md` | 119 | 1 | `test/jianghu/` | `test/jianghu/` | 代码路径(疑重构/移走) |
| `docs/spec/p3_1_lightfoot_spec_2026-05-23.md` | 149 | 1 | `test/redline/p3_1_light_foot_redline_test.dart` | `test/redline/p3_1_light_foot_redline_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p3_3_pvp_spec_2026-05-24.md` | 27 | 3 | `data/lore/pvp/` | `data/lore/pvp/` | 数据路径(疑移除/改名) |
| `docs/spec/p3_3_pvp_spec_2026-05-24.md` | 100 | 1 | `lib/features/pvp/application/pvp_service.dart` | `lib/features/pvp/application/pvp_service.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p3_3_pvp_spec_2026-05-24.md` | 101 | 1 | `lib/features/pvp/application/pvp_sync_service.dart` | `lib/features/pvp/application/pvp_sync_service.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p3_3_pvp_spec_2026-05-24.md` | 99 | 1 | `lib/features/pvp/domain/strategy/pvp_strategy.dart` | `lib/features/pvp/domain/strategy/pvp_strategy.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p4_1_sect_management_spec_2026-05-25.md` | 98 | 1 | `lib/features/sect/presentation/sect_management_screen.dart` | `lib/features/sect/presentation/sect_management_screen.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p4_1_sect_management_spec_2026-05-25.md` | 120 | 1 | `test/sect_management/` | `test/sect_management/` | 代码路径(疑重构/移走) |
| `docs/spec/p5_lineage_full_spec_2026-05-24.md` | 77 | 1 | `data/numbers_config.dart` | `data/numbers_config.dart` | 数据路径(疑移除/改名) |
| `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` | 37 | 1 | `lib/data/seed_service.dart` | `lib/data/seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` | 30 | 1 | `test/features/battle/master_disciple_battle_test.dart` | `test/features/battle/master_disciple_battle_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` | 84 | 1 | `test/features/onboarding/onboarding_service_test.dart` | `test/features/onboarding/onboarding_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/spec/playability_upgrade_master_spec_2026-06-09.md` | 557 | 1 | `data/proficiency.yaml` | `data/proficiency.yaml` | 数据路径(疑移除/改名) |
| `docs/superpowers/2026-07-15-baicao-duanhun-orchestration-review.md` | 5 | 2 | `docs/equip-baicao-orchestration` | `docs/equip-baicao-orchestration` | 文档路径(疑移走/删除) |
| `docs/superpowers/plans/2026-05-30-p5_2-enemy-internal-force-symmetric.md` | 112 | 1 | `/data/numbers_config.dart` | `/data/numbers_config.dart` | 其他 |
| `docs/superpowers/plans/2026-05-30-p5_2-enemy-internal-force-symmetric.md` | 307 | 1 | `test/tools/output/balance_summary_2026-05-29.md` | `test/tools/output/balance_summary_2026-05-29.md` | 生成物(不入库) |
| `docs/superpowers/plans/2026-06-01-battle-screen-b2.md` | 310 | 1 | `/data/defs/stage_def.dart` | `/data/defs/stage_def.dart` | 其他 |
| `docs/superpowers/plans/2026-06-01-battle-screen-publishing-art-b1.md` | 317 | 1 | `test/features/battle/presentation/battle_screen_result_overlay_test.dart` | `test/features/battle/presentation/battle_screen_result_overlay_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-02-p0-2-battle-visibility.md` | 630 | 1 | `docs/handoff/codex_visual_battle_p0_2_2026-06-XX.md` | `docs/handoff/codex_visual_battle_p0_2_2026-06-XX.md` | 文档路径(疑移走/删除) |
| `docs/superpowers/plans/2026-06-02-p0-asset-gate.md` | 245 | 3 | `test/tools/output/asset_audit.md` | `test/tools/output/asset_audit.md` | 生成物(不入库) |
| `docs/superpowers/plans/2026-06-02-p0-asset-gate.md` | 245 | 2 | `test/tools/output/asset_audit_missing.txt` | `test/tools/output/asset_audit_missing.txt` | 生成物(不入库) |
| `docs/superpowers/plans/2026-06-04-p0-3-bc-inner-demon-panel.md` | 232 | 1 | `lib/features/inner_demon/application/inner_demon_providers.g.dart` | `lib/features/inner_demon/application/inner_demon_providers.g.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-05-ui-kit-v1.md` | 24 | 2 | `lib/shared/widgets/wuxia_ui/paper_panel.dart` | `lib/shared/widgets/wuxia_ui/paper_panel.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-09-audio-system.md` | 713 | 1 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-09-p0-manual-boss-break.md` | 285 | 1 | `../data/defs/skill_def.dart` | `../data/defs/skill_def.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-06-10-cangjingge-skill-loadout.md` | 26 | 2 | `lib/data/numbers.yaml` | `lib/data/numbers.yaml` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-10-cangjingge-skill-loadout.md` | 530 | 1 | `test/features/battle/stage_battle_setup_test.dart` | `test/features/battle/stage_battle_setup_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-11-treasure-drop-animation.md` | 30 | 1 | `/data/numbers_config.dart` | `/data/numbers_config.dart` | 其他 |
| `docs/superpowers/plans/2026-06-11-treasure-drop-animation.md` | 20 | 4 | `test/data/numbers_config_test.dart` | `test/data/numbers_config_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-14-cycle-evolution-p1.md` | 27 | 1 | `lib/features/battle/domain/default_ground_strategy.dart` | `lib/features/battle/domain/default_ground_strategy.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-14-cycle-evolution-p1.md` | 40 | 1 | `test/features/battle/battle_replay_record_service_test.dart` | `test/features/battle/battle_replay_record_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md` | 582 | 1 | `../data/isar_setup.dart` | `../data/isar_setup.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md` | 528 | 1 | `data/game_repository.dart` | `data/game_repository.dart` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md` | 528 | 1 | `data/isar_setup.dart` | `data/isar_setup.dart` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-06-16-m6-inner-demon-failure-penalty.md` | 97 | 1 | `lib/core/domain/character.g.dart` | `lib/core/domain/character.g.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-16-m6-inner-demon-failure-penalty.md` | 12 | 2 | `lib/features/inner_demon/domain/inner_demon_def.dart` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-27-taohua-island-phase2-foundation.md` | 27 | 2 | `lib/features/taohua_island/domain/island_building_type.dart` | `lib/features/taohua_island/domain/island_building_type.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-27-taohua-island-phase2-foundation.md` | 30 | 1 | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/features/taohua_island/domain/taohua_island_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-29-fourth-tier-experience-batch.md` | 33 | 1 | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/features/taohua_island/domain/taohua_island_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-29-night-tier2-seclusion-map-yields.md` | 33 | 1 | `lib/features/seclusion/domain/seclusion_map_def.dart` | `lib/features/seclusion/domain/seclusion_map_def.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-29-night-tier2-taohua-building-synergy.md` | 35 | 1 | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/features/taohua_island/domain/taohua_island_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-30-tap-skill-cast.md` | 32 | 7 | `test/features/battle/presentation/battle_drag_skill_test.dart` | `test/features/battle/presentation/battle_drag_skill_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-countdown-ring-cd-debuff.md` | 436 | 2 | `test/features/battle/presentation/battle_beat_ring_test.dart` | `test/features/battle/presentation/battle_beat_ring_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-countdown-ring-cd-debuff.md` | 388 | 1 | `test/features/battle/presentation/battle_cd_ring_test.dart` | `test/features/battle/presentation/battle_cd_ring_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md` | 158 | 1 | `/data/game_repository.dart` | `/data/game_repository.dart` | 其他 |
| `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md` | 409 | 4 | `test/features/tower/floor30_guardian_ward_config_test.dart` | `test/features/tower/floor30_guardian_ward_config_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md` | 517 | 2 | `test/features/tower/floor30_guardian_ward_redline_test.dart` | `test/features/tower/floor30_guardian_ward_redline_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md` | 450 | 2 | `test/features/tower/floor30_soft_gate_battle_test.dart` | `test/features/tower/floor30_soft_gate_battle_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-ui-night-main-menu-feed-polish.md` | 43 | 1 | `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-01-ui-night-main-menu-feed-polish.md` | 43 | 1 | `test/features/home_feed/presentation/home_feed_screen_test.dart` | `test/features/home_feed/presentation/home_feed_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch1-vulnerability-base.md` | 180 | 1 | `/data/defs/stage_def.dart` | `/data/defs/stage_def.dart` | 其他 |
| `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch1-vulnerability-base.md` | 465 | 1 | `test/tools/floor30_soft_gate_diagnostic_test.dart` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch2-tower-application.md` | 31 | 5 | `test/data/enemy_def_vulnerability_validation_test.dart` | `test/data/enemy_def_vulnerability_validation_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch2-tower-application.md` | 36 | 3 | `test/tools/floor30_soft_gate_diagnostic_test.dart` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-03-founder-sect-naming.md` | 215 | 1 | `/data/defs/founder_names_def.dart` | `/data/defs/founder_names_def.dart` | 其他 |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 422 | 1 | `../data/defs/` | `../data/defs/` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 531 | 1 | `../data/defs/boss_vulnerability_def.dart` | `../data/defs/boss_vulnerability_def.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 778 | 1 | `../data/defs/skill_def.dart` | `../data/defs/skill_def.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 225 | 3 | `../data/defs/stage_win_condition.dart` | `../data/defs/stage_win_condition.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 218 | 2 | `lib/core/application/battle_providers.dart:78-87` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md` | 463 | 2 | `lib/features/inner_demon/domain/inner_demon_def.dart:15-116` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md` | 37 | 1 | `/data/defs/boss_vulnerability_def.dart` | `/data/defs/boss_vulnerability_def.dart` | 其他 |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md` | 572 | 1 | `docs/sessions/2026-07-04-` | `docs/sessions/2026-07-04-` | 文档路径(疑移走/删除) |
| `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md` | 336 | 1 | `test/tools/floor30_soft_gate_diagnostic_test.dart:183-260` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-07-offline-settlement-loop.md` | 425 | 1 | `../data/isar_setup.dart` | `../data/isar_setup.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-07-offline-settlement-loop.md` | 593 | 1 | `data/isar_setup.dart` | `data/isar_setup.dart` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-07-08-sweep-readiness.md` | 155 | 1 | `lib/core/domain/save_data.g.dart` | `lib/core/domain/save_data.g.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-08-sweep-readiness.md` | 15 | 2 | `lib/features/sweep/domain/sweep_readiness.dart` | `lib/features/sweep/domain/sweep_readiness.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-10-test-infrastructure-migrations.md` | 19 | 1 | `data/balance/features/tools` | `data/balance/features/tools` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-07-10-ui-reliability.md` | 17 | 1 | `test/shared/widgets/wuxia_title_bar_test.dart` | `test/shared/widgets/wuxia_title_bar_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-11-project-health-hardening.md` | 91 | 1 | `lib/features/battle/domain/battle_engine.dart` | `lib/features/battle/domain/battle_engine.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md` | 349 | 2 | `test/features/battle/application/inner_breath_disorder_recovery_test.dart` | `test/features/battle/application/inner_breath_disorder_recovery_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md` | 219 | 2 | `test/features/battle/domain/qi_combat_loop_test.dart` | `test/features/battle/domain/qi_combat_loop_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md` | 350 | 2 | `test/features/seclusion/inner_breath_disorder_recovery_test.dart` | `test/features/seclusion/inner_breath_disorder_recovery_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-character-attribute-roles.md` | 185 | 1 | `lib/features/encounter/domain/encounter_event_loader.dart` | `lib/features/encounter/domain/encounter_event_loader.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 505 | 1 | `lib/features/level/application/level_service.dart` | `lib/features/level/application/level_service.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 506 | 1 | `lib/features/level/domain/level_config.dart` | `lib/features/level/domain/level_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 513 | 1 | `test/combat/level_derived_stats_test.dart` | `test/combat/level_derived_stats_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 674 | 1 | `test/data/character_level_repair_test.dart` | `test/data/character_level_repair_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 320 | 1 | `test/features/cultivation/level_up_summary_test.dart` | `test/features/cultivation/level_up_summary_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 507 | 1 | `test/features/level/level_service_test.dart` | `test/features/level/level_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md` | 55 | 2 | `lib/features/cultivation/domain/progression_release_cap.dart` | `lib/features/cultivation/domain/progression_release_cap.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md` | 137 | 1 | `lib/features/inner_demon/domain/inner_demon_def.dart` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md` | 336 | 1 | `test/features/tower/floor30_soft_gate_battle_test.dart` | `test/features/tower/floor30_soft_gate_battle_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md` | 334 | 1 | `test/tools/floor30_soft_gate_diagnostic_test.dart` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-a2-cap-config.md` | 39 | 2 | `lib/features/boss_gauntlet/domain/boss_gauntlet_config.dart` | `lib/features/boss_gauntlet/domain/boss_gauntlet_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-a2-cap-config.md` | 38 | 2 | `lib/features/expedition/domain/expedition_config.dart` | `lib/features/expedition/domain/expedition_config.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md` | 37 | 2 | `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart` | `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md` | 129 | 1 | `test/features/boss_gauntlet/gauntlet_controller_test.dart` | `test/features/boss_gauntlet/gauntlet_controller_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md` | 145 | 1 | `test/features/boss_gauntlet/gauntlet_entry_test.dart` | `test/features/boss_gauntlet/gauntlet_entry_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-17-erliu-content-ch7.md` | 44 | 2 | `test/data/stage_win_condition_test.dart` | `test/data/stage_win_condition_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-17-gauntlet-battle-flow-wiring.md` | 19 | 1 | `lib/features/boss_gauntlet/application/gauntlet_stage_plan.dart` | `lib/features/boss_gauntlet/application/gauntlet_stage_plan.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-18-erliu-content-ch8.md` | 47 | 2 | `test/data/stage_win_condition_test.dart` | `test/data/stage_win_condition_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-19-equipment-disposal-migration.md` | 46 | 1 | `../data/defs/equipment_disposal_def.dart` | `../data/defs/equipment_disposal_def.dart` | 相对父目录(边界) |
| `docs/superpowers/plans/2026-07-19-equipment-disposal-migration.md` | 40 | 1 | `data/defs/` | `data/defs/` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-07-20-ch10-yiliu.md` | 128 | 1 | `test/data/progression_release_cap_test.dart` | `test/data/progression_release_cap_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 125 | 1 | `lib/features/battle/presentation/widgets/battle_pouch.dart` | `lib/features/battle/presentation/widgets/battle_pouch.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 146 | 1 | `lib/features/battle/presentation/widgets/battle_scene_background.dart` | `lib/features/battle/presentation/widgets/battle_scene_background.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 147 | 1 | `lib/features/battle/presentation/widgets/battlefield.dart` | `lib/features/battle/presentation/widgets/battlefield.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 101 | 2 | `lib/features/battle/presentation/widgets/character_avatar.dart` | `lib/features/battle/presentation/widgets/character_avatar.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 100 | 1 | `lib/features/battle/presentation/widgets/hp_bar.dart` | `lib/features/battle/presentation/widgets/hp_bar.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 124 | 1 | `lib/features/battle/presentation/widgets/skill_command_strip.dart` | `lib/features/battle/presentation/widgets/skill_command_strip.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md` | 123 | 1 | `lib/features/battle/presentation/widgets/stage_command_desk.dart` | `lib/features/battle/presentation/widgets/stage_command_desk.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-05-30-p5_2-enemy-internal-force-symmetric-design.md` | 60 | 1 | `test/tools/output/balance_summary_2026-05-29.md` | `test/tools/output/balance_summary_2026-05-29.md` | 生成物(不入库) |
| `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md` | 40 | 1 | `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart:_CandidateInfo` | `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart:_CandidateInfo` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md` | 33 | 1 | `lib/features/onboarding/application/master_builder.dart:buildMasterCharacter` | `lib/features/onboarding/application/master_builder.dart:buildMasterCharacter` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md` | 37 | 1 | `lib/features/sect/presentation/sect_screen.dart:_MemberRow` | `lib/features/sect/presentation/sect_screen.dart:_MemberRow` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-06-02-p0-asset-gate-design.md` | 43 | 2 | `test/tools/output/asset_audit.md` | `test/tools/output/asset_audit.md` | 生成物(不入库) |
| `docs/superpowers/specs/2026-06-16-m6-inner-demon-failure-penalty-design.md` | 7 | 1 | `lib/features/inner_demon/domain/inner_demon_def.dart` | `lib/features/inner_demon/domain/inner_demon_def.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-06-30-tap-skill-cast-replace-drag-design.md` | 29 | 1 | `test/features/battle/presentation/battle_drag_skill_test.dart` | `test/features/battle/presentation/battle_drag_skill_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md` | 25 | 1 | `test/tools/floor30_soft_gate_diagnostic_test.dart` | `test/tools/floor30_soft_gate_diagnostic_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-07-05-skill-target-chip-design.md` | 78 | 1 | `test/features/battle/battle_screen_target_chip_test.dart` | `test/features/battle/battle_screen_target_chip_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/specs/2026-07-18-erliu-content-ch8-design.md` | 12 | 1 | `data/narratives/chapters/chapter_NN.yaml` | `data/narratives/chapters/chapter_NN.yaml` | 数据路径(疑移除/改名) |

## 4. 唯一死链目标(可行动清单)

> 按命中次数降序。修复/恢复一个目标可同时消解其全部引用。692 个唯一目标。

| 目标(清洗后) | 命中次数 | 首次出现 | 类别 |
|---|---:|---|---|
| `test/features/battle/presentation/battle_drag_skill_test.dart` | 14 | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md:34` | 代码路径(疑重构/移走) |
| `lib/core/application/battle_providers.dart` | 14 | `docs/handoff/lib_structure_audit_2026-05-19.md:63` | 代码路径(疑重构/移走) |
| `docs/equip-baicao-orchestration` | 12 | `docs/sessions/2026-07-15_1550_装备副本文档编排批1.md:5` | 文档路径(疑移走/删除) |
| `data/narratives/techniques/insights/` | 9 | `docs/audit/yaml_integrity_2026-05-12.md:166` | 数据路径(疑移除/改名) |
| `test/tools/floor30_soft_gate_diagnostic_test.dart` | 8 | `docs/audit/overnight_fix_and_balance_review_2026-07-08.md:51` | 代码路径(疑重构/移走) |
| `lib/ui/main_menu.dart` | 8 | `docs/handoff/codex_dispatch_w15_stage_drop_visual_2026-05-16.md:27` | 代码路径(疑重构/移走) |
| `lib/features/inner_demon/domain/inner_demon_def.dart` | 8 | `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md:51` | 代码路径(疑重构/移走) |
| `lib/ui/strings.dart` | 7 | `docs/NARRATIVE_SCHEMA.md:139` | 代码路径(疑重构/移走) |
| `test/data/encounter_yaml_test.dart` | 7 | `docs/handoff/deepseek_w16_festival_closeout_2026-05-16.md:95` | 代码路径(疑重构/移走) |
| `lib/features/battle/domain/battle_engine.dart` | 7 | `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md:40` | 代码路径(疑重构/移走) |
| `lib/providers/isar_provider.dart` | 7 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md:72` | 代码路径(疑重构/移走) |
| `lib/providers/` | 7 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:313` | 代码路径(疑重构/移走) |
| `test/data/numbers_config_test.dart` | 7 | `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md:153` | 代码路径(疑重构/移走) |
| `test/tools/output/asset_audit.md` | 6 | `docs/PUBLISHING_ART_PASS_1_0.md:1052` | 生成物(不入库) |
| `lib/features/seclusion/domain/seclusion_map_def.dart` | 6 | `docs/handoff/art_assets_integration_closeout_2026-05-20.md:48` | 代码路径(疑重构/移走) |
| `lib/services/phase2_seed_service.dart` | 6 | `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md:24` | 代码路径(疑重构/移走) |
| `test/combat/battle_engine_test.dart` | 6 | `docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md:35` | 代码路径(疑重构/移走) |
| `test/services/phase2_seed_service_test.dart` | 6 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:26` | 代码路径(疑重构/移走) |
| `data/codex/` | 6 | `docs/handoff/deepseek_p1_42_phase2_p1z_codex_dispatch_2026-05-18.md:115` | 数据路径(疑移除/改名) |
| `lib/features/codex/domain/codex_category.dart` | 6 | `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md:24` | 代码路径(疑重构/移走) |
| `lib/features/taohua_island/domain/taohua_island_config.dart` | 6 | `docs/spec/2026-06-25-taohua-island-phase1-plan.md:22` | 代码路径(疑重构/移走) |
| `lib/ui/` | 5 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:249` | 代码路径(疑重构/移走) |
| `test/data/drop_table_test.dart` | 5 | `docs/spec/2026-06-21-p4-material-economy-balance-plan.md:192` | 代码路径(疑重构/移走) |
| `test/data/enemy_def_vulnerability_validation_test.dart` | 5 | `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch2-tower-application.md:31` | 代码路径(疑重构/移走) |
| `01_baseline_1280x720.png` | 4 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:15` | 截图/图片(多不入库) |
| `docs/handoff/codex_d_progress_stage_row_2026-06-12/` | 4 | `docs/handoff/codex_d_progress_stage_row_2026-06-12.md:17` | 文档路径(疑移走/删除) |
| `lib/ui/debug/encounter_debug_picker.dart` | 4 | `docs/handoff/codex_dispatch_w15_dialog_round3_2026-05-15.md:57` | 代码路径(疑重构/移走) |
| `lib/ui/mainline/stage_entry_flow.dart` | 4 | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-14-v4.md:13` | 代码路径(疑重构/移走) |
| `lib/ui/tower/tower_entry_flow.dart` | 4 | `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-14-v4.md:13` | 代码路径(疑重构/移走) |
| `lib/data/enum_localizations.dart` | 4 | `docs/handoff/p1_1_candidate5_claudemd_align_closeout_2026-05-21.md:20` | 代码路径(疑重构/移走) |
| `lib/features/codex/domain/codex_index.dart` | 4 | `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md:25` | 代码路径(疑重构/移走) |
| `lib/features/codex/domain/codex_entry.dart` | 4 | `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md:26` | 代码路径(疑重构/移走) |
| `test/services/encounter_service_test.dart` | 4 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md:80` | 代码路径(疑重构/移走) |
| `lib/services/seclusion_service.dart` | 4 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:60` | 代码路径(疑重构/移走) |
| `test/data/encounter_skills_yaml_test.dart` | 4 | `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md:97` | 代码路径(疑重构/移走) |
| `test/ui/main_menu/phase2_test_menu_test.dart` | 4 | `docs/handoff/week14_full_closeout_2026-05-15.md:196` | 代码路径(疑重构/移走) |
| `lib/ui/battle/` | 4 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:148` | 代码路径(疑重构/移走) |
| `lib/combat/` | 4 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:148` | 代码路径(疑重构/移走) |
| `/data/models/` | 4 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:205` | 其他 |
| `lib/services/` | 4 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:310` | 代码路径(疑重构/移走) |
| `../data/X` | 4 | `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md:65` | 相对父目录(边界) |
| `lib/data/models/` | 4 | `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md:13` | 代码路径(疑重构/移走) |
| `test/tools/output/stress_2026-06-02.md` | 4 | `docs/sessions/2026-06-02_2104_P0缺图门禁.md:29` | 生成物(不入库) |
| `docs/handoff/visual_acceptance_2026-06-30/` | 4 | `docs/sessions/2026-06-30_1252_视觉验收修复.md:28` | 文档路径(疑移走/删除) |
| `test/features/equipment/milestone_grant_hook_test.dart` | 4 | `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md:324` | 代码路径(疑重构/移走) |
| `test/features/ascension/ascend_milestone_grant_test.dart` | 4 | `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md:444` | 代码路径(疑重构/移走) |
| `lib/features/taohua_island/domain/island_building_type.dart` | 4 | `docs/spec/2026-06-25-taohua-island-phase1-plan.md:21` | 代码路径(疑重构/移走) |
| `test/features/tower/floor30_guardian_ward_config_test.dart` | 4 | `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md:409` | 代码路径(疑重构/移走) |
| `test/data/stage_win_condition_test.dart` | 4 | `docs/superpowers/plans/2026-07-17-erliu-content-ch7.md:44` | 代码路径(疑重构/移走) |
| `test/tools/output/idle_economy_2026-05-29.md` | 3 | `docs/RELEASE_CHECKLIST_1_0.md:74` | 生成物(不入库) |
| `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` | 3 | `docs/RELEASE_CHECKLIST_1_0.md:100` | 截图目录(多不入库) |
| `lib/core/combat/formulas.dart` | 3 | `docs/audit/full_audit_2026-06-16.md:84` | 代码路径(疑重构/移走) |
| `data/narratives/techniques/` | 3 | `docs/audit/full_project_review_2026-07-02.md:41` | 数据路径(疑移除/改名) |
| `lib/features/home_feed/presentation/home_feed_screen.dart` | 3 | `docs/handoff/art_assets_integration_closeout_2026-05-20.md:71` | 代码路径(疑重构/移走) |
| `lib/ui/character_panel/encounter_skill_section.dart` | 3 | `docs/handoff/codex_dispatch_w14_3c_2026-05-14.md:109` | 代码路径(疑重构/移走) |
| `lib/ui/inventory/equipment_detail_screen.dart` | 3 | `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md:21` | 代码路径(疑重构/移走) |
| `docs/screenshots/w15_resonance/` | 3 | `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md:115` | 截图目录(多不入库) |
| `docs/screenshots/w17/` | 3 | `docs/handoff/codex_dispatch_w17_festival_chip_extend_visual_check_2026-05-17.md:113` | 截图目录(多不入库) |
| `lib/core/domain/save_data.g.dart` | 3 | `docs/handoff/p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md:26` | 代码路径(疑重构/移走) |
| `lib/features/mass_battle/domain/mass_battle_def.dart` | 3 | `docs/handoff/p3_2_c_fix_1_numerical_overhaul_2026-05-24.md:33` | 代码路径(疑重构/移走) |
| `lib/foo.dart` | 3 | `docs/handoff/session_closeout_2026-05-25_v2.2_warmup_cleanup.md:31` | 代码路径(疑重构/移走) |
| `lib/services/encounter_service.dart` | 3 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md:41` | 代码路径(疑重构/移走) |
| `lib/ui/encounter/encounter_dialog.dart` | 3 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md:51` | 代码路径(疑重构/移走) |
| `test/services/seclusion_service_test.dart` | 3 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:141` | 代码路径(疑重构/移走) |
| `test/data/seclusion_map_def_test.dart` | 3 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:143` | 代码路径(疑重构/移走) |
| `lib/ui/enhancement/` | 3 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:149` | 代码路径(疑重构/移走) |
| `data/models/` | 3 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:201` | 数据路径(疑移除/改名) |
| `test/services/` | 3 | `docs/handoff/week15_phase5_3_e_k_2026-05-16.md:13` | 代码路径(疑重构/移走) |
| `../data/models/X.dart` | 3 | `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md:54` | 相对父目录(边界) |
| `test/tools/output/balance_summary_2026-05-29.md` | 3 | `docs/sessions/2026-05-30_1516_4决策第三层.md:12` | 生成物(不入库) |
| `test/tools/output/joint_economy_probe_2026-07-16.md` | 3 | `docs/sessions/2026-07-16_1456_batch3联合经济探针.md:25` | 生成物(不入库) |
| `lib/features/battle/presentation/camera_shake.dart` | 3 | `docs/spec/2026-06-18-phase5-mainline2-batch24-impact-feel-plan.md:27` | 代码路径(疑重构/移走) |
| `test/features/equipment/treasure_highlight_test.dart` | 3 | `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md:625` | 代码路径(疑重构/移走) |
| `test/data/defs/stage_def_test.dart` | 3 | `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md:180` | 代码路径(疑重构/移走) |
| `test/features/character_panel/lineage_panel_screen_test.dart` | 3 | `docs/spec/2026-06-21-p4-lineage-codex-plan.md:49` | 代码路径(疑重构/移走) |
| `test/data/defs/item_def_test.dart` | 3 | `docs/spec/2026-06-21-p4-material-economy-balance-plan.md:30` | 代码路径(疑重构/移走) |
| `test/features/equipment/drop_service_test.dart` | 3 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md:85` | 代码路径(疑重构/移走) |
| `/data/numbers_config.dart` | 3 | `docs/spec/2026-06-22-p4-martial-codex-plan.md:1034` | 其他 |
| `test/features/equipment/milestone_equipment_grant_service_test.dart` | 3 | `docs/spec/2026-06-23-f1-milestone-equipment-grant-plan.md:186` | 代码路径(疑重构/移走) |
| `lib/features/level/domain/level_config.dart` | 3 | `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md:20` | 代码路径(疑重构/移走) |
| `test/features/character_panel/equip_slot_dialog_test.dart` | 3 | `docs/spec/2026-06-26-equip-slot-dialog-redesign-plan.md:20` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/[日期]-[任务名].md` | 3 | `docs/spec/dispatch_templates/codex_art_task.md:45` | 文档路径(疑移走/删除) |
| `data/lore/pvp/` | 3 | `docs/spec/p3_3_pvp_spec_2026-05-24.md:27` | 数据路径(疑移除/改名) |
| `test/features/tower/floor30_soft_gate_battle_test.dart` | 3 | `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md:450` | 代码路径(疑重构/移走) |
| `../data/defs/stage_win_condition.dart` | 3 | `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md:225` | 相对父目录(边界) |
| `10_baseline_1440x900.png` | 2 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:15` | 截图/图片(多不入库) |
| `13_hover_bench_card_1280x720.png` | 2 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:22` | 截图/图片(多不入库) |
| `../../.claude/projects/-Users-a10506/memory/feedback_audit_report_phase0_verify.md` | 2 | `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md:49` | 出 repo 边界 |
| `test/tools/output/art_tone_audit.md` | 2 | `docs/audit/stage_review_2026-06-28.md:18` | 生成物(不入库) |
| `data/ranks.yaml` | 2 | `docs/handoff/afk_batch_closeout_2026-08-01.md:36` | 数据路径(疑移除/改名) |
| `data/inventory.yaml` | 2 | `docs/handoff/ch4_lore_equipment_skill_audit_2026-05-22.md:59` | 数据路径(疑移除/改名) |
| `docs/handoff/codex_batch3_console_visual_2026-06-12/` | 2 | `docs/handoff/codex_batch3_console_visual_2026-06-12.md:13` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/01_inventory_polished.png` | 2 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:33` | 截图/图片(多不入库) |
| `docs/handoff/codex_ui_equipment_line_polish_2026-06-06/04_equipment_detail_screen_polished.png` | 2 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:34` | 截图/图片(多不入库) |
| `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png` | 2 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:35` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png` | 2 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07.md:33` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png` | 2 | `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07.md:34` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/` | 2 | `docs/handoff/codex_claude_resume_ui_progress_2026-06-07.md:114` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md` | 2 | `docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md:161` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_battle_b1_2026-06-01/` | 2 | `docs/handoff/codex_dispatch_battle_b1_2026-06-01.md:20` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_battle_b2_2026-06-01/` | 2 | `docs/handoff/codex_dispatch_battle_b2_2026-06-01.md:28` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_battle_scene_2026-06-02/` | 2 | `docs/handoff/codex_dispatch_battle_scene_longtail_2026-06-02.md:32` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_phase5_aoe_reverify_2026-06-17/` | 2 | `docs/handoff/codex_dispatch_phase5_aoe_reverify_2026-06-17.md:37` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/` | 2 | `docs/handoff/codex_dispatch_phase5_mainline1_reverify_2026-06-17.md:42` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_loot_dialog_2026-06-18/` | 2 | `docs/handoff/codex_dispatch_phase5_mainline3_loot_dialog_2026-06-18.md:42` | 文档路径(疑移走/删除) |
| `docs/screenshots/w15_round3/` | 2 | `docs/handoff/codex_dispatch_w15_dialog_round3_2026-05-15.md:131` | 截图目录(多不入库) |
| `docs/screenshots/w15_equipment_detail/01_inventory.png` | 2 | `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md:84` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/` | 2 | `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md:104` | 截图目录(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/01_inventory_15_eq.png` | 2 | `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md:67` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | 2 | `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md:92` | 截图/图片(多不入库) |
| `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | 2 | `docs/handoff/codex_dispatch_w15_stage_drop_visual_2026-05-16.md:89` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/` | 2 | `docs/handoff/codex_dispatch_w15_victory_dialog_2026-05-16.md:149` | 截图目录(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/` | 2 | `docs/handoff/codex_dispatch_w15_victory_dialog_round2_2026-05-16.md:170` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_981085a_20260609_115936/` | 2 | `docs/handoff/codex_t5_result_2026-06-09.md:11` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_e711a5b_20260609_153133/` | 2 | `docs/handoff/codex_t9_result_2026-06-09.md:57` | 截图目录(多不入库) |
| `docs/screenshots/w14_3_round2_disciple1_slot_filled.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:37` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3_round2_disciple1_bottom_sheet.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:38` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3_round2_disciple2_more_locks.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:39` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3_round2_founder_fewer_locks.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:40` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3_round2_disciple1_unequip.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:41` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3_round2_disciple1_equip_new.png` | 2 | `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md:42` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3c_dialog_opening_fadein.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:38` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3c_dialog_opening_full.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:39` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3c_dialog_outcome_full.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:40` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3c_dialog_outcome_crossfade.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:41` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3a_encounter_skill_section_empty.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:42` | 截图/图片(多不入库) |
| `docs/screenshots/w14_3a_encounter_skill_section_in_layout.png` | 2 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md:43` | 截图/图片(多不入库) |
| `test/data/lore_yaml_test.dart` | 2 | `docs/handoff/deepseek_w15_35_lore_closeout_2026-05-15.md:54` | 代码路径(疑重构/移走) |
| `docs/handoff/pen_visual_root_cause_a/` | 2 | `docs/handoff/h1_onboarding_audit_2026-05-29.md:47` | 文档路径(疑移走/删除) |
| `lib/ui/narrative/narrative_reader_screen.dart` | 2 | `docs/handoff/p1_1_mac_handoff_2026-05-12.md:221` | 代码路径(疑重构/移走) |
| `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | 2 | `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md:25` | 代码路径(疑重构/移走) |
| `lib/features/home_feed/` | 2 | `docs/handoff/p1_42_phase1_spec.md:203` | 代码路径(疑重构/移走) |
| `test/features/home_feed/presentation/home_feed_screen_test.dart` | 2 | `docs/handoff/p1_42_phase1_spec.md:223` | 代码路径(疑重构/移走) |
| `lib/features/encounter/domain/encounter_progress.g.dart` | 2 | `docs/handoff/p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md:51` | 代码路径(疑重构/移走) |
| `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_confirm_dialog.png` | 2 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/phase3_w5/` | 2 | `docs/handoff/t62_visual_check_spec_2026-05-13.md:7` | 截图目录(多不入库) |
| `lib/services/battle_resolution.dart` | 2 | `docs/handoff/week11_victory_resolution_2026-05-13.md:75` | 代码路径(疑重构/移走) |
| `test/services/skill_usage_persist_test.dart` | 2 | `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md:62` | 代码路径(疑重构/移走) |
| `lib/data/models/encounter_progress.dart` | 2 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md:35` | 代码路径(疑重构/移走) |
| `lib/core/domain/character.g.dart` | 2 | `docs/handoff/week15_30_phase2_consumption_layer_2026-05-16.md:31` | 代码路径(疑重构/移走) |
| `lib/features/tower/domain/tower_floor_def.dart` | 2 | `docs/handoff/week15_30_phase3_advancement_2026-05-16.md:60` | 代码路径(疑重构/移走) |
| `lib/data/models/lore.dart` | 2 | `docs/handoff/week15_loreloader_接入_2026-05-15.md:45` | 代码路径(疑重构/移走) |
| `lib/features/README.md` | 2 | `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md:46` | 代码路径(疑重构/移走) |
| `lib/services/drop_service.dart` | 2 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:63` | 代码路径(疑重构/移走) |
| `lib/ui/debug/battle_test_menu.dart` | 2 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:94` | 代码路径(疑重构/移走) |
| `lib/ui/debug/` | 2 | `docs/handoff/week15_phase5_3_e_k_2026-05-16.md:13` | 代码路径(疑重构/移走) |
| `../data/numbers_config.dart` | 2 | `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md:55` | 相对父目录(边界) |
| `lib/utils/` | 2 | `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md:23` | 代码路径(疑重构/移走) |
| `data/lore/masters/` | 2 | `docs/handoff/week4_d_minimal_spec_2026-05-13.md:55` | 数据路径(疑移除/改名) |
| `data/narratives/retreat/` | 2 | `docs/sessions/2026-06-28_1325_睡觉模式集成.md:25` | 数据路径(疑移除/改名) |
| `docs/baicao-spec-revision` | 2 | `docs/sessions/2026-07-15_1007_编成实装.md:51` | 文档路径(疑移走/删除) |
| `data/proficiency.yaml` | 2 | `docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md:39` | 数据路径(疑移除/改名) |
| `lib/features/battle/domain/battle_action.dart` | 2 | `docs/spec/2026-06-18-phase6-coop-break-window-plan.md:25` | 代码路径(疑重构/移走) |
| `../data/game_repository.dart` | 2 | `docs/spec/2026-06-18-phase7-postbattle-hero-camera-plan.md:425` | 相对父目录(边界) |
| `test/features/battle/enum_localizations_test.dart` | 2 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md:45` | 代码路径(疑重构/移走) |
| `test/features/seclusion/seclusion_service_test.dart` | 2 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md:67` | 代码路径(疑重构/移走) |
| `test/features/inventory/inventory_screen_test.dart` | 2 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md:241` | 代码路径(疑重构/移走) |
| `test/features/main_menu/main_menu_test.dart` | 2 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md:241` | 代码路径(疑重构/移走) |
| `/data/game_repository.dart` | 2 | `docs/spec/2026-06-21-p4-material-economy-p2-plan.md:255` | 其他 |
| `lib/features/injury/domain/injury_config.dart` | 2 | `docs/spec/2026-06-25-combat-tension-loop-plan.md:43` | 代码路径(疑重构/移走) |
| `lib/features/taohua_island/domain/island_building_state.dart` | 2 | `docs/spec/2026-06-25-taohua-island-phase1-plan.md:23` | 代码路径(疑重构/移走) |
| `lib/features/equipment/presentation/equipment_detail_screen.dart` | 2 | `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md:22` | 代码路径(疑重构/移走) |
| `test/features/level/level_service_test.dart` | 2 | `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md:598` | 代码路径(疑重构/移走) |
| `docs/UX_GUIDELINES.md` | 2 | `docs/spec/h_polish_ux_spec_2026-05-29.md:30` | 文档路径(疑移走/删除) |
| `lib/core/audio/sound_manager.dart` | 2 | `docs/spec/m15_e_audio_spec_2026-05-29.md:16` | 代码路径(疑重构/移走) |
| `docs/legal/ai_disclosure.md` | 2 | `docs/spec/m15_g_legal_spec_2026-05-29.md:41` | 文档路径(疑移走/删除) |
| `/data/defs/stage_def.dart` | 2 | `docs/superpowers/plans/2026-06-01-battle-screen-b2.md:310` | 其他 |
| `test/tools/output/asset_audit_missing.txt` | 2 | `docs/superpowers/plans/2026-06-02-p0-asset-gate.md:245` | 生成物(不入库) |
| `lib/shared/widgets/wuxia_ui/paper_panel.dart` | 2 | `docs/superpowers/plans/2026-06-05-ui-kit-v1.md:24` | 代码路径(疑重构/移走) |
| `../data/defs/skill_def.dart` | 2 | `docs/superpowers/plans/2026-06-09-p0-manual-boss-break.md:285` | 相对父目录(边界) |
| `lib/data/numbers.yaml` | 2 | `docs/superpowers/plans/2026-06-10-cangjingge-skill-loadout.md:26` | 代码路径(疑重构/移走) |
| `data/isar_setup.dart` | 2 | `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md:528` | 数据路径(疑移除/改名) |
| `../data/isar_setup.dart` | 2 | `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md:582` | 相对父目录(边界) |
| `test/features/battle/presentation/battle_beat_ring_test.dart` | 2 | `docs/superpowers/plans/2026-07-01-countdown-ring-cd-debuff.md:436` | 代码路径(疑重构/移走) |
| `test/features/tower/floor30_guardian_ward_redline_test.dart` | 2 | `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md:517` | 代码路径(疑重构/移走) |
| `lib/features/sweep/domain/sweep_readiness.dart` | 2 | `docs/superpowers/plans/2026-07-08-sweep-readiness.md:15` | 代码路径(疑重构/移走) |
| `test/features/battle/domain/qi_combat_loop_test.dart` | 2 | `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md:219` | 代码路径(疑重构/移走) |
| `test/features/battle/application/inner_breath_disorder_recovery_test.dart` | 2 | `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md:349` | 代码路径(疑重构/移走) |
| `test/features/seclusion/inner_breath_disorder_recovery_test.dart` | 2 | `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md:350` | 代码路径(疑重构/移走) |
| `lib/features/cultivation/domain/progression_release_cap.dart` | 2 | `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md:55` | 代码路径(疑重构/移走) |
| `lib/features/expedition/domain/expedition_config.dart` | 2 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-a2-cap-config.md:38` | 代码路径(疑重构/移走) |
| `lib/features/boss_gauntlet/domain/boss_gauntlet_config.dart` | 2 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-a2-cap-config.md:39` | 代码路径(疑重构/移走) |
| `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart` | 2 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md:37` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/character_avatar.dart` | 2 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:101` | 代码路径(疑重构/移走) |
| `02_swap_dialog_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:17` | 截图/图片(多不入库) |
| `03_swapped_and_confirmed_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:17` | 截图/图片(多不入库) |
| `09_insert_into_empty_dialog_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:17` | 截图/图片(多不入库) |
| `04_disciple_dispatch_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:18` | 截图/图片(多不入库) |
| `05_founder_dispatch_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:18` | 截图/图片(多不入库) |
| `06_block_no_main_snackbar_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:19` | 截图/图片(多不入库) |
| `07_block_retreat_snackbar_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:19` | 截图/图片(多不入库) |
| `08_empty_seat_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:20` | 截图/图片(多不入库) |
| `12_hover_active_card_1280x720.png` | 1 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md:26` | 截图/图片(多不入库) |
| `data/narratives/lore/events/` | 1 | `docs/RELEASE_CHECKLIST_1_0.md:37` | 数据路径(疑移除/改名) |
| `docs/handoff/r3_visual_check_screenshots/` | 1 | `docs/RELEASE_CHECKLIST_1_0.md:110` | 截图目录(多不入库) |
| `docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png` | 1 | `docs/RELEASE_CHECKLIST_1_0.md:228` | 截图/图片(多不入库) |
| `lib/features/cultivation/domain/dispel_cultivation.dart` | 1 | `docs/audit/full_audit_2026-06-16.md:85` | 代码路径(疑重构/移走) |
| `test/support/def_loading.dart` | 1 | `docs/audit/full_project_review_2026-07-02.md:43` | 代码路径(疑重构/移走) |
| `docs/audit/early_difficulty_gate_probe_2026-07-05.dart` | 1 | `docs/audit/overnight_fix_and_balance_review_2026-07-08.md:86` | 文档路径(疑移走/删除) |
| `test/tools/output/readable_first_clear_tempo_2026-07-09.md` | 1 | `docs/audit/self_review_2026-07-09.md:37` | 生成物(不入库) |
| `test/tools/output/readable_first_clear_tempo_2026-07-09.csv` | 1 | `docs/audit/self_review_2026-07-09.md:38` | 生成物(不入库) |
| `data/narratives/mainline_test_01.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:40` | 数据路径(疑移除/改名) |
| `data/narratives/mainline_test_02.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:41` | 数据路径(疑移除/改名) |
| `data/narratives/mainline_test_03.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:42` | 数据路径(疑移除/改名) |
| `data/narratives/mainline_test_04.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:43` | 数据路径(疑移除/改名) |
| `data/narratives/mainline_test_05.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:44` | 数据路径(疑移除/改名) |
| `data/narratives/mainline_test_06.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:45` | 数据路径(疑移除/改名) |
| `data/narratives/stages/stage_01_01.yaml` | 1 | `docs/audit/yaml_integrity_2026-05-12.md:65` | 数据路径(疑移除/改名) |
| `lib/features/stage/stage_entry_flow.dart` | 1 | `docs/dispatch/2026-08-06_K1_kimi_techdebt_series.md:10` | 代码路径(疑重构/移走) |
| `/docs/dispatch_evidence/inscription_2026-08-06/` | 1 | `docs/dispatch/2026-08-06_night_plan.md:48` | 其他 |
| `data/chapters.yaml` | 1 | `docs/handoff/art_stage3_phase0_reality_check_2026-05-21.md:177` | 数据路径(疑移除/改名) |
| `docs/handoff/b_cover_visual_2026-05-31/technique_panel_top.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31/closeout.md:5` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/technique_panel_full.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31/closeout.md:6` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/technique_panel_bottom.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31/closeout.md:7` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31/technique_panel_1280x720.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31/closeout.md:8` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_full_max.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31_r3/closeout.md:11` | 截图/图片(多不入库) |
| `docs/handoff/b_cover_visual_2026-05-31_r3/technique_panel_seal.png` | 1 | `docs/handoff/b_cover_visual_2026-05-31_r3/closeout.md:12` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1280x720.png` | 1 | `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md:47` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1920x1080.png` | 1 | `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md:48` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1280x720.png` | 1 | `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md:52` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1920x1080.png` | 1 | `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md:53` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_console_visual_2026-06-12/t1_charge_break.png` | 1 | `docs/handoff/codex_batch3_console_visual_2026-06-12.md:22` | 截图/图片(多不入库) |
| `docs/handoff/codex_batch3_console_visual_r2_2026-06-12/` | 1 | `docs/handoff/codex_batch3_console_visual_r2_2026-06-12.md:14` | 文档路径(疑移走/删除) |
| `docs/handoff/batch3_visual_2026-05-30/` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:13` | 文档路径(疑移走/删除) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_01_transition_button.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:29` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_02_drop_tier.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:30` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_03a_battlelog.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:31` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_03b_summary.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:32` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_04_refine_button.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:33` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05a_picker_close.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:34` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05b_picker_empty.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:35` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05c_picker_empty_closed.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:36` | 截图/图片(多不入库) |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05d_picker_worn_by_other.png` | 1 | `docs/handoff/codex_batch3_visual_2026-05-30.md:37` | 截图/图片(多不入库) |
| `docs/equip-baicao-orchestration@25221323` | 1 | `docs/handoff/codex_battle_ui_stage_2026-07-16.md:57` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_battle_victory_ui_kit_2026-06-06/01_battle_victory_paper_report.png` | 1 | `docs/handoff/codex_battle_victory_ui_kit_2026-06-06.md:22` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_2026-06-05/05_inventory_full_after_divider.png` | 1 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_2026-06-05/06_shead_weapon_after_divider.png` | 1 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:30` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_2026-06-05/07_shead_armor_after_divider.png` | 1 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_2026-06-05/08_shead_accessory_after_divider.png` | 1 | `docs/handoff/codex_branch_closeout_t11_inventory_2026-06-06.md:32` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446/` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:27` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_break_feel_20260610_170446/charge_building.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:46` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:47` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446/charge_building_static.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:48` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446/interrupt_caption_static.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:49` | 截图/图片(多不入库) |
| `docs/handoff/codex_break_feel_20260610_170446/after_click_probe.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:50` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_charge_break_1280x720.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:53` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_4d370db0_20260610_170843/battle_interrupt_caption_1280x720.png` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:54` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_4d370db0_20260610_170843/manifest.txt` | 1 | `docs/handoff/codex_break_feel_20260610_170446.md:55` | 截图目录(多不入库) |
| `docs/handoff/codex_character_header_polish_2026-06-07/01_character_header_portrait_plaque.png` | 1 | `docs/handoff/codex_character_header_polish_2026-06-07.md:28` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06/01_character_panel.png` | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06/02_character_panel_encounter_skill.png` | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md:30` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06/03_character_panel_slots.png` | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06/04_character_panel_readability.png` | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md:32` | 截图/图片(多不入库) |
| `docs/handoff/codex_character_panel_ui_polish_2026-06-06/05_character_panel_profile_header.png` | 1 | `docs/handoff/codex_character_panel_ui_polish_2026-06-06.md:33` | 截图/图片(多不入库) |
| `docs/handoff/ch4_visual_check_closeout_2026-05-22.md` | 1 | `docs/handoff/codex_dispatch_ch4_visual_check_2026-05-22.md:60` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_chapter_cover_2026-06-01/` | 1 | `docs/handoff/codex_dispatch_chapter_cover_2026-06-01.md:19` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_chapter_cover_recheck_2026-06-01/` | 1 | `docs/handoff/codex_dispatch_chapter_cover_recheck_2026-06-01.md:25` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_char_panel_profile_2026-06-01/` | 1 | `docs/handoff/codex_dispatch_char_panel_profile_2026-06-01.md:26` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_narrative_scene_2026-06-02/` | 1 | `docs/handoff/codex_dispatch_narrative_scene_2026-06-02.md:34` | 文档路径(疑移走/删除) |
| `docs/handoff/p4_1_1_screenshots_r2/` | 1 | `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md:64` | 文档路径(疑移走/删除) |
| `docs/handoff/pen_visual_verify_p4_1_1_round2_2026-05-27.md` | 1 | `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md:84` | 文档路径(疑移走/删除) |
| `docs/handoff/r4_visual_check_screenshots/r4_10_skill_description.png` | 1 | `docs/handoff/codex_dispatch_r4_p2_1_content_drop_2026-05-28.md:16` | 截图/图片(多不入库) |
| `docs/handoff/r4_visual_check_screenshots/r4_12_synergy_no_crash.png` | 1 | `docs/handoff/codex_dispatch_r4_p2_1_content_drop_2026-05-28.md:17` | 截图/图片(多不入库) |
| `docs/handoff/codex_treasure_glow_acceptance_2026-06-13_closeout.md` | 1 | `docs/handoff/codex_dispatch_treasure_glow_2026-06-13.md:64` | 文档路径(疑移走/删除) |
| `lib/ui/character_panel/character_panel_screen.dart` | 1 | `docs/handoff/codex_dispatch_w14_3_round2_2026-05-15.md:104` | 代码路径(疑重构/移走) |
| `lib/ui/theme/colors.dart` | 1 | `docs/handoff/codex_dispatch_w14_3c_2026-05-14.md:94` | 代码路径(疑重构/移走) |
| `lib/ui/enhancement/enhance_dialog.dart` | 1 | `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md:22` | 代码路径(疑重构/移走) |
| `lib/ui/inventory/inventory_screen.dart` | 1 | `docs/handoff/codex_dispatch_w15_equipment_detail_2026-05-15.md:23` | 代码路径(疑重构/移走) |
| `docs/screenshots/w15_equipment_detail_round2/` | 1 | `docs/handoff/codex_dispatch_w15_equipment_detail_round2_2026-05-15.md:91` | 截图目录(多不入库) |
| `docs/screenshots/w16/` | 1 | `docs/handoff/codex_dispatch_w16_festival_chip_visual_check_2026-05-16.md:117` | 截图目录(多不入库) |
| `docs/screenshots/w18/` | 1 | `docs/handoff/codex_dispatch_w18_a1_synergy_visual_check_2026-05-17.md:211` | 截图目录(多不入库) |
| `docs/handoff/codex_encounter_outcome_banner_2026-06-07/01_encounter_outcome_skill_1280x720.png` | 1 | `docs/handoff/codex_encounter_outcome_banner_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/00_contact_sheet_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:21` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/01_main_menu_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:22` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/02_battle_in_progress_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:23` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/03_battle_victory_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:24` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/04_character_panel_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:25` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/05_inventory_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:26` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/06_equipment_detail_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:27` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/07_technique_panel_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:28` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/08_mainline_stage_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/09_tower_map_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:30` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/10_seclusion_map_1280x720.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/00_contact_sheet_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:35` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/01_main_menu_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:36` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/02_battle_in_progress_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:37` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/03_battle_victory_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:38` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/04_character_panel_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:39` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/05_inventory_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:40` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/06_equipment_detail_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:41` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/07_technique_panel_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:42` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/08_mainline_stage_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:43` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/09_tower_map_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:44` | 截图/图片(多不入库) |
| `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/10_seclusion_map_1920x1080.png` | 1 | `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07.md:45` | 截图/图片(多不入库) |
| `docs/handoff/codex_growth_ceremony_victory_2026-06-07/01_victory_growth_ceremony_1280x720.png` | 1 | `docs/handoff/codex_growth_ceremony_victory_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_icons_2026-06-07/01_main_menu_icons_1280x720.png` | 1 | `docs/handoff/codex_main_menu_icons_2026-06-07.md:28` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_second_pass_2026-06-06/01_main_menu_three_columns.png` | 1 | `docs/handoff/codex_main_menu_second_pass_2026-06-06.md:23` | 截图/图片(多不入库) |
| `docs/handoff/codex_main_menu_status_2026-06-07/01_main_menu_status_1280x720.png` | 1 | `docs/handoff/codex_main_menu_status_2026-06-07.md:33` | 截图/图片(多不入库) |
| `docs/handoff/codex_mainline_route_visual_2026-06-07/01_chapter_route_full.png` | 1 | `docs/handoff/codex_mainline_route_visual_2026-06-07.md:30` | 截图/图片(多不入库) |
| `docs/handoff/codex_mainline_route_visual_2026-06-07/02_chapter_route_1280x720.png` | 1 | `docs/handoff/codex_mainline_route_visual_2026-06-07.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_asset_integration_2026-06-07/01_main_menu_mj_assets.png` | 1 | `docs/handoff/codex_mj_asset_integration_2026-06-07.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_asset_integration_2026-06-07/02_main_menu_mj_assets_clean_bg.png` | 1 | `docs/handoff/codex_mj_asset_integration_2026-06-07.md:33` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/01_battle_boss_fx_overlay.png` | 1 | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07.md:49` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/02_battle_boss_fx_overlay_restart.png` | 1 | `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07.md:50` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07/01_battle_boss_frame_victory_title.png` | 1 | `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07.md:35` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07/seclusion_result_ceremony_full.png` | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md:51` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07/battle_victory_first_clear_ceremony_full.png` | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md:52` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07/technique_refine_insight_dialog_ceremony_full.png` | 1 | `docs/handoff/codex_mj_ceremony_integration_2026-06-07.md:53` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/01_main_menu_gate_bg.png` | 1 | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07.md:33` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/02_main_menu_gate_bg_clean.png` | 1 | `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07.md:35` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_red_seal_integration_2026-06-07/01_first_clear_red_seal.png` | 1 | `docs/handoff/codex_mj_red_seal_integration_2026-06-07.md:28` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_red_seal_integration_2026-06-07/02_battle_victory_red_seal.png` | 1 | `docs/handoff/codex_mj_red_seal_integration_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_05adb81_20260609_212740/` | 1 | `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md:9` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_05adb81_20260609_214413/character_panel_1280x720.png` | 1 | `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md:10` | 截图/图片(多不入库) |
| `docs/handoff/codex_p0_break_ui_visual_2026-06-09_assets/` | 1 | `docs/handoff/codex_p0_break_ui_visual_2026-06-09.md:11` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_phase5_mainline1_visual_2026-06-17/` | 1 | `docs/handoff/codex_phase5_mainline1_visual_2026-06-17.md:10` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_refine_insight_dialog_2026-06-07/01_refine_insight_dialog_1280x720.png` | 1 | `docs/handoff/codex_refine_insight_dialog_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/screenshots/round2_01_main_menu_mountain.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:13` | 截图/图片(多不入库) |
| `docs/screenshots/round2_02_chapter_list.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:14` | 截图/图片(多不入库) |
| `docs/screenshots/round2_03_inventory_equipment.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:15` | 截图/图片(多不入库) |
| `docs/screenshots/round2_04_equipment_detail.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:16` | 截图/图片(多不入库) |
| `docs/screenshots/round2_05_inventory_material.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:17` | 截图/图片(多不入库) |
| `docs/screenshots/round2_06_lineage_panel.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:18` | 截图/图片(多不入库) |
| `docs/screenshots/round2_07_technique_panel.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:19` | 截图/图片(多不入库) |
| `docs/screenshots/round2_08_seclusion_meditation.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:20` | 截图/图片(多不入库) |
| `docs/screenshots/round2_09_home_feed_seal_baseline.png` | 1 | `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md:21` | 截图/图片(多不入库) |
| `docs/handoff/codex_route_map_first_slice_2026-06-06/01_mainline_route_map.png` | 1 | `docs/handoff/codex_route_map_first_slice_2026-06-06.md:31` | 截图/图片(多不入库) |
| `docs/handoff/codex_route_map_first_slice_2026-06-06/02_tower_spine.png` | 1 | `docs/handoff/codex_route_map_first_slice_2026-06-06.md:32` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06/01_seclusion_map_list.png` | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06.md:18` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06/02_seclusion_setup.png` | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06.md:19` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06/03_active_retreat.png` | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06.md:20` | 截图/图片(多不入库) |
| `docs/handoff/codex_seclusion_map_visual_2026-06-06/04_retreat_result.png` | 1 | `docs/handoff/codex_seclusion_map_visual_2026-06-06.md:21` | 截图/图片(多不入库) |
| `docs/handoff/codex_stage_journey_visual_2026-06-07/01_stage_journey_1280x720.png` | 1 | `docs/handoff/codex_stage_journey_visual_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_t11_inventory_fix_2026-06-05/` | 1 | `docs/handoff/codex_t11_inventory_fix_closeout_2026-06-06.md:50` | 文档路径(疑移走/删除) |
| `docs/handoff/visual_capture_f771ab7_20260609_131615/` | 1 | `docs/handoff/codex_t9_result_2026-06-09.md:3` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_f771ab7_20260609_131615/manifest.txt` | 1 | `docs/handoff/codex_t9_result_2026-06-09.md:4` | 截图目录(多不入库) |
| `docs/handoff/codex_technique_school_matrix_2026-06-07/01_technique_school_matrix_1280x720.png` | 1 | `docs/handoff/codex_technique_school_matrix_2026-06-07.md:29` | 截图/图片(多不入库) |
| `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/` | 1 | `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md:202` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_mj_ceremony_integration_2026-06-07/` | 1 | `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md:204` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/` | 1 | `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md:206` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_tower_visual_second_pass_2026-06-06/01_tower_stepped_spine.png` | 1 | `docs/handoff/codex_tower_visual_second_pass_2026-06-06.md:26` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:18` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260613_004017/` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:22` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260613_004658/` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:24` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260613_011907/` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:26` | 截图目录(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260613_011907/_before_after_ui_polish_3_routes_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:28` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_sheet_27_routes_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:30` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_battle_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:31` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_systems_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:32` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_seclusion_equipment_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:33` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_5cdd696e_20260612_234753/_contact_narrative_dialog_gallery_1280x720.png` | 1 | `docs/handoff/codex_ui_polish_sweep_2026-06-12_closeout.md:34` | 截图/图片(多不入库) |
| `docs/handoff/codex_victory_first_clear_2026-06-07/01_boss_first_clear_banner_1280x720.png` | 1 | `docs/handoff/codex_victory_first_clear_2026-06-07.md:17` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_char_panel_bc_2026-06-04_closeout.md` | 1 | `docs/handoff/codex_vis_char_panel_bc_2026-06-04.md:38` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_art_2026-06-04/` | 1 | `docs/handoff/codex_vis_enemy_equipment_2026-06-04.md:5` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_main_menu_smoke_1280.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:36` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:37` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory_1920.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:38` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:39` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel_1920.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:40` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:41` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero_1920.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:42` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1280_top.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:43` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:44` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_2.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:45` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_3.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:46` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_4.png` | 1 | `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md:47` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_rerun_2026-06-04/` | 1 | `docs/handoff/codex_vis_rerun_2026-06-04.md:5` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05/` | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05.md:6` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05/01_inventory_full.png` | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05.md:55` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05/02_shead_weapon.png` | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05.md:56` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05/03_shead_armor.png` | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05.md:57` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_t11_inventory_2026-06-05/04_shead_accessory.png` | 1 | `docs/handoff/codex_vis_t11_inventory_2026-06-05.md:58` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:6` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/01_inventory.png` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:76` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/02_equipment_detail.png` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:77` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/03_technique_panel.png` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:78` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/04_battle_victory.png` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:79` | 截图/图片(多不入库) |
| `docs/handoff/codex_vis_textscale_mj_2026-06-07/05_main_menu.png` | 1 | `docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:80` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_chapter_cover_2026-06-01/01_chapter_list_top.png` | 1 | `docs/handoff/codex_visual_chapter_cover_2026-06-01.md:8` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_chapter_cover_2026-06-01/02_chapter_list_scroll.png` | 1 | `docs/handoff/codex_visual_chapter_cover_2026-06-01.md:9` | 截图/图片(多不入库) |
| `docs/handoff/visual_capture_manual_33265c8_20260531_165322/` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:17` | 截图目录(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_top_fullscreen.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:19` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_mid_fullscreen.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:20` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_lower_fullscreen.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:21` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_bottom_fullscreen.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:22` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_main_debug_entry.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:34` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_candidate_debug_list_no_portraits.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:35` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_recruit_dialog_no_portrait.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:36` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_top.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:46` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_bottom.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:47` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_top.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:58` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_bottom.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:59` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_compress_portraits_20260531/b_portrait_asset_contact_sheet.png` | 1 | `docs/handoff/codex_visual_compress_portraits_20260531.md:60` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:19` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:20` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_member_row_closeup.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:21` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top_r2.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:22` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom_r2.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:23` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_force_recruit_list.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:24` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_recruit_confirm_dialog.png` | 1 | `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-1a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:20` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-1b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:20` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-2a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:21` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-2b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:21` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-3a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-3b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-4a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-4b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-5a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-5b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-6a_opening.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_round3/r3-6b_outcome.png` | 1 | `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/02_shenwu_tian_wen_jian.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:18` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/03_shenwu_kun_lun_pei.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:19` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/04_baowu_chang_hong_jian.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:20` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/05_baowu_jin_si_jia.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:21` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/06_zhongqi_qing_xu_jian.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/07_zhongqi_yin_lin_jia.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/08_enhance_open.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail_round2/09_enhance_plus1.png` | 1 | `docs/handoff/codex_w15_equipment_detail_round2_visual_check_2026-05-15.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/02_liqi_long_quan.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/03_haojiahuo_qing_feng_jian.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/04_xiangyang_gang_dao.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/05_xunchang_bu_yi.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/06_enhance_tab.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:26` | 截图/图片(多不入库) |
| `docs/screenshots/w15_equipment_detail/07_forging_tab.png` | 1 | `docs/handoff/codex_w15_equipment_detail_visual_check_2026-05-15.md:27` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/02_xunchang_shengshu_plus0.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/03_xiangyang_chenshou_plus5.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/04_haojiahuo_moqi_plus10.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/05_liqi_xinjian_plus15_heritage.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/06_zhongqi_moqi_plus19.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:26` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/07_shenwu_xinjian_plus0.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:27` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/08_aperture_zero_slots.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/09_aperture_one_slot_attack.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:29` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/10_aperture_two_slots.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:30` | 截图/图片(多不入库) |
| `docs/screenshots/w15_resonance/11_aperture_three_slots_full.png` | 1 | `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md:31` | 截图/图片(多不入库) |
| `docs/screenshots/w15_stage_drop/02_inventory_after_drop.png` | 1 | `docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md:19` | 截图/图片(多不入库) |
| `docs/screenshots/w15_stage_drop/03_materials_mojianshi.png` | 1 | `docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md:20` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/seed_precheck_vc15_fresh_main_technique_r2.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/A1_mainline_01_01_dialog_localized.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:29` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/A2_mainline_01_01_narrative_after_dialog.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:30` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/B1_mainline_01_02_dialog_advancement.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:31` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/C1_tower_floor1_firstclear_advancement.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:32` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/D1_inventory_material_tab_fresh.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:33` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog_round2/D2_inventory_material_tab_accumulated.png` | 1 | `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md:34` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/A1_mainline_01_01_dialog.png` | 1 | `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md:21` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/A2_mainline_01_01_narrative_after_dialog.png` | 1 | `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md:22` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/B1_mainline_01_02_dialog.png` | 1 | `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md:23` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/C1_tower_floor2_firstclear_actual.png` | 1 | `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md:24` | 截图/图片(多不入库) |
| `docs/screenshots/w15_victory_dialog/C2_tower_floor2_replay_actual.png` | 1 | `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:20` | 截图目录(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chunJie.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:26` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_yuanXiao.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:27` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_duanWu.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_qiXi.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:29` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_zhongQiu.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:30` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chongYang.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:31` | 截图/图片(多不入库) |
| `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_cleared.png` | 1 | `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md:32` | 截图/图片(多不入库) |
| `docs/screenshots/w17/w17_festival_chip_chuXi.png` | 1 | `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md:26` | 截图/图片(多不入库) |
| `docs/screenshots/w17/w17_festival_chip_qingMingJie.png` | 1 | `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md:27` | 截图/图片(多不入库) |
| `docs/screenshots/w17/w17_festival_dialog_9_options.png` | 1 | `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/w17_lineage_panel/w17_lineage_main_menu_9buttons.png` | 1 | `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md:25` | 截图/图片(多不入库) |
| `docs/screenshots/w17_lineage_panel/w17_lineage_panel_empty.png` | 1 | `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md:26` | 截图/图片(多不入库) |
| `docs/screenshots/w17_lineage_panel/w17_lineage_panel_full_after_p5.png` | 1 | `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md:27` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_phase2menu_13buttons.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:28` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_chip_01_yinyang.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:29` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_chip_02_gangrou.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:30` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_chip_03_yinying.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:31` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_chip_04_tongpai.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:32` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_chip_05_tongbei.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:33` | 截图/图片(多不入库) |
| `docs/screenshots/w18/w18_a1_battle_stage_01_05_injection.png` | 1 | `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md:34` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.out.log` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:42` | 文档路径(疑移走/删除) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_run.err.log` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:43` | 文档路径(疑移走/删除) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_start.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:61` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A0_main_menu.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:62` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_A1_chapterlist.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:63` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_top.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:64` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_main_menu_scrolled.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:65` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B0_phase2_menu.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:66` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_after_seed_target.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:67` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B1_chapterlist.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:68` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B2_chapterlist.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:69` | 截图/图片(多不入库) |
| `docs/handoff/whitescreen_repro_2026-05-30/whitescreen_B3_chapterlist.png` | 1 | `docs/handoff/codex_whitescreen_repro_2026-05-30.md:70` | 截图/图片(多不入库) |
| `docs/handoff/deepseek_p1_44_continued_lore_closeout_2026-05-19.md` | 1 | `docs/handoff/deepseek_p1_44_continued_lore_dispatch_2026-05-19.md:326` | 文档路径(疑移走/删除) |
| `lib/shared/widgets/auto_play_toggle.dart` | 1 | `docs/handoff/g3_autoplay_toggle_closeout_2026-06-13.md:22` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/stage_auto_play_control.dart` | 1 | `docs/handoff/g3_autoplay_toggle_closeout_2026-06-13.md:24` | 代码路径(疑重构/移走) |
| `test/tools/output/balance_simulation_2026-05-29.csv` | 1 | `docs/handoff/m15_5h_autonomous_handoff_2026-05-29.md:13` | 生成物(不入库) |
| `lib/features/tower/domain/tower_progress.g.dart` | 1 | `docs/handoff/p0_40_local_leaderboard_spec.md:102` | 代码路径(疑重构/移走) |
| `lib/features/main_menu/presentation/main_menu_screen.dart` | 1 | `docs/handoff/p0_40_local_leaderboard_spec.md:344` | 代码路径(疑重构/移走) |
| `test/features/main_menu/main_menu_screen_test.dart` | 1 | `docs/handoff/p0_40_local_leaderboard_spec.md:367` | 代码路径(疑重构/移走) |
| `test/features/debug/phase2_test_menu_test.dart` | 1 | `docs/handoff/p0_40_local_leaderboard_spec.md:368` | 代码路径(疑重构/移走) |
| `lib/core/application/battle_providers.dart:70/93` | 1 | `docs/handoff/p0_battle_strategy_spec.md:44` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/battle_demo.dart` | 1 | `docs/handoff/p0_battle_strategy_spec.md:50` | 代码路径(疑重构/移走) |
| `test/balance/battle_strategy_e2e_mainline_test.dart` | 1 | `docs/handoff/p0_battle_strategy_spec.md:343` | 代码路径(疑重构/移走) |
| `test/balance/battle_strategy_e2e_tower_test.dart` | 1 | `docs/handoff/p0_battle_strategy_spec.md:343` | 代码路径(疑重构/移走) |
| `lib/features/recruitment/domain/` | 1 | `docs/handoff/p1_1_a1_recruitment_audit_2026-05-21.md:239` | 代码路径(疑重构/移走) |
| `lib/features/resonance/` | 1 | `docs/handoff/p1_1_a3_resonance_phase0_audit_2026-05-21.md:29` | 代码路径(疑重构/移走) |
| `test/data/equipment_def_test.dart` | 1 | `docs/handoff/p1_1_a4_forging_phase0_audit_2026-05-21.md:138` | 代码路径(疑重构/移走) |
| `data/narratives/foo.yaml` | 1 | `docs/handoff/p1_1_mac_handoff_2026-05-12.md:141` | 数据路径(疑移除/改名) |
| `lib/services/mainline_progress_service.dart` | 1 | `docs/handoff/p1_1_mac_handoff_2026-05-12.md:219` | 代码路径(疑重构/移走) |
| `test/features/home_feed/presentation/home_feed_screen_time_format_test.dart` | 1 | `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md:24` | 代码路径(疑重构/移走) |
| `test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart` | 1 | `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md:26` | 代码路径(疑重构/移走) |
| `lib/features/event/application/game_event_service.g.dart` | 1 | `docs/handoff/p1_42_phase1_spec.md:172` | 代码路径(疑重构/移走) |
| `lib/features/event/domain/game_event_summary.dart` | 1 | `docs/handoff/p1_42_phase1_spec.md:173` | 代码路径(疑重构/移走) |
| `lib/core/domain/game_event_summary.dart` | 1 | `docs/handoff/p1_42_phase1_spec.md:216` | 代码路径(疑重构/移走) |
| `test/features/home_feed/application/home_feed_providers_test.dart` | 1 | `docs/handoff/p1_42_phase1_spec.md:228` | 代码路径(疑重构/移走) |
| `test/features/event/application/game_event_service_lore_hook_test.dart` | 1 | `docs/handoff/p1_42_phase1_spec.md:294` | 代码路径(疑重构/移走) |
| `lib/features/tutorial/application/tutorial_providers.g.dart` | 1 | `docs/handoff/p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md:27` | 代码路径(疑重构/移走) |
| `test/features/X/` | 1 | `docs/handoff/p1_42_phase2_p1z_p2_workflow_reflection_2026-05-18.md:25` | 代码路径(疑重构/移走) |
| `data/events/_archive/yu_zhong_qiao_men.yaml` | 1 | `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md:58` | 数据路径(疑移除/改名) |
| `test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart` | 1 | `docs/handoff/p2_3_ascension_closeout_2026-05-24.md:37` | 代码路径(疑重构/移走) |
| `data/narratives/chapters/chapter_04/05/06.yaml` | 1 | `docs/handoff/p2_mainline_audit_2026-05-21.md:196` | 数据路径(疑移除/改名) |
| `test/features/chapter_list_screen_test.dart` | 1 | `docs/handoff/p2_x_chapter6_phase0_reality_check_2026-05-22.md:35` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_x_inner_demon_spec_2026-05-22.md` | 1 | `docs/handoff/p2_x_inner_demon_phase0_reality_check_2026-05-22.md:59` | 文档路径(疑移走/删除) |
| `lib/features/inheritance/founder_buff_service.dart` | 1 | `docs/handoff/p2_x_inner_demon_spec_2026-05-22.md:142` | 代码路径(疑重构/移走) |
| `lib/features/light_foot/domain/light_foot_def.dart` | 1 | `docs/handoff/p3_1_lightfoot_closeout_2026-05-23.md:58` | 代码路径(疑重构/移走) |
| `test/data/numbers_config_pvp_def_test.dart` | 1 | `docs/handoff/p3_tech_debt_closeout_2026-05-25.md:49` | 代码路径(疑重构/移走) |
| `test/features/pvp/pvp_service_test.dart` | 1 | `docs/handoff/p3_tech_debt_closeout_2026-05-25.md:57` | 代码路径(疑重构/移走) |
| `lib/features/sect/domain/sect_rank.dart` | 1 | `docs/handoff/p4_1_b1_schema_closeout_2026-05-25.md:15` | 代码路径(疑重构/移走) |
| `lib/features/sect/domain/territory_def.dart` | 1 | `docs/handoff/p4_1_b1_schema_closeout_2026-05-25.md:16` | 代码路径(疑重构/移走) |
| `docs/handoff/h1_visual_check_screenshots/h1_01_main_menu.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:17` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_02_lategame_locked.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:18` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_03_pvp_locked.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:19` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_04_social_locked.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:20` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_05_equip_picker_open.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:21` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_06_equipped.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:22` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_07_realm_locked.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:23` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_08_unequip.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:24` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_10_chapter_transition_button.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:26` | 截图/图片(多不入库) |
| `docs/handoff/h1_visual_check_screenshots/h1_11_battle.png` | 1 | `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md:27` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step0_game_onboarding_window.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:13` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step0_main_loaded.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:14` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_opening_options.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:27` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_after_outcome_no_confirm.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:29` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step2_chapter1_stage_list.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:45` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_battle_or_result.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:46` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_after_wait.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:47` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step3_character_panel_lineage_sect_membership.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:63` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step4_desert_opening_options.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:80` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step4_desert_outcome_body.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:81` | 截图/图片(多不入库) |
| `docs/handoff/p4_1_1_screenshots/step4_mountain_outcome_or_phase2.png` | 1 | `docs/handoff/pen_visual_verify_p4_1_1_2026-05-26.md:82` | 截图/图片(多不入库) |
| `docs/handoff/r4_visual_check_screenshots/` | 1 | `docs/handoff/pen_visual_verify_r4_p2_1_content_drop_2026-05-28.md:5` | 截图目录(多不入库) |
| `test/foo_test.dart` | 1 | `docs/handoff/session_closeout_2026-05-25_v2.2_warmup_cleanup.md:32` | 代码路径(疑重构/移走) |
| `data/narratives/chapters/chapter_p2_01.yaml` | 1 | `docs/handoff/session_p2_audit_closeout_2026-05-21.md:77` | 数据路径(疑移除/改名) |
| `docs/handoff/_archived_phase5/` | 1 | `docs/handoff/stage_audit_2026-05-21.md:146` | 文档路径(疑移走/删除) |
| `docs/screenshots/phase3_w3_seclusion/` | 1 | `docs/handoff/t52_visual_check_spec_2026-05-12.md:7` | 截图目录(多不入库) |
| `docs/screenshots/phase3_w4/` | 1 | `docs/handoff/t58_visual_check_spec_2026-05-13.md:7` | 截图目录(多不入库) |
| `lib/providers/battle_providers.dart` | 1 | `docs/handoff/week10_phase4_defeat_resolution_2026-05-13.md:111` | 代码路径(疑重构/移走) |
| `test/services/battle_resolution_test.dart` | 1 | `docs/handoff/week11_victory_resolution_2026-05-13.md:112` | 代码路径(疑重构/移走) |
| `lib/data/models/skill_usage_entry.dart` | 1 | `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md:54` | 代码路径(疑重构/移走) |
| `lib/data/models/enums.dart` | 1 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:31` | 代码路径(疑重构/移走) |
| `lib/ui/encounter/encounter_hook.dart` | 1 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:67` | 代码路径(疑重构/移走) |
| `lib/ui/seclusion/active_retreat_screen.dart` | 1 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md:72` | 代码路径(疑重构/移走) |
| `lib/data/models/character.dart` | 1 | `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md:34` | 代码路径(疑重构/移走) |
| `lib/combat/battle_state.dart` | 1 | `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md:49` | 代码路径(疑重构/移走) |
| `lib/core/application/inventory_providers.g.dart` | 1 | `docs/handoff/week15_30_phase3_followup_inventory_material_tab_2026-05-16.md:41` | 代码路径(疑重构/移走) |
| `lib/ui/encounter/encounter_outcome_banner_test.dart` | 1 | `docs/handoff/week15_audit_c2_closeout_2026-05-15.md:27` | 代码路径(疑重构/移走) |
| `test/ui/encounter/encounter_outcome_banner_test.dart` | 1 | `docs/handoff/week15_audit_c2_closeout_2026-05-15.md:91` | 代码路径(疑重构/移走) |
| `test/ui/inventory/equipment_detail_screen_test.dart` | 1 | `docs/handoff/week15_full_closeout_2026-05-15.md:26` | 代码路径(疑重构/移走) |
| `test/features/tower/domain/tower_floor_def_test.dart:218/235/266` | 1 | `docs/handoff/week15_g_pen_t64_crlf_fix_2026-05-16.md:40` | 代码路径(疑重构/移走) |
| `lib/ui/seclusion/` | 1 | `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md:66` | 代码路径(疑重构/移走) |
| `test/ui/seclusion/` | 1 | `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md:66` | 代码路径(疑重构/移走) |
| `lib/data/models/retreat_session.dart` | 1 | `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md:213` | 代码路径(疑重构/移走) |
| `lib/ui/tower` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:56` | 代码路径(疑重构/移走) |
| `test/ui/tower` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:56` | 代码路径(疑重构/移走) |
| `lib/services/stage_battle_setup.dart` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:64` | 代码路径(疑重构/移走) |
| `lib/ui/mainline` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:92` | 代码路径(疑重构/移走) |
| `test/ui/mainline` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:92` | 代码路径(疑重构/移走) |
| `lib/ui/encounter` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:124` | 代码路径(疑重构/移走) |
| `test/ui/encounter` | 1 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md:124` | 代码路径(疑重构/移走) |
| `lib/features/character_panel/domain/character.dart` | 1 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:44` | 代码路径(疑重构/移走) |
| `lib/ui/theme/` | 1 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:151` | 代码路径(疑重构/移走) |
| `lib/ui/effects/` | 1 | `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md:151` | 代码路径(疑重构/移走) |
| `lib/services/cultivation_service.dart` | 1 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:100` | 代码路径(疑重构/移走) |
| `lib/services/dispel_service.dart` | 1 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md:101` | 代码路径(疑重构/移走) |
| `lib/ui/debug` | 1 | `docs/handoff/week15_phase5_3_e_k_2026-05-16.md:77` | 代码路径(疑重构/移走) |
| `test/services` | 1 | `docs/handoff/week15_phase5_3_e_k_2026-05-16.md:103` | 代码路径(疑重构/移走) |
| `lib/features/X/application/` | 1 | `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md:208` | 代码路径(疑重构/移走) |
| `test/ui/enhancement/` | 1 | `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md:289` | 代码路径(疑重构/移走) |
| `lib/features/service_providers.dart` | 1 | `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md:327` | 代码路径(疑重构/移走) |
| `lib/fixtures/phase2_seed_service.dart` | 1 | `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md:37` | 代码路径(疑重构/移走) |
| `lib/features/technique_panel/application/` | 1 | `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md:46` | 代码路径(疑重构/移走) |
| `/data/models/X.dart` | 1 | `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md:54` | 其他 |
| `data/lineage_heritages.yaml` | 1 | `docs/handoff/week4_d_minimal_spec_2026-05-13.md:99` | 数据路径(疑移除/改名) |
| `lib/ui/tower/tower_floor_list_screen.dart` | 1 | `docs/handoff/week9_a_audit_closeout_2026-05-13.md:36` | 代码路径(疑重构/移走) |
| `lib/ui/tower/tower_floor_card.dart` | 1 | `docs/handoff/week9_a_audit_closeout_2026-05-13.md:37` | 代码路径(疑重构/移走) |
| `lib/providers/tower_providers.dart` | 1 | `docs/handoff/week9_a_audit_closeout_2026-05-13.md:39` | 代码路径(疑重构/移走) |
| `test/features/tower/presentation/tower_entry_flow_test.dart:53` | 1 | `docs/handoff/wuxia_d3_plugin_enable_dry_run_2026-05-17.md:19` | 代码路径(疑重构/移走) |
| `data/events/_archive/huang_yuan_yi_zhong.yaml` | 1 | `docs/handoff/wuxia_orphan_events_rematch_prep_2026-05-17.md:71` | 数据路径(疑移除/改名) |
| `lib/features/character_panel/presentation/lineage_panel.dart` | 1 | `docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md:78` | 代码路径(疑重构/移走) |
| `lib/core/application/battle_providers.dart:58/75` | 1 | `docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md:22` | 代码路径(疑重构/移走) |
| `lib/features/sect_management/` | 1 | `docs/phase0/p4_1_sect_management_phase0_2026-05-25.md:99` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_visual_r5_2026-05-30/` | 1 | `docs/sessions/2026-05-30_1319_Codex验收triage与清理.md:14` | 文档路径(疑移走/删除) |
| `docs/handoff/v3_shenwu_drop_2026-05-30/` | 1 | `docs/sessions/2026-05-30_2256_V3神物金验收.md:10` | 文档路径(疑移走/删除) |
| `docs/handoff/v3_checklist_s9_2026-05-30/` | 1 | `docs/sessions/2026-05-30_2323_§9视觉验收收口.md:12` | 文档路径(疑移走/删除) |
| `docs/handoff/g4_narrative_tap_2026-05-30/` | 1 | `docs/sessions/2026-05-31_0023_G4验收闭环.md:15` | 文档路径(疑移走/删除) |
| `lib/shared/widgets/wuxia_paper_panel.dart` | 1 | `docs/sessions/2026-05-31_1507_出版美术心法面板.md:11` | 代码路径(疑重构/移走) |
| `docs/handoff/window_min_size_2026-06-02/` | 1 | `docs/sessions/2026-06-02_1925_窗口验收Pen修复性能验证.md:10` | 文档路径(疑移走/删除) |
| `docs/handoff/vis_char_panel_bc_2026-06-04/` | 1 | `docs/sessions/2026-06-04_1529_角色面板心魔与主修hero.md:14` | 文档路径(疑移走/删除) |
| `docs/superpowers/plans/2026-06-13-semi-manual-step5-full-closeout.md` | 1 | `docs/sessions/2026-06-13_半手动P0步骤5全闭环.md:11` | 文档路径(疑移走/删除) |
| `docs/acceptance_screenshots/` | 1 | `docs/sessions/2026-06-14_1816_红线收口.md:25` | 文档路径(疑移走/删除) |
| `docs/demos/battle_skill_status_ui_demo.html` | 1 | `docs/sessions/2026-06-14_1936_软红线放宽诊断.md:24` | 文档路径(疑移走/删除) |
| `docs/demos/` | 1 | `docs/sessions/2026-06-14_1936_软红线放宽诊断.md:24` | 文档路径(疑移走/删除) |
| `test/tools/output/extreme_cycle_diagnosis_2026-06-14.md` | 1 | `docs/sessions/2026-06-14_1936_软红线放宽诊断.md:25` | 生成物(不入库) |
| `docs/reviews/l1_acceptance/` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:8` | 文档路径(疑移走/删除) |
| `docs/reviews/l1_acceptance/fullscreen_on.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:16` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/fullscreen_off.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:17` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/res_720.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:25` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/res_900.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:26` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/res_1080.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:27` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/res_dropdown_disabled_in_fullscreen.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:28` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/f11_before.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:36` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/f11_after.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:37` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/restart_restored.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:43` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/m2_recap_card.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:49` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/round2/r2_altenter_before.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:68` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/round2/r2_altenter_after.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:69` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/round2/r2_recap_card.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:81` | 截图/图片(多不入库) |
| `docs/reviews/l1_acceptance/round2/r2_after_gocollect.png` | 1 | `docs/sessions/2026-06-15_l1_display_codex_acceptance.md:82` | 截图/图片(多不入库) |
| `docs/spec/2026-06-15-m2-offline-recap-design-DRAFT.md` | 1 | `docs/sessions/2026-06-15_overnight_autonomous_handoff.md:11` | 文档路径(疑移走/删除) |
| `docs/handoff/visual_acceptance_rerun_2026-06-30/rerun_triage_report.md` | 1 | `docs/sessions/2026-06-30_2133_视觉验收重验收口.md:10` | 文档路径(疑移走/删除) |
| `test/tools/output/tower_boss_feel_2026-07-01.md` | 1 | `docs/sessions/2026-07-01_1637_爬塔复核.md:25` | 生成物(不入库) |
| `test/tools/early_difficulty_gate_probe_test.dart` | 1 | `docs/sessions/2026-07-06_night_挂机夜批.md:28` | 代码路径(疑重构/移走) |
| `docs/audit/full_project_review_2026-07-06.md` | 1 | `docs/sessions/2026-07-06_night_视觉收口.md:24` | 文档路径(疑移走/删除) |
| `lib/shared/audio/audio_assets.dart:54/57` | 1 | `docs/sessions/2026-07-14_1026_心法合并收环.md:13` | 代码路径(疑重构/移走) |
| `docs/team-lineup-spec` | 1 | `docs/sessions/2026-07-14_2223_编成拍板.md:5` | 文档路径(疑移走/删除) |
| `lib/features/gauntlet/` | 1 | `docs/sessions/2026-07-17_0156_断魂庄C2.1入场扣帖.md:26` | 代码路径(疑重构/移走) |
| `data/defs/stage_def.dart` | 1 | `docs/sessions/2026-07-24_1851_三批收账.md:47` | 数据路径(疑移除/改名) |
| `test/features/battle/weakness_hit_glyph_test.dart` | 1 | `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md:325` | 代码路径(疑重构/移走) |
| `test/features/cultivation/skill_treasure_overlay_test.dart` | 1 | `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md:407` | 代码路径(疑重构/移走) |
| `test/features/mainline/stage_skill_drop_wiring_test.dart` | 1 | `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md:421` | 代码路径(疑重构/移走) |
| `data/narrative_loader.dart` | 1 | `docs/spec/2026-06-19-phase7-batch3-team-growth-plan.md:28` | 数据路径(疑移除/改名) |
| `test/core/domain/save_data_test.dart` | 1 | `docs/spec/2026-06-19-phase7-batch3-team-growth-plan.md:122` | 代码路径(疑重构/移走) |
| `test/redlines/` | 1 | `docs/spec/2026-06-20-p4-weapon-codex-plan.md:746` | 代码路径(疑重构/移走) |
| `lib/features/baike/application/martial_codex_provider.g.dart` | 1 | `docs/spec/2026-06-22-p4-martial-codex-plan.md:632` | 代码路径(疑重构/移走) |
| `lib/features/sect/application/sect_monthly_tick_gate.dart` | 1 | `docs/spec/2026-06-24-b1-sect-event-game-loop-wiring-design.md:107` | 代码路径(疑重构/移走) |
| `/data/defs/drop_entry.dart` | 1 | `docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md:77` | 其他 |
| `test/features/level/` | 1 | `docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md:610` | 代码路径(疑重构/移走) |
| `data/narratives/lore/events` | 1 | `docs/spec/P0_手动Boss战破招_落地方案_2026-06-09.md:183` | 数据路径(疑移除/改名) |
| `docs/handoff/h1_onboarding_audit.md` | 1 | `docs/spec/h_polish_ux_spec_2026-05-29.md:38` | 文档路径(疑移走/删除) |
| `docs/handoff/m15_f1_steam_signup_guide.md` | 1 | `docs/spec/m15_f_steam_spec_2026-05-29.md:71` | 文档路径(疑移走/删除) |
| `docs/legal/font_license.md` | 1 | `docs/spec/m15_g_legal_spec_2026-05-29.md:47` | 文档路径(疑移走/删除) |
| `docs/legal/audio_license.md` | 1 | `docs/spec/m15_g_legal_spec_2026-05-29.md:49` | 文档路径(疑移走/删除) |
| `data/narratives/chapters/chapter_0[4-5].yaml` | 1 | `docs/spec/overnight_v3_2026-05-24/A_ch4_5_yiliu_words.md:28` | 数据路径(疑移除/改名) |
| `test/jianghu/` | 1 | `docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md:119` | 代码路径(疑重构/移走) |
| `test/redline/p3_1_light_foot_redline_test.dart` | 1 | `docs/spec/p3_1_lightfoot_spec_2026-05-23.md:149` | 代码路径(疑重构/移走) |
| `lib/features/pvp/domain/strategy/pvp_strategy.dart` | 1 | `docs/spec/p3_3_pvp_spec_2026-05-24.md:99` | 代码路径(疑重构/移走) |
| `lib/features/pvp/application/pvp_service.dart` | 1 | `docs/spec/p3_3_pvp_spec_2026-05-24.md:100` | 代码路径(疑重构/移走) |
| `lib/features/pvp/application/pvp_sync_service.dart` | 1 | `docs/spec/p3_3_pvp_spec_2026-05-24.md:101` | 代码路径(疑重构/移走) |
| `lib/features/sect/presentation/sect_management_screen.dart` | 1 | `docs/spec/p4_1_sect_management_spec_2026-05-25.md:98` | 代码路径(疑重构/移走) |
| `test/sect_management/` | 1 | `docs/spec/p4_1_sect_management_spec_2026-05-25.md:120` | 代码路径(疑重构/移走) |
| `data/numbers_config.dart` | 1 | `docs/spec/p5_lineage_full_spec_2026-05-24.md:77` | 数据路径(疑移除/改名) |
| `test/features/battle/master_disciple_battle_test.dart` | 1 | `docs/spec/p5_onboarding_seed_spec_2026-05-25.md:30` | 代码路径(疑重构/移走) |
| `lib/data/seed_service.dart` | 1 | `docs/spec/p5_onboarding_seed_spec_2026-05-25.md:37` | 代码路径(疑重构/移走) |
| `test/features/onboarding/onboarding_service_test.dart` | 1 | `docs/spec/p5_onboarding_seed_spec_2026-05-25.md:84` | 代码路径(疑重构/移走) |
| `test/features/battle/presentation/battle_screen_result_overlay_test.dart` | 1 | `docs/superpowers/plans/2026-06-01-battle-screen-publishing-art-b1.md:317` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_visual_battle_p0_2_2026-06-XX.md` | 1 | `docs/superpowers/plans/2026-06-02-p0-2-battle-visibility.md:630` | 文档路径(疑移走/删除) |
| `lib/features/inner_demon/application/inner_demon_providers.g.dart` | 1 | `docs/superpowers/plans/2026-06-04-p0-3-bc-inner-demon-panel.md:232` | 代码路径(疑重构/移走) |
| `test/features/battle/stage_battle_setup_test.dart` | 1 | `docs/superpowers/plans/2026-06-10-cangjingge-skill-loadout.md:530` | 代码路径(疑重构/移走) |
| `lib/features/battle/domain/default_ground_strategy.dart` | 1 | `docs/superpowers/plans/2026-06-14-cycle-evolution-p1.md:27` | 代码路径(疑重构/移走) |
| `test/features/battle/battle_replay_record_service_test.dart` | 1 | `docs/superpowers/plans/2026-06-14-cycle-evolution-p1.md:40` | 代码路径(疑重构/移走) |
| `data/game_repository.dart` | 1 | `docs/superpowers/plans/2026-06-15-m2-offline-passive-idle.md:528` | 数据路径(疑移除/改名) |
| `test/features/battle/presentation/battle_cd_ring_test.dart` | 1 | `docs/superpowers/plans/2026-07-01-countdown-ring-cd-debuff.md:388` | 代码路径(疑重构/移走) |
| `/data/defs/founder_names_def.dart` | 1 | `docs/superpowers/plans/2026-07-03-founder-sect-naming.md:215` | 其他 |
| `../data/defs/` | 1 | `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md:422` | 相对父目录(边界) |
| `../data/defs/boss_vulnerability_def.dart` | 1 | `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch3-inner-demon.md:531` | 相对父目录(边界) |
| `/data/defs/boss_vulnerability_def.dart` | 1 | `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md:37` | 其他 |
| `docs/sessions/2026-07-04-` | 1 | `docs/superpowers/plans/2026-07-04-endgame-mechanic-boss-batch4-cycle-vulnerability.md:572` | 文档路径(疑移走/删除) |
| `data/balance/features/tools` | 1 | `docs/superpowers/plans/2026-07-10-test-infrastructure-migrations.md:19` | 数据路径(疑移除/改名) |
| `test/shared/widgets/wuxia_title_bar_test.dart` | 1 | `docs/superpowers/plans/2026-07-10-ui-reliability.md:17` | 代码路径(疑重构/移走) |
| `lib/features/encounter/domain/encounter_event_loader.dart` | 1 | `docs/superpowers/plans/2026-07-13-character-attribute-roles.md:185` | 代码路径(疑重构/移走) |
| `test/features/cultivation/level_up_summary_test.dart` | 1 | `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md:320` | 代码路径(疑重构/移走) |
| `lib/features/level/application/level_service.dart` | 1 | `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md:505` | 代码路径(疑重构/移走) |
| `test/combat/level_derived_stats_test.dart` | 1 | `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md:513` | 代码路径(疑重构/移走) |
| `test/data/character_level_repair_test.dart` | 1 | `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md:674` | 代码路径(疑重构/移走) |
| `test/features/boss_gauntlet/gauntlet_controller_test.dart` | 1 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md:129` | 代码路径(疑重构/移走) |
| `test/features/boss_gauntlet/gauntlet_entry_test.dart` | 1 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-c-gauntlet.md:145` | 代码路径(疑重构/移走) |
| `lib/features/boss_gauntlet/application/gauntlet_stage_plan.dart` | 1 | `docs/superpowers/plans/2026-07-17-gauntlet-battle-flow-wiring.md:19` | 代码路径(疑重构/移走) |
| `data/defs/` | 1 | `docs/superpowers/plans/2026-07-19-equipment-disposal-migration.md:40` | 数据路径(疑移除/改名) |
| `../data/defs/equipment_disposal_def.dart` | 1 | `docs/superpowers/plans/2026-07-19-equipment-disposal-migration.md:46` | 相对父目录(边界) |
| `test/data/progression_release_cap_test.dart` | 1 | `docs/superpowers/plans/2026-07-20-ch10-yiliu.md:128` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/hp_bar.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:100` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/stage_command_desk.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:123` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/skill_command_strip.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:124` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/battle_pouch.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:125` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/battle_scene_background.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:146` | 代码路径(疑重构/移走) |
| `lib/features/battle/presentation/widgets/battlefield.dart` | 1 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md:147` | 代码路径(疑重构/移走) |
| `lib/features/onboarding/application/master_builder.dart:buildMasterCharacter` | 1 | `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md:33` | 代码路径(疑重构/移走) |
| `lib/features/sect/presentation/sect_screen.dart:_MemberRow` | 1 | `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md:37` | 代码路径(疑重构/移走) |
| `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart:_CandidateInfo` | 1 | `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md:40` | 代码路径(疑重构/移走) |
| `test/features/battle/battle_screen_target_chip_test.dart` | 1 | `docs/superpowers/specs/2026-07-05-skill-target-chip-design.md:78` | 代码路径(疑重构/移走) |
| `data/narratives/chapters/chapter_NN.yaml` | 1 | `docs/superpowers/specs/2026-07-18-erliu-content-ch8-design.md:12` | 数据路径(疑移除/改名) |

## 5. 跳过类样本与说明

- **通配 `* ? {}`**(374 条):文件名通配,非具体引用。例:`docs/handoff/*dispatch*.md`(docs/dispatch/README.md:10)指一类历史派单包。
- **模板 `<>` / `...`**(20 条):占位符模板。例:`<date>_<单号>_<端>_<域>.md`(docs/dispatch/README.md:7)为派单包命名模板。
- **范围简写 `a..b`**(2 条):文件名区间简写。例:`docs/handoff/r4_visual_check_screenshots/r4_01..r4_12.png`(docs/RELEASE_CHECKLIST_1_0.md:119)指 r4_01 到 r4_12 共 12 张图。
- **日期模板**(3 条):`YYYY-MM-DD_HHMM_` 占位。例:`docs/sessions/YYYY-MM-DD_HHMM_<主题>.md`(docs/handoff/README.md:11)。
- **前缀简写**(18 条):末段无扩展名且以 `_` 结尾,属「前缀提及」非具体文件。例:`docs/handoff/visual_capture_`、`data/narratives/chapters/chapter_`。

## 6. 补充:非反引号裸路径死链线索(任务主范围外·高误报·人工复核)

> 任务定义只扫「md 链接 + 反引号路径」。本节扫描**非反引号、非 md 链接**的裸文本路径(已通过路径形态过滤),244 条。
> 裸文本提及可能为行文举例而非引用,且多文件并列清单(；/、分隔)只取首个校验。**本节不作为死链结论,仅供人工线索。**

> 共 244 条;仅列通过路径形态过滤者,裸文本提及可能为行文而非引用,**不作为死链结论**。

| md 文件 | 行 | 引用原文 | 目标(清洗后) | 类别 |
|---|---:|---|---|---|
| `docs/RELEASE_CHECKLIST_1_0.md` | 130 | `docs/handoff/v3_checklist_s9_2026-05-30/` | `docs/handoff/v3_checklist_s9_2026-05-30/` | 文档路径(疑移走/删除) |
| `docs/art/equipment_detail_prompts_2026-05-28.md` | 6 | `docs/art/MJ_Stage2_W6_prompts.txt` | `docs/art/MJ_Stage2_W6_prompts.txt` | 文档路径(疑移走/删除) |
| `docs/audit/drop_consistency_2026-06-23.md` | 20 | `lib/data/test` | `lib/data/test` | 代码路径(疑重构/移走) |
| `docs/audit/full_project_bughunt_2026-07-07.md` | 8 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/audit/full_project_review_2026-07-02.md` | 24 | `/data/lore/` | `/data/lore/` | 其他 |
| `docs/audit/global_content_visual_audit_2026-07-25.md` | 816 | `/data/visual` | `/data/visual` | 其他 |
| `docs/dispatch/2026-08-06_night_plan.md` | 41 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/handoff/5h_autonomous_handoff_2026-05-26.md` | 4 | `test/analyze` | `test/analyze` | 代码路径(疑重构/移走) |
| `docs/handoff/5h_autonomous_handoff_2026-05-26.md` | 19 | `test/analyze` | `test/analyze` | 代码路径(疑重构/移走) |
| `docs/handoff/art_assets_integration_closeout_2026-05-20.md` | 99 | `lib/features/character/master/disciple` | `lib/features/character/master/disciple` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_2026-05-12.md` | 23 | `docs/audits/` | `docs/audits/` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_dispatch_2026-05-12.md` | 94 | `test/core/combat/damage_calculator_test.dart` | `test/core/combat/damage_calculator_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/codex_dispatch_battle_b2_2026-06-01.md` | 9 | `docs/macos` | `docs/macos` | 文档路径(疑移走/删除) |
| `docs/handoff/codex_visual_narrative_scene_2026-06-02.md` | 16 | `docs/handoff/codex_visual_narrative_scene_2026-06-02/01_stage_01_05.png` | `docs/handoff/codex_visual_narrative_scene_2026-06-02/01_stage_01_05.png` | 截图/图片(多不入库) |
| `docs/handoff/codex_visual_tier_cover_2026-05-31.md` | 6 | `docs/handoff/visual_capture_manual_33265c8_20260531_165322/` | `docs/handoff/visual_capture_manual_33265c8_20260531_165322/` | 截图目录(多不入库) |
| `docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md` | 45 | `docs/screenshots-only` | `docs/screenshots-only` | 截图目录(多不入库) |
| `docs/handoff/deepseek_w18_a2_event_yaml_dispatch_2026-05-17.md` | 257 | `lib/data/synergies.yaml` | `lib/data/synergies.yaml` | 代码路径(疑重构/移走) |
| `docs/handoff/h2_midgame_audit_2026-05-29.md` | 25 | `test/seed` | `test/seed` | 代码路径(疑重构/移走) |
| `docs/handoff/nightshift_20260519_closeout.md` | 55 | `lib/core+features` | `lib/core+features` | 代码路径(疑重构/移走) |
| `docs/handoff/nightshift_20260519_handoff.md` | 129 | `lib/yaml` | `lib/yaml` | 代码路径(疑重构/移走) |
| `docs/handoff/overnight_2026-05-30_handoff.md` | 47 | `/data/error` | `/data/error` | 其他 |
| `docs/handoff/p1_2_spec_pending_e_fix_handoff_2026-05-24.md` | 9 | `lib/test/data` | `lib/test/data` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_2_spec_pending_e_fix_handoff_2026-05-24.md` | 45 | `lib/test/data` | `lib/test/data` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_nightshift_4subsys_closeout_2026-05-18.md` | 145 | `test/seed` | `test/seed` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase1_spec.md` | 42 | `test/seed` | `test/seed` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md` | 149 | `test/seed` | `test/seed` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md` | 148 | `test/seed` | `test/seed` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 192 | `data/codex/` | `data/codex/` | 数据路径(疑移除/改名) |
| `docs/handoff/p1_42_phase2_p1z_codex_spec.md` | 248 | `lib/features/codex/domain/codex_index.dart` | `lib/features/codex/domain/codex_index.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p1_44_red_line_case_impl_closeout_2026-05-19.md` | 89 | `docs/handoff/spec` | `docs/handoff/spec` | 文档路径(疑移走/删除) |
| `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md` | 38 | `/test/Phase` | `/test/Phase` | 其他 |
| `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md` | 49 | `/test/Phase` | `/test/Phase` | 其他 |
| `docs/handoff/p1_45_37_cleanup_closeout_2026-05-19.md` | 107 | `/test/Phase` | `/test/Phase` | 其他 |
| `docs/handoff/p1_x_chapter4_spec_2026-05-21.md` | 279 | `test/analyze` | `test/analyze` | 代码路径(疑重构/移走) |
| `docs/handoff/p2_mainline_audit_2026-05-21.md` | 314 | `data/yaml` | `data/yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 13 | `data/lore/pvp/pvp_event_first_blood.yaml` | `data/lore/pvp/pvp_event_first_blood.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 22 | `lib/features/pvp/application/pvp_providers.dart` | `lib/features/pvp/application/pvp_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 23 | `lib/features/pvp/presentation/pvp_screen.dart` | `lib/features/pvp/presentation/pvp_screen.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 24 | `lib/features/pvp/presentation/widgets/rank_badge_widget.dart` | `lib/features/pvp/presentation/widgets/rank_badge_widget.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 25 | `lib/features/pvp/presentation/widgets/pvp_history_list.dart` | `lib/features/pvp/presentation/widgets/pvp_history_list.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 26 | `data/lore/pvp/pvp_event_first_blood.yaml` | `data/lore/pvp/pvp_event_first_blood.yaml` | 数据路径(疑移除/改名) |
| `docs/handoff/p3_3_pvp_full_closeout_2026-05-24.md` | 27 | `test/features/pvp/pvp_screen_test.dart` | `test/features/pvp/pvp_screen_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/p3_tech_debt_closeout_2026-05-25.md` | 30 | `data/loading/error` | `data/loading/error` | 数据路径(疑移除/改名) |
| `docs/handoff/pen_visual_verify_h1_batch123_2026-05-30.md` | 25 | `data/code.` | `data/code` | 数据路径(疑移除/改名) |
| `docs/handoff/session_closeout_2026-05-25_nightshift_v2.1_complete.md` | 52 | `/test/build_runner` | `/test/build_runner` | 其他 |
| `docs/handoff/session_closeout_2026-05-25_v2.2_warmup_cleanup.md` | 45 | `test/analyzer` | `test/analyzer` | 代码路径(疑重构/移走) |
| `docs/handoff/t52_visual_check_spec_2026-05-12.md` | 158 | `docs/screenshots/phase3_w3_seclusion/` | `docs/screenshots/phase3_w3_seclusion/` | 截图目录(多不入库) |
| `docs/handoff/t58_visual_check_spec_2026-05-13.md` | 134 | `docs/screenshots/phase3_w4/` | `docs/screenshots/phase3_w4/` | 截图目录(多不入库) |
| `docs/handoff/week15_30_phase3_followup_inventory_material_tab_2026-05-16.md` | 86 | `/test/docs` | `/test/docs` | 其他 |
| `docs/handoff/week15_audit_c2_closeout_2026-05-15.md` | 27 | `test/ui/encounter/` | `test/ui/encounter/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 121 | `lib/ui/seclusion` | `lib/ui/seclusion` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 121 | `lib/services/seclusion_service.dart` | `lib/services/seclusion_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` | 137 | `lib/core/combat/` | `lib/core/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 104 | `data/providers/services/ui` | `data/providers/services/ui` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md` | 177 | `lib/core/combat/` | `lib/core/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 117 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 135 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 156 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 192 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_batch3_ui_features_2026-05-16.md` | 192 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 13 | `lib/combat/` | `lib/combat/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 13 | `lib/ui/battle/` | `lib/ui/battle/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 13 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 69 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 70 | `lib/ui/battle` | `lib/ui/battle` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 110 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 111 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 114 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 138 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 181 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 181 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 181 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 204 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md` | 252 | `lib/ui/debug/battle_test_menu.dart` | `lib/ui/debug/battle_test_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 1 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 1 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 44 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 46 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 49 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 50 | `lib/ui/theme` | `lib/ui/theme` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 51 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 51 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 53 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 59 | `data/persistence?` | `data/persistence` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 63 | `test/integration/` | `test/integration/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 63 | `test/data/persistence/` | `test/data/persistence/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 64 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 72 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 79 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 83 | `/data/ui` | `/data/ui` | 其他 |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 84 | `data/ui` | `data/ui` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 85 | `data/ui` | `data/ui` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 98 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 142 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 143 | `/data/features/ui/widget_test.dart` | `/data/features/ui/widget_test.dart` | 其他 |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 157 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 157 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 158 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 180 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 180 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_e_k_2026-05-16.md` | 180 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 13 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 13 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 13 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 72 | `lib/core/application/battle_providers.dart` | `lib/core/application/battle_providers.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 75 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 76 | `lib/ui/enhancement/enhance_dialog.dart` | `lib/ui/enhancement/enhance_dialog.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 77 | `lib/ui/enhancement/forging_panel.dart` | `lib/ui/enhancement/forging_panel.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 78 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 79 | `test/services/battle_resolution_test.dart` | `test/services/battle_resolution_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 79 | `test/services/phase2_scenarios_test.dart` | `test/services/phase2_scenarios_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 113 | `lib/features/equipment/application/equipment_service_providers.g.dart` | `lib/features/equipment/application/equipment_service_providers.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 113 | `lib/providers/isar_provider.g.dart` | `lib/providers/isar_provider.g.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 123 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 152 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 152 | `lib/features/X/application/` | `lib/features/X/application/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 192 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 192 | `lib/test_support/` | `lib/test_support/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 197 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 201 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 254 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 255 | `lib/ui/enhancement/` | `lib/ui/enhancement/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_equipment_features_2026-05-16.md` | 321 | `lib/providers/isar_provider.dart` | `lib/providers/isar_provider.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 39 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 145 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 152 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 152 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 155 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 157 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 257 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 261 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md` | 262 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 1 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 36 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 38 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 40 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 52 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 52 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 53 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 61 | `lib/services/phase2_seed_service.dart` | `lib/services/phase2_seed_service.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 61 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 70 | `lib/ui/debug/phase2_test_menu.dart` | `lib/ui/debug/phase2_test_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 71 | `test/services/master_disciple_battle_test.dart` | `test/services/master_disciple_battle_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 72 | `test/services/stage_battle_setup_test.dart` | `test/services/stage_battle_setup_test.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 79 | `lib/services/technique_learning.dart` | `lib/services/technique_learning.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 116 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 126 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 128 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 129 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 144 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 144 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 148 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_j_lib_services_cleanup_2026-05-16.md` | 150 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 13 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 13 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 37 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 41 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 55 | `data/numbers_config` | `data/numbers_config` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 64 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 64 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 79 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 163 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md` | 165 | `lib/data/defs/X_def.dart` | `lib/data/defs/X_def.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `test/services/` | `test/services/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `lib/ui/debug/` | `lib/ui/debug/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `lib/utils/` | `lib/utils/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 7 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 35 | `data/isar_provider.dart` | `data/isar_provider.dart` | 数据路径(疑移除/改名) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 43 | `lib/data/models` | `lib/data/models` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 43 | `test/data/models` | `test/data/models` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 44 | `lib/ui/theme/` | `lib/ui/theme/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 45 | `lib/ui/effects/` | `lib/ui/effects/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 46 | `lib/ui/strings.dart` | `lib/ui/strings.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 47 | `lib/utils/rng.dart` | `lib/utils/rng.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 48 | `lib/ui/narrative/` | `lib/ui/narrative/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 49 | `lib/providers/rng_provider` | `lib/providers/rng_provider` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 49 | `lib/shared/utils/rng_provider` | `lib/shared/utils/rng_provider` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 50 | `lib/providers/isar_provider` | `lib/providers/isar_provider` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 50 | `lib/data/isar_provider` | `lib/data/isar_provider` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 51 | `lib/ui/main_menu.dart` | `lib/ui/main_menu.dart` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 52 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 52 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 52 | `test/ui/` | `test/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 75 | `lib/ui/` | `lib/ui/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 75 | `lib/utils/` | `lib/utils/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 75 | `lib/providers/` | `lib/providers/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md` | 75 | `lib/data/models/` | `lib/data/models/` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_resonance_closeout_2026-05-15.md` | 20 | `lib/services` | `lib/services` | 代码路径(疑重构/移走) |
| `docs/handoff/week15_resonance_closeout_2026-05-15.md` | 20 | `lib/ui` | `lib/ui` | 代码路径(疑重构/移走) |
| `docs/handoff/week6_full_closeout_2026-05-14.md` | 70 | `lib/services/` | `lib/services/` | 代码路径(疑重构/移走) |
| `docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md` | 39 | `data/jianghu` | `data/jianghu` | 数据路径(疑移除/改名) |
| `docs/phase0/p3_3_pvp_phase0_2026-05-24.md` | 39 | `data/pvp` | `data/pvp` | 数据路径(疑移除/改名) |
| `docs/phase0/p3_4_sect_event_phase0_2026-05-24.md` | 49 | `data/sect` | `data/sect` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-30_1637_P5.2敌人内力对称化.md` | 46 | `data/lib/docs` | `data/lib/docs` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-30_2256_V3神物金验收.md` | 46 | `data/lib/docs/test` | `data/lib/docs/test` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-30_2256_V3神物金验收.md` | 50 | `/docs/handoff/...` | `/docs/handoff/` | 其他 |
| `docs/sessions/2026-05-30_2323_§9视觉验收收口.md` | 45 | `data/lib/docs/test` | `data/lib/docs/test` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-30_2323_§9视觉验收收口.md` | 48 | `/docs/handoff/...` | `/docs/handoff/` | 其他 |
| `docs/sessions/2026-05-30_2354_H段polish_G2banner_G4剧情轻点.md` | 45 | `data/lib/docs/test` | `data/lib/docs/test` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-31_0023_G4验收闭环.md` | 47 | `data/lib/docs/test` | `data/lib/docs/test` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-05-31_0023_G4验收闭环.md` | 50 | `/docs/handoff/...` | `/docs/handoff/` | 其他 |
| `docs/sessions/2026-05-31_0212_出版美术启动主菜单.md` | 48 | `lib/data/test/docs` | `lib/data/test/docs` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-09_2354_可玩性P1a与音频体检.md` | 37 | `data/proficiency.yaml` | `data/proficiency.yaml` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-06-13_半手动P0步骤5.md` | 66 | `test/sect` | `test/sect` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-14_1329_战斗交互重做.md` | 45 | `test/save_migration_021_test/sect` | `test/save_migration_021_test/sect` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-22_0030_门派谱1.1.md` | 48 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-06-28_1627_codex7分支合并.md` | 38 | `data/narratives/retreat/` | `data/narratives/retreat/` | 数据路径(疑移除/改名) |
| `docs/sessions/2026-07-06_night_视觉收口.md` | 11 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-07_1949_体检与codex批合并.md` | 16 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-07_2130_invalidate速修批3.md` | 19 | `lib/test` | `lib/test` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-15_1502_装备副本审查拍板.md` | 27 | `lib/data/test` | `lib/data/test` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-07-15_1640_装备副本文档编排批2.md` | 20 | `test/analyze` | `test/analyze` | 代码路径(疑重构/移走) |
| `docs/sessions/2026-08-04_1730_批B周目语义.md` | 49 | `test/analyze` | `test/analyze` | 代码路径(疑重构/移走) |
| `docs/spec/full_review_2026-07-18_followup_backlog.md` | 22 | `data/defs` | `data/defs` | 数据路径(疑移除/改名) |
| `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` | 103 | `test/master_disciple_battle_test` | `test/master_disciple_battle_test` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-06-09-playability-p1a-cultivation-core.md` | 983 | `data/proficiency.yaml` | `data/proficiency.yaml` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-06-29-next-stage-candidate-batch.md` | 11 | `data/manifest/prompt` | `data/manifest/prompt` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-06-29-night-tier2-sweep-preview.md` | 217 | `docs/progress` | `docs/progress` | 文档路径(疑移走/删除) |
| `docs/superpowers/plans/2026-06-29-night-ui-b4-qa-safety.md` | 8 | `/test/tooling/docs` | `/test/tooling/docs` | 其他 |
| `docs/superpowers/plans/2026-07-07-offline-settlement-loop.md` | 12 | `lib/build_runner` | `lib/build_runner` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-11-project-health-hardening.md` | 95 | `test/diagnostic` | `test/diagnostic` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md` | 762 | `/test/data` | `/test/data` | 其他 |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 28 | `lib/features/equipment/domain/enhancement_rules.dart` | `lib/features/equipment/domain/enhancement_rules.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 29 | `lib/features/equipment/domain/enhancement_aid.dart` | `lib/features/equipment/domain/enhancement_aid.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 30 | `lib/features/equipment/application/enhancement_context_provider.dart` | `lib/features/equipment/application/enhancement_context_provider.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 31 | `test/features/equipment/domain/enhancement_rules_test.dart.` | `test/features/equipment/domain/enhancement_rules_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 32 | `test/features/equipment/domain/enhancement_aid_test.dart.` | `test/features/equipment/domain/enhancement_aid_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 33 | `test/features/equipment/application/enhancement_atomic_service_test.dart.` | `test/features/equipment/application/enhancement_atomic_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 271 | `lib/features/equipment/domain/enhancement_rules.dart` | `lib/features/equipment/domain/enhancement_rules.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 272 | `test/features/equipment/domain/enhancement_rules_test.dart` | `test/features/equipment/domain/enhancement_rules_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 502 | `lib/features/equipment/domain/enhancement_aid.dart` | `lib/features/equipment/domain/enhancement_aid.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 503 | `test/features/equipment/domain/enhancement_aid_test.dart` | `test/features/equipment/domain/enhancement_aid_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 665 | `lib/features/equipment/application/equipment_service_providers.g.dart` | `lib/features/equipment/application/equipment_service_providers.g.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 666 | `test/features/equipment/application/enhancement_atomic_service_test.dart` | `test/features/equipment/application/enhancement_atomic_service_test.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 822 | `lib/features/equipment/domain/forging_slot_activity.dart` | `lib/features/equipment/domain/forging_slot_activity.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-15-equipment-aid-dismantle-enhancement.md` | 901 | `lib/features/equipment/application/enhancement_context_provider.dart` | `lib/features/equipment/application/enhancement_context_provider.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-17-gauntlet-battle-flow-wiring.md` | 15 | `lib/.g.dart` | `lib/.g.dart` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-18-kimi-stage-entry-flow-tests.md` | 41 | `data/shared/core/combat/support/audit/widget_test` | `data/shared/core/combat/support/audit/widget_test` | 数据路径(疑移除/改名) |
| `docs/superpowers/plans/2026-07-18-overnight-audit-batch.md` | 16 | `test/support//features/README` | `test/support//features/README` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-18-overnight-audit-batch.md` | 40 | `test/support/README` | `test/support/README` | 代码路径(疑重构/移走) |
| `docs/superpowers/plans/2026-07-19-kimi-test-quality.md` | 102 | `/data/journey_migration` | `/data/journey_migration` | 其他 |
| `docs/superpowers/plans/2026-07-21-kimi-redline-probe.md` | 59 | `lib/yaml` | `lib/yaml` | 代码路径(疑重构/移走) |

## 7. 局限声明

1. **行号漂移不验**:`file:line` 的 `line` 部分一律剥离,只验文件存在性(任务明确排除行号漂移)。
2. **生成物不入库**:`test/tools/output/*` 为测试运行生成产物,本不在 repo;列为死链但非文档失修。
3. **截图/图片多不入库**:`*.png` / `docs/screenshots/*` / `docs/handoff/*_visual_check_screenshots/` 多为本地截图未 commit;列示但非失修。
4. **多文件并列清单**:`；`/`、` 分隔的多文件清单只校验首个。
5. **大小写**:macOS 默认大小写不敏感,`os.path.exists` 按实路径判,大小写错配可能判存活(漏报)。本扫描未做大小写敏感复核。
6. **相对父目录路径(`../`)**:按「md 目录」与「repo 根」两基准解析;`../data/` 之类作者本意可能为 repo 根 `data/`,存在误判为死的风险(此类 23 条,列「相对父目录(边界)」)。
7. **裸文本路径未纳入主扫**:按任务定义,可能漏报;§6 为补充线索。
8. **sessions/ 与 superpowers/ 历史快照**:含大量历史路径提及,死链多为代码重构后的历史快照,非「文档互链失修」;读 §3/§4 时应结合 §2.1 子目录分布区分看待。
9. **围栏代码块不扫**:代码示例中的路径不入扫描(降低误报),但可能漏掉代码块内的真实引用。

## 8. 验收

- [x] REPORT_B1.md 落盘 worktree 根
- [x] 除报告外零改动(git status 干净)
- [x] 扫描范围 = docs/** 排除 _archive,共 1204 文件
- [x] 死链清单含 md 文件:行 / 引用原文 / 判定(§3)
- [x] 方法与局限声明(§1、§7)
- [x] 跳过类单独说明(§1.4、§5)
- [ ] git commit -m "[READY] B1 docs 死链扫描报告"(下一步)
