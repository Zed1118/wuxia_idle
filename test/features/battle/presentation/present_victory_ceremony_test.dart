import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';

void main() {
  testWidgets('GameRepository 未加载 → presentVictoryCeremony 走简版勝',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => presentVictoryCeremony(
                context,
                const DropResult(equipments: [], items: []),
                treasureGate: true,
              ),
              child: const Text('go'),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(VictorySealFlash), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byType(VictorySealFlash), findsNothing);
  });

  testWidgets('treasureGate=false 也走简版勝(塔重打档)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => presentVictoryCeremony(
                context,
                const DropResult(equipments: [], items: []),
                treasureGate: false,
              ),
              child: const Text('go'),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(VictorySealFlash), findsOneWidget);
  });
}
