# 跨系统数值红线 audit · 2026-05-25 (nightshift T20)

> 任务:盘点 P2.2 心魔 / P3.1 LightFoot / P3.2 MassBattle / P1.2 江湖恩怨 `attackPowerMultiplier` 链 + R5 压测 §5.4 红线
> 基线:`nightshift/T20` HEAD `2f3bc4a` from main · `+10/-0 pass` audit 增量 / `analyze` clean
> 来源风险:`docs/handoff/stage_audit_1_0_overall_2026-05-24.md` §6 R2「单 feature R5 都过,跨系统 multiplier 叠加未压测」

## 1. attackPowerMultiplier 接入点(grep 实测)

| 系统 | 接入点(file:line) | 烘焙时机 | 上限值 | 实装状态 |
|---|---|---|---|---|
| **基础** | `battle_state.dart:147` `attackPowerMultiplier = 1.0` 默认值 | BattleCharacter 构造时 default-safe | 1.0 | ✅ T11 |
| **基础** | `default_ground_strategy.dart:420-422` 末端 `raw = base * cult * school * crit * def * realm * atkPowerMult` | 战斗 tick 内 _calculateInBattle | — | ✅ P3.1.B |
| **P3.1** | `light_foot_strategy.dart:120` `_bake` **SET** `attackPowerMultiplier: m.damageMultiplier` (双方对等) | runToEnd 入口烘焙 | rooftop **1.15** / water 1.00 / bamboo 0.90 | ✅ P3.1.B |
| **P3.2** | `mass_battle_strategy.dart:182` `_bake` **SET** `attackPowerMultiplier: m.damageMultiplier` (**仅 leftTeam**) | runToEnd 入口烘焙 | fengShi **1.10** / yanXing 1.00 / baGua 1.00 | ✅ P3.2 |
| **P1.2** | `npc_relation_service.dart::attackPowerMultFor`(待 T17 ship) | startBattle 注入 | spec clamp_max **1.25** | ❌ spec only (`docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md` commit `4cc649a`) |
| **PVP** | `pvp_strategy.dart:16` 注释「**0 引入 `attackPowerMultiplier`**」反 ELO 段位 buff 越权 | — | 1.0 永远 | ✅ T15 |
| **旧路径** | `damage_calculator.dart:126` `raw = base * cult * school * crit * def * realm` **不消费 APM** | 仅单元测试 / `_calculateInBattle` 镜像之外的合成路径 | — | 标记 |

**关键发现**:有 2 个并存的伤害计算实现 — `damage_calculator.dart`(无 APM,test 走)与 `default_ground_strategy._calculateInBattle`(含 APM,产线走)。**审计针对产线路径**(strategy)模拟 APM 末端乘项。

## 2. 叠加规则(R5 实测)

### 2.1 P3.1 × P3.2:**不可能同 stage 烘焙**
- `stages.yaml`:`stage_light_foot_xx`(StageType.lightFoot)与 `stage_mass_battle_xx`(StageType.massBattle)命名隔离
- 同 BattleState 不会经 2 strategy 双烘焙 — `runToEnd` 入口只走 1 个 strategy

### 2.2 P3.1 / P3.2 内部:**SET 而非乘**
- 两 strategy `_bake` 都是 `attackPowerMultiplier: m.damageMultiplier`(SET),
  后烘焙覆盖前者。但实际产线无双烘焙路径(2.1),不构成累乘风险

### 2.3 P3.1 / P3.2 + P1.2 enmity:**待 T17 ship 决定**
- P1.2 spec 未指定与 strategy `_bake` 的协作顺序;若 startBattle 注入晚于 `_bake`,
  则 enmity 直接覆盖 terrain/formation APM(仅取 enmity 值)
- 若选累乘语义(worst-case):`1.15 * 1.25 = 1.4375`(R5.5 实测验)
- **T17 ship 前必须拍板:覆盖 vs 累乘 vs 取 max** — 挂账下批

### 2.4 暴击 vs APM:**完全独立**
- 暴击是 `_calculateInBattle` 的 `critMult` 项;APM 是末端独立乘项
- worst-case 链:`base * cult(3.0) * school(1.25) * crit(1.5) * def(0.65) * realm(1.0) * APM(1.58)`(R5.7 验)

