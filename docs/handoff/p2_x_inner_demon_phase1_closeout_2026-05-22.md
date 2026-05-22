# §12.1 心魔系统 Phase 1 全收口 + Phase 2 handoff(1.0 P2.2)

> 日期:2026-05-22 晚 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`p2_x_inner_demon_phase0_reality_check_2026-05-22.md`(59 行)
> 上游 Phase 1:`p2_x_inner_demon_spec_2026-05-22.md`(148 行)
> ROADMAP_1_0.md:110/200/247 P2.2 子阶段 spec 起草拍板 → Phase 2 实装接续

---

## TL;DR

P2.2 §12.1 心魔系统 **Phase 0+1 全收口 ✅** — 3 commit `e666e4c` Phase 0 + `4558359` Phase 1+GDD + `cae83c7` PROGRESS 全 push origin/main · HEAD `cae83c7` worktree clean。**spec doc 148 行 ≤150 限** + GDD v1.7→v1.8 + 4 主轴拍板 B+B+A 微调+B + 7 关 unlock 矩阵 + InnerDemonStrategy 设计完整。**实测 ~1h**(估 2.5-3h · **精度 0.33× 显著快于估** — 技术 spec 无叙事段重写,与 Ch4-6 叙事 spec 节奏不可比,memory `feedback_opus_xhigh_interactive_duration` 应补「技术 spec」类别锚点)。**Phase 2+ 实装 ~7-8h opus xhigh,适合新会话开局**。

---

## 一 · 3 commit 时间线

| commit | 内容 | doc/code |
|---|---|---|
| `e666e4c` | Phase 0 reality check 5 维 grep + 4 主轴 B+B+A 微调+B 拍板 | doc 59 行 |
| `4558359` | Phase 1 spec doc + GDD v1.7 → v1.8 [GDD] | spec 148 行 + GDD 2 处 edit |
| `cae83c7` | PROGRESS 顶段同步(Ch6 段下推保留同日 context) | 12 行新 + 1 行改 |

## 二 · 4 主轴拍板(Phase 1 spec 落地)

| # | 决策 | 拍板 | spec 落地段落 |
|---|---|---|---|
| 1 | 触发时机 | **B**(wuSheng 6 内部 + 1 飞升前置 = 7 关) | spec §一 unlock 矩阵 + §三 unlock hook |
| 2 | 关卡形态 | **B**(stages.yaml `stageType: innerDemon`) | spec §五 schema patch(StageType +innerDemon / EncounterBiome +innerRealm / 7 stage entries) |
| 3 | 数值模型 | **A 微调**(镜像玩家 +10-20%) | spec §二 InnerDemonStrategy + mirror_buff_per_stage 7 配 + mirror_caps §5.4 红线强加 |
| 4 | 失败惩罚 | **B**(散功阉割版 + 心魔余毒 debuff) | spec §二 failure_penalty(内力 ×0.85 / 主修修炼度 ×0.9 + residue_debuff 闭关 8h 清) |

## 三 · 已产 artifacts

- **`docs/handoff/p2_x_inner_demon_phase0_reality_check_2026-05-22.md`**(59 行 · 5 维 grep 矩阵 + 4 主轴拍板)
- **`docs/handoff/p2_x_inner_demon_spec_2026-05-22.md`**(148 行 · TL;DR + 7 关 unlock + 镜像模型 + unlock hook + narrative 体例 + schema patch + GDD/ROADMAP/PROGRESS 同步 + 风险挂账 + 估时 + 不变量沿用)
- **`docs/handoff/p2_x_inner_demon_phase1_closeout_2026-05-22.md`**(本文)
- **GDD.md v1.8**(顶部 v1.8 变更摘要 + §12.1 心魔行加 spec 拍板注 + 版本号升)
- **PROGRESS.md** 顶段加 P2.2 Phase 0+1 全段(Ch6 段下推保留同日 context)

## 四 · Phase 2+ 实装路线(新会话另起批次)

| Batch | 内容 | 估时 |
|---|---|---|
| 2.1 schema | StageType/EncounterBiome enum 各 +1 + numbers.yaml inner_demon 段 ~25 行 + 7 stage entries + advancement_service unlock hook 2-3 行 | ~1.5h |
| 2.2 代码 | `lib/features/inner_demon/` 全模块(InnerDemonDef + InnerDemonService + InnerDemonStrategy implements BattleStrategy + InnerDemonScreen + BreakthroughBlocker) | ~2h |
| 2.3 narrative | 7 关 ~3,500 字(opening/victory/defeat × 7 + chapter_inner_demon)+ Tier wuSheng「湛然/寂照/圆融/化机」+ 心魔 7 主题贪/嗔/痴/慢/疑/空/真 | ~1.5h |
| 2.4 doc | GDD §12.1 实装升档 / ROADMAP P2.2「实装 ✅」/ PROGRESS 同步 | ~25min |
| 2.5 测试 | R1 unit(unlock hook) + R2 integration(突破前置流程) + R3 strategy(镜像数值) + R4 narrative(21 文件) + R5 跨阶红线压测(镜像 +20% 不破 §5.4) | ~1.5h |
| closeout | Phase 2 全收口 closeout + Phase 3+ handoff | ~25min |
| **合计** | — | **~7-8h opus xhigh** |

## 五 · 不变量沿用 + 边界

- **GDD §5.4 数值红线**(普伤 ≤8k / 玩家血 ≤20k / 内力 ≤15k / 装备 ≤2k)— `mirror_caps` 字段强加 schema 上 cap
- **GDD §5.3 三系锁死** / **§5.1 反留存焦虑** / **§6 散功公式 ×0.5 阉割版对齐**
- **Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径完全不变**(`isLayerLocked` 严格 wuSheng 短路,非 wuSheng tier 返 false)
- **B 路线 0 contamination**(Phase 0 grep verify codebase 0 心魔引用)
- **CLAUDE.md v1.9 Mac+Opus 单端全权**(GDD/numbers/data_schema/IDS_REGISTRY 顶部变更摘要明文确认)

## 六 · 新会话起读清单(用户 first action)

1. 读 PROGRESS.md 顶段(P2.2 Phase 0+1 段)~2min
2. 读 本 closeout(~3min)
3. 读 spec doc(148 行 ~5min,重点 §一 7 关矩阵 + §二 镜像模型 + §五 schema patch)
4. 选读 GDD v1.8 摘要 + §12.1 心魔行
5. `git pull --rebase --autostash`(预期 0 改动)
6. 选读 memory:`feedback_phase0_grep_two_axes` / `feedback_avoid_over_engineer_abstraction` / `feedback_doc_inflation_overnight` / `feedback_opus_xhigh_interactive_duration`

会话 context cache 冷,新会话从 0 起,需重新拉 spec doc 全文 + GDD v1.8 + PROGRESS 顶段共 ~10min 起步。

---

**P2.2 Phase 1 全收口 ✅ → Phase 2+ 实装新会话开局**
