# 二阶段候选 full-suite 隔离事故记录（2026-08-26）

## 事实

- 命令：在 b679 候选 worktree 运行 `flutter test --no-pub`，默认并发。
- 前置：工作树含未提交的纯治理/审计改动；`flutter analyze --no-pub lib test` 为 0 issue，墙钟约 5.7 秒。
- 约 `1:27` 时 reporter 已显示至少 `+1151 -28`，多个 widget test 出现异常；随后报 `Getting current working directory failed ... No such file or directory`。
- 从 `/` 复核确认 `/Users/a10506/.codex/worktrees/b679/挂机武侠` 整体不存在，worktree 登记由 154 降为 153；main 与其余 worktree 未见变化。
- 失去 cwd 后测试无新输出，最终在墙钟 `3:44.14` 发送中断，exit `130`。因此没有最终失败总数，不能写成完整 suite 结果。

## 影响与恢复

- 被删除目录内的未提交文档改动丢失；没有生产数据、main 或远程变更。
- 候选 branch 仍安全停在 clean `4226a9c2`。从 main checkout 执行显式 `git worktree add`，已恢复原路径与候选 branch，worktree 总数回到 154。
- 治理/审计改动按已知 patch 重做；再次 full suite 前先提交可恢复检查点。

## 当前判断边界

- 已确认“full suite 运行期间 worktree 被递归删除”；尚未证明具体测试或外部清理进程，不能把相关 widget failures 直接归因于某一生产改动。
- 本轮纯文档改动不会参与 Dart 编译，但完整套件失败仍阻止候选 Gate 关闭。
- 后续复现必须在 disposable worktree 进行，并记录删除发生前最后完成的测试文件；不得再次拿未提交的真实候选目录试验。

## 关闭标准

- 找到并约束删除目标，使测试清理只能落在自身唯一临时目录，且有“不得等于/包含 repo root”的回归守卫。
- 风险匹配测试通过，scoped analyze 0 issue。
- 已提交候选的完整 `flutter test --no-pub` 在隔离环境退出 0，并记录真实墙钟与通过数。
- candidate diff check、registry parse 和最终工作树 clean。
