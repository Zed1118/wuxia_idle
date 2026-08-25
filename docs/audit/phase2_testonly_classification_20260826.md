# Phase 2 仅测试引用文件分类（2026-08-26）

查询基线固定为 `c799b964`；本报告只定性，不将未接线文件改名或重分类以缩小分母。

| 文件 | 档位 | 证据（file:line 或 Gate/决策 ID） | 一句话理由 |
|---|---|---|---|
| `lib/data/validation/combat_catalog_migration_gate.dart` | VALIDATION_ONLY | `P2-G2-L02-COMBAT-CATALOG-MIGRATION-COVERAGE-GATE`；`test/data/phase2/ch1_production_catalog_test.dart:145` | 专用联合迁移覆盖校验器，真实生产 catalog 验收测试消费它，不选择运行路由。 |
| `lib/data/validation/combat_encounter_defeat_projection_mapper.dart` | VALIDATION_ONLY | `P2-M2-V02A-CH1-CANDIDATE-DEFEAT-OBJECTIVE-EXECUTION-MATRIX`；`test/data/phase2/ch1_candidate_defeat_objective_execution_matrix_test.dart:507` | V02A/V02B 候选验收矩阵用它校验显式 defeat projection，生产 factory 未消费该 mapper。 |
| `lib/features/battle/application/phase0a/attack_token_observe_only_observer.dart` | PARKED | `TUNE-ATTACK-TOKEN-01` | observe-only 诊断接缝等待令牌预算定标，决策仍为 `tuning`，不得先行 enforce。 |
| `lib/features/battle/domain/phase0a/action_timeline.dart` | PARKED | `TUNE-WEAPON-TIMELINE-01` | 五武器前摇/生效/收招尚未定标，当前生产仍用 cooldown 即时结算。 |
| `lib/features/battle/domain/phase0a/basic_attack_chain.dart` | PARKED | `M3` | 五类普攻属 M3 武器与战斗深度，该生产批尚未启动。 |
| `lib/features/battle/domain/phase0a/combat_modifiers.dart` | PARKED | `M3` | 三主修特性是 M3 未关闭项，当前只有调用方注入参数的纯合同。 |
| `lib/features/battle/domain/phase0a/posture.dart` | PARKED | `TUNE-POSTURE-01` | 姿态容量、恢复和 Boss 折算仍为 `tuning`，明确保持 pure contract 不接生产。 |
| `lib/features/battle/domain/phase0a/qi_resource.dart` | PARKED | `TUNE-WEAPON-QI-01` | 真气账本等待五武器收支/恢复 policy 定标，当前生产仍以既有 YAML `qiDelta` 为准。 |
| `lib/features/battle/domain/phase0a/status_effects.dart` | PARKED | `M3` | slow/root/internalInjury/poison 固定拍账本是 M3 战斗深度预置合同，尚无 reducer 消费。 |
| `lib/features/mainline/application/mainline_next_stage_runtime_admission.dart` | PARKED | `M2`；`MAINLINE-RUN-01`；`MENTOR-INSIGHT-OCCUPANCY-01` | 连续下一关与听剑占用的组合接缝留给 M2，当前生产协调器未消费它。 |
| `lib/features/mainline/application/mentor_insight_reverse_activity_guard.dart` | PARKED | `M2`；`MENTOR-INSIGHT-OCCUPANCY-01` | 听剑单关占用尚未接入四类真实活动入口，先保留 fail-closed 纯守卫。 |
| `lib/features/mainline/application/mentor_insight_stage_claim_boundary.dart` | PARKED | `M2`；`MENTOR-INSIGHT-CORE-01`；`MENTOR-INSIGHT-RATE-01` | 听剑 claim 边界等待 durable observation 与成长比例/cap 授权，当前不得发放。 |
| `lib/shared/battle_shared/reward_policy.dart` | PARKED | `M6`；`REWARD-POLICY-CORE-01` | M6/U09 的三层奖励与 durable receipt/outbox 尚未关闭，内存 claim guard 不能冒充生产幂等。 |

