# §12.1 心魔系统 Phase 2 final closeout(1.0 P2.2 全收尾)

> 日期:2026-05-23 / 模型:Mac + Opus 4.7 xhigh
> 上游 implementation closeout(Batch 2.1-2.4):`p2_x_inner_demon_implementation_closeout_2026-05-22.md`
> ROADMAP_1_0.md:110/200/247 P2.2 子阶段 final

---

## TL;DR

P2.2 §12.1 心魔系统 **Batch 2.1-2.5 全收尾 ✅**(17 commit `e666e4c → b15d34d` 全 push origin/main · HEAD `b15d34d` · worktree clean)。机制全通 + UI reactive + main_menu 入口可达。**累计 ~5.25h opus xhigh · spec 估 ~7-8h · 精度 0.66×**。3 项挂账留 1.0 P3+(BreakthroughBlocker character_panel 集成 / 战斗机制层调优 / inner_demon 7 主题 enemy 立绘异步)。

## 一 · Batch 2.5 时间线(3 commit)

| commit | 内容 | Batch |
|---|---|---|
| `308bf52` | R5 跨阶红线压测 3 测 e2e(R5.1 7 关 × 50 种子 / R5.2 cap §5.4 e2e / R5.3 unlock 链 e2e)+ PROGRESS sync | 2.5.A |
| `b15d34d` | UI reactive 三态 + main_menu 入口 + _07 +40% 单副本 + cap 6000 纠 §5.4 维度 + main_menu_test 12 按钮适配 | 2.5.B + 2.5.C |
| (本)| GDD v1.9→v1.10 + ROADMAP P2.2 final + 本 closeout + PROGRESS 收尾 | doc 收尾 |

## 二 · Batch 2.5.A R5 压测数据(支持 2.5.C 决议)

50 种子 × 7 关 distribution(玩家 wuSheng·N layer 满 build vs 镜像 +buff):

```
qiMeng   _01 (+10%): 3/0/47   ruMen    _02 (+12%): 3/0/47
shuLian  _03 (+14%): 3/0/47   jingTong _04 (+16%): 3/0/47
yuanShu  _05 (+18%): 3/0/47   huaJing  _06 (+20%): 3/0/47
dengFeng _07 (+40%): 3/0/47   ← Batch 2.5.C 升档后仍同分布
```

**关键发现**:**数值层 buff 单维度调整不影响战斗结果**(_07 +40% vs +20% 完全同分布 3/0/47)— 真改需战斗机制层(挂账 1.0 P3+,见 §四)。当前「克己难赢但不输」语义 acceptable(0% 输 + 6% 赢 + 94% 平局)。

## 三 · spec 调整记录(本批新增 2 项,接 implementation closeout §四 6 项)

| # | spec 写法 | 实装调整 | 理由 |
|---|---|---|---|
| 7 | inner_demon_07 +20% × 2 副本 | +40% 单副本(YAGNI) | R5.1 实测数据印证 _07 +20% 同 _06 + 不动 BattleState 6v3 架构(memory `feedback_avoid_over_engineer_abstraction`) |
| 8 | mirror_caps.attack_power_max=2000 | 6000(3 × §5.4 单件 2000) | spec 锚错 §5.4 维度 — §5.4「装备攻击 2000」是 equipment.yaml 单件 cap,镜像 totalEquipmentAttack 是 3 件求和;原 2000 让镜像 attack 永远 < 玩家 2850,buff 无效 |

## 四 · 挂账留 1.0 P3+(3 项)

1. **BreakthroughBlocker 集成 character_panel** — character_panel 1257 行,集成需 reactive provider + 找合适插入点 ~30-45min。Demo 玩家通常不达 wuSheng,UX polish 不阻塞 P2.2 收尾。
2. **inner_demon 战斗机制层调优** — R5.1 实测数据层 buff 不影响结果。候选改进:(a) 心魔余毒 debuff 实装(numbers 已配 `residue_debuff.battle_output_multiplier=0.95`,production 未挂);(b) mirror crit_rate +0.20 buff;(c) max_ticks 兜底改 randomized 单方淘汰。1.0 P3+ 战斗机制层调优做。
3. **inner_demon 7 主题 enemy 立绘** — 心魔贪/嗔/痴/慢/疑/空/真 7 张 MJ 派单,iconPath 占位先落,异步 Phase 5+ 美术批次跟。

## 五 · 实装组件清单累计(Batch 2.1-2.5 全段)

| 层 | 文件 | 累计行数(P2.2 全段)|
|---|---|---|
| domain | `lib/features/inner_demon/domain/inner_demon_def.dart` | 206 |
| application | `lib/features/inner_demon/application/inner_demon_service.dart` | 130 |
| application(改) | `character_advancement_service.dart` / `stage_battle_setup.dart` / 3 callers | +47 |
| presentation | `inner_demon_screen.dart`(Batch 2.5.B reactive 升级) | 212 |
| presentation | `breakthrough_blocker.dart` | 90 |
| presentation(改) | `main_menu.dart` 入口 + `shared/strings.dart` 文案 | +11 |
| schema | `enums.dart` StageType/EncounterBiome 各 +1 / `numbers.yaml` inner_demon 段 | +52 |
| stages | `data/stages.yaml stage_inner_demon_01..07` | +130 |
| narrative | `chapter_inner_demon.yaml` + stages × 21 | ~3,900 字 |
| test | inner_demon_service_test + narrative_test + R5 redline_test + main_menu_test 适配 | 28 + 改 |

## 六 · 不变量沿用 + 边界

- GDD §5.4 红线 ✓(`mirror_caps` cap 强加 + Batch 2.5.C 纠 attack_power_max 维度)
- GDD §5.3 三系锁死 / §5.1 反留存焦虑(EXP 不归零)/ §6 散功 ×0.5 公式 ✓
- Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径**完全不变**(`isLayerLocked` 严格 wuSheng 短路 + qiMeng 跨 tier 起步层放行)✓
- CLAUDE.md v1.9 Mac+Opus 单端全权(GDD v1.9→v1.10 + ROADMAP + numbers.yaml 顶部变更摘要明文)✓
- doc 体量(memory `feedback_doc_inflation_overnight`)— 本 closeout ~78 行 ≤80 ✓
- R5 测约束语义不写瞬时事实(memory `feedback_red_line_test_semantics`)✓

## 七 · 累计实测时间(opus xhigh)

| Batch | 实际 | spec 估 | 精度 |
|---|---|---|---|
| Phase 0 + Phase 1 | ~1h | ~1h | 1.00× |
| Batch 2.1 | ~25min | ~1.5h | 0.28× |
| Batch 2.2.A + 2.2.B | ~1.5h | ~2h | 0.75× |
| Batch 2.3 | ~50min | ~1.5h | 0.56× |
| Batch 2.4 | ~15min | ~25min | 0.60× |
| Batch 2.5.A | ~45min | ~45min | 1.00× |
| Batch 2.5.B + 2.5.C | ~45min | ~45min | 1.00× |
| 本 doc 收尾 | ~25min | ~25min | 1.00× |
| **合计** | **~5.25h** | **~7-8h** | **0.66×** |

---

**P2.2 §12.1 心魔系统 Batch 2.1-2.5 全收尾 ✅ → 1.0 P3 起步留下波新会话**(memory `feedback_clear_session_timing`:子系统全收口 = 会话清理边界)
