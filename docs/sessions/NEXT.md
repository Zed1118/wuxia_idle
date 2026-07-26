> 交接时间：2026-07-26 18:25 · **HEAD = 本文件所在的 handoff commit**（本会话末次 commit；其父 `b7a70788` 是最后一个内容 commit，`060c53d5` 是 spec 冻结）
> 新会话打「开工」= 读本文件按其执行。核对方式：`git log --oneline -3` 顶部为本次 handoff 的 docs commit，其下应是 `b7a70788` → `060c53d5`；对不上先报偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch17「沙海纵深」章级 spec 已六项拍板冻结（全按推荐 1A/2A/3A/4A/5A/6A），实装依据就位、无阻塞。
本会话纯文档零代码改动；顺带关闭 PR #83（改走 cherry-pick）、清掉孤儿 worktree、视觉证据 493M→204M。
main 工作树净，**领先 origin 43 个 commit 未 push**（用户明示不推）。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26 首条
2. 读 docs/sessions/2026-07-26_1825_Ch17spec与清账.md
3. **读 docs/spec/2026-07-26-ch17-shahai-zongshen-design.md（130 行·实装唯一依据·六项已冻结）**
4. git pull --rebase --autostash（本地纯领先 43、落后 0，pull 为 no-op；先确认不会打乱）
5. 选读 memory：reference_anti_hallucination（固定）
   + feedback_wuxia_add_mainline_chapter_reconcile（**Ch17 必读**·加章 ~17 站点）
   + feedback_wuxia_release_cap_raise_reconcile（cap 38→40·**within-tier 判据**）
   + feedback_stages_yaml_edit_direction（stages.yaml 从 `- id:` 正向定位）
   + feedback_flutter_test_batch_silent_skip（批传显式路径静默漏跑·验收须逐文件对账）
   + feedback_living_doc_state_drift（**本会话新增类型 D**·上游 spec 前瞻段必逐条证伪）
   + feedback_gh_pr_mergeable_vs_local_divergence（本会话新增）

【环境快照】
- HEAD = 本次 handoff commit（本会话 6 commit·**全部未 push**·sha 由现跑 `git rev-parse` 实证，勿转抄）
- **本会话主 checkout 实测**：`flutter analyze --no-pub` **EXIT=0 · No issues found**（3.0s）
- **全量 test 4711 pass / 0 fail** — 来自 **2026-07-26 16:5x 上一会话**主 checkout 实测；本会话**纯文档零代码/零 yaml 改动**故未重跑（守 CLAUDE §8.0）。**新会话一旦动代码必须重新实测，禁转抄此数字。**
- PROGRESS **98 行**（100 上限·本会话净增 0）
- Ch17 spec **130 行·已冻结**；`build/visual_acceptance/` **204M**（gitignored·6 批·其中 2 批有「勿清/未拍板要用」依据）
- **在途 worktree：无**（`session-handoff-0726` 本轮已实证清理——7h 零活动、无 lock、内容已在 main）
- 残留：远端分支 `origin/worktree-session-handoff-0726`（删需 push 授权）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch17「沙海纵深」整章实装（推荐） | opus xhigh | ~3.5-4h | 唯一能推主线；spec 已冻结、§9 站点清单与 §6 A 案五步就位，开工零阻塞，是当前性价比最高的一波 |
| 2 | push 43 commit + 删远端残留分支 | — | ~5min | 已积压多轮；需你明确授权（硬约束是不 push） |
| 3 | 29 组历史详情近似图第一批（神武/宝物/特殊 8 组） | opus high | ~2h | 复查文档 §P2-01 已给顺序；门禁双向棘轮会逼着同步清 allowlist |
| 4 | battle-ui-v2 阶段 5 全模式终验 | opus high | ~1h | 需独占 app 与屏幕；做完才能清 `battle_ui_v2_85_sample` 111M |

【硬约束沿用】
- **不 push 远端**，除非用户当轮明确授权；bg 会话禁自行 merge PR。
- **上游 spec 的前瞻段当假设不当事实**：Ch17 spec §1 已列段级 spec 三处错（skill 计数实为 255 / fang 是佛门防御变体非敦煌意象且 9 招已存在 / 「三灵巧向」有一招实为阴柔）。**Ch18 起草前必读 Ch17 spec §1**，段级 spec 本身未回改。
- **`flutter test` 批传显式路径会静默漏跑**（已三次复现）。日志 grep 到文件名**不足以**证明它跑完了，验收须逐文件单跑或按出现次数对账。
- **bg 写守卫拦 Write/Edit**：纯文档用 Bash heredoc；改已有中文文档先 heredoc 写 python 脚本再跑。**不要为文档开 EnterWorktree**（baseRef=fresh 基于 origin，会丢本地 43 个未 push commit）。
- Edit dart 后必 `dart format`；破坏证红必须在 commit 之后做。

【防幻觉守则】
- 本提示词【环境快照】数字：analyze 是 2026-07-26 18:2x 本会话实测；全量 test 是上一会话（16:5x）实测**转述并已标注出处**。新会话改动后必须重新实测，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- **Ch17 spec 内的行号/计数是 2026-07-26 实测快照，实装前必须全部重新 grep 复定**（spec §12 已明写）。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS、session 记录与 Ch17 spec 的关键信息 2. 确认环境状态（HEAD/未 push 数/有无新在途 worktree）3. 不要直接动代码。