## 3. base 公式 + multiplier worst-case 实算

| 配置 | base | mainDamage(无 APM) | × APM | 末值 | 红线 | 守 |
|---|---|---|---|---|---|---|
| R5.1 yiLiu 8000IF + 1500eq + APM 1.0 | 5200 | ~3950 | 1.0 | ~3950 | 8000 | ✅ |
| R5.2 + APM 1.15(rooftop) | 5200 | ~3950 | 1.15 | ~4543 | 8000 | ✅ |
| R5.3 + APM 1.10(fengShi) | 5200 | ~3950 | 1.10 | ~4345 | 8000 | ✅ |
| R5.4 + APM 1.25(enmity spec) | 5200 | ~3950 | 1.25 | ~4938 | 8000 | ✅ |
| R5.5 + APM 1.15×1.25=1.4375(P3.1×P1.2 worst) | 5200 | ~3950 | 1.4375 | ~5678 | 8000 | ✅ |
| R5.6 + APM 1.10×1.25=1.375(P3.2×P1.2 worst) | 5200 | ~3950 | 1.375 | ~5431 | 8000 | ✅ |
| R5.7 wuSheng+15000IF+2000eq+crit+jiJing+gangMeng→yinRou+APM 1.581 | 8500 | ~31078 | 1.581 | ~49,135 | **100000** | ✅ |

> 注:R5.1-R5.6 用一流·登峰区间(Demo 实际可达),R5.7 压 1.0 满级 worst-case 看是否进十万。
> 万一暴击破 8000 普伤红线?**不算**,§5.4 「普通伤害 ≤ 8000 / 大招暴击 几万 不入十万」是 2 条独立红线,暴击走「几万」cap。

## 4. R5 测族清单(`test/audit/cross_system_damage_test.dart` · 10 测)

| # | 测名 | 验证项 | 结果 |
|---|---|---|---|
| R5.1 | baseline · APM=1.0 无 multiplier · 普攻 ≤ 8000 | 无 APM 基线不破 | ✅ pass |
| R5.2 | P3.1 terrain rooftop APM=1.15 单维度 | 单维 P3.1 不破 | ✅ pass |
| R5.3 | P3.2 formation fengShi APM=1.10 单维度 | 单维 P3.2 不破 | ✅ pass |
| R5.4 | P1.2 enmity APM=1.25 单维度(spec) | 单维 P1.2 不破 | ✅ pass |
| R5.5 | 跨系统 P3.1+P1.2 乘语义 APM=1.4375 | worst-case P3.1×P1.2 不破 | ✅ pass |
| R5.6 | 跨系统 P3.2+P1.2 乘语义 APM=1.375 | worst-case P3.2×P1.2 不破 | ✅ pass |
| R5.7 | worst-case 暴击+三 APM 链 ≤ 100000 | 大招暴击不入十万 | ✅ pass (~49k) |
| R5.8 | P1.2 enmity clamp_max ≤ 1.25 spec 契约 | T17 ship 入参契约 | ✅ pass |
| R5.9 | LightFoot vs MassBattle 烘焙覆盖语义 | 单 strategy APM 上限契约 | ✅ pass |
| R5.10 | §5.4 mirror_caps hp/IF/atk cap 不破 | hp≤20k / IF≤15k / atk≤6k(3 件求和) | ✅ pass |

## 5. 结论 & 挂账

**全过 10/10**,生产路径(P2.2/P3.1/P3.2 实装 + P1.2 spec 假设)**不破 §5.4 红线**。R5.7 worst-case ~49k 远低于 100k 大招红线,无 cap 兜底需求。

### 挂账(T17 ship P1.2 前必拍板)
- **P1.2 enmity 与 P3.1/P3.2 strategy `_bake` APM 协作语义未定**:覆盖 / 累乘 / 取 max 三选一。**推荐累乘**(R5.5/R5.6 验不破红线,语义直观)。T17 实装时在 `NpcRelationService.attackPowerMultFor` 加 R5.4-R5.6 同体例真实战回归
- **公式分叉**:`damage_calculator.dart:126` 不消费 APM(仅 test),`default_ground_strategy._calculateInBattle:422` 消费 APM(产线)。本批不重构合并(YAGNI)
- 若 T17 实装变更 spec clamp_max=1.25,须回头校 §1/§2
