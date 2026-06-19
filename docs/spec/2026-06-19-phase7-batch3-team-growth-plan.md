# 第七阶段·批三·队伍成长 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把开局从「3 人满队」重塑成「孤身祖师 → 过 01_02 大弟子拜入 → 过 01_04 二弟子拜入」的渐进成长弧,并让三角色战斗职责三分(祖师爆发/大弟子破防/二弟子破招控场)。

**Architecture:** ① 渐进解锁 = 生产 onboarding 改单人种子(`soloStart` 参数隔离,debug 保满队)+ 懒创建弟子的 `DiscipleJoinService`(挂 victory hook)。③ 职责差异 = LineageRole 加 senior/junior(masters.yaml 驱动)+ autoFill 破防倾向只给 senior + BattleCharacter 透传 lineageRole 让 battle_ai 给 junior「优先盯蓄力敌」。④ 拜入仪式 = 复用 NarrativeReaderScreen + presentHeroCamera。存档 0.24→0.25 迁移:老档弟子原地不动只补 role + 防重触发。

**Tech Stack:** Flutter Desktop · Riverpod 3 · Isar · YAML 配置 · TDD。**红线**:不加属性 buff / 不改伤害公式量级 / 文案进 data+UiStrings / 数值进 yaml(守 §5.1/§5.4/§5.6/§5.7)。

**关键约束:**
- `flutter test` / `flutter analyze` 不加 `DEVELOPER_DIR=` 前缀;git 命令才加。
- 改 enum / Isar 实体字段后必跑 `dart run build_runner build --delete-conflicting-outputs`(.g.dart gitignored)。
- 每 task 跑**全量** `flutter test`(不只自测文件)防跨文件回归 + `flutter analyze` 0。
- baseline:**2566 测 +1 skip / analyze 0**(本会话主 checkout 实测)。

**关键签名锚点(摸排实测 file:line):**
- `LineageRole`(`lib/core/domain/enums.dart:160`):founder/disciple/grandDisciple。
- `MasterDef.lineageRole` 走 `LineageRole.values.byName`(`lib/data/defs/master_def.dart:39`);masters.yaml slot1=`first_disciple`(line 34)/slot2=`second_disciple`(line 55)现 `lineageRole: disciple`。
- `buildMasterCharacter(MasterDef, {required DateTime now})`→ `Character.create(... lineageRole: def.lineageRole, isFounder:..., isActive: true)`(`master_builder.dart:29-53`)。`equipMasterStarting` / `learnMasterStarting`(同文件)。
- `OnboardingService.ensureFoundingMasters()`(`onboarding_service.dart:44`)创建 3 角色 + `activeCharacterIds=[1,2,3]`。caller:splash(生产 `splash_screen.dart:60`)+ debug(`phase2_seed_service.dart:1203` / `visual_route_host.dart:150,174,191,196`)。
- `SaveData`(`save_data.dart`):`activeCharacterIds`(line 37)/`triggeredBossRecruitStageIds`(line 74,防重模式参照)。
- `SkillLoadout.autoFill(... LineageRole? lineageRole, bool isFounder)`:破防倾向 `lineageRole == LineageRole.disciple`(`skill_loadout.dart:97-129`)。
- `BattleCharacter`(`battle_state.dart:101`,非 Isar 运行时类)构造器 line 212-251,`fromCharacter`(line 264),`copyWith`(line ~490)。**无 lineageRole 字段**。`chargingSkill`/`chargeTicksRemaining`(line 182-184)。
- `BattleAI.decide`(`battle_ai.dart:28`)目标级联 line 61-74;`_pickFocusTargetId`(line 179)/`_pickTargetId`(line 152)。
- victory 流程 `runStageFlow`(`stage_entry_flow.dart:80`):victory 段 line 181-296。锚点:hero camera(230)→ 技能珍稀(236)→ 仪式+dialog(239-250)→ victory narrative(258-271)→ encounter hook(277-282)→ `runStageBossRecruitHookAfterVictory(context,ref,stage)`(288-292)→ 声望(295)。`clearedBeforeVictory` 快照(190-198)。
- `presentHeroCamera(BuildContext, HeroCameraData)`(`victory_ceremony.dart:191`);`HeroCameraData{portraitPath,heroName,realmLabel,bossName,topDamage}`。
- `NarrativeReaderScreen({required content, required fallbackTitle, onFinish, topBanner, backgroundImagePath})`;`NarrativeLoader.load(String id)`(`data/narrative_loader.dart`)扫 `data/narratives/<id>.yaml`。
- `NumbersConfig` 子配置模式(`numbers_config.dart`):class+`fromYaml`,字段声明+构造 required+`NumbersConfig.fromYaml` 内 `x: XConfig.fromYaml(y['key'] as Map<String,dynamic>?)`(参照 innerDemon line 367)。
- isar 迁移 `_migrateSaveData`(`isar_setup.dart:176`)+ `_compareVersion`(line 248)+ `_currentSaveVersion='0.24.0'`(line 121)。

---

## Group 1 — ③ 角色基座(枚举 + 数据 + 迁移)

### Task 1: LineageRole 加 senior/junior + masters.yaml 驱动

**Files:**
- Modify: `lib/core/domain/enums.dart:160-164`
- Modify: `data/masters.yaml:34,55`
- Test: `test/data/master_def_test.dart`(若无则新建)

- [ ] **Step 1: 写失败测试**

