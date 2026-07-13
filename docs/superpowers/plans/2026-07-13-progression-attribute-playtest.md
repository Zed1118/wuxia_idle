# Progression Attribute Playtest Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可复现的 Lv1～Lv490、七类经验入口、四属性职责和玩家成长路径体检，只修硬证据证明的 P0/P1，不在本批调整数值。

**Architecture:** 所有诊断代码留在 `test/`，通过共享合法玩家夹具直接调用真实 `GameRepository`、生产服务与战斗策略；硬契约进入常规全量测试，软指标只写绑定 commit/seed 的 Markdown 与 CSV。现有主线节奏、心魔和塔 Boss 诊断继续作为事实源，新汇总层只复用或抽取其测试支持代码，不复制生产公式。

**Tech Stack:** Flutter Desktop、Dart、flutter_test、Isar Community、YAML、固定种子战斗模拟、Markdown/CSV

---

## 当前恢复点

- 状态：Task 5 质量复核与最终 tick-cap 边界分类修复已完成；合法 build 与单一 battle run 真相源已补齐，旧首通节奏诊断 1200 场仍逐项等价，下一步执行 Task 6。
- 实现分支：`codex/progression-attribute-playtest-implementation`。
- 无修改基线 commit：`0b5d4b234f9630b43dfda9ce9b8ed1d81e3e2bbf`。
- 基线验证：重新生成 Git 忽略的 `g.dart` 后，`flutter analyze --no-pub` 为 `No issues found`；计划指定基线共 41 tests PASS；固定种子心魔观察值为 05=`17/20`、06=`17/20`、07=`13/20`；塔诊断 PASS。以上观察值均绑定 commit `0b5d4b234f9630b43dfda9ce9b8ed1d81e3e2bbf`。
- Task 1 TDD 红灯证据：`flutter test --no-pub test/support/progression_playtest_fixture_test.dart` 退出码 1，报告缺少 `progression_playtest_fixture.dart`，且 `ProgressionPlaytestFixture`、`GrowthStage` 未定义。
- Task 1 质量加固绿灯：同一目标测试 4 tests PASS；`flutter analyze --no-pub` 仍为 `No issues found`；以上结果绑定 commit `29f48d42324a8db8822c050696ef6c3931541f96`。
- Task 2 绿灯：新全路径契约单独运行 4 tests PASS；与 `character_advancement_service_test.dart`、`realm_progress_display_test.dart` 联合运行 32 tests PASS；`flutter analyze --no-pub` 为 `No issues found`；未触发 Task 7，且未修改 `lib/` / `data/`。以上结果绑定 commit `b9c677b5ca1085976315eab11dcd0ef86e4813ba`。
- Task 2 质量加固：心魔锁现在精确守住层位、经验留账和镜像刷新；真实 `RealmDef` 中学徒·精通门槛为 170，学徒·圆熟门槛为 230，锁定积累 340 后解锁 `+1` 的确定余量为 171，因此精确只升 1 层；终境守住 tier/layer、全量经验与终境镜像；逐层 tier/layer/mirror 断言均带 `absoluteLevel` 定位理由。单文件 4 tests PASS，三文件联合 32 tests PASS，`flutter analyze --no-pub` 为 `No issues found`；以上结果绑定 commit `1d6aee30bb9b8c97960adea9c357a9f098fc9872`。
- Task 3 初版绿灯：两份经验入口字符串契约与七份既有行为测试联合运行 133 tests PASS；旧 `level/levelExp` 在离线和经验丹路径保持不变；`flutter analyze --no-pub` 为 `No issues found`，未触发 Task 7，且未修改 `lib/` / `data/`。以上结果绑定 commit `90c8d8268669257f2bbe6fd8d3b85193c2c09145`。
- Task 3 质量加固：新增 analyzer AST 测试 helper，旧账守卫现在捕获六个生产路径中 `levelExp` 任意成员访问（读、`=`、`+=`、`++`）且忽略注释/字符串；正向契约确认主线/爬塔共享结算服务的真实构造与调用参数，三个 direct path 的真实静态调用，以及闭关合并经验后的唯一调用。真 Isar 测试 `10 天合并 72h 闭关 + 168h 挂机经验只应用一次且旧账不变` 精确断言合并经验 15600，并将最终 tier/layer/experience/layersGained 与单次成长服务参考结果对比。两契约 7 tests PASS，九文件定向集 136 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，format 无改动，`git diff --check` 通过；`analyzer: ^9.0.0` 已显式加入 dev dependencies，lockfile 仅将 analyzer 9.0.0 从 transitive 改为 direct dev，无版本升级。边界：本任务未声称 `runStageFlow` / `runTowerFlow` 首通/重打四案 E2E；公开 resolution helper 的 WidgetRef + 真 Isar 尝试在测试调度中不返回，已撤掉不可靠用例且未改生产代码。无 Task 7 硬失败。以上结果绑定 commit `e545ac5a08646fc457457e39726138b9941ceb95`。
- Task 3 `level` 广义守卫补强：六个经验生产路径当前对任意 `.level` 成员访问采用零容忍契约，与 `levelExp` 守卫并存；AST snippet 覆盖 `level` 的读、`=`、`+=`、`++`，以及 `repository.numbers.level`、`this.numbers.level`、`GameRepository.instance.numbers.level` 三种链式 receiver，并证明注释/字符串不计数。未扩张 AST helper；未处理 scope-aware 非阻塞项。未来若路径需要其他对象的 `.level`，须显式审查契约而不会静默放行。两契约 8 tests PASS，同一九文件定向集因新增回归用例为 137 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，format 无改动，`git diff --check` 通过；未修改 `lib/` / `data/`。以上结果绑定 commit `f560c76cc5c2bb49597d91aa1cb2ec3e821f5d9a`。
- Task 4 绿灯：新增四属性前中后期只读诊断，单文件 12 tests PASS，八文件联合 78 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，`git diff --check` 通过。三阶段原始值：根骨重伤时长 `8.0→7.52`；悟性有效使用 `100→106`、进度增量 `50→53`、领悟概率 `0.25→0.27999999999999997`；身法速度前/中/后期分别 `140→164` / `155→179` / `200→224`、闪避 `0.015→0.024`、暴击保持 `0.075`；机缘概率 `0.25→0.27999999999999997`，最大血量前/中/后期分别保持 `3597` / `6873` / `10149`，闪避保持 `0.015`、暴击保持 `0.075`。无 Task 7 硬失败，未修改 `lib/` / `data/` / `numbers.yaml`。以上结果绑定 commit `c02fc4970d98bd43a327f082d43cbbf572a83b83`。
- Task 4 质量加固：baseline/raised 现在共用相同 `Character.id` 与派生 name，并以本诊断相关生产输入快照锁住境界、稀有度、师承、流派、祖师/active、内力、经验及镜像和三个非目标属性，仅目标属性 `5→8`；心法 owner 同步共用相同角色 id。根骨经真实 `InjuryService.applyBattleInjuries` 硬仗战败入口仍为 `8.0→7.52h`，HP 前/中/后期分别 `3597→4797` / `6873→8073` / `10149→11349`。悟性经真实 `CultivationService.recordSkillUsage` 为 `50→53`，经真实 `DamageCalculator.calculate` 的 95 次原始熟练度跨档伤害分别 `1595→1701` / `3898→4158` / `8118→8659`，真实 `bamboo_listen_rain` + `EncounterService.evaluateTriggers` 固定 roll 均为 `0→1`。机缘经真实 `du_ke_wen_dao` + `EncounterService` 固定 roll 均为 `0→1`，同事件真实 `fortune_required: 8` 选项可用性均为 `0→1`；确定性伤害分别保持 `1519` / `3712` / `7731`，真实 `stage_01_01` 的 `DropService.rollDrops` 相同 seed 完整结果快照一致（每阶段 3 项），HP/闪避/暴击继续不变。身法速度/闪避上升且暴击不变。属性政策本身与阶段无关，故 policy 结果在三阶段有意重复验证；阶段相关 HP、速度、伤害均使用真实境界/心法。单文件 15 tests PASS，计划八文件联合 81 tests PASS，额外 DamageCalculator/DerivedStats/DropService 三文件 116 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，`git diff --check` 通过。无 Task 7 硬失败，未修改 `lib/` / `data/` / `numbers.yaml`。以上结果绑定 commit `f8071e71b47f6a00ac3c9f90016b020e001b254f`。
- Task 4 二次质量加固：所有攻击样本均保持 fixture 合法四维（defender 身法不再被改为 0），同一固定 seed 下前/中/后期 `isDodged=false`。悟性熟练度不再写死软数值：诊断通过真实 `AttributeEffectPolicy.effectiveUsageCount` 与 `SkillProficiency.stageFor(repository.numbers.skillProficiency)` 在真实最高档门槛内搜索首个跨档输入，当前动态结果为 raw uses `29`、有效次数 `29→30`；该输入同时驱动真实 `CultivationService`（进度 `29→30`）和 `DamageCalculator`（伤害前/中/后期 `1519→1595` / `3712→3898` / `7731→8118`）。奇遇 roll 改由真实 `EncounterDef.baseProbability` 计算两侧概率后取中点：`bamboo_listen_rain` 为 `0.50→0.56`，`du_ke_wen_dao` 为 `0.625→0.70`，真实 `EncounterService` 三阶段均稳定 `0→1`。机缘掉落隔离改为 baseline/raised 分别经真实 `BattleResolutionService.resolve`，复用同一胜利 `BattleState`、真实 `stage_01_01`、seed 与 clock，并比较包含装备全部持久字段/开锋槽/典故和全部物品字段的完整 `DropResult` 快照；两侧每阶段均为 3 项且一致，参战角色的本诊断相关生产输入仅机缘不同。单文件 15 tests PASS，计划八文件 81 tests PASS，扩展 DamageCalculator/DerivedStats/DropService/BattleResolution 相关 11 文件 175 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，format 0 changed，`git diff --check` 通过。无 Task 7 硬失败，未修改 `lib/` / `data/` / `numbers.yaml`。以上结果绑定 commit `d2f55cdea2b4cbc188195082867d3426a884a3bb`。
- Task 5 基线与等价回归：基线绑定 `HEAD=6c9bd2e272dc0bfc43775796c6f70254e4988798`，旧诊断 1 test PASS，30 mainline × 2 profile × 20 seed = 1200 个真实 battle runs。抽取前后完整汇总数值逐项一致：平均展示动作行/估算秒数 `5.6/15.3`；玩家普攻/技能伤害 `60.1%/39.9%`；普攻/技能击杀 `21.6%/78.4%`；Boss 转阶段/蓄力可见/破招平均行 `0.5/0.7/0.4`；47 个低于动作目标候选集合逐项一致；配了阶段但可见机制不足候选均为“无”。`stage_06_05` undergeared（旧 floor）前后均为：win `100.0%`、avg actions/est sec `8.9/20.8`、player/enemy atk `5.9/0.8`、phase/charge/break `1.0/1.1/1.0`、normal/skill damage `40.4%/59.6%`、normal/skill kills `0.0%/100.0%`、HP end `95.7%`、IF spent `-4.0%`。唯一预期文本差异是 profile 标签 `floor→undergeared`、`ceiling→nearMax`。共享 probe TDD 红灯为缺少文件与公开 API；绿灯 3 tests PASS，证明三 profile 合法且派生战力单调、同参确定性、observation 逐字段来自独立真实 battle。联合运行共享 probe 与旧诊断共 4 tests PASS，`flutter analyze --no-pub` 为 `No issues found`，format 0 changed，`git diff --check` 通过。实现提交为本任务的 `test: share progression battle probes`；未修改 `lib/` / `data/` / `numbers.yaml`。
- Task 5 质量复核修复：profile 精确定义为 undergeared=`enhanceRatio 0.0 / battleCount 0 / zhongCheng / constitution+agility 5 / founder buff false / 属性总和20 biaoZhun`，standard=`0.25 / 150 / zhongCheng / 5 / false / 总和20 biaoZhun`，nearMax=`0.5 / 400 / daCheng / 6 / true / 总和22 ziYou`；三者 enlightenment/fortune 均为 5，nearMax 只是接近满配而非全满。新增 immutable `ProgressionPlayerBuild` 与 `ProgressionBattleRun`；唯一 `runProgressionMainlineStage` 统一 3 人 build、首通调节、敌队、初态、`Random(seed)`、strategy 与 `progressionBattleMaxTicks=240`，到达上限且 draw 时抛含 stage/profile/seed/maxTicks 的 `StateError`；probe 只投影 run，旧诊断只把同一 run 喂给 `_TempoRun.fromBattle`。合法中间对象现在同步 owner、3 个领域默认空开锋槽、真实 `experienceToNextLayer` 与属性对应 rarity。代表 def 继续按 repository/yaml 插入顺序取每阶每槽首项，保持旧数值；装备 ID：xunChang=`weapon_xunchang_tie_jian/armor_xunchang_bu_yi/accessory_xunchang_yu_pei`，xiangYang=`weapon_xiangyang_gang_dao/armor_xiangyang_pi_jia/accessory_xiangyang_yin_jie`，haoJiaHuo=`weapon_haojiahuo_qing_feng_jian/armor_haojiahuo_jin_pao/accessory_haojiahuo_yu_pei_lao`，liQi=`weapon_liqi_long_quan/armor_liqi_xuan_tie_jia/accessory_liqi_fei_yu_pei`，zhongQi=`weapon_zhongqi_po_zhen_chui/armor_zhongqi_yin_lin_jia/accessory_zhongqi_qing_yu_huan`，baoWu=`weapon_baowu_xuan_tian_fu/armor_baowu_jin_si_jia/accessory_baowu_yu_long_pei`，shenWu=`weapon_shenwu_po_jun_dao/armor_shenwu_xuan_huang_pao/accessory_shenwu_kun_lun_pei`；刚猛心法 ID 依次为 `tech_gangmeng_jichu/tech_gangmeng_changlian/tech_gangmeng_mingjia/tech_gangmeng_menpai/tech_gangmeng_jianghu/tech_gangmeng_shichuan/tech_gangmeng_chuanshuo`。`schoolBias` 核实结论：`EquipmentFactory.fromDef` 把 bias 作为常规生成默认 school，但领域构造/API 无“实例 school 必须等于 def bias”的硬校验，schema 只守每阶流派武器覆盖与 founder 起手武器匹配，战斗派生数值完全不读 equipment.school/bias，UI 还显式支持 `equipment.school ?? def.schoolBias`；因此本测试夹具保留原 gangMeng 实例 school 以维持旧诊断，不把 bias 误升为硬约束。TDD 红灯为新 build/run API 缺失；probe 5 tests 与旧诊断联合共 6 tests PASS，覆盖全部 7 RealmTier × 3 team slots × 3 profiles、装备/心法 cap、owner/id/三开锋槽/镜像/rarity、投入单调、maxTicks、确定性与投影。1200 场 60 行及汇总继续与 Task 5 基线逐项一致；`flutter analyze --no-pub` 为 `No issues found`，format 0 changed，`git diff --check` 通过。修复提交 `14d3b93894978a79722796b8ff00135563e81a15` 独立于 `622f8f98`，未 amend；未修改 `lib/` / `data/` / `numbers.yaml`。
- Task 5 最终 tick-cap 边界分类：经 `BattleCharacter.isAlive` 与 `DefaultGroundStrategy` 真实结束链核实，规则平局为双方全灭，`runToEnd` 另在到达 tick 上限且战斗未结束时写入兜底 draw，`surviveTicks` 则直接写 `leftWin`。测试层公开纯分类器 `isUnfinishedAtTickCap` 仅在 `tick >= maxTicks && result == draw && 左右各有存活角色` 时拒绝，因此双方全灭恰逢边界的规则 draw 正常返回。TDD 红灯为缺少 `isUnfinishedAtTickCap`；绿灯 probe 6 tests PASS，既证明“双方存活 + `maxTicks=1`”仍抛错，又证明“双方全灭 + `tick == maxTicks` + draw”分类为正常终局；与旧诊断联合共 7 tests PASS。1200 场 60 行与汇总继续逐项等价：平均动作/秒 `5.6/15.3`，普攻/技能伤害 `60.1%/39.9%`，普攻/技能击杀 `21.6%/78.4%`，Boss 转阶段/蓄力/破招 `0.5/0.7/0.4`，47 个低动作候选不变，机制不足候选为“无”。format 0 changed，`flutter analyze --no-pub` 为 `No issues found`，`git diff --check` 通过。实现提交 `277d72f42d5bc74e1db5045fc392065ea53f8609` 独立提交、未 amend；未修改 `lib/` / `data/` / `numbers.yaml`。
- Task 6 原始 evidence 已完成：`test: record progression and attribute playtest evidence` = `654c317acfca28b2cff492b52f226c299c648c86`，data tree = `c0c557d1f57dfa97e81ef386eb63bd33042f09e2`。同一 commit 上主线 30×3×20=1800 observations 复跑 1 test PASS、6.58 秒，CSV 1801 行、header 精确、三 profile 各 600、30 stages、seed 0～19、组合零重复、零 tick cap、无中文/空行/NaN，重跑后 CSV 无 diff。profile 汇总：undergeared 600/600 胜、ticks/action/HP/Qi delta=`9.71/6.34/93.90%/+33.33`；standard=`8.61/5.94/94.73%/+38.23`；nearMax=`6.86/4.85/97.14%/+50.60`。
- Task 6 专项 evidence 同样绑定 `654c317acfca28b2cff492b52f226c299c648c86`：计划六文件联合 33/33 tests PASS、18.15 秒；为报告覆盖边界额外重跑 `combat_progression_settlement_service_test.dart` 4/4 PASS。心魔 05/06 BiS 均 17/20，07 BiS 13/20；塔 24/25/29/30 与四属性全部原始值已写入 `docs/audit/progression_attribute_playtest_2026-07-13.md`。P0/P1 均无，P2 仅保留 readable-first-clear 首通样本胜负区分不足与 `stage_02_05` 多配置/多 seed 相邻断崖两个候选，本批零生产代码修改。
- Task 6 report commit：`docs: record progression playtest audit` = `7d6dedeaa97fe330f971078dcddc4b4a101cd6d0`。报告明确绑定 evidence commit `654c317acfca28b2cff492b52f226c299c648c86`，没有把后续文档状态冒充原始执行证据。本恢复点提交只补记 report commit 与 Task 7 入口，不修改报告结论或 CSV。
- 设计规格：`docs/superpowers/specs/2026-07-13-progression-attribute-playtest-design.md`。
- Task 7 恢复点：先核对报告“问题分级”的 P0/P1 均为无，再运行计划 Task 7 Step 2A 的 `lib/**` / `data/**` diff；预期零输出并关闭生产修改门禁。不要把两个 P2 候选升级为硬失败。
- 下一步：执行 Task 7，按报告 P0/P1=无关闭生产修改门禁。
- 强制边界：本计划不改 `numbers.yaml`、schema、save version、属性倍率或发布流程。

