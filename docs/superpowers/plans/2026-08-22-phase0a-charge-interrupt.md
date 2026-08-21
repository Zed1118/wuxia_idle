# Phase 0A Boss 蓄力 / 玩家破招能力纵切

## 目标

把 production Boss 蓄力(`EnemyDef.chargeSkillId` 顶层入口 +
`BossPhaseMechanic.chargeCounter` 阶段入口)与玩家破招完整接入 Phase 0A
同一 reducer / 敌 AI / headless / settlement 路径,复用 Q/R 批已落的 typed
`Phase0aSkillEffectType.breakPower` 契约,不另造第二套打断语义。完成后
capability matrix 中因 `unsupported_boss_phase_or_charge_semantics` 跳过的
24 条真实内容(19 主线 + 5 塔:floor 7/14/21/28/35)具备真实语义并解除跳过;
guardian ward(2)、vulnerability(8)、survive 胜负(1)等未迁机制保持
skipped,不得伪报 eligible。

分支:`codex/qwen-phase0a-charge-interrupt-0822`(基线 main `19ff7879`,
前一批 Q/R typed behavior `698fad4a`)。

## 冻结边界(范围外)

- 不改敌人基础数值、伤害公式、掉落、成长、存档 schema/saveVersion。
- 不改鼠标落点、guardian ward、vulnerability、survive 胜负语义。
- 不做 Q/R 正式内容替换;不删 legacy fixture fallback(固定参数仅供隔离
  fixture,production 走真实技能)。
- 不重构 GameRepository、不清旧 3v3、不做 UI 美化/无关重构。
- Dart 不散写新玩法数值:蓄力/踉跄 tick 数与减防幅度全部预解析自
  `numbers.yaml combat.boss_charge`(既有段,零新增字段);玩家可见文案进
  `data/skills.yaml`。
- 未支持的 geometry/effect/组合继续 fail-closed,不放宽成任意
  powerSkill/aoe。

## 设计决策

### D1 · Q/R 与既有 canInterrupt 技如何进入 break 契约(本批拍点)

事实底座:
- 旧引擎破招语义(`default_ground_strategy.dart`):`canInterrupt` 技命中
  蓄力中目标 → 清蓄力 + 招牌技上 CD(`max(cooldownTurns,1)`)+ 踉跄
  `default_stagger_ticks` 拍 + 踉跄期防御率 ×(1 - `stagger_defense_down`)
  (加深部分来自 per-skill 熟练度,封顶 `interrupt_power_cap`);踉跄/蓄力中
  单位跳过行动;蓄力倒计时逐行动递减,归零当拍释放 `chargingSkill`;
  阶段 `chargeCounter` 进阶即推入蓄力,蓄招 = 该阶段解锁招里
  powerMultiplier 最高者,解锁招为空则 no-op。
- Phase 0A 现状:reducer 已有 boss phase 运行态;Q/R typed behavior 已落
  `damage/pull/stagger`,`break` 仅 schema 可解析、binding 主动拒绝;
  玩家破招槽(第七键)不在已冻结的 0A 数字 1–6 契约内;三把 legacy 破招技
  (破势/截影/拂脉)位于破招槽,当前无任何 0A 输入通道。

**决策(最小、可审计、fail-closed):**

1. reducer 的破招状态迁移**只认 typed `breakPower`**(intent 携带的
   `points` 载荷),不读 `canInterrupt` 标志、不按技能名称/描述猜测。
2. 过渡 R(`skill_phase0a_clear`)补 break 行为(effects 追加
   `{ type: break, points: 1 }`,描述同步补「断蓄力」语义),binding 的
   clear 允许集从 `{damage, stagger}` 放宽为 `{damage, stagger, break}`
   (仍精确集匹配,其余组合照旧 fail-closed)。Q 保持 `{pull}` 精确集,
   拒绝 break——Q/R 分工不变,符合灰盒冻结目标「Q/R 可参与破招」由 R 承担。
