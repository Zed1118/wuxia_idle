import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/baike/presentation/baike_screen.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1 #44 Nightshift T04 · BaikeScreen 典故 tab 7 阶分组严格顺序 + presetLoreIds 段数 edge。
///
/// Fixture 方案：自定义 loader 返回最小有效 YAML。
///   - equipment.yaml: 7 阶 × 5 件覆盖(3 流派武器 + 护甲 + 饰品)+ 4 件段数测试件
///   - masters.yaml:   3 角色最小有效结构，founder startingEquipmentIds=[利器遗物]
///   - techniques/skills/stages/towers: 空列表(跳过覆盖度红线)
///   - numbers.yaml:   沿用真实文件(49 境界行 / 数值参数)
///   - data/lore/*.yaml: 测试 lore id → inline 返回最小有效 lore YAML

// ─────────────────────────────────────────────────────────────────────────────
// Fixture helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<String> _fixtureLoader(String path) async {
  if (path == 'data/equipment.yaml') return _buildEquipmentYaml();
  if (path == 'data/masters.yaml') return _kMastersYaml;
  if (path == 'data/techniques.yaml') return 'techniques: []\n';
  if (path == 'data/founder_creation.yaml') {
    return 'schools: []\norigins: []\nfatePool: []\n';
  }
  if (path == 'data/skills.yaml') return 'skills: []\n';
  if (path == 'data/stages.yaml') return 'stages: []\n';
  if (path == 'data/towers.yaml') return 'floors: []\n';
  if (path.startsWith('data/lore/')) {
    final loreId = path
        .replaceFirst('data/lore/', '')
        .replaceFirst('.yaml', '');
    return 'id: $loreId\nname: 测试典故\ndefault_lore:\n  - text: 测试内容\n';
  }
  return File(path).readAsString();
}

// 3 角色最小结构：founder → yiLiu + 利器遗物；2 弟子 → 空 equipment/technique
const _kMastersYaml = '''
masters:
  - id: t_founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    enabledInDemo: true
    attributeProfile:
      constitution: 6
      enlightenment: 6
      agility: 6
      fortune: 6
    startingTechniqueIds: []
    startingEquipmentIds:
      - t_liQi_w_gangMeng

  - id: t_disciple1
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    enabledInDemo: true
    attributeProfile:
      constitution: 5
      enlightenment: 6
      agility: 5
      fortune: 5
    startingTechniqueIds: []
    startingEquipmentIds: []

  - id: t_disciple2
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    enabledInDemo: true
    attributeProfile:
      constitution: 5
      enlightenment: 5
      agility: 6
      fortune: 5
    startingTechniqueIds: []
    startingEquipmentIds: []
''';

