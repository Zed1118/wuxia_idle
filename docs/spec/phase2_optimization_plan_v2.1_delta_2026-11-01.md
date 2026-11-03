# 二阶段方案 v2.1 差异账（2026-11-01）

> 权威关系：v2.0 冻结稿 `docs/spec/phase2_optimization_plan_v2.0_frozen_2026-08-23.md`（SHA-256 `887eefe07d3cc6afcdfee29ac7f00e7cf6b3a6bb2d634c1cca170c99b9a95217`）保留产品愿景；本文件记录已被后续用户决定覆盖/修正的部分。冲突时：本文件 + `decision_registry.yaml` > v2.0 原文。
> 基线：`origin/main` @ `509bd3a4c`（2026-10-12）；本次审查实测 7,343 测试全绿、analyze 0、CI exact SHA success。

## 1. 当前里程碑（正式分母仍 1/10，仅 M1）

| 里程碑 | 当前事实 |
|---|---|
| M0 | blocked：20 条 tuning 已选待验证；七心魔逐身份签认缺 1；武器时间轴/真气映射已接 `8bb82d2c4` |
| M1 | 已关闭 |
| M2 | blocked 于 G2：候选已合 main `9f1602949`，gang_meng / ling_qiao / yin_rou 合法新档连续通关 01_01→01_05；真人 NOT_RUN |
| M3 | 工程 5/5 武器画像、45/45 矩阵；真人 deferred；`applyCombatModifiers`/`action_timeline` 生产消费者 0 |
| M4 | blocked：塔 6 轮/实际可见 1 敌、矩阵 28 格未采、59.678ms raster 根因未定 |
| M5 | 工程 42/42，真人 deferred |
| M6 | 工程 1/1，真人 deferred |
| M7 | 主线 105/105 + 塔 49/49 工程已接；formal open（依赖 M2–M6 人类门） |
| M8/M9 | planned |

## 2. 已被覆盖的 v2.0 原文

| v2.0 原文 | 现行合同 |
|---|---|
| §2.1 鼠标左键普攻、1–4 招式 | **J 按住单段普攻、1–6 招式、Space 闪避、Q 揽势、R 破阵**（现行合并真人验收单） |
| §3.2/M3/C08 五武器三段普攻链 | **五类单段、按住连发、无攻击位移**；`do_not_reintroduce_the_removed_three_hit_basic_attack_chain_without_an_explicit_product_decision` |
| §4.2/G2 第 4 项 护盾/化解/闪避各有用 | 玩家入口只剩 **Space 闪避**；shield/parry 只保留底层领域能力 |
| §12.4/§1025 近战攻击令牌 2–4 | 当前 `1/1/1/1`（TUNE-ATTACK-TOKEN-01 A，仍 TUNING） |
| §0/§19 Qoder/DeepSeek 受控并行 | **外部 agent 全部退役**（用户 2026-10-12 规则）；单窗口 + Claude/subagent |
| §18 M7 Gate 内容计数即可 | `M7-DEPENDENCY-SEMANTICS-01`：工程可先行，formal M7 必须等 M2–M6 人类门 |
| 基线 4,264 测试（2026-08-23） | 7,343 测试（2026-11-01 实测） |

## 3. 2026-11-01 G2 第一章可读性候选（3A+3B）

**性质：工程候选已合 main `9f1602949`（CI run 41373274789 success）；不是 G2 PASS，真人签字 NOT_RUN。**

### 3.1 迁移路径补回 `mainline_wave` 倍率（根因）

legacy mapper 的 `_asMainlineMob` 一直按 `numbers.mainline_wave` 缩放 hp/attack/output/speed；迁移后的 runtime binding adapter 只乘了 variant 倍率，漏了 profile。40 敌新遭遇因此继承完整 base stats，约 **10× 设计血线、4× 设计敌伤**。本次在 `_applyVariant` 按 `stage.isBossStage` 取 ordinary/boss profile，四项倍率与 legacy 对齐。

| 关卡 | baseHp | profile hp | 有效基础 HP（未乘变体） | 备注 |
|---|---:|---:|---:|---|
| stage_01_01 | 800 | 0.10 | 80 | 变体后约 64–88 |
| stage_01_02 | 900 | 0.10 | 90 | 变体后约 72–99 |
| stage_01_03 | 900 | 0.10 | 90 | 工厂实测：刀 90 / 弩 72 / 索 99 / 头目 117 |

旧 9 敌路径的单体 HP 被直接搬进 40 敌新遭遇；只改 baseHp 而不补 profile，首章仍是硬墙。3A 的 baseHp 800/900/900 与 profile 0.10 是**同一口径的两半**，不能只取其一。

