# §12.1 心魔系统 · Phase 1 spec(1.0 P2.2)

> 日期:2026-05-22 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`p2_x_inner_demon_phase0_reality_check_2026-05-22.md`
> 用户拍板 4 主轴(B+B+A 微调+B):触发=wuSheng 6 内部+1 飞升前置 7 关 / 形态=stages.yaml stageType: innerDemon / 数值=镜像自己 +10-20% / 惩罚=散功阉割版+心魔余毒 debuff
> ROADMAP_1_0.md:110/200/247 P2.2 子阶段 spec 落地

---

## TL;DR

7 关心魔系统(`stage_inner_demon_01..07` 拦截玩家 wuSheng 7 层突破)。新建 `lib/features/inner_demon/` 模块 + `InnerDemonStrategy implements BattleStrategy`(镜像玩家 character +10-20% 数值强化)+ `character_advancement_service` 加 layer 升级前 unlock 拦截 hook。`StageType` enum 加 `innerDemon` 第 3 项 + `EncounterBiome` 加 `innerRealm` 第 18 项 + `numbers.yaml inner_demon` 段 ~25 行。失败 = 内力 ×0.85 / 主修修炼度 ×0.9 + 「心魔余毒」debuff 闭关 8h 清。**镜像数值强加 §5.4 cap**(HP ≤20k / 内力 ≤15k / 装备 ≤2k),数值天然平衡不破红线。**schema 改动最小**(2 enum 各 +1 / 1 字段段 / 7 stage 实体)。

---

## 一 · 7 心魔关 unlock 矩阵(wuSheng 6 内部 + 1 飞升前置)

| stage_id | unlock 触发(完成 X → 解锁) | 玩家境界 → 突破到 | 镜像强化 | difficulty | 心魔具象 |
|---|---|---|---|---|---|
| stage_inner_demon_01 | mainline_06_05 victory(自动 wuSheng·qiMeng) | qiMeng → ruMen | +10% HP/Atk | 6.2 | 心魔·贪(求胜心) |
| stage_inner_demon_02 | inner_demon_01 victory | ruMen → shuLian | +12% | 6.4 | 心魔·嗔(回望仇) |
| stage_inner_demon_03 | inner_demon_02 victory | shuLian → jingTong | +14% | 6.6 | 心魔·痴(执着之过) |
| stage_inner_demon_04 | inner_demon_03 victory | jingTong → yuanShu | +16% | 6.8 | 心魔·慢(自满之态) |
| stage_inner_demon_05 | inner_demon_04 victory | yuanShu → huaJing | +18% | 7.0 | 心魔·疑(对师父之疑) |
| stage_inner_demon_06 | inner_demon_05 victory | huaJing → dengFeng | +20% | 7.2 | 心魔·空(无物之惧) |
| stage_inner_demon_07 | inner_demon_06 victory | dengFeng → 飞升前夜(A1 接管) | +20% × 双镜像 | 7.5 | 心魔·真(自己 vs 自己) |

> **§5.4 红线 spot check**:玩家 wuSheng·qiMeng HP 上限 ~22k(Ch6 末 reach) × 镜像 +20% = 26.4k > §5.4 玩家血 20k 红线 ⚠ → **镜像数值强加 §5.4 cap**(`mirror_caps` 字段)。普伤公式终值仍 ≤8,000 红线(玩家 build 自带不破)。

---

## 二 · 镜像强化模型(InnerDemonStrategy)

`InnerDemonStrategy implements BattleStrategy`:接玩家 character 镜像副本 + 强化系数,复用 DefaultGroundStrategy 全部 tick/requestUltimate(镜像 = 与玩家同 build 的 Character 实例,粗粒度 strategy 无需重写战斗逻辑)。

```yaml
# numbers.yaml inner_demon 段(新增 ~25 行)
inner_demon:
  mirror_buff_per_stage:                # 各关镜像强化比例
    inner_demon_01: 0.10
    inner_demon_02: 0.12
    inner_demon_03: 0.14
    inner_demon_04: 0.16
    inner_demon_05: 0.18
    inner_demon_06: 0.20
    inner_demon_07: 0.20                # 双镜像 2 副本
  mirror_caps:                          # §5.4 红线 cap(防玩家 build 超时镜像也超)
    hp_max: 20000
    internal_force_max: 15000
    attack_power_max: 2000
  failure_penalty:                      # 散功 ×0.5 公式(GDD §6)阉割版
    internal_force_multiplier: 0.85
    main_cultivation_multiplier: 0.90
    sub_cultivation_multiplier: 1.0
    debuff_id: inner_demon_residue
    debuff_clear_via_retreat_hours: 8
  residue_debuff:                       # 心魔余毒 buff 效果
    battle_output_multiplier: 0.95      # 战斗输出 -5%
    internal_force_recovery_multiplier: 0.80  # 内力恢复 -20%
  unlock_triggers:                      # 触发关 → 下一关 unlock 链
    mainline_06_05: inner_demon_01
    inner_demon_01: inner_demon_02
    # ... 7 项链
  required_realm_layer:                 # 当前境界达到才能进
    inner_demon_01: { tier: wuSheng, layer: qiMeng }
    # ... 7 项
```

