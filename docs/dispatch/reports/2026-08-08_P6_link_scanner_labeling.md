# P6 · 死链扫描器真实语料标注验证报告

> 日期:2026-08-08 · 执行:pi(分支 `pi/p6-link-label-0808`)· 派单:2026-08-08 夜批 P6
> 对象:`tools/doc_link_scan.py`(958 死链 / 5907 存活 / 575 ignored / 432 跳过,932 个 md)
> 目的:补上「真实语料 precision/recall 未测」这一证据缺口。**本单只体检不改工具。**

## 一、抽样方法

- **总体**:扫描器 JSON 输出的全部条目(dead 958 / alive 5907 / ignored 575)。alive 明细由独立脚本 import 扫描器采集函数复算(结果与扫描器汇总完全一致,7440 条无偏差)。
- **方法**:分层随机抽样,`random.Random(20260808)` 固定种子,各层内按 kind(backtick/mdlink)再细分(dead 取 8 mdlink+32 backtick;alive 取 6 mdlink+34 backtick;ignored 取 5+5),共 **90 条**。
- **构成**:dead 40 / alive 40 / ignored 10;backtick 71 / mdlink 19。抽中后打乱编号 S00–S89。
- **可复现**:种子 + 本报告完整标注表即全部抽样结果;复跑命令 `python3 tools/doc_link_scan.py --json` 后按上述层配比重抽即可(抽样脚本未入仓,层配比+种子即完整复现参数)。

## 二、独立标注方法(核心防自证循环)

对每条样本**不用扫描器判定**,直接对目标路径跑原始 git 三查:

1. `git ls-files` 精确命中或「是某已跟踪文件的父目录」→ 存活
2. 未命中 → `git check-ignore` 命中 → ignored
3. 均未命中 → 死链

另做四项独立核验:

- **相对路径解析**:样本中 3 条 `../` 引用(如 `[`CLAUDE.md`](../../CLAUDE.md)`)人工从源文件目录解析,与扫描器规范化结果全部一致。
- **锚点**:扫描范围内 `file.md#section` 型引用全仓为 **0**(纯锚点 `](#x)` 仅在 `docs/_archive/` 出现,已被排除)——锚点验证在本仓无从测起(空操作)。
- **行号**:alive 池 395 条 `:数字` 行号引用,抽查全量后**无一行号越界**(全部 ≤ 文件行数)。
- **大小写**:dead 池全量大小写不敏感比对 tracked,**0 条**可命中。
- **工作树状态**:本 worktree 干净 ⇒ 磁盘文件要么 tracked 要么 gitignored,git 三查即完备判据。

## 三、完整标注表(90 条)

