# Lv100 发布上限与当前内容经验重校实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Follow RED→GREEN→REFACTOR for every behavior change and keep the checkbox state current.

**Goal:** 将当前版本的角色成长硬封顶于 Lv100，保留溢出经验与 490 级长线空间，并把现有主线、塔、支线和挂机内容重校到 Lv80～95 的完整当前体验。

**Architecture:** 在 `numbers.yaml` 中增加可配置的发布上限，由无状态 `ProgressionGateService` 统一合并“发布上限”与“心魔内容锁”。所有经验入口继续使用同一本 `Character.experience` 账本和 `CharacterAdvancementService`，封顶时只停止进层、不截断经验、不回退旧档。数据层仅重排当前可玩内容到学徒/三流，二流及以上定义保留给未来副本。

**Tech Stack:** Flutter Desktop、Dart、Riverpod、YAML、flutter_test

**Workspace:** `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/progression-cap-100`

**Branch / Baseline:** `codex/progression-cap-100` / `d1fbd6a9`

**Approved Spec:** `docs/superpowers/specs/2026-07-14-progression-release-cap-100-design.md`

---

## 恢复协议

- 每个 Task 结束后更新本文档勾选状态，并做一个小切片 commit。
- 不修改 Isar schema、`saveVersion`、现有 49 层 `experience_to_next` 表或高阶定义。
- 不降级旧档：已高于 Lv100 的角色保持当前层，只是不再突破到更高层。
- 遇到与 Claude `feat/combat-feel-phase2` 的冲突时，仅手工合并 `data/numbers.yaml` 的独立键；不覆盖其 `readable_first_clear` / animation 调整。
- 仅在最终收口跑一次全量 `flutter test --no-pub`；日常切片只跑定向测试。

## 验收标准（CLAUDE.md §8.2）

- **生产接线证据:** 主线/重打/扫荡、塔、闭关、离线与经验丹的真实结算路径都消费 `ProgressionGateService`；总预算测试直接读生产 YAML。
- **Targeted test 证据:** 每个 Task 记录命令和通过数；收口时覆盖门禁、心魔、五类经验来源、经验预算、主线与塔战斗。
- **红线影响证据:** 不改玩家生命/内力、装备攻击、招式倍率上限；新增当前掉落阶上限保护三系锁死；在线/离线使用同一经验账本；Dart 不硬编码 Lv100 数值或中文文案。
- **残留风险:** 交付时明确列出未做 Windows 实机验收、旧档 Lv101+ 的祖父保留行为、封顶经验在未来开放时可能连跳、以及与 Claude 分支的 `numbers.yaml` 手工合并面。
- **交付清洁度:** 无未跟踪源码、生成物、日志或截图；tip 以 `[READY]` 开头且 worktree 干净后才交 Claude 评审。

## 已检查的范围边界

- 已读 `docs/spec/rejected_task_registry.md`；本任务不包含已否/暂缓项，不借调级扩展 UI、失败诊断、高阶装备追踪或新玩法。
- 本任务不是重做已完成的“单人主线平衡调参”；仅因 490 级派生等级上线后的新发布上限进行必要数值迁移。

## 当前恢复点

- **状态:** Task 3 已完成，全部生产经验来源已共用发布上限+心魔的统一门禁，分支仍为 WIP。
- **最后完成:** 战斗结算、闭关、离线挂机和经验丹入口均调用 `ProgressionGateService`；心魔或 Lv100 上限拦截时保留溢出 EXP；Lv101+ 旧档不回退且不再进层。
- **下一步:** 执行 Task 4，先建立主线/全内容/闭关/离线四条经验预算 RED 合同，再重校 YAML 真相源。
- **已跑验证:** Task 1 定向 6 tests passed；Task 2 心魔+数据+角色面板定向集 110 tests passed；Task 3 五类经验来源定向集 102 tests passed，真 Isar 离线结算+红线 5 tests passed；`git diff --check` 通过。
- **阻塞项:** 无。Claude `feat/combat-feel-phase2` 仍为 WIP，可并行；已知重叠仅为 `data/numbers.yaml` 的不同配置段，交付前再对比。

## 文件地图