---

## 文件结构

### 新建

- `test/support/progression_playtest_fixture.dart`：前中后期合法角色、单属性变体和确定性元数据。
- `test/support/progression_battle_probe.dart`：从既有首通诊断抽出的测试专用玩家构造与战斗采样 API。
- `test/support/progression_battle_probe_test.dart`：三档 profile、确定性与真实战斗观察字段的最小契约。
- `test/support/dart_source_contract.dart`：测试专用 analyzer AST 成员访问、方法调用与变量初始值查询。
- `test/features/cultivation/application/progression_full_path_contract_test.dart`：49 层、490 级、心魔锁和终境封顶硬契约。
- `test/features/cultivation/application/experience_source_consistency_test.dart`：七类经验入口委托与玩法差异契约。
- `test/tools/attribute_role_sensitivity_diagnostic_test.dart`：四属性前中后期方向性及职责隔离诊断。
- `test/tools/progression_playtest_diagnostic_test.dart`：主线三档成长路径软指标采集与统一输出。
- `docs/audit/progression_attribute_playtest_2026-07-13.md`：绑定 commit、环境、种子和结果的人工结论。
- `test/tools/output/progression_attribute_playtest_2026-07-13.csv`：本轮原始场景数据。

### 修改

- `test/tools/readable_first_clear_tempo_diagnostic_test.dart`：改用共享 battle probe，行为与现有断言不变。
- `test/features/cultivation/application/single_experience_account_contract_test.dart`：扩大旧等级账零写入守卫到全部经验来源。
- `test/features/seclusion/application/seclusion_service_test.dart`：精确验证闭关 + 溢出挂机经验合并后只应用一次。
- `pubspec.yaml` / `pubspec.lock`：显式声明测试 AST helper 使用的 analyzer 9.0.0 dev dependency。
- `PROGRESS.md`：仅在最终门禁完成后记录真实结果。
- 本计划文件：每个任务提交时更新恢复点。

