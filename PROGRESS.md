# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 2 装备 + 心法系统**（phase2_tasks.md 定义的 T19-T32），目标 3 周交付。Phase 1 已完成（v0.1.0-phase1）。

## 已完成

- **T01-T07**（2026-05-10）已收尾，详见 git log + `lib/data/`：T01 工程脚手架（Riverpod 2.5 / Isar 3.1 / yaml / intl）/ T02 18 枚举（91 值）/ T03 5 @embedded + 2 List-as-Map extension / T04 Character/Equipment/Technique @collection + Resonance/Dispersion / T05 SaveData + IsarSetup（单 slot，多 slot 留 Phase5）/ T06 5 Def 纯类（equipment/technique/skill/stage/realm）/ T07 yaml_loader + GameRepository 单例 + 红线校验 + 占位 fixture 10/6/18/6（武侠风命名+TODO_NARRATIVE）。累计 44/44 通过
- **T08 RealmUtils 境界派生**（2026-05-10）：`lib/combat/derived_stats.dart` 6 静态纯函数（absoluteLevelOf / realmDiffModifier / internalForceMaxOf / defenseRateOf / equipmentTierCapOf / maxEnhanceLevelOf）走 GameRepository + numbers.yaml 零硬编码；差 3+ attacker 按 GDD §5.5 取 1.0（yaml 是 null，挂账 #12）；15 用例
- **T09 CharacterDerivedStats 角色派生**（2026-05-10）：追 `CharacterDerivedStats`（maxHp / speed / criticalRate / evasionRate / effectiveEquipmentAttack/Hp/Speed）；NumbersConfig 扩 `enhancementBonusPerLevel` + `techniqueSpeedBonus`；按 §515 乘法连乘；criticalRate clamp 0.50；5 战例 maxHp 实测 A=3850 / B=6600 / C=6180 / D=7760 / E=19500；21 用例
- **T10 伤害计算器（核心）**（2026-05-10）：`damage_calculator.dart` AttackContext / AttackResult / DamageCalculator。7 阶段流水（闪避→基础→修炼度→流派克制→暴击→防御→境界差），NumbersConfig 扩 `cultivationMultiplier` + `SchoolCounterMatrix`(单向查表)；5 战例 A-D 与 yaml 误差 ≤1.2%；formulaBreakdown 字符串便于调试；21 用例
- **T11 战斗状态机数据结构**（2026-05-10）：`battle_state.dart` BattleResult / BattleAction / BattleCharacter(immutable) / BattleState(initial+copyWith with sentinel+isFinished+pendingUltimates)；`fromCharacter` 单一入口走 CharacterDerivedStats；边界守卫 fail-fast；T12 时追三字段；16 用例
- **T12 战斗引擎 + AI**（2026-05-10）：`battle_ai.dart` 纯函数 `decide → (SkillDef,targetId)`，优先级 pendingUltimates > powerSkill > normalAttack，目标对面活角色 currentHp 最低；`battle_engine.dart` tick / runToEnd(maxTicks=1000) / requestUltimate，tick 顺序锁死=CD-1→ap+=speed→筛活角色排序行动→应用结果消费 pending；`_calculateInBattle` 复刻 T10 公式读 BattleCharacter 快照避免循环 import；12 用例
- **T13 战斗事件日志**（2026-05-10）：`enum_localizations.dart` `EnumL10n` Phase 1 唯一"代码内中文"位置（覆盖 BattleResult/TechniqueSchool/RealmTier/RealmLayer/SkillType + realm 拼接 + attackEffect）；`battle_log.dart` formatAction 5 分支（普通/暴击/闪避/克制/击杀，克方主语对齐 GDD §4.4）+ formatSummary + formatAllActions；与 DamageCalculator 解耦不重算；16 用例
- **T11 前清账冲刺**（2026-05-10）：5 处硬编码接 NumbersConfig（共鸣阈值/倍率、师承遗物 0.7、散功 0.5、灵巧暴击 +0.20 与 ×2.0）；API 改签（Equipment.resonance* getter→方法、inheritFrom/disperse 加 NumbersConfig 参数）；numbers.yaml 修 b/c max_hp + 加 critical 段；phase1_tasks T10 §576 ≤30000→≤100000；CLAUDE.md §2 锁 Riverpod 2.x；解 #1/#13/#14/#15/#16
- **T14 战斗 UI 布局（3v3 半横版静态）**（2026-05-10）
  - `lib/ui/theme/colors.dart`：`WuxiaColors` 集中色板。`schoolColor` 三流派（刚猛红 `0xFFC23A2A` / 灵巧金 `0xFFD4A12C` / 阴柔紫 `0xFF8B5BB2`）+ `hpColor` 三段（>50% 绿 / 25-50% 黄 / <25% 红）+ 内力蓝 + UI 中性灰
  - `lib/ui/strings.dart`：`UiStrings` UI 静态中文集中位置（与 `enum_localizations.dart` 同性质，便于 i18n 迁出）。当前收：`battleTitle` / `tickPrefix` / `battleLog` / `emptyLog` / `ultimate` / `fastForward`
  - `lib/ui/battle/hp_bar.dart`：通用比例条 Stack 三层（轨道 / `FractionallySizedBox` 填充 / 居中文本）。`isInternalForce=true` 走内力蓝，否则走 HP 三段色；`max≤0` clamp 0 不崩
  - `lib/ui/battle/character_avatar.dart`：圆头像首字（`name.characters.first` 防 BMP 外字符）+ 流派色 4px 边框 + 名字 + 境界（走 `EnumL10n.realm`）+ HP 条 14px + 内力条 9px。`isAlive=false` 整体 `Opacity(0.3)` 落 §794 验收
  - `lib/ui/battle/battle_screen.dart`（T14 初版）：静态布局，StatelessWidget
  - `lib/ui/battle/battle_demo.dart`：T14 视觉目测 mock，直接构造 6 角色覆盖 3 流派/满-中-残/死亡
  - `lib/main.dart`：home 改 `BattleScreen(state: BattleDemo.build())`，`IsarSetup.init()` 加 `kIsWeb` 守卫
  - `flutter analyze` 0 issues / `flutter test` 146/146（widget +2 - 旧 startup smoke -1）
  - 挂账 #18 新增
