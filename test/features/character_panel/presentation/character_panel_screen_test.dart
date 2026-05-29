import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/features/character_panel/presentation/character_panel_screen.dart';

/// T28 角色面板 widget 测试（phase2_tasks.md §407）。
///
/// 4 用例：3 装备槽渲染 / 未装备占位 / 共鸣阶段中文 / 修炼度进度条 value。
/// 全部走 ProviderScope.overrides 注入 fixture，不打开真实 Isar。
/// setUpAll 加载真实 GameRepository（numbers.yaml）供派生数值公式使用。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── fixtures ──────────────────────────────────────────────────────────────

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({
    int id = 1,
    String name = '测试者',
    RealmTier realmTier = RealmTier.xueTu,
    LineageRole lineageRole = LineageRole.founder,
    int internalForceMax = 500,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int? weaponId,
    int? armorId,
    int? accessoryId,
    int? masterId,
    List<int>? discipleIds,
  }) {
    final now = DateTime(2026, 5, 11);
    return Character.create(
      name: name,
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: now,
      internalForce: 200,
      internalForceMax: internalForceMax,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
      equippedWeaponId: weaponId,
      equippedArmorId: armorId,
      equippedAccessoryId: accessoryId,
      masterId: masterId,
      discipleIds: discipleIds,
    )..id = id;
  }

  Equipment mkEquipment({
    required int id,
    required EquipmentSlot slot,
    int enhanceLevel = 0,
    int battleCount = 0,
    EquipmentTier tier = EquipmentTier.xunChang,
    String? defId,
    bool isLineageHeritage = false,
    List<int>? previousOwnerCharacterIds,
  }) {
    return Equipment.create(
      defId: defId ?? 'test_eq_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      baseHealth: 100,
      baseSpeed: 10,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
      isLineageHeritage: isLineageHeritage,
      previousOwnerCharacterIds: previousOwnerCharacterIds,
    )..id = id;
  }

  Technique mkTechnique({
    required int id,
    required int ownerId,
    required TechniqueRole role,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
    String? defId,
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
  }) {
    return Technique.create(
      defId: defId ?? 'test_tech_$id',
      ownerCharacterId: ownerId,
      tier: tier,
      school: school,
      role: role,
      learnedAt: DateTime(2026, 5, 11),
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
    )..id = id;
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Character character,
    Map<int, Character> extraCharacters = const {},
    List<int>? activeIds,
    Map<int, Equipment> equipments = const {},
    Map<int, Technique> techniques = const {},
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ids = activeIds ??
        <int>[character.id, ...extraCharacters.keys];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => ids),
          characterByIdProvider(character.id).overrideWith(
            (ref) async => character,
          ),
          for (final entry in extraCharacters.entries)
            characterByIdProvider(entry.key).overrideWith(
              (ref) async => entry.value,
            ),
          for (final entry in equipments.entries)
            equipmentByIdProvider(entry.key).overrideWith(
              (ref) async => entry.value,
            ),
          for (final entry in techniques.entries)
            techniqueByIdProvider(entry.key).overrideWith(
              (ref) async => entry.value,
            ),
        ],
        child: MaterialApp(
          home: CharacterPanelScreen(characterId: character.id),
        ),
      ),
    );
    // 四次 pump 让 activeCharacterIdsProvider + family Future 完成 + AsyncValue 翻转 + 子 Consumer rebuild。
    // 不用 pumpAndSettle：CircularProgressIndicator 是无限动画会卡。
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 1：3 装备槽全显示 ─────────────────────────────────────────────

  testWidgets('3 装备槽全装备时，+N 强化等级全部渲染', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final weapon = mkEquipment(
      id: 10,
      slot: EquipmentSlot.weapon,
      enhanceLevel: 5,
    );
    final armor = mkEquipment(
      id: 11,
      slot: EquipmentSlot.armor,
      enhanceLevel: 3,
    );
    final acc = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      enhanceLevel: 7,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: weapon, 11: armor, 12: acc},
    );

    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('护甲'), findsOneWidget);
    expect(find.text('饰品'), findsOneWidget);
  });

  // ── 用例 2：未装备占位 ─────────────────────────────────────────────────

  testWidgets('三个装备槽 id 全 null 时，渲染 3 个「未装备」占位', (tester) async {
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    expect(find.text('未装备'), findsNWidgets(3));
    expect(find.text('未修主修'), findsOneWidget);
    expect(find.text('未学'), findsNWidgets(3));
  });

  // ── 用例 3：共鸣阶段中文 ──────────────────────────────────────────────

  // 根因A(2026-05-29):默契边界 500→300,趁手 [100,300)。原 300 现属默契,
  // 改用 200 取趁手段(生疏 30 / 趁手 200 / 默契 1000)。
  testWidgets('battleCount 跨阶 30 / 200 / 1000 → 生疏 / 趁手 / 默契', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final w = mkEquipment(id: 10, slot: EquipmentSlot.weapon, battleCount: 30);
    final a = mkEquipment(id: 11, slot: EquipmentSlot.armor, battleCount: 200);
    final c = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      battleCount: 1000,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: w, 11: a, 12: c},
    );

    expect(find.text('生疏'), findsOneWidget);
    expect(find.text('趁手'), findsOneWidget);
    expect(find.text('默契'), findsOneWidget);
  });

  // ── 用例 4：修炼度进度条 ──────────────────────────────────────────────

  testWidgets('主修 progress=50 / toNext=100 → LinearProgressIndicator.value=0.5',
      (tester) async {
    final character = mkCharacter(mainTechniqueId: 20);
    final main = mkTechnique(
      id: 20,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 50,
      cultivationProgressToNext: 100,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {20: main},
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.5, 1e-9));
    expect(find.text('50 / 100'), findsOneWidget);
    expect(find.text('主修'), findsOneWidget);
  });

  // ── T56 用例 5：3 角色 Tab 切换 ────────────────────────────────────────

  testWidgets('activeCharacterIds=[1,2,3] → 3 Tab label 渲染 + 默认显示首位姓名',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
    );

    // 3 个 Tab label 都在
    expect(find.text('祖师'), findsOneWidget);
    expect(find.text('大弟子'), findsOneWidget);
    expect(find.text('二弟子'), findsOneWidget);
    // 默认首屏祖师爷姓名可见
    expect(find.text('祖师爷'), findsOneWidget);
    expect(find.text('大弟子A'), findsNothing);
  });

  testWidgets('tap 大弟子 Tab → 切到 character 2，祖师内容消失',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
    );

    expect(find.text('祖师爷'), findsOneWidget);

    await tester.tap(find.text('大弟子'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 切换后顶部姓名变更
    expect(find.text('大弟子A'), findsOneWidget);
    // 祖师爷顶部姓名消失（lineage section 师父行也可能出现祖师爷，
    // 所以 findsOneWidget 即可，不可断言 findsNothing）
    expect(find.text('祖师爷'), findsOneWidget); // 在「师父」行
  });

  // ── T56 用例 6：师承段渲染 ─────────────────────────────────────────────

  testWidgets('师承段：师父行 + 徒弟列表 join + 传记占位 + 遗物名',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
      weaponId: 100,
      armorId: 101,
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final sword = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_liqi_long_quan',
      isLineageHeritage: true,
    );
    final armor = mkEquipment(
      id: 101,
      slot: EquipmentSlot.armor,
      defId: 'armor_haojiahuo_jin_pao',
      isLineageHeritage: true,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
      equipments: {100: sword, 101: armor},
    );

    // 师承段标题
    expect(find.text('师承'), findsOneWidget);
    expect(find.text('师父'), findsOneWidget);
    expect(find.text('徒弟'), findsOneWidget);
    expect(find.text('传记'), findsOneWidget);
    expect(find.text('遗物'), findsOneWidget);

    // 祖师无师父 → 「无」
    expect(find.text('无'), findsOneWidget);
    // 徒弟列表 join
    expect(find.text('大弟子A / 二弟子B'), findsOneWidget);
    // 传记占位
    expect(find.text('[传记待补]'), findsOneWidget);
    // 遗物名（从 GameRepository.equipmentDefs 解析）
    expect(find.text('龙泉剑 / 锦袍'), findsOneWidget);
  });

  // ── T56 用例 7：祖师内力上限 lineage +10% buff 落 UI ──────────────────

  testWidgets('祖师装 2 件 lineage heritage → 内力上限显示 base × 1.10',
      (tester) async {
    // base 10000 → × (1 + 2×0.05) = 11000
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      internalForceMax: 10000,
      weaponId: 100,
      armorId: 101,
    );
    final sword = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
    );
    final armor = mkEquipment(
      id: 101,
      slot: EquipmentSlot.armor,
      isLineageHeritage: true,
    );

    await pumpPanel(
      tester,
      character: founder,
      equipments: {100: sword, 101: armor},
    );

    // internalForceValue 格式: "200 / 11000"（current=200 固定，max=11000）
    expect(find.text('200 / 11000'), findsOneWidget);
  });

  // ── W18-A1 用例 8:心法相生 chip ────────────────────────────────────────

  testWidgets('主修 gangMeng + 辅修 yinRou → 阴阳调和 chip 显示',
      (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 30,
      assistTechniqueIds: [31],
    );
    final main = mkTechnique(
      id: 30,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: 'tech_gangmeng_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
    );
    final assist = mkTechnique(
      id: 31,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_yinrou_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.yinRou,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {30: main, 31: assist},
    );

    expect(find.text('相生'), findsOneWidget,
        reason: 'UiStrings.synergyActiveLabel chip 显示');
    expect(find.textContaining('阴阳调和'), findsOneWidget,
        reason: 'synergy_yin_yang_he_xie name');
  });

  testWidgets('未修主修 / 无辅修 → 不显相生 chip', (tester) async {
    final character = mkCharacter(); // no main / no assist
    await pumpPanel(tester, character: character);

    expect(find.text('相生'), findsNothing);
  });

  testWidgets('主辅同流派 gangMeng+gangMeng → 同流派精进 chip(sameSchool 命中)',
      (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 40,
      assistTechniqueIds: [41],
    );
    final main = mkTechnique(
      id: 40,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: 'tech_gangmeng_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
    );
    final assist = mkTechnique(
      id: 41,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_gangmeng_changlian',
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.gangMeng,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {40: main, 41: assist},
    );

    expect(find.text('相生'), findsOneWidget);
    expect(find.textContaining('同流派精进'), findsOneWidget);
  });

  // ── 用例 13:P5+ 多代 chip · prev.length > 1 显「N 代传承」副行(F.2 续) ──

  testWidgets('character_panel 装 heritage prev=[1,2] → 显「3 代传承」副行',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      weaponId: 100,
    );
    final weapon = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
      previousOwnerCharacterIds: [1, 2],
    );

    await pumpPanel(
      tester,
      character: founder,
      equipments: {100: weapon},
    );

    // gen2 prev.length=2 → chip 副行显「3 代传承」(N = prevLen + 1)
    expect(find.text('3 代传承'), findsOneWidget,
        reason: 'P5+ 多代 chip · gen2 主断言');
  });

  // ── 用例 14:gen1 边界 · prev.length=1 不显 chip ─────────────────────────

  testWidgets('character_panel 装 heritage prev=[1] → 不显多代 chip(gen1 边界)',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      weaponId: 100,
    );
    final weapon = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
      previousOwnerCharacterIds: [1],
    );

    await pumpPanel(
      tester,
      character: founder,
      equipments: {100: weapon},
    );

    // gen1 prev.length=1 不触发 > 1 阈值 · 不应显示任何 N 代传承 chip
    expect(find.textContaining('代传承'), findsNothing,
        reason: 'gen1 边界 · 阈值 > 1 严守');
  });
}
