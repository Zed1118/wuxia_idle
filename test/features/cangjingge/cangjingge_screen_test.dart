import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/cangjingge_screen.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/skill_proficiency_row.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_resolver.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// CangJingGeScreen 藏经阁主屏测试（P1b Task9）。
///
/// 两层验证（遵循项目 widget-test 约定，参见 memory feedback_isar_widget_test_deadlock：
/// testWidgets 内不开真 Isar，否则 writeTxn 死锁）：
///
/// - **widget test**：ProviderScope.overrides 注入 fixture（无真 Isar），
///   验证 AppBar 标题 / 出战 6 槽 / 武学库 SkillProficiencyRow 渲染，
///   且已装配槽（mainSkillId1）的招名落到槽上。
/// - **autoFill 落库 test**：真 Isar（IsarSetup.init），跑屏幕进入时所用的
///   [SkillLoadoutResolver] + [SkillLoadoutService.applyAutoFill] 同一路径，
///   验证 mainSkillId1 落库非 null（与屏幕 initState autoFill 行为同源）。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  // ── fixtures ──────────────────────────────────────────────────────────────

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  // tech_gangmeng_jichu 的招（techniques.yaml）：basic/skill/ult 三招，tier=null 入门可装。
  const mainTechDefId = 'tech_gangmeng_jichu';
  const equippedSkillId = 'skill_gangmeng_jichu_basic';

  Character mkCharacter({int id = 1, String? mainSkillId1}) => Character.create(
    name: '测试弟子',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: mkAttrs(),
    rarity: RarityTier.xunChang,
    lineageRole: LineageRole.disciple,
    createdAt: DateTime(2026, 1, 1),
    mainTechniqueId: 100,
    mainSkillId1: mainSkillId1,
  )..id = id;

  Technique mkMainTechnique() => Technique.create(
    defId: mainTechDefId,
    ownerCharacterId: 1,
    tier: TechniqueTier.ruMenGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
  )..id = 100;

  // ── widget test（overrides，无真 Isar）─────────────────────────────────────

  testWidgets('藏经阁主屏：AppBar 标题 + 6 槽 + 武学库行渲染 + 已装配招落槽', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final character = mkCharacter(id: 1, mainSkillId1: equippedSkillId);
    final mainTech = mkMainTechnique();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => character),
          characterAllTechniquesProvider(
            1,
          ).overrideWith((ref) async => [mainTech]),
        ],
        child: const MaterialApp(home: CangJingGeScreen(characterId: 1)),
      ),
    );
    // 不用 pumpAndSettle：CircularProgressIndicator 无限动画会卡。
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // AppBar 标题（出战配置，AppBar + section 都用 → findsWidgets）
    expect(find.text(UiStrings.cangjingLoadoutTitle), findsWidgets);

    // 出战配置栏 6 槽标签
    expect(find.text(UiStrings.cangjingSlotMain(1)), findsOneWidget);
    expect(find.text(UiStrings.cangjingSlotMain(2)), findsOneWidget);
    expect(find.text(UiStrings.cangjingSlotAssist), findsOneWidget);
    expect(find.text(UiStrings.cangjingSlotResonance), findsOneWidget);
    expect(find.text(UiStrings.cangjingSlotUltimate), findsOneWidget);
    expect(find.text(UiStrings.cangjingSlotEncounter), findsOneWidget);

    // 已装配的 main1 槽显示招名（skill_gangmeng_jichu_basic = 「直拳」）
    final equippedName =
        GameRepository.instance.skillDefs[equippedSkillId]!.name;
    expect(find.text(equippedName), findsWidgets);

    // 武学库：至少一个熟练度行
    expect(find.byType(SkillProficiencyRow), findsWidgets);
  });

  testWidgets('藏经阁出战槽显示用途说明（main1 常用输出 / ultimate 高内力爆发）', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final character = mkCharacter(id: 1, mainSkillId1: equippedSkillId);
    final mainTech = mkMainTechnique();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => character),
          characterAllTechniquesProvider(
            1,
          ).overrideWith((ref) async => [mainTech]),
        ],
        child: const MaterialApp(home: CangJingGeScreen(characterId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 每个槽位带一行用途说明（玩家不查文档也懂槽位作用）
    expect(find.textContaining('常用输出'), findsOneWidget); // main1
    expect(find.textContaining('高内力爆发'), findsOneWidget); // ultimate
  });

  // ── autoFill 落库 test（真 Isar，跑屏幕进入时同一路径）────────────────────

  group('进入 autoFill 落库（resolver + service 同源路径）', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_cangjingge_af_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      await IsarSetup.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('有主修心法角色（5 槽全空）→ autoFill 后 mainSkillId1 落库非 null', () async {
      final isar = IsarSetup.instance;
      late int charId;
      await isar.writeTxn(() async {
        final c = Character.create(
          name: '测试弟子',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: mkAttrs(),
          rarity: RarityTier.xunChang,
          lineageRole: LineageRole.disciple,
          createdAt: DateTime(2026, 1, 1),
        );
        charId = await isar.characters.put(c);
        final tech = Technique.create(
          defId: mainTechDefId,
          ownerCharacterId: charId,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 1, 1),
        );
        final techId = await isar.techniques.put(tech);
        final updated = await isar.characters.get(charId);
        updated!.mainTechniqueId = techId;
        await isar.characters.put(updated);
      });

      // 屏幕 initState autoFill 同一路径：resolver 解析 + service 落库。
      final character = await isar.characters.get(charId);
      final numbers = GameRepository.instance.numbers;
      final sources = await SkillLoadoutResolver(isar: isar).resolve(
        character!,
        numbers: numbers,
      );
      await SkillLoadoutService(isar).applyAutoFill(
        characterId: charId,
        mainTechniqueSkills: sources.mainTechniqueSkills,
        assistTechniqueSkills: sources.assistTechniqueSkills,
        jointSkill: sources.jointSkill,
        ultimatePowerThreshold: numbers.loadoutUltimatePowerThreshold,
      );

      final after = await isar.characters.get(charId);
      expect(after?.mainSkillId1, isNotNull);
    });
  });
}
