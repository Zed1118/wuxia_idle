import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/baike/application/martial_codex_provider.dart';
import 'package:wuxia_idle/features/baike/presentation/martial_arts_tab.dart';
import 'package:wuxia_idle/features/baike/presentation/skill_codex_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

SkillDef _s(String id, SkillSource src, {bool ci = false}) => SkillDef(
  id: id,
  name: '$id名',
  description: 'd',
  type: SkillType.powerSkill,
  powerMultiplier: 1000,
  internalForceCost: 10,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
  source: src,
  canInterrupt: ci,
);

TechniqueDef _t(
  String id,
  TechniqueTier tier, {
  TechniqueSchool school = TechniqueSchool.gangMeng,
  List<String> skillIds = const [],
  List<String> sourceTags = const ['starter'],
}) => TechniqueDef(
  id: id,
  name: '$id心法',
  tier: tier,
  school: school,
  description: '$id描述',
  skillIds: skillIds,
  internalForceGrowthBonus: 1,
  speedBonus: 0,
  acquireSourceTags: sourceTags,
);

Widget _host(List<MartialCodexGroup> groups) => ProviderScope(
  overrides: [martialCodexProvider.overrideWith((ref) async => groups)],
  child: const MaterialApp(home: Scaffold(body: MartialArtsTab())),
);

Widget _techHost({
  required List<TechniqueCodexGroup> allGroups,
  List<TechniqueCodexGroup> filteredGroups = const [],
}) => ProviderScope(
  overrides: [
    martialCodexProvider.overrideWith((ref) async => const []),
    techniqueCodexProvider(
      tierFilter: null,
    ).overrideWith((ref) async => allGroups),
    techniqueCodexProvider(
      tierFilter: TechniqueTier.mingJiaGong,
    ).overrideWith((ref) async => filteredGroups),
  ],
  child: const MaterialApp(home: Scaffold(body: MartialArtsTab())),
);

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  tearDownAll(GameRepository.resetForTest);

  testWidgets('混态:点亮显名 + 剪影显??? + 进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      MartialCodexGroup(
        kind: MartialGroupKind.trueSolution,
        subGroups: [
          MartialCodexSubGroup(
            entries: [
              MartialCodexEntry(
                def: _s('a', SkillSource.mainlineDrop),
                isLit: true,
              ),
              MartialCodexEntry(
                def: _s('b', SkillSource.mainlineDrop),
                isLit: false,
              ),
            ],
          ),
        ],
        litCount: 1,
        totalCount: 2,
      ),
    ];
    await tester.pumpWidget(_host(groups));
    await tester.pumpAndSettle();
    expect(find.text('a名'), findsOneWidget);
    expect(find.text(UiStrings.skillCodexLocked), findsOneWidget);
    expect(find.text(UiStrings.skillCodexProgress(1, 2)), findsOneWidget);
  });

  testWidgets('空态:全未点亮不甩剪影墙', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      MartialCodexGroup(
        kind: MartialGroupKind.trueSolution,
        subGroups: [
          MartialCodexSubGroup(
            entries: [
              MartialCodexEntry(
                def: _s('b', SkillSource.mainlineDrop),
                isLit: false,
              ),
            ],
          ),
        ],
        litCount: 0,
        totalCount: 1,
      ),
    ];
    await tester.pumpWidget(_host(groups));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.skillCodexEmpty), findsOneWidget);
    expect(find.text(UiStrings.skillCodexLocked), findsNothing);
  });

  testWidgets('详情屏同步显 招名+description+倍率+未练', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final def = _s('po_shi', SkillSource.special, ci: true);
    await tester.pumpWidget(
      MaterialApp(home: SkillCodexDetailScreen(def: def, maxStage: null)),
    );
    await tester.pumpAndSettle();
    expect(find.text('po_shi名'), findsOneWidget);
    expect(find.text('d'), findsOneWidget);
    expect(find.textContaining('1000'), findsWidgets);
    expect(find.text(UiStrings.skillCodexProficiencyNone), findsOneWidget);
  });

  testWidgets('详情屏已练:显示熟练度当前效果、下阶效果和来源', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final def = _s('po_shi', SkillSource.special, ci: true);
    final stage = GameRepository.instance.numbers.skillProficiency.stages[2];

    await tester.pumpWidget(
      MaterialApp(home: SkillCodexDetailScreen(def: def, maxStage: stage)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('招式熟练 · po_shi名'), findsOneWidget);
    expect(find.textContaining('当前 伤害 +'), findsOneWidget);
    expect(find.textContaining('下阶 伤害 +'), findsOneWidget);
    expect(
      find.textContaining(UiStrings.cangjingProficiencySourceCombat),
      findsOneWidget,
    );
  });

  testWidgets('心法页:切换后渲染列表、境界限制和来源', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entry = TechniqueCodexEntry(
      def: _t('basic', TechniqueTier.ruMenGong, skillIds: const ['s1']),
      requiredRealmTier: RealmTier.xueTu,
      skills: [_s('s1', SkillSource.technique)],
    );
    await tester.pumpWidget(
      _techHost(
        allGroups: [
          TechniqueCodexGroup(tier: TechniqueTier.ruMenGong, entries: [entry]),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.skillCodexSectionTechniques));
    await tester.pumpAndSettle();

    expect(find.text('basic心法'), findsOneWidget);
    expect(find.textContaining('学徒'), findsOneWidget);
    await tester.tap(find.text('basic心法'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.techniqueCodexDetailTitle), findsOneWidget);
    expect(find.text('开局传授'), findsOneWidget);
    expect(find.text('s1名'), findsOneWidget);
  });

  testWidgets('心法页:按品阶筛选', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final allEntry = TechniqueCodexEntry(
      def: _t('basic', TechniqueTier.ruMenGong),
      requiredRealmTier: RealmTier.xueTu,
      skills: const [],
    );
    final filteredEntry = TechniqueCodexEntry(
      def: _t('mingjia', TechniqueTier.mingJiaGong),
      requiredRealmTier: RealmTier.erLiu,
      skills: const [],
    );
    await tester.pumpWidget(
      _techHost(
        allGroups: [
          TechniqueCodexGroup(
            tier: TechniqueTier.ruMenGong,
            entries: [allEntry],
          ),
          TechniqueCodexGroup(
            tier: TechniqueTier.mingJiaGong,
            entries: [filteredEntry],
          ),
        ],
        filteredGroups: [
          TechniqueCodexGroup(
            tier: TechniqueTier.mingJiaGong,
            entries: [filteredEntry],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.skillCodexSectionTechniques));
    await tester.pumpAndSettle();
    expect(find.text('basic心法'), findsOneWidget);
    expect(find.text('mingjia心法'), findsOneWidget);

    await tester.tap(find.text('名家功').first);
    await tester.pumpAndSettle();
    expect(find.text('basic心法'), findsNothing);
    expect(find.text('mingjia心法'), findsOneWidget);
  });
}