- **T15 攻击动画 + 伤害飘字**（2026-05-10）
  - `data/numbers.yaml`：新增 `animation` 段（前冲/停顿/后撤/飘字/快进/屏震时序 11 键）
  - `lib/data/numbers_config.dart`：新增 `AnimationNumbers` 类（含 `const defaults` 供测试），`NumbersConfig` 新增 `animation` 字段
  - `lib/ui/theme/colors.dart`：追加 `popupNormal/popupCritical/popupDodge` 三色
  - `lib/ui/strings.dart`：追加 `dodge/counterUp/counterDown`
  - `lib/ui/battle/attack_animation.dart`（新建）：`AttackAnimationWidget` 无状态，外部注入 AnimationController，`_computeOffset` 三段式 easeIn/停顿/easeOut；HP 条随 CharacterAvatar 同体平移
  - `lib/ui/battle/damage_popup.dart`（新建）：`DamagePopupData` + `DamagePopup`，`SingleTickerProviderStateMixin`，后半段淡出，`criticalFontScale` 从 `AnimationNumbers` 注入
  - `lib/ui/battle/battle_screen.dart`（重构为 StatefulWidget）：`TickerProviderStateMixin` 管理 6 攻击 controller + 1 屏震 controller；`Timer.periodic` 按 actionLog 顺序播放；`_CharacterSlot` Stack(clipBehavior: none) 承载动画包 + 飘字；快进按钮内部控制间隔切换；`dispose()` 保证 7 个 controller 全部释放
  - `test/widget_test.dart`：追加 7 条 T15 测试（dispose 无泄漏/普通飘字/闪避飘字/克制标记/普攻串行/暴击串行/闪避串行），_testAnim 短时序（50ms 间隔）
  - **review 修复**（Mac 端 Opus 4.7）：删 `_CharacterSlot.super.key` 警告 / widget_test 3 处冗余 `const <String>[]` / `AttackAnimationWidget` 改 `config: AnimationNumbers` 注入，三段式比例由 `attackRushMs/attackHoldMs/attackTotalMs` 动态计算（修 yaml 即生效）
  - `flutter analyze` 0 issues / `flutter test` 153/153（Mac 端实测，已对齐预期）
- **T17 4 套战斗测试场景**（2026-05-11）
  - `lib/ui/debug/battle_test_menu.dart`（新建）：BattleTestMenu 调试菜单 + ScenarioLauncher + 4 场景工厂（内存对象不写 Isar）
  - `BattleScreen` 加 hint 横幅 + onBattleEnd 回调；main.dart home 改 BattleTestMenu
  - 4 场景：A 同境界速度对决 / B 全面克制循环 1.667× / C +12默契纯武器 ×1.92（IF=0）/ D 差 3 境界碾压（绝顶7020一击杀三流6000血）
  - 修正挂账 #5（T17 笔误"差 2"→"差 3"）；test 160/160；分支 feat/t17-test-scenarios 24ff82c
- **T18 Phase 1 验收**（2026-05-11）
  - flutter analyze 0 issues / flutter test 160/160 全绿
  - feat/t15 / feat/t16 / feat/t17 三分支 no-ff 合并 main；tag v0.1.0-phase1 推送
  - phase1_summary.md：功能清单 / 5 战例数值对照（误差 ≤1.1%）/ 已知问题 / 性能基准