| # | 引用出处 | 目标(规范化后) | 扫描器 | 人工 | 一致 |
|---|---|---|---|---|---|
| S00 | `docs/handoff/pen_visual_verify_r3_consolidated_2026-05-28.md`:9 | `docs/handoff/r3_visual_check_screenshots` | dead | dead | ✓ |
| S01 | `docs/handoff/week14_1_encounter_vertical_slice_2026-05-14.md`:82 | `test/services/encounter_service_test.dart` | dead | dead | ✓ |
| S02 | `docs/handoff/week14_full_closeout_2026-05-15.md`:3 | `lib/data/models` | dead | dead | ✓ |
| S03 | `docs/audit/cross_system_damage_audit_2026-05-25.md`:5 | `docs/handoff/stage_audit_1_0_overall_2026-05-24.md` | alive | alive | ✓ |
| S04 | `docs/superpowers/plans/2026-07-13-character-attribute-roles.md`:82 | `test/features/injury/application/injury_service_test.…` | alive | alive | ✓ |
| S05 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`:41 | `docs/screenshots/w14_3c_dialog_outcome_crossfade.png` | ignored | ignored | ✓ |
| S06 | `docs/dispatch/2026-08-07_R1_l1d_rawtarget_fix.md`:40 | `docs/nope.md` | dead | dead | ✓ |
| S07 | `docs/spec/2026-06-23-battle-pacing-readability-plan.md`:31 | `test/features/battle/battle_advance_one_action_test.dart` | alive | alive | ✓ |
| S08 | `docs/handoff/week15_30_phase2_consumption_layer_2026-05-16.md`:33 | `lib/core/domain/character.g.dart` | ignored | ignored | ✓ |
| S09 | `docs/handoff/h1_polish_candidates_2026-05-29.md`:8 | `lib/shared/strings.dart` | alive | alive | ✓ |
| S10 | `docs/audio_asset_generation_guide.md`:155 | `assets/audio/sfx/styleAgileCrit.mp3` | dead | dead | ✓ |
| S11 | `docs/handoff/week15_phase5_3_lib_core_extract_2026-05-16.md`:167 | `data/models` | dead | dead | ✓ |
| S12 | `docs/audit/long_term_balance_audit_2026-07-01.md`:63 | `docs/audit/主力12关` | dead | dead | ✓ |
| S13 | `docs/superpowers/plans/2026-07-19-battle-ui-v2-85-fidelity-implementation.md`:97 | `lib/features/battle/presentation/battle_scene_backgro…` | alive | alive | ✓ |
| S14 | `docs/superpowers/plans/2026-06-09-p0-manual-boss-break.md`:33 | `test/features/battle/p0_charge_break_test.dart` | alive | alive | ✓ |
| S15 | `docs/superpowers/plans/2026-06-10-cangjingge-skill-loadout.md`:130 | `lib/data/numbers.yaml` | dead | dead | ✓ |
| S16 | `docs/superpowers/plans/2026-07-14-progression-release-cap-100.md`:200 | `test/features/inventory/item_use_service_test.dart` | alive | alive | ✓ |
| S17 | `docs/superpowers/plans/2026-07-19-assets-zero-reference-rescan.md`:33 | `lib` | alive | alive | ✓ |
| S18 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md`:17 | `docs/handoff/codex_team_lineup_visual_2026-07-15/03_s…` | ignored | ignored | ✓ |
| S19 | `docs/superpowers/specs/2026-05-31-visual-capture-infra-design.md`:170 | `tools/visual_capture/visual_capture.sh` | alive | alive | ✓ |
| S20 | `docs/handoff/week14_full_closeout_2026-05-15.md`:59 | `lib/ui/encounter/encounter_dialog.dart` | dead | dead | ✓ |
| S21 | `docs/superpowers/plans/2026-07-10-ui-reliability.md`:27 | `test/shared/widgets/wuxia_image_fallback_audit_test.dart` | alive | alive | ✓ |
| S22 | `docs/superpowers/plans/2026-07-19-assets-zero-reference-rescan.md`:57 | `assets/enemies/xiliang_b.png` | dead | dead | ✓ |
| S23 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md`:33 | `lib/data/models/enums.dart` | dead | dead | ✓ |
| S24 | `docs/superpowers/plans/2026-07-15-baicao-duanhun-joint-economy-probe.md`:30 | `test/tools/joint_economy_probe_test.dart` | alive | alive | ✓ |
| S25 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md`:17 | `docs/handoff/codex_team_lineup_visual_2026-07-15/02_s…` | ignored | ignored | ✓ |
| S26 | `docs/superpowers/plans/2026-06-09-audio-system.md`:35 | `lib/shared/widgets/wuxia_ink_button.dart` | alive | alive | ✓ |
| S27 | `docs/handoff/p2_x_inner_demon_phase0_reality_check_2026-05-22.md`:59 | `docs/handoff/p3_x_inner_demon_spec_2026-05-22.md` | dead | dead | ✓ |
| S28 | `docs/handoff/stage_audit_2026-05-24.md`:4 | `docs/handoff/stage_audit_2026-05-22.md` | alive | alive | ✓ |
| S29 | `docs/handoff/week15_phase5_3_battle_features_2026-05-16.md`:253 | `lib/combat` | dead | dead | ✓ |
| S30 | `docs/audit/yaml_integrity_2026-05-12.md`:41 | `data/narratives/mainline_test_02.yaml` | dead | dead | ✓ |
| S31 | `docs/handoff/week13_codex_visual_check_closeout_2026-05-14.md`:3 | `lib/providers` | dead | dead | ✓ |
| S32 | `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md`:37 | `lib/features/codex/presentation/codex_entry_detail.dart` | alive | alive | ✓ |
| S33 | `docs/spec/p4_1_q6b_stage_boss_recruit_spec_2026-05-26.md`:124 | `CLAUDE.md` | alive | alive | ✓ |
| S34 | `docs/superpowers/plans/2026-07-19-assets-zero-reference-rescan.md`:12 | `data` | alive | alive | ✓ |
| S35 | `docs/handoff/p5_ui_polish_closeout_2026-05-24.md`:48 | `CLAUDE.md` | alive | alive | ✓ |
| S36 | `docs/audit/stage_review_2026-08-01.md`:18 | `test` | alive | alive | ✓ |
| S37 | `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md`:37 | `lib/features/sect/presentation/sect_screen.dart:_Memb…` | dead | alive | ✗ |
| S38 | `docs/superpowers/plans/2026-07-19-ch78-standee-calibration.md`:110 | `build` | dead | ignored | ✗ |
| S39 | `docs/handoff/codex_break_feel_20260610_170446.md`:54 | `docs/handoff/visual_capture_4d370db0_20260610_170843/…` | ignored | ignored | ✓ |
| S40 | `docs/sessions/2026-06-17_help_system_phase123.md`:9 | `docs/spec/contextual_help_system_spec_2026-06-16.md` | alive | alive | ✓ |
| S41 | `docs/handoff/week15_phase5_3_isar_provider_split_2026-05-16.md`:146 | `lib/ui` | dead | dead | ✓ |
| S42 | `docs/handoff/codex_main_menu_second_pass_2026-06-06.md`:23 | `docs/handoff/codex_main_menu_second_pass_2026-06-06/0…` | ignored | ignored | ✓ |
| S43 | `docs/spec/2026-06-21-p4-material-economy-p2-plan.md`:21 | `data/items.yaml` | alive | alive | ✓ |
| S44 | `docs/audit/long_term_balance_audit_2026-07-01.md`:63 | `docs/audit/终局` | dead | dead | ✓ |
| S45 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`:112 | `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md` | alive | alive | ✓ |
| S46 | `docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md`:255 | `test/features/seclusion/application/seclusion_drop_te…` | alive | alive | ✓ |
| S47 | `docs/handoff/week15_full_closeout_2026-05-15.md`:3 | `lib/ui` | dead | dead | ✓ |
| S48 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md`:67 | `test/features/seclusion/seclusion_service_test.dart` | dead | dead | ✓ |
| S49 | `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md`:50 | `lib/data/defs/stage_def.dart` | alive | alive | ✓ |
| S50 | `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md`:3 | `lib/services` | dead | dead | ✓ |
| S51 | `docs/dispatch/2026-08-07_R1_l1d_rawtarget_fix.md`:41 | `assets/x.png` | dead | dead | ✓ |
| S52 | `docs/superpowers/plans/2026-06-09-playability-p1a-cultivation-core.md`:33 | `data/skills.yaml` | alive | alive | ✓ |
| S53 | `docs/spec/2026-06-25-taohua-island-phase1-plan.md`:253 | `lib/data/game_repository.dart` | alive | alive | ✓ |
| S54 | `docs/superpowers/plans/2026-07-13-realm-derived-490-level.md`:676 | `test/data/character_level_repair_test.dart` | dead | dead | ✓ |
| S55 | `docs/handoff/p1_42_phase2_p1y_bubble_hint_spec.md`:88 | `lib/features/tutorial/application/tutorial_service.dart` | alive | alive | ✓ |
| S56 | `docs/audit/expedition_cycle_numbers_probe_2026-08-05.md`:41 | `docs/audit/27h/54h` | dead | dead | ✓ |
| S57 | `docs/handoff/wuxia_idle_ui_gap_guidance_2026-06-02.md`:94 | `lib/features/battle/domain/battle_state.dart` | alive | alive | ✓ |
| S58 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md`:26 | `docs/handoff/codex_team_lineup_visual_2026-07-15/12_h…` | ignored | ignored | ✓ |
| S59 | `docs/superpowers/plans/2026-08-01-battle-ui-sample-fidelity-95.md`:147 | `lib/features/battle/presentation/widgets/battlefield.…` | dead | dead | ✓ |
| S60 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md`:16 | `docs/handoff/codex_team_lineup_visual_2026-07-15/01_b…` | ignored | ignored | ✓ |
| S61 | `docs/handoff/codex_dispatch_p5_p3_visual_check_2026-05-24.md`:60 | `CLAUDE.md` | alive | alive | ✓ |
| S62 | `docs/handoff/codex_b3b5_break_defeat_reverify_2026-06-10.md`:53 | `docs/handoff/visual_capture_38964c01_20260610_111903/…` | ignored | ignored | ✓ |
| S63 | `docs/spec/2026-07-15-battle-stage-command-desk-design.md`:10 | `docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png` | alive | alive | ✓ |
| S64 | `docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md`:119 | `test/jianghu` | dead | dead | ✓ |
| S65 | `docs/handoff/deepseek_w16_festival_dispatch_2026-05-16.md`:120 | `data/events/chong_yang_deng_gao.yaml` | alive | alive | ✓ |
| S66 | `docs/superpowers/plans/2026-06-27-taohua-island-phase2-foundation.md`:29 | `lib/features/taohua_island/domain/island_building_typ…` | dead | dead | ✓ |
| S67 | `docs/handoff/week9_a_audit_closeout_2026-05-13.md`:38 | `lib/ui/tower/tower_floor_list_screen.dart` | dead | dead | ✓ |
| S68 | `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`:69 | `lib/features/battle/domain/battle_engine.dart` | dead | dead | ✓ |
| S69 | `docs/dispatch/2026-08-07_L1D.md`:23 | `docs/dispatch/path` | dead | dead | ✓ |
| S70 | `docs/superpowers/plans/2026-07-01-floor30-guardian-ward.md`:413 | `test/features/tower/floor30_guardian_ward_config_test…` | dead | dead | ✓ |
| S71 | `docs/dispatch/2026-08-07_R1_l1d_rawtarget_fix.md`:39 | `docs/GDD.md` | dead | dead | ✓ |
| S72 | `docs/spec/2026-06-18-phase5-mainline2-batch24-impact-feel-plan.md`:22 | `data/numbers.yaml` | alive | alive | ✓ |
| S73 | `docs/handoff/art_assets_integration_spec_2026-05-20.md`:201 | `lib/features/seclusion/domain/seclusion_map_def.dart` | dead | dead | ✓ |
| S74 | `docs/audit/long_term_balance_audit_2026-07-01.md`:63 | `docs/audit/学徒` | dead | dead | ✓ |
| S75 | `docs/spec/2026-06-19-phase7-batch2-boss-mechanics-plan.md`:325 | `lib/features/loot_preview` | alive | alive | ✓ |
| S76 | `docs/dispatch/2026-08-07_L1B.md`:9 | `lib/providers` | dead | dead | ✓ |
| S77 | `docs/handoff/ch12_art_delivery_report_2026-07-22.md`:17 | `assets/scenes/narrative_stage_12_05.png` | alive | alive | ✓ |
| S78 | `docs/handoff/art_assets_integration_closeout_2026-05-20.md`:73 | `lib/features/home_feed/presentation/home_feed_screen.…` | dead | dead | ✓ |
| S79 | `docs/handoff/p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md`:7 | `docs/handoff/p1_x_chapter4_phase0_reality_check_2026-…` | alive | alive | ✓ |
| S80 | `docs/spec/2026-06-22-p4-encounter-codex-plan.md`:48 | `test/features/baike/application/encounter_codex_provi…` | alive | alive | ✓ |
| S81 | `docs/handoff/wuxia_navigator_observer_mock_pattern_2026-05-17.md`:133 | `test` | alive | alive | ✓ |
| S82 | `docs/spec/2026-06-24-forging-lifesteal-pierce-plan.md`:129 | `lib/features/battle/domain/battle_state.dart` | alive | alive | ✓ |
| S83 | `docs/handoff/week15_30_phase3_advancement_2026-05-16.md`:57 | `lib/features/seclusion/application/seclusion_service.…` | alive | alive | ✓ |
| S84 | `docs/handoff/p2_3_ascension_closeout_2026-05-24.md`:37 | `test/features/character_panel/presentation/lineage_pa…` | dead | dead | ✓ |
| S85 | `docs/superpowers/plans/2026-06-05-ui-kit-v1.md`:1565 | `docs/handoff` | alive | alive | ✓ |
| S86 | `docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md`:264 | `test/data/technique_qi_profile_test.dart` | alive | alive | ✓ |
| S87 | `docs/spec/2026-06-21-p4-material-economy-p1-plan.md`:241 | `test/features/main_menu/main_menu_test.dart` | dead | dead | ✓ |
| S88 | `docs/handoff/week15_phase5_3_batch2_features_2026-05-15.md`:100 | `lib/ui/main_menu.dart` | dead | dead | ✓ |
| S89 | `docs/handoff/codex_team_lineup_visual_2026-07-15/report.md`:21 | `docs/handoff/codex_team_lineup_visual_2026-07-15/01_b…` | ignored | ignored | ✓ |
## 四、混淆矩阵与指标

