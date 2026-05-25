# P5.0 Onboarding Production Seed Closeout · 2026-05-25

> 体量 ≤80 行 · Mac+Opus xhigh ~1h(spec 估 1.5-2h · 精度 0.5-0.67×)
> 范围:audit `1_0_release_audit_2026-05-25.md` P0-1 release 阻塞修复
> 1 PR `feat/p5_onboarding_seed_p0_fix` squash merge 推 origin/main · 1476 → 1484 测 / 0 analyze

## TL;DR

**P0-1 release 阻塞清 ✅**:玩家全新启动游戏 → splash → home_feed → main_menu → 任何战斗不再 crash(原 `StageBattleSetup._buildPlayerTeam` 抛 `StateError('先跑 P1 种子')`)。沿 spec `p5_onboarding_seed_spec_2026-05-25.md` 默认决策 A+X+M+P+S+V+N 全跑通,实测 ~1h 0.5-0.67× 精度(快于估)。1.0 整体 90% → 91%。

## 实装清单(6 step 串行)

| Step | 内容 | 实测 |
|---|---|---|
| 1 helpers 抽 | `lib/features/onboarding/application/master_builder.dart` 5 top-level functions(buildMasterCharacter / defaultMasterName / equipMasterStarting / learnMasterStarting / seedBasicMaterials)+ `phase2_seed_service` wire | ~12min |
| 2 OnboardingService | `ensureFoundingMasters()` 幂等(信源 Character.isFounder=true count > 0)+ Character × 3 + Equipment × 9 + Technique × 4 + SaveData wire + 物料 50/0 | ~10min |
| 3 SplashScreen wire | `_bootstrap` IsarSetup.init 之后 `await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters()` | ~3min |
| 4 P1 顺带 | main_menu Phase 1/2 入口 `if (kDebugMode) ...[]` 包裹 + home_feed empty hint 加「按下「直入江湖」启程」引导 | ~5min |
| 5 R5 测族 8 测 | R5.1-R5.8 覆盖全 path · 1476 → 1484 / 0 analyze | ~20min |
| 6 收尾 doc + PR | spec/ROADMAP/PROGRESS + closeout + PR | ~10min |

## 关键决策

| Q | 决策 | 备注 |
|---|---|---|
| Q1 落点 | A 独立 `lib/features/onboarding/` 包 | 对齐 lib/features/* 体例 · 1.1 可扩 "创角向导" |
| Q2 触发 | X `SplashScreen._bootstrap` IsarSetup.init 后 | 用户感知不到(splash loading 期 +~200ms 写 Isar) |
| Q3 幂等 | M count(isFounder=true) > 0 跳过 | 信源 Character ≠ SaveData(R5.3 守):异常态 SaveData 被清空 Character 仍在 → 不重 seed |
| Q4 debug seed 保留 | P 保留 `seedMasterDisciple` | dev/test 工作流必备 · 8+ test caller 零改动 · 共用 master_builder.dart helpers |
| Q5 拆 PR | S 单 PR | scope ~1h · 拆 B 反增开销 |
| Q6 P1 顺带 | V 带 P1-1 + P1-3 · P1-2 后查 | kDebugMode 1 行 free + home_feed 文案 1 段 free |
| Q7 worktree | N feat 分支 squash | 沿 P4.1 体例 |

## R5 测族(8 测 · spec §4 Step 5)

- **R5.1** 全新 db ensureFoundingMasters → true · Character × 3 · SaveData.activeCharacterIds=[1,2,3] · founderCharacterId=1 · sectName='我的门派'
- **R5.2** 二次调用幂等 → false · Character count 不增
- **R5.3** 手写 founder(isFounder=true)但 SaveData 空 → false(信源 Character)
- **R5.4** Equipment count=9 · Technique count=4 · founder.equippedWeaponId/armorId/accessoryId + mainTechniqueId + assistTechniqueIds.length=1
- **R5.5** 真战斗 e2e:`StageBattleSetup(isar).buildTeams(stage_01_01)` 返 (left.length=3, right.length≥1)不抛 StateError(audit P0-1 修复证)
- **R5.6** founder.id 严格锚 1(与既有 main_menu / character_panel 对齐)
- **R5.7** sectName ??= 不覆盖(预写 '剑湖派' 不被覆盖 — 1.1 自定义场景守)
- **R5.8** 物料 magic 50 / jie 0(§5.1 反留存不爆量 vs debug seed 2000/200)

## 不变量(全保)

- 不动 GDD / CLAUDE.md / numbers.yaml / masters.yaml / data_schema.md / IDS_REGISTRY.md
- 不动 §5.4 红线(20k/15k/8k/2k) / §5.3 三系锁 / §5.5 在线=离线 / §5.1 反留存 / §6 公式
- 不动 Isar schema 版本 0.13.0(无新 collection)
- 不动 `Phase2SeedService.seedMasterDisciple` 主流(8+ test caller 全过)
- 不动 master_disciple_battle_test × 6 / founder_buff_service_test × 2 / phase2_seed_service_test × 47

## 文件改动清单(7 file)

- 新建 `lib/features/onboarding/application/master_builder.dart`(165 行 · 5 top-level functions)
- 新建 `lib/features/onboarding/application/onboarding_service.dart`(108 行 · OnboardingService class)
- 新建 `test/features/onboarding/application/onboarding_service_test.dart`(192 行 · 8 R5 测)
- 改 `lib/features/debug/application/phase2_seed_service.dart`(删 5 helpers ~120 行 / wire master_builder import + caller / 删 master_def unused import)
- 改 `lib/features/splash/presentation/splash_screen.dart`(+3 行 wire OnboardingService)
- 改 `lib/features/main_menu/presentation/main_menu.dart`(import foundation + if kDebugMode 包裹 Phase 1/2)
- 改 `lib/shared/strings.dart`(homeFeedEmptyHint 加引导一句)

## 挂账(留 1.1+)

- **P1-2** fallback id=1 `_SeclusionMenuButton` defaultCharacterId=1 / defaultRealmTier=xueTu 是 phase 2 dev seed 习惯,P5.0 落地后 grep 是否仍 stale 再说(audit P1 三项已部分清,P1-1 + P1-3 顺带做完)
- **创角向导 UI**:新玩家姓名/性别/属性自定义 — Demo 用 masters.yaml 默认
- **多槽存档**:P5 isar_setup TODO 已留
- **sectName 自定义 UI**:R5.7 守 ??= 不覆盖语义,1.1 自定义后保留

## 下波候选(留新会话)

| 选项 | 工作量 | 推荐 |
|---|---|---|
| Pen Codex Windows 视觉验收(P4.1 sect_screen 4 Tab + P5.0 全新启动 e2e 视觉) | ~1h 异步 | ★★★ 最自然衔接 |
| 1.0 整体 audit v2(剩余 P2/P3/P4 视觉/UI/数值/性能审计) | xhigh 2-3h | ★★ 冲 1.0 release ~95% |
| 1.1 挂账起点(Q6 A encounter recruit) | xhigh 4-6h | ★ 1.0 90→95% 后再开 |