/// 生成最小有效 equipment YAML:
///   - 7 阶 × 5 件(gangMeng/lingQiao/yinRou 武器 + 护甲 + 饰品), presetLoreIds: []
///   - liQi×gangMeng 武器 isLineageHeritage: true (满足 T55 祖师遗物红线)
///   - 4 件段数测试件(xunChang 额外武器), 段数分别 0/1/3/5
String _buildEquipmentYaml() {
  final buf = StringBuffer('equipment:\n');

  for (final tier in EquipmentTier.values) {
    final t = tier.name;
    // 3 流派武器
    for (final school in TechniqueSchool.values) {
      final s = school.name;
      final isHeritage =
          tier == EquipmentTier.liQi && school == TechniqueSchool.gangMeng;
      buf.write('''  - id: t_${t}_w_$s
    name: 测$t$s
    tier: $t
    slot: weapon
    schoolBias: $s
    baseAttackMin: 10
    baseAttackMax: 100
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: []
    tagline: 测试占位典故
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: $isHeritage
''');
    }
    // 护甲
    buf.write('''  - id: t_${t}_armor
    name: 测$t护甲
    tier: $t
    slot: armor
    baseAttackMin: 0
    baseAttackMax: 50
    baseHealthMin: 0
    baseHealthMax: 500
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: []
    tagline: 测试占位典故
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
''');
    // 饰品
    buf.write('''  - id: t_${t}_acc
    name: 测$t饰品
    tier: $t
    slot: accessory
    baseAttackMin: 0
    baseAttackMax: 0
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 10
    presetLoreIds: []
    tagline: 测试占位典故
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
''');
  }

  // 段数测试件(0/1/3/5 lore ids)，挂在 xunChang 阶(额外武器，不影响覆盖度)
  buf.write('''  - id: t_test_zero
    name: 零段测试件
    tier: xunChang
    slot: weapon
    schoolBias: yinRou
    baseAttackMin: 5
    baseAttackMax: 50
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: []
    tagline: 测试占位典故
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
  - id: t_test_one
    name: 一段测试件
    tier: xunChang
    slot: weapon
    schoolBias: yinRou
    baseAttackMin: 5
    baseAttackMax: 50
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: [test_lore_1]
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
  - id: t_test_three
    name: 三段测试件
    tier: xunChang
    slot: weapon
    schoolBias: yinRou
    baseAttackMin: 5
    baseAttackMax: 50
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: [test_lore_3a, test_lore_3b, test_lore_3c]
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
  - id: t_test_five
    name: 五段测试件
    tier: xunChang
    slot: weapon
    schoolBias: yinRou
    baseAttackMin: 5
    baseAttackMax: 50
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 0
    presetLoreIds: [test_lore_5a, test_lore_5b, test_lore_5c, test_lore_5d, test_lore_5e]
    dropSourceTags: []
    iconPath: assets/placeholder.png
    isLineageHeritage: false
''');

  return buf.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    GameRepository.resetForTest();
    await GameRepository.loadAllDefs(loader: _fixtureLoader);
  });

  tearDownAll(GameRepository.resetForTest);

  // 切典故 tab 的公共辅助：拉大 viewport 确保 ListView.builder 全量构建
  Future<void> goToLoreTab(WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BaikeScreen())),
    );
    await tester.tap(find.text(UiStrings.baikeTabLore));
    await tester.pumpAndSettle();
  }

  testWidgets('A. 典故 tab 7 阶 heading 顺序严格 ≡ EquipmentTier.values', (
    tester,
  ) async {
    await goToLoreTab(tester);

    // EquipmentTier.values 白名单定义"正确顺序"——不写「第 1 个是寻常货」
    final tierL10ns = EquipmentTier.values.map(EnumL10n.equipmentTier).toList();
    final allTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .toList();
    // 过滤出 tier heading：仅取与 L10n 列表完全匹配的文本
    final headings = allTexts.where(tierL10ns.contains).toList();

    expect(
      headings,
      equals(tierL10ns),
      reason: '7 阶分组 heading 顺序应与 EquipmentTier.values 枚举声明顺序严格一致',
    );
  });

  testWidgets('B. presetLoreIds 空列表 → 渲染「0 段典故」', (tester) async {
    await goToLoreTab(tester);

    final def = GameRepository.instance.equipmentDefs['t_test_zero']!;
    expect(
      def.presetLoreIds,
      isEmpty,
      reason: '测试前提：fixture t_test_zero 段数为 0',
    );
    // 断言用「def.presetLoreIds.length 维度等价」，不写字面数字
    expect(
      find.text('${def.presetLoreIds.length} 段典故'),
      findsAtLeastNWidgets(1),
      reason: 'presetLoreIds 为空 → widget 渲染 ${def.presetLoreIds.length} 段典故',
    );
  });

  testWidgets('C. presetLoreIds 恰好 1 段 → 渲染「1 段典故」', (tester) async {
    await goToLoreTab(tester);

    final def = GameRepository.instance.equipmentDefs['t_test_one']!;
    expect(
      def.presetLoreIds.length,
      equals(1),
      reason: '测试前提：fixture t_test_one 段数为 1',
    );
    expect(
      find.text('${def.presetLoreIds.length} 段典故'),
      findsAtLeastNWidgets(1),
      reason:
          'presetLoreIds.length=1 → widget 渲染 ${def.presetLoreIds.length} 段典故',
    );
  });

  testWidgets('D. presetLoreIds N 段混合(1/3/5) → 集合等价各显对应段数', (tester) async {
    await goToLoreTab(tester);

    final testIds = ['t_test_one', 't_test_three', 't_test_five'];
    final defs = testIds
        .map((id) => GameRepository.instance.equipmentDefs[id]!)
        .toList();

    // 验证 fixture 本身: 3 件装备段数各不相同
    final expectedTexts = defs
        .map((d) => '${d.presetLoreIds.length} 段典故')
        .toSet();
    expect(expectedTexts.length, equals(3), reason: 'fixture 3 件装备应有 3 个不同段数');

    // 集合等价：widget tree 中每个预期段数文本均出现
    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .toSet();
    for (final expected in expectedTexts) {
      expect(
        rendered.contains(expected),
        isTrue,
        reason: '典故 tab 应渲染「$expected」',
      );
    }
  });
}
