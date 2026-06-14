import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime(2026, 1, 1)
    ..status = RetreatStatus.active;

  Future<bool> pumpGuard(
    WidgetTester tester, {
    required RetreatSession? session,
  }) async {
    var allowed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => guardBattleEntry(
                  context: context,
                  ref: ref,
                  onAllowed: () => allowed = true,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return allowed;
  }

  testWidgets('无 active session → onAllowed 调用、无拦截弹窗', (tester) async {
    final allowed = await pumpGuard(tester, session: null);
    expect(allowed, isTrue);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsNothing);
  });

  testWidgets('有 active session → 拦截弹窗、onAllowed 不调用', (tester) async {
    final allowed = await pumpGuard(tester, session: fakeSession());
    expect(allowed, isFalse);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsOneWidget);
    expect(find.text(UiStrings.seclusionBattleLockEndEarly), findsOneWidget);
  });
}
