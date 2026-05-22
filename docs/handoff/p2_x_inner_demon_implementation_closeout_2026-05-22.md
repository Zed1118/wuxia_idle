# §12.1 心魔系统 Phase 2 实装收口 + Batch 2.5 handoff(1.0 P2.2)

> 日期:2026-05-22 夜 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`p2_x_inner_demon_phase0_reality_check_2026-05-22.md`(59 行)
> 上游 Phase 1:`p2_x_inner_demon_spec_2026-05-22.md`(148 行) + closeout `p2_x_inner_demon_phase1_closeout_2026-05-22.md`
> ROADMAP_1_0.md:110/200/247 P2.2 子阶段 Phase 2 实装(Batch 2.1-2.4)

---

## TL;DR

P2.2 §12.1 心魔系统 **Batch 2.1-2.4 全完 ✅**(Phase 0+1 spec/closeout + Phase 2 实装 + doc 同步)— **14 commit `e666e4c → 99bd584` 全 push origin/main**(9 主 commit + 5 PROGRESS sync)· HEAD `99bd584` · worktree clean。**机制全通**:`InnerDemonService.isLayerLocked` 拦截 hook + `buildMirrorEnemyTeam` 深拷贝 + 3 callers wire production + 22 narrative ~3,900 字 + 2 UI 占位。**累计实测 ~4.5h opus xhigh · spec 估 ~7-8h · 精度 0.56×**(整体快于估,memory `feedback_opus_xhigh_interactive_duration` 应补 P2.2 实装类锚点)。**Batch 2.5 R5 跨阶红线压测 + UI reactive 集成 + inner_demon_07 双镜像决议留下波 ~75min**。

---

## 一 · 14 commit 时间线

| commit | 内容 | 阶段 |
|---|---|---|
| `e666e4c` | Phase 0 reality check 5 维 grep + 4 主轴 B+B+A 微调+B 拍板(doc 59 行) | Phase 0 |
| `4558359` [GDD] | Phase 1 spec doc 148 行 + GDD v1.7 → v1.8 | Phase 1 |
| `cae83c7` | PROGRESS Phase 0+1 sync | Phase 1 |
| `70b5ac9` | Phase 1 closeout 70 行 + Phase 2 handoff | Phase 1 |
| `2903e90` [schema] | Batch 2.1 schema(enums 2 项 + numbers.yaml 46 行 + stages.yaml 7 entries + test baseline) | Batch 2.1 |
| `02c467c` | PROGRESS Batch 2.1 sync | Batch 2.1 |
| `71bd0a7` | Batch 2.2.A InnerDemonDef 206 + isLayerLocked 55 + applyExperience hook + R1 14 测 + 1206 pass | Batch 2.2.A |
| `91ef671` | PROGRESS Batch 2.2.A sync | Batch 2.2.A |
| `1a26488` | Batch 2.2.B buildMirrorEnemyTeam 75 + StageBattleSetup 分支 + 3 callers wire + R2-R3 7 测 + 1213 pass | Batch 2.2.B |
| `563964a` | PROGRESS Batch 2.2.B sync(P2.2 Batch 2.2 全完) | Batch 2.2.B |
| `6bde146` | Batch 2.3 22 narrative ~3,900 字 + UI 占位 2 widget + R4 4 测 + 1217 pass | Batch 2.3 |
| `a0cbb29` | PROGRESS Batch 2.3 sync | Batch 2.3 |
| `86d55fc` [GDD] | Batch 2.4 GDD v1.8 → v1.9 + §12.1 实装升档 + ROADMAP P2.2 实装完成详条 | Batch 2.4 |
| `99bd584` | PROGRESS Batch 2.4 sync(P2.2 doc 全收口 ✅) | Batch 2.4 |

## 二 · 实装组件清单

| 层 | 文件 | 行数 |
|---|---|---|
| domain | `lib/features/inner_demon/domain/inner_demon_def.dart` | 206 |
| application | `lib/features/inner_demon/application/inner_demon_service.dart` | 130 |
| application(改) | `lib/features/cultivation/application/character_advancement_service.dart` | +15 |
| application(改) | `lib/features/battle/application/stage_battle_setup.dart` | +15 |
| application(wire) | `seclusion_service.dart:344` / `tower_entry_flow.dart:351` / `stage_entry_flow.dart:410` | +17 各 |
| presentation | `lib/features/inner_demon/presentation/inner_demon_screen.dart` | 122 |
| presentation | `lib/features/inner_demon/presentation/breakthrough_blocker.dart` | 90 |
| schema | `enums.dart` StageType+innerDemon / EncounterBiome+innerRealm | +6 |
| numbers | `data/numbers.yaml inner_demon` 段(mirror_buff×7 / mirror_caps / failure_penalty / residue_debuff / unlock_triggers×7 / required_realm_layer×7) | +46 |
| stages | `data/stages.yaml stage_inner_demon_01..07` | +130 |
| narrative | `data/narratives/chapters/chapter_inner_demon.yaml` + `stages/stage_inner_demon_01..07_{opening,victory,defeat}.yaml` × 21 | ~3,900 中文字 |
| test | `test/features/inner_demon/application/inner_demon_service_test.dart` 15 测 + `inner_demon_narrative_test.dart` 4 测 + `character_advancement_service_test.dart` +R1 6 测 | 25 |

## 三 · 25 测明细

