# 二阶段候选分支 / worktree 分类审计（2026-08-26）

## 结论

- 盘点对象：本机 `refs/heads` 与 `git worktree list`；不读取远程新状态，不执行 merge、push、删除或移动。
- 当前候选：`codex/phase2-candidate-stabilization-20260826`，基线 `4226a9c2`。
- 本地分支：187；其中 100 个 tip 已是当前候选祖先，属于已进入统一候选链。
- 历史分叉：87；它们尚未逐项完成“已替代 / 补丁已吸收 / 仍待评”语义判断，不能直接报告为 87 项孤立集成债。
- 2026-08-25 新增分叉只有 `codex/phase2-governance-integration-20260825 @ 503d1ad3`；其规则语义已由本稳定化 Gate 吸收，原分支保持不动。
- worktree：初次盘点 154 clean / 0 dirty。首次 full suite 意外删除当前 b679 worktree 后降至 153；已从 clean branch 精确重建同路径，恢复为 154。其余 worktree 未被本任务修改。

## 债务口径

- **已进入候选链**：tip 是当前候选祖先；100 个。
- **语义已吸收但非祖先**：治理分支 1 个；需以本 Gate 最终 diff 和验证为准。
- **历史未分类队列**：其余 86 个；可能含已 cherry-pick、被后续实现替代、纯证据分支或仍待评实现，必须按生产路径和 patch-id 再判。
- **main 发布债**：0 个已关闭权威产品 Gate 待发 main；当前稳定化 Gate 不是产品里程碑，M0–M9 不因此晋升。
- **禁止推论**：branch 数、worktree 数、READY 前缀、局部绿测和 clean 均不得独立换算整体完成度。

## 复核方法

1. 用 `git merge-base --is-ancestor <branch> <candidate>` 判断是否进入候选祖先链。
2. 对非祖先分支按 commit date 筛出新增分叉，再比较实际 diff / patch-id / 生产路径语义。
3. 用每个 worktree 的 `git status --porcelain` 只检查 clean 状态。
4. 最终以 candidate diff、风险匹配验证、统一集成态和 clean 四项共同决定是否关闭 Gate。

## 后续施工建议

- 先完成当前候选回归，再按“最近且可能影响权威 Gate”顺序审 86 个历史分叉；不要批量 cherry-pick。
- 每次只处理一个真实孤立集成债：确认生产缺口、补丁仍有增量、验证通过后并入当前候选链。
- 分支/worktree 清理由人类另行授权；即使判为已替代，也只登记，不在本任务删除。