3. legacy canInterrupt 技**契约门口敞开、本批不入场**:数字技能 binding 的
   fail-closed 检查从「canInterrupt 一律拒绝」细化为「canInterrupt 且无
   phase0aBehavior.break 才拒绝」;带 typed break 的技能经数字槽进入时,
   input adapter 把 `points` 透传进 `Phase0aSkillIntent.breakPower`,reducer
   同一迁移消费。三把 legacy 破招技没有 behavior、且位于未接线的破招槽,
   保持被 binding 大声拒绝(不静默丢机制),随正式内容替换批(或破招槽
   输入切片)沿同一 typed 契约入场。不给它们伪造 radial geometry 假契约。
4. `points` 语义:本批为「该命中具备破招资格」的 typed 载荷,踉跄窗口/减防
   幅度统一取 `boss_charge` 基础值(与 legacy 无熟练度加成的基础层等价);
   按 points 区分窗口长短属未来内容决策,不在本批发明新数值公式,留残留风险。
   熟练度 `interrupt_power_pct` 加深(波A)随破招槽/正式内容批再迁;基础值
   0.3 < `interrupt_power_cap` 0.5,红线不破。

### D2 · 蓄力运行态模型(不可变可回放)

`Phase0aActor` 新增字段(全部进 `==`/`hashCode`;默认值走命名 const 守
source contract 禁数值默认值字面量):

- 静态预解析(application 注入,reducer 不回查仓库):
  - `chargeCast: Phase0aChargeCast?` — 顶层 chargeSkillId 招牌技的施放参数
    (SkillDef + range/halfArc/effectRadius/cooldownSeconds/
    actionCooldownSeconds);null = 无顶层蓄力。
  - `phaseChargeCasts: List<Phase0aChargeCast?>` — 按阶段下标对齐
    bossPhases;`chargeCounter` 且解锁招非空的阶段存最高 powerMultiplier
    解锁招,其余为 null;无阶段 = 空表。
  - `chargeTicksTotal` / `staggerTicksTotal` — 预解析自
    `numbers.combat.bossCharge.defaultChargeTicks/defaultStaggerTicks`。
- 运行态:
  - `chargingCast: Phase0aChargeCast?` — 正在蓄力的那一次施放(区分顶层与
    阶段招牌);null = 未蓄力。
  - `chargeTicksRemaining` — >0 = 蓄力倒计时。
  - `staggerTicksRemaining` — >0 = 踉跄剩余拍数。

`Phase0aChargeCast` 为 domain 不可变值对象(model.dart),应用层构造。

### D3 · reducer 状态机(时序)

1. **pre-step**(与普攻/技能 CD 扣减同处,intent 之前):每个敌人——
   踉跄>0:本拍压制(不收任何 intent)并 -1(踉跄优先,对齐 legacy
   「踉跄 pre-step 必须在蓄力判定之前」);否则蓄力>0:本拍压制并 -1,
   归零者登记「本拍尾释放」。
   - 压制语义 = legacy「蓄力/踉跄中跳过行动」:不移动、不普攻、不放技能。
   - 总时长对齐 legacy:蓄力 N 拍 = 第 N 拍尾释放;踉跄 N 拍 = 压制 N 拍。
2. **intent 结算**:被压制 actor 的一切 intent 直接拒绝(reducer 权威,
   AI 已停发双保险)。`Phase0aEnemySkillIntent` 分支:
   `skill.id == actor.chargeCast.skill.id` → 改走「起手蓄力」(校验参数合法、
   该技 CD 归零、真气足够;发 `Phase0aBossChargeStarted`;本拍无伤害、不上
   CD、不耗真气——真气在释放时结算,对齐 legacy),绝不直接释放;顶层招牌
   技由此旁路 `unlockedEnemySkillIds` 门(charge profile 即唯一闸门)。
