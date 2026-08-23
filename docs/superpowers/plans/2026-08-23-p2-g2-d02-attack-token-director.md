# P2-G2-D02：AttackTokenDirector 基础合同

## 目标

在纯 Dart 领域层实现攻击令牌分配合同（方案 §12.4 / §17.3 第 7 项）：近战/远程/冲锋/支援四类并发攻击预算全部由调用方显式输入，强制执行出生宽限、起手可读、屏外高威胁、不可阻挡范围上限等公平性 fail-closed 闸门，输出确定性、不可变的 granted/denied 决策，为下一批 `Phase0aEncounterFlow` 黑风岭 2–4 攻击令牌生产纵切提供单一语义基础。

## 分支

`codex/phase2-g2-d02-attack-token-20260823`（worktree `挂机武侠-phase2-g2-d02-attack-token`）

## 验收标准

- [x] 四类预算（melee/ranged/charge/support）全部调用方显式输入并严格校验，Dart 无 2-4 之类默认值。
- [x] 请求必含字段：actorId / kind / priority / isOffscreen / isHighImpact / isUnblockableArea / spawnGraceTicksRemaining / telegraphReady，构造期校验；actorId 必须已是 trimmed non-empty canonical ID。
- [x] spawn grace 未完成（>0）或 telegraph 未完成 → fail closed。
- [x] 屏外 + 高威胁 → fail closed；屏外非高威胁 / 屏内高威胁不受影响。
- [x] 同批最多一个不可阻挡大范围攻击生效；该上限跨类别生效，不得通过类别预算绕过。
- [x] 候选排序 = priority 降序 → actorId 升序，输入顺序无关。
- [x] 重复 actorId 抛 ArgumentError（fail closed）。
- [x] 输出 granted/denied 带 typed reason（`AttackTokenDenial`），decisions 列表不可变；安全闸门判定先于预算耗尽。
- [x] 不执行伤害、不改 reducer / data / UI / save，不猜 action lifecycle；令牌释放与再请求归调用方。
- [x] 先红测再实现；`flutter test` targeted 23/23；限定 `dart analyze` 0 issue；`git diff --check` 干净。

## 任务切片

1. 红测文件（23 用例，覆盖校验、四闸门、上限、排序、不可变性）。
2. 实现 `attack_token_director.dart`（枚举 + 预算/请求/决策/分配四个 final class + 无状态 `AttackTokenDirector`）。
3. 验证 + 普通实现 commit + `[READY]` 空提交。

## 当前恢复点

- 状态：完成，已打 `[READY]`。
- 最后完成：实现 + 测试 + analyze + diff --check 全绿。
- 验证：`flutter test --no-pub test/features/battle/domain/phase0a/attack_token_director_test.dart` → 23 pass；`dart analyze` 两文件 0 issue。
- 剩余边界（不在本合同内）：
  1. Boss 显式机制叠加多个不可阻挡范围攻击需人工可读性验收，合同内固定上限 1，不可配置（有意 fail closed）。
  2. 令牌释放 / 持有跟踪 / 跨 tick 再请求归调用方（EncounterFlow），合同无状态。
  3. 2–4 近战预算、8–16 活跃等数值为后续数据/试玩参数，由调用方从配置传入。
  4. 已起手后离屏攻击的边缘方向/威胁/声音提示属表现层（battle presentation feed），不在本合同。
