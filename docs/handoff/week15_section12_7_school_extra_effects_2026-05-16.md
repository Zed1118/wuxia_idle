# W15 §12.1 #7 三流派 extra_effect 数值 v1.4 决议 + 代码层全链路落地 closeout

> 2026-05-16 / Mac · opus xhigh / 单会话 ~2.5h / 3 commit / 零回退

## 1. 一句话

CLAUDE.md §12.1 #7 由 W1-W15 起阻塞战斗系统进阶 + 闭关正午加成的 3 条 sub-decision 全收口:① 刚猛震伤 +500 固定 ② 阴柔内伤 N=3 × 200/tick ③ 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `school==gangMeng` 触发。numbers.yaml + CLAUDE.md v1.4 + 代码层全链路同期落地(NumbersConfig + damage_calculator + battle_engine + BattleState + seclusion_service),**722/722** + analyze 0 issues。**销账 §12.1 #7 → §12.2 归档**,§12.1 剩 #10 师承遗物 1 条。

## 2. 拍板 4 个子项决议

| Q | 决议(全选推荐)| 理由 |
|---|---|---|
| Q1 刚猛震伤值 | 固定 +500 每招(穿透防御不暴击,主攻击命中才触发) | 500 是普攻基础伤害区间(500-1500)下界,触发感存在但不喧宾夺主;红线 ≤8000 安全 |
| Q2 阴柔内伤单位 | 守方 tick 数 N=3 + 每 tick 扣 200 固定 | 项目 actionPoint 制下「守方下次自己出手」最贴近回合制 N 语义;200×3=600 对玩家 max_hp 20000 约 3% / Boss 50000 约 1.2% |
| Q3 叠加规则 | 刷新持续(refresh 覆盖)+ 不叠层 | 最常见武侠/RPG 体例,玩家直觉=「debuff 续命」;代码层简单(单 slot 单 timer)|
| Q4 正午阳刚加成维度 | `internalForcePoints` 维度 × 1.2,仅 `character.school==gangMeng` 触发 | 刚猛=阳刚武学=内力外放,语义对偶;子时 +20% 已乘 internalForcePoints,正午 +20% 同对应 = 主线一致 |

## 3. 改动清单

### 3.1 numbers.yaml(C-1)

`combat.schools` 新增 2 sub-config:

```yaml
gang_meng_quake:
  damage: 500
  pierces_defense: true
  pierces_critical: true
  follows_main_hit: true

yin_rou_internal_injury:
  turns_persist: 3
  damage_per_tick: 200
  pierces_defense: true
  stack_rule: "refresh"
  follows_main_hit: true
```

`retreat.time_of_day_bonus[zhengWu]` 加 2 字段:

```yaml
- period: zhengWu
  time_range: ["11:00", "13:00"]
  effect: "yang_school_techniques"
  multiplier: 1.20
  target_attribute: "internal_force_points"  # v1.4 决议
  applies_to_school: "gangMeng"              # v1.4 决议
```

### 3.2 CLAUDE.md v1.4(C-1)

- 头部 version `v1.3 → v1.4`
- v1.4 变更摘要(2026-05-16):§12.1 #7 拍板 + 4 yaml 字段 + 代码层全链路落地清单
- §12.1 删 #7(剩 #10 + 备注 #11/#12)
- §12.2 已消解归档加 #7 条目(4 sub-decisions 描述 + 落地引用位置)
- §12 章节头从「v1.2 收口」改「v1.4 收口」 + 剩 1 条说明

### 3.3 代码层(C-2)

