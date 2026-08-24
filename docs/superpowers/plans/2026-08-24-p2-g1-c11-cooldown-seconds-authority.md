# P2 G1 C11B：Phase 0A 冷却秒权威迁移

## 冻结决策

- 用户于 2026-08-24 批准 G1 审计的推荐方案。
- 玩家数字键技能：将当前 `cooldownTurns × 0.55s` 物化到
  `SkillDef.cooldownSeconds`。既有 Q/R tactical 真实值 5s/8s 保持。
- 敌方阶段技/蓄力技：将当前 `cooldownTurns × 1.0s` 物化到
  `SkillDef.phase0aEnemyCooldownSeconds`。同一技能可同时拥有玩家与敌方两个不同的角色值。
- Phase 0A production mapper 三处只读秒字段，不再读取或乘算
  `cooldownTurns`。攻击间隔今后可独立调整，不隐式改动技能 CD。

## 白名单

- `lib/data/defs/skill_def.dart`
- `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`
- `lib/shared/battle_shared/enemy_combatant_snapshot_assembler.dart`
- `data/skills.yaml`
- `data/encounter_skills.yaml`
- C11 直接测试与本计划。

## 验证合同

1. 261 条生产技能的玩家/敌方秒值均显式存在且有限非负。
2. Q/R 保持 5s/8s；其余玩家技能精确等于旧 `turns × 0.55`。
3. 敌方秒值精确等于旧 `turns × 1.0`。
4. 代表数字键、顶层蓄力、阶段蓄力与 enemy AI binding 均传入对应秒字段。
5. `phase0a_stage_content_mapper.dart` 对 `cooldownTurns` 零命中。
6. 定向回归、scoped analyze、format、`git diff --check` 通过。

## 恢复点

- base：`39ed522804295dfd6b93dbbd867f152d2b7d2ed2`。
- branch：`codex/phase2-g1-c11-cooldown-seconds-authority-20260824`。
- 当前：实现、定向验证与独立只读 diff 审查完成，待提交。

## 完成证据

- 红测先精确失败于 `phase0aEnemyCooldownSeconds` 字段不存在。
- 生产数据：`skills.yaml` 221/221、`encounter_skills.yaml` 40/40
  均有玩家/敌方两个 seconds 字段；机械对比证明 261 条旧记录除新字段外零漂移。
- C11 核心契约与代表数字键/蓄力生产链：13/13。
- mapper、脆弱窗口、主线/塔/扫荡/心魔/断魂庄扩展回归：53/53。
- `test/features/battle/application/phase0a` + `test/data`：1093/1093。
- 变更 Dart/测试 scoped analyze：0 issue；`git diff --check`：0。
- 独立只读审查：P0/P1=0，冻结方案、三处 mapper 读方、loader
  边界与 clone 传值均确认。既有 readable-first-clear clone 尚未完整复制
  `mountDeferred/qiDrainPct/phase0aBehavior` 被记为非 C11 引入的 P2，不在
  G2 唯一关键路径中扩面修复。