3. **阶段进阶**(`_advanceBossPhases`):进入阶段 i 且 mechanic ==
   chargeCounter 且 `phaseChargeCasts[i]` 非 null → 置 chargingCast +
   倒计时并发 ChargeStarted;已有蓄力则覆盖(一击跨多阈值以最后阶段为准,
   对齐 legacy `_advancePhases` 覆写);解锁招为空 = no-op。
4. **拍尾释放**(按敌人 id 稳定序):登记对象仍存活且 chargingCast 仍在
   (未被破招)→ 走既有敌方技能结算路径(`Phase0aEnemySkillDamageResolver`
   → `DamageCalculator`,single/aoe 按 SkillDef.targetType),写
   `enemySkillCooldowns[skill.id] = cast.cooldownSeconds`、结算
   `skill.qiDelta`、`attackCooldownRemaining = cast.actionCooldownSeconds`、
   清 chargingCast。无合法目标 → 蓄力散逸(无事件无 CD,对齐 intent 分支
   `targets.isEmpty` 口径)。释放仅一次(释放即清 cast)。
5. **破招迁移**:`Phase0aClearIntent` / `Phase0aSkillIntent` 携带
   `breakPower > 0` 时,逐目标:命中(`isHit`)、目标为存活敌人、
   `chargeTicksRemaining > 0` → 清蓄力(chargingCast=null、计数归零)+
   `staggerTicksRemaining = staggerTicksTotal` +
   `enemySkillCooldowns[招牌技] = cast.cooldownSeconds`(为 0 时回落一个
   敌行动拍 = legacy `max(cooldownTurns,1)` 等价)+ 发
   `Phase0aBossChargeInterrupted`。闪避/非蓄力/目标死亡 → 无迁移(伤害照常)。
   gather 分支不带 breakPower 通道(Q 契约不变)。
6. **踉跄减防**:`Phase0aDamageResolver.resolve` /
   `Phase0aEnemySkillDamageResolver.resolveEnemySkill` 增加可选
   `defenderStaggered`(默认 false,不破既有 fixture):reducer 按目标
   `staggerTicksRemaining > 0` 传入;production adapter 把守方防御率乘
   `(1 - numbers.combat.bossCharge.staggerDefenseDown)` 后喂既有
   `DamageCalculator.calculateResolved`——公式唯一真相源不破,reducer 不写
   数值。

### D4 · 敌 AI 与装配

- `Phase0aEnemyAiAdapter`:蓄力/踉跄中敌人不产任何 intent;`_pickSkill` 对
  `chargeCast.skill.id` 放开 unlock 门(CD/真气/参数门保留)。
- mapper 预解析:顶层 chargeSkillId 从 `snapshot.availableSkills` 取
  SkillDef(loader 红线已保 ∈ skillIds,缺则 fail-fast);施放参数沿阶段
  技能绑定口径(range/arc = arena 敌攻参数,effectRadius = 同 range,
  cooldownSeconds = cooldownTurns × enemyAttackCooldownSeconds,
  actionCooldownSeconds = enemyAttackCooldownSeconds);`phaseChargeCasts`
  取 `snapshot.bossPhaseUnlockSkills[i]` 最高 powerMultiplier;
  charge/stagger ticks 取 numbers;AI 绑定表追加深层 charge skill binding。
- 玩家侧:clear binding 暴露 `breakPower`(break effect points),input
  adapter 透传进 ClearIntent;numeric binding 对带 typed break 的技能放行并
  透传 points;legacy fixture fallback(无 binding)breakPower=0 语义不变。

### D5 · manifest 与消费面

- `_enemyTeamSkipReason` 的 phase/charge 条件改为「mechanic 支持性」检查:
  穷尽 switch 表达式枚举 `BossPhaseMechanic`(当前唯一值 chargeCounter 已
  消费 → 通过),未来新增枚举值 = 编译错误 = 强制 fail-closed 决策;
  顶层 chargeSkillId 不再触发 skip;cycleBossPhases 在 0A 装配恒为
  cycle-1(主线灰度门限一周目、mapper 无 cycle 参数)下为惰性覆盖,不再
  触发 skip(与 manifest 描述「cycle-1 语义是否已消费」一致)。
