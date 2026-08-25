# 二阶段统一候选稳定化计划

## 结果合同

- 单一目标：把 `4226a9c2` 之后的治理、成本口径、历史分叉分类和最终回归纳入同一条可审查的候选链，使 `P2-CANDIDATE-STABILIZATION` 从 `0/1` 到 `1/1`。
- 固定验收门：治理规则同链；错误的“全量约 5 小时”口径已订正；PROGRESS 只保留结果仪表盘；candidate diff check、scoped analyze、一次完整 test suite、registry parse 全部通过；工作树 clean。
- 实时基线：分支 `codex/phase2-candidate-stabilization-20260826`，base `4226a9c2`；M0–M9 candidate `1/10`，main `0/10`；187 branches / 154 worktrees。
- 当前关键阻塞：首次并发 full suite 触发运行 worktree 被递归删除，必须先定位并隔离测试清理边界，才能再次完整验收。
- 预期增量：只关闭候选稳定化 `0/1 → 1/1`；不晋升 M0–M9、U14、M5、M6 或 Phase 2。
- 成本上限：主成本读数为墙钟；约 90 分钟无 Gate 变化即停线；不得在未隔离删除风险时从真实候选 worktree 重跑全量。

## 范围

- 吸收 `503d1ad3` 的结果驱动治理语义，并按当前候选事实调整。
- 纠正 CLAUDE、PROGRESS、相关 plan/audit 中的测试成本单位误读。
- 压缩 PROGRESS 顶部历史 READY 堆叠为不超过 100 行的结果仪表盘。
- 分类本地分支/worktree，只记录证据，不删除、移动、合并或复用。
- 修复候选相对 main 的纯格式 diff-check 问题。
- 定位并修复/隔离 full-suite 递归删除 worktree 的测试基础设施缺陷；回归必须在可恢复的已提交候选上执行。

## 非目标

- 除测试隔离缺陷外，不改生产 Dart、schema/saveVersion、YAML、数值、玩法或美术。
- 不替人类选择 light-foot / mass-battle 的持久模型方案。
- 不合并或推送 main，不删除历史 branch/worktree，不把局部 READY 当成 Gate 完成。

## 施工与验证

1. 复核 main、candidate、governance branch 和 worktree clean 基线。
2. 写入 CLAUDE §8.4、纠正提交节奏与全量成本口径。
3. 压缩 PROGRESS，新增分支/worktree 分类审计和 registry 权威 WIP。
4. 运行 `git diff --check main..HEAD`，关闭历史尾随空格；先提交可恢复检查点。
5. 对首次 full-suite 删除事故做只读定位；在 disposable worktree 复现，禁止拿真实候选目录做破坏性试验。
6. 修复后运行 `flutter analyze --no-pub lib test`、风险匹配测试和一次完整 `flutter test --no-pub`。
7. 解析 registry YAML，复核分支/worktree/owned-file 证据，更新 READY 恢复点并冻结 clean tip。

## 当前恢复点

- 状态：WIP / full-suite isolation blocker under investigation。
- 最后完成：首次 scoped analyze 0 issue；并发 full suite 在约 `1:27` 累计至少 28 项失败，同时运行 worktree 消失，失去 cwd 后在墙钟 `3:44` 终止。已从 clean branch `4226a9c2` 恢复同路径工作树并重做治理改动。
- 下一步：提交可恢复检查点；在 disposable worktree 定位删除源，补边界守卫，再做最终回归。
- 已跑验证：main 未动；恢复前其余 153 worktrees 保持登记；恢复后总数回到 154；scoped analyze 首轮 0 issue（约 5.7 秒）。
- 阻塞项：full-suite 测试隔离/清理缺陷；light-foot / mass-battle schema 决策保持任务外待批。
