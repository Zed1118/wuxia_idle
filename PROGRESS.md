# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 1 战斗系统**（phase1_tasks.md 定义的 T01–T18），目标 3 周交付。

## 已完成

- **T01 / T02 / T03**（2026-05-10）已收尾。详见 git log + `lib/data/models/`
  - T01：`flutter create` + Riverpod 2.5 / Isar 3.1 / yaml / intl，`data/` 声明为 asset 根，`*.g.dart` 不入库
  - T02：18 个枚举（91 个值）按 data_schema §2 进 `enums.dart`
  - T03：5 个 @embedded 类 + 2 个 List-as-Map extension，6 用例全过
- **T04 三个核心 Isar 实体（Character / Equipment / Technique）**（2026-05-10）
  - `lib/data/models/{character,equipment,technique}.dart` 三个 @collection
  - 各加 `.create(...)` 工厂方法一次填齐 late 字段；`Equipment.create` 默认填 3 个空 ForgingSlot（索引 1/2/3）
  - 两个 extension：`EquipmentResonance`（resonanceStage/Bonus/inheritFrom）+ `TechniqueDispersion.disperse`
  - 顺手补 T03 5 个嵌入对象缺失的 `part 'xxx.g.dart'` 指令（不补则 Equipment/Technique.g.dart 引用 EmbeddedSchema 编译失败，是 T04 阻塞）
  - `test/data/models/entities_test.dart` 7 用例（factory 默认值 / forgingSlots 自动填齐 / 显式传入保留 / resonance 8 段映射 / inheritFrom 70% / dispersion 半减）全过
  - `flutter analyze` 0 issues / `flutter test` 14/14 通过 / build_runner 49 outputs
- **T05 SaveData + IsarSetup（单 slot 简化版）**（2026-05-10）
  - `lib/data/models/{save_data,inventory_item,game_event}.dart` 三个 @collection（schema §4.1/§4.8/§4.9）
  - `lib/data/isar_setup.dart`：Phase 1 简化版，仅 `init({slotId, directory?, inspector})` + `close()` + `_ensureSaveData()`，switchSlot/listAllSlots/deleteSlot 加 TODO Phase 5
  - `lib/data/game_repository.dart`：T07 占位 stub，main 启动序按 phase1_tasks T05 范式调用
  - `lib/main.dart`：`WidgetsFlutterBinding.ensureInitialized` → `loadAllDefs` → `IsarSetup.init` → `ProviderScope`
  - `IsarSetup.init` 接受可注入 `directory`，生产用 path_provider，测试传临时目录
  - `_allSchemas` 当前 6 个（SaveData/Character/Equipment/Technique/InventoryItem/GameEvent），T11+ 追加 StageProgress/AdventureRecord/RetreatSession/DailyChallenge
  - `test/data/isar_setup_test.dart` 4 用例（首次 init 默认值/再 init 不覆盖原值/三实体 round-trip 字段完整/@Index filter 可查）全过——含 T04 验收剩余 2 条
  - 用 `Isar.initializeIsarCore(download: true)` 在 dart test 环境下 native lib（首次 ~17s，后续缓存）
  - `flutter analyze` 0 issues / `flutter test` 18/18 通过
- **T06 配置类（Defs）**（2026-05-10）
  - 5 个纯 Dart 类（不入 Isar）：`lib/data/defs/{equipment,technique,skill,stage,realm}_def.dart`，`stage_def.dart` 内含 `EnemyDef` plain class
  - 全字段 `final` + `const` 构造 + `factory fromYaml(Map)` + `@override toString()`
  - `fromYaml` 防御性 `(num).toInt()/.toDouble()` 兼容 yaml int/double 写法不一致；枚举走 `Values.byName(...)`；可空字段（schoolBias/parentTechniqueDefId/chapterIndex/towerLayer/narrativeId）显式 null 处理
  - `StageDef.enemyTeam` 支持长度 0–3（剧情关空数组 / 单 Boss / 群战 3 人均覆盖测试）
  - 范围按 phase1_tasks T06 钉的 5 个；AdventureDef / SynergyDef / RetreatMapDef 推迟到 Phase 4（schema §5.5–5.7 留白）
  - `test/data/defs/defs_test.dart` 12 用例（每 Def 全字段 round-trip + 可空字段缺省 + num→int/double 防御性转换 + enemyTeam 空/单/三人）全过
  - `flutter analyze` 0 issues / `flutter test` 30/30 通过
