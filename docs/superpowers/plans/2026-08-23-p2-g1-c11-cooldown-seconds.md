# P2 G1 C11A — `cooldownSeconds` 安全迁移

## 目标与范围

本切片建立 `SkillDef.cooldownSeconds` 的 typed、loader 校验边界，并把
Phase 0A Q/R 战术技能迁移到该字段。它不改 reducer、数值配置或 UI。

## 审计结论（2026-08-23）

历史 `cooldownTurns` 在 Phase 0A 的生产读方存在三种不等价语义：

| 读方 | 旧语义 | C11A 处理 |
| --- | --- | --- |
| `phase0a_tactical_skill_binding.dart` | `turns` 直接视作秒 | 已无损迁移；两个实际 Q/R 秒值分别冻结为 5、8。 |
| `phase0a_stage_content_mapper.dart:_numericSkillBindings` | `turns * playerAttackCooldownSeconds`（当前 0.55，但来自运行时配置） | 阻塞：静态秒值会改变手感，待拍板映射规则。 |
| `phase0a_stage_content_mapper.dart:_chargeCast` / `_enemyPhaseSkillBindings` | `turns * enemyAttackCooldownSeconds`（当前 1.0，但来自运行时配置） | 阻塞：与数字键语义不同，不能猜成统一值。 |

因此本批为 C11A，而非把 262 条旧值机械复制为秒：复制没有证明其跨角色/运行时配置等价，且会伪造已经冻结的 tuning 决策。

## 已完成

- `SkillDef.cooldownSeconds` 为显式 typed 字段；负数、非数值、非有限值拒绝。
- 配置了 `phase0aBehavior` 的技能必须提供 `cooldownSeconds`，Q/R 真实配置已补齐。
- `Phase0aTacticalSkillBinding` 只读 `cooldownSeconds`，不再读取 `cooldownTurns`。

## 归零守卫与后续恢复点

**当前状态：C11A 已冻结，未声称全 Phase 0A 归零。** 生产读方归零守卫应在以下三个 mapper 读方完成显式 seconds mapping 后再启用；在此之前启用会把已知未决 tuning 伪装成测试失败。

1. 为数字键、敌方阶段技、敌方蓄力技分别拍板 static seconds 的来源，或把“角色攻击间隔”提升为明确的 seconds 配置合同；
2. 迁移 mapper 三处读方；
3. 加静态/运行测试，断言 `lib/features/battle/application/phase0a/**` 生产代码对 `cooldownTurns` 的读方为零；
4. 再决定何时要求全部 YAML skill 都填写 `cooldownSeconds`，随后退役 `cooldownTurns`。

## 验证

- `flutter analyze lib/data/defs/skill_def.dart lib/features/battle/application/phase0a/phase0a_tactical_skill_binding.dart`
- `flutter test --no-pub test/data/skill_def_p0_test.dart test/data/defs/phase0a_skill_behavior_test.dart test/features/battle/application/phase0a/phase0a_stage_content_mapper_test.dart`

运行结果：前两个 schema/binding 测试通过；本隔离 worktree 缺失既有 Isar
`lib/core/domain/*.g.dart`，因此 mapper 集成测试不能编译。这不是本切片触及的文件，
合并工作区补齐生成文件后应重跑该第三项。