### 条件修改

- `lib/**`：只有新增硬契约实际失败并被归类为 P0/P1 时才允许修改；先暂停执行，把失败测试、根因和精确修法追加为本计划的新任务，再按 TDD 实施。

---

### Task 1: 冻结基线并建立合法玩家夹具

**Files:**
- Create: `test/support/progression_playtest_fixture.dart`
- Test: `test/support/progression_playtest_fixture_test.dart`
- Modify: `docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md`

- [x] **Step 1: 记录无修改基线**

Run:

```bash
git status -sb
flutter analyze --no-pub
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart
```

Expected: 工作区干净，analyze 为 0，所有指定测试 PASS。把真实通过数和心魔观察值连同 `git rev-parse HEAD` 写入本计划“当前恢复点”，观察值必须附 commit。

- [x] **Step 2: 写夹具失败测试**

Create `test/support/progression_playtest_fixture_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import 'progression_playtest_fixture.dart';
import 'test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('early middle late profiles use real realm definitions', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final early = fixture.createCharacter(GrowthStage.early, id: 101);
    final middle = fixture.createCharacter(GrowthStage.middle, id: 102);
    final late = fixture.createCharacter(GrowthStage.late, id: 103);

    expect(repository.getRealm(early.realmTier, early.realmLayer).absoluteLevel, 4);
    expect(repository.getRealm(middle.realmTier, middle.realmLayer).absoluteLevel, 25);
    expect(repository.getRealm(late.realmTier, late.realmLayer).absoluteLevel, 46);
    expect([early.id, middle.id, late.id], [101, 102, 103]);
  });

  test('attribute variant changes exactly one field and stays legal', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final base = fixture.createCharacter(GrowthStage.middle, id: 201);
    final agile = fixture.createCharacter(
      GrowthStage.middle,
      id: 202,
      raisedAttribute: AttributeKey.agility,
    );

    expect(base.attributes.total, 20);
    expect(agile.attributes.total, 23);
    expect(agile.attributes.constitution, base.attributes.constitution);
    expect(agile.attributes.enlightenment, base.attributes.enlightenment);
    expect(agile.attributes.agility, 8);
    expect(agile.attributes.fortune, base.attributes.fortune);
  });

  test('fixture mirrors the current RealmDef threshold only for compatibility', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final character = fixture.createCharacter(GrowthStage.late, id: 301);
    final realm = repository.getRealm(character.realmTier, character.realmLayer);

    expect(character.experienceToNextLayer, realm.experienceToNext);
    expect(character.internalForceMax, realm.internalForceMax);
  });
}
```

