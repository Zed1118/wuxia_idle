# P2-M2-R03：目标组合控制器合同

## 目标与范围

在 C01 的扁平 `all | any` objective composition schema 上，交付领域级不可变 `ObjectiveController`、stable clause 和 owner-bound progress，并让 data mapper 显式映射为该领域合同。本切片是纯 runtime 合同，不是 production host。

- 分支：`codex/phase2-m2-r03-objective-controller-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r03-objective-controller`
- 基线：`b195571b944067b0893e6938a03086b4a4500724`
- 允许：`lib/features/battle/domain/phase0a/**`、`lib/data/validation/combat_objective_primitive_mapper.dart`、对应 tests 与本计划。
- 禁止：production data/host、task/decision registry、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、spawn/token/save/UI/reward/tuning。

## 冻结语义与风险边界

- controller 只接受非空、clause ID 唯一且无空白的扁平集合；输入顺序稳定保留并防御性复制。
- 事件按 clause 顺序广播给所有尚未完成的 primitive；`all` 仅全完成时终局，`any` 任一完成时终局。
- controller 终局后后续事件返回原 progress；重放幂等依赖现有 primitive dedupe。
- progress 与 controller owner 绑定，跨 owner 使用在检查终局之前 fail closed。
- 不推断 nested/failure/timeout/phase/residual-enemy/reward/spawn/token/host/save/UI 语义。

## 验收 checklist（CLAUDE §8.2）

- [x] 领域层无 data import；data enum 穷尽映射为 domain enum。
- [x] `all/any`、stable IDs/order、terminal no-op、duplicate replay、unrelated event、wrong-owner 均有直接测试。
- [x] 输入防御性复制、暴露集合不可变，mapper 每次生成 fresh controller/objective owners。
- [x] 八 primitive mapper/domain 回归保持通过。
- [x] targeted tests 记录命令与通过数；scoped analyze 0 issue；format 与 `git diff --check` 通过。
- [x] 生产接线证据：本任务按授权明确不接 production host；仅交付供后续 host 消费的领域/gateway 合同。
- [x] 红线：0 production 数值、0 Dart 玩家文案、0 三系/在线离线/反主流触点。
- [x] 实现 commit 后追加 `[READY][CODEX][P2-M2-R03] 目标组合控制器合同完成` 空提交，树干净。

## 红/绿与任务切片

1. 红：先增 controller 负向与语义测试，确认缺少 domain controller API 导致失败。
2. 绿：最小实现 domain completion rule/clause/controller/progress。
3. 绿：收敛 C01 mapper 为 domain controller gateway，增 fresh owner 与穷尽 enum 测试。
4. 验收：targeted、scoped analyze、format、diff/path 边界审计。
5. 恢复点更新，提交实现并追加 READY 空提交。

## 当前恢复点

- 状态：实现、验证与分支冻结完成，待主控独立评审。
- 最后完成：新增领域 `ObjectiveCompletionRule` / stable clause / owner-bound immutable progress / controller；C01 mapper 改为穷尽映射并返回 fresh domain controller。初始执行因 fresh worktree 无 `.dart_tool` 触发 Flutter native-assets tool crash，执行 `flutter pub get --offline` 后重跑，测试按预期因 controller 文件/API 缺失编译红；实现后转绿。
- 下一步：主控核对 diff、targeted 证据与 P0/P1 风险后决定整合。
- 已跑验证：`encounter_objective_test.dart` 9/9、`objective_controller_test.dart` 8/8、`combat_objective_primitive_mapper_test.dart` 12/12，共 29/29 通过；`flutter analyze --no-pub` scoped 7 文件 0 issue；`dart format` 4 文件 0 changed；`git diff --check` 通过。
- 阻塞项：无。
- 残留风险：production host 后续必须尊重 terminal no-op 并不得在外层继续推进未完成 clause；本切片不接 host，因此不声称 production 闭环。
