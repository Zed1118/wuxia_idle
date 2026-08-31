import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_startup_gate.dart';
import 'package:wuxia_idle/features/progressive_unlock/application/progressive_unlock_providers.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';

void main() {
  test(
    'progressive unlock observation waits for all existing startup writers',
    () async {
      final recap = Completer<void>();
      final monthly = Completer<void>();
      final expedition = Completer<void>();
      final journey = Completer<void>();
      var unlockRan = false;

      final run = runMainMenuStartupSequence(
        offlineRecap: recap.future,
        monthlyTick: monthly.future,
        expeditionSettlement: expedition.future,
        journeyUnlock: journey.future,
        observeProgressiveUnlocks: () async {
          unlockRan = true;
        },
      );

      recap.complete();
      monthly.complete();
      expedition.complete();
      await Future<void>.delayed(Duration.zero);
      expect(unlockRan, isFalse, reason: '远行解锁写入前不得观察旧快照');

      journey.complete();
      await run;
      expect(unlockRan, isTrue);
    },
  );

  testWidgets(
    'provider refresh while main menu stays mounted re-observes unlocks',
    (tester) async {
      var generation = 0;
      final refresh = Provider<int>((ref) => generation);
      var observations = 0;
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProgressiveUnlockObservationProvider.overrideWith((
              ref,
            ) async {
              final observedGeneration = ref.watch(refresh);
              return CurrentProgressiveUnlockObservation(
                saveDataId: 1,
                snapshot: ProgressiveUnlockSnapshot({
                  for (final id in ProgressiveUnlockId.values)
                    id:
                        observedGeneration == 1 &&
                            id == ProgressiveUnlockId.lightFoot
                        ? ProgressiveUnlockState.open
                        : ProgressiveUnlockState.hidden,
                }),
              );
            }),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return MainMenuStartupGate(
                  progressiveUnlockObserver: (context, ref) async {
                    observations += 1;
                  },
                  child: const SizedBox(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(observations, 1, reason: '启动写入完成后执行一次基线观察');

      generation = 1;
      container.invalidate(refresh);
      await tester.pumpAndSettle();
      expect(observations, 2, reason: '主菜单未重建也必须响应生产事实刷新');
    },
  );
}
