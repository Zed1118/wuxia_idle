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
import 'package:wuxia_idle/shared/widgets/wuxia_ui/stage_progress_row.dart';

/// CharacterPanelScreen 边界用例（nightshift T03）。
///
/// 5 用例：school=null 兜底 / activeIds 老存档兜底 /
/// cultivationProgressToNext=0 防除零 / 非遗物装备过滤 / 满修炼度 1.0。
///
/// 红线：约束语义而非瞬时事实——
/// - school=null 路径不触发 ErrorWidget（防御分支自洽）
/// - 老存档兜底：渲染 ids.first 的角色（兜底路径自洽）
/// - toNext=0：进度条 value=0.0 不产生 NaN（除零防御自洽）
/// - 过滤路径：全非遗物 → 空态文案（集合过滤自洽）
/// - 满进度：value clamped 1.0（边界夹断自洽）
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
    TechniqueSchool? school = TechniqueSchool.gangMeng,
    int? mainTechniqueId,
    int? weaponId,
    int? armorId,
    int? accessoryId,
    int? masterId,
    List<int>? discipleIds,
  }) {
    return Character.create(
      name: name,
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 5, 17),
      internalForce: 200,
      internalForceMax: internalForceMax,
      school: school,
      mainTechniqueId: mainTechniqueId,
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
    bool isLineageHeritage = false,
  }) {
    return Equipment.create(
      defId: 'test_eq_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 17),
      obtainedFrom: 'test',
      baseAttack: 50,
      baseHealth: 100,
      baseSpeed: 10,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
      isLineageHeritage: isLineageHeritage,
    )..id = id;
  }

  Technique mkTechnique({
    required int id,
    required int ownerId,
    required TechniqueRole role,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
  }) {
    return Technique.create(
      defId: 'test_tech_$id',
      ownerCharacterId: ownerId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: role,
      learnedAt: DateTime(2026, 5, 17),
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

    final ids = activeIds ?? [character.id, ...extraCharacters.keys];

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
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 A：school=null → TopBar 不崩 ────────────────────────────────────

  testWidgets('school=null → 色条走 textMuted 兜底，name 正常渲染，无 ErrorWidget',
      (tester) async {
    final character = mkCharacter(id: 1, name: '无派隐者', school: null);

    await pumpPanel(tester, character: character);

    // name 字段正常渲染（不因 school=null 抛错或跳过）
    expect(find.text('无派隐者'), findsOneWidget);
    // 无 ErrorWidget（school=null 分支防御自洽）
    expect(find.byType(ErrorWidget), findsNothing);
  });

  // ── 用例 B：activeIds 不含 initialCharacterId → 兜底 ids.first ────────────

  testWidgets('characterId=99 不在 activeIds=[1] → 兜底渲染 ids.first 角色，无 ErrorWidget',
      (tester) async {
    final fallback = mkCharacter(id: 1, name: '备用角色');

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 故意用 characterId=99，但 activeIds 只有 [1]
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => fallback),
        ],
        child: const MaterialApp(
          home: CharacterPanelScreen(characterId: 99),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // effectiveId = ids.first = 1 → 备用角色名字渲染
    expect(find.text('备用角色'), findsOneWidget);
    // 兜底路径不产生 ErrorWidget
    expect(find.byType(ErrorWidget), findsNothing);
  });

  // ── 用例 C：cultivationProgressToNext=0 → 防除零，value=0.0 ──────────────

  testWidgets('主修 cultivationProgressToNext=0 → 进度条 value=0.0，不产生 NaN',
      (tester) async {
    final character = mkCharacter(id: 1, mainTechniqueId: 20);
    final main = mkTechnique(
      id: 20,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 500,
      cultivationProgressToNext: 0,
    );

    await pumpPanel(tester, character: character, techniques: {20: main});

    final row = tester.widget<StageProgressRow>(
      find.byType(StageProgressRow),
    );
    // cultivationProgressToNext==0 → 防除零分支 → ratio=0.0，非 NaN/异常
    expect(row.ratio, closeTo(0.0, 1e-9));
  });

  // ── 用例 D：装备 isLineageHeritage=false 全过滤 → 遗物行空态 ─────────────

  testWidgets(
      '3 件装备 isLineageHeritage=false → 遗物行走过滤路径，label 存在且值为「无」',
      (tester) async {
    // master 和 disciple 有名字，确保师父/徒弟行不显示「无」，
    // 让「无」唯一来源是遗物行（集合过滤自洽验证）
    final master = mkCharacter(
      id: 99,
      name: '老侠客',
      lineageRole: LineageRole.founder,
    );
    final disciple = mkCharacter(
      id: 98,
      name: '年轻人',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final character = mkCharacter(
      id: 1,
      name: '主角甲',
      lineageRole: LineageRole.disciple,
      masterId: 99,
      discipleIds: [98],
      weaponId: 10,
      armorId: 11,
      accessoryId: 12,
    );
    final weapon = mkEquipment(
      id: 10,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: false,
    );
    final armor = mkEquipment(
      id: 11,
      slot: EquipmentSlot.armor,
      isLineageHeritage: false,
    );
    final acc = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      isLineageHeritage: false,
    );

    await pumpPanel(
      tester,
      character: character,
      extraCharacters: {99: master, 98: disciple},
      equipments: {10: weapon, 11: armor, 12: acc},
    );

    // 遗物行 label 正常渲染
    expect(find.text('遗物'), findsOneWidget);
    // 师父行 value='老侠客'，徒弟行 value='年轻人'，均非「无」；
    // 唯一「无」来自遗物行（3 件装备均非遗物，过滤后 names.isEmpty）
    expect(find.text('无'), findsOneWidget);
    // 无 ErrorWidget
    expect(find.byType(ErrorWidget), findsNothing);
  });

  // ── 用例 E：满修炼度 progress=toNext → value clamped 1.0 ─────────────────

  testWidgets('主修 cultivationProgress=cultivationProgressToNext → 进度条 value clamped 1.0',
      (tester) async {
    final character = mkCharacter(id: 1, mainTechniqueId: 20);
    final main = mkTechnique(
      id: 20,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 300,
      cultivationProgressToNext: 300,
    );

    await pumpPanel(tester, character: character, techniques: {20: main});

    final row = tester.widget<StageProgressRow>(
      find.byType(StageProgressRow),
    );
    // 300/300 = 1.0，clamp(0.0, 1.0) 仍为 1.0（满修炼度边界自洽）
    expect(row.ratio, closeTo(1.0, 1e-9));
  });
}
