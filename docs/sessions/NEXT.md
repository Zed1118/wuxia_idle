项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

> 交接时间：2026-07-27 10:53
> HEAD：**现跑 `git rev-parse --short HEAD` 取,禁转抄本文**(本文件自身的 handoff docs commit 会让任何写死的 sha 落地即过期)。
> 最后一个**内容** commit = `80531d37`(PR #85 merge·Ch17 webp 清账);其后只有 handoff docs commit。

Ch17「沙海纵深」全链彻底闭环:章批→美术 11 图→webp 清账三批全部合入 main 并 push。工作树净、与 origin 同步(现跑 `git status -sb` 复核)、零在途 worktree/分支。下一个内容里程碑 = Ch18「天地之远」宗师段收官章,spec 尚未起草。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26「Ch17 美术 11 图接线」条(含合并态复验段 + webp 清账批段)
2. 读 docs/sessions/2026-07-27_1052_Ch17收尾.md
3. `git pull --rebase --autostash`(应为 no-op)
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_wuxia_add_mainline_chapter_reconcile（Ch18 = 加主线章·~11 测站点+6 生产站点）
   + feedback_wuxia_release_cap_raise_reconcile（cap 40→42 封顶·破/漂 4 站点）
   + feedback_spec_writing_checklist + feedback_phase0_grep_two_axes（写 spec 前 reality check + Phase 0 六维）
   + feedback_wuxia_boss_balance_crosstier（章末 Boss 跨阶才真难）
   + feedback_chinese_path_shell_pitfalls（新增 #5 zsh 不分词）

【环境快照】
- 最后内容 commit `80531d37`;本会话 main 前进 8 commit 全已 push(HEAD 现跑取)
- `flutter analyze --no-pub` **EXIT=0 · No issues found** —— 2026-07-27 **主 checkout** 实测
- 全量 `flutter test --no-pub` **4711 pass / 0 fail**(EXIT=0 · `All tests passed!` · `-1` 0 · `[E]` 0 · **4m13s**) —— 2026-07-27 **主 checkout · HEAD `80531d37`** 实测。**改动代码后必须重新实测。**
- 主线 **17 章 85 关** · cap **40** · `known_missing_assets` **清零** · `asset_audit` **430 引用/430 存在/缺失 0**(六类全零·chapterCover 17·narrative 85)
- assets **99M**(本轮 114M→99M);`build/visual_acceptance` 204M(含 battle_ui_v2_85_sample 111M 待阶段 5 终验)
- PROGRESS **98 行**(100 上限内·本轮两次更新净增长均 0)

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch18「天地之远」spec 起草（推荐） | opus high(可升 xhigh) | ~2h | Ch17 彻底闭环,宗师段收官章是唯一自然接续;**起草前必读 Ch17 spec §1** 三处上游段级事实错 |
| 2 | 拍板 39M 留置处置 | — | ~2min | `ch17_art_out` 已实证冗余(原图在 git 历史可取回),另两个建议留 |
| 3 | battle-ui-v2 阶段 5 全模式终验 | opus high | ~1.5h | 需独占 app 与屏幕;做完可回收 111M |
| 4 | 压缩全局 `MEMORY.md` 163→<140 行 | opus high | ~20min | hook 已提示;需逐条判断可合并/过时项 |

【硬约束沿用】
- **Ch18 spec 起草前必读 Ch17 spec §1**:记了上游段级 spec 三处事实错(skill 计数 / fang 变体性质 / 三灵巧向),段级 spec **本身未回改**,不读会再踩。
- **zsh 不对含空格字符串变量分词**:多文件 `flutter test` 会收到一条拼接路径、误报 EXIT=1 且日志看着像真回归。多文件循环一律数组 `for f in "${files[@]}"`。另 zsh 是 `$pipestatus`(1-indexed)不是 `$PIPESTATUS`,取码改 `cmd > log 2>&1; echo $?`。
- **`git show ref:中文路径` 比对必看字节数**:两侧都取不到会得相同空哈希 `da39a3ee`、**假报「内容一致」**;取路径用 `-c core.quotepath=false` + `-z`(git 默认把中文路径转义成带引号八进制形式,直接喂 `git show` 取不到)。
- **中文文件名不能做 heredoc 重定向目标**(静默不落盘):中文名文档用 Write 工具或 python `io.open` 写。
- **ExitWorktree「Discarded N commits」是误报**:分支已合入时先跑三验(`is-ancestor`/`main..分支` 计数/`branch --merged`)再 `discard_changes: true`;**远端分支它不管,须另删**。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照;新会话改动代码后**必须重新实测**,禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后:1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态(现跑 HEAD/status/worktree list) 3. 不要直接动代码。