以「死链」为正类:

| 扫描器＼人工 | 死链 | 存活 | ignored |
|---|---|---|---|
| **死链** | **38 (TP)** | 1 (FP) | 1 (FP) |
| **存活** | 0 (FN) | **40 (TN)** | 0 |
| **ignored** | 0 | 0 | **10** |

- **precision(死链)= TP/(TP+FP) = 38/40 = 95.0%**
- **recall(死链)= TP/(TP+FN) = 38/38 = 100%**
- 90 条中 88 条一致(97.8%)

**全池扫描(非抽样)补查结果**:对 958 条死链全量扫了「尾斜杠目录引用」「`:符号`后缀」「大小写」「mdlink 目标在 tracked」四类可疑形态,对 5907 条存活全量扫了「行号越界」「锚点」——除下述两处系统性 FP 外无其他类别;据此估计**全池死链 precision ≈ 930/958 ≈ 97.1%**。

## 五、FP/FN 逐条根因

### FP ×2(样本内,各代表一类系统性 bug)

| 条目 | 出处 | 目标 | 扫描器 | 人工 | 根因 |
|---|---|---|---|---|---|
| **S37** | `docs/superpowers/specs/2026-05-31-sect-portrait-wiring-design.md:37` | `lib/features/sect/presentation/sect_screen.dart:_MemberRow` | 死链 | 存活 | 基底文件 `sect_screen.dart` 真实存在(tracked);`:_MemberRow` 是符号后缀。清洗层只剥 `:数字` 行号(`file.dart:39` 能正确判活,如 S09),**不剥 `:Symbol`** → 整串当路径判死 |
| **S38** | `docs/superpowers/plans/2026-07-19-ch78-standee-calibration.md:110` | `build/visual_acceptance/ch78_standee_calibration/` | 死链 | ignored | 目标在 gitignore 的 `build/` 目录内(文档原文自陈「ignored build/…」);规范化剥掉尾斜杠后 feed `git check-ignore`,git 对**目录型模式**(`build/`、`visual_capture_*/` 等)要求查询路径带尾斜杠(或磁盘上确为目录)才命中 → 误判死链 |