- 预期:24 条 → eligible(主线 73→92、塔 41→46);skip 35→11 守恒
  (vulnerability 8 + guardian 2 + unsupported_win_condition 1);
  tower_32/42/49 仍按 guardian/vulnerability 优先跳过。
- settlement adapter 与 vfx 穷尽 switch 增补两个新事件 case(settlement 归
  ignore 组;vfx 本批不加特效,蓄力 telegraph 可视化列入残留风险随表现批)。

## 验收标准(§8.2 四类证据)

1. **生产接线证据**:`data/skills.yaml(skill_phase0a_clear break)` →
   `SkillDef.fromYaml` → `Phase0aTacticalSkillBinding` → input adapter
   ClearIntent.breakPower → reducer 破招迁移;
   `EnemyDef.chargeSkillId / bossPhases.onEnterMechanic` →
   `EnemyCombatantSnapshotAssembler` → mapper 预解析 ChargeCast →
   `Phase0aActor` → reducer 蓄力/释放/破招 → headless/settlement。
   真实内容入口:stage_02_05(顶层+阶段双入口)、tower_7(纯阶段入口)。
2. **targeted test 结果**(命令+通过数见恢复点):
   - 新 focused:顶层 charge;phase-enter chargeCounter;未满不出手、完成
     仅一次;起手蓄力不直接释放;蓄力/踉跄压制(移动/普攻/技能全拒);
     break 成功(清蓄力+踉跄+招牌技 CD+事件)/非蓄力 no-op/闪避 no-op;
     踉跄抑制 N 拍与恢复、踉跄期减防传参;招牌技 CD 内不二次蓄力;
     同 seed 回放事件流与末态全等;
     AI 对 chargeCast 的 unlock 门放开与 CD 门保留。
   - 真实内容:stage_02_05 / tower_7 装配断言 + headless 确定性双跑 +
     settlement/headless 事件不丢真实 skill id(招牌技与 R)。
   - manifest:24 条分类变化(0 条 phase/charge skip)+ 其他 skip 守恒
     (11 条:8/2/1)+ tower_32/42/49 原因不变。
   - 回归:既有 boss phase runtime、Q/R typed behavior、reducer guard、
     numeric binding 等全绿;legacy fixture fallback(无 tactical binding)
     行为零变化。
3. **红线影响说明**:不触数值硬红线(伤害经唯一 DamageCalculator;招牌技
   为既有技能,倍率已在 schema ≤8000 内;踉跄减防 0.3 < cap 0.5,减伤方向
   不膨胀数字);不触三系锁死/在线=离线(headless 与真人同 reducer 同
   intent)/反主流清单;文案数值不硬编码(ticks/减防全部 numbers.yaml,
   break 描述进 skills.yaml)。
4. **残留风险**:guardian ward、vulnerability、survive 仍 skipped;
   legacy 三把破招技未入场(破招槽未接线,等正式内容替换/输入切片);
   points 差异化窗口与熟练度 interrupt 加深未迁;蓄力 telegraph 表现层
   VFX 未接;六人主观 Gate/Windows Gate 未触发;bot 不等真人。

## 任务切片

1. 计划 + focused 红测(reducer/AI 契约)。
2. domain:model(ChargeCast/actor 字段)、events(2 新事件)、intent
   (breakPower)、reducer(pre-step/起手/阶段蓄力/拍尾释放/破招/减防传参)。
3. application:mapper 预解析、AI adapter、damage adapter 减防、
   tactical/numeric binding。
4. YAML(R break+描述)、manifest 分类、settlement/vfx switch 增补。
5. 真实内容接线测 + manifest/matrix/diagnostic 计数更新 + 既有测试翻绿。
6. dart format、定向、analyze、全量一次;diff 审查;恢复点;`[READY]`。

## 当前恢复点

