# M3 产品合同重定向与单段候选收口审计

## 结论

M3 不能按旧方案直接施工。旧方案要求剑“直刺 → 横扫 → 进步斩”及五武器普攻链；但用户随后因第三段拉扯和抽搐明确要求取消三段攻击，并批准单段平滑远程普攻。当前 main 正确执行后者：生产 player mapping 的 `basicAttackChain` 为 `null`，连续命中没有链段身份或攻击位移，玩家主动防御只保留 `Space` 闪避。

因此，恢复 `swordBasicAttackChain`、接入 parked timeline 或重新开放 shield/parry 都属于产品回退，不是 M3 推进。M3 当前为 `BLOCKED`，不是代码故障。

## 实时生产基线

| 子门 | 当前状态 | 当前证据 | 判断 |
|---|---:|---|---|
| 五武器身份 | `0/5` | `WeaponType` 只存在于 parked `basic_attack_chain.dart`；仅定义剑三段链；生产 mapping 不注入 chain；`EquipmentDef` 只有通用 `weapon` slot，没有五类武器字段 | 未形成可由实际装备选择的生产身份 |
| 三特性 modifier | `0/3` | `combat_modifiers.dart` 定义刚猛/灵巧/阴柔及纯函数；`lib/` 内没有 `applyCombatModifiers` 调用方 | 只有领域候选，无生产消费者 |
| 动作 timeline | `0/1` | `action_timeline.dart` 有领域实现；`lib/` 内没有 `ActionTimeline(...)` 构造方 | parked，不可当生产节奏 |
| 三种 Bot 战术 | `3/3` 工程已接 | `sweep_screen.dart` 通过 `Phase0aBotTacticPolicy.forTactic` 选择，`sweep_unit.dart` 把 policy 送入同一 headless runner | 可复用，不需重做 |
| Boss 阶段/破绽响应 | 核心已接，M3 场景门未闭 | snapshot assembler、stage mapper、reducer、VFX 均有 production path；但五武器画像不存在，无法完成每武器三场矩阵 | 保留现有实现，后续补画像与漏洞门 |
| 玩家防御 | 后续产品合同覆盖旧 M3 | 生产键盘仅 `Space => dodge`；shield/parry 仅留底层领域能力，无玩家入口 | 不得按旧 M3 重新开放 |
| 每武器三场画像 | `0/15` | 缺五武器生产身份，无法从真实装备进入五种画像 | 阻断 M3 Gate |

补充 targeted 复核在该 worktree 完成 build_runner 后执行：玩家 Bot policy、sweep 真实选择/同核 runner、单段远程普攻 checkpoint 守卫共 `24/24 PASS`。这只确认表中已接能力与禁止回退项，不填充五武器 `0/5` 或三场画像 `0/15`。

## 冲突证据

- 旧权威方案 `/Users/a10506/Desktop/二阶段优化方案.md` §3.2 与 M3：五武器普攻链，剑为三段链。
- 后续批准实现 `b653852e28607129b52fa485d1869857c17072c5`：取消三段普攻并消除移动键提示音。
- READY `3e589284` 及契约迁移 `p2-m2-combat-input-simplify-20260830.yaml`：生产与 debug 均不注入 chain，单段远程掌风无攻击位移，shield/parry/Z 入口删除。
- 当前生产守卫 `phase0a_stage_content_mapper_test.dart`：`mapping.playerAdapter.basicAttackChain` 为 `null`。
- 当前 checkpoint 守卫 `phase0a_mainline_sword_displacement_checkpoint_test.dart`：单段远程攻击不移动、不触发 x=520 checkpoint。

## 建议的新 M3 合同

推荐保留“五种武器身份”，但每种都采用单段、可持续按住、无攻击位移的基础攻击；身份差异只来自可读的弹道/命中几何、节奏和技能修饰，不再来自三段链或前冲。shield/parry 不恢复，`Space` 闪避保持唯一玩家防御入口。

该路线需要一次明确授权后再实施：

