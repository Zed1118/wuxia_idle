# 祖师 / 门派命名 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让玩家在新档创建页给祖师和门派取名（含随机取名按钮），并在主菜单显示门派名。

**Architecture:** 名字进已有字段 `Character.name` / `SaveData.sectName`，**不改 Isar schema、不 bump saveVer**。新增组件式名库 yaml + 纯函数随机生成器 + 创建页名号段 + 主菜单门派横幅。

**Tech Stack:** Flutter + Riverpod 3.x + Isar，yaml 配置，`Rng` 抽象（`rngProvider`）。

**Spec:** `docs/superpowers/specs/2026-07-03-founder-sect-naming-design.md`

**通用测试命令：** 全量 `flutter test --no-pub`（默认并发）；单文件 `flutter test --no-pub <path>`；分析 `flutter analyze lib/ test/`。

---

### Task 1: 名库数据 + 配置类 + 加载

**Files:**
- Create: `data/founder_names.yaml`
- Create: `lib/data/defs/founder_names_def.dart`
- Modify: `lib/data/game_repository.dart`（镜像现有 `founderCreation` 的三处接线）
- Test: `test/data/founder_names_config_test.dart`

- [ ] **Step 1: 写名库 yaml**（组件式，真实内容；后续 wuxia-content skill 可扩）

`data/founder_names.yaml`：
```yaml
# 祖师/门派随机取名素材（组件式：姓+名 / 前缀+后缀）。
# 加载:game_repository.loadAllDefs → FounderNamesConfig.fromYaml。无 schema 硬校验。
founder_surnames: [慕容, 令狐, 独孤, 上官, 东方, 西门, 南宫, 欧阳, 司马, 叶, 楚, 沈, 苏, 秦, 萧]
founder_given: [无咎, 惊鸿, 玄机, 拂尘, 问天, 归尘, 听澜, 挽风, 观澜, 望舒, 抱朴, 忘机, 若虚, 长歌]
sect_prefixes: [青城, 昆仑, 天山, 桃花, 听雨, 落霞, 松风, 云隐, 寒江, 玄铁, 断崖, 流云, 碧水, 苍梧]
sect_suffixes: [派, 门, 山庄, 阁, 洞, 观, 宗, 剑庄]
```

- [ ] **Step 2: 写失败测试**

`test/data/founder_names_config_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/founder_names_def.dart';

void main() {
  test('fromYaml 解析四池非空且为 String', () {
    final cfg = FounderNamesConfig.fromYaml(const {
      'founder_surnames': ['慕容', '令狐'],
      'founder_given': ['无咎', '惊鸿'],
      'sect_prefixes': ['青城', '昆仑'],
      'sect_suffixes': ['派', '门'],
    });
    expect(cfg.founderSurnames, ['慕容', '令狐']);
    expect(cfg.founderGiven.length, 2);
    expect(cfg.sectPrefixes.first, '青城');
    expect(cfg.sectSuffixes, contains('派'));
  });

  test('缺 key 回退空列表', () {
    final cfg = FounderNamesConfig.fromYaml(const {});
    expect(cfg.founderSurnames, isEmpty);
    expect(cfg.sectSuffixes, isEmpty);
  });
}
```

- [ ] **Step 3: 运行确认失败**

Run: `flutter test --no-pub test/data/founder_names_config_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../founder_names_def.dart'`

- [ ] **Step 4: 写 config 类**

`lib/data/defs/founder_names_def.dart`：
```dart
/// 祖师/门派随机取名素材（组件式）。data/founder_names.yaml 加载。
class FounderNamesConfig {
  final List<String> founderSurnames;
  final List<String> founderGiven;
  final List<String> sectPrefixes;
  final List<String> sectSuffixes;

  const FounderNamesConfig({
    required this.founderSurnames,
    required this.founderGiven,
    required this.sectPrefixes,
    required this.sectSuffixes,
  });

  factory FounderNamesConfig.fromYaml(Map<String, dynamic> y) {
    List<String> pool(String key) => List<String>.from(
      (y[key] as List? ?? const []).map((e) => e as String),
    );
    return FounderNamesConfig(
      founderSurnames: pool('founder_surnames'),
      founderGiven: pool('founder_given'),
      sectPrefixes: pool('sect_prefixes'),
      sectSuffixes: pool('sect_suffixes'),
    );
  }

  static const empty = FounderNamesConfig(
    founderSurnames: [],
    founderGiven: [],
    sectPrefixes: [],
    sectSuffixes: [],
  );
}
```