| 文件 | 改动 |
|---|---|
| `lib/data/numbers_config.dart` | 加 `GangMengQuakeConfig` / `YinRouInternalInjuryConfig` class + `SchoolCounterMatrix` 加 2 字段 + `SchoolCounterMatrix.fromYaml` 解析;`RetreatConfig` 加 `zhengWuYangSchoolMultiplier` / `zhengWuTargetAttribute` / `zhengWuAppliesToSchool` 3 字段 + `RetreatConfig.fromYaml` 解析 |
| `lib/features/battle/domain/damage_calculator.dart` | `AttackResult` 加 `mainDamage` / `quakeDamage` 必填字段 + `.dodged` factory 兜底 0;`DamageCalculator.calculate` 主乘式后追加 quakeDamage 独立加值(刚猛 → 阴柔时 = yaml.damage,其他 = 0);breakdown 串加震伤显示 |
| `lib/features/battle/domain/battle_engine.dart` | `_calculateInBattle` 同步加 quakeDamage 分支(与 damage_calculator 镜像逻辑);`_resolveAction` 入口扣 internalInjury dot(若 turns > 0:扣 damagePerTick 穿透防御 + turns-=1,致死写「内伤崩裂」BattleAction + 胜负判定 + return 跳过本次行动);末尾命中后若 atk=yinRou + def=lingQiao + !isDodged → refresh defender.internalInjury(覆盖) |
| `lib/features/battle/domain/battle_state.dart` | 新加 `InternalInjurySlot` immutable class(`remainingTurns` / `damagePerTick` + `==` / `hashCode`);`BattleCharacter` 加 `internalInjury` nullable 字段 + `copyWith(Object? internalInjury = _unset)` sentinel 处理 null 替换 + `toString` 显示 |
| `lib/features/seclusion/application/seclusion_service.dart` | `_isZhengWu(startedAt)` helper 新加(11-13 时);`computeOutputs` 签名加 `TechniqueSchool? charSchool` 可选参数 + 计算 `zhengWuBonus`(正午 + applies_to_school 命中乘 multiplier);`internalForcePoints` 公式加 `× zhengWuBonus`;`completeRetreat` writeTxn 外预读 character.school 传给 computeOutputs(2 次 read 开销可忽略 - 低频路径)|

### 3.4 test 矩阵(C-3) **+14 test**

| 文件 | 增量 |
|---|---|
| `test/combat/damage_calculator_test.dart` | +3 quake test(刚猛 vs 阴柔触发 / 非刚猛 attacker 不触发 / 刚猛 vs 非阴柔不触发);I2 老 test 改写主乘式锚点(`mainDamage`=1187 + `quakeDamage`=500,而非 `finalDamage`=1187) |
| `test/combat/battle_engine_test.dart` | +5 internal_injury 状态机 test(命中施加 / 出手扣 dot 衰减 / turns=1 用尽清空 / 同源刷新覆盖 / 闪避不施加)|
| `test/features/seclusion/application/seclusion_service_test.dart` | +3 正午阳刚 test(刚猛 + 正午 +20% / 非刚猛 + 正午不加成 / 刚猛 + 非正午不加成);老 caller 不传 charSchool 默认 null 走「不加成」分支 - 兼容沿老体例 |
| `test/data/school_counter_v14_config_test.dart` | **新建** +3 红线 test(`gang_meng_quake` 4 字段值锁 / `yin_rou_internal_injury` 5 字段值锁 / `zhengWu` 3 字段值锁)|
| `test/widget_test.dart` | 3 处 `AttackResult` const 构造补 `mainDamage` / `quakeDamage`(0 - 老 fixture 不触发刚猛克阴柔)|
| `test/combat/battle_log_test.dart` | `_normalHit` helper 补 `mainDamage`=damage / `quakeDamage`=0 |
| `test/combat/t17_scenarios_test.dart` | 场景 B 克制/被克制比值 1.667 改用 `mainDamage` 锚点(`finalDamage` 含震伤会撞干扰)|
| `test/features/seclusion/domain/seclusion_map_def_test.dart` | 2 处 `const RetreatConfig(...)` 补 3 字段(`zhengWuYangSchoolMultiplier` / `zhengWuTargetAttribute` / `zhengWuAppliesToSchool`)|

## 4. 关键决策细节

### 4.1 `quakeDamage` 独立加值不进 raw 乘式

