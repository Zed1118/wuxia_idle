# 2026-08-06 夜批总计划(22:14 起 · 8h 档 · 至 ~06:15)

> 断点续跑唯一真相源:任何一次唤醒(cron/事件)都从本文件重建上下文,不依赖会话记忆。
> 基线 main `74a7993c`;两执行端 worktree 均自该基线。

## 端与单
- codex · 单 C1 题字清查:`docs/dispatch/2026-08-06_C1_codex_inscription_cleanup.md`,worktree `.claude/worktrees/codex-inscription`,log `/Users/a10506/.claude/jobs/1dedbe6d/tmp/codex_C1.log`
- kimi · 单 K1 技术债序列:`docs/dispatch/2026-08-06_K1_kimi_techdebt_series.md`,worktree `.claude/worktrees/kimi-techdebt`,log `/Users/a10506/.claude/jobs/1dedbe6d/tmp/kimi_K1.log`(预热 log `kimi_prep.log`)
- Claude 自主活块(主 checkout;代码改动须 EnterWorktree,纯文档 Bash heredoc):
  - 块1 杂项清账:phase8 spec §1「塔 14/21/28/32 已用 guardianDefIds」→ 实况 {42,49} 回改 / BACKLOG 四区第八阶段条目销账(已收官改归档指针) / docs/spec/playability_phase2_backlog.md 四区 P2③ 勾销(第八阶段落地) / `.codegraph` 重建(codegraph_status 查,坏则重建)
  - 块2 方向盘点:产出 `docs/audit/direction_candidates_2026-08-07.md`——盘 GDD 各系统余量、音频二期(phase2_backlog §七)、战斗爽感原则落点、master spec 后续、rejected_task_registry 排除项;每候选 Phase 0 grep 实测+预估+推荐标记;早上用户拍板用
  - 块3 头部候选 spec 草案(标【草案待拍板】,≤150 行)
  - 块4 早班预收账:双端 [READY] 预 Gate 检查(merge-tree 预检,不合并)+ handoff 文档
- 真机塔 42 目检未排(需用户在场),留早上收账后;第八阶段关账以它为准

## 巡查 SOP(cron 唤醒时执行)
1. 双端活性:`ps aux | grep -E 'codex|kimi'` + log 行数增量(codex 判活=日志持续涨;卡在 banner+prompt 回显=挂死,别只看进程在)
2. 挂死处理:codex → `codex exec resume --last`(不认 --cd/--sandbox,workdir 继承);kimi → `~/.kimi-code/bin/kimi -r <sid>`(-p 结束会打印续跑命令,log 尾可查)
3. `git -C <worktree> log --oneline -5` 查 [READY]/[BLOCKED];`status` 查未提交残留
4. 出现 [READY] → 预 Gate 记录(不合并;合并等早上用户说「收账」)
5. 更新本文件「进度」段
6. Claude 自主活块未完则继续做;全完则本次唤醒只巡查

## 用量护栏(方案详 memory feedback_overnight_quota_refresh_scheduling)
- 双端配额独立,Claude 撞墙不影响其整夜跑;重活已前置发出
- cron 唤醒失败(配额尽)→ 下一 cron 点自动重试 = 天然等到窗口刷新,无需精确刷新时刻
- 唤醒节奏:23:41 / 01:41 / 03:41 / 05:41 巡查 + 22:47 接力(块1/块2)+ 06:07 收尾(块4)

## 进度(唤醒时更新)
- [x] C1 发出(22:2x) / [ ] C1 [READY]
- [x] K1 发出(22:26) / [x] K1 全序列 [READY](23:1x 收官:0e9e1c22 目标1+246449bf 目标3+ac449241 报告;目标2 审计零可修项;预 Gate 复核过=analyze 0+4 测试文件 5/34/3/24 全绿本会话实测;全量留收账)
- [x] 块1(23:0x 完成:spec §1 订正/BACKLOG 四区销账/P2③ 勾销/.codegraph 收尾:db 重建成功(1294 files/56273 edges,CLI 验证);locked 根因=双 serve 进程锁竞争(8/5 起 45440 与 8/6 起 20757);误杀本会话连接的 45440 致本会话 MCP 断连(grep 兜底不阻塞),20757 现独占锁,下会话预期自愈——教训:kill MCP server 前先验 ppid 归属,启动时间早≠残留) / [x] 块2(direction_candidates_2026-08-07.md,55 行) / [x] 块3(23:1x 提前完成:playtest-data-collection-draft 43 行) / [ ] 块4

## 块4 预收账终稿(8/7 01:3x,双端收官后提前完成)

### 验证矩阵(全部本会话实测)
| 端/批 | 产出 | analyze | targeted | 全量 | merge-tree |
|---|---|---|---|---|---|
| kimi K1(3 commits,tip `ac449241`) | 目标1 Random 注入化 15 位点+契约测 / 目标2 审计零可修项 / 目标3 假绿修 3 处 | 0 issues | 4 文件 5/34/3/24 全绿 | **4885/0**(=4880+5 守恒吻合) | vs main CLEAN |
| codex C1(`62986b1a`) | 20 张题字清除(固定 8+narrative 105 全查命中 12),印章保留,contact sheet×4 | —(纯资产) | asset 4 件套 4/3/2/3 全绿 | 不适用 | vs main CLEAN |
| 双分支互检 | lib/test vs assets 零交集 | — | — | — | CLEAN |

### Claude 侧产出(已进 main)
`001c14bc` 派单包 → `fc702a86` 块1 订正×3+块2 方向盘点 → `52881aac` 块3 试玩采集 spec 草案 → `40df126d` codegraph 根因记录。

### 等用户拍板项
1. **「收账」指令** → 合并两分支(零冲突,建议 kimi 先 codex 后)+CI 确认
2. **C1 视觉终拍**:contact sheet 在 `docs/dispatch_evidence/inscription_2026-08-06/`(抽验 2 张初检 PASS)
3. **方向盘点拍板**:`docs/audit/direction_candidates_2026-08-07.md`(A1 试玩数据阀门头部推荐)+ 配套 spec 草案
4. **真机塔 42 目检**(第八阶段关账最后一验)
5. **工作流优化 A-F 拍板**(昨晚探讨:首件抽检/追加单池/夜合/真机录屏/刷新点/扇出 review)

### [BLOCKED]:无。收账末问:本批「预热 worktree(pub get+dylib+build_runner)」已手工做 3 次,值得封装成脚本/Skill。