- 状态:完成,待 `[READY]` 合入。基线 main `19ff7879`(Q/R 批 `698fad4a` 之上)。
- 生产接线入口:
  - 蓄力:`data/stages.yaml|towers.yaml EnemyDef.chargeSkillId /
    bossPhases.onEnterMechanic: chargeCounter` →
    `EnemyCombatantSnapshotAssembler`(chargeSkillId/bossPhases/
    bossPhaseUnlockSkills 已解析)→ `Phase0aStageContentMapper`
    (`_topLevelChargeCast`/`_phaseChargeCasts`/`_chargeCast` 预解析 +
    `_enemyPhaseSkillBindings` 纳入招牌技)→ `Phase0aActor`
    (chargeCast/phaseChargeCasts/staggerTicksTotal/运行态三字段)→
    reducer(起手/拍尾释放/阶段入口)→ `Phase0aBossChargeStarted` /
    `Phase0aEnemySkillStarted` 事件 → headless/settlement。
  - 破招:`data/skills.yaml skill_phase0a_clear` 增 `{ type: break,
    points: 1 }` → `SkillDef.fromYaml` → `Phase0aTacticalSkillBinding`
    (clear 允许集 {damage,stagger,break},`breakPower` getter)→
    `Phase0aPlayerInputAdapter`(ClearIntent.breakPower;数字槽同经
    `Phase0aNumericSkillBinding.breakPower`)→ reducer
    `_maybeApplyChargeBreak`(唯一破招迁移)→ `Phase0aBossChargeInterrupted`。
  - 踉跄减防:reducer `defenderStaggered` 传参 →
    `Phase0aDamageCalculatorAdapter` 读
    `numbers.combat.bossCharge.staggerDefenseDown` 乘 `(1-x)` 后喂唯一
    `DamageCalculator.calculateResolved`。
- 命令与通过数(本会话实测):
  - focused `phase0a_charge_interrupt_test.dart` 12/12;
  - 真内容接线 `phase0a_charge_production_wiring_test.dart` 3/3
    (stage_02_05 双入口蓄力+双招牌真实释放+确定性回放;tower_7 纯阶段
    入口蓄力+释放+回放;装配断言含 breakPower>0);
  - phase0a 全领域定向(domain/application/presentation/debug fixture/
    mainline wiring/behavior/manifest/matrix)339/339;
  - 生产预检 diagnostic:manifest 149 / eligible 138(+24)/ skipped 11
    (vulnerability 8 + guardian 2 + win_condition 1 守恒)/ 414 局
    58 胜 356 负 0 timeout / maxDamage 2044;
  - `dart format` 7 文件重排;`flutter analyze --no-pub lib test`
    No issues found!;最终全量 `flutter test --no-pub` **5300 pass / 0 fail**
    (= 上批基线 5285 + focused 12 + 接线 3 逐值吻合)。
- 红线:伤害唯一走 DamageCalculator(招牌技经既有 enemy skill 路径,零公式
  复制);蓄力/踉跄 tick 数与减防幅度全部预解析自
  `numbers.combat.boss_charge`(yaml 零新增字段);三系锁死/在线=离线/
  反主流清单零触碰;Dart 无新增中文玩家文案(仅开发诊断串,沿既有体例)、
  无散写玩法数值、无 debugPrint;`git diff --check` 通过。
- 残留风险:
  1. guardian ward / vulnerability / survive 胜负仍 skipped(11 条),
     未伪报 eligible;
  2. legacy 三把破招技(破势/截影/拂脉)未入场:位于未接线的破招槽且无
     typed behavior,binding 大声拒绝中;随正式内容替换批或破招槽输入切片
     沿同一 `breakPower` 契约入场;
  3. `break.points` 当前为破招资格载荷,窗口/减防统一基础值;按 points
     差异化窗口与熟练度 `interrupt_power_pct` 加深未迁(留内容批);
  4. 蓄力 telegraph 表现层 VFX 未接(事件已发射,随表现批);
  5. 六人主观 Gate / Windows 实机 Gate 未触发;bot 不等真人。
- 阻塞项:无。
