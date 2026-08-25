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
- 治理/审计改动按已知 patch 重做，并先提交可恢复检查点 `2ff18b61`。

## 当前判断边界

- 已确认“full suite 运行期间应用托管 worktree 整体消失”；尚未取得外部清理进程的直接日志，不能把相关 widget failures 归因于某一生产改动。
- 仓内文字检索未发现删除 repo root / parent 的路径；170 个递归删除点均需结合运行值判断，单凭源码数量不能定罪。
- 同一 `2ff18b61` 在 disposable clone 完成默认并发 full suite，越过原事故时间点且目录始终存在。因此最符合现有证据的推断是应用托管 worktree 生命周期清理与测试重叠，而非套件稳定删除当前目录；此结论是推断，不冒充已取得进程级直接证据。

## 隔离复现与处置

- fresh clone 先运行 `flutter pub get` 与 `dart run build_runner build`；缺生成文件的无效首轮已明确排除，不计业务回归。
- 有效命令：`flutter test --no-pub -r json`，commit `2ff18b61`，默认并发。
- 结果：6,294 个非 loading test events，全部 success；0 fail / 0 skip / 0 error；runner done `success: true`，内部 `844138ms`，shell 墙钟 `14:06.91`。
- 原始 JSON：3,931,050 bytes，SHA-256 `f41dac22f5528a351ec394b7e176b573cf9b4a43f20cf2dbbe2fc7da2018cecf`（临时诊断文件，不入仓）。
- 当前候选已从 `.codex/worktrees/b679` 迁至 `/Users/a10506/Desktop/Projects/挂机武侠-phase2-candidate-stabilization-20260826`，消除复用应用托管路径的生命周期风险。

## 关闭标准

- 已提交候选的完整 `flutter test --no-pub` 在隔离环境退出 0，并记录真实墙钟与通过数：已满足。
- 候选迁出应用托管 worktree，且不再在未提交目录做破坏性复现：已满足。
- stable worktree 首次 analyze 因 ignored `*.g.dart` 未生成产生 5,337 项级联错误；运行 `dart run build_runner build` 写出 128 个 ignored outputs 后，正式 `flutter analyze --no-pub lib test` 0 issue，墙钟 `22.10s`。该首轮属于环境前置失败，不计代码回归。
- candidate diff check 0、registry parse PASS；最终 READY tip clean 后关闭本事故对候选 Gate 的阻塞。
- 剩余风险：缺外部清理进程的直接日志，归因保持“高一致性推断”；若稳定专用 worktree 再消失，立即重开测试清理代码调查，不得继续按生命周期竞态解释。
