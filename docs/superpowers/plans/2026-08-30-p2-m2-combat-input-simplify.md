# M2 进步斩镜头与防御输入收敛计划

## 结果合同

- 单一目标：修复用户在 `stage_01_02` 反馈的第三段进步斩拉扯、
  近敌截停收尾抽搐，并将玩家侧主动防御收敛为仅 `Space` 闪避。
- 验收分母：生产 `Phase0aBattleScreen` 中进步斩时角色在屏幕上
  有可见前冲；短距离截停全程屏幕脚点不回退；`E/F/Z` 不产生
  防御事件；`Space` 仍产生闪避；HUD 仅显示 `Space 闪避`；
  playerBot 不再使用护盾或化解。
- 基线：`ef6a6802dcc61bf4cbf2bb9a9463010e5004192c`；分支
  `codex/p2-m2-combat-input-simplify-20260830`；独立 worktree
  `/Users/a10506/.codex/worktrees/p2-m2-combat-input-simplify-20260830`。
- 预期增量：交付 M2 手感复验候选；G2 继续 FAIL，用户在 1-2 真人复验
  前不改判；M3/M4 不启动。
- 成本边界：单 WIP，不改 schema/存档/现有 `numbers.yaml` 数值，
  不拆 checkpoint 移动归因守卫；超过约 90 分钟无验收门变化则重评。

## 实施选择

1. 保留 M2 已冻结的直刺→横扫→进步斩三段链与 `advance_distance=120.0`；
   本单不擅自删除三段产品语义。
2. 镜头在玩家渲染坐标周围保留世界空间死区；120 单位进步斩
   主要表现为角色向前，只由镜头消化超出死区的余量。
3. 移除 actor 外层固定 4px 步态偏移，避免短距离截停收尾帧离散回抽。
4. 移除人类玩家 `E/F/Z` 生产输入、守势/化解 HUD 和 bot 的
   shield/parry 选择；保留底层 defense intent/reducer 作为 parked 能力，
   不改 schema 或存档结构。

## 当前恢复点

- 状态：候选验证完成，正在形成最终 `[READY]` tip 并运行 receipt/gate；
  未经用户真人复验，不等于 G2 通过。
- 实现提交：`9029d24d`（`消除进步斩拉扯并精简防御输入`）。
- 初始 RED：实现前实测 8 项失败，包括角色屏幕前冲 `Actual: 0.0`、
  `E/F/Z` 各自仍发出防御事件、两视口 HUD 仍显示三项、bot 仍出 shield。
- 近敌截停 RED：18 世界单位短进步斩在收尾帧从
  `663.74` 回退到 `662.28125`；移除 4px 离散偏移后该用例通过。
- 双向破坏证红：将水平镜头死区临时改为 0，进步斩屏幕前冲守卫
  1 项失败；临时恢复 `Z || Space` 闪避映射，`Z` 禁用守卫 1 项失败。
  两向均已用精确反向补丁还原，worktree 回到提交态。
- 已验证：直接 targeted `+47`；扩展 Phase0A 表现层与主线相邻组
  `+221`；`flutter analyze lib test` 为 `No issues found!`；整仓 format 为
  `1647 files (0 changed)`。
- 持锁全量：`05:17 +5707: All tests passed!`，`[E]` 0，
  `/Users/a10506/.claude/locks/wuxia_full_test.lock` 已精确释放。
- 测试契约迁移：旧 shield/parry/Z/HUD/camera 断言正是本单修改的产品
  语义；已登记 35 条，机器校验为 `expect 删 27 / 增 32`、
  `用例 删 8 / 增 9`，`PASS: test_contract_migration`。
- 已知环境基线：裸 `flutter analyze` 会跨入独立子包
  `tools/phase0minus_probe` 并因其未安装 Flame/子包依赖报 1943 项；
  根应用权威分析边界是 `lib test`。
- 下一步：形成 `[READY]` tip，生成与该 tip 绑定的外置 receipt 并运行
  gate；然后从本 worktree 启动 macOS 应用交用户在 1-2 复验。
- 尚未结论：用户手感、G2、合并、push、CI 均未通过。