```dart
final raw = base * cultMult * schoolMult * critMult * defMult * realmMult;
final mainDamage = raw.toInt();
final quakeDamage = (atk=gangMeng && def=yinRou) ? n.schoolCounter.gangMengQuake.damage : 0;
final finalDamage = mainDamage + quakeDamage;
```

不进 raw 是因为 yaml 明文「穿透防御不暴击」:若进 raw → 会被 `× critMult × defMult × realmMult` 4 个分支干扰,语义偏离。独立加值方式让 `quakeDamage` 字段在 `AttackResult` 上**永远是设计值**(500),log 显示「主伤害 1187 + 震伤 500 = 1687」干净。

### 4.2 `internalInjury` 用「守方下次自己出手」语义(非每 tick)

设计权衡:
- 每 tick 衰减 → 实现简单但语义偏离(N=3 = 3 tick 后消失,但 tick 跟 character speed 解耦)
- 守方自己出手时衰减 → 「守方 turn」最贴近 user-facing 回合制 N 语义,代价是「速度 0 角色不结算」(但 speed 0 角色本来就不该有 turn,合理)

选后者。代码层在 `_resolveAction` 入口扣 dot + `turns-=1`,致死 → 写「内伤崩裂」BattleAction + return。

### 4.3 `BattleCharacter.copyWith` 用 `_unset` sentinel 处理 nullable 字段

`internalInjury` 是 nullable(`InternalInjurySlot?`)。`copyWith(internalInjury: null)` 应该被解读为「清空 debuff slot」,而 `copyWith()` 不传该字段应该「保留原值」。Dart `copyWith(int? x)` 模式下,传 `null` 和不传无法区分。

沿 `BattleState.copyWith(Object? result = _unset)` 体例(line 336 `const Object _unset = Object()` 已有),BattleCharacter 同步加。

### 4.4 `_resolveAction` 用 `preActor` / `preState` 局部变量

dot 结算扣 hp + turns-=1 + 写 BattleAction 修改了 actor / state。本批新加 dot 路径走到后半段「主攻击执行」需要用 dot 后 state 不是原 state。重命名 `actor → preActor` / `state → preState` 让数据流明晰:

```
state, actor → (dot 扣 / 致死则 return) → preState, preActor → ... 主攻击执行 ...
```

代价:全函数 30+ 行 `state` / `actor` 替换为 `preState` / `preActor`,但语义清晰。

### 4.5 老 caller `computeOutputs` 不传 `charSchool` 默认 null 不加成

`computeOutputs` 加 `TechniqueSchool? charSchool` 可选参数(默认 null)。`zhengWuBonus = (_isZhengWu && charSchool == config.zhengWuAppliesToSchool) ? 1.20 : 1.0` — null 比对 `gangMeng` 为 false → 不加成,**老 caller(test、未传参的 caller)行为不变**,沿用项目老兼容体例。

`completeRetreat` writeTxn 外预读 `character.school` 传给 `computeOutputs` — 2 次 character read(predict + writeTxn 内 write 用),seclusion 完工是低频路径,开销可忽略。

## 5. 数据流图(主战斗 + 闭关)

```
战斗内:
  actor 出手 → _resolveAction(state, actor) 入口
    ├ 若 actor.internalInjury != null + remainingTurns > 0
    │   ├ 扣 damagePerTick(穿透 defense)+ turns -= 1
    │   ├ 致死 → 写「内伤崩裂」BattleAction + 胜负判定 + return
    │   └ 存活 → preActor 注入 + 继续主攻击
    ├ 主攻击 _calculateInBattle
    │   ├ 主伤害 raw 乘式(mainDamage)
    │   └ 刚猛 → 阴柔 → +500 震伤(quakeDamage,独立加值)
    └ 命中后 → 阴柔 → 灵巧 → defender 加/refresh internalInjury slot

闭关内:
  computeOutputs 入口 → charSchool 注入
    ├ _isZhengWu(startedAt) + charSchool == gangMeng
    │   → zhengWuBonus = 1.20
    └ internalForcePoints *= zhengWuBonus(其他维度不动)
```

