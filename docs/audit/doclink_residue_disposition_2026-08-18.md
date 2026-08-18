# 死链残余 71 条处置台账(N2)

> 日期:2026-08-18(夜批)
> 状态:`RESIDUE_ACCEPTED_WITH_LEDGER`
> 分支:`fix/doclink-residue-0818`
> 上位:08-15 死链修复批(`368→278`)/ 08-18 扫描器重评+Bug C 修(`373→87`)/
> 08-18 修复批(`87→71`);本台账把 08-18 的「残余定性」从口头结论升级为
> 逐条实证账。

## 1. 本批动作

基线重扫 **dead 71**(与 08-18 收账数字逐值吻合,证明后续 5 个文档批零新增死链)。
逐条实证后处置:

| 处置 | 条数 | 内容 |
|---|---:|---|
| C 类机械修 | 6 | 见 §2 |
| 修复后残余 | **65** | B/D 类接受,逐条定性见 §3 |

守恒:dead 71→65(−6 恰 C 类)/ refs 8314→8313(−1 = 误成链语法消失)/
alive 6720→6725(+5 = 改名 3 + balance_simulator + baseline 报告落点)。

## 2. C 类修复明细(全部有 git/文件系统实证)

1. `battle_drag_skill_test.dart` → `battle_tap_skill_test.dart`:改名实证
   `c579e70e`「拖招测试改名 battle_tap_skill_test」。修 6 处引用
   (tempo-firstclear-design.md:41 / plan.md:31,418,481,512,528;扫描器可见 3)。
   **注:08-18 定性把此条归入 D 系遗漏**——它实为改名非删除。
2. m15_d:41 `tools/balance_simulator.dart` → `test/tools/balance_simulator_test.dart`:
   沿 08-15 ROADMAP v1.9 订正先例(`c3574d65` 实证:计划路径从未入库,实装即此测)。
3. m15_d:59 `通关率 [60%, 85%](难度曲线合理)`:散文括号误成 markdown 链接语法,
   加空格拆解(假阳根修,非改语义)。
4. phase0minus spec:384 示例路径 `docs/performance/2026-08-xx-…` → 实际落点
   `docs/phase0/2026-08-13-phase0minus-macos-baseline.md`(目录从未建立,报告已存在)。

## 3. 残余 65 条定性(B/D 接受)

### B 类 · 假阳/示例/有意缺失/作者自注(23 条)

| 文件 | 条数 | 定性 |
|---|---:|---|
| `2026-08-16-phase0a-production-asset-manifest.md` | 7 | 待产资产落点定义(battle_fx 5 图+battle_hud+battleDeath.mp3);battleDeath 系 Batch 9A 冻结决策「不新增无资产 SfxId」,落点即 manifest 本体 |
| `m15_g_legal_spec` | 7 | legal 三文档+LICENSES 自注「(待创建)」,1.0 法务线未启动 |
| `2026-06-18-phase6-coop-break-window-plan.md` | 2 | `battle_action.dart(已移除)` 作者自注 |
| `2026-06-26-equip-sell-decompose-inventory-plan.md` | 2 | `level_config.dart(已移除)` 作者自注 ×2 |
| `2026-06-24-b1-sect-event-game-loop-wiring-design.md` | 1 | `home_feed_screen.dart(已移除)` 作者自注 |
| `p3_3_pvp_spec` | 2 | `pvp_service/pvp_sync_service(已移除)` 作者自注 |
| `m15_e_audio_spec` | 1 | `assets/audio/voice` 计划目录,语音线未启动 |
| `full_review_2026-07-02_followup_backlog.md` | 1 | `assets/enemies/x.png` 系 iconPath 体例说明的示例字面量,非真引用 |

### D 类 · 从未入库/确删且功能废除(42 条)

| 簇 | 条数 | 实证 |
|---|---:|---|
| `assets/techniques` 心法 cover(PUBLISHING_ART_PASS ×2 / phase_b_technique_panel ×1) | 3 | 曾有 7 commit,`d3cde5a3` 零引用清理确删 |
| `assets/images/inner_demon/*` 心魔七敌图(inner_demon_enemy_mj_prompts ×7) | 7 | git 零历史;心魔走镜像墨色反相路线,专图从未产出 |
| pvp 域(p3_3_pvp_spec: data/lore/pvp ×3 + pvp_strategy ×1) | 4 | `2d0dcded` GDD 切除 PVP |
| `camera_shake.dart`(batch24-impact-feel-plan ×2) | 2 | `778652b5` 明删(+打击感体系替代) |
| `data/proficiency.yaml` ×2 / `lib/core/combat/formulas.dart` ×1(p1a/playability master) | 3 | git 零历史,熟练度实装走他路径 |
| 计划测试路径(numbers_config/stage_def ×2/weakness_hit_glyph/stage_skill_drop_wiring/save_data/drop_table/ascend_milestone_grant ×2/level_service) | 10 | git 零历史(spec 计划名未采用) |
| 计划 lib 路径(sect_monthly_tick_gate/sect_management_screen/seed_service) | 3 | git 零历史(实装另名另址) |
| `tools/perf_profile.dart` / `tools/idle_long_run.dart`(m15_d ×2) | 2 | git 零历史 |
| `docs/UX_GUIDELINES.md`(h_polish_ux ×2) | 2 | git 零历史;现行体例 UI_TERMINOLOGY.md |
| `data/narratives/lore/events`(P0 手动Boss ×1) / `data/narratives/techniques`(full_review ×1) | 2 | narratives 实际子目录无 lore/techniques,结构未采用 |
| `data/ranks.yaml`(tower-extension ×1) | 1 | git 零历史 |
| `docs/handoff/r3_visual_check_screenshots`(RELEASE_CHECKLIST ×1) | 1 | git 零历史 |
| `test/jianghu` ×1 / `test/sect_management` ×1 | 2 | 目录从未建立 |

(D 类合计 42 条;B 23 + D 42 = 65。)

## 4. 残余接受理由与再开条件

沿 08-15/08-18 同结论模式:B 类自注即否决语义(改了反而毁掉作者的移除标记);
D 类全部实证「从未存在或确删且功能废除」,修 = 给不存在的目标造假锚。
**再开条件**:① legal 线启动(m15_g 7 条随创建自愈)② 0A 待产资产落地
(manifest 7 条自愈)③ 扫描器若新增「历史计划目录」归档类(须用户拍板,
会推翻现行 ARCHIVAL_DIRS 五目录口径)。

## 5. 批内守恒

- 纯 md 批零 `.dart`,免 Flutter 全量(守 §8.0 v1.29),flutter test 计数应保持
  **5167** 待 CI 核;
- 扫描器两套件未动(本批零 tools/ 改动)。