- **T07 YAML 加载器 + GameRepository + 占位 fixture**（2026-05-10）
  - `lib/data/yaml_loader.dart` 递归 deepConvert YamlMap/YamlList → 纯 dart `Map<String,dynamic>`/`List<dynamic>`，便于下游 `as String / as num`
  - `lib/data/numbers_config.dart`：`combat`（damage/maxHp/speed/critical/evasion）+ `levelDiffModifier` + `defenseRateByTier` 强类型；其余段保留 `raw` Map（按 phase1_tasks T07 §7.2 范围）
  - `LevelDiffModifier.diff3OrMore.attacker` yaml 是 null，按 phase1_tasks 提示兜底取 `diff2.attacker`
  - `lib/data/game_repository.dart` 重写：单例 + `loadAllDefs(loader可注入)` + 红线校验（49 行境界 / 装备 baseAttackMax≤2000 / internalForceMax∈[500,15000]）+ getRealm/getRealmByAbsoluteLevel/getEquipment 等便捷方法 + `resetForTest`
  - 占位 fixture（武侠风命名 + description=TODO_NARRATIVE）：
    - `data/equipment.yaml` 10 件（xunChang weapon/armor/accessory + xiangYang weapon/armor/accessory + haoJiaHuo weapon/armor/accessory + liQi weapon），数值贴 numbers.yaml 范围
    - `data/techniques.yaml` 6 本（gangMeng/lingQiao/yinRou × ruMenGong/mingJiaGong）
    - `data/skills.yaml` 18 招（每本 1 普攻 500 + 1 强力 + 1 大招），ultimate 倍率封顶在心法阶 max_skill_multiplier（ruMenGong 1500 / mingJiaGong 2500）
    - `data/stages.yaml` 6 关（mainline/纯测试用，每关 3 敌人覆盖 3 流派，难度递增 xueTu→sanLiu→erLiu）
  - `lib/main.dart` 加 debugPrint counts 日志（仅 kDebugMode），`loadAllDefs` 返回 repo 实例供 main 取数
  - `test/data/game_repository_test.dart` 14 用例（counts 准 / NumbersConfig 强类型 / diff3 兜底 / 便捷查询 / 红线越界 fail-fast / yaml 错语法 / id 重复 / 改 numbers 立刻反映 / 未初始化抛错）全过
  - `flutter analyze` 0 issues / `flutter test` 44/44 通过

## 进行中

- 无

## 已知偏差 / 挂账事项

1. **Riverpod 版本**：CLAUDE.md v1.1 锁 3.x，但实际用 2.x（phase1_tasks.md 一致）。等 Phase 5 收尾时统一文档
2. **lib/ 目录结构**：CLAUDE.md 写 DDD（`core/features/shared`），实际用 phase1_tasks 的 flat（`data/combat/ui/providers`）
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` 在 analyzer 版本互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个（章节3+关卡15+装备45+心法22+招式102+奇遇26+百科18+模板7）。等 DeepSeek 改文末
5. **phase1_tasks.md T17 场景 D 笔误**：「差 2 大境界」应为「差 3」（三流→绝顶）。做到 T17 时一并改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 numbers.yaml 平衡值（×1.0 / ×0.7）为准。GDD 文字暂不修
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气。GDD 没明确要求 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界层 vs 修炼度层重名、属性单项分布、+20+ 强化曲线等。Phase 1 实现到对应位置时按需提问
9. **T05 验收「inspector: true 浏览器看表」未跑**：需要 `flutter run` 实机启动，Mac 端无 Xcode 跑不了 macOS desktop，留给 Windows DeepSeek 端首次跑应用时验。代码已默认开 inspector
10. **yaml key 命名约定差异**：`numbers.yaml` 用 snake_case（CLAUDE.md §4 规范），内容 yaml（equipment/techniques/skills/stages）用 camelCase（与 schema §5 JSON 示例 + Def.fromYaml 期望对齐）。两套约定按文件类型隔离不冲突
11. **T07 验收「日志输出 counts」**：Mac 端 `flutter run` 跑不了，已写在 main.dart 的 `kDebugMode` debugPrint 里，留给 Windows DeepSeek 端首次跑应用时看到

## 下一步

T08 境界派生工具（Week 2 战斗核心起点）→ T09 角色派生属性 → T10 伤害计算器

## 关键约束（每次开局必读）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 不硬编码数值（走 numbers.yaml）、不硬编码中文文案（走 data/narratives, lore, events）
- Riverpod 状态管理；Isar 本地存储；data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md（DeepSeek 领地）
- Mac 端写 lib/、data/*.yaml（顶层）、test/；DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub：https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作：Mac+Opus 写代码与数值；Windows+DeepSeek 写文案