- `data/numbers.yaml`: 发布上限、心魔节点、闭关/离线经验真相源。
- `data/stages.yaml`: 30 个主线、7 个心魔、10 个支线的需求境界、奖励、敌人和掉落。
- `data/towers.yaml`: 30 层塔的需求境界、经验、敌人和技能残页。
- `data/items.yaml`: 三种经验丹的当层比例。
- `lib/data/numbers_config.dart`: 解析并校验 `progression.release_cap`。
- `lib/features/cultivation/domain/progression_release_cap.dart`: 新建发布上限值对象。
- `lib/features/cultivation/application/progression_gate_service.dart`: 新建统一进层门禁。
- `lib/features/inner_demon/application/inner_demon_service.dart`: 将心魔锁从武圣专用改为绝对层通用。
- `lib/features/{battle,seclusion,inventory}/...`: 把各经验入口改为统一门禁。
- `test/features/cultivation/application/progression_release_budget_test.dart`: 新建发布版路线总预算合同。
- `test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`: 验证新档单人主线可通过性。
- `test/data/game_repository_test.dart` 及 balance/redline tests: 将现有内容的境界、掉落和来源合同收窄到发布上限内。

---

### Task 1: 增加可配置 Lv100 发布上限与统一门禁

**Files:**
- Create: `lib/features/cultivation/domain/progression_release_cap.dart`
- Create: `lib/features/cultivation/application/progression_gate_service.dart`
- Create: `test/features/cultivation/application/progression_gate_service_test.dart`
- Create: `test/data/numbers_config_progression_release_cap_test.dart`
- Modify: `lib/data/numbers_config.dart`
- Modify: `data/numbers.yaml`

- [x] **Step 1: 为解析、边界和旧档行为写 RED 测试**

  覆盖以下合同：

  ```dart
  expect(repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel, 10);
  expect(() => ProgressionReleaseCap.fromYaml({'release_cap': {
    'max_absolute_realm_level': 0,
  }}), throwsStateError);

  expect(ProgressionGateService.isLayerLocked(
    nextTier: RealmTier.sanLiu,
    nextLayer: RealmLayer.jingTong, // absolute 11
    releaseCap: const ProgressionReleaseCap(maxAbsoluteRealmLevel: 10),
    realmLookup: realmLookup,
    innerDemonDef: InnerDemonDef.empty,
    clearedStageIds: const {},
  ), isTrue);

  // 旧档已在 absolute 11：不回退，但下一层继续被锁。
  expect(gateFor(nextAbsolute: 12), isTrue);
  ```

- [x] **Step 2: 运行新测试并确认 RED**

  Run:

  ```bash
  flutter test --no-pub test/features/cultivation/application/progression_gate_service_test.dart test/data/numbers_config_progression_release_cap_test.dart
  ```

  Expected: FAIL，因为新类和 `NumbersConfig.progressionReleaseCap` 尚不存在。

- [x] **Step 3: 实现配置值对象与解析校验**

  `ProgressionReleaseCap.fromYaml` 仅接受 1～49；无配置时默认 49，保证单元测试/局部 fixture 不被意外封顶。生产 YAML 明确配置：

  ```yaml
  progression:
    release_cap:
      max_absolute_realm_level: 10
  ```

  把解析结果注入 `NumbersConfig`，不在 Dart 业务代码写死 10 或 100。

- [x] **Step 4: 实现统一门禁**

  `ProgressionGateService.isLayerLocked` 先查下一境界层的 `absoluteLevel` 是否超过发布上限，再委托 `InnerDemonService.isLayerLocked`。它只回答“能否进入下一层”，不修改角色、不截断经验。

- [x] **Step 5: 跑 GREEN、格式化并提交**

  ```bash
  dart format lib/data/numbers_config.dart lib/features/cultivation/domain/progression_release_cap.dart lib/features/cultivation/application/progression_gate_service.dart test/features/cultivation/application/progression_gate_service_test.dart test/data/numbers_config_progression_release_cap_test.dart
  flutter test --no-pub test/features/cultivation/application/progression_gate_service_test.dart test/data/numbers_config_progression_release_cap_test.dart
  git add data/numbers.yaml lib/data/numbers_config.dart lib/features/cultivation/domain/progression_release_cap.dart lib/features/cultivation/application/progression_gate_service.dart test/features/cultivation/application/progression_gate_service_test.dart test/data/numbers_config_progression_release_cap_test.dart
  git commit -m "[balance] 增加Lv100发布上限门禁"
  ```