- 分档实测：WIRED `0`、VALIDATION_ONLY `2`、PARKED `11`、RESIDUE-EXCLUDED `0`，合计 `13`。
- CLAUDE.md §8.4 第①项仍应判 **PARTIAL**；两个验收设施不要求进入玩家路径，但 11 个 PARKED 合同仍未连接。
- 转 PASS 至少需：在对应 Gate/决策解冻后将 11 项逐一接入真实生产路径并通过风险匹配验证；若后续证明某项被替代，须由权威 Gate 明确退役/删除后重审分母，不能靠本表重分类转 PASS。

## 附录：可复跑命令

```bash
# 表格行数与四档计数（输出 13，以及 WIRED=0 / VALIDATION_ONLY=2 / PARKED=11 / RESIDUE-EXCLUDED=0）
awk -F '|' '/^\| `lib\// { n++; k=$3; gsub(/^ +| +$/, "", k); c[k]++ } END { print n; print "WIRED", c["WIRED"]+0; print "VALIDATION_ONLY", c["VALIDATION_ONLY"]+0; print "PARKED", c["PARKED"]+0; print "RESIDUE-EXCLUDED", c["RESIDUE-EXCLUDED"]+0 }' docs/audit/phase2_testonly_classification_20260826.md

# 13 个路径在冻结 commit 全部存在
awk -F '`' '/^\| `lib\// { print $2 }' docs/audit/phase2_testonly_classification_20260826.md | while IFS= read -r f; do git cat-file -e "c799b964:$f" || exit 1; done

# 文件名引用核验：对表中 basename 逐一执行，命中均为 test/ 导入/字符串
for n in combat_catalog_migration_gate.dart combat_encounter_defeat_projection_mapper.dart attack_token_observe_only_observer.dart action_timeline.dart basic_attack_chain.dart combat_modifiers.dart posture.dart qi_resource.dart status_effects.dart mainline_next_stage_runtime_admission.dart mentor_insight_reverse_activity_guard.dart mentor_insight_stage_claim_boundary.dart reward_policy.dart; do git grep -n -F "$n" c799b964 -- '*.dart' || true; done

# 公开符号存在性+调用方核验：每个模式先命中 lib/ 定义，再显示其余命中只在 test/
for s in validateCombatCatalogMigrationCoverage mapCombatEncounterDefeatObjectiveEventSource AttackTokenObserveOnlyObserver ActionTimeline BasicAttackChain applyCombatModifiers PostureConfig QiResourceLedger TimedStatusLedger prepareNextMainlineStageRuntimeAdmission requireMentorInsightActivityEntryAllowed prepareMentorInsightStageClaimCandidate RewardPolicy; do git grep -n -w "$s" c799b964 -- 'lib/*.dart' 'lib/**/*.dart' 'test/*.dart' 'test/**/*.dart' || true; done

# VALIDATION_ONLY 真实验收消费方
git grep -n -E 'validateCombatCatalogMigrationCoverage|mapCombatEncounterDefeatObjectiveEventSource' c799b964 -- test/data/phase2/ch1_production_catalog_test.dart test/data/phase2/ch1_candidate_defeat_objective_execution_matrix_test.dart test/data/phase2/ch1_candidate_observable_transactional_composition_matrix_test.dart

# PARKED 决策 ID 与状态，以及 M2/M3/M6 权威状态矩阵
git grep -n -E 'MAINLINE-RUN-01|MENTOR-INSIGHT-(CORE|OCCUPANCY|RATE)-01|REWARD-POLICY-CORE-01|TUNE-(ATTACK-TOKEN|WEAPON-TIMELINE|WEAPON-QI|POSTURE)-01' c799b964 -- docs/dispatch/phase0a_overhaul/decision_registry.yaml
git grep -n -E '^\| M[236] ' c799b964 -- docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md
```
