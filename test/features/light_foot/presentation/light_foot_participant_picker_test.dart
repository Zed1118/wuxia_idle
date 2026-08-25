import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/light_foot/application/light_foot_participant_service.dart';
import 'package:wuxia_idle/features/light_foot/presentation/light_foot_participant_picker.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  Character character(int id, String name, {required bool founder}) =>
      Character.create(
        name: name,
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: founder ? LineageRole.founder : LineageRole.disciple,
        createdAt: DateTime.utc(2026, 8, 25),
      )..id = id;

  testWidgets('双视口展示禁用占用态并返回实际门人 ID', (tester) async {
    final candidates = [
      LightFootParticipantCandidate(
        character: character(1, '闭关掌门', founder: true),
        occupied: true,
        healing: false,
        hasMainTechnique: true,
      ),
      LightFootParticipantCandidate(
        character: character(2, '空闲门人', founder: false),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];

    for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(viewport);
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showLightFootParticipantPicker(
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
      expect(find.text(UiStrings.lightFootParticipantTitle), findsOneWidget);
      expect(find.text(UiStrings.lightFootParticipantOccupied), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('light_foot_participant_1')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('空闲门人'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