- [ ] **Step 5: 运行确认通过**

Run: `flutter test --no-pub test/data/founder_names_config_test.dart`
Expected: PASS（2 tests）

- [ ] **Step 6: 接入 GameRepository（镜像 founderCreation 三处）**

先定位三处：`grep -n 'founderCreation' lib/data/game_repository.dart`
预期命中：① 私有字段声明 ② `loadAllDefs` 里 `_loadOptionalAsset` 加载（约 241-246）③ public getter。

在每处旁加平行的 `founderNames`：

字段声明处旁加：
```dart
  FounderNamesConfig _founderNames = FounderNamesConfig.empty;
```

`loadAllDefs` 中 `founderCreation` 加载块（241-246）之后加：
```dart
    final founderNames = await _loadOptionalAsset<FounderNamesConfig>(
      load,
      'data/founder_names.yaml',
      (raw) => FounderNamesConfig.fromYaml(parseYamlMap(raw)),
      fallback: FounderNamesConfig.empty,
    );
```
并在同方法把它赋给字段的地方（找 `_founderCreation = founderCreation;` 同款赋值行）旁加：
```dart
    _founderNames = founderNames;
```
（若 founderCreation 是直接赋值给字段，按同款写法对齐。）

getter 处（找 `founderCreation` getter）旁加：
```dart
  FounderNamesConfig get founderNames => _founderNames;
```
文件顶部 import：
```dart
import 'defs/founder_names_def.dart';
```

- [ ] **Step 7: 分析 + 提交**

Run: `flutter analyze lib/ test/`
Expected: No issues found

```bash
git add data/founder_names.yaml lib/data/defs/founder_names_def.dart lib/data/game_repository.dart test/data/founder_names_config_test.dart
git commit -m "祖师命名 1/6:名库 yaml + FounderNamesConfig + 加载接入"
```

---

### Task 2: 随机取名生成器（纯函数）

**Files:**
- Modify: `lib/features/onboarding/domain/founder_creation_selection.dart`（加两个 top-level 函数）
- Test: `test/features/onboarding/founder_name_generator_test.dart`

- [ ] **Step 1: 写失败测试**（用 seeded Rng 确定性）

`test/features/onboarding/founder_name_generator_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/founder_names_def.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

const _cfg = FounderNamesConfig(
  founderSurnames: ['慕容', '令狐'],
  founderGiven: ['无咎', '惊鸿'],
  sectPrefixes: ['青城', '昆仑'],
  sectSuffixes: ['派', '门'],
);

void main() {
  test('generateFounderName 组合姓+名、非空、在长度上限内', () {
    final name = generateFounderName(_cfg, DefaultRng(seed: 42));
    expect(name.isNotEmpty, true);
    expect(name.length <= 8, true);
    // 姓在前、名在后:必以某个姓开头
    expect(_cfg.founderSurnames.any((s) => name.startsWith(s)), true);
  });

  test('generateSectName 组合前缀+后缀、非空、在长度上限内', () {
    final name = generateSectName(_cfg, DefaultRng(seed: 42));
    expect(name.isNotEmpty, true);
    expect(name.length <= 12, true);
    expect(_cfg.sectSuffixes.any((s) => name.endsWith(s)), true);
  });

  test('空池回退空串（UI 侧不填）', () {
    expect(generateFounderName(FounderNamesConfig.empty, DefaultRng(seed: 1)), '');
    expect(generateSectName(FounderNamesConfig.empty, DefaultRng(seed: 1)), '');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test --no-pub test/features/onboarding/founder_name_generator_test.dart`
Expected: FAIL — `generateFounderName` 未定义

- [ ] **Step 3: 实现（加到 founder_creation_selection.dart 末尾，与 generateFounderFateChoices 同款 Rng 体例）**

