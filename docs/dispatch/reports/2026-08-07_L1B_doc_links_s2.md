# L1-B · docs/spec 路径失修修复报告(S2 分片)

- **执行端**:codebuddy(glm-5.2)
- **worktree**:`.claude/worktrees/cb-links-s2` · **分支**:`cb/doc-links-s2`
- **执行日期**:2026-08-07
- **性质**:文档路径修复,零代码改动、零测试改动
- **权威依据**:`docs/PATH_MIGRATION_MAP.md`(2026-08-07 主工作树实测)

## 一、处置计数总表

| 类别 | 处置 | 处数 | 说明 |
|---|---|---|---|
| A 类 · 文档互链 | 修(补日期后缀) | 2 | h1_onboarding_audit.md · m15_f1_steam_signup_guide.md |
| A 类 · 文档互链 | 标注(待创建) | 4 | docs/legal/{ai_disclosure,font_license,audio_license}.md(ai_disclosure ×2) |
| A 类 · 文档互链 | [BLOCKED] | 2 | docs/UX_GUIDELINES.md ×2(无同文档继承者) |
| A 类 · 文档互链 | 不动(模板占位符) | 3 | docs/spec/dispatch_templates/*.md 的 `[日期]-[任务名]` 占位 |
| B 类 · def/config 批映射 | 替换 | 15 | 见 §三详表,逐个 ls 验证通过 |
| C 类 · 无继承者 | 标注(已移除) | 9 | level_config ×3 · battle_action ×3 · pvp_service ×1 · pvp_sync_service ×1 · home_feed_screen ×1 |
| C 类 · 无继承者 | [BLOCKED] | 2 | paper_panel.dart 一拆二 · wuxia_paper_panel.dart 判不准继承者 |
| D 类 · 计划态/元说明/有效路径 | 不动 | — | 见 §六 |

**改动文件数**:13 个 md 文件,全部落在 `docs/spec/` 下。`git diff --stat`:29 insertions / 29 deletions(纯路径替换,对称)。

## 二、越界自检

```
$ git diff --name-only
docs/spec/2026-06-18-phase5-mainline3-loot-rumors-plan.md
docs/spec/2026-06-18-phase6-coop-break-window-plan.md
docs/spec/2026-06-24-b1-sect-event-game-loop-wiring-design.md
docs/spec/2026-06-24-b2-seclusion-equipment-drop-plan.md
docs/spec/2026-06-25-combat-tension-loop-plan.md
docs/spec/2026-06-25-taohua-island-phase1-plan.md
docs/spec/2026-06-26-equip-sell-decompose-inventory-plan.md
docs/spec/2026-06-27-taohua-island-zangjuange-design.md
docs/spec/h_polish_ux_spec_2026-05-29.md
docs/spec/m15_f_steam_spec_2026-05-29.md
docs/spec/m15_g_legal_spec_2026-05-29.md
docs/spec/p3_3_pvp_spec_2026-05-24.md
docs/spec/p4_1_q6a_encounter_recruit_spec_2026-05-25.md

$ git diff --name-only | grep -v "^docs/spec/"
(空=通过)
```

13 个改动文件全部落在 `docs/spec/` 下,无越界。

## 三、B 类新路径存在性自检(关键验收项)

B 类替换出的每个新路径逐个 `ls` 验证:

```
$ ls -1 lib/data/defs/tower_floor_def.dart lib/data/defs/seclusion_map_def.dart \
       lib/data/defs/encounter_def.dart lib/data/defs/taohua_island_config.dart \
       lib/core/domain/island_building_type.dart lib/core/domain/island_building_state.dart \
       lib/data/defs/injury_config.dart
lib/core/domain/island_building_state.dart
lib/core/domain/island_building_type.dart
lib/data/defs/encounter_def.dart
lib/data/defs/injury_config.dart
lib/data/defs/seclusion_map_def.dart
lib/data/defs/taohua_island_config.dart
lib/data/defs/tower_floor_def.dart
```

7 个目标路径全部存在(Exit 0)。**无一处替成同样不存在的路径**。

### B 类逐条详表

| # | 宿主文件 | 旧路径 | 新路径 | 处数 |
|---|---|---|---|---|
| B1 | `2026-06-18-phase5-mainline3-loot-rumors-plan.md` | `lib/features/tower/domain/tower_floor_def.dart` | `lib/data/defs/tower_floor_def.dart` | 1(:19) |
| B2 | `2026-06-24-b2-seclusion-equipment-drop-plan.md` | `lib/features/seclusion/domain/seclusion_map_def.dart` | `lib/data/defs/seclusion_map_def.dart` | 3(:19, :33, :119) |
| B3 | `p4_1_q6a_encounter_recruit_spec_2026-05-25.md` | `lib/features/encounter/domain/encounter_def.dart` | `lib/data/defs/encounter_def.dart` | 1(:36) |
| B4 | `2026-06-25-taohua-island-phase1-plan.md` + `2026-06-27-taohua-island-zangjuange-design.md` | `lib/features/taohua_island/domain/taohua_island_config.dart` | `lib/data/defs/taohua_island_config.dart` | 3(phase1-plan :22, :119;zangjuange-design :38) |
| B5 | `2026-06-25-taohua-island-phase1-plan.md` | `lib/features/taohua_island/domain/island_building_type.dart` | `lib/core/domain/island_building_type.dart`(例外,去 core 不去 defs) | 2(:21, :119) |
| B6 | `2026-06-25-taohua-island-phase1-plan.md` | `lib/features/taohua_island/domain/island_building_state.dart` | `lib/core/domain/island_building_state.dart`(例外,去 core 不去 defs) | 2(:23, :295) |
| B7 | `2026-06-25-combat-tension-loop-plan.md` | `lib/features/injury/domain/injury_config.dart` | `lib/data/defs/injury_config.dart` | 3(:43, :99, :176) |

合计 15 处替换。

**B 类例外确认**:`lib/features/taohua_island/domain/island_building_{type,state}.dart` 按 PATH_MIGRATION_MAP.md §三明确指向 `lib/core/domain/`(不是 `lib/data/defs/`),已正确遵循。

**未替换的 package: 形式 import**:`2026-06-25-taohua-island-phase1-plan.md:126-127, 301` 有 `import 'package:wuxia_idle/features/taohua_island/domain/...'` 形式的 import 语句。这些是 spec 代码示例里的 import,属计划态代码示例(§〇 计划与实现自然漂移),未追改。详见 §六 D 类。

## 四、幂等自检

```
$ grep -rn "(待创建)(待创建)" docs/spec/
(空=通过)

$ grep -rn "(已移除)(已移除)" docs/spec/
(空=通过)
```

标注类无任何文件被插两次。`(待创建)` 计数 4(均在 m15_g_legal_spec),`(已移除)` 计数 9(level_config 3 + pvp 2 + home_feed 1 + battle_action 3),与处置计数一致。

## 五、A 类详表

| # | 宿主文件:行 | 旧引用 | 处置 | 目标存在性 |
|---|---|---|---|---|
| A1 | `h_polish_ux_spec_2026-05-29.md:38` | `docs/handoff/h1_onboarding_audit.md` | 改 → `docs/handoff/h1_onboarding_audit_2026-05-29.md`(补日期后缀) | 目标存在 |
| A2 | `m15_f_steam_spec_2026-05-29.md:71` | `docs/handoff/m15_f1_steam_signup_guide.md` | 改 → `docs/handoff/m15_f1_steam_signup_guide_2026-05-29.md`(补日期后缀) | 目标存在 |
| A3 | `h_polish_ux_spec_2026-05-29.md:30, :61` | `docs/UX_GUIDELINES.md` | **[BLOCKED]** 见 §七.1 | 不存在,最近似 `docs/UI_TERMINOLOGY.md` 但非同一文档 |
| A4 | `m15_g_legal_spec_2026-05-29.md:41, :47, :49, :69` | `docs/legal/{ai_disclosure,font_license,audio_license}.md` | 标注 `(待创建)` 保留引用(待办非失修) | `docs/legal/` 整目录不存在 |
| A5 | `docs/spec/dispatch_templates/*.md` ×3 | `docs/superpowers/plans/[日期]-[任务名].md` | 不动(模板占位符) | N/A |

## 六、D 类记录(不动)

下列引用经评估属"计划态预告 / 元说明 / 有效路径",按派单 §〇 不追改:

1. **camera_shake.dart Create 语境**(2026-06-18-phase5-mainline2-batch24-impact-feel-plan.md:27, :607, :733, :739):plan 写 `Create: lib/features/battle/presentation/camera_shake.dart`。PATH_MIGRATION §五列该文件已删,但 plan 是 Create 语境(计划态预告),不标(已移除)。
2. **data/proficiency.yaml**(2026-06-09-playability-p1a-cultivation-core-design.md:39;playability_upgrade_master_spec_2026-06-09.md:557):spec 标"(新)"或章节标题描述 yaml 草稿,属计划态预告。
3. **data/ranks.yaml 元说明**(2026-08-01-tower-extension-design.md:68):原文本身在说明"`data/ranks.yaml` 不存在,境界实配在 `numbers.yaml realms.tiers`",加标注会破坏元说明语义。
4. **data/lore/pvp/ 新目录**(p3_3_pvp_spec_2026-05-24.md:27, :114, :117, :137, :147):spec 标"新目录""新增""Phase 5 计划写满 8-12 条",全为计划态预告。
5. **data/narratives/techniques/ 元说明**(full_review_2026-07-02_followup_backlog.md:20):原文描述"已归档,26 篇迁至 `data/narratives/_archive/techniques/`",引用是历史说明,不动。
6. **battle/presentation/widgets/ 有效路径**(2026-08-01-battle-ui-sample-fidelity-95-repair-report.md:348, :413, :414):`lib/features/battle/presentation/widgets/` 目录**仍存在**(battle_banners.dart / battle_bottom_bar.dart / battle_skill_slip.dart 仍在该目录),仅 character_avatar.dart 搬到上层。这 3 处引用是有效路径,不动。
7. **package: 形式 import**(2026-06-25-taohua-island-phase1-plan.md:126, :127, :301):spec 代码示例的 import 语句,属计划态代码示例漂移,不追改。
8. **裸文件名引用**(多处):如 `level_config.dart:39-40`、`battle_action.dart`(无完整路径)、`home_feed_screen.dart`(无完整路径)等,无完整路径,无法判定迁移目标,不动。
9. **lib/features/*/domain/ 非 def/config 文件**(battle_state, battle_ai, damage_calculator, enum_localizations, battle_log, derived_stats, strategy/*, auto_play_mode, top_damage_contributor 等):这些文件仍在 `lib/features/battle/domain/` 下(PATH_MIGRATION §三确认),路径未变,不动。
10. **test/* 计划态路径**(约 100+ 条):spec 是计划态文档,预告的测试文件名落地时常改名,按派单 §D 不动。

## 七、[BLOCKED] 节(附证据)

### 7.1 `docs/UX_GUIDELINES.md`(A3)

- **宿主**:`docs/spec/h_polish_ux_spec_2026-05-29.md:30, :61`
- **原文**:
  - :30 `| H-Q4 | UX 体例统一规范:本批补 \`docs/UX_GUIDELINES.md\` 还是不补? | **补 1 份 ≤80 行**(...) |`
  - :61 `- **H5.6**:\`docs/UX_GUIDELINES.md\` 起草(若 H-Q4 拍是)`
- **证据**:`ls docs/UX_GUIDELINES.md` → 不存在。`ls docs/UI_TERMINOLOGY.md` → 存在。但派单明确指示:UI_TERMINOLOGY.md 不是同一文档,不要猜。
- **判断**:该 spec 是在讨论"是否要新建 UX_GUIDELINES.md",这是待决项(若 H-Q4 拍是才起草)。引用本身是计划态预告,且继承者判不准。
- **处置**:保留原样,不标(待创建)也不改路径。理由:spec 文字本身在讨论"补还是不补",加标注会破坏待决语境。

### 7.2 `lib/shared/widgets/wuxia_ui/paper_panel.dart`(C 类特例)

- **宿主**:`docs/spec/2026-06-22-p4-martial-codex-plan.md:1053`
- **原文**:`import '../../../shared/widgets/wuxia_ui/paper_panel.dart';`(武学详情屏 import 语句)
- **证据**:
  ```
  $ ls lib/shared/widgets/wuxia_ui/paper_panel.dart
  ls: No such file or directory
  $ ls lib/shared/widgets/wuxia_ui/light_paper_panel.dart lib/shared/widgets/wuxia_ui/panel_surface.dart
  lib/shared/widgets/wuxia_ui/light_paper_panel.dart
  lib/shared/widgets/wuxia_ui/panel_surface.dart
  ```
- **判断**:PATH_MIGRATION_MAP.md §四明确:"一拆二,按上下文选"。该 import 在武学详情屏代码示例里,无法确定该用 light_paper_panel.dart 还是 panel_surface.dart(取决于该屏用的是轻量纸面板还是面板基底)。
- **处置**:[BLOCKED],保留原样。需人工根据武学详情屏实际实现定夺。

### 7.3 `lib/shared/widgets/wuxia_paper_panel.dart`(C 类)

- **宿主**:`docs/spec/2026-06-26-equip-slot-dialog-redesign-plan.md:346`
- **原文**:`import '../../../shared/widgets/wuxia_paper_panel.dart';`(装备槽对话框 redesign 代码示例)
- **证据**:`ls lib/shared/widgets/wuxia_paper_panel.dart` → 不存在。该文件名与 paper_panel.dart 相近但不同,不在 PATH_MIGRATION 的"一拆二"明确列表里。
- **判断**:文件不存在,但无法确定继承者。可能是 paper_panel.dart 一拆二的某个别名,也可能是独立删除的文件。
- **处置**:[BLOCKED],保留原样。需人工核实该 import 在历史中指向哪个文件。

## 八、方法论说明

### 8.1 替换工具

按派单 §三要求,统一使用 `perl -CSD -i -pe 'use utf8; ...'`:
- `-CSD`:强制 STDIN/STDOUT/STDERR 为 UTF-8
- `use utf8`:让 perl 把 `-e` 脚本字面量当 UTF-8 解码(解决中文标注乱码问题,实测必须加)
- 分隔符 `{}`:路径含 `/`、md 表格含 `|`
- `\Q...\E` 包 pattern:防止 `.` 匹配任意字符
- 否定前瞻 `(?!\(待创建\))` / `(?!\(已移除\))`:加标注类防双标,保证幂等

### 8.2 判定原则

- **现在式引用**(plan 的 Modify/引用现有文件)+ 文件不存在 → C 类标(已移除)
- **计划态预告**(spec 的"新""新建""Create""Phase N 计划")+ 文件不存在 → D 类不动
- **元说明**(原文本身在说明文件不存在)→ D 类不动
- **有效路径**(文件实际存在,只是路径模式看着像旧路径)→ D 类不动
- **判不准继承者** → [BLOCKED]

### 8.3 关键陷阱规避

1. **`lib/features/battle/presentation/widgets/` 陷阱**:PATH_MIGRATION §二说该目录"去掉 widgets/ 一层",但实测该目录**仍存在**(仅 character_avatar.dart 搬到上层,battle_banners/bottom_bar/skill_slip 仍在 widgets/ 下)。若套通配规则会误改有效路径。本单逐个 ls 验证,3 处 widgets/ 引用判定为有效路径,不动。
2. **`level_config.dart` 陷阱**:lib/data/defs/ 没有 level_config.dart(PATH_MIGRATION §五说 lib/features/level/ 整个已删)。若套"B 类批映射"规则会替成不存在的路径。本单 ls 验证后转 C 类标注(已移除)。
3. **taohua_island 例外**:island_building_{type,state}.dart 去 `lib/core/domain/` 不是 `lib/data/defs/`,按 PATH_MIGRATION §三明确指示处理。

## 九、交付状态

- [x] 三类分别给处置计数
- [x] 新路径存在性自检(B 类 7 个新路径 ls 通过,贴 §三)
- [x] 越界自检(git diff --name-only 全在 docs/spec/,贴 §二)
- [x] 幂等自检(标注类无双标,贴 §四)
- [x] 报告落盘 `docs/dispatch/reports/2026-08-07_L1B_doc_links_s2.md`
- [ ] 分支 tip commit message 以 `[READY]` 开头,工作区干净(下一步执行)
