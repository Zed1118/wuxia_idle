# 夜批盘面 2026-08-07(断点续跑唯一真相源)

> 开工 16:05 · 目标收官 ~次日 00:00(8h 档,用户未报时长按 8h 默认,做到哪冻到哪)
> 基线:main `fdd23305` · analyze 0(本会话实测 5.9s)· 全量 4886/0(交接口径,合并前须复跑)

## 在跑单

| 单 | 端 | 分支 / worktree | log | 状态 |
|---|---|---|---|---|
| Q2 配置声明vs硬编码背离扫描 | qoderclicn | `qoder/config-bypass-audit` / `qoder-config-bypass` | `q2_qoder.log` | 派于 16:09 |
| K2 假绿抽查扩面(7目标序列) | kimi | `kimi/night-goals-0807` / `kimi-night2` | `k2_kimi.log` | 派于 16:26,已预热 |
| C2 桃花岛7建筑水墨图 | codex | `codex/taohua-art-0807` / `codex-taohua` | `c2_codex.log` | 派于 16:31 |
| L1-A 核心文档路径修复 | pi | `pi/doc-links-s1` / `pi-links-s1` | `l1a_pi.log` | 派于 16:47 |
| L1-B docs/spec 路径修复 | codebuddy | `cb/doc-links-s2` / `cb-links-s2` | `l1b_cb.log` | 派于 16:47 |

log 目录:`$CLAUDE_JOB_DIR/tmp/`(= `/Users/a10506/.claude/jobs/1dedbe6d/tmp/`)

## Claude 自留活(不下放)

- **N1** numbers.yaml 16 字段处置(红线)——**已发现 2 条非文档问题**,见下「代拍决策」
- **R1** 真机录屏验收塔 42 协同演出(真机位,每晚限 1)
- **P3** RELEASE_CHECKLIST E 段 reconcile(BGM 已实装未勾等 stale 批注)

## 本夜代拍决策清单(供次日复核/推翻)

1. **时长按 8h 默认**:用户说「开始挂机任务流」未报时长,已问过一次不二次阻塞;超排原则下时长偏差由「做到哪冻到哪」吸收。
2. **C2 重定义**:候选池原描述「岛景背景+7 建筑热区立绘,只换皮」**前提错误**——背景图已是成品水墨(1456×816,过 `webp_in_png_decode_test.dart:45-46` 守卫),热区是 152×94 信息卡、图标位仅 18-21px 塞不下立绘。改为出「图标级 256²透明 + 卡背景级 1408×864 + 主菜单入口图 + 背景候选」四类 25 张。
3. **背景图不替换**:换现役成品美术属视觉终拍,留用户;但**出 2448×1224(比例 2.0)候选**供次日对比——现图 1.784 在 2.0 场景框里被 cover 裁掉 11-16%,2x 屏下 1456 源宽欠采样(cacheWidth 需 ~2496)。不出候选=省力伪装。
4. **新增 Q2 单**(不在原候选池):核 N1 时实锤 `rarity_distribution` 是「配置声明了、生产硬编码绕开」,前两轮审计结构性逮不到,值得全仓扫。
5. **L1 大幅缩范围**:原「1092 处按目录分片并行修」**会造成实际损害**——398 条指向 .gitignore 声明不入库的产物(合规非失修)、29 条是 fresh worktree 没跑 build_runner 的 `.g.dart` 假阳性、`docs/handoff/week15_phase5_3_*.md` 本身是迁移账本改了自毁。真候选 ~630,只派其中「现役文档失修」约 90 条(S1+S2 两片)。
6. **新产出 `docs/PATH_MIGRATION_MAP.md`**:侦察实测的旧→新路径全表落成仓内文档(以前不存在),两个 L1 分片共同依赖。

## 巡查 SOP

- 挂死判定:log 15min 零增长 → resume(kimi `-r <sid>` / codex `exec resume --last` / pi `-r`)
- 收工判定:**git 分支 tip 以 `[READY]`/`[BLOCKED]` 开头 + worktree 干净**(log 只作辅助;qoderclicn 输出到结束才落盘,log 为 0 不代表挂死)
- 收工后:预 Gate → 滚动池取次一单续派(域检查:与在跑单文件域不相交)
- 验证数字一律 Claude 本会话复跑,禁采信执行端自报

## 滚动池(待续派)

| 单 | 端 | 备注 |
|---|---|---|
| L1-C S3/S4/S5 档头批(handoff/superpowers/sessions 共 219 文件插归档档头) | pi 或 codebuddy 收工后续派 | 纯机械+幂等,验收走 grep 计数;**不降死链数**,验收判据用覆盖率不用降数 |
| L1-D 入仓 `tools/doc_link_scan.py` 死链扫描脚本 | 任意代码端 | 现无 link-check 工具;须内置 `git check-ignore` 过滤 + 用 `git ls-files` 判存在性(否则重现 1092 假数) |
| P2 真机录屏管线 | Claude | 见自留活 R1 |
| P3 checklist E 段 reconcile | Claude | 语义敏感,勾 checklist ≈ 代拍板,只加批注 |
