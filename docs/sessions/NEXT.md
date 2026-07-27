> 交接时间：2026-07-27 22:31 · HEAD `ac7c8ba4`（main，与 origin 同步）
> 新会话打「开工」即读本文件执行。动手前先核头部 HEAD sha / 时间与 git 实况，漂移先报告偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch18「阳关故人」宗师段收官章内容层已合 main（PR #86），美术 11 图已出齐接线但停在 draft PR #87 待审合。
主 checkout 干净、与 origin 同步。main 上已是 18 章 90 关 / cap 42 / `mount_deferred` 全仓归零。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-27 Ch18 条目
2. 读 docs/sessions/2026-07-27_2231_Ch18美术批.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + reference_codex_image_gen_art_pipeline（**本会话已订正 CLI 调用式，出图批必读**）
   + feedback_visual_acceptance（Claude 终判闸门）
   + feedback_wuxia_webp_cleanup_recipe（若开 webp 清账批）
   + feedback_gh_pr_mergeable_vs_local_divergence（PR 合并前本地 merge-tree 复算）
   + feedback_worktree_gitignored_evidence_lost（清 worktree 前先救留置证据）

【环境快照】
- 主 checkout HEAD `ac7c8ba4`（本会话 5 commit，**已全部 push**，与 origin 同步）
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues found**（5.7s）—— 2026-07-27 本会话实测
- 主 checkout targeted 受影响测族 9 文件 **80 pass / 0 fail**（EXIT 逐个取证）—— 本会话 PR #86 合并后实测
- 主 checkout 全量本会话**未跑**（代码改动在 PR #87 分支）。PR #87 分支全量 = **4711 pass / 0 fail**（EXIT=0 · `[E]` 0 · `-1` 0 · 7m03s）—— 本会话 worktree 实测
- PR #87：OPEN · draft · 相对 main **1 commit / 15 文件**（本地 merge-tree **零冲突**实测；GitHub 侧 mergeable 当时报 UNKNOWN 未采信）
- worktree 只剩 `ch18-art`（陈旧的 ch18-yangguan / ch18-lore 本轮已清）
- assets：main 上 **99M**；PR #87 分支 **122M**（11 张真 PNG 未转 webp）· build/dispatch 25M · build/visual_acceptance 204M
- 全局 MEMORY.md **139 行**（本会话 163→139）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 审并合 PR #87（推荐） | opus high | ~20min | 已全绿只卡 review；不合则 webp 清账批无从开工，且 Ch18 唯一未闭合项挂着 |
| 2 | webp 清账批 | opus high | ~40min | assets 122M，Ch14-17 惯例压缩率 ~93%，可回收约 22M；须先合 #87 |
| 3 | 铜镜 canon 修正 | opus high | ~40min | **需用户先拍板 D1/D2/D3**（记录「重要决策」有权衡，我方推 D3） |
| 4 | battle-ui-v2 阶段 5 全模式终验 | opus high | ~1.5h | 需独占 app 与屏幕；做完可回收 204M 里的 111M |

【硬约束沿用】
- **codex CLI 正解 = `codex exec -C <dir> -s workspace-write -i a.png -- "$PROMPT" < /dev/null`**：`--` 终止变参 + 显式喂 EOF，两者缺一不可。旧记法 `cat prompt.txt | codex exec -i img` **实测挂死 2 小时 0 输出 %CPU 0.0**；prompt 走位置参数会被变参 `-i` 吞成图片路径。判活看 %CPU + 日志行数是否在涨，别只看进程还在。
- **不采信 codex 自评**：本批它自报 `san_dizi`「不等边三角队形更明确」实为近乎并排（与 Ch17 批「厚背阔刀」误报同型）。Claude 逐图视觉终判是必过闸门。验收工装在 `build/dispatch/gate_precheck.py`（另存 `~/scripts/wuxia_gate_precheck.py`），逐条复刻 `battle_standee_asset_role_test:120-151` 九判据，已用 Ch17 五张已知 fraction 反验一致。
- **改叙事前必读全文再估代价**：铜镜方案 D1 初估「~14 处但机械」是错的——镜子与「师」字玉佩配对撑着 Ch5/Ch6 五个情感段落，只 grep 关键词会严重低估。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（现跑 HEAD / status / worktree list / PR #87 状态） 3. 不要直接动代码。