### 两 bug 的全池影响(已全量量化)

**Bug A — 裸目录引用 + 目录型 gitignore 模式失效:22 条**(dead 池 958 条中)

- 全部为 `raw` 以 `/` 结尾、目标为 gitignored 目录的引用:`build/…` 9 条、`docs/handoff/visual_capture_*/…` 11 条、`assets/audio/_suno_candidates/` 2 条。
- 其中 **9 条(`build/` 型)随工作树漂移**:同一仓库在主 checkout(磁盘有 `build/`)跑 `check-ignore` 裸路径会命中 → 判 ignored;在本 worktree(无 `build/`)不命中 → 判死链。**违反工具自身设计目标「与工作树状态解耦,任何地方跑结果一致」**(`tools/doc_link_scan.py` 头注释自述)。
- 另 13 条(`visual_capture_*` 等,两处磁盘都不存在)两处一致判死链——判定错误但输出稳定。
- 修复方向(未执行):规范化时保留尾斜杠,或 check-ignore 前按原始 raw 补回 `/`。

**Bug B — `:Symbol`/`:行号+内容` 后缀不剥:6 条**

- 全部基底文件 tracked:`data/numbers.yaml:130 combined_rate_cap: 0.95`、`data/numbers.yaml:206 max_absolute_realm_level: 10/17`、`master_builder.dart:buildMasterCharacter`、`sect_screen.dart:_MemberRow`、`sect_recruit_confirm_dialog.dart:_CandidateInfo`。
- 根因同 S37:清洗层 `:数字` 行号正则要求**锚定结尾**,这些后缀后面还有内容 → 不剥 → 整串判死。
- 修复方向(未执行):对 `:` 后缀先剥文件扩展名后的任意 `:…` 再判存在性。