**InnerDemonStrategy 关键步骤**:① 深拷贝 player snapshot → enemy Character(inner_demon_07 = 2 副本);② 数值强化 `enemy.hpMax = min(player.hpMax * (1+buff), caps.hp_max)`;③ 复用 DefaultGroundStrategy tick / requestUltimate;④ Victory → `InnerDemonService.unlockNext` + 解锁 layer 升;无 dropTable(心魔关无装备掉落)。

---

## 三 · 突破前置 unlock 拦截 hook

`character_advancement_service.dart:54-67` while-loop 升层段插 2-3 行 hook:

```dart
while (true) {
  if (ch.experienceToNextLayer <= 0) break;
  if (ch.experience < ch.experienceToNextLayer) break;
  final next = nextLayer(ch.realmTier, ch.realmLayer);
  if (next == null) break;
  // ⭐ unlock 拦截:wuSheng 各 layer 升前查 inner_demon_progress 是否 cleared
  if (InnerDemonService.isLayerLocked(ch.realmTier, next.tier, next.layer)) break;
  // 原 EXP 消费 + tier/layer 推进
}
```

`InnerDemonService.isLayerLocked(currentTier, nextTier, nextLayer)`:① 非 wuSheng tier → false(不影响 Demo 7 阶 + Ch4-6 P2.1 主线);② wuSheng·qiMeng → ruMen 查 `inner_demon_01` cleared,未 cleared → true;③ 类推 7 关 unlock 链;④ inner_demon_07 cleared → wuSheng·dengFeng 满 → A1 飞升 hook(P2.3,本 spec 不实装,留接口)。

**EXP 不归零**(GDD §5.1 反留存焦虑):玩家可一直挂机攒 EXP,过心魔关后立刻全部消费多 layer。

---

## 四 · narrative 体例(7 关 ~3,500 字)

| 文件 | 字数 | 风格锚点(Tier wuSheng 风格梯度词:**湛然 / 寂照 / 圆融 / 化机**)|
|---|---|---|
| stage_inner_demon_01..07 _opening | ~250 × 7 | 心魔具象 7 主题 — 贪/嗔/痴/慢/疑/空/真 + 「自己执剑指自己」诗化 |
| stage_inner_demon_01..07 _victory | ~180 × 7 | 镜像消散 + 师父第三句遗言「下文要自己走」回响 |
| stage_inner_demon_01..07 _defeat | ~220 × 7 | 镜像击败你,心魔余毒缠身,闭关清解 |
| chapter_inner_demon.yaml | ~800 | prologue 起「飞升前夜七关心魔」+ epilogue 收 inner_demon_07 后接 A1 飞升 hook |

**字数合计**:~3,500-4,000 字。**风格梯度词**:wuSheng 阶「湛然 / 寂照 / 圆融 / 化机」(对照 zongShi 「澄澈 / 无为 / 玄妙 / 化境」更上一阶,人 vs 自己内省纯粹)。**黑名单**:沿 memory `feedback_collab_mode_single_lore_workflow` 14 词 + 加「神化 / 觉者 / 解脱」等宗教词避免(武侠克制)。

---

## 五 · schema patch 矩阵

| 位置 | 现状 | 改动 |
|---|---|---|
| `lib/core/domain/enums.dart:157 StageType` | `mainline / tower` 2 项 | 加 `innerDemon` 第 3 项 |
| `lib/core/domain/enums.dart:212 EncounterBiome` | 17 项 | 加 `innerRealm` 第 18 项 |
| `data/stages.yaml` | 30 mainline + tower | 加 7 inner_demon entries(沿 stage_06_* 体例 + `stageType: innerDemon` + `biome: innerRealm`) |
| `data/numbers.yaml` | 无 inner_demon 段 | 加 ~25 行 inner_demon 段 |
| `lib/features/inner_demon/` | 不存在 | 新建 domain/InnerDemonDef + application/InnerDemonService + InnerDemonStrategy(战斗) + presentation/InnerDemonScreen + InnerDemonBreakthroughBlocker(UI 拦截) |
| `lib/features/cultivation/application/character_advancement_service.dart:54-67` | while-loop 无拦截 | 加 unlock 拦截 hook(2-3 行) |
| `lib/features/battle/application/` battle 启动入口 | 接 DefaultGroundStrategy | 心魔关 stageType 时实例化 InnerDemonStrategy 替代 |
| `data/narratives/stages/inner_demon_*.yaml` × 21 + `chapter_inner_demon.yaml` | 不存在 | 全新建 |
| `test/balance/inner_demon_*_test.dart` × R1-R5 | 不存在 | 新建测试套 |