### 3.2 首通敌攻 ×0.70（3A）

- 生产 factory 将 `readableFirstClear.enemyAttackMultiplier` 施到 `CombatantSnapshot.attackPowerMultiplier`（整段伤害），不是只缩 `totalEquipmentAttack`。
- 首通标记：`runStageFlow` 的 firstClear 分支 → `Phase0aMainlineBattleHost.isFirstClear` → `Phase0aMainlineEncounterHostBuildRequest.readableFirstClearTuning`；重打/扫荡/debug 保持 1.0。
- `enemy_hp_multiplier` 由 3.0 改为 **1.0**；`boss_enemy_hp_multiplier` 1.5→**1.0**。2026-11-02 已把三个待接线字段接入生产首通路径（见 §3.6）：attack 仍由 factory 施加；HP 与自动技能由 assembler / `_applyVariant` 施加，避免双重乘算。

### 3.3 01_03 密度/宽限（3A）

`active_limit 12→8`、`reinforcement_threshold 3→2`、`entry_warning_ticks 30→40`、`attack_grace_ticks 15→25`；仍落在方案 G2 的 35–45 总量 / 8–16 活跃区间。

### 3.4 敌方 school 跟随 attack set（仅 Ch1）

| role | attack set 基础招 | 旧 school | 新 school |
|---|---|---|---|
| 刀匪 / 鸣锣头目 | `skill_gangmeng_jichu_basic` | gangMeng | gangMeng |
| 弩手 | `skill_lingqiao_jichu_basic` | gangMeng | lingQiao |
| 绳索掠袭者 | `skill_yinrou_jichu_basic` | gangMeng | yinRou |

修正前第一章全部敌人 gangMeng：灵巧对全场 1.25、阴柔对全场 0.75，40 敌密度把 school counter 放大成墙。修正后 01_01 真实编成为 14 刀 + 6 弩 + 5 索（R5 击杀账断言同步为 14/6/5）。**该派生只作用于 `stage_01_`**；后章保留 authored school，10 个后章 content 迁移测试与 M3 矩阵恢复全绿。

### 3.5 实测（合法新档连续链，1280×720）

gang_meng / mountain_wanderer / balanced_seed（内置 bot，首批 5 关全通）：

| 关卡 | 结果 | 记录击杀 | ticks | 剩余 HP |
|---|---|---:|---:|---:|
| 01_01 | victory | 25 | 213 | 3,652 / 4,000 |
| 01_02 | victory | 12 | 69 | 4,000 / 4,000 |
| 01_03 | victory | 40 | 434 | 3,146 / 4,000 |
| 01_04 | victory | 3 | 39 | 4,000 / 4,000 |
| 01_05 | victory | 2 | 45 | 4,000 / 4,000 |

ling_qiao / escort_apprentice / balanced_seed：同链 5/5 victory（01_01 25、01_02 12、01_03 40、01_04 3、01_05 1 记录击杀），每关剩余 HP 3,928/3,928。

- 自定义首胜脚本（gang_meng）：01_01 25/25、213 拍、剩余 3,652。
- 操作容错：baseline/coarse/slow/stationary 四策略 × 01_01/01_02 通过；kiteSlow/kiteNoDodge 两策略通过。这两个测试只证明“真实键盘策略可运行”，不要求每策略都胜。
- **yin_rou**：2026-11-02 真实 UI 连续链 **5/5 victory**（01_01 161 拍/25 杀、01_02 76/12、01_03 347/40、01_04 37/3、01_05 47/2，全程 3921 HP）。11-01 的 headless 01_01「25 杀但 objective 未收口」是诊断 bot 未接检查点续行，已修，非数值墙。
- 全链现在会遇到并消解战后机缘弹窗、章内行程与章末卷轴；harness 已按真实控件处理，不用测试专用跳过。

### 3.6 首通 HP / 自动技能字段接线（2026-11-02）

- 生产入口：`Phase0aMainlineEncounterRuntimeBindingSourceAdapter.readableFirstClearLoader`；tuned 请求未配置 loader 时 fail-closed，不静默退回普通 bundle。
- 分流：`enemy_attack_multiplier` 仍由生产 factory 施加；`enemy_hp_multiplier` / `boss_enemy_hp_multiplier` 由 assembler 施加；`auto_skill_power_multiplier` / `opening_auto_skill_cooldown_turns` 由 assembler（保留原身份的 Boss）与 `_applyVariant`（变体攻击集）各施加一次。
- 单位修正：`openingSkillCooldowns` 存的是敌人攻击间隔，`opening_auto_skill_cooldown_turns: 1` → 1.0s（原 `turns × ceil(1000/speed) + 1` 会放大到约 11s）。
- 覆盖：`enemy_combatant_snapshot_assembler_test`、新增 `phase0a_mainline_readable_first_clear_wiring_test`（stage_01_05 Boss）、G2 生产验收；`READABLE_FIRST_CLEAR=1` 的 Ch1 headless 诊断通过。
- 影响面：Ch1 01_01–01_03 敌人无自动技能；首通自动技能杠杆实际作用于 01_04/01_05 Boss 及后续带技能敌人。HP 两档当前均为 1.0，行为中性。