- [x] **Step 3: 运行测试确认失败**

Run:

```bash
flutter test --no-pub test/support/progression_playtest_fixture_test.dart
```

Expected: FAIL，`progression_playtest_fixture.dart`、`ProgressionPlaytestFixture` 和 `GrowthStage` 尚不存在。

- [x] **Step 4: 实现最小夹具**

Create `test/support/progression_playtest_fixture.dart`:

```dart
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

enum GrowthStage { early, middle, late }

final class ProgressionPlaytestFixture {
  const ProgressionPlaytestFixture(this.repository);

  final GameRepository repository;

  Character createCharacter(
    GrowthStage stage, {
    required int id,
    AttributeKey? raisedAttribute,
  }) {
    final (tier, layer) = switch (stage) {
      GrowthStage.early => (RealmTier.xueTu, RealmLayer.jingTong),
      GrowthStage.middle => (RealmTier.yiLiu, RealmLayer.jingTong),
      GrowthStage.late => (RealmTier.wuSheng, RealmLayer.jingTong),
    };
    final realm = repository.getRealm(tier, layer);
    final attributes = Attributes()
      ..constitution = raisedAttribute == AttributeKey.constitution ? 8 : 5
      ..enlightenment = raisedAttribute == AttributeKey.enlightenment ? 8 : 5
      ..agility = raisedAttribute == AttributeKey.agility ? 8 : 5
      ..fortune = raisedAttribute == AttributeKey.fortune ? 8 : 5;
    final character = Character.create(
      name: '体检角色-${stage.name}-$id',
      realmTier: tier,
      realmLayer: layer,
      attributes: attributes,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 7, 13),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: true,
      isActive: true,
      school: TechniqueSchool.gangMeng,
    )..id = id;
    validateCharacter(character);
    return character;
  }

  void validateCharacter(Character character) {
    final realm = repository.getRealm(character.realmTier, character.realmLayer);
    if (character.attributes.total < 16 || character.attributes.total > 24) {
      throw StateError('属性总和 ${character.attributes.total} 不在 [16, 24]');
    }
    if (character.internalForceMax != realm.internalForceMax) {
      throw StateError('角色内力上限未使用真实 RealmDef');
    }
  }
}
```

- [x] **Step 5: 格式化并运行夹具测试**

Run:

```bash
dart format test/support/progression_playtest_fixture.dart test/support/progression_playtest_fixture_test.dart
flutter test --no-pub test/support/progression_playtest_fixture_test.dart
```

Expected: 3 tests PASS。

- [x] **Step 6: 提交**

```bash
git add \
  test/support/progression_playtest_fixture.dart \
  test/support/progression_playtest_fixture_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: add progression playtest fixtures"
```

---

### Task 2: 建立 49 层与 Lv490 全路径硬契约

**Files:**
- Create: `test/features/cultivation/application/progression_full_path_contract_test.dart`
- Use: `test/support/progression_playtest_fixture.dart`

- [x] **Step 1: 写全路径契约**

Create `test/features/cultivation/application/progression_full_path_contract_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';

import '../../../support/progression_playtest_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
  });

  test('49 real layers expose exactly Lv1 through Lv490', () {
    final realms = [...repository.realms]
      ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
    expect(realms.length, 49);

    final levels = <int>[];
    for (final realm in realms) {
      for (var segment = 0; segment < 10; segment++) {
        final experience = segment == 9
            ? realm.experienceToNext - 1
            : (realm.experienceToNext * segment + 9) ~/ 10;
        levels.add(
          RealmProgressDisplay.fromSnapshot(
            absoluteRealmLevel: realm.absoluteLevel,
            experience: experience,
            experienceToNext: realm.experienceToNext,
            hasNextRealmLayer: realm.absoluteLevel < 49,
          ).level,
        );
      }
    }

    expect(levels, List<int>.generate(490, (index) => index + 1));
  });

  test('every real layer advances to the next RealmDef and refreshes its mirror', () {
    final realms = [...repository.realms]
      ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
    for (var index = 0; index < realms.length - 1; index++) {
      final current = realms[index];
      final next = realms[index + 1];
      final character = fixture.createCharacter(GrowthStage.early, id: 1000 + index)
        ..realmTier = current.tier
        ..realmLayer = current.layer
        ..internalForceMax = current.internalForceMax
        ..experienceToNextLayer = 999999;

      final result = CharacterAdvancementService.applyExperience(
        character,
        current.experienceToNext,
        realmLookup: repository.getRealm,
      );

      expect(result.layersGained, 1, reason: 'absolute=${current.absoluteLevel}');
      expect(character.realmTier, next.tier);
      expect(character.realmLayer, next.layer);
      expect(character.experienceToNextLayer, next.experienceToNext);
    }
  });

  test('locked overflow remains at level ten then advances after unlock', () {
    final character = fixture.createCharacter(GrowthStage.early, id: 2001);
    final current = repository.getRealm(character.realmTier, character.realmLayer);

    final locked = CharacterAdvancementService.applyExperience(
      character,
      current.experienceToNext * 2,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => true,
    );
    expect(locked.layersGained, 0);
    expect(locked.progressChange.after.level, current.absoluteLevel * 10);
    expect(locked.progressChange.after.isWaitingForBreakthrough, isTrue);

    final unlocked = CharacterAdvancementService.applyExperience(
      character,
      1,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => false,
    );
    expect(unlocked.layersGained, greaterThan(0));
  });

  test('terminal realm reaches Lv490 and never creates layer 50', () {
    final terminal = repository.getRealm(
      RealmTier.wuSheng,
      RealmLayer.dengFeng,
    );
    final character = fixture.createCharacter(GrowthStage.late, id: 3001)
      ..realmTier = terminal.tier
      ..realmLayer = terminal.layer
      ..experience = 0
      ..experienceToNextLayer = 0
      ..internalForceMax = terminal.internalForceMax;

    final result = CharacterAdvancementService.applyExperience(
      character,
      terminal.experienceToNext * 2,
      realmLookup: repository.getRealm,
    );

    expect(result.layersGained, 0);
    expect(result.progressChange.after.level, 490);
    expect(result.progressChange.after.didReachPeak, isTrue);
    expect(CharacterAdvancementService.nextLayer(
      character.realmTier,
      character.realmLayer,
    ), isNull);
  });
}
```

