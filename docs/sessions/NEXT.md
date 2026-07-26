> 交接时间：2026-07-26 19:53 · **最后一个内容 commit = `754c96b6`**（Ch17 `--no-ff` 合并）；其后全是 handoff 收尾的 docs commit（本文件即其一），故 **HEAD sha 不钉死**——以现跑 `git rev-parse --short HEAD` 为准。
> 新会话打「开工」= 读本文件按其执行。核对方式：`git log --oneline -8` 里应能看到 `754c96b6` → `ddbe39b6` → `bff16da8` 三条内容 commit，且 `git status -sb` 显示与 origin **ahead/behind 0/0**。对不上先报偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch17「沙海纵深」整章实装已完成、合入 main 并 push；主线达 17 章 85 关，cap 40，机制型 Boss 首次进入主线。HEAD `e1b085a1`，工作树净，与 origin **完全同步（ahead/behind 0/0）**。本章唯一未闭合项是 11 张美术图。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26「Ch17 整章实装」条
2. 读 docs/sessions/2026-07-26_1953_Ch17实装.md
3. git pull --rebase --autostash（已同步，pull 应为 no-op；先确认不会打乱）
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_wuxia_add_mainline_chapter_reconcile（**本轮刚补两个新站点**：立绘 standee 注册表 / skill_count_contract genericIds）
   + reference_codex_image_gen_art_pipeline（美术批必读·出图管线）
   + feedback_visual_acceptance（视觉验收 SOP + Claude 终判闸门）
   + feedback_flutter_test_minus1_carryforward（-1 带向后续·排查法）
   + feedback_zero_ref_asset_may_be_deprecated（接线前先查移除史）

【环境快照】
- 本会话 6 commit·**全部已 push**·与 origin ahead/behind **0/0**（**sha 与 ahead 数一律现跑 `git rev-parse --short HEAD` / `git status -sb` 实证，禁转抄本提示词**）
- `flutter analyze --no-pub` **EXIT=0 · No issues found** —— 2026-07-26 19:5x 主 checkout 实测
- 全量 `flutter test --no-pub` **4711 pass / 0 fail**（EXIT=0 · All tests passed! · `[E]` 0 · `-1` 0）—— **主 checkout 合并态实测于 `754c96b6`**；其后 `327413b3`/`e1b085a1` 均为纯文档 commit，故此数对当前 HEAD 仍成立。**一旦动代码必须重新实测。**
- 主线 **17 章 85 关** · cap **40**（宗师·圆熟）· skills **216** · boss 敌 **36** · 图鉴 catalog **49** · 首通 **Lv102**（cumExp 3633）· 全内容 **Lv118**
- Ch17 美术 **11 图未出**（`test/fixtures/known_missing_assets.txt` 已登记·errorBuilder 兜底）
- PROGRESS **98 行**（100 上限内）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch17 美术 11 图 codex image_gen 专批（推荐） | opus high | ~2h | 唯一能闭合 Ch17 的收尾；出图后同时清 allowlist + 补脚底 fraction，standee 门禁自动恢复全量把关 |
| 2 | 删残留远端分支 `origin/worktree-session-handoff-0726` | — | ~2min | 已逐字节验证零独有内容，需你授权（对外操作） |
| 3 | Ch18「天地之远」spec 起草 | opus high | ~2h | 宗师段收官章；段级 §8 已定向（cap 40→42 封顶·yang_guan 收编·全机制 0.12）|
| 4 | 29 组历史详情近似图第一批（神武/宝物/特殊 8 组） | opus high | ~2h | 复查文档 §P2-01 已给顺序；门禁双向棘轮会逼着同步清 allowlist |

【硬约束沿用】
- **Ch18 spec 起草前必读 Ch17 spec §1**：那里记了上游段级 spec 的三处事实错（skill 计数 / fang 变体性质 / 三灵巧向），段级 spec 本身**未回改**，不读会再踩。
- **spec §9 的站点清单当「起点」不当「全集」**：Ch17 spec 前一天刚做完 Phase 0，仍漏 2 站点。真全集只有全量测试知道 —— 章批必跑全量，别只跑 targeted。
- **`flutter test` 的 `-1` 带向后续**：日志尾部文件名是假象，必须 `grep -n -m1 -- "-1:"` 抓第一个才是真失败。
- **章批与美术批分两次**：凡「读真实资产」的新门禁都要先想清「章批已落·出图批未跑」中间态，复用 `known_missing_assets` allowlist 而非另开豁免。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`（已列入上方「选读 memory」）。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（HEAD / 与 origin 同步 / 有无在途 worktree）3. 不要直接动代码。
