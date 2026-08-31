import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expedition/application/expedition_startup.dart';
import '../../expedition/application/journey_unlock.dart';
import '../../progressive_unlock/application/progressive_unlock_providers.dart';
import '../../progressive_unlock/presentation/progressive_unlock_seal.dart';
import '../../seclusion/presentation/offline_recap_gate.dart';
import '../../sect/application/sect_providers.dart';

/// 主菜单首帧启动工作的稳定生命周期边界。
class MainMenuStartupGate extends ConsumerStatefulWidget {
  const MainMenuStartupGate({
    super.key,
    required this.child,
    this.progressiveUnlockObserver,
  });

  final Widget child;
  final Future<void> Function(BuildContext context, WidgetRef ref)?
  progressiveUnlockObserver;

  @override
  ConsumerState<MainMenuStartupGate> createState() =>
      _MainMenuStartupGateState();
}

class _MainMenuStartupGateState extends ConsumerState<MainMenuStartupGate> {
  bool _initialUnlockObservationFinished = false;
  String? _lastUnlockObservationSignature;
  Future<void> _unlockObservationQueue = Future<void>.value();

  Future<void> _observeProgressiveUnlocks() =>
      widget.progressiveUnlockObserver?.call(context, ref) ??
      observeCurrentProgressiveUnlocks(context: context, ref: ref);

  void _queueProgressiveUnlockObservation() {
    _unlockObservationQueue = _unlockObservationQueue.then((_) async {
      if (!mounted) return;
      await _observeProgressiveUnlocks();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        runMainMenuStartupSequence(
          offlineRecap: maybeShowOfflineRecap(context: context, ref: ref),
          monthlyTick: maybeRunSectMonthlyTick(ref),
          expeditionSettlement: maybeSettleExpedition(ref),
          journeyUnlock: maybeUnlockJianghuJourney(ref),
          observeProgressiveUnlocks: () async {
            if (!mounted) return;
            await _observeProgressiveUnlocks();
            if (!mounted) return;
            _lastUnlockObservationSignature = ref
                .read(currentProgressiveUnlockObservationProvider)
                .value
                ?.signature;
            setState(() => _initialUnlockObservationFinished = true);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProgressiveUnlockObservationProvider, (previous, next) {
      if (!_initialUnlockObservationFinished ||
          next is! AsyncData<CurrentProgressiveUnlockObservation?>) {
        return;
      }
      final signature = next.value?.signature;
      if (signature == null || signature == _lastUnlockObservationSignature) {
        return;
      }
      _lastUnlockObservationSignature = signature;
      _queueProgressiveUnlockObservation();
    });
    return widget.child;
  }
}

/// Existing startup writers remain concurrent. U11 observes only after every
/// writer has settled so a same-frame journey unlock cannot be missed.
Future<void> runMainMenuStartupSequence({
  required Future<void> offlineRecap,
  required Future<void> monthlyTick,
  required Future<void> expeditionSettlement,
  required Future<void> journeyUnlock,
  required Future<void> Function() observeProgressiveUnlocks,
}) async {
  await Future.wait([
    offlineRecap,
    monthlyTick,
    expeditionSettlement,
    journeyUnlock,
  ]);
  await observeProgressiveUnlocks();
}