- [x] **Step 2: 运行契约测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/progression_full_path_contract_test.dart
```

Expected: 若 PASS，确认当前生产逻辑满足完整契约；若 FAIL，保留失败输出并进入 Task 7 硬门禁，不立即改生产代码。

- [x] **Step 3: 联合既有境界测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart
```

Expected: all PASS。

- [x] **Step 4: 提交硬契约**

```bash
git add \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: cover the full Lv490 progression path"
```

---

### Task 3: 锁定七类经验入口与玩法差异

**Files:**
- Create: `test/features/cultivation/application/experience_source_consistency_test.dart`
- Create: `test/support/dart_source_contract.dart`
- Modify: `test/features/cultivation/application/single_experience_account_contract_test.dart`
- Modify: `test/features/seclusion/application/seclusion_service_test.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Verify existing behavior tests listed below

- [x] **Step 1: 写入口委托与策略契约**

Create `test/features/cultivation/application/experience_source_consistency_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all seven experience entrances delegate to the single experience account', () async {
    const combatPaths = {
      'mainline': 'lib/features/mainline/presentation/stage_entry_flow.dart',
      'tower': 'lib/features/tower/presentation/tower_entry_flow.dart',
    };
    for (final entry in combatPaths.entries) {
      final source = await File(entry.value).readAsString();
      expect(source, contains('CombatProgressionSettlementService'));
      expect(source, contains('settlement.applyExperience'));
      expect(source, isNot(contains('.levelExp =')), reason: entry.key);
      expect(source, isNot(contains('LevelService')), reason: entry.key);
    }

    const directPaths = {
      'retreat': 'lib/features/seclusion/application/seclusion_service.dart',
      'offline': 'lib/features/seclusion/application/offline_passive_service.dart',
      'item': 'lib/features/inventory/application/item_use_service.dart',
    };
    for (final entry in directPaths.entries) {
      final source = await File(entry.value).readAsString();
      expect(
        source,
        contains('CharacterAdvancementService.applyExperience'),
        reason: '${entry.key} 未委托唯一成长服务',
      );
      expect(source, isNot(contains('.levelExp =')), reason: entry.key);
      expect(source, isNot(contains('LevelService')), reason: entry.key);
    }
  });

  test('mainline replay and tower first-clear policies remain intentionally different', () async {
    final mainline = await File(
      'lib/features/mainline/presentation/stage_entry_flow.dart',
    ).readAsString();
    final tower = await File(
      'lib/features/tower/presentation/tower_entry_flow.dart',
    ).readAsString();

    expect(mainline, contains('experienceReward: stage.baseExpReward'));
    expect(
      tower,
      contains('experienceReward: isFirstClear ? floor.baseExpReward : 0'),
    );
  });

  test('retreat and passive sources combine before one advancement call', () async {
    final source = await File(
      'lib/features/seclusion/application/seclusion_service.dart',
    ).readAsString();
    expect(
      source,
      contains('outputs.experiencePoints + settlement.passive.experience'),
    );
  });
}
```

- [x] **Step 2: 扩大旧等级账守卫**

In `test/features/cultivation/application/single_experience_account_contract_test.dart`, replace both path loops with one list that also covers the shared settlement service:

```dart
const productionExperiencePaths = [
  'lib/features/mainline/presentation/stage_entry_flow.dart',
  'lib/features/tower/presentation/tower_entry_flow.dart',
  'lib/features/battle/application/combat_progression_settlement_service.dart',
  'lib/features/seclusion/application/seclusion_service.dart',
  'lib/features/seclusion/application/offline_passive_service.dart',
  'lib/features/inventory/application/item_use_service.dart',
];

test('all production experience paths ignore the legacy level account', () async {
  for (final path in productionExperiencePaths) {
    final source = await File(path).readAsString();
    expect(source, isNot(contains('LevelService')), reason: path);
    expect(source, isNot(contains('LevelConfig')), reason: path);
    expect(source, isNot(contains('.levelExp =')), reason: path);
    expect(source, isNot(contains('numbers.level')), reason: path);
  }
});
```

- [x] **Step 3: 运行新契约与真实持久化入口测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/features/battle/application/combat_progression_settlement_service_test.dart \
  test/features/seclusion/application/offline_passive_settle_test.dart \
  test/features/seclusion/application/seclusion_service_test.dart \
  test/features/inventory/item_use_service_test.dart \
  test/features/mainline/presentation/stage_victory_dialog_test.dart \
  test/features/tower/presentation/tower_victory_content_test.dart \
  test/features/seclusion/presentation/retreat_result_screen_test.dart
```

Expected: all PASS；离线和经验丹行为测试继续证明旧 `level/levelExp` 不变，闭关服务测试继续证明合并经验只结算一次。

- [x] **Step 4: 提交**

```bash
git add \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: lock progression experience source policies"
```

---

### Task 4: 建立四属性方向性与职责隔离诊断

**Files:**
- Create: `test/tools/attribute_role_sensitivity_diagnostic_test.dart`
- Use: `test/support/progression_playtest_fixture.dart`

- [x] **Step 1: 写属性诊断**

Create `test/tools/attribute_role_sensitivity_diagnostic_test.dart`:

```dart
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import '../support/progression_playtest_fixture.dart';
import '../support/test_data.dart';

void recordAttributeObservation(
  GrowthStage stage,
  String metric,
  num baseline,
  num raised,
) {
  print([
    'attribute_role',
    stage.name,
    metric,
    baseline,
    raised,
  ].join(','));
}

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;
  late AttributeEffectPolicy policy;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
    policy = AttributeEffectPolicy(repository.numbers.attributeEffects);
  });

  for (final stage in GrowthStage.values) {
    test('${stage.name}: constitution shortens new heavy injury duration', () {
      final base = fixture.createCharacter(stage, id: 100 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 200 + stage.index,
        raisedAttribute: AttributeKey.constitution,
      );
      final hoursBase = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: base.attributes.constitution,
      );
      final hoursRaised = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: raised.attributes.constitution,
      );
      recordAttributeObservation(
        stage,
        'constitution_heavy_injury_hours',
        hoursBase,
        hoursRaised,
      );
      expect(hoursRaised, lessThan(hoursBase));
    });

    test('${stage.name}: enlightenment improves all three growth entrances', () {
      final base = fixture.createCharacter(stage, id: 300 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 400 + stage.index,
        raisedAttribute: AttributeKey.enlightenment,
      );
      final usageBase = policy.effectiveUsageCount(
        rawUses: 100,
        enlightenment: base.attributes.enlightenment,
      );
      final usageRaised = policy.effectiveUsageCount(
        rawUses: 100,
        enlightenment: raised.attributes.enlightenment,
      );
      final progressBase = policy.effectiveProgressDelta(
        rawBefore: 20,
        rawDelta: 50,
        enlightenment: base.attributes.enlightenment,
      );
      final progressRaised = policy.effectiveProgressDelta(
        rawBefore: 20,
        rawDelta: 50,
        enlightenment: raised.attributes.enlightenment,
      );
      final encounterBase = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.enlightenment,
        attributes: base.attributes,
      );
      final encounterRaised = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.enlightenment,
        attributes: raised.attributes,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_effective_usage',
        usageBase,
        usageRaised,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_progress_delta',
        progressBase,
        progressRaised,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_encounter_probability',
        encounterBase,
        encounterRaised,
      );
      expect(usageRaised, greaterThan(usageBase));
      expect(progressRaised, greaterThan(progressBase));
      expect(encounterRaised, greaterThan(encounterBase));
    });

    test('${stage.name}: agility raises speed/evasion but never critical rate', () {
      final base = fixture.createCharacter(stage, id: 500 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 600 + stage.index,
        raisedAttribute: AttributeKey.agility,
      );
      final tier = RealmUtils.techniqueTierCapOf(base.realmTier);
      final def = repository.techniqueDefs.values.firstWhere(
        (value) => value.tier == tier && value.school == TechniqueSchool.gangMeng,
      );
      Technique techniqueFor(int id) => Technique.create(
        defId: def.id,
        ownerCharacterId: id,
        tier: def.tier,
        school: def.school,
        role: TechniqueRole.main,
        learnedAt: DateTime.utc(2026, 7, 13),
        cultivationLayer: CultivationLayer.zhongCheng,
      );

      final speedBase = CharacterDerivedStats.speed(
        base,
        const [],
        techniqueFor(base.id),
        repository.numbers,
      );
      final speedRaised = CharacterDerivedStats.speed(
        raised,
        const [],
        techniqueFor(raised.id),
        repository.numbers,
      );
      final evasionBase =
          CharacterDerivedStats.evasionRate(base, repository.numbers);
      final evasionRaised =
          CharacterDerivedStats.evasionRate(raised, repository.numbers);
      final criticalBase =
          CharacterDerivedStats.criticalRate(base, repository.numbers);
      final criticalRaised =
          CharacterDerivedStats.criticalRate(raised, repository.numbers);
      recordAttributeObservation(
        stage,
        'agility_speed',
        speedBase,
        speedRaised,
      );
      recordAttributeObservation(
        stage,
        'agility_evasion_rate',
        evasionBase,
        evasionRaised,
      );
      recordAttributeObservation(
        stage,
        'agility_critical_rate',
        criticalBase,
        criticalRaised,
      );
      expect(speedRaised, greaterThan(speedBase));
      expect(evasionRaised, greaterThan(evasionBase));
      expect(criticalRaised, criticalBase);
    });

    test('${stage.name}: fortune changes fortune encounters but not combat stats', () {
      final base = fixture.createCharacter(stage, id: 700 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 800 + stage.index,
        raisedAttribute: AttributeKey.fortune,
      );
      final encounterBase = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.fortune,
        attributes: base.attributes,
      );
      final encounterRaised = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.fortune,
        attributes: raised.attributes,
      );
      final hpBase =
          CharacterDerivedStats.maxHp(base, const [], repository.numbers);
      final hpRaised =
          CharacterDerivedStats.maxHp(raised, const [], repository.numbers);
      final evasionBase =
          CharacterDerivedStats.evasionRate(base, repository.numbers);
      final evasionRaised =
          CharacterDerivedStats.evasionRate(raised, repository.numbers);
      final criticalBase =
          CharacterDerivedStats.criticalRate(base, repository.numbers);
      final criticalRaised =
          CharacterDerivedStats.criticalRate(raised, repository.numbers);
      recordAttributeObservation(
        stage,
        'fortune_encounter_probability',
        encounterBase,
        encounterRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_max_hp',
        hpBase,
        hpRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_evasion_rate',
        evasionBase,
        evasionRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_critical_rate',
        criticalBase,
        criticalRaised,
      );
      expect(encounterRaised, greaterThan(encounterBase));
      expect(hpRaised, hpBase);
      expect(evasionRaised, evasionBase);
      expect(criticalRaised, criticalBase);
    });
  }
}
```

- [x] **Step 2: 运行属性诊断**

Run:

```bash
flutter test --no-pub test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: 初版 12 tests PASS；质量加固拆出每阶段 1 个真实选项 widget test 后为 15 tests PASS。任何失败都进入 Task 7 硬门禁；不因“提升幅度看起来小”修改倍率。

- [x] **Step 3: 联合既有属性入口测试**

Run:

```bash
flutter test --no-pub \
  test/core/domain/attribute_effect_policy_test.dart \
  test/features/injury/application/injury_service_test.dart \
  test/features/cultivation/application/cultivation_service_test.dart \
  test/features/cultivation/application/insight_exchange_service_test.dart \
  test/features/encounter/application/encounter_service_test.dart \
  test/features/encounter/presentation/encounter_dialog_test.dart \
  test/features/battle/damage_calculator_proficiency_wire_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: all PASS。质量加固后真实计数为 81 tests PASS。

- [x] **Step 4: 提交**

```bash
git add \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: diagnose attribute role sensitivity"
```

---

### Task 5: 抽取测试专用战斗采样 API

**Files:**
- Create: `test/support/progression_battle_probe.dart`
- Modify: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`
- Test: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`

- [x] **Step 1: 先运行既有首通诊断保存行为基线**

Run:

```bash
flutter test --no-pub test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

Expected: PASS；保存最终摘要中的总 run 数、平均展示动作行和 `stage_06_05` floor 数据。

- [x] **Step 2: 创建共享类型和 API**

Create `test/support/progression_battle_probe.dart` with these public declarations:

```dart
import 'dart:math';

import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

enum ProgressionBuildProfile { undergeared, standard, nearMax }

final class ProgressionBattleObservation {
  const ProgressionBattleObservation({
    required this.stageId,
    required this.profile,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.playerHpStart,
    required this.playerHpEnd,
    required this.playerQiStart,
    required this.playerQiEnd,
    required this.actionRows,
  });

  final String stageId;
  final ProgressionBuildProfile profile;
  final int seed;
  final BattleResult result;
  final int ticks;
  final int playerHpStart;
  final int playerHpEnd;
  final int playerQiStart;
  final int playerQiEnd;
  final int actionRows;
}