1. 把 M3 产品口径从“五种三段链”改为“五种单段武器画像”。
2. 为非持久化 `EquipmentDef`/装备 YAML 增加明确武器类别来源，禁止按名称猜测或在 Dart 硬编码 ID。
3. 批准五种单段画像的范围、几何、节奏和表现候选；现有 `TUNE-WEAPON-*` 三段 timeline 值不能直接复用。
4. 允许同步更新二阶段方案与 decision registry；不改 Isar/saveVersion、玩家属性、奖励、经济和现有装备基础数值。

若不保留五武器系统，则需要另一项产品决定：正式删除旧 M3 的五武器分母，改以主动技能/build 深度作为 M3。未获选择前不得自行改分母。

## 状态

- M3 工程 Gate：`0/1 BLOCKED`
- 五武器生产画像：`0/5`
- 真人目检：挂账
- Phase 2 正式里程碑：仍为 `1/10`
- M4/M7/M8/M9：不因本审计开启或通过

## 授权后的结构交付

用户已授权保留五类武器身份，并把基础普攻合同统一为“单段、按住连发、无攻击位移”。本候选据此完成以下结构门，但没有选择或写入正式战斗数值：

- 新增唯一非持久化 `WeaponArchetype`：`sword`、`heavy`、`flexible`、`dual`、`hidden`。
- `EquipmentDef.fromYaml` 对武器缺类别、非武器携带类别均 fail closed；运行时不按名称、ID、流派或属性猜测类别。
- `data/equipment.yaml` 的 37 件生产武器全部显式分类：剑 8、重兵 7、软兵 7、双持 7、暗器 8。
- 实际装备类别贯通 `EquipmentDef -> CombatantSnapshot -> Phase0aPlayerInputAdapter`；复制、心魔镜像与生产 stage mapper 均保留该字段。
- 无装备时保持既有掌风基线；多武器、悬空 def 或 slot 不一致继续 fail closed。
- 生产 mapper 仍保持 `basicAttackChain == null`，没有恢复三段链、进步斩、攻击位移、shield/parry 或 `Z`。

## 五类候选而非生产值

候选值及 `5 x 3` reducer 模拟在 `docs/spec/phase2_m3_single_attack_weapon_candidates_20260901.md`。15/15 受控场景均完成，且每拍最多命中 1 个目标、无链段身份、无玩家位移、一次出手只结算一次候选产气。

这些结果只证明五类差异可以在同一单段 reducer 合同中成立，不证明正式清杂、精英、Boss 画像已通过。候选尚未写入生产配置或表现层；正式分母仍为 `0/5` 与 `0/15`。

## 破坏证红

以下四个变异均在提交后的候选上执行，每次只改一个方向、得到精确 `1` 个失败，再用反向补丁原样还原：

1. 删除一件生产武器的 `weaponArchetype`：仓库全量分类合同变红。
2. 删除快照 builder 的类别赋值：实际装备来源合同变红。
3. 删除生产 mapper 的类别透传：生产适配器接线合同变红。
4. 把重兵候选 `maxTargets` 从 `1` 改为 `2`：单次最多一目标合同变红。

这四项分别证明 YAML schema、实际装备来源、生产 mapper 与候选单目标红线不是恒真断言；所有变异均已精确还原。

## 验证

- 官方应用分析：`flutter analyze --no-pub lib test tool`，`0 issue`。
- 整仓格式：`dart format .`，`1711 files / 0 changed`。
- 联合定向：结构、候选、M2 防回退、远征与百科 fixture 共 `125/125 PASS`。
- 首轮全量：`5863 pass / 2 fail`；两项均为新 fail-closed 合同暴露的旧测试 fixture 缺口——远征使用不存在的假装备 def，百科临时武器缺类别。
- fixture 修正：远征改用真实生产武器 def；百科的五类临时武器显式写 `weaponArchetype: sword`。没有放松生产守卫。
- 修正后完整全量：`5868/5868 PASS`，退出码 `0`，原始 reporter 尾行 `All tests passed!`，`[E]` 为 `0`。
- `git diff --check`：通过；未修改 `numbers.yaml`、Isar、版本号、玩家数值、技能、奖励、经济或解锁。

