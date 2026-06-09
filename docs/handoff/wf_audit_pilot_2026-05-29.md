WORKFLOW_OK · finders=3 · total_findings=21

# 只读静态 Audit 报告 — 挂机武侠

- **base**: `b882907 docs(H2): 中期玩法深度 audit + 候选清单 · 4 系统 Phase 0 grep`
- **方式**: dynamic workflow，3 个并行 sonnet finder（Explore agentType · 只读 grep/read · schema 结构化返回）
- **范围**: `lib/` `data/` `test/` 纯静态审查，未跑 build/test，未改任何现有文件

严重度小计：high=3 · med=11 · low=7

---

## 维度 A — extension 硬编码（1 处）

extension 方法体内写死本应来自 yaml 的常量/魔法数字。

### low

1. **`lib/features/codex/domain/codex_category.dart:36`** — `extension CodexCategoryStep on CodexCategory` 的 `get step` 对 8 个 enum case 逐一 return 字面量 1-8；同一个分母 `8` 又被 `codex_tab.dart:78`、`codex_providers.dart:33` 当魔法数字复用，`numbers.yaml` 无对应字段，`game_repository.dart:553` 还有校验字符串。GDD §10.1 「N 档」扩档时需多处同步改，易不一致。
   - **建议**: `numbers.yaml` 补 `tutorial.mechanic_step_count: 8`，`NumbersConfig` 暴露 `mechanicStepCount`；或 extension 改 `CodexCategory.values.where((c)=>c.isMechanic).toList().indexOf(this)+1` 动态推导，UI 分母统一换成 `.where((c)=>c.isMechanic).length`。

---

## 维度 B — 数值平衡红线一致性（9 处）

对照 `data/*.yaml` 找「配了 yaml 却没消费」与「硬编码绕过配置」。

### high

1. **`lib/features/battle/application/stage_battle_setup.dart:282`** — 敌人 `maxInternalForce`/`currentInternalForce` 硬编码 `1000`，绕过 yaml。`numbers.yaml realms.tiers[*].internal_force_max` 给了各境界内力上限，但敌人内力池永远固定 1000，高境界 Boss 实际只能放代价 ≤1000 内力的招式，与 GDD §5.2（内力 ≤15000）设计意图脱节。
   - **建议**: `EnemyDef` 加可选 `baseInternalForce` 字段（默认参照境界 `internal_force_max`），`_enemyToBattle` 读取而非写死。

2. **`lib/features/encounter/application/encounter_service.dart:104`** — `EncounterService` 构造函数 `attributeGainCap` 默认值硬编码 `5`，而 `numbers.yaml character.adventure_attribute_bonus.lifetime_cap_per_character: 5` 已定义完全对应项，但该 yaml key 在 `lib/` 零消费。改 yaml 不生效。
   - **建议**: `NumbersConfig.fromYaml` 解析该 key 并暴露字段；provider 构造 `EncounterService` 时传入，消除 hardcoded default。

### med

3. **`lib/features/battle/application/stage_battle_setup.dart:285`** — 敌人 `criticalRate`/`evasionRate` 硬编码 `0.05`，未读 yaml。改 `numbers.yaml combat.critical.base_rate` 后敌人行为不变。
   - **建议**: `EnemyDef` 加 `baseCritRate`/`baseEvasionRate`（默认从 `combat.critical.base_rate`/`combat.evasion` 推导），或 `_enemyToBattle` 直接读 `NumbersConfig`。

4. **`lib/features/battle/application/stage_battle_setup.dart:233`** — `applySynergy` 里 `maxHp`/`maxInternalForce` 红线 clamp 值 `20000`/`15000` 是 Dart 字面量，而 §5.4 红线已在 `numbers.yaml inner_demon.mirror_caps.hp_max=20000 / internal_force_max=15000`。改 yaml 不影响 clamp。
   - **建议**: clamp 上限改从 `n.innerDemon.mirrorCaps.hpMax`/`.internalForceMax` 读，保持单一数值来源。

5. **`lib/features/encounter/application/encounter_service.dart:225`** — 奇遇软概率 `p = baseProbability * (1 + fortune/20.0)` 中除数 `20.0` 硬编码，无 yaml 配置项，fortune 灵敏度作为平衡核心参数未外置。
   - **建议**: `numbers.yaml` 加 `encounter.fortune_sensitivity: 20`，`NumbersConfig` 强类型化后消费。

6. **`lib/features/mass_battle/domain/mass_battle_def.dart:90`** — `fromYaml` 解析 `residual_hp_threshold_pct` 的 fallback 默认 `0.05`，但 `numbers.yaml mass_battle.residual_hp_threshold_pct: 0.30`（第 1445 行）。生产路径读 0.30，但 `empty()` 工厂（第 44 行）走 const 默认 0.05，fixture/fallback 路径残血容差与设计值不符。
   - **建议**: const 构造默认值 0.05 → 0.30 对齐 yaml，或 `empty()` 显式传 0.30。

