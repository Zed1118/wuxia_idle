import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
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
    canInterrupt: ci);

Widget _host(List<MartialCodexGroup> groups) => ProviderScope(
      overrides: [martialCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: MartialArtsTab())),
    );

void main() {
  testWidgets('混态:点亮显名 + 剪影显??? + 进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      MartialCodexGroup(
        kind: MartialGroupKind.trueSolution,
        subGroups: [
          MartialCodexSubGroup(entries: [
            MartialCodexEntry(
                def: _s('a', SkillSource.mainlineDrop), isLit: true),
            MartialCodexEntry(
                def: _s('b', SkillSource.mainlineDrop), isLit: false),
          ]),
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
          MartialCodexSubGroup(entries: [
            MartialCodexEntry(
                def: _s('b', SkillSource.mainlineDrop), isLit: false),
          ]),
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
    await tester.pumpWidget(MaterialApp(
      home: SkillCodexDetailScreen(def: def, maxStage: null),
    ));
    await tester.pumpAndSettle();
    expect(find.text('po_shi名'), findsOneWidget);
    expect(find.text('d'), findsOneWidget);
    expect(find.textContaining('1000'), findsWidgets);
    expect(find.text(UiStrings.skillCodexProficiencyNone), findsOneWidget);
  });
}