### FN = 0

存活类判定是「tracked 精确匹配 + 目录前缀」,结构上无假阴性路径;alive 层 40 条全数人工复核一致。全池补查亦未发现其他 FN 形态(行号越界 0、锚点引用 0、大小写 0)。

## 六、语义层发现(不计入混淆矩阵,但决定「能不能当修链清单」)

分类正确 ≠ 列表可用。死链池存在两类语义噪声:

1. **mdlink 散文伪链接**:17 条 dead mdlink 中,**10 条是散文**——`[5,10](学徒)`、`[15,30](27h/54h)`、`[200,280](终局)`、`[24,72](离线可达人剑合一,不秒解锁)` 等,作者用 markdown 链接语法做强调,非路径意图;**6 条是夹具**——`[x](docs/nope.md)`、`[alt](path)` 等,来自扫描器自身的测试文档(`docs/dispatch/2026-08-07_R1_l1d_rawtarget_fix.md` / `L1D.md` / `B1_codebuddy_doc_links.md` / `STOP_SNAPSHOT.md`);仅 `[说明](docs/GDD.md)` 1 条是真实死链(真文件在 repo 根,引用写错位置)。**分类上它们全是「正确死链」(目标确实不存在),语义上 94% 是噪声。**
2. **来源集中在低修链价值目录**:dead 池 602/958(63%)来自 `docs/handoff/`(历史 closeout),64 条来自 `docs/dispatch/`(旧路径迁移文档 + 夹具)。拿 958 条直接当修复清单会大量空转。

