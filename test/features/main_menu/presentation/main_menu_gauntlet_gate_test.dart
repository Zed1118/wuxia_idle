import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// #1 wiring Task 6：主菜单断魂庄入口门控（§5.7 隐藏式·同江湖远行 gate）。
/// `SaveData.jianghuJourneyUnlocked` 为真才显断魂庄入口（onTap→GauntletLoadoutScreen），
/// 未解锁隐藏。gate 经 [mainMenuSaveSnapshotProvider]（无 Isar 返 null → 未解锁）。
void main() {
  testWidgets('断魂庄入口：jianghuJourneyUnlocked=true → 显示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainMenuSaveSnapshotProvider.overrideWith(
            (ref) async => SaveData()..jianghuJourneyUnlocked = true,
          ),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    // 让 snapshot future 落定 + 门控重建（不用 pumpAndSettle·避真 async 撞挂）。
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('断魂庄入口：未解锁（默认）→ 隐藏', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainMenu())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
