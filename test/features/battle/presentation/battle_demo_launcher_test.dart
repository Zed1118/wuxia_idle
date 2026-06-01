import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

void main() {
  testWidgets('BattleDemoLauncher 把 sceneBackgroundPath 传给 BattleScreen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: BattleDemoLauncher(
            sceneBackgroundPath: 'assets/scenes/battle_citywall.png'),
      ),
    ));
    await tester.pump(); // let initState postFrame run startBattle
    final bs = tester.widget<BattleScreen>(find.byType(BattleScreen));
    expect(bs.sceneBackgroundPath, 'assets/scenes/battle_citywall.png');
  });
}