7. **`lib/data/numbers_config.dart:1`** — `numbers.yaml character.adventure_attribute_bonus.bonus_per_event_min/max/distribution/weights`（每次奇遇属性加成范围/分布权重）完全未被 `lib/` 加载消费；`applyOutcome` 用的是各 encounter yaml outcome 写死的 `attributeDelta`，与通用范围约束脱节。
   - **建议**: 明确这批字段是「设计参考」还是「运行时约束」。若是后者，`NumbersConfig` 解析并在 `GameRepository` 红线校验中验证各 outcome delta ≤ `bonus_per_event_max`；若仅文档性，yaml 加注释。

### low

8. **`lib/features/battle/domain/strategy/default_ground_strategy.dart:55`** — 行动制阈值 `1000`（`actionPoint >= 1000` / `-= 1000`）是速度系统核心时序参数，硬编码无 yaml 项。调整速度系统时间尺度无法仅改 yaml。
   - **建议**: `numbers.yaml combat.speed_formula.action_point_threshold: 1000`，`NumbersConfig` 解析后由 strategy 消费。变动风险极低，纳入仅为「零硬编码」一致性。

9. **`lib/data/numbers_config.dart:398`** — `FounderAncestorBuff.cultivationProgressPct` 从 `inheritance.founder_ancestor_buff.sect_wide_buff.cultivation_progress_pct: 0.03` 正确加载，但除 `lineage_panel_screen.dart`（UI 显示）外无业务逻辑消费，对游戏无效。
   - **建议**: 已知 Phase 5+ 挂账（CLAUDE.md §12.2 #11）。yaml 字段加 `# Phase 5+: not consumed yet` 注释，防数值调整者误判已生效。

---

## 维度 C — 红线/平衡测试语义健壮性（11 处）

区分「约束语义」（区间/白名单/集合自洽，robust）与「瞬时具体数字」（数值一调即挂，fragile）。

### high

1. **`test/balance/p3_2_mass_battle_redline_test.dart:576`** — `expect(leftWins, greaterThanOrEqualTo(33))` 把残血容差改善后的历史快照胜场下限写死（注释自承「原 R5.1 33 wins 下限」）。任何平衡微调导致种子分布略偏即误挂，而设计意图（容差启用后胜率更好）仍成立。典型瞬时数字断言。
   - **建议**: 去掉绝对下限，改为同 test 内对比 `residualHpThresholdPct=0` 与启用时的 `leftWins`，断言 `withThreshold >= without`（或至少 `greaterThan(0)`）。历史锚点写注释而非断言。

### med

2. **`test/balance/maxhp_extremum_redline_test.dart:112`** — `expect(maxHp, 16550)` 锁死 wuSheng·dengFeng 极值。意图防漂移（「销账锚点」），但 shenWu 装备 `hp_max` 区间一调即挂，而语义红线 ≤16667 未破。锚点与语义红线同 group，失败时混淆原因。
   - **建议**: 锚点 case 拆独立 group 并注明「追踪 yaml 平衡变更，非语义红线」；或改 `inInclusiveRange(16400, 16667)`。

3. **`test/balance/synergy_hot_loop_upgrade_test.dart:147`** — `expect(result.maxHp, 20000)` 钉死 cap 触发后具体值。若 §5.4 玩家血上限改 22000，语义不变但断言爆。（line 168/187/204-206/229-231 同类精确等值断言并存。）
   - **建议**: 改 `lessThanOrEqualTo(20000)` 验证 cap 语义，另加 `lessThan(21800*1.20)` 或 `greaterThan(18000)` 确认 cap 路径有效触发。

4. **`test/balance/p3_2_mass_battle_redline_test.dart:479`** — `expect(waves.length, 3)` + 各 wave 敌人数 `5/6/6` 钉死 `stage_mass_battle_02` 的 yaml 配置。属「yaml 内容一致性」而非平衡语义；设计师调 wave 配置即合法变更却误挂。
   - **建议**: 改 `inInclusiveRange(1,4)` / 每 wave `inInclusiveRange(5,7)`（R5.1 group 已正确写出，R5.4 的精确断言冗余且脆弱）。

5. **`test/features/sect/stage_boss_recruit_test.dart:109`** — `expect(...baseProbability, 0.40)` ×3 处（109 循环内 / 119 yaml 值 / 126 默认值）钉死招降概率。本意「加载一致性」，但设计师调 P4.1 数值（如 0.35）schema 语义未破却全挂。
   - **建议**: 加载一致性改 `inInclusiveRange(0.0,1.0)` + `greaterThan(0)`；防归零/超限的红线放进 `_enforceBossRecruitRedLines` 用 `[0.1,0.7]` 范围校验，而非测试锁具体值。