### Task 2: 将心魔节点泛化并重排到学徒—三流

**Files:**
- Modify: `lib/features/inner_demon/application/inner_demon_service.dart`
- Modify: `lib/features/inner_demon/domain/inner_demon_def.dart`
- Modify: `lib/features/inner_demon/domain/inner_demon_panel.dart`
- Modify: `data/numbers.yaml`
- Modify: `data/stages.yaml`
- Modify: `test/features/inner_demon/application/inner_demon_service_test.dart`
- Modify: `test/features/inner_demon/domain/inner_demon_def_test.dart`
- Modify: `test/features/inner_demon/domain/inner_demon_panel_test.dart`
- Modify: `test/features/inner_demon/domain/inner_demon_progress_test.dart`
- Modify: `test/balance/inner_demon_r5_redline_test.dart`
- Modify: `test/data/game_repository_test.dart`

- [x] **Step 1: 为跨 tier 心魔锁和 7 个新节点写 RED 测试**

  断言心魔锁使用 `RealmUtils.absoluteLevelOf`，能拦截 `xueTu.dengFeng → sanLiu.qiMeng`，通关对应心魔后解锁。生产节点精确映射：

  | 心魔关 | 玩家当前层 | 被锁的下一绝对层 |
  |---|---|---:|
  | `stage_inner_demon_01` | `xueTu.shuLian` | 4 |
  | `stage_inner_demon_02` | `xueTu.jingTong` | 5 |
  | `stage_inner_demon_03` | `xueTu.yuanShu` | 6 |
  | `stage_inner_demon_04` | `xueTu.huaJing` | 7 |
  | `stage_inner_demon_05` | `xueTu.dengFeng` | 8 |
  | `stage_inner_demon_06` | `sanLiu.qiMeng` | 9 |
  | `stage_inner_demon_07` | `sanLiu.ruMen` | 10 |

- [x] **Step 2: 跑定向测试并确认 RED**

  ```bash
  flutter test --no-pub test/features/inner_demon/application/inner_demon_service_test.dart test/features/inner_demon/domain/inner_demon_def_test.dart test/features/inner_demon/domain/inner_demon_panel_test.dart test/features/inner_demon/domain/inner_demon_progress_test.dart test/balance/inner_demon_r5_redline_test.dart test/data/game_repository_test.dart
  ```

- [x] **Step 3: 实现绝对层心魔锁**

  对待进入的 `(nextTier, nextLayer)` 计算 `nextAbsolute`，在 `requiredRealmLayer` 中查找绝对层为 `nextAbsolute - 1` 的节点，对应关卡未通关则锁定。删掉仅武圣可用的分支和过时注释。

- [x] **Step 4: 重排生产心魔数据**

  - `unlock_triggers` 从 `stage_01_03 → stage_inner_demon_01` 开始，后续保持心魔链。
  - 心魔01～05 `requiredRealm: xueTu`，06～07 `requiredRealm: sanLiu`。
  - 保留现有 7 关机制、故事、掉落 ID；只重校解锁与数值。

- [x] **Step 5: 跑 GREEN 并提交**

  ```bash
  dart format lib/features/inner_demon/application/inner_demon_service.dart lib/features/inner_demon/domain/inner_demon_def.dart lib/features/inner_demon/domain/inner_demon_panel.dart test/features/inner_demon/application/inner_demon_service_test.dart test/features/inner_demon/domain/inner_demon_def_test.dart test/features/inner_demon/domain/inner_demon_panel_test.dart test/features/inner_demon/domain/inner_demon_progress_test.dart test/balance/inner_demon_r5_redline_test.dart test/data/game_repository_test.dart
  flutter test --no-pub test/features/inner_demon/application/inner_demon_service_test.dart test/features/inner_demon/domain/inner_demon_def_test.dart test/features/inner_demon/domain/inner_demon_panel_test.dart test/features/inner_demon/domain/inner_demon_progress_test.dart test/balance/inner_demon_r5_redline_test.dart test/data/game_repository_test.dart
  git add data/numbers.yaml data/stages.yaml lib/features/inner_demon test/features/inner_demon test/balance/inner_demon_r5_redline_test.dart test/data/game_repository_test.dart
  git commit -m "[balance] 将七个心魔重排至Lv100前"
  ```

### Task 3: 让全部经验来源共用发布上限

