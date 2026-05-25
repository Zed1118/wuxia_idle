# P5 Onboarding Seed Spec · 2026-05-25

> 体量 ≤150 行 · audit doc `1_0_release_audit_2026-05-25.md` P0-1 修复
> 范围:首次启动 production 路径自动 seed 3 师徒 · 不动 phase2_seed_service debug 路径
> 预估:opus xhigh ~1.5-2h(精度参考 P4.1 0.16× · 体量 < P4.1 B1+B2 ~3-4h)

## 1. 目标 + 范围

**IN**:
- 抽出 `OnboardingService.ensureFoundingMasters()` production 路径 — 从 `data/masters.yaml` 读 3 MasterDef → 写 Character × 3 + Equipment × 9 + Technique × 4 + SaveData.activeCharacterIds + founderCharacterId + InventoryItem 基础物料
- 幂等:已有 Character(isFounder=true)→ short-circuit 跳过
- wire 触发点:`SplashScreen._bootstrap` IsarSetup.init 之后
- R5 测族 5-7 测(全新 db / 幂等 / 反复启动 / SaveData wire / 战斗能进)
- 顺带修 P1-1 debug 入口 kReleaseMode 切除 + P1-3 空 feed 引导文案

**OUT**(留 1.1+):
- 新玩家姓名/性别/属性自定义(传统 RPG 创角)— Demo 用 masters.yaml 默认
- 多槽存档(P5 isar_setup TODO 已留)
- "开始新游戏" UI 界面(纯 splash → home_feed 直进)
- P1-2 fallback id=1(B1 落地后再 grep 确认是否仍 stale,不一定要改)

## 2. Phase 0 六维 grep 结果

| 维度 | 结论 |
|---|---|
| **schema** | `MasterDef.fromYaml` + `GameRepository.masters` × 3 已落 · `Character.create` + `EquipmentFactory.fromDef` + `Technique.create` 全 helper 已存在 |
| **caller** | production 0 caller(`Phase2TestMenu` debug only)· test 8+ caller(保留不动)· `StageBattleSetup._buildPlayerTeam:93` 抛 `StateError('先跑 P1 种子')` 是真阻塞 |
| **邻近目录** | `data/masters.yaml` 3 角色 def 已落 · `GameRepository._enforceMasterRedLines` 已校验 3 条 · 无 `lib/features/onboarding/` 包 |
| **UI widget** | splash/home_feed/main_menu **0 onboarding 入口** — debug 入口经 Phase2TestMenu → seedMasterDisciple 已 wire,production 无 |
| **红线层** | `test/features/battle/master_disciple_battle_test.dart` 6 测 + `founder_buff_service_test` 2 测 + `phase2_seed_service_test` 已有 — production 化后需新 R5 测族,debug seed 测族不动 |
| **公式** | `_buildMasterCharacter` 用 `realmDef.internalForceMax`(默认满血)· `_equipMasterStarting` 用 `EquipmentFactory.fromDef`(standard roll)· `_learnMasterStarting` 用 `Technique.create`(首项 main / 余 assist) · `_seedMaterials(mojianshi: 2000, jieJing: 200)` 基础物料 |

## 3. 设计决策点(待拍板)

