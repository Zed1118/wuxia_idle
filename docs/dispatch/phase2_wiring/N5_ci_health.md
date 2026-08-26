# 批 N5:CI 健康度实测(2026-08-26)

分支 `codex/p2-n5-ci-20260826`,基线 `6ab44026`,worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-n5-ci`。
**只读单。**

## 背景

本项目有过「scoped lint 绿但全仓 CI 长期红无人发现」的实录。main 已领先 `origin/main` 700+ commit 且**未 push**,
所以 CI 上跑的是**很旧的代码**——需要弄清 CI 当前到底是什么状态、最后一次成功是什么时候、红在哪。

## 任务

用 `gh` CLI(已装且 authed)实测,**不要凭印象**:
1. `gh run list` 取最近 20 次运行:workflow 名 / 分支 / `conclusion` / headSha / 时间;
2. 找出**最后一次 success** 与**最早的连续失败起点**;
3. 对最近一次失败,取 job 层日志,定位失败步骤与错误首行;
4. 核对 CI 里钉的 flutter 版本与本地实际版本(`flutter --version`)是否一致;
5. 列出仓库现有 workflow 文件及各自触发条件(`.github/workflows/`)。

> **注意**:`gh run watch --exit-status` 的退出码会掩盖 cancelled,**必须显式读 `conclusion` 字段**,不要靠退出码判定。

## 产出

`docs/audit/ci_health_20260826.md`(**≤80 行**):基线 sha + 上述 5 项的实测结果 + 一句话结论
(CI 当前是绿 / 红 / 从未跑过本地这 700 commit)。**不给修复方案**,只给事实。

## 硬约束

- **只读**:除上述一个 `.md` 外不得改任何文件。禁 push / 禁 merge / 禁碰 main。
- 禁区同前:`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`。
- commit 中文动宾,tip `[READY]`/`[BLOCKED]`,工作区干净。
- **不得 push 任何东西来「触发 CI 看看」**——那会把 700 个未审 commit 推上去。
- 数字实测禁估算,贴命令原始输出。

## [BLOCKED] 出口

- `gh` 未认证或无权限读 Actions;
- 需要 push 才能得出结论(那就停下报告,不要推)。

## 协调者怎么验收

我会复跑 `gh run list` 核对最近几行。出现 push / 代码改动 = 直接打回。结论与贴出的原始输出对不上 = 打回。
