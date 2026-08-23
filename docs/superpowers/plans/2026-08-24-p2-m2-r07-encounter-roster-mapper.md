# P2-M2-R07：Encounter roster mapper

## 目标与边界

在 C01 content definition、R04 exact `SpawnDirector` 与现有 `Phase0aEncounterRoster` 之间新增纯 data-validation 薄映射。actor 的完整战斗属性由调用方 factory 显式构造；mapper 只负责 entry 集合闭合、权威 runtime enemy ID 传递与 roster binding。

- 分支：`codex/phase2-m2-r07-encounter-roster-mapper-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r07-encounter-roster-mapper`
- 基线：Batch11 READY `57f04b397d1412128535ba8f74a7e61ecdfb4577`
- 只允许：`lib/data/validation/combat_encounter_roster_mapper.dart`、`test/data/validation/combat_encounter_roster_mapper_test.dart`、本计划。
- 禁止：task registry、`GDD.md` / `CLAUDE.md` / `PROGRESS.md`、production host/YAML/UI/save/reward/injury/tuning、actor stats/default positions。

## 冻结合同

- API 接收 exact `CombatEncounterDef`、exact `SpawnDirector`、显式 `playerId` 与 required `CombatEncounterActorFactory`。
- 在 factory 第一次调用前，按 entryId 集合双向核对 definition 与 director 全量 units；缺失、额外或等数量替换均 fail closed，factory 零调用。
- 校验通过后按 `definition.spawnEntries` content 顺序调用 factory，每项恰好一次；runtime enemy ID 只来自 director snapshot，绝不使用 entryId fallback。
- actor 校验交给 `Phase0aEncounterRoster`：actor.id 必须等于 enemyId、enemy side、初始存活、不得与 playerId 冲突、绑定与 actor ID 全量唯一。
- factory 异常与 roster 校验异常原样传播，不暴露 partial roster；每次调用返回 fresh immutable roster owner。
- mapper 不推进 definition/director，不持有 callback/外部可变集合，不接 production host，不提供 stats/position/default/tuning。

## 验收 checklist（CLAUDE §8.2）

- [x] TDD 红测明确由目标 mapper/API 缺失触发，后续转绿。
- [x] 覆盖正常映射、显式 enemy ID、content 调用顺序与 factory 恰一次/entry。
- [x] 覆盖 definition/director missing/extra/replaced entry drift 且 factory 零调用。
- [x] 覆盖 factory throw 原样传播；actor id/side/alive/player failures 由 roster fail closed。
- [x] 覆盖 fresh immutable ownership、输入 definition/director 不推进不替换。
- [x] source audit 证明无 entryId enemy fallback、无 production host/import/default/tuning。
- [x] targeted mapper + roster/director/R04 合同测试全绿；变更 Dart scoped analyze 0 issue；format 与 `git diff --check` 通过。
- [x] 生产接线证据：按本切片授权明确不接 production host；交付是后续 host actor assembly 的纯 gateway，不冒充上线。
- [x] 红线：0 production 数值/公式，0 玩家文案，0 三系/在线离线/反主流/奖励/伤势/save/UI 触点。
- [x] 实现/证据提交后追加 `[READY][QODER][P2-M2-R07]` 空提交，工作树干净。

## Qoder 审查

- CLI：`qoderclicn` 1.1.28；可用模型确切标识 `Qwen3.8-Max`。
- 设计审查：实际使用 `Qwen3.8-Max` + `--reasoning-effort high` + 只读工具，结论 PASS。建议先构建 director entryId → snapshot，再做双向集合比较；通过后按 content 顺序取权威 enemyId 调 factory，最后委托 roster 校验。重点补测 drift 时 factory 零调用、factory 异常透传、输入不推进。
- 最终 diff 审查：实际使用同一 `Qwen3.8-Max` + `--reasoning-effort high` + 只读工具，结论 PASS，P0=0、P1=0。审查给出 4 条非阻塞 P2 备注：一条测试命名已收窄；其余为冗余 source guard、权威 runtime enemy ID 允许不同值、仓库既有相对 cwd audit 惯例，均不构成代码缺陷或合同缺口。
- 全程不得记录或输出 token/key。

## 任务切片

1. 完整读取项目红线、已否清单、C01/R04/director/roster/actor 合同与相关测试。
2. Qoder/Qwen3.8-Max high 只读设计审查；新增测试并跑出红测。
3. 用 `apply_patch` 实现薄 mapper，运行定向回归。
4. Qoder/Qwen3.8-Max high 最终 diff 审查；主 agent 复核并修正 findings。
5. format、scoped analyze、diff/path/production isolation 审计；更新恢复点、提交证据并打 READY。

## 当前恢复点

- 状态：实现、验证与 Qoder 最终审查完成，准备提交并冻结分支。
- 最后完成：新增纯 mapper；entry set 漂移在 factory 首调前 fail closed，通过后按 content 顺序传递 director 权威 runtime enemy ID，并委托 roster 完成 actor 校验。红测先因目标文件/API 缺失编译失败，实现后转绿。
- 下一步：提交实现/证据，追加 `[READY][QODER][P2-M2-R07]` 空提交，交主控独立复审和 Batch12 集成。
- 已跑验证：新 mapper 8/8、R04 mapper 8/8、content definition 20/20、roster 9/9、SpawnDirector 33/33，共 78/78 通过；scoped analyze 2 files 0 issue；Dart format 与 `git diff --check` 通过。Qoder 1.1.28 / `Qwen3.8-Max` / high 设计审查与最终审查均 PASS。
- 阻塞项：无。
- 生产接线：依授权不接 production host；后续 host 必须显式提供 actor factory。
- 红线影响：预期无生产数值、玩家文案、奖励、伤势、save、UI、三系、在线离线或反主流触点。
- 残留风险：本切片不验证 production actor 装配与候选数值；Batch12 集成后仍需独立复审和批末全量验证。
