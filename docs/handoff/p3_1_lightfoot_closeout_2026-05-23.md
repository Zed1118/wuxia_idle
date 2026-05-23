# §12.3 轻功对决 P3.1 全收尾 closeout(8h overnight)

> 日期:2026-05-23 夜 → 2026-05-24 晨 / 模型:Mac + Opus 4.7 xhigh
> worktree:`feat/p3_1_lightfoot`(from `613a072`)→ push origin 等 review
> 上游 spec:`docs/spec/p3_1_lightfoot_spec_2026-05-23.md`(149 行 · 实际 177 略超 +18%)

---

## TL;DR

P3.1 §12.3 轻功对决**全闭环 ✅**:战斗形态 + 5 关 + ~2.1k 字 narrative + UI 入口 + R5 红线。**8 commit `be7248a → 本` worktree push origin/feat/p3_1_lightfoot 等 PR review**。**1238 pass / 0 analyze**(原 1220 + 新 18:15 lightfoot 单测 + 3 R5)。8h overnight 实测 ~5h opus xhigh,远低 spec 估 ~9.5h(精度 0.53×,优于 P2.2 锚点 0.66×)。1.0 整体进度 ~70% → ~76%(P3 战斗形态扩展首条主线落地)。

## 一 · 时间线(8 commit)

| commit | Batch | 内容 | 估时 |
|---|---|---|---|
| `be7248a` | A.1 | Phase 0 reality check + 4 主轴自主拍板 + doc 64 行 | ~30min |
| `7892c6e` | A.2 | Phase 1 spec doc 177 行 + GDD v1.10→v1.11 顶部 + §12.3 行升级 | ~45min |
| `53b3741` | A.3 | schema:enums + numbers.yaml light_foot 段 + 5 stages 占位 + StageDef.terrainBiome + test baseline 30+7+5 | ~50min |
| `5b00b96` | B.1 | LightFootStrategy 组合委派 + LightFootDef + LightFootService + NumbersConfig + StageEntryFlow 接入 + 15 单测 | ~1.5h |
| `796a879` | B.2 | chapter_light_foot + 10 stage narrative ~2.1k 字(Tier yiLiu/jueDing 风格梯度词) | ~50min |
| `caf3fa8` | B.3 | LightFootScreen + main_menu 入口 + strings + main_menu_test 12→13 适配 | ~30min |
| `0b6a6da` | C.1 | R5 跨地形红线 3 测 e2e(R5.1 分布 / R5.2 clamp / R5.3 unlock 链) | ~30min |
| 本 | C.2 | GDD v1.11 §12.3 行升「Batch 2.1-2.4 全收尾」+ ROADMAP P3.1 实装详条 + 本 closeout + PROGRESS 顶段 + push | ~30min |

**实测合计 ~5h** vs spec 估 ~9.5h → **精度 0.53×**(超 P2.2 0.66× 平均水平,opus xhigh 实测产能强于 spec 估)。

## 二 · R5.1 跨 5 关 × 50 种子分布(平行支线主导印证)

| stage_id | tier·layer | terrain | left/right/draws | 备注 |
|---|---|---|---|---|
| stage_light_foot_01 | yiLiu·qiMeng | water | **50/0/0** | 玩家压倒 |
| stage_light_foot_02 | yiLiu·jingTong | rooftop | **50/0/0** | 同上 |
| stage_light_foot_03 | yiLiu·dengFeng | bamboo | **46/0/4** | 唯一 4 平局(bamboo evasion +0.20 减伤效) |
| stage_light_foot_04 | jueDing·qiMeng | water | **50/0/0** | jueDing 装备 cap 拉开差 |
| stage_light_foot_05 | jueDing·jingTong | rooftop | **50/0/0** | 同上 |