- **Phase 2 Week 1 数值层装备**（2026-05-11，分支 feat/phase2-equipment）
  - T19 EquipmentFactory + Rng 抽象（10 用例：固定种子复现 / 蒙特卡洛区间 / fail-fast）
  - T20 强化服务 + 心血结晶（20 用例：4 段成功率 / +20-49 公式 / penalty half/full / 保底 3 段 / 1000 次蒙特卡洛 ±5%）
  - T21 开锋服务 + EquipmentDef.specialSkillCandidates（18 用例：3 槽 unlock / 槽 2 互斥 / specialSkill 三类校验）
  - T22 装备战斗加成整合 + 师承内力上限 + 11 战例验收（+0/+12/+19/+49 / 全栈 883 / 师承 0/1/4 件）
  - 累计 219/219 测试，0 issues
- **Windows 视觉验收 T15/T16/T17**（2026-05-11，Pen 实测 5 张截图）
  - A 同境界普伤 2613（区间 2000-8000 ✅）/ B 克制比值 3852/2311=1.67×（与 banner 精确匹配）/ C +12默契vs裸装 1142/595=1.92×（精确）/ D 1v3 绝顶 8370 一击杀三流 6000
  - 攻击动画 + 飘字（普伤/暴击/闪避三色）+ 击杀标记 + HP 三段色 + 内力蓝 + Opacity 0.3 死亡淡化 + 大招 IF<阈值置灰 全部正常
  - 中文 BMP 外字符（降世神拳等）显示无缺字；BattleTestMenu / 4 场景启动 / battle_screen Riverpod 串接全部生效
- **T23 心法学习服务**（2026-05-11，分支 feat/phase2-equipment）
  - `data/numbers.yaml` 新增 `techniques.learning_cost`（assist=100 / main=500，Pen 拍板）
  - `lib/data/numbers_config.dart`：新增 `LearningCostConfig`（assist/main + `costFor(role)`），`NumbersConfig` 加字段 + fromYaml 接 `techniques.learning_cost`
  - `lib/combat/derived_stats.dart`：新增 `RealmUtils.techniqueTierCapOf(RealmTier) → TechniqueTier`（仿 equipmentTierCapOf，从已有 RealmDef.techniqueTierCap 取）
  - `lib/services/technique_learning.dart`（新建）：`TechniqueLearningService.learn(...)` 返回 `TechniqueLearningResult`；4 类校验 fail-fast 顺序：tier 上限 → 主修存在 → 辅修槽满 → 领悟点；服务**只构造 Technique 实例**，写 Isar / 改 Character 字段归调用方（与 EnhancementService 一致）
  - 单测 10/10：LearningCostConfig 解析 ×2 / 4 类失败分支 + 校验顺序 / 主修+辅修+刚好达 tier 上限 ×3 成功路径
  - 累计 229/229 测试，0 issues
- **T24 修炼度累积**（2026-05-11，分支 feat/phase2-equipment）
  - `lib/data/numbers_config.dart`：新增 `Map<CultivationLayer, int> cultivationProgressToNext`（解析 `techniques.cultivation.progress_to_next`，仅 8 entry，jiJing 不收录）
  - `lib/services/cultivation_service.dart`（新建）：`CultivationService.recordSkillUsage({tech, skillId, progressToNextMap, delta=1})` 返回 `CultivationProgressResult(didLevelUp / oldLayer / newLayer / layersGained / currentProgress / currentProgressToNext)`；in-place 修改 Technique（与 EnhancementService 一致）
  - 升层逻辑：increment skillUsage → progress += delta → while (layer != jiJing && progress >= progressToNext) 消耗升层 + 切换 progressToNext；jiJing 时保留升上来的 progressToNext 值（=6500）作封顶上限
  - 单测 12/12：cultivationProgressToNext 解析 ×2 / 单次累积 / 跨层 +1 / 多层连升 +1000 / 一次塞 5000 +5 层 / 16250 全升 / 30000 封顶 / 20000 不封顶 / jiJing 再加封顶 / skillId 同/异累计
  - 累计 241/241 测试，0 issues