**Files:**
- Modify: `lib/features/battle/application/combat_progression_settlement_service.dart`
- Modify: `lib/features/seclusion/application/offline_passive_service.dart`
- Modify: `lib/features/seclusion/application/seclusion_service.dart`
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`
- Modify: `test/features/cultivation/application/experience_source_consistency_test.dart`
- Modify: `test/features/cultivation/application/character_advancement_service_test.dart`
- Modify: `test/features/seclusion/application/offline_passive_service_test.dart`
- Modify: `test/features/seclusion/application/seclusion_service_test.dart`
- Modify: `test/features/inventory/item_use_service_test.dart`

- [x] **Step 1: 为主线/重打/扫荡、塔、闭关、离线和经验丹写 RED 合同**

  扩展 `experience_source_consistency_test.dart`，不再只找 `InnerDemonService.isLayerLocked`，而是要求生产入口统一调用 `ProgressionGateService.isLayerLocked`。行为测试使用低阈值 fixture，验证：

  ```dart
  expect(character.realmTier, RealmTier.sanLiu);
  expect(character.realmLayer, RealmLayer.shuLian); // absolute 10
  expect(character.experience, greaterThanOrEqualTo(threshold)); // 溢出保留
  expect(display.level, 100);
  ```

- [x] **Step 2: 跑定向测试并确认 RED**

  ```bash
  flutter test --no-pub test/features/cultivation/application/experience_source_consistency_test.dart test/features/cultivation/application/character_advancement_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/seclusion_service_test.dart test/features/inventory/item_use_service_test.dart
  ```

- [x] **Step 3: 替换五个生产接线点**

  在各接线点从 `GameRepository.instance.numbers.progressionReleaseCap` 取配置，向统一门禁传入 `realmLookup`、`innerDemonDef` 与 `clearedStageIds`。`CharacterAdvancementService` 的经验累加循环不改，扫荡继续复用主线/塔的 settlement。

- [x] **Step 4: 跑 GREEN、检查生产中无旧门禁直接接线，然后提交**

  ```bash
  dart format lib/features/battle/application/combat_progression_settlement_service.dart lib/features/seclusion/application/offline_passive_service.dart lib/features/seclusion/application/seclusion_service.dart lib/features/inventory/presentation/inventory_screen.dart test/features/cultivation/application/experience_source_consistency_test.dart test/features/cultivation/application/character_advancement_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/seclusion_service_test.dart test/features/inventory/item_use_service_test.dart
  flutter test --no-pub test/features/cultivation/application/experience_source_consistency_test.dart test/features/cultivation/application/character_advancement_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/seclusion_service_test.dart test/features/inventory/item_use_service_test.dart
  rg -n "isLayerLocked:.*InnerDemonService|InnerDemonService\.isLayerLocked" lib/features/battle lib/features/seclusion lib/features/inventory
  git add lib/features/battle/application/combat_progression_settlement_service.dart lib/features/seclusion/application/offline_passive_service.dart lib/features/seclusion/application/seclusion_service.dart lib/features/inventory/presentation/inventory_screen.dart test/features/cultivation/application/experience_source_consistency_test.dart test/features/cultivation/application/character_advancement_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/seclusion_service_test.dart test/features/inventory/item_use_service_test.dart
  git commit -m "[balance] 统一全部经验来源的封顶门禁"
  ```

### Task 4: 建立经验预算合同并重校挂机/经验丹

**Files:**
- Create: `test/features/cultivation/application/progression_release_budget_test.dart`
- Modify: `data/stages.yaml`
- Modify: `data/towers.yaml`
- Modify: `test/tools/idle_economy_test.dart`
- Modify: `test/data/item_def_test.dart`
- Modify: `data/numbers.yaml`
- Modify: `data/items.yaml`
- Modify: `data/shop.yaml`

- [ ] **Step 1: 先写四条 RED 预算断言**

  - 30 主线首通从 Lv1 出发，忽略心魔但启用发布上限，结束于 Lv35～50。
  - 主线 + 30 塔 + 10 支线 + 7 心魔 + 72h 闭关 + 24h 离线 + 各 1 枚丹药，结束于 Lv80～95，且不超过 Lv100。
  - 三流可达地图 72h 闭关仅提升 3～6 个显示级。
  - 三流 8h 离线不超过 1 个显示级，三枚经验丹分别是当层 10%/20%/30%。

- [ ] **Step 2: 跑预算与道具测试并确认 RED**

  ```bash
  flutter test --no-pub test/features/cultivation/application/progression_release_budget_test.dart test/tools/idle_economy_test.dart test/data/item_def_test.dart
  ```

- [ ] **Step 3: 写入经验真相源**

  主线 30 关奖励依次为：

  ```text
  5,5,5,10,15, 8,8,8,15,20, 10,10,8,20,25,
  12,12,10,25,30, 15,15,10,30,35, 18,18,10,35,45
  ```

  合计 492，基线模拟结束约 Lv44。塔按 5 层一组：

  ```text
  1–4:8, 5:20; 6–9:10, 10:25; 11–14:12, 15:30;
  16–19:14, 20:35; 21–24:16, 25:40; 26–29:18, 30:45
  ```

  合计 507。轻功与群战各用 `[20, 25, 30, 50, 75]`。

- [ ] **Step 4: 调整挂机和消耗品**

  - 当前可达地图：`山林 3.0/h`、`古剑冢 2.5/h`、`藏经阁 3.0/h`。未来二流/宗师地图保留高阶产出，不纳入当前版路线。
  - `passive_idle.base_exp_per_hour: 3.0`。
  - 三种丹药 `layer_fraction: 0.1 / 0.2 / 0.3`，同步调整 `shop.yaml` 价格比例，继续满足无套利红线。

- [ ] **Step 5: 跑 GREEN 并提交**

  ```bash
  dart format test/features/cultivation/application/progression_release_budget_test.dart test/tools/idle_economy_test.dart test/data/item_def_test.dart
  flutter test --no-pub test/features/cultivation/application/progression_release_budget_test.dart test/tools/idle_economy_test.dart test/data/item_def_test.dart test/data/shop_def_test.dart
  git add data/numbers.yaml data/stages.yaml data/towers.yaml data/items.yaml data/shop.yaml test/features/cultivation/application/progression_release_budget_test.dart test/tools/idle_economy_test.dart test/data/item_def_test.dart test/data/shop_def_test.dart
  git commit -m "[balance] 重校当前版经验总预算"
  ```

### Task 5: 将 30 个主线关重排到学徒/三流并收窄掉落

**Files:**
- Modify: `data/stages.yaml`
- Modify: `test/data/mainline_stage_curve_redline_test.dart`
- Modify: `test/data/game_repository_test.dart`
- Modify: `test/data/stage_skill_drop_redline_test.dart`
- Modify: `test/data/drop_table_reference_redline_test.dart`
- Modify: `test/features/onboarding/onboarding_first_30min_battle_test.dart`
- Modify: `test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`

- [ ] **Step 1: 为主线境界、单关跳级与当前掉落上限写 RED 测试**

  合同：Ch1～3 均要求/使用 `xueTu`，Ch4～6 均为 `sanLiu`；普通关从推荐等级进入时增加 0～1 级，Boss 增加 1～3 级；当前主线装备掉落不高于 `xiangYang`，掉落技能不高于 tier 2。

- [ ] **Step 2: 跑主线数据/战斗测试并确认 RED**

  ```bash
  flutter test --no-pub test/data/mainline_stage_curve_redline_test.dart test/data/game_repository_test.dart test/data/stage_skill_drop_redline_test.dart test/data/drop_table_reference_redline_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart
  ```

- [ ] **Step 3: 重排境界与敌方基础数值**

  保留每关阵容、Boss 机制、速度和剧情。以现有 HP/攻击为基线按章缩放：Ch1 `1.00`、Ch2 `0.85`、Ch3 `0.65`、Ch4 `0.55`、Ch5 `0.35`、Ch6 `0.25`；HP 四舍五入到 50（最少 500），攻击四舍五入到 10（最少 50）。`difficultyMultiplier` 不参与战斗，不把它当作平衡杠杆。

- [ ] **Step 4: 收窄装备/技能来源**

  高阶定义原样保留，但当前普通掉落表只引用 `xunChang` / `xiangYang`；师承或明确的 +1/+2 收藏例外继续由既有三系门禁管理。将现有 tier 3+ 真解/残页来源移出当前关卡或替换为 tier 1/2 技能。

- [ ] **Step 5: 跑 GREEN；若战斗失败，只微调失败关敌人/掉落，不 buff 玩家全局**

  ```bash
  flutter test --no-pub test/data/mainline_stage_curve_redline_test.dart test/data/game_repository_test.dart test/data/stage_skill_drop_redline_test.dart test/data/drop_table_reference_redline_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart
  git add data/stages.yaml test/data/mainline_stage_curve_redline_test.dart test/data/game_repository_test.dart test/data/stage_skill_drop_redline_test.dart test/data/drop_table_reference_redline_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart
  git commit -m "[balance] 重排当前主线至三流境"
  ```

### Task 6: 将塔与两类支线重排到 Lv100 前

**Files:**
- Modify: `data/towers.yaml`
- Modify: `data/stages.yaml`
- Modify: `test/data/game_repository_test.dart`
- Modify: `test/balance/p3_1_light_foot_redline_test.dart`
- Modify: `test/balance/p3_2_mass_battle_redline_test.dart`
- Modify: `test/tools/floor30_soft_gate_diagnostic_test.dart`
- Modify: `test/tools/tower_boss_feel_diagnostic_test.dart`
- Modify: `test/features/tower/floor30_soft_gate_battle_test.dart`

- [ ] **Step 1: 为境界分布、经验和掉落写 RED 合同**

  - 塔1～15为学徒，16～30为三流；每 5 层 layer 依次 `qiMeng, ruMen, shuLian, jingTong, yuanShu`。
  - 轻功/群战各5关依次为 `xueTu.yuanShu`、`xueTu.dengFeng`、`sanLiu.qiMeng`、`sanLiu.ruMen`、`sanLiu.shuLian`。
  - 当前塔/支线掉落不引用超过当前发布上限的装备或技能。

- [ ] **Step 2: 跑定向测试并确认 RED**

  ```bash
  flutter test --no-pub test/data/game_repository_test.dart test/balance/p3_1_light_foot_redline_test.dart test/balance/p3_2_mass_battle_redline_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  ```

- [ ] **Step 3: 重校塔数据**

  保留 Boss 层和机制，按 5 层分组缩放现有 HP/攻击：`1.00 / 0.80 / 0.60 / 0.50 / 0.40 / 0.30`，沿用主线的 50/10 取整规则。写入 Task 4 的 507 经验预算，保留地板 30 机制体验。

- [ ] **Step 4: 重校两类支线**

  关01～03的敌人 HP/攻击按现值 `0.60`，04～05按 `0.40`；保留地形、波次和特殊机制，写入各自 `[20, 25, 30, 50, 75]` 的经验。

- [ ] **Step 5: 跑 GREEN 并提交**

  ```bash
  dart format test/data/game_repository_test.dart test/balance/p3_1_light_foot_redline_test.dart test/balance/p3_2_mass_battle_redline_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  flutter test --no-pub test/data/game_repository_test.dart test/balance/p3_1_light_foot_redline_test.dart test/balance/p3_2_mass_battle_redline_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  git add data/towers.yaml data/stages.yaml test/data/game_repository_test.dart test/balance/p3_1_light_foot_redline_test.dart test/balance/p3_2_mass_battle_redline_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  git commit -m "[balance] 重校塔与支线的Lv100前节奏"
  ```

### Task 7: 跑完整发布路线与战斗诊断，只修正高影响断点

**Files:**
- Modify: `data/stages.yaml` (only when a mainline/side-stage diagnostic exposes a release-blocking regression)
- Modify: `data/towers.yaml` (only when a tower diagnostic exposes a release-blocking regression)
- Modify: `test/features/cultivation/application/progression_release_budget_test.dart`
- Modify: `test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`
- Modify: `test/tools/progression_playtest_diagnostic_test.dart`
- Modify: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`