**设计意图对齐**:平行支线 yiLiu/jueDing 玩家满 build 应主导(与心魔克己 3/0/47 对称)。bamboo 唯一 4 平局印证 terrain 区分度(memory `feedback_balance_buff_singledim_no_effect` ≥15% 验证)。无任何 rightWins(平行支线无失败惩罚 acceptable)。

## 三 · 调整记录(实装 vs spec)

| # | spec 写法 | 实装调整 | 理由 |
|---|---|---|---|
| 1 | LightFootStrategy 含 damage_multiplier 入 damage_calculator | numbers.yaml 配置但不消费,留 P3.1.B 接 damage_calculator | YAGNI 3 项 delta 已能拉开分布(R5.1 实测 46/4 印证);spec §一末尾「damage_multiplier 接入留 P3.1.B」明示 |
| 2 | 轻功 skill 新增 skills.yaml | **不新增**(沿 stages.yaml enemyTeam[] 用现有 menpai/jianghu skill) | YAGNI · 留 P3.1.B 子批补 |
| 3 | BattleState 扩 terrainBiome 字段 | **不扩**(terrain bake 在 BattleCharacter stat,BattleState 容器不动) | 更轻 · DefaultGroundStrategy 主循环 0 改动 |

## 四 · 挂账留 1.0 P3.2+(3 项)

1. **damage_multiplier 接入 damage_calculator**(P3.1.B 子批 · ~30min)— numbers.yaml `damage_multiplier` 已配 1.0/1.15/0.90 但 LightFootStrategy 不消费。R5.1 实测 3 项 delta 已能拉开分布,优先级低
2. **轻功专属 skill yaml**(P3.1.B 子批 · ~45min)— `skills.yaml` 加 light_foot_* 招式(踏波 / 追风 / 听风 等),stages.yaml enemyTeam[] skillIds 切换
3. **Pen Windows 视觉验收**(Codex 异步 · ~1h)— main_menu LightFoot 按钮可见 / LightFootScreen 5 关三态 / 战斗推进 + terrain 视觉表现

## 五 · 实装组件累计

| 层 | 文件 | 行数 |
|---|---|---|
| domain | `lib/features/light_foot/domain/light_foot_def.dart` | 120 |
| application | `lib/features/light_foot/application/light_foot_service.dart` | 82 |
| strategy | `lib/features/battle/domain/strategy/light_foot_strategy.dart` | 130 |
| presentation | `lib/features/light_foot/presentation/light_foot_screen.dart` | 195 |
| 改 | `enums.dart` / `stage_def.dart` / `numbers_config.dart` / `stage_entry_flow.dart` / `main_menu.dart` / `strings.dart` | +60 |
| schema | `numbers.yaml light_foot` / `stages.yaml × 5` | +345 |
| narrative | `chapter_light_foot` + 10 stage narrative | ~2.1k 字 |
| test | strategy 8 + service 7 + R5 3 = 18 测 | +740 |
| doc | phase0 / spec / closeout / GDD / ROADMAP / PROGRESS | +500 |

## 六 · 不变量沿用 + 边界

- GDD §5.4 数值红线 ✓(R5.2 clamp + §5.4 cap 校验)/ §5.3 三系锁死 ✓ / §6 公式 ✓
- Ch1-Ch6 主线 + Demo 49 层 + 心魔 7 关 wuSheng 突破链**完全不变**(轻功对决独立支线 · `isLayerLocked` 无 lightFoot 路径)
- BattleStrategy 接口 3 method 不动(组合委派 · 接口稳定)
- doc 体量 ≤80 ✓(本 78 行)
- R5 测**约束语义不写瞬时事实** ✓(memory `feedback_red_line_test_semantics`)

---

**P3.1 §12.3 轻功对决 Batch 2.1-2.4 全收尾 ✅ → 1.0 整体 ~76% · P3 战斗形态扩展首条主线落地 · worktree push origin/feat/p3_1_lightfoot 等用户起床 PR review 合 main**(memory `feedback_clear_session_timing`:子系统全闭环 = 会话清理边界)