## 4. 仍未解决/待拍板

1. ~~**yin_rou 第一章**~~（2026-11-02 收口）：真实 UI 连续链 **5/5 victory**（01_01 161 拍/25 杀、01_02 76/12、01_03 347/40、01_04 37/3、01_05 47/2，全程 3921 HP）；headless 01_01「25 杀但 objective 未收口」是诊断 bot 未接检查点续行，已补 `objectiveContinuationCommandBuilder`，非数值问题。
2. **真人 G2**：现行合并验收单逐项签字；自动化/风筝/截图不代签。
3. ~~**首通配置字段接线**~~（2026-11-02 收口）：三个待接线字段已接入生产首通路径，见 §3.6。
4. **M0 收口**：20 条 tuning 的“保持基线”验证定义；七心魔逐身份签认。
5. **M4 性能**：59.678ms raster 与 28 格矩阵；不能以塔 6 轮/1 可见敌关闭。
6. **M3/M5/M6 人类门**：G2 通过后一次性批处理；Windows 单列。
7. **M7 formal**：保持依赖语义，不把 105/105 + 49/49 工程进度写成 formal M7。

## 5. 本次改动文件

- `data/stages.yaml`（Ch1 三基础敌 HP）
- `data/numbers.yaml`（`readable_first_clear` HP 1.0 / 攻击 0.70）
- `data/combat/encounters/black_wind_ridge.yaml`（01_03 密度/宽限）
- `lib/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart`（mainline_wave 四项倍率；Ch1 school 派生；可选首通参数）
- `lib/features/mainline/application/phase0a_mainline_encounter_host.dart`（首通请求字段）
- `lib/features/mainline/application/phase0a_mainline_production_encounter_factory.dart`（首通敌攻乘子）
- `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart`、`stage_entry_flow.dart`（firstClear 传递）
- 测试：G2 生产验收、Ch1 template/catalog、mainline wiring、工厂/目录/tuning 断言、主线 golden（按新平衡重生成）、mainline onboarding harness（机缘/行程/卷轴）、Ch1 合法新档诊断
- profile 修复后的后续断言：Ch2 有效角色画像乘 0.10/0.25/0.85、M3 矩阵控制画像改为坦克低攻（保留 posture 守卫）、追击关控制玩家降至非一击并补 objective builder、结算诊断改断言显式参与者伤害

### 5.1 2026-11-02 追加改动

- `data/numbers.yaml`（首通注释：字段已接线、1 轮=1 次普攻间隔；数值不变）
- `lib/features/mainline/application/phase0a_mainline_encounter_host.dart`（tuned loader seam；request 标记传入）
- `lib/features/mainline/application/phase0a_mainline_production_encounter_factory.dart`（把首通标记传给 binding source）
- `lib/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart`（`_applyVariant` 对变体攻击集施加自动技能调参）
- `lib/shared/battle_shared/enemy_combatant_snapshot_assembler.dart`（HP 保留、attack 移出、开场冷却单位修正、公开调参 helper）
- 测试：assembler 单测、新增生产接线测试、G2 验收 tuned loader、diagnostics（检查点续行 + 学校参数 + tuned loader）

## 6. 验证边界

- 已跑：phase2 数据 191/191、M3 矩阵 1/1（坦克低攻画像）、G2 生产验收 3/3、工厂 6/6、mapper 30/30、catalog 9/9、tuning 4/4、Ch2 content 7/7、追击 5/5、结算诊断 1/1。
- 诊断：chain 5/5 victory（gang_meng）、second-start 5/5 victory（ling_qiao）、first-victory、two-victories、kite variants、tolerance 全通过。
- 2026-11-02 首通接线后：yin_rou 连续链 **5/5 victory**（tuned 与接线前读数一致：161/76/347/37/47 拍，全程 3921 HP）；gang_meng 连续链 5/5（213/69/434/39/45 拍，与 11-01 记录一致）；`READABLE_FIRST_CLEAR=1` 的 Ch1 headless 诊断通过。
- 全量：2026-11-02 最终代码 **+7,348 全绿**（`All tests passed!`，exit 0，8:22）；`flutter analyze --no-pub` 0 issue。
- 未跑：真实 Windows 实机、真人 G2、真实存档迁移。