## 6. test 矩阵覆盖

| 子系统 | test 用例 | 增量 |
|---|---|---|
| damage_calculator quake | I2 改写 + 3 quake | +3 / 改 1 |
| battle_engine internal_injury | 5 状态机 case | +5 |
| seclusion 正午阳刚 | 3 case(正午+刚猛 / 正午+非刚猛 / 非正午+刚猛) | +3 |
| numbers.yaml v1.4 红线 | 3 段字段值锁 | +3 |
| AttackResult 构造补字段 | 4 caller(3 widget_test + 1 battle_log_test) | 0 增减(改写)|
| RetreatConfig 构造补字段 | 2 caller(seclusion_map_def_test) | 0 增减 |
| t17 场景 B 主伤害比 | 改 finalDamage → mainDamage | 0 增减 |
| **共计** | **+14 新增 / 7 改写** | **708 → 722** |

## 7. 销账

| 候选 | 状态 |
|---|---|
| C-1 yaml + CLAUDE.md v1.4 | ✅ 4 字段 + v1.4 头部摘要 + §12.1 → §12.2 归档 |
| C-2 代码落地 | ✅ NumbersConfig + damage_calculator + battle_engine + battle_state + seclusion_service 全链路 |
| C-3 test 矩阵 | ✅ 14 新增 test 全过 + 7 老 test 改写零回退 |
| C-4 PROGRESS + closeout + commit | ✅ 本批 closeout + 3 commit feat + test + docs |

## 8. 下波候选

**§12.1 #7 收口完成,Codex Pen round2 派单跑中**(异步等):

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 候选 A | Codex round2 closeout 回销账(#34 完整闭环)| inline | 5-10min | 等 Codex 完工 |
| 候选 B | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min 讨论 | 剩 §12.1 最后 1 条挂账 |
| 候选 C | mainline+tower victory 写回 widget integration test | sonnet | 1-2h | 本批 dialog 单元 test 已覆盖,e2e 可选 |
| 候选 D | battle_log 加内伤崩裂 / 震伤命中文案到 enum_localizations.dart | sonnet | 30min | 本批 BattleAction `description` inline,可正式抽 |

## 9. 经验沉淀

### 9.1 nullable field copyWith 的 _unset sentinel 已是项目体例

BattleState `result: Object? = _unset` 已落 W11,本批沿用扩 BattleCharacter `internalInjury`。**新加 nullable 字段时 default = _unset + identical check** 是已定纪律,不需要 memory(项目内已有 2 处实例)。

### 9.2 v1.4 数值红线 test = 写「v1.4 决议被 yaml 加载层落地」语义

`test/data/school_counter_v14_config_test.dart` 是「决议落地红线」类型:不验代码逻辑,只验 numbers.yaml 加载后字段值 = §12.1 #7 决议。改 yaml 数值需要同步改 test + CLAUDE.md + PROGRESS,**三方互锁防漂移**。沿 `feedback_red_line_test_semantics` 但加了"v1.x 决议锁"维度。

### 9.3 跨多模块改 `AttackResult` schema(加必填字段)的连锁修法

`AttackResult` 加 2 必填字段(`mainDamage` / `quakeDamage`)→ analyze 1 次跑出 4 caller 缺字段 + 1 个老 test 期望值需更新。**改 schema 必填字段 = 一波拉清单 + 一波 grep 反应炉**,本批走的是「先 analyze 拿全名单 → 一波 edit → 再 analyze 0 → flutter test 全 → 改老 test 期望值」4 步,**约 5 min 完成 4 处补字段 + 2 处 regression 修正**。

(本条不纳入 memory,场景偶发,但走流程已是肌肉记忆。)

---

## 10. 收尾

**会话清理建议**:不需要清理(同一子系统 W15 §12.1 收口链路,候选 A round2 closeout 等 Codex 异步回 / 候选 B/C/D 均与本批语义紧密关联)

push 3 commit 后等 Codex Pen round2 回。