文件顶部确认已 import：`import 'package:wuxia_idle/data/defs/founder_names_def.dart';`（若无则加）。追加：
```dart
/// 随机祖师名（姓 + 名）。空池返回空串，由 UI 侧决定不填。
String generateFounderName(FounderNamesConfig config, Rng rng) {
  if (config.founderSurnames.isEmpty || config.founderGiven.isEmpty) return '';
  final surname = config.founderSurnames[rng.nextInt(config.founderSurnames.length)];
  final given = config.founderGiven[rng.nextInt(config.founderGiven.length)];
  return '$surname$given';
}

/// 随机门派名（前缀 + 后缀）。空池返回空串。
String generateSectName(FounderNamesConfig config, Rng rng) {
  if (config.sectPrefixes.isEmpty || config.sectSuffixes.isEmpty) return '';
  final prefix = config.sectPrefixes[rng.nextInt(config.sectPrefixes.length)];
  final suffix = config.sectSuffixes[rng.nextInt(config.sectSuffixes.length)];
  return '$prefix$suffix';
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test --no-pub test/features/onboarding/founder_name_generator_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/features/onboarding/domain/founder_creation_selection.dart test/features/onboarding/founder_name_generator_test.dart
git commit -m "祖师命名 2/6:随机取名纯函数生成器"
```

---

### Task 3: 名字接进 selection + 构造 + seeding（核心数据流）

**Files:**
- Modify: `lib/features/onboarding/domain/founder_creation_selection.dart`（加字段）
- Modify: `lib/features/onboarding/application/master_builder.dart`（加 nameOverride）
- Modify: `lib/features/onboarding/application/onboarding_service.dart`（透传名字 + sectName）
- Test: `test/features/onboarding/founder_creation_onboarding_test.dart`（新增用例）

- [ ] **Step 1: 写失败测试**（新增到现有 onboarding 测试文件，复用其 setUp）

在 `test/features/onboarding/founder_creation_onboarding_test.dart` 末尾（`main()` 内、现有 test 之后）加：
```dart
  test('自定义名 → founder.name / save.sectName;留空回退默认', () async {
    final config = GameRepository.instance.founderCreation;
    final sel = FounderCreationSelection(
      school: config.schools.first,
      origin: config.origins.first,
      fate: config.fatePool.first,
      founderName: '慕容无咎',
      sectName: '青城派',
    );
    await OnboardingService(isar: IsarSetup.instance).createFoundingMaster(selection: sel);

    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final founder = await isar.characters.get(save.founderCharacterId!);
    expect(founder!.name, '慕容无咎');
    expect(save.sectName, '青城派');
  });

  test('留空 founderName/sectName 回退默认「祖师」「我的门派」', () async {
    final config = GameRepository.instance.founderCreation;
    final sel = FounderCreationSelection(
      school: config.schools.first,
      origin: config.origins.first,
      fate: config.fatePool.first,
    );
    await OnboardingService(isar: IsarSetup.instance).createFoundingMaster(selection: sel);

    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final founder = await isar.characters.get(save.founderCharacterId!);
    expect(founder!.name, '祖师');
    expect(save.sectName, '我的门派');
  });
```
> 注：这两个 test 各自需要干净的 isar（现有测试文件的 setUp 每例清库/重建）。若现有 setUp 是每例重建，直接可用；若非，照现有 test 的 setUp/tearDown 体例补。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test --no-pub test/features/onboarding/founder_creation_onboarding_test.dart`
Expected: FAIL — `FounderCreationSelection` 无 `founderName` 具名参数

- [ ] **Step 3a: selection 加字段**

`lib/features/onboarding/domain/founder_creation_selection.dart` 的 `FounderCreationSelection`：
```dart
class FounderCreationSelection {
  final FounderSchoolOption school;
  final FounderOriginOption origin;
  final FounderFateOption fate;
  final String? founderName;
  final String? sectName;

