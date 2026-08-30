# M2 单段远程普攻与移动输入静音计划

## 结果合同

- 单一目标：响应用户在 `stage_01_02` 的真人反馈，取消玩家生产路径的
  直刺→横扫→进步斩三段链，改为无前冲、无链段切换的单段远程普攻，
  并消除长按移动键时 macOS 连续提示音。
- 验收分母：生产和 debug player mapping 均不注入 basic attack chain、
  geometry registry 或 arena bounds；每次被 reducer 接受的玩家普攻都没有
  `basicAttackSegment` 且不附加攻击位移；近距和远距命中均只产生同一种
  掌风轨迹；macOS 的 `KeyRepeatEvent` 被战斗屏消费但不重复入队。
- 基线：`ef6a6802dcc61bf4cbf2bb9a9463010e5004192c`；分支
  `codex/p2-m2-combat-input-simplify-20260830`；独立 worktree
  `/Users/a10506/.codex/worktrees/p2-m2-combat-input-simplify-20260830`。
- 当前候选前态：`456c247f5649152e3b5863f231b0d50a9408c96c` 虽完成前一轮
  镜头与防御输入收敛，但用户真人复验仍感到第三段拉扯和抽搐，故不接受。
- 预期增量：交付新的 M2 真人复验候选；G2 继续 FAIL，用户在 1-2
  重新试玩前不改判；M3/M4 不启动。
- 成本边界：单 WIP，不改 schema/存档/checkpoint 移动归因守卫、
  `strings.dart`、现有 `numbers.yaml` 数值或既有 range/cooldown；不合并、
  不 push。

## 实施选择

1. 生产和 debug player adapter 不再注入 `swordBasicAttackChain`，沿用已有
   标量射程、角度和冷却；底层链配置保留为 parked/historical 能力，不再有
   玩家生产消费者。
2. 单段普攻不产生 `basicAttackSegment`、advance 或截停位移；普通移动仍按
   held input 每个 fixed tick 采样，攻击与移动同拍只产生正常移动量。
3. 玩家命中无论距离均使用已有 `palmTrail` 表现，形成稳定、可辨认的单一
   远程攻击，不新增美术或数值。
4. `W/A/S/D/J` 的 macOS `KeyRepeatEvent` 返回 handled，阻止未处理键事件
   冒泡到系统产生“滴滴”提示音；重复事件不入队，按住状态与松键语义不变。
5. 前一候选已经完成的仅 `Space` 闪避、移除 `E/F/Z` 玩家防御入口继续保留。

## 当前恢复点

- 实现提交：`b653852e28607129b52fa485d1869857c17072c5`
  （`取消三段普攻并消除移动键提示音`），worktree 干净。
- 初始 RED：测试先改后实测 6 项失败，分别覆盖三段仍被 production mapping
  注入、进步斩仍产生 120 位移、checkpoint 用例仍出现进步斩链段、
  macOS repeat 未消费及两项真实 BattleScreen 链段/VFX 行为。
- 实现路线校验：曾尝试保留单一 `sword_thrust` 链段，但 Chapter 1
  `stage_01_05` headless 战败且 25 seeds 从 25/25 退化为 20/25，已否决且
  未提交；最终采用完全不注入 chain 的现有 scalar attack 路径。
- 已验证：直接相关 101 项通过；扩展 Phase0A、debug 与 mainline 相邻组
  `+1417: All tests passed!`；`flutter analyze --no-pub lib test` 为
  `No issues found!`；`git diff --check` 通过。
- 双向破坏证红：临时恢复 production `swordBasicAttackChain`，生产映射守卫
  1 项失败；临时把 movement `KeyRepeatEvent` 改回 ignored，macOS 输入守卫
  1 项失败。两向均已精确反向还原，worktree 回到提交态。
- 待完成：更新本次契约迁移登记，整仓 format、持锁全量、migration gate、
  总 gate 与外置 receipt，然后从本 worktree 启动 macOS 候选供用户复验。
- 尚未结论：用户手感、G2、合并、push、CI 均未通过。
