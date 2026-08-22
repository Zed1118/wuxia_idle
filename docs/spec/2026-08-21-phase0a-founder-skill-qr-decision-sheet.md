# Phase 0A 起手技能与 Q/R 行为拍板单

> 状态：DECIDED / 2026-08-21 用户拍板全部推荐项
> 日期：2026-08-21  
> 基线：`699f61a8`  
> 性质：产品与契约决策，不是实现完成声明

## 1. 已确认事实

- production 新档三流派都已学习本流派入门心法，但初窥阶段只开放第
  1 招普攻；第 2 招 `powerSkill` 尚未达到成长门槛，因此数字 1–6 为空。
- 当前 Q/R 是 `numbers.phase0a_arena` 提供的固定全局能力：Q 以玩家为
  中心把作用半径内敌人拉到内环，零伤害；R 以玩家为中心做圆形群伤。
- 1500 局 headless 画像中 Q 每场一次、R 零次；Q 后真气不足以接 R，
  这证明当前资源循环不能作为长期正式契约。
- 灰盒已冻结“聚怪后清场”“Q/R 可参与破招”和“Q/R 不可互换”的产品
  目标，但 production `SkillDef` 尚无 pull/stagger/geometry 行为 schema。
- 现有数字技能 binding 会对 `canInterrupt`、`defenseBreakPct`、
  `qiDrainPct` fail-closed；不得静默丢弃旧技能机制。

## 2. 待拍板

### D1 · Ch1 起手主动技能可见性

**A（推荐）——三流派各提前开放本流派入门心法的第 2 招
`powerSkill`，保持大招门槛不动。**

- 第一章即可验证真实数字技能、真气与 CD，不伪造临时技能。
- 实装前先选择“只调整三本入门心法的成长门槛”或“祖师开局修炼层
  提升”中影响更小的一条；不得改全局 ultimate threshold。
- 需重跑三流派 Ch1 画像，并把灵巧 Boss 分叉作为观察项而非顺手调数值。

**B——保持数字槽为空，只增加明确的成长预告。**

- 最稳，但第一章仍无法验证正式数字技能体验，产品替换 Gate 会继续后移。

**C——降低全局 ultimate threshold。**

- 会影响全内容装配与平衡，不推荐。

### D2 · Q/R 与真实技能的关系

**A（推荐）——保留 Q/R 作为战术键，但槽中必须绑定真实 `SkillDef`；
production mapper 不保留固定 gather/clear fallback；低层隔离 fixture 可直接构造
Adapter，但不得进入 production mapping。**

- Q/R 的键位记忆和现有表现可保留。
- 真气、CD、伤害和技能身份来自真实技能；不再生成伪 `SkillDef`。
- 未绑定兼容行为的技能 fail-closed，不按名称或描述猜语义。

**B——取消 Q/R 专用槽，所有技能只走数字 1–6。**

- 数据模型更统一，但推翻已验证的聚怪→清场输入循环，不推荐在当前阶段做。

**C——永久保留两枚全局固定能力。**

- 与成长、流派和真实技能脱节，画像已证明资源循环不成立，不推荐。

### D3 · 行为 schema 形态

**A（推荐）——效果可组合、几何独立的 typed schema。**

建议概念结构（字段名在实现设计时再冻结）：

```yaml
phase0aBehavior:
  geometry:
    shape: radial
    radius: 520
    anchor: caster
  effects:
    - type: pull
      destinationRadius: 120
    - type: break
      points: 2
```

- 伤害继续读取既有 `powerMultiplier` / `qiDelta` / `cooldownTurns`，schema
  不复制伤害公式。
- `pull`、`break`、`stagger` 等效果显式组合；未知类型、非法半径、互斥
  组合在 load/binding 阶段 fail-fast。
- reducer 只消费 application 已解析的 typed behavior，不回查 YAML。

**B——单一枚举（`gather` / `clear` / `stagger`）绑定整招。**

- 实现较小，但无法表达“群伤 + 破招”或“聚怪 + 破招”等组合，后续大概率
  再迁一次。

**C——继续由 Adapter 按技能类型猜行为。**

- 隐式规则不可审计，容易静默丢机制，不推荐。

### D4 · Q/R 几何锚点

**A（推荐）——首版继续以施法者为圆心：Q 径向拉入内环，R 径向群伤并
按 behavior 施加 break/stagger；鼠标落点版本另立后续切片。**

- 与当前键盘输入、reducer 和现有表现一致，最小化本批风险。
- 仍须在 schema 中保留显式 `anchor: caster`，不得把当前实现写成永久默认。

**B——Q 改为鼠标世界落点聚怪，R 仍以施法者为圆心。**

- 更接近灰盒“落点预览”文字，但需要新的指针目标 intent、无鼠标 fallback、
  bot 策略和表现验收，属于独立交互批。

**C——Q/R 都使用鼠标落点。**

- 改动面最大，且会削弱当前键盘闭环，不推荐。

## 3. 推荐组合与实施边界

推荐：**D1-A / D2-A / D3-A / D4-A**。

拍板后仍拆成两个原子批：

1. 起手技能可见性批：只处理三本入门心法第 2 招的开放路径，重跑三流派
   Ch1 画像；不调敌人数值、不改 ultimate threshold。
2. Q/R behavior schema 纵切：先选各一门真实技能贯通 YAML → loader →
   binding → intent → reducer → event/headless；固定 Adapter 暂不立即删除，
   直到 coverage matrix 证明替代完成。

charge/破招的 24 条内容迁移必须排在这两批之后，并复用同一 typed
`break` 契约，避免再造第二套打断语义。

## 4. 拍板回填

- D1：A——三流派提前开放入门心法第 2 招 `powerSkill`。
- D2：A——保留 Q/R 战术键，改为绑定真实 `SkillDef`。
- D3：A——采用可组合效果 + 独立几何的 typed schema。
- D4：A——首版使用 `anchor: caster`，鼠标落点另立后续切片。
- 备注：按两个原子批执行；先做起手技能可见性，再做 behavior schema。

## 5. D2–D4 实装口径（2026-08-21，2026-08-23 现状回填）

- `skills.yaml` 新增 `skill_phase0a_gather` / `skill_phase0a_clear`，Q/R
  production 映射不再生成伪 `SkillDef`。
- `phase0aBehavior.geometry` 当前只接受 `radial + caster + radius`；
  `effects` 已定义 `damage` / `pull` / `stagger` / `break`。
- 首切片只允许 Q=`pull`、R=`damage + stagger`；后续 charge/破招批已让
  R 精确接受 `damage + stagger + break`，typed `break` 载荷由 reducer
  消费并触发清蓄力、踉跄窗口与招牌技冷却。Q 仍严格为纯 `pull`，带
  `break` 会 fail-closed。
- 真气与冷却仍取 `SkillDef.qiDelta/cooldownTurns`，伤害仍取既有
  `powerMultiplier` 并走唯一 `DamageCalculator`；Q 因无 `damage` effect
  明确零伤且不消耗 RNG。
- D4-A 已冻结为 `radial + caster`；未知 shape/anchor、非法半径、重复效果
  与不受支持的效果组合均在 loader/binding 边界拒绝，不回查名称或描述猜语义。
- 生产 `numbers.yaml` 已同时绑定 `skill_phase0a_gather` / `skill_phase0a_clear`；
  loader 与 mapper 均要求双 ID 非空且解析为真实 `SkillDef`。2026-08-23
  可达性审计证明 mapper 的双空逃生口及 synthetic clear 分支已是死代码，现已删除；
  低层隔离 fixture 仍可直接构造无 typed binding 的 Adapter，不属于 production mapping。