---

## 六 · GDD / ROADMAP / PROGRESS 同步(Phase 1 + Phase 2.x)

### 6.1 Phase 1(与 spec 同 commit)
- **GDD.md** v1.7 → **v1.8**:顶加 v1.8 摘要(§12.1 心魔系统 spec 拍板)+ §12.1 加「心魔系统 1.0 P2.2 spec」条目(4 主轴 + 7 关 unlock 链)

### 6.2 Phase 2.x(实装后另起批次)
- **PROGRESS.md** 顶段加 P2.2 心魔全推进段(Ch6 段归档末尾)
- **ROADMAP_1_0.md** P2.2 加「spec 拍板 + 实装完成」状态
- **GDD §12.1** 心魔行升「实装 ✅」

---

## 七 · 风险挂账

| # | 风险 | 应对 |
|---|---|---|
| R1 | 玩家 build 超 §5.4 红线时镜像也超 | `mirror_caps` 字段 schema 上 cap ≤20k/15k/2k |
| R2 | unlock 拦截影响 Demo 全境界(非 wuSheng) | `isLayerLocked` 严格 wuSheng → 其他 tier 默认 false |
| R3 | 心魔余毒 debuff 与现有 buff 体系冲突 | 查 `lib/features/inheritance/founder_buff_service.dart` 体例 + character.activeBuffs(若有);若无,新建单点 buff 应用(简单) |
| R4 | 玩家死刷 EXP 一次性升 6 layer 数值膨胀 | EXP 不归零但 layer 升级 = 1 心魔关 / 次,进步速度自然平衡 |
| R5 | 镜像 + 强化 = 双方实力极接近,跑 max_ticks 兜底 draw(类 Ch6 末关 98% 平局) | acceptable(「难赢但不输」符合「克己」叙事);R5 跑 50 种子 e2e 验 leftWins ≥ rightWins |
| R6 | A1 飞升(P2.3)依赖 inner_demon_07 后置 unlock | 本 spec 留 hook,A1 飞升 spec 起草时接 |
| R7 | enemy 立绘(心魔具象 7 张)异步 MJ 派单(贪/嗔/痴/慢/疑/空/真 7 主题) | iconPath 占位先落 yaml,Phase 2 不阻塞 |

---

## 八 · Phase 2+ 工作流估时(opus xhigh 锚点)

| Batch | 内容 | 估时 |
|---|---|---|
| Phase 1 | spec doc(本) + GDD v1.7→v1.8 | ~30min |
| Batch 2.1 | StageType / EncounterBiome enum 扩 + numbers.yaml inner_demon 段 + 7 stage entries + advancement_service unlock hook | ~1.5h |
| Batch 2.2 | InnerDemonStrategy + InnerDemonService(domain+application)+ InnerDemonScreen 占位 UI + BreakthroughBlocker | ~2h |
| Batch 2.3 | 7 关 narrative ~3,500 字(opening/victory/defeat × 7 + chapter) | ~1.5h |
| Batch 2.4 | GDD §12.1 实装升档 + ROADMAP P2.2 升 + PROGRESS 同步 | ~25min |
| Batch 2.5 | R1-R5 测试套 + Phase 2 closeout | ~1.5h |
| **合计** | — | **~7-8h opus xhigh** |

---

## 九 · 不变量沿用

- GDD §5.4 红线(普伤 ≤8k / 玩家血 ≤20k / 内力 ≤15k / 装备 ≤2k)— mirror_caps 强加 ✅
- GDD §5.3 三系锁死 / §5.1 反留存焦虑 / §6 散功公式 ×0.5 阉割版对齐
- CLAUDE.md v1.9 Mac+Opus 单端全权(GDD/numbers 顶部变更摘要明文)
- memory `feedback_phase0_grep_two_axes` Phase 0 已跑 5 维 ✅
- memory `feedback_avoid_over_engineer_abstraction` — InnerDemonStrategy 直接 implements BattleStrategy 粗粒度 3 method
- memory `feedback_red_line_test_semantics` R5 双边断言
- memory `feedback_doc_inflation_overnight` ≤150 行 ✅(本 spec ~148 行)
- memory `feedback_opus_xhigh_interactive_duration` 精度 1.0× / `feedback_collab_mode_single_lore_workflow` 黑名单 14 词

---

**Phase 1 完 → Phase 2.1+ 实装(spec 拍板后另起批次)**
