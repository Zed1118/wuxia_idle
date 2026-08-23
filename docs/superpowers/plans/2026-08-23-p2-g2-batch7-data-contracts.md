# P2 G2 Batch7：数据合同与诊断前置

## 目标

从 READY `935c04e1` 出发，在不猜黑风岭具体胜利条件、不切 production host、不执行 AttackToken enforce 的前提下，建立可供后续 loader/validator 与 headless 诊断消费的内容中立合同。

## 并行切片

1. O01（Codex 子 agent）：八类遭遇目标原语的不可变纯领域合同和确定性推进。
2. S01（Pi + DeepSeek Flash）：战斗敌人 archetype、encounter 与 catalog manifest typed schema。
3. M0-F01（Codex 子 agent）：同步 21 章/105 关等仓库事实和二阶段 PROPOSED 索引，不替用户拍板。
4. 主控：复审真实 diff、整合、补缺口并在 schema READY 后派发 L01 loader/validator 给 Qoder。

## 冻结边界

- 不修改 `data/combat/**`、`data/stages.yaml`、`GameRepository` 或任何 production host。
- 不选择黑风岭伏击终局条件，不定义 40 敌人具体配比、补兵阈值、warning/grace 或 token enforce 语义。
- 不新增 UI/VFX、奖励、伤势、存档或导航逻辑。
- 新 Dart 类型不携带中文玩家文案；所有数值字段由 caller 显式提供且构造期 fail closed。
- schema 名称必须与既有叙事 `EncounterDef` 明确分离；目标原语不得依赖内容 ID。

## 验收 checklist

- [ ] O01 八类目标原语逐类验证完成、输入顺序与重复事件确定性明确。
- [ ] S01 三类 typed def 对非法 ID、重复引用、非有限/负数和集合 mutation fail closed。
- [ ] M0-F01 仅同步可验证事实，所有 PROPOSED 仍明确标注未冻结。
- [ ] 主控 diff 复审、targeted tests、`flutter analyze --no-pub lib test` 与独立审查通过。
- [ ] 所有任务 worktree clean 且 tip 为 `[READY]`，集成分支生成 Batch7 READY 恢复点。

## 当前恢复点

- 状态：Batch7 集成基线已建立，准备并行派发 O01、S01、M0-F01。
- 最后完成：Batch6 READY `935c04e1`，全量 4599/4599，主项目 analyze 0 issue。
- 下一步：冻结本计划和 registry 后建立三个独立任务 worktree。
- 阻塞项：production Blackwind objective、AttackToken enforce、入口表现与主线参与/连续 Run policy 仍未冻结；不阻塞本批合同工作。
