# M2 屏外威胁提示计划

## 目标

在真实 `Phase0aBattleScreen` 为已离开视口的关键威胁提供可读、克制的边缘提示，不为普通追路杂兵制造满屏箭头。

## 分支

`codex/p2-m2-offscreen-indicator-20260829`，唯一基线 `348a74af9ed53d848697c0282760ae636556a4f1`。

## 已冻结范围

- 权威方案 `§16.5` (`/Users/a10506/Desktop/二阶段优化方案.md:778-780`) 规定：只为冲锋、远程蓄力、支援单位和 Boss 显示；同时最多三个方向；包含方向、攻击类型和临近程度。
- `§21.4` (`:1420-1428`) 规定 1280×720 / 1440×900、8/16/24 活跃单位、最多三方向、无高饱和 Material 矩形感的视觉验收。
- 不改数值、schema、存档、战斗机制、文案或键位语义；不触碰禁区文件。

## 已拍板的表现方案

用户于 2026-08-29 回答“按推荐方案执行”，以下整套规则已获授权：

1. 边缘形态：使用无文字、非矩形的水墨尖标，尖端指向威胁；Boss 用克制绛红，其他类型用墨/青。
2. 类型与临近：在尖标内用简单几何纹样区分冲锋/远程蓄力/支援/Boss，不新增玩家文案；临近程度用三档透明度与脉冲强度表达。
3. 三方向取舍：固定优先级 Boss → 已进入蓄力/冲锋的高影响威胁 → 支援 → 其他远程蓄力；同级按临近程度、稳定 actor id 排序，同一方向聚合为一个提示。

## 验收标准

- 生产接线：只从真实 battle state/actor 运行态派生，在 `Phase0aBattleScreen` 实际 Stack 渲染；不使用手设屏外布尔值的孤立假组件代替。
- 真实双视口和 8/16/24 活跃单位下最多三方向，HUD 不遮挡、无 overflow，威胁进入/离开屏幕时提示正确出现/消失。
- 实现 commit 后两向破坏证红，逐文件 targeted、analyze、整仓 format、持锁全量、diff check、receipt 与持锁 gate 通过；合并/push 后核 CI `conclusion` 与 `headSha`。
- 残留风险：最终视觉手感仍属 G2 用户真人验收，自动测试不替代主观签字。

## 开工后发现的架构实况偏差

视觉方案获批后按宪法 §2.2 / §2.6 重新定位生产路径，发现当前代码无法表达已冻结验收语义：

1. `Phase0aStage.worldToScreen` 在
   `lib/features/battle/presentation/phase0a/phase0a_stage.dart:30-48`
   把所有世界锚点 clamp 到 `safeRect`；`Phase0aBattleScreen` 在
   `phase0a_battle_screen.dart:848-894` 直接使用该结果摆放 actor。当前战场
   没有 camera/window，合法 arena actor 不会按几何意义离开视口。
2. `Phase0aActor` 在
   `lib/features/battle/domain/phase0a/phase0a_combat_model.dart:141-245`
   只有 `isBoss` 与 Boss `chargingCast` 等状态；没有统一的“远程蓄力中”、
   “支援角色”或当前 `AttackTokenKind` 运行态，不能从 battle state 诚实区分
   四种提示纹样。
3. typed token 元数据只存于
   `lib/features/mainline/application/phase0a_mainline_production_encounter_factory.dart:99-152`
   的局部 map，并在 `:200-217` 的 intent mapper 闭包消费，没有进入
   `Phase0aBattleController` / presentation。当前生产
   `data/combat/runtime_bindings.yaml:42-78` 四类行为的 `is_offscreen` 还全部为
   `false`，也不能作为现成的真实可见性来源。
4. 因而现在直接施工只能采用手设 `isOffscreen`、按 actor id 猜角色，或把
   “靠近 arena 边缘”冒充“离开 viewport”；三者均违反本计划“真实 battle
   state/actor 运行态派生”和双向破坏证红的判定。

该偏差命中宪法 §10“方案范围与现有架构存在不可调和冲突”，执行端不得自行
选择新的 camera 语义、运行态合同或数据配置。

## 已拍板的架构路线

用户于 2026-08-29 回答“按推荐执行”，批准 **A（忠实语义）**：先把本单
扩成一个受控纵切——新增 camera-aware
未 clamp 投影/动态可见性，并把已有 typed token kind 与真实 windup 状态通过
只读 presentation snapshot 暴露给 `Phase0aBattleScreen`；不改伤害、AI、
token 分配、schema 或存档。camera 采用已批准的固定规则：可见世界宽高均为
现有 arena 的 75%，中心逐帧跟随玩家并在 arena 边界 clamp，不做缓动；屏外
由未 clamp 脚点投影动态判定。charge/support/Boss 离屏即提示，ranged 仅在
真实 `chargingCast` 期间提示。

静态 `is_offscreen` 近似与顺延路线均未选用。

## 任务切片

1. 已完成：用户拍板表现方案。
2. 已完成：重新定位视口变换、actor 运行态和实际 Stack 消费点；确认架构缺口。
3. 已完成：用户批准 A 与 75% 玩家跟随 camera 规则。
4. 先写真实生产路径红测，再实现候选选择/方向聚合/边缘渲染与双视口验收。
5. 完成双向破坏证红、九步验收、gate、合并、push 和 CI 核验。

## 当前恢复点

- 状态：`[WIP]`。
- 最后完成：已实现 75% 玩家跟随 camera、未 clamp 动态可见性、主线 typed
  token metadata 只读透传、八方向聚合/三方向上限和无文字水墨 painter；真实
  `Phase0aBattleScreen` 在 1280×720 / 1440×900 与 8/16/24 actor 下通过。
- 下一步：提交实现后执行 `remove_implementation` / `force_degenerate_value`
  双向破坏证红，精确还原后进入逐文件 targeted、analyze、整仓 format、持锁全量。
- 已跑验证：fresh worktree 已完成 `libisar.dylib` 拷贝、`flutter pub get`、
  `build_runner`（128 outputs）；新屏外测试 11/11、Stage 7/7、生产工厂 5/5、
  visual roster 12/12、主线 wiring 18/18、整屏 28/28，analyze 0 issue。
- 阻塞项：无；后续如需改变已冻结 camera、威胁分类或视觉规则，重新触发 §10。
