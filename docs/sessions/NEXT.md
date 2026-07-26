> 交接时间：2026-07-26 16:59 · **HEAD = 本文件自己的 handoff commit**（末次纯 docs commit；其父 `f3e05056` 是最后一个代码 commit）
> 新会话打「开工」= 读本文件按其执行。核对方式：`git log --oneline -3` 顶部为本次 handoff 的 docs commit，其下最后一个**代码** commit 应是 `f3e05056`；对不上先报偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

codex 全局视觉收口 phase1 + phase2 已全部合入 main 并各经一轮 Claude 端真机抽查；
phase2 抽查挖出的肖像裁切 no-op 已按 TDD 修复，并新增飘字验收 route 补上暴击色盲区。
main 工作树净，**领先 origin 37 个 commit 未 push**（用户明示不推）。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26 两条
2. 读 docs/sessions/2026-07-26_1659_视觉二期与肖像修复.md
3. git pull --rebase --autostash（注意本地领先 37 未 push，pull 前先确认不会打乱）
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_flutter_loose_constraints_fit_noop（本会话新增·表现层 no-op 与断言口径）
   + feedback_flutter_test_batch_silent_skip（本会话更新第三形态）
   + feedback_wuxia_add_mainline_chapter_reconcile（Ch17 必读·加章 ~17 站点）
   + feedback_phase0_check_inflight_worktrees（开局与收尾各查一次）
   + 候选 1/2 加读 feedback_wuxia_release_cap_raise_reconcile + feedback_stages_yaml_edit_direction

【环境快照】
- HEAD = 本 handoff commit（本会话 11 commit：自产 5 + codex phase2 带入 6·**全部未 push**·
  sha 现跑 `git rev-parse` 实证，勿转抄）
- **主 checkout 实测（2026-07-26 16:5x）**：`flutter analyze --no-pub` **EXIT=0 · No issues found**
  （3.1s）；全量 `flutter test --no-pub` **4711 pass / 0 fail**（FULL_EXIT=0 · `[E]` 0 · `-1` 0 · 4:29）
- PROGRESS **98 行**（100 上限，本会话净增 0）
- 视觉子系统：phase1+phase2 全合入；肖像焦点裁切已真生效；新增
  `battle_damage_popup_gallery` route 可随时复看飘字/暴击色
- **他方在途**：PR #83（OPEN + draft + CI 全绿 + 零冲突）其 worktree
  `.claude/worktrees/session-handoff-0726` 被另一 session 持锁，本会话无权 merge 也无法移除
- `build/visual_acceptance/` **493M**（gitignored）：本会话新增 39.6M 留置为视觉证据；
  往批 428M **连挂第三轮未决**

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch17「沙海纵深」章级 spec 起草 + 拍板（推荐） | opus xhigh | ~1-1.5h | 唯一能推主线；Ch14/15/16 惯例都是先 spec 后实装，跳过会在实装中途反复打断用户拍板 |
| 2 | Ch17 整章实装 | opus xhigh | ~3.5-4h | 若拍板跳过 spec 则沿段级 §8 前瞻直接做；~17 站点 reconcile + idle_horizon 重校（s1 45.6/下沿 45 贴线必破） |
| 3 | 合并 PR #83 | — | ~5min | 需用户执行 `gh pr ready 83 && gh pr merge 83`；bg 会话禁自行 merge PR |
| 4 | 往批 428M 视觉证据存废拍板 | — | ~2min | 连挂三轮；根卷可用 1.2Ti 非空间压力，纯「证据留不留」 |
| 5 | 29 组历史详情近似图第一批（神武/宝物/特殊 8 组） | opus high | ~2h | 复查文档 §P2-01 已给顺序；门禁双向棘轮会逼着同步清 allowlist |

【硬约束沿用】
- **不 push 远端**，除非用户当轮明确授权；bg 会话禁自行 merge PR。
- **`flutter test` 批传显式路径会静默漏跑**（已三次复现，第三形态是「播报首个 test 即被丢弃」）。
  日志里 grep 到文件名**不足以**证明它跑完了，验收须逐文件单跑或用出现次数对账。
- **表现层交付断言渲染结果，不断言「参数传到了 widget」**——后者对 no-op 零保护
  （12 张肖像焦点失效即栽在此）。
- **合并 codex 分支**：merge-tree 必按**当前** main 重跑（codex 预检有保质期）；交集文件要
  `git show <mergetree-oid>:<file>` 验**合并后的树**；合并后必重跑门禁测（跨侧 allowlist 会收紧）。
- Edit dart 后必 `dart format`；破坏证红必须在 commit 之后做。

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-26 16:5x 主 checkout 实测快照；新会话改动后必须重新实测，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS 与 session 记录关键信息 2. 确认环境状态（含 PR #83 是否已合、
本地 37 commit 是否仍未 push、phase2 后有无新在途 worktree）3. 不要直接动代码。
