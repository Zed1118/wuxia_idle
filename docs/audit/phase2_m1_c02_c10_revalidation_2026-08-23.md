# 二阶段 M1 C02-C10 Batch7 重验审计

## 结论

本次冻结基线为委派时 `codex/phase2-g2-batch7-data-contracts-20260823` 的 `1a7ddbf9b52ea1de161df242e2e0ee68f8fe82a3`。旧 M1 集成 tip `f93c29e6c5130ba1a95f56fe93c3c5ef343f680b` 以及九个 READY 候选 tip 均是该基线祖先；九个实现和九个测试在基线中全部存在。因此没有“仍缺失且契约有效”的实现提交可重放，本分支刻意执行零次 cherry-pick，避免把旧对象覆盖到后续有效补强之上。

本审计只确认九个当前纯领域合同的继承、漂移和专项验证状态，不把未决产品语义写入合同，不修改公共 model/reducer、数据、存档、UI、host、数值或 task registry。

## 基线与祖先证据

- 冻结基线：`1a7ddbf9b52ea1de161df242e2e0ee68f8fe82a3`
- 旧候选集成：`f93c29e6c5130ba1a95f56fe93c3c5ef343f680b`
- `git merge-base --is-ancestor f93c29e6 1a7ddbf9`：PASS
- 九个 READY tip：`ed28b6f6`、`6a5f9734`、`05ce58f7`、`e623f8f2`、`ce55c486`、`97583183`、`eea0b3ac`、`cbd161cd`、`bb108f36`，逐个祖先检查均 PASS。
- 派发后 Batch7 ref 继续前移；为避免追逐并发 WIP，本任务始终使用委派 worktree 固定的 `1a7ddbf9`，未修改 Batch7 分支。

## 九项逐对象比较

| 合同 | 当前实现/测试相对旧集成 | 重放决定 | 当前基线独立检查 |
|---|---|---|---|
| C02 `combat_geometry` | 实现、测试对象相同 | 不重放 | 六类 typed scope；非法/非有限几何 fail closed；命中按几何量和 ID 确定排序 |
| C03 `action_timeline` | 实现、测试对象相同 | 不重放 | 固定拍 windup/active/recovery/终态；首效至多一次；取消/打断/失败冷却标记显式 |
| C04 `defense_resolution` | 当前为后续 C16 加固超集；测试新增 4 项 | 保留后续版本，不反向覆盖 | 防御 flags 正交；反击预算、typed effect allowlist、projectile redirect 和 non-recursive 语义显式 |
| C05 `posture` | 实现、测试对象相同 | 不重放 | 单一累计姿态；破势窗口内抑制重复姿态伤害；恢复策略和 Boss 控制折算由 caller 注入 |
| C06 `status_effects` | 测试对象相同；实现仅构造器委托形式修复 | 保留当前等价形式 | slow/root/内伤/毒固定拍；同源刷新/叠层、快照隔离、绝对逻辑 tick 和稳定伤害排序 |
| C07 `qi_resource` | 测试对象相同；实现仅 const 构造器重定向形式修复 | 保留当前等价形式 | 预留/提交/取消生命周期；动作 ID 去重；溢出可观测；击杀窗口降低 cap 不反向扣气 |
| C08 `basic_attack_chain` | 实现、测试对象相同 | 不重放 | 五武器 identity；opaque geometry/timeline/effect 引用；不可变段快照；连段重置确定 |
| C09 `combat_modifiers` | 实现、测试对象相同 | 不重放 | 复用 `TechniqueSchool`；三系字段正交；正有限因子；乘法溢出 fail closed；caller bounds 收口 |
| C10 `combat_event_order` | 实现、测试对象相同 | 不重放 | 九阶段稳定顺序；重复 ID/未排序 feed fail closed；表现投影快照只读且不改领域事件 |

对象比较显示六组实现+测试完全相同；C04 为有效后续功能加固；C06/C07 只改变 Dart 构造器写法，原测试对象均未变化。旧对象反向重放会让 C04 丢失 C16 合同，并回退 C06/C07 的基线编译修复。

## 边界复核

- 九个实现只依赖 `dart:math`、同域 `arena_vector.dart` 或核心 `TechniqueSchool`；未依赖 Flutter UI、application/presentation、data/save、host、公共 combat model 或 reducer。
- 九个实现没有中文玩家文案；没有新增产品平衡值、关卡 ID、生产默认值或未决 policy。
- 本分支不修改 `phase0a_combat_model.dart`、`phase0a_combat_reducer.dart`、`data/**`、save、UI、host、数值或 `docs/dispatch/**`。
- 旧专项测试声明为 77 项；当前基线因 C16 防御加固新增 4 项，当前完整九文件专项集合为 81 项。验收时保留并运行完整 81 项，不删除有效加固测试来伪造 77 数字；77 项旧核心仍是完整集合的严格子集。

## 验证

- 九个 targeted 测试文件：待 Flutter 串行资源锁放行后运行。
- 18 文件 scoped analyze：待 Flutter 串行资源锁放行后运行。
- `git diff --check`：待最终文档完成后运行。
- 范围 diff check：待最终文档完成后运行。
- 独立子 agent 终审：待动态验证完成后运行。

## 遗留风险

- 本次证明的是委派快照 `1a7ddbf9`，不覆盖 Batch7 分支在派发后新增的并发提交。
- 九个合同中的部分已被后续 G1/G2 adapter 消费；本次没有修改这些消费方，也不宣称黑风岭产品纵切已完成。
- `PROPOSED` / `TUNING` 决策仍保持未冻结；本审计没有从现有 API 反推产品语义。