6. **`test/features/sect/stage_boss_recruit_test.dart:123`** — `expect(...stageBossFailRecoverProb, 0.30)` 钉死「战败收降概率」。字段注释说留 P5+/1.1 不动，但此断言使任何调整都得同步改测试，并非保护不变量。
   - **建议**: 改语义约束 `stageBossFailRecoverProb < stageBossRecruitProb` + `inInclusiveRange(0.0,1.0)`（R5.failRecover group line 299-304 已正确写出，line 123 冗余脆弱）。

7. **`test/features/jianghu/jianghu_r5_test.dart:96`** — `stageBossKillDelta=5` / `stageBossKillRivalDelta=3` / `encounterNpcDeltaMin=-8` / `encounterNpcDeltaMax=8` 四处精确断言。Boss 击杀 delta 调整为 6 或 -10（合理平衡）即全挂，语义（敌派降/友派升/delta 在合理范围）仍成立。
   - **建议**: 改 `>0` / `>0` / `<0` / `>0` + `Min.abs() <= Max.abs()`。数值追踪靠注释/changelog。

### low

8. **`test/balance/synergy_hot_loop_upgrade_test.dart:168`** — `expect(result.maxHp, 19860)` 钉死 `16550×1.20` 精确乘积。语义只是「日常路径不触发 cap」，浮点实现或 yaml 微调即脆弱。
   - **建议**: 改 `lessThan(20000)` + `greaterThan(16000)`；需追踪公式精度则单独 `formulaAccuracy` group。

9. **`test/features/jianghu/jianghu_r5_test.dart:119`** — `valueFor(1,'shaolin')==-10` / `'jiaoMen'==3` 对累积声望精确断言，是 `delta×次数` 的乘积，delta 一调即爆。
   - **建议**: 改 `lessThan(0)` / `greaterThan(0)`，或用 `triggers` 动态算期望 `-2 * t.stageBossKillDelta`。

10. **`test/features/inheritance/application/founder_buff_service_test.dart:86`** — `expect(hypotheticalCap, 18900)` 钉死「4 件 lineage×5% + founder 5%」叠加精确结果。bonus 系数一调即爆，而真正语义（叠加后 IF 上限 <20000 不破 §5.4）未破。
    - **建议**: 改 `lessThan(20000)`，等值 18900 转注释。

11. **`test/combat/damage_calculator_test.dart:52`** — 战例 A/B/C/D 及边界组约 20+ 处 `finalDamage` 精确等值断言。纯函数公式回归基线，精确值对确定性单元测试合理；但耦合 `numbers.yaml` 的 `cultivationMultiplier`/`defenseRate`，yaml 平衡调整（如修炼倍率 3.0→2.8）会连锁失败。战例 D/E 已用区间断言（`lessThanOrEqualTo(30000)` / `>20000 && <100000`）体现正确语义区分。
    - **建议**: 公式逻辑正确性可保留精确值，但标注「公式回归基线（依赖 numbers.yaml，yaml 变更需同步更新）」；红线触线系列保留 `lessThan(8000)` 约束语义，精确数字转注释不作阻断。

---

## 试点元信息

观察到的 Workflow 行为：

- **工具真正调用**: 用了 `Workflow` 工具（dynamic workflow，inline script），非 Agent 串行、非主 agent 自己 grep。Run ID `wf_61aaf9b8-cb3`，后台执行 + 完成通知回调。
- **并行生效**: `parallel([fA, fB, fC])` 一个 barrier 同时起 3 个 finder（concurrency cap 16，3 个全并发无排队）。
- **子 agent 真跑**: usage 报告 `agent_count=3` · `subagent_tokens=377173` · `tool_uses=108`（三个 finder 合计 108 次 grep/read 工具调用），证明子 agent 真正读了文件而非空转。
- **耗时**: 整体 `duration_ms=287645`（≈4分48秒）墙钟。三 finder 并行，墙钟≈最慢单个 finder；B（9 发现，跨 6 个 lib 文件）和 C（11 发现，跨 8 个 test 文件）明显比 A（1 发现）重，整体被这两个拖到 ~4.8min。
- **无报错**: 三个 finder 全部正常返回 schema 校验通过的结构化结果，无 null、无 agent 崩溃、无 schema retry 可见痕迹。`results` 数组 3 项齐全。
- **schema 强约束有效**: 每条发现都带齐 `file/anchor/problem/severity/suggestion` 五字段，severity 枚举受控（high|med|low），主 agent 汇总零解析成本。
- **只读纪律守住**: 三 finder 均无写操作，全程 grep/read；本次只新建 `WF_AUDIT_REPORT.md` 一个文件。
- **可改进**: A 维度（extension 硬编码）发现面偏窄（仅 1 处），可能本项目 extension 用得克制、或 finder A 搜索面可再放宽（如把 mixin / 顶层 const 一并纳入）。负载不均（A 轻 B/C 重）下 barrier 让 A 早完成后空等，若改 pipeline 对本场景无收益（无下游 stage），此处 parallel 选择正确。
