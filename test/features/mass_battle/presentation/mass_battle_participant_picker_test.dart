import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/mass_battle/application/mass_battle_participant_service.dart';
import 'package:wuxia_idle/features/mass_battle/presentation/mass_battle_participant_picker.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  Character character(int id, String name) => Character.create(
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: id == 1 ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime.utc(2026, 8, 25),
  )..id = id;

  testWidgets('展示禁用占用态并返回实际守城参与者 ID', (tester) async {
    final candidates = [
      MassBattleParticipantCandidate(
        character: character(1, '占用掌门'),
        occupied: true,
        healing: false,
        hasMainTechnique: true,
      ),
      MassBattleParticipantCandidate(
        character: character(2, '空闲门人'),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];
    int? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showMassBattleParticipantPicker(
                  context: context,
                  candidates: candidates,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.massBattleParticipantTitle), findsOneWidget);
    expect(find.text(UiStrings.massBattleParticipantOccupied), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('mass_battle_participant_1')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('空闲门人'));
    await tester.pumpAndSettle();

    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
