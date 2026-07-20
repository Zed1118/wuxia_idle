# 测试质量硬化批：弱断言强化 + flaky 锚定 + 边界补齐 + 过 mock 纠偏

> 派单日期：2026-07-20。分支 `kimi/test-hardening`（基点 main@4a61a47e），
> worktree `.worktrees/kimi-harden`。执行协议：CLAUDE.md §8.0/§8.2/§8.3。
> 上一批（provider/service 覆盖 19 测）已合 main，本批不刷覆盖数字，审现有测试
> 套件**质量/健壮性**，揪弱测并加固。

## 目标

按四类审 `test/` 现有测试（先扫定候选，从命中最多的文件起，**序列制**逐文件，
每文件独立 commit）：

1. **弱断言**：只断言 isNotNull/isNotEmpty/长度，不验具体值/语义 → 强化为语义断言。
2. **隐性 flaky**：依赖迭代顺序/时间/全局单例/并发共享 → 加确定性锚
   （排序/固定 seed/隔离 setUp）。
3. **缺边界**：只测 happy path，缺错误/空/越界/并发路径 → 补边界用例。
4. **过度 mock**：mock 到不测真实行为 → 改真实入口驱动。
   （预备注：全仓 grep 无 mocktail/Mockito/Fake 使用，本类预计稀少。）

**每处加固先复现弱点**：强化断言先填错误期望值跑 RED（证原断言宽松、新断言有牙），
改回正确值转绿后再提交，不盲改。

## 禁区（碰=立即 [BLOCKED] 停）

- `lib/features/battle/**`、`test/features/battle/**`、`test/combat/**`（codex 并行占 battle）
- `data/` 全目录、数值/schema/红线测试（`test/data/**`、`test/balance/**` 红线类）、
  `pubspec.yaml`、`lib/shared/strings.dart`、`GDD.md`、`PROGRESS.md`、`BACKLOG.md`、
  `NEXT*`、saveVersion、结算公式层
- 不改 `lib/` 生产逻辑；发现疑似生产 bug → 记「发现项」+ 必要时 `[BLOCKED]` 冻结
- 主 checkout（/Users/a10506/Desktop/Projects/挂机武侠 顶层）只读

## 验收（每文件，§8.2 四证据批末汇总）

- 加固后该文件 targeted 绿 + `flutter analyze --no-pub` 0 issue
- 恢复点记：审了几文件 / 加固几处 / 各属四类哪类 / 发现的生产 bug（若有）
- 批末：一次全量 `flutter test --no-pub`（并发）绿；树净 + tip 前缀
  `[READY] 测试质量硬化批交付`

## 候选清单（弱断言模式命中数降序，扫于 2026-07-20）

| 命中 | 文件 | 初判 |
|---|---|---|
| 25 | test/features/debug/application/phase2_seed_service_test.dart | 多为 null 守卫+具体值，实弱点多在「装备齐只查 id 非空」类 |
| 22 | test/features/equipment/application/equipment_disposal_service_test.dart | 待审 |
| 10 | test/features/mainline/presentation/apply_victory_resolution_test.dart | 待审（上批留偶发观察项） |
| 9 | test/features/taohua_island/island_settle_service_test.dart | 待审 |
| 9 | test/features/sect/stage_boss_recruit_test.dart | 待审 |
| 9 | test/features/seclusion/application/seclusion_service_test.dart | 待审 |

（5-7 命中档：offline_recap_service / sect_providers / equipment_catalog_service /
sweep_unit / onboarding_service / inner_demon_narrative / expedition_config_load /
expedition_combat_runner / gauntlet_providers / gauntlet_enemies —— 视进度续审。）

## 任务切片

- [ ] 切片 1：计划文件 + 候选扫描（本文件）
- [ ] 切片 2+：逐文件审→复现→加固→targeted+analyze→commit（逐文件追加记录）
- [ ] 末片：批末全量绿 + 四证据 + [READY] 冻结

## 逐文件记录

（执行中追加：每文件记 审到的问题分类 / 加固点 / RED 证据 / targeted 结果 / commit）

## 当前恢复点

- **状态**：切片 1 完成（候选已扫定），待逐文件开审。
- **最后完成**：计划文件建立；候选清单按弱断言命中数降序（见上表）；
  全仓无 mock 框架使用（类别 4 预计稀少）。
- **下一步**：从 phase2_seed_service_test.dart 起逐文件审+加固。
- **已跑验证**：无（尚未动测试）。
- **阻塞项**：无。

## 发现项（疑似生产 bug，只记录不修）

（暂无）