- **T16 Riverpod 串接 + 大招触发 + 结算 overlay**（2026-05-10）
  - `lib/providers/battle_providers.dart`（新建，`@riverpod` 代码生成）：`numbersConfigProvider` 包装 GameRepository 单例 / `BattleNotifier` (startBattle / requestUltimate / `advance` 连续 tick 直到 actionLog 增长或战斗结束) / `leftTeamProvider` / `rightTeamProvider` / `battleResultProvider`
  - **`advance()` 与 spec 偏差说明**：spec §16.1 写 `advanceTick()` 单 tick，实际改为连续 tick 直到出 action。原因：单 tick 是 actionPoint += speed 的最小时间单位，不一定有人 ≥1000 行动；若 UI Timer 间隔=单 tick 则慢角色场景看大段空白。`maxConsecutiveTicks=100` 兜底
  - `lib/ui/battle/battle_screen.dart`（改 ConsumerStatefulWidget）：移除 state/onUltimate/onFastForward 参数；`ref.listen` 三类边沿（team 从空→非空启动 Timer / actionLog 增长触发动画+解除大招置灰 / result 翻转弹 dialog）；team 空时 placeholder
  - `lib/ui/battle/battle_demo.dart`：`BattleDemo.build()`→`mockTeams()` 返回 `(left, right)`；新增 `BattleDemoLauncher`（initState `addPostFrameCallback` 调 startBattle）
  - `lib/main.dart`：home 改 `const BattleDemoLauncher()`
  - 大招按钮：本地 `Set<int> _disabledUltimateChars` 置灰（不污染 BattleState），按下加 / actor 行动后移除；`_isUltimateReady` 检查 alive + 内力 + CD
  - 结算 overlay：result 翻转 → `addPostFrameCallback` → `showDialog`（避免 build 期 setState）；`UiStrings.battleSummary` 显示总伤害/暴击次数/用时 tick
  - `test/widget_test.dart`：`_TestBattleNotifier`（advance no-op 避免测试触发 numbersConfigProvider）+ ProviderScope override pumpBattle helper；T16 新增 3 用例（结算 dialog / 大招按钮 enabled 状态 / 按下置灰+解除）
  - `flutter analyze` 0 issues / `flutter test` 156/156（base 153 + T16 新增 3）

## 进行中

- Phase 2 Week 2 心法 + 战斗联动（T23-T27），分支 feat/phase2-equipment（暂沿用，T28+ UI 阶段再分）

## 已知偏差 / 挂账事项

2. **lib/ 目录结构**：CLAUDE.md 写 DDD（`core/features/shared`），实际用 phase1_tasks 的 flat。Phase 5 整理
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` analyzer 互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个。等 DeepSeek 改文末
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 yaml 平衡值（×1.0 / ×0.7）为准
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气。GDD 没明确 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界/修炼度层重名等。Phase 1 实现到对应位置时按需提问
9. **T05 验收 inspector 未跑**：Mac 无 Xcode 跑不了 desktop，留 Windows 首跑验
10. **yaml key 命名约定差异**：numbers.yaml snake_case，内容 yaml camelCase。按文件类型隔离不冲突
11. **T07 验收 counts 日志**：Mac 跑不了 `flutter run`，已写 main.dart kDebugMode，留 Windows 首跑验
12. **`LevelDiffModifier.diff3OrMore.attacker` 数据层 vs 公式层语义不同**：NumbersConfig 兜底为 `diff2.attacker`(=2.5)，公式层取 `1.0`。Phase 5 收尾时一并把兜底改 1.0
17. **phase1_tasks T12 §709 笔误**：「三流→绝顶差 2 守方 0.05」错（差 2 守方=0.3，差 3+ 才是 0.05）。"必败"语义仍成立，验收按差 2 实测
18. **`flutter build web` 被 Isar 阻塞**：`combat/*.dart` 链路通过 `data/models/{character,equipment,technique}.dart` 拉入 `*.g.dart` 64-bit hash 字面量（JS 表示不下）+ Isar `dart:ffi` web 不支持。Phase 5 切 Isar 4.x 时一并恢复 web 入口

> 已解决条目（#1/#13/#14/#15/#16/#19/#20）已归档到文末。

## 下一步

T25 散功服务（双重惩罚 + cultivationLayer 重算）：DispelService.dispel / 内力 ×0.5 / progress ×0.5 / 反查 progressToNext 回退 layer / 6+ 用例

⚠️ T25 涉及 cultivationLayer 反向重算（progress×0.5 后跨层回退 + 加上前层差额），算法易错。开工前建议升 opus 4.7（已在），写一个 `_recalcLayerFromProgress` 纯函数单独覆盖。

## 关键约束（每次开局必读）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 不硬编码数值（走 numbers.yaml）、不硬编码中文文案（战斗调试日志走 enum_localizations.dart，UI 标签走 lib/ui/strings.dart，剧情走 data/narratives, lore, events）
- Riverpod 状态管理；Isar 本地存储；data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md（DeepSeek 领地）
- Mac 端写 lib/、data/*.yaml（顶层）、test/；DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub：https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作：Mac+Opus 写代码与数值；Windows+DeepSeek 写文案

## 归档（已解决挂账）

#1 Riverpod 锁 2.x / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）/ #19 T15 远程沙箱无 Flutter（2026-05-10 Mac 本地 review 时实跑 analyze + test 全绿，153/153）/ #20 T15/T16/T17 Windows 视觉验收（2026-05-11，5 截图 4 场景 A2613/B1.67×/C1.92×/D8370 全部命中）。