- [ ] **Step 1: 运行预算、新档主线和可读性诊断**

  ```bash
  flutter test --no-pub test/features/cultivation/application/progression_release_budget_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/tools/progression_playtest_diagnostic_test.dart test/tools/readable_first_clear_tempo_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  ```

  必须记录：每关前后 Lv、累计经验、首个失败关、各50个种子的通过率，以及完整路线终局 Lv。

- [ ] **Step 2: 按优先级修正诊断结果**

  1. 先修复死锁、不可通过和超 Lv100。
  2. 再修复单关跳级超预算。
  3. 最后修复过软的 Boss。

  只调整相应关卡敌人基础数值、掉落或小额奖励；不改玩家全局成长公式，不引入新系统。

- [ ] **Step 3: 固化最终预算与重要战斗回归**

  把最终通过的总预算和战斗边界保留为硬断言，不把 diagnostic 日志本身当成验收。

- [ ] **Step 4: 跑定向 GREEN 并提交**

  ```bash
  dart format test/features/cultivation/application/progression_release_budget_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/tools/progression_playtest_diagnostic_test.dart test/tools/readable_first_clear_tempo_diagnostic_test.dart
  flutter test --no-pub test/features/cultivation/application/progression_release_budget_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/tools/progression_playtest_diagnostic_test.dart test/tools/readable_first_clear_tempo_diagnostic_test.dart test/tools/tower_boss_feel_diagnostic_test.dart
  git add data/stages.yaml data/towers.yaml test/features/cultivation/application/progression_release_budget_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/tools/progression_playtest_diagnostic_test.dart test/tools/readable_first_clear_tempo_diagnostic_test.dart
  git commit -m "[balance] 收口Lv100发布路线可玩性"
  ```