## 候选阶段收口判断（已被后续授权覆盖）

- 当时分支定位为 `BLOCKED` 候选，等待产品选择正式几何、节奏与表现值。
- 当时 M3 工程 Gate 为 `0/1 BLOCKED`；五类正式生产画像 `0/5`；正式三场矩阵 `0/15`。
- 下节记录后续授权与正式生产推进；本节只保留候选阶段的历史判断。

## 正式生产画像推进（2026-09-01 夜间）

用户随后按推荐 M3 合同授权自主选择生产画像。实现没有复用旧三段 timeline，也没有修改技能伤害公式；而是在 `data/combat/player_attack_profiles.yaml` 中对既有 Phase 0A 基线施加非持久化相对因子：

| 武器 | 射程因子 | 半角因子 | 冷却因子 | 姿态因子 | 单次目标 | 攻击位移 | 表现身份 |
|---|---:|---:|---:|---:|---:|---:|---|
| 剑 | 1.00 | 0.75 | 1.00 | 1.00 | 1 | 0 | 窄直墨锋 |
| 重兵 | 0.82 | 1.35 | 1.35 | 1.60 | 1 | 0 | 宽厚墨压 |
| 软兵 | 1.15 | 1.10 | 1.12 | 1.15 | 1 | 0 | 长弧墨带 |
| 双持 | 0.88 | 0.88 | 0.78 | 0.80 | 1 | 0 | 双线快击 |
| 暗器 | 1.25 | 0.50 | 1.05 | 0.90 | 1 | 0 | 远窄点射 |

生产清杂/精英/Boss Gate 不再使用候选自造 damage resolver：测试从真实 `GameRepository` 读取画像，经过 production mapper、`Phase0aBattleSnapshotFactory`、`Phase0aDamageCalculatorAdapter` 与 reducer；五类 × 三流派 × 三场景共 45 格首轮全部胜利。每拍最多 1 次命中、玩家位置不变、一次已接受普攻只结算一次正式 `qiDelta`，且武器与流派身份贯通事件和 VFX。

这里的三流派消费沿用真实伤害计算器已有的刚猛/灵巧/阴柔克制与技能绑定；没有把 parked `applyCombatModifiers` 伪报为生产消费者。真人桌面可读性、节奏与手感仍按用户要求挂账，不能由 45 格自动矩阵代签。

### 正式画像破坏证红与最终回归

在生产画像提交 `9ae5f78d` 上逐项施加四个单变量破坏，每次运行对应精确用例后都得到 `0 pass / 1 fail`，随后用精确反向补丁还原，并确认 worktree 与提交完全一致：

1. mapper 不再消费画像射程因子：五类实际武器生产修饰合同红 1 项，重兵实际值从期望 `344.4` 回退为基线 `420.0`。
2. 重兵 `max_targets` 从 `1` 改为 `2`：生产 catalog 加载合同红 1 项，命中单目标守卫。
3. 暗器 `attack_displacement` 从 `0.0` 改为 `1.0`：生产 catalog 加载合同红 1 项，命中零攻击位移守卫。
4. VFX controller 不再复制武器/流派身份：五类 × 三流派事件到 VFX 合同红 1 项，实际身份变为 `null`。

还原后的最终结果：

- 八个独立定向文件累计 `128/128 PASS`；其中一个参数化生产矩阵测试实际遍历 `5 × 3 × 3 = 45` 格。
- `dart format .`：`1715 files / 0 changed`。
- `flutter analyze --no-pub lib test tool`：`0 issue`。
- 锁保护 `flutter test --no-pub`：`5874/5874 PASS`，退出码 `0`，reporter 尾行 `All tests passed!`，`[E]` 为 `0`。
- 测试删除迁移门：`expect 删 0 / 增 61；用例删 1 / 增 14；登记 1`，`PASS`。旧 Gate 的零删除检查仍会报告已登记的 4 行删除，必须与迁移门联合判读。

工程画像因此可进入 main 集成；真人桌面手感仍是 `deferred_by_user`，正式 M3 与 Phase 2 总里程碑不由本自动证据代签。