## 七、结论:能不能升级为「终审事实源」?

**分两个层面回答:**

- **作为「死链分类底账」(哪些引用目标在 git 中不存在):可以升级。** precision 95%(样本)/≈97%(全池估计)、recall 100%,两个 FP 类别共 28 条(2.9%)全部可枚举、可解释、修复方向明确且改动极小。修掉 Bug A/B 后预计 precision >99%。
- **作为「终审修复清单」(哪些引用该修):暂不能。** 语义噪声(散文伪链接、夹具、handoff/dispatch 历史文档)未过滤,mdlink 死链里真实可修的不到 1/17;且 Bug A 的 9 条输出随工作树漂移,违反工具自身「任何地方跑结果一致」的设计承诺。

**建议升级路径(供协调者/用户拍板,本单不执行)**:①修 Bug A(尾斜杠保留)与 Bug B(`:符号` 后缀剥离),各 1 行级改动;②mdlink 加「非路径形态」启发式(如含 CJK/数字区间/无扩展名)→ 归入跳过类;③对 `docs/dispatch/` 自述夹具与 `docs/handoff/` 做范围或标注决策;④完成后将 `tools/README.md` 定位从「可试用·非终审事实源」改为「分类层已验证」,并注明语义噪声限制。

## 八、未解决问题 / 局限

- **锚点验证空操作**:扫描范围内 `file.md#section` 引用为 0,section 存在性判定无真实语料可测(纯锚点 `](#x)` 全在 `_archive/`)。若未来出现带锚点引用,需补验。
- **跳过类(432 条)未标注**:通配/模板占位/`@hex` 等跳过规则合理,但本单未逐条验证(派单范围只含死链/存活/ignored 三类的 precision/recall)。
- **行号/字段后缀语义**:`file.yaml:行号`、`file.yaml.field` 只验证文件存在,不验证行/字段真实存在(本仓 395 条行号引用均未越界,字段未验)。
- **git 内部细节**:Bug A 的触发条件(裸路径查询 vs 目录型模式)经实测确认,但 git 对「中间组件目录判定」存在深浅差异(`docs/demos/` 模式在父目录删除后仍能命中,`build` 裸路径则不能),修复建议以「保留尾斜杠查询」为稳妥做法,勿依赖 git 的组件猜测逻辑。
- **主 checkout 对照**:主 checkout(`~/Desktop/Projects/挂机武侠`)对 22 条中 9 条裸查询命中,实测证实输出漂移,已计入 Bug A 影响面。

---
*本报告为 P6 派单唯一交付物;扫描器与 README 定位均未改动;未 push,未碰 main。*
