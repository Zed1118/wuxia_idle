# 新手前 30 分钟体验审计 · 2026-06-28

## 结论

当前前 30 分钟骨架比 5 月 H1 审计健康得多：生产新档已回归“学徒 · 单人 · 空手起家”，首关必掉装备/材料，首胜能触发小层突破，主菜单晚期系统已有锁印门控，装备穿戴入口也已补齐。默认不建议本批改 `lib/` / `data/`。

剩余主要风险不是“缺教程弹窗”，而是两件事：生产单人空手开局缺真实战斗胜率红线测试；step 1/2 的下一目标依赖菜单状态和关卡行信息，缺一个不打断流程的默认目标强化。

## 约束来源

- `AGENTS.md`：不新增教程弹窗；数值/文案不硬编码；在线=离线。
- `CLAUDE.md` §8.0：独立分支、计划文件、小切片 commit、恢复点。
- `GDD.md` §5.7：爽感来自表现层和即时反馈，不靠数值膨胀。
- `GDD.md` §10：0-15 分钟为战斗/境界/装备掉落，15-30 分钟为装备强化/共鸣被动展示；第一小时应轻松取胜；未解锁系统隐藏或灰显。
- `docs/spec/playability_phase2_backlog.md` §十二：本项只优化解锁顺序、默认目标、初期掉落、首个失败点、首个成长反馈。

## 前 30 分钟路径

| 时间 | 当前路径 | 证据 | 判断 |
|---|---|---|---|
| 0 分钟 | Splash 只加载 defs，进入 3 槽存档选择；空槽确认后 `switchSlot` 并执行 onboarding。 | `splash_screen.dart` 注释说明不在 splash 初始化 Isar；`save_select_screen.dart` 调 `OnboardingService.ensureFoundingMasters()`。 | 合理。确认弹窗是存档操作，不是教程弹窗。 |
| 0-2 分钟 | 新档只种祖师一人，`xueTu/qiMeng`，空装备，2 本入门功，50 磨剑石，0 心血结晶。 | `onboarding_service.dart` 默认 `soloStart=true`；`masters.yaml` 祖师学徒、`startingEquipmentIds: []`；`onboarding_service_test.dart` 覆盖单人出战和 50/0 物料。 | 符合“学武出山”，但战斗验证要跟上。 |
| 2-5 分钟 | 主菜单给“主线江湖路”状态，进入 Ch1；Ch1 新进度只开放 `stage_01_01`。 | `main_menu.dart` `_mainlineMenuStatus`；`stage_list_screen_test.dart` 验证 01 可挑战、02-05 锁定。 | 默认目标可达，但主菜单入口较多，主线 CTA 可再强化。 |
| 5-10 分钟 | 首关 `stage_01_01`：3 名学徒敌，必掉寻常护甲、磨剑石、银两，30% 饰品。 | `data/stages.yaml` 首关 dropTable；`game_repository_test.dart` W13-v3 首关必掉护甲+磨剑石；`drop_table_reference_redline_test.dart` 校验引用。 | 初期掉落足够清晰。 |
| 10-15 分钟 | 首胜结算显示掉落、战斗摘要、境界/等级成长。 | `numbers.yaml` 学徒启蒙 `experience_to_next: 50`；`stage_01_01 baseExpReward: 50`；`stage_entry_flow.dart` 胜利后对 active 角色 `applyExperience` 并传入 `StageVictoryContent`。 | 首个成长反馈强：首胜即小层突破。 |
| 15-30 分钟 | 继续 Ch1 02-04；step 2 后理论进入装备强化/共鸣被动展示区间，但没有 step 2 banner。 | `tutorial_service.dart` step 2 = `stage_01_02` cleared；`tutorial_hint_def.dart` 明确 step 1/2/4 不立 banner。 | 可接受但有摩擦：玩家未必知道“去角色/装备槽强化首件装备”。 |
| 30 分钟边界 | `stage_01_05` 后 step 5 才弹闭关/江湖提示；章末 Boss 同阶 `xueTu/dengFeng`，失败会走 Boss 失败惩罚和战败剧情。 | `data/stages.yaml` `stage_01_05`；`stage_entry_flow.dart` Boss 失败分支会 `_applyBossDefeatPenalty`。 | 这是第一个明确失败点候选；需要单人开局胜率红线测试确认是否过早。 |

## 已改善现状

- 主菜单未解锁系统已门控：心法/藏经阁按 tutorial step，晚期战斗按 `stage_06_05`，江湖/门派/排行榜/藏卷阁按 `stage_01_05`，战绩册/兵器谱/商店按实际获得记录解锁。
- 掉落装备已能穿戴：`EquipmentService.equip` 守 §5.3 境界锁，`EquipSlotDialog` 从角色装备槽进入，`equipment_service_test.dart` 和 `equip_slot_dialog_test.dart` 覆盖。
- 战前可读性已补强：关卡行显示推荐境界和掉落摘要，info 角标升级为战前情报，`stage_row_loot_wiring_test.dart` 覆盖。
- 首胜成长反馈成立：首关经验正好等于第一层阈值，胜利结算会展示 `AdvancementSummary`。

## 当前摩擦

### M1 · 生产单人开局缺首章胜率红线测试