- **R1 isLayerLocked unit**(8):非 wuSheng / qiMeng 跨 tier / 未通拦 / 已通放行 / 阶梯锁 / empty def / fromYaml 完整+null
- **R1 applyExperience hook integration**(6):null=原行为 / 始终拦 / 选择性拦 / 信任完全 / 阶梯锁 / 拦截不动 cap
- **R2 buildMirrorEnemyTeam 数值/slot**(4):镜像 ×(1+buff)+ 字段重置 / 3v3 slot+id / def 无 stageId / >3 截 3
- **R3 §5.4 cap 红线**(3):接近上限 + buff cap 不破 / 远低于 cap 不变形 / empty def 不破
- **R4 22 narrative loader**(4):7 opening + 7 victory + 7 defeat 全非 placeholder + chapter content 完整

**1217 pass / 0 analyze ✅**(原 1192 + 新 25)

## 四 · spec 调整记录(6 项)

| # | spec doc 写法 | 实装调整 | 理由 |
|---|---|---|---|
| 1 | InnerDemonStrategy implements BattleStrategy | 不建 | YAGNI · BattleStrategy 是 tick 层 / enemy 构造在 setup 层职责(memory `feedback_avoid_over_engineer_abstraction`) |
| 2 | inner_demon_07 双镜像 +20%×2 副本 | 单副本 +20% 占位 | BattleState slot ∈ [0,2] 限 3v3 · 真双镜像 6v3/连战 留 Batch 2.5 R5 讨论 |
| 3 | Batch 2.1 advancement_service hook | 物理挪 Batch 2.2.A | 避免 stub 半成品 · InnerDemonService 实装一起做 |
| 4 | Batch 2.2 InnerDemonScreen / BreakthroughBlocker | 推 Batch 2.3 narrative 一起 | 文案 ready 后 widget 才有内容 |
| 5 | chapter_inner_demon 运行时不 load | 与 chapter_06 同体例 | 纯叙事 doc / R4 测仅验文件存在 + content |
| 6 | UI widget reactive 集成 character_panel/main_menu | 留 Batch 2.5+ | Riverpod provider 集成 + 路由超 Batch 2.3 scope |

## 五 · 不变量沿用 + 边界

- **GDD §5.4 红线**(普伤 ≤8k / 玩家血 ≤20k / 内力 ≤15k / 装备 ≤2k)— `mirror_caps` 强加 schema cap ✓
- **GDD §5.3 三系锁死** / **§5.1 反留存焦虑** / **§6 散功 ×0.5 公式对齐** ✓
- **Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层完全不变** — `isLayerLocked` 严格 wuSheng 短路 + qiMeng 跨 tier 起步层放行 ✓
- **CLAUDE.md v1.9 Mac+Opus 单端全权** — GDD v1.8→v1.9 + ROADMAP 改动明文 ✓
- **doc 体量**(memory `feedback_doc_inflation_overnight`)— 本 closeout ~80 行 / narrative 中文 ~3,900 在 spec 估 3,500-4,000 范围 ✓

## 六 · Batch 2.5 handoff(下波 ~75min opus xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| 2.5.A R5 跨阶红线压测 | 50 种子 × 7 关 stage_inner_demon_XX e2e 跑 buildMirrorEnemyTeam + battle_engine.runToEnd · 双边断言 leftWins ≥ rightWins(玩家镜像数值 acceptable 难赢但不输) · 普伤峰值 spot check ≤ §5.4 8k · 闭塞 layer-by-layer 渐进通关流程 e2e | ~45min |
| 2.5.B UI 集成 | InnerDemonScreen reactive(MainlineProgress.clearedStageIds 三态 cleared/available/locked)+ BreakthroughBlocker 接 character_panel(advancement.layersGained=0 + ch.experience ≥ ch.experienceToNextLayer 条件显示)+ main_menu / sidebar 入口路由 | ~30min |
| 2.5.C inner_demon_07 双镜像决议 | spec §一 +20%×2 副本 vs 当前单副本 +20% — R5 实测平局率 / 玩家通关率 → 决定升 +40% 单副本 或扩 BattleState 6v3 或连战 | (含入 2.5.A) |
| closeout | P2.2 Batch 2.5 + 全 Phase 2 收口 doc(本 closeout 升 final) | ~25min |
| **合计** | — | **~100min ~1.5-2h** |

## 七 · 新会话起读清单

1. 读 PROGRESS.md 顶段(P2.2 Batch 2.1-2.4 段)~2min
2. 读 本 closeout(~3min ⭐ 关键)
3. 选读 spec doc(`p2_x_inner_demon_spec_2026-05-22.md` 148 行,重点 §一 7 关矩阵 / §二 镜像模型 / §七 R5 风险)
4. 选读 GDD v1.9 §12.1 + ROADMAP P2.2 (~2min)
5. `git pull --rebase --autostash`(预期 0 改动 · `99bd584` 已 push)
6. 选读 memory:
   - `feedback_phase0_grep_two_axes`(Phase 0 已跑,Batch 2.5 不重跑)
   - `feedback_red_line_test_semantics`(R5 双边断言 / 50 种子)
   - `feedback_avoid_over_engineer_abstraction`(UI 集成不过度抽象 Riverpod)
   - `feedback_riverpod_closure_ref_disposed`(UI reactive 集成 closure ref 风险)
   - `feedback_opus_xhigh_interactive_duration`(Batch 2.5 估时锚点)
   - `feedback_doc_inflation_overnight`(P2.2 final closeout 体量上限)
   - `project_wuxia_idle` / `project_wuxia_idle_ch4_cultural_arc`

会话 context cache 冷,新会话从 0 起,需重新拉 closeout(本)+ PROGRESS 顶段 + spec doc 共 ~10min 起步。

---

**P2.2 §12.1 心魔系统 Batch 2.1-2.4 全收口 ✅ → Batch 2.5 R5+UI+双镜像 决议留下波新会话**
