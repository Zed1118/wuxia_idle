# N9 · BACKLOG 补给扫描(只读提案)

## 背景

`BACKLOG.md` 的「二·已解锁可派」与「四·方向级候选」**两栏都是空的**(2026-08-26 实测),
而 M0–M9 仍报 `1/10`。项目处于 1.0 长线打磨期、显然远未做完——所以池空不是「做完了」,是**储备没人喂**。
后果:夜批跑到半程就无活可派,而真实待办散在 PROGRESS 挂账段、audit followup、spec 未实装项和代码 TODO 里,没被归纳。

## 目标

扫下列四个源,把**未被 BACKLOG 收录**的真实待办归纳成候选条目提案:

1. `PROGRESS.md` 的挂账 / 已知问题 / 下一步段
2. `docs/audit/` 下各报告的 followup / 未覆盖 / 残留风险段
3. `docs/spec/` 下标注未实装 / 待接线 / 候选的条目
4. 代码内 `TODO` / `FIXME` / `XXX` / `HACK` 注释(带 `file:line`)

每条提案给出:一句话描述 / 证据 `file:line` / **准入三态判定**(待拍板 / 已解锁未做 / 依赖锁死,依赖锁死须写再开条件)。

## 范围围栏(机器可判)

- 改动必须**恰好 1 个文件**:`docs/audit/backlog_replenish_proposal_20260826.md`
- `BACKLOG.md` **一行都不许改** —— 你只出提案,销账与入账由协调者做
- `lib/` / `test/` / `data/` / `PROGRESS.md` 改动数必须为 **0**
- 报告 ≤130 行

## 禁止的修法

- ❌ 禁止改 `BACKLOG.md` 或 `PROGRESS.md`。
- ❌ **禁止发明任务**。每条提案必须能指到一个已存在的证据位置;没有 `file:line` 的条目不许写。
- ❌ 禁止把「本次没空做 / 可以顺手优化 / 建议重构」写成条目 —— BACKLOG 准入三态明确排除这类,写了即作废。
- ❌ 先读 `docs/spec/rejected_task_registry.md`(反向储备),**已拍死不做的不许重提**;命中的单列一段「已拍死,不重提」。

## [BLOCKED] 出口条件

- `docs/spec/rejected_task_registry.md` 不存在或无法解析 → 停 `[BLOCKED]`(没有反向储备就无法保证不重提)。

## 验收方式

1. `gate.sh <worktree> <base> HEAD --skip-full` 必须 PASS
2. 抽查 5 条提案的 `file:line`,现场核对证据是否真在那里
3. 协调者自查:提案里是否混进了 rejected_task_registry 已拍死项

## 硬约束(全部照抄自协调者契约,违反即作废)

**执行端禁区文件**(一行都不许改):`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`

- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- commit message 用**中文动宾**,tip 打 `[READY]`(写完待评)或 `[BLOCKED]`(需拍板)
- 收工时工作树必须干净(`git status -sb` 无未提交实质改动、无未跟踪文件)
- 🔴 红级(玩家可见 UI / 数值与成长规则 / schema 迁移 / 删配置字段或功能 / GDD 解释)→ **停 `[BLOCKED]`,禁代拍**
- **数字必须实测**,禁转抄历史、禁凭记忆写 `file:line`;每条引用现 grep 定位
- 搜不到 ≠ 不存在:`git grep -E` 是 POSIX ERE **不认 `\s`**(静默永不匹配);先搜中文/领域词找代码真实命名