| Q | 选项 | 我的倾向 |
|---|---|---|
| **Q1 production 落点** | A: `lib/features/onboarding/application/onboarding_service.dart` 独立 feature 包 · B: `IsarSetup._ensureFoundingMasters` 内联 · C: `lib/data/seed_service.dart` 顶层 | **A**:独立 feature 包对齐 lib/features/* 体例 · 1.1 后扩 "创角向导" 自然 · test 隔离容易 |
| **Q2 触发时机** | X: `SplashScreen._bootstrap` IsarSetup.init 之后 · Y: `HomeFeedScreen` 快速领取触发 · Z: `MainMenu.build` 首帧前 | **X**:最早触发 · 用户感知不到(splash 已有 loading 屏 + ~200-500ms 写 Isar)· Y/Z 让后续 screen 出 loading 状代码丑 |
| **Q3 幂等策略** | M: count(isFounder=true) > 0 跳过 · N: SaveData.activeCharacterIds 非空跳过 | **M**:Character 层信源 · 比 SaveData 字段更直接 · 万一 SaveData 字段被 reset 还能正确判 |
| **Q4 seedMasterDisciple debug 保留?** | P: 保留(reseed/test/视觉验收用)· Q: 删除(只 OnboardingService 用) | **P**:dev 工作流必备 · test 8+ caller 改造工作量大 · OnboardingService 复用 helpers(`_buildMasterCharacter`/`_equipMasterStarting`/`_learnMasterStarting`)从 Phase2SeedService 静态化导出 |
| **Q5 B1/B2 拆分** | S: 不拆单 PR · T: B1 service+wire / B2 R5+收尾 | **S**:scope 小(~1.5-2h)· 拆 B 反而增加 PR 开销 |
| **Q6 顺带 P1 三项?** | U: 全带(P1-1 + P1-2 + P1-3) · V: 只带 P1-1 + P1-3 · W: 都不带 | **V**:P1-1(kReleaseMode 1 line)+ P1-3(home_feed 文案 1 段)free 顺带 · P1-2(fallback id=1)B1 后 grep 看是否仍 stale 再说 |
| **Q7 worktree?** | Y: 走 worktree · N: 不走,feat 分支单 PR | **N**:改动 ~3-5 个文件 · 沿 P4.1 体例 feat 分支 squash PR |

## 4. 实装步骤(决策点拍板后细化)

预估按 **A+X+M+P+S+V+N** 默认:

**Step 1 · helpers 静态化导出**(~15min)
- `Phase2SeedService` 静态方法 `_buildMasterCharacter` / `_equipMasterStarting` / `_learnMasterStarting` / `_defaultMasterName` 抽出到新文件 `lib/features/onboarding/application/master_builder.dart`(top-level functions)
- Phase2SeedService import 改 wire(test 8+ caller 0 改动)

**Step 2 · OnboardingService**(~30min)
- 新建 `lib/features/onboarding/application/onboarding_service.dart`:
  ```dart
  class OnboardingService {
    const OnboardingService({required this.isar});
    final Isar isar;

    /// 幂等:已有 founder 跳过返回 false · 全新 db 走 seed 链返回 true
    Future<bool> ensureFoundingMasters() async {
      final count = await isar.characters.filter().isFounderEqualTo(true).count();
      if (count > 0) return false;
      // 沿 seedMasterDisciple 主流(无 _clearAll · 无 _seedMaterials 可选)
      // Character × 3 + Equipment × 9 + Technique × 4 + SaveData wire
      return true;
    }
  }
  ```
- Optional 物料:basic moJianShi(50)/jieJing(0)给新玩家试强化(不像 debug seed 给 2000/200)— 待拍板

**Step 3 · SplashScreen wire**(~10min)
- `_bootstrap` 末加:
  ```dart
  await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
  ```
- 不显额外 loading 文案(splash 已是 loading 屏)

**Step 4 · P1 顺带修**(~10min)
- P1-1:main_menu BattleTestMenu / Phase2TestMenu 包 `if (!kReleaseMode) ...`
- P1-3:home_feed `_EmptyHint` 文案改加「点'开始挂机'踏出第一步」(具体文案待拍板)

**Step 5 · R5 测族**(~30-45min)
- `test/features/onboarding/onboarding_service_test.dart` 新建:
  - R5.1 全新 db ensureFoundingMasters → 返 true + Character × 3 + SaveData.activeCharacterIds=[1,2,3] + founderCharacterId=1
  - R5.2 二次调用幂等 → 返 false + Character count 不变
  - R5.3 已存在 founder 但活跃槽空 → 返 false(信源是 Character 不是 SaveData · 与 Q3=M 对齐)
  - R5.4 装备/心法/物料正确(沿 master_disciple_battle_test 体例 spot-check)
  - R5.5 真战斗 e2e:ensureFoundingMasters → StageBattleSetup._buildPlayerTeam 不抛 StateError(对齐 audit P0 复现 → 修)
- 期望:8 测 · 1476 → 1484 / 0 analyze

**Step 6 · 收尾**(~15min)
- GDD 不动(纯 wire · 不动数值红线 / 公式 / schema · 不动 §12)
- ROADMAP_1_0.md:P5 段加 P0 修补 closeout
- PROGRESS.md:顶段 1.0 → ~91-92%(P0-1 阻塞清 / +P1-1+P1-3)
- `docs/handoff/p5_onboarding_closeout_2026-05-25.md`(≤80 行)

## 5. 红线沿用 + 不变量

- 不动 GDD / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md / masters.yaml
- 不动 §5.4 数值红线 / §5.3 三系锁 / §5.5 在线=离线 / §5.1 反留存 / §6 公式
- 不动 phase2_seed_service.seedMasterDisciple(debug 路径)
- 不动 test/master_disciple_battle_test 8 caller(保 debug seed 等价测族)
- 不动 Isar schema 版本(0.13.0 不升 · 无新 collection)

## 6. 挂账(本 spec OUT)

- P1-2 fallback id=1 是否真 stale → B1 落地后 grep + 主对话决定
- "开始新游戏" UI 界面 → 留 1.1+ 创角向导
- 多槽存档 → 留 P5 已有 TODO
- "我的门派" sectName 是否改用户输入 → 留 1.1+

## 7. 失败模式 + 回退

- ensureFoundingMasters 抛错:splash 显错误屏 + 「请重启游戏」(沿现有 GameRepository.loadAllDefs 失败兜底体例)
- 已有 SaveData.activeCharacterIds=[1,2,3] 但 Character 缺失(异常态):Q3=M 信源 Character → return true 重新 seed(覆盖式)— R5.6 加测

## 8. 工作量预估

| Step | 估时 |
|---|---|
| 1 helpers 静态化 | 15min |
| 2 OnboardingService | 30min |
| 3 Splash wire | 10min |
| 4 P1 顺带 | 10min |
| 5 R5 测族 8 测 | 30-45min |
| 6 收尾 doc | 15min |
| **合计** | **~1.7-2.0h xhigh** |

参考 P4.1 0.16× 精度,spec 估 ~1.7-2.0h 实际可能更短(~1-1.5h)。
