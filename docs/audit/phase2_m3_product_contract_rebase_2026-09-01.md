# M3 产品合同重定向审计

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