```dart
// test/data/master_def_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/master_def.dart';

void main() {
  test('MasterDef 解析 senior/junior 子枚举', () {
    final senior = MasterDef.fromYaml({
      'id': 't_senior', 'lineageRole': 'senior', 'slotIndex': 1,
      'defaultRealm': 'xueTu', 'defaultLayer': 'qiMeng',
      'attributeProfile': {'constitution': 5, 'enlightenment': 5, 'agility': 5, 'fortune': 5},
    });
    expect(senior.lineageRole, LineageRole.senior);
    final junior = MasterDef.fromYaml({
      'id': 't_junior', 'lineageRole': 'junior', 'slotIndex': 2,
      'defaultRealm': 'xueTu', 'defaultLayer': 'qiMeng',
      'attributeProfile': {'constitution': 5, 'enlightenment': 5, 'agility': 5, 'fortune': 5},
    });
    expect(junior.lineageRole, LineageRole.junior);
  });

  test('LineageRole 保留 disciple 值供老档反序列化', () {
    expect(LineageRole.values.byName('disciple'), LineageRole.disciple);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/master_def_test.dart`
Expected: FAIL（`senior` not a valid LineageRole name → byName 抛 ArgumentError）

- [ ] **Step 3: 改 enum(保留 disciple)**

```dart
// lib/core/domain/enums.dart — 替换 LineageRole 定义
/// 师徒角色定位（GDD §7.1）。
/// senior=大弟子 / junior=二弟子（第七阶段批三:开局渐进解锁 + 战斗职责三分）。
/// disciple 值保留:老档(0.25.0 前)反序列化安全,迁移后按 founder.discipleIds 顺序
/// 重映射为 senior/junior;通过收徒系统新增的通用弟子仍可为 disciple。
enum LineageRole {
  founder,        // 开派祖师（玩家本体）
  disciple,       // 弟子（通用/老档过渡值）
  senior,         // 大弟子（批三:破防开窗职责）
  junior,         // 二弟子（批三:破招打断控场职责）
  grandDisciple,  // 徒孙（绝顶境界后解锁）
}
```

- [ ] **Step 4: 改 masters.yaml(slot1→senior / slot2→junior)**

`data/masters.yaml`:把 `first_disciple` 段(line 34)`lineageRole: disciple` 改 `lineageRole: senior`;`second_disciple` 段(line 55)`lineageRole: disciple` 改 `lineageRole: junior`。founder 不动。

- [ ] **Step 5: build_runner 重生成(enum 进 Character @Enumerated)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 成功,`character.g.dart` 更新 enum 映射含 senior/junior。

- [ ] **Step 6: 跑测试 + 全量回归**

Run: `flutter test test/data/master_def_test.dart && flutter analyze`
Expected: PASS / analyze 0。

