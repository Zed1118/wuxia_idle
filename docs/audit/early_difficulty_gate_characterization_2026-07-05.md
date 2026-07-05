# 早期难度特征化 · 技能成长门控批后(2026-07-05 夜间批 A)

> 目的:量化验证「UX对比度+技能成长门控」批(`6ce5e37e`)的两个改动对早期难度的真实影响:
> ① 心法 3 招按修炼层解锁(初窥第1招/小成第2招/大成大招);② 配套 3 关敌 HP ~7% 下调
> (01_04 2200→2050 / 04_04 8500→8000 / 06_04 20000←22000)。
> 探针:`early_difficulty_gate_probe_2026-07-05.dart`(本目录附件,一次性诊断不入 test/)。
> 体例镜像 `balance_simulator_test.dart`(on-level·floor/ceiling 剖面·25 seed/格·BattleEngine 确定性)。

## 结论(TL;DR)

1. **3 关 HP 下调在模拟下 = no-op**:cur vs old 全部格子 win% 完全一致(76/76、84/84、100/100),
   avgWinTicks 差 ≤0.3。~7% 下调既没有产生可测的难度缓和,也无回归风险。
   「补偿早期少招」的名义收益未显形——因为「少招」本身就不构成难度(见 2)。
2. **门控的真实影响只在初窥(1招)段**:中成(2招) vs ungated(3招) 全表零差——大招在 ≤15 tick
   的早期战斗里基本不参战(CD/内力门槛),锁不锁无感。**小成(2招)起门控对难度无影响**。
3. **发现真实难度悬崖(非本批引入)**:SOLO·floor·初窥 stage_01_04 = **4%** 胜率。
   01_04 的压迫源是灵巧克制+速度(qingshan speed 105·lingQiao 克玩家刚猛),不是 HP——
   更肉的 01_05(3800 血)同 build 反而 100%。与 stages.yaml:165 注释「保留灵巧压迫」的
   设计意图一致;玩家到 01_04 若已小成(2招)即回 76% 健康区。
4. **3 人满编 on-level 全表 100%**:早期难度实际只存在于单人段(收徒前)。
   balance_simulator 的 3p 剖面对 Ch1 失真,后续早期调参应以 solo 剖面为主读数。

## 数据(25 seed/格 · on-level)

仅列有信息量的行(全表见探针输出;3p 各格全 100% 略):

| stage | hp | build | win% | avgWinTicks |
|---|---|---|---|---|
| 01_04 | cur | SOLO·floor·gated(2招) | 76% | 13.9 |
| 01_04 | old | SOLO·floor·gated(2招) | 76% | 13.9 |
| 01_04 | cur | SOLO·floor·ungated(3招) | 76% | 13.9 |
| 01_04 | cur | SOLO·ceiling(3招) | 92% | 14.0 |
| 01_04 | cur/old | SOLO·floor·gated·初窥(1招) | **4%** | 27.0 |
| 01_04 | cur/old | SOLO·floor·gated·小成(2招) | 76% | 13.9 |
| 01_05 | cur | SOLO·floor·gated·初窥(1招) | 100% | 14.8 |
| 04_04 | cur | SOLO·floor·gated(2招) | 84% | 9.0 |
| 04_04 | old | SOLO·floor·gated(2招) | 84% | 9.2 |
| 04_05 | cur | SOLO·floor·gated(2招) | 100% | 8.4 |
| 06_04 | cur/old | floor·gated(2招·3p) | 100% | 3.6 |

## 探针局限(如实标注)

- floor 剖面沿模拟器体例用 huaJing 境界层——真实 01_04 玩家境界层更低,**绝对胜率被高估**,
  但 A/B 对比(cur/old、gated/ungated)不受影响。
- 玩家固定刚猛流派;01_04 灵巧压迫对刚猛是最坏匹配(阴柔玩家会更轻松),4% 是下界读数。
- 敌全为单体 Boss;真实修炼层节奏(玩家到 01_04 时是初窥还是小成)未建模,是 4% 格子
  是否现实可达的关键未知项。

## 建议(留拍板 · 不动值)

- **无需回调 HP**:下调无害(no-op),回调同样无意义,不折腾。
- **若真机观察到 01_04 卡关**:优先杠杆是敌速度/攻击或修炼度节奏(保证到 01_04 前自然小成),
  HP 已证不敏感。
- **balance_simulator 后续演进候选**:① Ch1-2 加 solo 剖面常驻读数;② fromCharacter fallback
  分支不过门控(battle_state.dart:418 `techDef.skillIds` 直取),模拟器 floor 档火力与生产
  autoFill 路径有体系性偏差——中成后无实测差异,暂不修,记录在案防未来误读。