当前 `onboarding_service_test.dart` 证明 production seed 是单人空手，但真战斗 e2e 仍用 `soloStart=false` 满队验证 `stage_01_01 buildTeams`。`battle_strategy_e2e_test.dart` 使用 `Phase2SeedService.seedP3()`，不是 production onboarding。也就是说，首关/前四关/章末 Boss 对“单人学徒空手祖师”的真实胜负没有红线覆盖。

风险：GDD §10 要求第一小时轻松取胜；如果 `stage_01_05` 或更早关卡在单人开局下过早失败，现有测试不一定抓到。

### M2 · step 1/2 的默认目标不够显性

实现有意识不为 step 1/2/4 弹 banner，避免打断。但 GDD §10.1 把 15-30 分钟锚定为装备强化+共鸣，当前玩家在 `stage_01_02` 后只得到菜单状态、关卡行、装备详情入口等间接信号。对“默认目标”来说，缺一个非弹窗的轻提示或菜单状态，告诉玩家首件护甲可以穿上/强化。

风险：玩家会继续点主线也能走，但可能错过 50 磨剑石的“首次强化”反馈；这会削弱 15-30 分钟装备成长主题。

### M3 · 首个失败点语义需要固定

普通关失败可免费重试；Boss 失败有惩罚与剧情。这个规则本身合理，但前 30 分钟首个失败点如果落在 `stage_01_05`，需要确保战前整备条已经明确给出“装备/心法补强”或“已可挑战”的准确判断。当前整备条只按推荐境界差判断；同阶但空装备/未强化时仍可能显示可挑战。

风险：若真实单人 build 在章末 Boss 边缘，玩家收到的整备反馈可能偏乐观。

## 推荐修复切片

### Slice A · 补 production onboarding 首章战斗红线测试

目标：不改数值，先把“生产单人空手开局”纳入测试。

建议文件：
- 新增 `test/features/onboarding/onboarding_first_30min_battle_test.dart`

建议断言：
- fresh Isar + `ensureFoundingMasters()` 默认参数后，`stage_01_01` 至 `stage_01_04` 用固定 seed `BattleEngine.runToEnd` 不抛且至少不出现 `rightWin`。
- `stage_01_05` 可先只诊断输出或软断言“不撞 maxTicks + 有终态”；若结果是右胜，再由人类拍板是允许首个失败点还是调装备/强化默认目标。

验证：
- `flutter test test/features/onboarding/onboarding_first_30min_battle_test.dart`
- 保留现有 `onboarding_service_test.dart`。

风险：如果测试暴露当前单人开局打不过早期关卡，不要立即调高数值；先记录首个失败点，再决定是默认装备、初期掉落、强化提示还是关卡数值。

### Slice B · 强化 step 2 非弹窗目标提示

目标：不新增教程弹窗，只用菜单状态或已有 banner 体系补“装备强化/首件穿戴”目标。

建议方案：
- 在主菜单“装备仓库”或角色面板入口 `status` 加短状态：如有可穿戴/可强化装备时显示“可换装”或“可强化”。
- 或新增 step 2 的 `TutorialHintDef`，但仍是主菜单上下文气泡，不是弹窗；文案限制在 50-100 字，强调“先把首件护甲穿上，再试一次强化”。

建议优先级：先做菜单状态，侵入更小，且不增加气泡数量。

验证：
- `flutter test test/features/mainline/presentation/stage_list_screen_test.dart`
- `flutter test test/features/inventory/presentation/inventory_screen_test.dart`
- 新增/扩展主菜单 widget test 覆盖 status。

### Slice C · 章末 Boss 整备条纳入装备/强化缺口

目标：避免同阶但空装/低强化时误报“稳妥”。

建议方案：
- 保持 `StagePreparationSummary` 的境界判断不变。
- 在表现层额外读取当前角色装备槽与强化状态，若 `stage.isBossStage && currentRealm == requiredRealm && 装备缺槽或全 +0`，action 文案偏向“装备/心法补强”。

验证：
- `stage_list_screen_test.dart` 增加同阶空装 Boss 行显示补强建议。
- 不改战斗公式、不改掉落。

## 验证记录

本 worktree 初始缺 `.g.dart` 生成文件，首次测试编译失败。按项目历史约定运行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

当前 build_runner 提示 `--delete-conflicting-outputs` 已被忽略，但生成成功：`Built with build_runner/aot in 62s; wrote 112 outputs.` 生成物为 gitignored，本批不提交。

随后运行：

```bash
flutter test test/features/onboarding/application/onboarding_service_test.dart test/features/tutorial/application/tutorial_service_test.dart test/features/tutorial/domain/tutorial_hint_def_test.dart test/data/game_repository_test.dart test/data/drop_table_reference_redline_test.dart test/features/mainline/presentation/stage_list_screen_test.dart test/features/loot_preview/stage_row_loot_wiring_test.dart test/features/equipment/application/equipment_service_test.dart test/features/character_panel/presentation/equip_slot_dialog_test.dart
```

结果：`All tests passed!`，共 103 tests。

## 局限

- CodeGraph 在本 worktree 未初始化，结构查询改用 `rg` 和定向读取。
- 本批未运行真实 UI 视觉验收，也未新增临时战斗模拟文件。
- 现有测试仍缺 production `soloStart=true` 的首章真实胜负覆盖；这是本报告最高优先级后续切片。