- [ ] **Step 7: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): LineageRole 加 senior/junior + masters.yaml 驱动大/二弟子"
```

---

### Task 2: SaveData.triggeredDiscipleJoinStageIds 字段

**Files:**
- Modify: `lib/core/domain/save_data.dart`(尾部加字段)
- Test: `test/data/isar_setup_test.dart`(追加 case)或 `test/core/domain/save_data_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/domain/save_data_join_field_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('SaveData.triggeredDiscipleJoinStageIds 默认空 + 可追加', () {
    final s = SaveData();
    expect(s.triggeredDiscipleJoinStageIds, isEmpty);
    s.triggeredDiscipleJoinStageIds = [...s.triggeredDiscipleJoinStageIds, 'stage_01_02'];
    expect(s.triggeredDiscipleJoinStageIds, ['stage_01_02']);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/domain/save_data_join_field_test.dart`
Expected: FAIL（getter 不存在）

- [ ] **Step 3: 加字段**

```dart
// lib/core/domain/save_data.dart — 在 triggeredBossRecruitStageIds(line 74)之后加:
  /// 已触发命名弟子拜入的 stage id（第七阶段批三 · 渐进解锁防重）。
  ///
  /// 沿 [triggeredBossRecruitStageIds] 一次性防重模式:过 join 触发关后
  /// `runDiscipleJoinHookAfterVictory` 创建弟子并 add 本字段,重战不再触发。
  /// 0.24→0.25 迁移:老档(满队)预填全部 join stage id(弟子已在,不重建)。
  List<String> triggeredDiscipleJoinStageIds = [];
```

- [ ] **Step 4: build_runner(SaveData @collection)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `save_data.g.dart` 含新字段读写。

- [ ] **Step 5: 跑测试**

Run: `flutter test test/core/domain/save_data_join_field_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): SaveData 加 triggeredDiscipleJoinStageIds 防重字段"
```

---

### Task 3: numbers.yaml 拜入触发表 + LineageOnboardingConfig

**Files:**
- Modify: `data/numbers.yaml`(加 `lineage_onboarding:`)
- Modify: `lib/data/numbers_config.dart`(加 config 类 + 字段 + 解析)
- Test: `test/data/lineage_onboarding_config_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/data/lineage_onboarding_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('LineageOnboardingConfig 解析 2 个拜入触发(01_02→senior / 01_04→junior)', () {
    final cfg = LineageOnboardingConfig.fromYaml({
      'disciple_joins': [
        {'stage_id': 'stage_01_02', 'master_slot_index': 1, 'role': 'senior'},
        {'stage_id': 'stage_01_04', 'master_slot_index': 2, 'role': 'junior'},
      ],
    });
    expect(cfg.discipleJoins.length, 2);
    expect(cfg.discipleJoins[0].stageId, 'stage_01_02');
    expect(cfg.discipleJoins[0].masterSlotIndex, 1);
    expect(cfg.discipleJoins[0].role, LineageRole.senior);
    expect(cfg.discipleJoins[1].role, LineageRole.junior);
    expect(cfg.joinStageIds, {'stage_01_02', 'stage_01_04'});
  });

  test('null yaml → 空配置(default-safe)', () {
    final cfg = LineageOnboardingConfig.fromYaml(null);
    expect(cfg.discipleJoins, isEmpty);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/lineage_onboarding_config_test.dart`
Expected: FAIL（`LineageOnboardingConfig` 未定义）

- [ ] **Step 3: 加 config 类(numbers_config.dart 文件尾部加)**

```dart
// lib/data/numbers_config.dart — 文件尾部新增:
/// 第七阶段批三·队伍成长:命名弟子拜入触发表。
class DiscipleJoinDef {
  final String stageId;
  final int masterSlotIndex; // masters.yaml slotIndex(1=大弟子/2=二弟子)
  final LineageRole role;
  const DiscipleJoinDef({
    required this.stageId,
    required this.masterSlotIndex,
    required this.role,
  });
  factory DiscipleJoinDef.fromYaml(Map<String, dynamic> y) => DiscipleJoinDef(
        stageId: y['stage_id'] as String,
        masterSlotIndex: (y['master_slot_index'] as num).toInt(),
        role: LineageRole.values.byName(y['role'] as String),
      );
}

class LineageOnboardingConfig {
  final List<DiscipleJoinDef> discipleJoins;
  const LineageOnboardingConfig({this.discipleJoins = const []});
  Set<String> get joinStageIds => discipleJoins.map((j) => j.stageId).toSet();
  factory LineageOnboardingConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return const LineageOnboardingConfig();
    final raw = (y['disciple_joins'] as List?) ?? const [];
    return LineageOnboardingConfig(
      discipleJoins: raw
          .map((e) => DiscipleJoinDef.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}
```

- [ ] **Step 4: 接入 NumbersConfig(字段 + 构造 + 解析)**

```dart
// numbers_config.dart class NumbersConfig:
//   字段声明区(参照 line 152 innerDemon 体例)加:
  final LineageOnboardingConfig lineageOnboarding;
//   构造 required 区(参照 line 254)加:
    required this.lineageOnboarding,
//   NumbersConfig.fromYaml 内(参照 line 367 innerDemon)加:
      lineageOnboarding: LineageOnboardingConfig.fromYaml(
        y['lineage_onboarding'] as Map<String, dynamic>?,
      ),
```

- [ ] **Step 5: 加 numbers.yaml 配置**

```yaml
# data/numbers.yaml — 文件中任意顶层位置加:
# 第七阶段批三·队伍成长:开局单人,命名弟子按主线关卡节点拜入。
lineage_onboarding:
  disciple_joins:
    - stage_id: stage_01_02   # 过荒山野店 → 大弟子拜入(2 人)
      master_slot_index: 1
      role: senior
    - stage_id: stage_01_04   # 过洛阳城外小Boss → 二弟子拜入(满队迎章末Boss)
      master_slot_index: 2
      role: junior
```

- [ ] **Step 6: 跑测试 + 全量(确认 numbers.yaml 真实加载不崩)**

Run: `flutter test test/data/lineage_onboarding_config_test.dart && flutter test test/data/ && flutter analyze`
Expected: PASS / analyze 0（真实 GameRepository 加载 numbers.yaml 含新键不报错）。

- [ ] **Step 7: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): numbers.yaml 拜入触发表 + LineageOnboardingConfig 解析"
```

---

### Task 4: 存档迁移 0.24→0.25(角色重映射 + 预填防重)

**Files:**
- Modify: `lib/data/isar_setup.dart`(saveVer + `_migrateSaveData` 加段)
- Test: `test/data/isar_setup_test.dart`(追加 case)

- [ ] **Step 1: 写失败测试**

```dart
// test/data/isar_setup_migration_lineage_test.dart
// 用真实 Isar(临时目录)建 0.24.0 老档:founder(id=1) + 2 disciple(id 2,3,lineageRole=disciple)
// founder.discipleIds=[2,3] + activeCharacterIds=[1,2,3] + triggeredDiscipleJoinStageIds 空。
// 触发 IsarSetup.init(走 _ensureSaveData → _migrateSaveData)。
// 断言:① 弟子 role 重映射 id2→senior / id3→junior;
//       ② triggeredDiscipleJoinStageIds 预填 {stage_01_02, stage_01_04};
//       ③ saveVersion == '0.25.0';④ activeCharacterIds 不变(弟子原地不动)。
// (体例参照现有 isar_setup_test.dart 周目迁移 case + GameRepository.loadAllDefs 先加载。)
```

> 实装时:参照 `test/data/isar_setup_test.dart` 既有迁移测的临时目录 + GameRepository 加载 setup,手建 0.24.0 fixture。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/isar_setup_migration_lineage_test.dart`
Expected: FAIL（弟子仍为 disciple / version 仍 0.24.0）

- [ ] **Step 3: 升版本号 + 加迁移段**

```dart
// isar_setup.dart line 121:
  static const _currentSaveVersion = '0.25.0';
// 顶部注释追加一行说明 0.25.0 迁移内容。
```

```dart
// _migrateSaveData(...) writeTxn 内,段 2 之后、save.saveVersion 赋值之前,加段 4:
      // --- 段 4(0.25.0 队伍成长):命名弟子 role 重映射 + 拜入防重预填 ---
      // 老档(<0.25.0)均由旧 onboarding 种满队,故:
      //   a) founder.discipleIds 顺序前2位 disciple → senior/junior(通用收徒弟子不动);
      //   b) 预填全部 join stage id(弟子已在,hook 不再触发、不重建)。
      if (_compareVersion(fromVersion, '0.25.0') < 0) {
        final allChars = await isar.characters.where().findAll();
        Character? founder;
        for (final c in allChars) {
          if (c.isFounder) { founder = c; break; }
        }
        if (founder != null) {
          for (var i = 0; i < founder.discipleIds.length && i < 2; i++) {
            final d = await isar.characters.get(founder.discipleIds[i]);
            if (d == null || d.lineageRole != LineageRole.disciple) continue;
            d.lineageRole = i == 0 ? LineageRole.senior : LineageRole.junior;
            await isar.characters.put(d);
          }
        }
        if (GameRepository.isLoaded) {
          final joinIds = GameRepository.instance.numbers.lineageOnboarding.joinStageIds;
          final cur = List<String>.of(save.triggeredDiscipleJoinStageIds);
          for (final id in joinIds) {
            if (!cur.contains(id)) cur.add(id);
          }
          save.triggeredDiscipleJoinStageIds = cur;
        }
      }
```

- [ ] **Step 4: 跑测试 + 全量迁移测**

Run: `flutter test test/data/isar_setup_migration_lineage_test.dart && flutter test test/data/isar_setup_test.dart`
Expected: PASS（含既有 0.21/0.22/0.24 迁移不回归）

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): 存档 0.25.0 迁移 — 弟子 role 重映射 + 拜入防重预填"
```

---

## Group 2 — ① 单人开局 + 拜入服务

### Task 5: onboarding 单人种子(soloStart 参数隔离)

**Files:**
- Modify: `lib/features/onboarding/application/onboarding_service.dart`
- Modify: `lib/features/debug/application/phase2_seed_service.dart:1203`(传 `soloStart: false`)
- Modify: `lib/features/debug/presentation/visual_route_host.dart:150,174,191,196`(传 `soloStart: false`)
- Test: `test/features/onboarding/application/onboarding_service_test.dart`(更新)

- [ ] **Step 1: 写失败测试**

```dart
// onboarding_service_test.dart 追加/更新:
test('生产默认 soloStart=true → 只种祖师单人出战', () async {
  final svc = OnboardingService(isar: isar);
  final seeded = await svc.ensureFoundingMasters();
  expect(seeded, true);
  final save = await isar.saveDatas.get(0);
  expect(save!.activeCharacterIds, [1]); // 仅祖师
  final chars = await isar.characters.where().findAll();
  expect(chars.length, 1);
  expect(chars.first.isFounder, true);
  expect(chars.first.discipleIds, isEmpty);
});

test('debug soloStart=false → 满队 3 人(回归既有行为)', () async {
  final svc = OnboardingService(isar: isar);
  await svc.ensureFoundingMasters(soloStart: false);
  final save = await isar.saveDatas.get(0);
  expect(save!.activeCharacterIds, [1, 2, 3]);
  expect((await isar.characters.where().findAll()).length, 3);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/onboarding/application/onboarding_service_test.dart`
Expected: FAIL（默认仍种 3 / 无 soloStart 参数）

- [ ] **Step 3: 改 ensureFoundingMasters 加 soloStart 分支**

```dart
// onboarding_service.dart — 方法签名改:
  Future<bool> ensureFoundingMasters({bool soloStart = true}) async {
// existing founder 短路不变。writeTxn 内:
//   soloStart=true:只 put 祖师(founder id=1),不建弟子;
//     founder.discipleIds=[];activeCharacterIds=[founder.id];
//     装备/心法只对 founder 跑;物料不变。
//   soloStart=false:原 3 角色全流程(保留既有代码路径)。
```

具体改法:把现有 writeTxn 体抽成两路。soloStart 路径:

```dart
    await isar.writeTxn(() async {
      final founder = buildMasterCharacter(masters[0], now: now)..id = 1;
      await isar.characters.put(founder);

      final List<Character> seeded;
      if (soloStart) {
        founder.discipleIds = [];
        seeded = [founder];
      } else {
        final firstDisciple = buildMasterCharacter(masters[1], now: now);
        await isar.characters.put(firstDisciple);
        final secondDisciple = buildMasterCharacter(masters[2], now: now);
        await isar.characters.put(secondDisciple);
        founder.discipleIds = [firstDisciple.id, secondDisciple.id];
        firstDisciple.masterId = founder.id;
        secondDisciple.masterId = founder.id;
        seeded = [founder, firstDisciple, secondDisciple];
      }

      final defs = soloStart ? [masters[0]] : [masters[0], masters[1], masters[2]];
      for (var i = 0; i < seeded.length; i++) {
        await equipMasterStarting(isar, character: seeded[i],
            defIds: defs[i].startingEquipmentIds, rng: rng, now: now);
        await learnMasterStarting(isar, character: seeded[i],
            techDefIds: defs[i].startingTechniqueIds, now: now);
      }
      await isar.characters.putAll(seeded);

      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.activeCharacterIds = seeded.map((c) => c.id).toList();
        save.founderCharacterId = founder.id;
        save.sectName ??= UiStrings.defaultSectName;
        await isar.saveDatas.put(save);
      }
      await seedBasicMaterials(isar,
          mojianshi: _starterMojianshi, jieJing: _starterJieJing, at: now);
    });
    return true;
```

- [ ] **Step 4: debug caller 传 soloStart:false**

`phase2_seed_service.dart:1203` → `ensureFoundingMasters(soloStart: false)`;`visual_route_host.dart` 4 处(150/174/191/196)同改。(debug 视觉/种子要满队。)

- [ ] **Step 5: 跑全量(暴露依赖满队的测试)**

Run: `flutter test && flutter analyze`
Expected: onboarding_service_test PASS。**若有其它测试因调 ensureFoundingMasters 默认满队而挂** → 该测试若要满队则传 `soloStart: false`,若测单人则更新断言。逐一修到全绿。analyze 0。

- [ ] **Step 6: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): 生产 onboarding 改单人开局(soloStart 参数隔离,debug 保满队)"
```

---

### Task 6: DiscipleJoinService 懒创建拜入

**Files:**
- Create: `lib/features/lineage/application/disciple_join_service.dart`
- Test: `test/features/lineage/application/disciple_join_service_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// disciple_join_service_test.dart(真实 Isar + GameRepository 加载)
// 前置:soloStart 种子(只 founder id=1)。
test('过 join 关 → 懒创建 senior 弟子并入队 + 防重', () async {
  final svc = DiscipleJoinService(isar: isar);
  final joined = await svc.joinForClearedStage('stage_01_02');
  expect(joined, isNotNull);
  expect(joined!.lineageRole, LineageRole.senior);
  expect(joined.isActive, true);
  final save = await isar.saveDatas.get(0);
  expect(save!.activeCharacterIds.contains(joined.id), true);
  expect(save.triggeredDiscipleJoinStageIds.contains('stage_01_02'), true);
  final founder = await isar.characters.get(1);
  expect(founder!.discipleIds.contains(joined.id), true);

  // 幂等:重战同关不再创建
  final again = await svc.joinForClearedStage('stage_01_02');
  expect(again, isNull);
  expect((await isar.characters.where().findAll()).length, 2); // 仍 founder+1
});

test('非 join 关 → null 无副作用', () async {
  final svc = DiscipleJoinService(isar: isar);
  expect(await svc.joinForClearedStage('stage_01_01'), isNull);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/lineage/application/disciple_join_service_test.dart`
Expected: FAIL（类不存在）

- [ ] **Step 3: 实装 service**

```dart
// lib/features/lineage/application/disciple_join_service.dart
import 'package:isar_community/isar.dart';
import '../../../core/domain/character.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../onboarding/application/master_builder.dart';

/// 第七阶段批三·渐进解锁:过 join 触发关后懒创建对应命名弟子并入队。
/// 防重走 SaveData.triggeredDiscipleJoinStageIds(一次性,重战不再触发)。
class DiscipleJoinService {
  DiscipleJoinService({required this.isar});
  final Isar isar;

  /// 若 [clearedStageId] 是某弟子拜入触发关且未触发过,懒创建弟子并入队,
  /// 返回新弟子;否则返回 null。
  Future<Character?> joinForClearedStage(String clearedStageId, {DateTime? at}) async {
    final repo = GameRepository.instance;
    final cfg = repo.numbers.lineageOnboarding;
    DiscipleJoinDef? join;
    for (final j in cfg.discipleJoins) {
      if (j.stageId == clearedStageId) { join = j; break; }
    }
    if (join == null) return null;

    final save = await isar.saveDatas.get(0);
    if (save == null) return null;
    if (save.triggeredDiscipleJoinStageIds.contains(clearedStageId)) return null;

    final masters = repo.masters;
    if (join.masterSlotIndex >= masters.length) return null;
    final def = masters[join.masterSlotIndex];
    final now = at ?? DateTime.now();
    final rng = DefaultRng();

    Character? created;
    await isar.writeTxn(() async {
      final disciple = buildMasterCharacter(def, now: now); // lineageRole 来自 masters.yaml(senior/junior)
      await isar.characters.put(disciple);
      await equipMasterStarting(isar, character: disciple,
          defIds: def.startingEquipmentIds, rng: rng, now: now);
      await learnMasterStarting(isar, character: disciple,
          techDefIds: def.startingTechniqueIds, now: now);

      final founderId = save.founderCharacterId;
      if (founderId != null) {
        disciple.masterId = founderId;
        final founder = await isar.characters.get(founderId);
        if (founder != null) {
          founder.discipleIds = [...founder.discipleIds, disciple.id];
          await isar.characters.put(founder);
        }
      }
      await isar.characters.put(disciple);

      save.activeCharacterIds = [...save.activeCharacterIds, disciple.id];
      save.triggeredDiscipleJoinStageIds =
          [...save.triggeredDiscipleJoinStageIds, clearedStageId];
      await isar.saveDatas.put(save);
      created = disciple;
    });
    return created;
  }
}
```

- [ ] **Step 4: 跑测试 + 全量**

Run: `flutter test test/features/lineage/ && flutter analyze`
Expected: PASS / analyze 0。

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): DiscipleJoinService 懒创建命名弟子入队 + 防重"
```

---

## Group 3 — ④ 拜入仪式 + victory 接线

### Task 7: 拜师 narrative 内容 + UiStrings 题字

**Files:**
- Create: `data/narratives/lineage_first_disciple_join.yaml`
- Create: `data/narratives/lineage_second_disciple_join.yaml`
- Modify: `lib/shared/strings.dart`(加题字词条)
- Test: `test/data/lineage_join_narrative_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/data/lineage_join_narrative_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('拜师 narrative 可加载', () async {
    final first = await NarrativeLoader.load('lineage_first_disciple_join');
    expect(first.paragraphs, isNotEmpty);
    final second = await NarrativeLoader.load('lineage_second_disciple_join');
    expect(second.paragraphs, isNotEmpty);
  });

  test('UiStrings 拜入题字存在', () {
    expect(UiStrings.discipleJoinCaption('大弟子'), contains('大弟子'));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/lineage_join_narrative_test.dart`
Expected: FAIL（文件缺 / UiStrings 无方法）

- [ ] **Step 3: 写 2 段 narrative(体例参照 data/narratives/stages/stage_02_05_boss_recruit.yaml)**

```yaml
# data/narratives/lineage_first_disciple_join.yaml
id: lineage_first_disciple_join
title: 收徒 · 大弟子
paragraphs:
  - 荒山野店外,少年挡在你身前,挨了那一记本该落在你肩上的拳。
  - 「师父教过的招,我只会这一手。」他咧嘴笑,门牙磕出了血。
  - 你看着他握刀的手——虎口磨出的茧,是日复一日劈出来的。
  - 「往后,这江湖路,我陪你走。」
```

```yaml
# data/narratives/lineage_second_disciple_join.yaml
id: lineage_second_disciple_join
title: 收徒 · 二弟子
paragraphs:
  - 洛阳城外的尘土里,那身影一直缀在你们身后,不近不远。
  - 直到城兵围上来,他才出手——快得只见残影,一招便卸了为首者的腕。
  - 「我没师承,只在墙角偷看过你出剑。」他低着头,声音发紧。
  - 你把手按在他肩上。三人成众,这条路,从今日起不再是孤身。
```

- [ ] **Step 4: 加 UiStrings 题字**

```dart
// lib/shared/strings.dart — UiStrings 内加(集中式 sink,§5.6 合法):
  /// 弟子拜入英雄镜头题字(第七阶段批三)。[name]=弟子名(大弟子/二弟子)。
  static String discipleJoinCaption(String name) => '$name 拜入门下';
```

- [ ] **Step 5: 跑测试**

Run: `flutter test test/data/lineage_join_narrative_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): 大/二弟子拜师 narrative + UiStrings 拜入题字"
```

---

### Task 8: 拜入 hook 接线 victory 流程(仪式)

**Files:**
- Create: `lib/features/lineage/presentation/disciple_join_hook.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`(victory 段加调用)
- Test: `test/features/lineage/presentation/disciple_join_hook_test.dart`

> **设计:** hook = 薄编排。先 `DiscipleJoinService.joinForClearedStage(stage.id)`,返回非 null 弟子时:① push 对应拜师 NarrativeReaderScreen;② `presentHeroCamera` 立绘切入(用弟子 portraitPath/name/realm + 题字)。返回 null(非 join 关/已触发)直接 no-op。hero camera 用 `HeroCameraData`,但 bossName/topDamage 字段不适用拜入语义 → 复用 `presentHeroCamera`,以弟子名入镜(题字走 `UiStrings.discipleJoinCaption`);若 HeroCameraData 字段语义不契合,本 task 实装时改用直接 `HeroCameraOverlay` 或简化为 narrative + 题字 overlay(实装者按 victory_ceremony.dart 现状择优,保持「立绘 + 题字」即可)。

- [ ] **Step 1: 写失败测试(逻辑层 — hook gate 决策)**

```dart
// disciple_join_hook_test.dart:验证 hook 的「是否触发拜入」决策走 service 真值。
// 用 soloStart 种子 + 真实 isar,不渲染 UI:测一个可注入的纯逻辑入口
// `shouldPresentJoin(stageId)` 或直接断言 joinForClearedStage 被正确 gate。
// (UI push 用 widget 测覆盖 gate=true 分支,见 Step 3 的 @visibleForTesting seam。)
test('非主线/非 join 关 → hook 不触发拜入', () async {
  final svc = DiscipleJoinService(isar: isar);
  expect(await svc.joinForClearedStage('stage_03_01'), isNull);
});
```

- [ ] **Step 2: 跑测试确认失败/通过基线**

Run: `flutter test test/features/lineage/`
Expected: 现有 service 测 PASS;hook 文件尚未建。

- [ ] **Step 3: 实装 hook + 接线**

```dart
// lib/features/lineage/presentation/disciple_join_hook.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/isar_setup.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../battle/presentation/victory_ceremony.dart' show presentHeroCamera;
import '../../battle/presentation/hero_camera_overlay.dart' show HeroCameraData;
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../application/disciple_join_service.dart';

/// 第七阶段批三:过 join 触发关后弹拜师叙事 + 立绘英雄镜头。
/// 仅主线关 + 命中 lineage_onboarding.disciple_joins 才触发(service 内 gate)。
Future<void> runDiscipleJoinHookAfterVictory({
  required BuildContext context,
  required WidgetRef ref,
  required String stageId,
}) async {
  final svc = DiscipleJoinService(isar: IsarSetup.instance);
  final joined = await svc.joinForClearedStage(stageId);
  if (joined == null) return;
  if (!context.mounted) return;

  // 拜师叙事
  final narrativeId = stageId == GameRepository.instance.numbers.lineageOnboarding
          .discipleJoins.first.stageId
      ? 'lineage_first_disciple_join'
      : 'lineage_second_disciple_join';
  final content = await NarrativeLoader.load(narrativeId);
  if (context.mounted) {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => NarrativeReaderScreen(
        content: content,
        fallbackTitle: UiStrings.discipleJoinCaption(joined.name),
      ),
    ));
  }
  // 立绘英雄镜头(题字=拜入)
  if (context.mounted) {
    await presentHeroCamera(context, HeroCameraData(
      portraitPath: joined.portraitPath,
      heroName: joined.name,
      realmLabel: EnumL10n.realmTier(joined.realmTier),
      bossName: '',
      topDamage: 0,
    ));
  }
}
```

```dart
// stage_entry_flow.dart victory 段:在 encounter hook(line 277-282)之后、
// runStageBossRecruitHookAfterVictory(line 288)之前插:
      if (context.mounted) {
        await runDiscipleJoinHookAfterVictory(
          context: context, ref: ref, stageId: stage.id);
      }
```

> 注:`HeroCameraOverlay` 若对 `bossName`/`topDamage` 有强渲染依赖(显「最高伤害」行),实装者改用「立绘 + `discipleJoinCaption` 题字」的最小 overlay 或给 HeroCameraData 加可选「拜入模式」分支,**不显伤害数字**(拜入无战斗语义)。保持纯表现层,不写 BattleState。

- [ ] **Step 4: widget 测覆盖 gate=true(立绘/叙事渲染不崩)**

```dart
// 用 pumpWidget + soloStart 种子 + 触发 runDiscipleJoinHookAfterVictory('stage_01_02'),
// 断言:弟子被 join(isar 校验)+ NarrativeReaderScreen 出现(find.byType)。
// (沿批一 hero_camera widget 测体例;errorBuilder 保立绘缺图不破布局。)
```

- [ ] **Step 5: 跑全量 + analyze**

Run: `flutter test && flutter analyze`
Expected: PASS / analyze 0。

- [ ] **Step 6: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): 拜入 hook 接线 victory 流程(拜师叙事 + 立绘英雄镜头)"
```

---

## Group 4 — ③ 战斗职责差异

### Task 9: autoFill 破防倾向 disciple→senior

**Files:**
- Modify: `lib/features/cultivation/domain/skill_loadout.dart:97`
- Test: `test/features/cultivation/skill_loadout_test.dart`(追加 senior/junior case)

- [ ] **Step 1: 写失败测试**

```dart
// 构造含破防技(defenseBreakPct>0)与普通强力技的 mainTechniqueSkills:
test('senior → 破防技进主修槽;junior 不强加破防;founder 不变', () {
  final skills = [normalPower, breakSkill]; // breakSkill.defenseBreakPct>0
  final asSenior = SkillLoadout.autoFill(/* ... */ lineageRole: LineageRole.senior, isFounder: false, existing: const SkillLoadout());
  expect([asSenior.mainSkillId1, asSenior.mainSkillId2], contains(breakSkill.id));

  final asJunior = SkillLoadout.autoFill(/* ... */ lineageRole: LineageRole.junior, isFounder: false, existing: const SkillLoadout());
  // junior 不触发破防替换 → 仍按 power 降序(breakSkill 若 power 低则可能不在槽)
  // 断言 junior 不因身份强插破防(行为 == 无身份默认)。
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/cultivation/skill_loadout_test.dart`
Expected: FAIL（当前 junior 会走 disciple 分支?不会 — junior!=disciple,但断言 senior 触发破防会失败因条件是 disciple）

- [ ] **Step 3: 改条件 disciple→senior**

```dart
// skill_loadout.dart:97 — 把:
    if (lineageRole == LineageRole.disciple && !isFounder) {
// 改成:
    if (lineageRole == LineageRole.senior && !isFounder) {
// 注释同步更新:第六阶段 disciple → 第七阶段批三 senior(大弟子破防开窗);
// junior(二弟子)走破招控场(battle_ai),不在 autoFill 强插破防。
```

- [ ] **Step 4: 跑测试 + 全量**

Run: `flutter test test/features/cultivation/ && flutter analyze`
Expected: PASS / analyze 0。

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): autoFill 破防倾向收窄到 senior(大弟子);junior 走破招控场"
```

---

### Task 10: BattleCharacter 透传 lineageRole

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`(字段 + 构造 + fromCharacter + copyWith)
- Test: `test/features/battle/battle_character_lineage_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('fromCharacter 透传 lineageRole;敌人路径默认 null', () {
  // 用 junior Character → fromCharacter → expect bc.lineageRole == LineageRole.junior
  // _enemyToBattle / 直接构造默认 → null
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/battle_character_lineage_test.dart`
Expected: FAIL（无 lineageRole getter）

- [ ] **Step 3: 加字段(default-safe nullable)**

```dart
// battle_state.dart BattleCharacter:
//   import enums.dart 已在。字段区(schoolDamageTakenMult 后)加:
  /// 第七阶段批三:角色师徒定位(玩家方透传 Character.lineageRole;敌人/NPC 恒 null)。
  /// battle_ai 据此给 junior(二弟子)「优先盯蓄力敌」控场目标偏好。default null=无差异。
  final LineageRole? lineageRole;
//   构造器尾部(schoolDamageTakenMult 后)加:
    this.lineageRole,
//   fromCharacter(line 264)内构造 BattleCharacter 处加:
//     lineageRole: character.lineageRole,
//   copyWith(~line 490)加形参 + 透传:
//     LineageRole? lineageRole,  ...  lineageRole: lineageRole ?? this.lineageRole,
```

> fromCharacter 末尾 `return BattleCharacter(...)` 加 `lineageRole: character.lineageRole,`。`_enemyToBattle`(stage_battle_setup)不传 → null。

- [ ] **Step 4: 跑测试 + 全量**

Run: `flutter test test/features/battle/ && flutter analyze`
Expected: PASS / analyze 0（copyWith 既有 caller 不回归）。

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): BattleCharacter 透传 lineageRole(default-safe)"
```

---

### Task 11: battle_ai junior 控场目标偏好

**Files:**
- Modify: `lib/features/battle/domain/battle_ai.dart`(decide 加 junior 分支 + `_pickControlTargetId`)
- Test: `test/features/battle/battle_ai_junior_control_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// 构造:敌方有一个 chargingSkill!=null 的蓄力敌(非血最低)+ 一个血最低的普通敌。
test('junior 不用破招技时优先盯蓄力敌(控场);非 junior 走血最低', () {
  // junior actor + 用普攻(canInterrupt=false):
  final (_, jTargets) = BattleAI.decide(juniorActor, state, n);
  expect(jTargets.first, chargingEnemy.characterId);
  // founder/senior 同局面 → 血最低敌
  final (_, fTargets) = BattleAI.decide(founderActor, state, n);
  expect(fTargets.first, lowestHpEnemy.characterId);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/battle_ai_junior_control_test.dart`
Expected: FAIL（junior 当前走 _pickFocusTargetId ?? _pickTargetId → 血最低）

- [ ] **Step 3: 加 junior 分支 + helper**

```dart
// battle_ai.dart decide() — 把 line 67-73 的 else-if 级联改成:
    } else if (_currentBossAiMode(actor) == BossAiMode.focus) {
      targetId = _pickTargetId(actor, state);
    } else if (actor.lineageRole == LineageRole.junior) {
      // 第七阶段批三:二弟子控场 — 不用破招技这一拍时,优先盯正在蓄力的敌(压制要放大招的威胁),
      // 无蓄力敌回落破绽窗口 → 血最低。纯目标选择,不改伤害量级(§5.4)。
      targetId = _pickControlTargetId(actor, state)
          ?? _pickFocusTargetId(actor, state)
          ?? _pickTargetId(actor, state);
    } else {
      targetId = _pickFocusTargetId(actor, state) ?? _pickTargetId(actor, state);
    }
```

```dart
// battle_ai.dart — _pickFocusTargetId 之后加:
  /// 第七阶段批三:二弟子控场目标 — 对面正在蓄力(chargingSkill!=null)的活角色中
  /// chargeTicksRemaining 最小(最快要放)优先,同则 slotIndex 小;无蓄力敌返 null。纯函数。
  static int? _pickControlTargetId(BattleCharacter actor, BattleState state) {
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    BattleCharacter? best;
    for (final e in enemyTeam) {
      if (!e.isAlive || e.chargingSkill == null) continue;
      if (best == null ||
          e.chargeTicksRemaining < best.chargeTicksRemaining ||
          (e.chargeTicksRemaining == best.chargeTicksRemaining &&
              e.slotIndex < best.slotIndex)) {
        best = e;
      }
    }
    return best?.characterId;
  }
```

- [ ] **Step 4: 跑测试 + 全量**

Run: `flutter test test/features/battle/ && flutter analyze`
Expected: PASS / analyze 0（senior/founder/敌人 lineageRole 非 junior → 走原路径,零回归）。

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(lineage): battle_ai 二弟子控场目标偏好(优先盯蓄力敌)"
```

---

## Group 5 — 红线 + 集成

### Task 12: 渐进解锁 e2e + 红线守卫

**Files:**
- Test: `test/features/lineage/team_growth_e2e_test.dart`
- Test: `test/balance/`(确认 ③ 不抬伤害量级 — 复用既有红线测,不新增数值断言)

- [ ] **Step 1: 写 e2e 测试**

```dart
// team_growth_e2e_test.dart(真实 isar + GameRepository)
test('单人开局 → 过 01_02 → 2 人 → 过 01_04 → 满队 3 人', () async {
  await OnboardingService(isar: isar).ensureFoundingMasters(); // solo
  expect((await isar.saveDatas.get(0))!.activeCharacterIds.length, 1);

  final svc = DiscipleJoinService(isar: isar);
  final s1 = await svc.joinForClearedStage('stage_01_02');
  expect(s1!.lineageRole, LineageRole.senior);
  expect((await isar.saveDatas.get(0))!.activeCharacterIds.length, 2);

  final s2 = await svc.joinForClearedStage('stage_01_04');
  expect(s2!.lineageRole, LineageRole.junior);
  final save = await isar.saveDatas.get(0);
  expect(save!.activeCharacterIds.length, 3);
  expect(save.triggeredDiscipleJoinStageIds, containsAll(['stage_01_02', 'stage_01_04']));
});
```

- [ ] **Step 2: 跑 e2e**

Run: `flutter test test/features/lineage/team_growth_e2e_test.dart`
Expected: PASS

- [ ] **Step 3: 全量 + analyze 收口**

Run: `flutter test && flutter analyze`
Expected: **全绿**(基线 2566 + 本批新增测,零回归)/ analyze 0。**贴最后 5 行输出到 commit/PROGRESS。**

- [ ] **Step 4: 红线自检(人工核对,不写死数值)**

确认:① 无任何属性 buff 新增(§5.4);② junior 目标偏好只改打谁、不改伤害公式/量级;③ 弟子走确定性剧本非抽卡(§5.1);④ 文案全进 data/narratives + UiStrings(§5.6);⑤ 离线挂机用 activeCharacterIds 照常,单人不破(§5.5);⑥ 跑 `check-redlines` skill(读 GDD §5.4 + 16 红线测全绿)。

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add -A
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "test(lineage): 队伍成长 e2e + 红线收口"
```

---

## 收尾(全部 task 后)

- [ ] 跑全量 `flutter test` 贴最后输出 + `flutter analyze` 0,记真实测数到 PROGRESS。
- [ ] worktree commit 全部 → 主 checkout `git rebase main` 后 ff-merge(本地未 push commit 需先在 worktree 提交,见 `feedback_bg_worktree_baseref_fresh_diverge`)。
- [ ] **视觉验收待真机**:单人开局战斗 / 大弟子拜入立绘+题字 / 二弟子拜入(动效单帧截不出)→ `flutter run -d macos` 打 stage_01_02、01_04 目检;静态可截部分(拜师 narrative 排版)Claude 自截。
- [ ] PROGRESS 续29 + session 记录 + 更新 backlog(批三完成,「做2+3」三批全闭环)。

## 自检对照 spec

| spec 要求 | 覆盖 task |
|---|---|
| ① 单人开局 | T5 |
| ① 拜入触发(01_02/01_04) | T3(配置)+T6(服务)+T8(接线) |
| ③ senior/junior 枚举 | T1 |
| ③ autoFill senior→破防 | T9 |
| ③ junior 破招控场 | T10+T11 |
| ④ 拜师叙事+英雄镜头 | T7+T8 |
| D 存档迁移 0.25 | T2(字段)+T4(迁移) |
| E 内容(narrative/UiStrings/yaml) | T3+T7 |
| 红线自检 | T12 |
| 工程量预警(测试冲击) | T5 Step 5 |