ProgressionBattleObservation probeMainlineStage({
  required GameRepository repository,
  required StageDef stage,
  required ProgressionBuildProfile profile,
  required int seed,
}) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      buildProgressionPlayer(
        repository: repository,
        tier: stage.requiredRealm,
        slot: slot,
        isFounder: slot == 0,
        profile: profile,
      ),
  ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repository.numbers,
    maxTicks: 240,
    rng: Random(seed),
  );
  int sumHp(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentHp);
  int sumQi(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentQi);
  return ProgressionBattleObservation(
    stageId: stage.id,
    profile: profile,
    seed: seed,
    result: terminal.result,
    ticks: terminal.tick,
    playerHpStart: sumHp(initial.leftTeam),
    playerHpEnd: sumHp(terminal.leftTeam),
    playerQiStart: sumQi(initial.leftTeam),
    playerQiEnd: sumQi(terminal.leftTeam),
    actionRows: terminal.actionLog.length,
  );
}
```

Add the complete player builder below. It preserves the existing undergeared/nearMax values and adds only the standard midpoint profile:

```dart
BattleCharacter buildProgressionPlayer({
  required GameRepository repository,
  required RealmTier tier,
  required int slot,
  required bool isFounder,
  required ProgressionBuildProfile profile,
}) {
  const school = TechniqueSchool.gangMeng;
  final numbers = repository.numbers;
  final realm = repository.getRealm(tier, RealmLayer.huaJing);
  final (enhanceRatio, battleCount, cultivationLayer, attributeValue, buff) =
      switch (profile) {
        ProgressionBuildProfile.undergeared =>
          (0.0, 0, CultivationLayer.zhongCheng, 5, false),
        ProgressionBuildProfile.standard =>
          (0.25, 150, CultivationLayer.zhongCheng, 5, false),
        ProgressionBuildProfile.nearMax =>
          (0.5, 400, CultivationLayer.daCheng, 6, true),
      };
  final enhanceLevel = (realm.absoluteLevel * enhanceRatio).round();

  final equipmentTier = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final slotType in const [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final EquipmentDef def = repository.equipmentDefs.values.firstWhere(
      (value) => value.tier == equipmentTier && value.slot == slotType,
      orElse: () => throw StateError(
        'progression_probe: 无 ${equipmentTier.name}/${slotType.name} 装备',
      ),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime.utc(2026, 7, 13),
        obtainedFrom: 'progression_playtest',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
        forgingSlots: const <ForgingSlot>[],
      ),
    );
  }

  final techniqueTier = RealmUtils.techniqueTierCapOf(tier);
  final TechniqueDef techniqueDef = repository.techniqueDefs.values.firstWhere(
    (value) => value.tier == techniqueTier && value.school == school,
    orElse: () => throw StateError(
      'progression_probe: 无 ${techniqueTier.name}/${school.name} 心法',
    ),
  );
  final ownerId = 7000 + slot;
  final mainTechnique = Technique.create(
    defId: techniqueDef.id,
    ownerCharacterId: ownerId,
    tier: techniqueDef.tier,
    school: techniqueDef.school,
    role: TechniqueRole.main,
    learnedAt: DateTime.utc(2026, 7, 13),
    cultivationLayer: cultivationLayer,
  );
  final attributes = Attributes()
    ..constitution = attributeValue
    ..enlightenment = 5
    ..agility = attributeValue
    ..fortune = 5;
  final character = Character.create(
    name: isFounder ? '成长体检祖师' : '成长体检弟子$slot',
    realmTier: tier,
    realmLayer: RealmLayer.huaJing,
    attributes: attributes,
    rarity: RarityTier.biaoZhun,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime.utc(2026, 7, 13),
    internalForce: realm.internalForceMax,
    internalForceMax: realm.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = ownerId;
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTechnique,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: buff,
  );
}
```

- [x] **Step 3: 改既有首通诊断使用共享 API**

In `test/tools/readable_first_clear_tempo_diagnostic_test.dart`:

- import `../support/progression_battle_probe.dart`;
- keep `_TempoRun.fromBattle` and all existing action-log assertions unchanged;
- delete only the now-duplicated local `_buildPlayer` function and profile enum;
- apply these exact type and call-site replacements:

```dart
const readableProfiles = [
  ProgressionBuildProfile.undergeared,
  ProgressionBuildProfile.nearMax,
];

// _TempoRun field and constructor parameter
final ProgressionBuildProfile profile;

// _simulate signature
_TempoRun _simulate(
  StageDef stage,
  GameRepository repository,
  ProgressionBuildProfile profile,
  int seed,
) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      buildProgressionPlayer(
        repository: repository,
        tier: stage.requiredRealm,
        slot: slot,
        isFounder: slot == 0,
        profile: profile,
      ),
  ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repository.numbers,
    maxTicks: _maxTicks,
    rng: Random(seed),
  );
  return _TempoRun.fromBattle(
    stage: stage,
    profile: profile,
    seed: seed,
    initial: initial,
    terminal: terminal,
  );
}
```

Replace `_TempoProfile.values` loops with `readableProfiles`, `_TempoProfile.floor`
with `ProgressionBuildProfile.undergeared`, and `_TempoProfile.ceiling` with
`ProgressionBuildProfile.nearMax`.

- [x] **Step 4: 运行格式与等价性回归**

Run:

```bash
dart format \
  test/support/progression_battle_probe.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart
flutter test --no-pub test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

Expected: PASS，run 数和 Task 5 Step 1 保存的关键摘要相同；若不相同，恢复到语义等价后再继续。

- [x] **Step 5: 提交**

```bash
git add \
  test/support/progression_battle_probe.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: share progression battle probes"
```

---

### Task 6: 生成统一成长路径 CSV 与诊断报告

**Files:**
- Create: `test/tools/progression_playtest_diagnostic_test.dart`
- Create: `test/tools/output/progression_attribute_playtest_2026-07-13.csv`
- Create: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Use: `test/support/progression_battle_probe.dart`

- [x] **Step 1: 写受控规模成长诊断**

Create `test/tools/progression_playtest_diagnostic_test.dart`:

```dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seedCount = 20;
const _csvPath =
    'test/tools/output/progression_attribute_playtest_2026-07-13.csv';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'progression playtest: 30 mainline × 3 profiles × 20 seeds',
    () {
      final stages = repository.stageDefs.values
          .where((stage) =>
              stage.stageType == StageType.mainline &&
              stage.enemyTeam.isNotEmpty)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final rows = <ProgressionBattleObservation>[];
      for (final stage in stages) {
        for (final profile in ProgressionBuildProfile.values) {
          for (var seed = 0; seed < _seedCount; seed++) {
            rows.add(probeMainlineStage(
              repository: repository,
              stage: stage,
              profile: profile,
              seed: seed,
            ));
          }
        }
      }

      expect(stages.length, 30);
      expect(rows.length, 30 * 3 * _seedCount);
      expect(rows.every((row) => row.ticks < 240), isTrue,
          reason: '诊断样本不得撞 maxTicks');

      final buffer = StringBuffer()
        ..writeln(
          'stage_id,profile,seed,result,ticks,player_hp_start,'
          'player_hp_end,player_qi_start,player_qi_end,action_rows',
        );
      for (final row in rows) {
        buffer.writeln([
          row.stageId,
          row.profile.name,
          row.seed,
          row.result.name,
          row.ticks,
          row.playerHpStart,
          row.playerHpEnd,
          row.playerQiStart,
          row.playerQiEnd,
          row.actionRows,
        ].join(','));
      }
      File(_csvPath).writeAsStringSync(buffer.toString());
      print('progression playtest wrote ${rows.length} rows to $_csvPath');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
```

- [x] **Step 2: 运行诊断并核对 CSV**

Run:

```bash
flutter test --no-pub test/tools/progression_playtest_diagnostic_test.dart
wc -l test/tools/output/progression_attribute_playtest_2026-07-13.csv
head -n 2 test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

Expected: test PASS；CSV 为 1801 行（表头 + 1800 个场景）。

- [x] **Step 3: 运行心魔、塔和经验专项形成同 commit 证据**

Run:

```bash
git rev-parse HEAD
flutter --version
flutter test --no-pub \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: all PASS。记录当前心魔 05/06/07、塔 25/30、Lv490 和属性诊断的真实输出。