  const FounderCreationSelection({
    required this.school,
    required this.origin,
    required this.fate,
    this.founderName,
    this.sectName,
  });
}
```

- [ ] **Step 3b: buildMasterCharacter 加 nameOverride**

`lib/features/onboarding/application/master_builder.dart`，签名加参数：
```dart
Character buildMasterCharacter(
  MasterDef def, {
  required DateTime now,
  AttributeProfile? attributeProfile,
  String? nameOverride,
  String? founderCreationSchoolId,
  String? founderCreationOriginId,
  String? founderCreationFateId,
}) {
```
构造里 `name:` 改为：
```dart
    name: nameOverride ?? defaultMasterName(def),
```

- [ ] **Step 3c: seeding 透传**

`lib/features/onboarding/application/onboarding_service.dart` 的 `_seedFoundingMasters`：

祖师 build（`buildMasterCharacter(masters[0], ...)..id = 1`）加一行 `nameOverride`：
```dart
      final founder = buildMasterCharacter(
        masters[0],
        now: now,
        attributeProfile: creation?.fate.attributeProfile,
        nameOverride: creation?.founderName,
        founderCreationSchoolId: creation?.school.id,
        founderCreationOriginId: creation?.origin.id,
        founderCreationFateId: creation?.fate.id,
      )..id = 1;
```
sectName 行由 `save.sectName ??= UiStrings.defaultSectName;` 改为：
```dart
        save.sectName = creation?.sectName ?? UiStrings.defaultSectName;
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test --no-pub test/features/onboarding/founder_creation_onboarding_test.dart`
Expected: PASS（含新增 2 例 + 原有例不回归）

- [ ] **Step 5: 全项目分析 + 提交**

Run: `flutter analyze lib/ test/`（buildMasterCharacter 调用点若有编译影响会在此暴露）
Expected: No issues found

```bash
git add lib/features/onboarding/ test/features/onboarding/founder_creation_onboarding_test.dart
git commit -m "祖师命名 3/6:名字接进 selection/构造/seeding + 回退默认"
```

---

### Task 4: UiStrings 命名文案

**Files:**
- Modify: `lib/shared/strings.dart`（founderCreate 段，约 1895-1930）

- [ ] **Step 1: 加字符串**（放在 `founderCreateBack` 之后同段内）
```dart
  static const String founderCreateNameSection = '四 · 立名号';
  static const String founderCreateFounderNameLabel = '祖师名';
  static const String founderCreateSectNameLabel = '门派名';
  static const String founderCreateRollName = '掷个名号';
  static const String founderCreateFounderNameHint = '留空则称「祖师」';
  static const String founderCreateSectNameHint = '留空则称「我的门派」';
```

- [ ] **Step 2: 分析 + 提交**

Run: `flutter analyze lib/`
Expected: No issues found
```bash
git add lib/shared/strings.dart
git commit -m "祖师命名 4/6:命名段 UiStrings"
```

---

### Task 5: 创建页名号段 UI

**Files:**
- Modify: `lib/features/onboarding/presentation/founder_creation_screen.dart`
- Test: `test/features/onboarding/founder_creation_screen_naming_test.dart`

- [ ] **Step 1: State 加控制器**（在 `_FounderCreationScreenState` 字段区）
```dart
  final _founderNameController = TextEditingController();
  final _sectNameController = TextEditingController();
```
加 dispose（若无 dispose 则新增）：
```dart
  @override
  void dispose() {
    _founderNameController.dispose();
    _sectNameController.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: build 里插入名号段**（`_PreviewPanel` 之后、确认按钮 `Align` 之前）
```dart
                        const SizedBox(height: 16),
                        _Section(
                          title: UiStrings.founderCreateNameSection,
                          child: _NameFields(
                            founderController: _founderNameController,
                            sectController: _sectNameController,
                            onRollFounder: () {
                              final name = generateFounderName(
                                GameRepository.instance.founderNames,
                                ref.read(rngProvider),
                              );
                              if (name.isNotEmpty) {
                                _founderNameController.text = name;
                              }
                            },
                            onRollSect: () {
                              final name = generateSectName(
                                GameRepository.instance.founderNames,
                                ref.read(rngProvider),
                              );
                              if (name.isNotEmpty) {
                                _sectNameController.text = name;
                              }
                            },
                          ),
                        ),
```

- [ ] **Step 3: _confirm() 透传名字**（读控制器、trim、空→null）

`_confirm()` 里构造 `FounderCreationSelection(...)` 改为：
```dart
      selection: FounderCreationSelection(
        school: _school,
        origin: _origin,
        fate: _fate,
        founderName: _founderNameController.text.trim().isEmpty
            ? null
            : _founderNameController.text.trim(),
        sectName: _sectNameController.text.trim().isEmpty
            ? null
            : _sectNameController.text.trim(),
      ),
```

- [ ] **Step 4: 新增 _NameFields widget**（文件末尾，深底配色沿用 WuxiaColors）
```dart
class _NameFields extends StatelessWidget {
  const _NameFields({
    required this.founderController,
    required this.sectController,
    required this.onRollFounder,
    required this.onRollSect,
  });

  final TextEditingController founderController;
  final TextEditingController sectController;
  final VoidCallback onRollFounder;
  final VoidCallback onRollSect;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _NameRow(
        label: UiStrings.founderCreateFounderNameLabel,
        hint: UiStrings.founderCreateFounderNameHint,
        controller: founderController,
        maxLength: 8,
        onRoll: onRollFounder,
      ),
      const SizedBox(height: 12),
      _NameRow(
        label: UiStrings.founderCreateSectNameLabel,
        hint: UiStrings.founderCreateSectNameHint,
        controller: sectController,
        maxLength: 12,
        onRoll: onRollSect,
      ),
    ],
  );
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxLength,
    required this.onRoll,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLength;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 64,
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
      Expanded(
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          style: const TextStyle(color: WuxiaColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: WuxiaColors.textMuted),
            counterText: '',
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: onRoll,
        icon: const Icon(Icons.casino_outlined, size: 18),
        label: const Text(UiStrings.founderCreateRollName),
      ),
    ],
  );
}
```

- [ ] **Step 5: 写 widget 测试**（复用 onboarding 测试的 setUp 加载 GameRepository + IsarSetup）

`test/features/onboarding/founder_creation_screen_naming_test.dart`：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
// TODO(engineer):把 founder_creation_onboarding_test.dart 里 setUpAll/tearDownAll
// (加载 GameRepository + 初始化 IsarSetup 临时库) 原样复制到此文件,保证 GameRepository.instance 与 IsarSetup.instance 可用。

void main() {
  // <复用上面 setUpAll/tearDown>

  testWidgets('名号段渲染 + 掷名按钮填入祖师名', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FounderCreationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 名号段标题在
    expect(find.text(UiStrings.founderCreateNameSection), findsOneWidget);
    // 掷名按钮存在(祖师名 + 门派名各一)
    expect(find.text(UiStrings.founderCreateRollName), findsNWidgets(2));

    // 点第一个掷名按钮 → 祖师名输入框非空
    await tester.tap(find.text(UiStrings.founderCreateRollName).first);
    await tester.pumpAndSettle();
    final founderField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(founderField.controller!.text.isNotEmpty, true);
  });
}
```
> 若 `FounderCreationScreen` 无 config（GameRepository 未加载）会走 `founderCreateNoConfig` 分支——故必须复用真实加载 setUp。

- [ ] **Step 6: 运行确认通过**

Run: `flutter test --no-pub test/features/onboarding/founder_creation_screen_naming_test.dart`
Expected: PASS

- [ ] **Step 7: 分析 + 提交**

Run: `flutter analyze lib/ test/`
Expected: No issues found
```bash
git add lib/features/onboarding/presentation/founder_creation_screen.dart test/features/onboarding/founder_creation_screen_naming_test.dart
git commit -m "祖师命名 5/6:创建页名号段 UI + 掷名按钮"
```

---

### Task 6: 主菜单门派横幅

**Files:**
- Modify: `lib/features/main_menu/presentation/main_menu.dart`
- Test: `test/features/main_menu/sect_banner_test.dart`

- [ ] **Step 1: 写失败测试**（纯 widget，横幅拆成可独立测的私有 widget）

`test/features/main_menu/sect_banner_test.dart`：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/main_menu/presentation/sect_banner.dart';

void main() {
  testWidgets('SectBanner 显示门派名', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SectBanner(sectName: '青城派'))),
    );
    expect(find.text('青城派'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test --no-pub test/features/main_menu/sect_banner_test.dart`
Expected: FAIL — `sect_banner.dart` 不存在

- [ ] **Step 3: 建独立横幅 widget**（纯展示，便于测 + 复用）

`lib/features/main_menu/presentation/sect_banner.dart`：
```dart
import 'package:flutter/material.dart';
import 'package:wuxia_idle/shared/theme/wuxia_colors.dart';

/// 主菜单门派名横幅（纯展示）。sectName 由父层从 activeSave 取。
class SectBanner extends StatelessWidget {
  const SectBanner({required this.sectName, super.key});

  final String sectName;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      sectName,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    ),
  );
}
```
> 注：`wuxia_colors.dart` 路径以项目实际 import 为准（`grep -rn "WuxiaColors" lib/features/main_menu/presentation/main_menu.dart` 抄它的 import）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test --no-pub test/features/main_menu/sect_banner_test.dart`
Expected: PASS

- [ ] **Step 5: 在主菜单接线**（watch 已有 provider，顶部插横幅）

`lib/features/main_menu/presentation/main_menu.dart`：
顶部 import：
```dart
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'sect_banner.dart';
```
（若 status_summary_provider 已 import 则跳过。）

在 `build` 里加读取：
```dart
    final sectName = ref
        .watch(mainMenuSaveSnapshotProvider)
        .maybeWhen(data: (s) => s?.sectName, orElse: () => null);
```
在主菜单返回的顶部区域（标题/菜单列表最上方）插入横幅。先定位插点：`grep -n 'child: Column\|children: \[' lib/features/main_menu/presentation/main_menu.dart` 找主体 Column，在其 children 顶部加：
```dart
                  if (sectName != null && sectName.isNotEmpty)
                    SectBanner(sectName: sectName),
```

- [ ] **Step 6: 分析 + 提交**

Run: `flutter analyze lib/ test/`
Expected: No issues found
```bash
git add lib/features/main_menu/ test/features/main_menu/sect_banner_test.dart
git commit -m "祖师命名 6/6:主菜单门派名横幅"
```

---

### Task 7: 整体验证 + 视觉验收

- [ ] **Step 1: pubspec 资产守卫**（founder_names.yaml 在 data/ 根，由 `- data/` 声明覆盖，无需改 pubspec）

Run: `flutter test --no-pub test/data/pubspec_asset_declaration_test.dart`
Expected: PASS（确认 founder_names.yaml 可达）

- [ ] **Step 2: 全量测试**（接线碰存档写路径属跨切面，批末跑全量）

Run: `flutter test --no-pub`
Expected: 全绿 0 fail（基线 + 新增测试）

- [ ] **Step 3: 分析**

Run: `flutter analyze lib/ test/`
Expected: No issues found

- [ ] **Step 4: 视觉验收（人工）**

- 创建页：`flutter run -d macos --dart-define=VISUAL_ROUTE=founder_creation` 看名号段 + 掷名按钮 + 深底文字对比
- 主菜单门派横幅：真机开新档取名 → 回主菜单看横幅（无独立 VISUAL_ROUTE，需真跑）
- 报告截图/观察

- [ ] **Step 5: 更新 backlog + PROGRESS**（订正 drift）

- `docs/spec/playability_phase2_backlog.md §十二`：标注祖师创建 6/7 早已实装（c967a959），第⑦命名本波补齐
- `PROGRESS.md` 顶段加完成条

```bash
git add docs/spec/playability_phase2_backlog.md PROGRESS.md
git commit -m "祖师命名:backlog drift 订正 + PROGRESS 更新"
```

---

## Self-Review 覆盖检查

- Spec「创建页底部名号段」→ Task 5 ✓
- Spec「founder_names.yaml 名库 + 掷名」→ Task 1 + 2 ✓
- Spec「名字进 Character.name / SaveData.sectName」→ Task 3 ✓
- Spec「主菜单门派横幅」→ Task 6 ✓
- Spec「留空回退默认 / 长度 8·12 / 不改 saveVer」→ Task 3(回退) + Task 5(maxLength) + 全程无 schema 改动 ✓
- Spec「rngProvider 不用裸 dart:math」→ Task 5 用 ref.read(rngProvider) ✓
- Spec 测试全维度 → Task 1/2/3/5/6 各带测 + Task 7 全量 ✓
