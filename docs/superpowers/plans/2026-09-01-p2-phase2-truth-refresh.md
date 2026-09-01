# 二阶段权威总账校准计划

## 结果合同

- 单一目标：把 M5 工程集成后的实时事实写回 `PROGRESS.md` 与 Phase 2 task registry，并补齐 M0–M9 顶层门，避免候选完成、工程完成、真人验收和正式里程碑混写。
- 基线：`main == origin/main == e10cdcc528a14d8a35dc2d836ee45d714bf0ce30`，worktree clean；M5 工程分母 42/42 已集成，本地全量 5861/5861，精确 SHA CI run `33512497821` 最终成功。
- 固定分母：正式里程碑仍按未加权 M0–M9 共 10 门报告；当前仅 M1 关闭，结果为 `1/10`。
- 本门增量：治理真相从旧基线与缺失顶层门，推进为 M0–M9 全覆盖、M5 精确集成状态可追溯、真人挂账独立列示。
- 成本上限：仅治理文件；不重跑已在精确 main SHA 完成的全量测试，不触碰生产代码、数值、schema 或存档。

## 工作区与所有权

- 分支：`codex/p2-phase2-truth-refresh-20260901`
- worktree：`/Users/a10506/.codex/worktrees/p2-phase2-truth-refresh-20260901`
- 基线：`e10cdcc528a14d8a35dc2d836ee45d714bf0ce30`
- owned files：
  - `PROGRESS.md`
  - `docs/dispatch/phase0a_overhaul/task_registry.yaml`
  - `docs/superpowers/plans/2026-09-01-p2-phase2-truth-refresh.md`

## 非目标

- 不修改 `lib/`、`data/`、`test/`、`GDD.md`、`CLAUDE.md`、持久化 schema、版本号、数值、奖励、技能或战斗规则。
- 不代替 M2/M4/M5/M6 的真人桌面、视觉或 Windows 验收。
- 不把历史 READY、局部测试或候选分支计入正式 `1/10`。
- 本门不实施 M3；总账集成后再独立建立 M3 首门。

## 验收门

1. `PROGRESS.md` 与 task registry 同时记录精确 main/origin SHA、M5 本地全量和精确 SHA CI。
2. 正式门固定为 M0–M9、关闭 1 门、仅 M1，权重未批准。
3. registry 中 M0–M9 每个里程碑至少有一个顶层状态条目，任务 ID 唯一。
4. M2/M4/M5/M6 的真人或 Windows 缺口独立挂账；M3/M7/M8/M9 明确为未关闭门。
5. M5 工程顶层条目从候选态更新为已集成、已 push、精确 SHA CI 成功。
6. YAML 可解析，`current_authoritative_wip` 最多一个，diff check clean。

## 恢复点

- 每次恢复先核对 `git status --short`、分支名与基线祖先关系。
- 本门 READY 后只允许 fast-forward 合入 main；main 不直接落笔。
- 若总账语义校验失败，停在本分支修正，不启动 M3。