### Task 8: 更新真相源并做一次完成级验证

**Files:**
- Modify: `GDD.md`
- Modify: `PROGRESS.md`
- Modify: `docs/superpowers/specs/2026-07-14-progression-release-cap-100-design.md` only if implementation discovered an approved-spec mismatch
- Modify: this plan file (checkboxes and final recovery point)

- [ ] **Step 1: 更新设计/进度真相源**

  记录：当前版发布上限 Lv100，对应绝对境界层 10；经验溢出保留；当前主线目标 Lv35～50；当前完整路线 Lv80～95；高阶境界、装备和心法定义为未来副本保留。

- [ ] **Step 2: 运行格式、静态分析和最终定向集**

  ```bash
  dart format lib test
  flutter analyze --no-pub
  flutter test --no-pub test/features/cultivation/application/progression_gate_service_test.dart test/features/cultivation/application/experience_source_consistency_test.dart test/features/cultivation/application/progression_release_budget_test.dart test/features/inner_demon/application/inner_demon_service_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/tools/idle_economy_test.dart test/tools/tower_boss_feel_diagnostic_test.dart test/data/game_repository_test.dart
  ```

- [ ] **Step 3: 运行一次全量测试**

  ```bash
  flutter test --no-pub
  ```

  Expected: PASS。若失败，只修复本次改动引起的回归；无关既有失败记录证据与风险，不扩张范围。