- [x] **Step 4: 写审计报告**

Create `docs/audit/progression_attribute_playtest_2026-07-13.md`，内容必须按以下固定顺序填写本轮真实值，不引用旧 `PROGRESS.md` 数字：

```markdown
# 成长路径与四属性体感体检 · 2026-07-13

## 运行元数据

- commit：本轮 `git rev-parse HEAD`
- Flutter：本轮 `flutter --version`
- 战斗种子：0～19
- 主线矩阵：30 关 × 3 配置 × 20 seed
- 生产代码修改：是或否，并列出 `lib/` 文件

## 硬契约结论

- Lv1～Lv490 / 49 层：通过或失败，并列失败测试
- 七类经验入口：通过或失败，并列失败测试
- 心魔锁与终境：通过或失败，并列失败测试
- 四属性职责：通过或失败，并列失败测试

## 软观察

- 主线：分别汇总 undergeared / standard / nearMax 胜率、节拍、剩余血量与真气
- 心魔：记录 05/06/07 当前 commit 的固定种子观察值
- 通天塔：记录 25/30 层及前驱层当前 commit 的观察值
- 四属性：逐项记录前/中/后期 baseline 与 raised 原始值，不只写“通过”

## 问题分级

- P0：只列硬契约证明的问题；无则写“无”
- P1：只列确定性职责/显示/落库错误；无则写“无”
- P2：列数值候选及复现配置，不在本批修改
- 观察项：列单个临界种子或主观手感

## 第一批处置

- 已修 P0/P1 及对应测试；无则明确“零生产代码修改”
- 第二批候选：逐项说明为什么可能调整、不调整会怎样
```

- [x] **Step 5: 校验报告引用与 CSV 卫生**

Run:

```bash
git diff --check
rg -n "T[B]D|T[O]DO|待[补]|旧[报]告" \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

Expected: `git diff --check` 无输出，`rg` 无命中。

- [x] **Step 6: 分离提交原始诊断证据与报告恢复点**

原始 test + CSV 先以 `654c317acfca28b2cff492b52f226c299c648c86`
提交；随后在该 commit 重跑全部证据。报告与计划独立进入 docs commit，确保报告
明确绑定已提交 evidence，而不引用同一提交中的未提交状态。

---

### Task 7: P0/P1 证据门禁

**Files:**
- Inspect: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Modify conditionally: this plan and the exact failing production/test files

- [ ] **Step 1: 审核硬失败列表**

Run:

```bash
rg -n "^## 问题分级|^- P0|^- P1" \
  docs/audit/progression_attribute_playtest_2026-07-13.md
git diff --name-only $(git merge-base HEAD main)..HEAD | sort
```

Expected: 问题分级与实际失败测试一致，不能把 P2 或单 seed 观察升级成 P1。

- [ ] **Step 2A: 无 P0/P1 时关闭生产修改门禁**

If P0/P1 都为“无”，run:

```bash
git diff --name-only $(git merge-base HEAD main)..HEAD -- 'lib/**' 'data/**'
```

Expected: 无输出。把报告“第一批处置”写为“零生产代码修改”，继续 Task 8。

- [ ] **Step 2B: 存在 P0/P1 时暂停并具体化修复任务**

If any hard contract fails:

1. 不修改 `lib/` 或 `data/`；
2. 在本计划 Task 7 后追加一个独立任务，标题使用失败行为，例如“修复心魔锁可被离线经验绕过”；
3. 新任务必须列出失败测试、精确生产文件、红绿命令、最小实现代码和独立提交；
4. 若修复需要 `numbers.yaml`、schema、save version 或改变三个以上系统规则，停止并请求用户确认；
5. 追加任务后重新执行 `writing-plans` 自检，再按 TDD 实施。

Expected: 未具体化修复任务前保持零生产修改；不允许用通用“修一下”步骤越过门禁。

- [ ] **Step 3: 提交门禁结论**

若报告因门禁审核有文字修正：

```bash
git add \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "docs: classify progression audit findings"
```

若无文字变化，不创建空提交。

---

### Task 8: 全量门禁、macOS 复验与收尾

**Files:**
- Modify: `PROGRESS.md`
- Modify: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Modify: `docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md`

- [ ] **Step 1: 格式检查与静态分析**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
git diff --check
```

Expected: formatter 0 changed，analyze `No issues found!`，diff check 无输出。

- [ ] **Step 2: 运行本批定向门禁**

Run:

```bash
flutter test --no-pub \
  test/support/progression_playtest_fixture_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart \
  test/tools/progression_playtest_diagnostic_test.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart
```

Expected: all PASS，记录真实非隐藏测试数。

- [ ] **Step 3: 运行全量测试并提取真实计数**

Run:

```bash
set -o pipefail
flutter test --no-pub --reporter json 2>/dev/null \
  | jq -r 'select(.type == "testDone" and .hidden == false) | .result' \
  | sort | uniq -c
```

Expected: 仅一行 `<实际数量> success`，无 failure/error。不可把 hidden load events 计入 pass 数。

- [ ] **Step 4: macOS Debug 构建**

Run:

```bash
flutter build macos --debug
```

Expected: `✓ Built build/macos/Build/Products/Debug/wuxia_idle.app`。第三方 warning 单独记录，不把 warning 写成 build failure。

- [ ] **Step 5: 四画面双视口复验**

用既有 debug visual route/harness 复验：

- 前期角色档案；
- 心魔锁定与经验溢出；
- 战后经验/Lv/突破反馈；
- Lv490 角色档案。

每个画面检查 1280×720 和 1440×900，验收标准：无 overflow/exception、等级与境界一致、心魔等待说明可见、Lv490 无虚假进度。截图路径和结果写入审计报告；本步不改 UI，发现布局问题按 P1 证据门禁新增具体任务。

- [ ] **Step 6: 更新进度文档**

在 `PROGRESS.md` 顶部新增一条，必须区分：

- 已完成：硬契约、诊断矩阵和报告；
- 已验证：format/analyze/定向/全量/build/双视口真实结果；
- 已知风险：P2 和观察项；
- 下批建议：只引用审计报告中的第二批候选；
- 明确是否零生产代码修改，且本批无 `numbers.yaml`/schema/save version 变化。

- [ ] **Step 7: 最终自检与 READY 提交**

Run:

```bash
git diff --check
git status -sb
git log --oneline -10
```

Expected: 仅本步报告/计划/PROGRESS 待提交，历史为小切片提交。

```bash
git add \
  PROGRESS.md \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "[READY] docs: close progression attribute playtest audit"
```

Expected: worktree clean，tip 前缀为 `[READY]`。合并和推送属于后续显式授权，不在本计划自动执行。

---

## 自检清单

- 设计规格的 Lv490、七入口、四属性、成长路径、报告、门禁和真机复验均有对应任务。
- 生产代码默认零修改；P0/P1 未具体化前不能越过 Task 7。
- 软观察不写精确永久断言，所有数字绑定 commit 和 seed。
- 夹具只构造合法样本，不复制生产经验、属性或战斗公式。
- 不包含发布准备、Windows、数值调整、schema/save version 或 rejected registry 方向。
