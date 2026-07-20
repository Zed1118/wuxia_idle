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

### ① test/features/debug/application/phase2_seed_service_test.dart（commit 44b73aaa）
- 审出：类别1 弱断言 3 处；类别2/3/4 未见实弱（真 Isar 临时目录隔离、
  集合比较用 Set/containsAll、已有 clear/reseed 幂等边界）。
- 加固：
  1. 「师徒装备齐」由 equippedXxxId 非空 → 每件 id 可解析 + slot 匹配 +
     ownerCharacterId 归属本人 + 主修 role=main 归属本人（悬空 id 旧断言抓不到）。
  2. 「buildTeams 不再 fail-fast」敌队 isNotEmpty → right.length ==
     stage.enemyTeam.length（与 def 对齐）+ negative id 约定（characterId<0）。
  3. 「W14_3 reseed」大弟子 equippedEncounterSkillId 非空 → 仍在 unlock 池内。
- RED 证据：3 处填错值（owner+100 / enemyTeam.length+1 + id>0 / bogus skill id）
  → +36 -3，仅目标 3 用例红，改回真值 → **39/39 绿**；analyze 0；format 0。

### ② test/features/equipment/application/equipment_disposal_service_test.dart（commit 5be31f19）
- 审出：类别1 弱断言 6 处（拒绝路径只查「装备仍在」不查「字段未被改写」）；
  类别3 缺边界 2 处（批量处置测全 +0，强化加成在批量路径无覆盖）。
- 加固：
  1. 6 处拒绝测补字段不变量：rejectedEquipped×2（ownerCharacterId 1/42 不被改写）、
     rejectedHeritage×2（isLineageHeritage 仍 true）、rejectedLocked×2（isLocked 仍 true）。
  2. 新测 sellAllOfTier 带强化（liQi+3 ×2 → totalSilver 728=2×280×1.3）。
  3. 新测 disassembleAllOfTier 带强化（liQi+2 ×2 → mj 18=2×(7+2)、xx 2）。
- RED 证据：字段探针填错（999/isFalse）+ 新测填「批量忽略强化加成」错误值
  （560/14）→ +19 -8 精准 8 红（Actual 728/18 证批量逐件计入强化加成），
  改回真值 → **27/27 绿**；analyze 0；format 0。

## 当前恢复点

- **状态**：文件 ①② 完成并已各自独立 commit，继续候选表文件 ③。
- **最后完成**：② equipment_disposal_service_test 8 处加固（27/27 绿，5be31f19）。
- **下一步**：③ apply_victory_resolution_test.dart（10 命中，上批留偶发观察项）。
- **已跑验证**：① 39/39 绿 + analyze 0 + format 0；② 27/27 绿 + analyze 0 + format 0。
  两文件 RED→GREEN 均有运行记录（见各节）。
- **阻塞项**：无。

## 发现项（疑似生产 bug，只记录不修）

（暂无）