- [ ] **Step 4: 检查 diff、冲突面和工作树清洁度**

  ```bash
  git diff --check main...HEAD
  git diff --stat main...HEAD
  git status --short
  git log --oneline --decorate -10
  git diff main...HEAD -- data/numbers.yaml
  ```

  单独对比 Claude 分支对 `data/numbers.yaml` 的改动，确认只有 YAML 独立键层面的可手工合并重叠。

- [ ] **Step 5: 提交文档与最终收口**

  ```bash
  git add GDD.md PROGRESS.md docs/superpowers/specs/2026-07-14-progression-release-cap-100-design.md docs/superpowers/plans/2026-07-14-progression-release-cap-100.md
  git commit -m "[docs] 记录Lv100发布上限验收结果"
  git status --short
  ```

- [ ] **Step 6: 冻结分支并打 Claude 可评审标记**

  先确认本计划的“当前恢复点”已改为完成、验证数字已录入且 `git status --short` 为空，再执行：

  ```bash
  git commit --allow-empty -m "[READY] 交付Lv100发布上限与当前内容重校"
  git status --short
  git log -1 --format=%s
  ```

---

## 最终验收清单

- [ ] 新档不会因任何经验来源超过 Lv100。
- [ ] 旧档 Lv101+ 不降级、经验不丢失，但不再进层。
- [ ] 封顶经验无上限累加，展示保持 Lv100/待开放。
- [ ] 30 主线首通终局在 Lv35～50。
- [ ] 当前完整参考路线终局在 Lv80～95。
- [ ] 普通主线单关 +0～1，Boss +1～3，8h 离线不超过约 1 级。
- [ ] 当前关卡的三系掉落不穿越学徒/三流上限。
- [ ] 现有 49 层、高阶定义、Isar schema 和存档版本未被破坏。
- [ ] `flutter analyze --no-pub` 与一次全量 `flutter test --no-pub` 通过。
