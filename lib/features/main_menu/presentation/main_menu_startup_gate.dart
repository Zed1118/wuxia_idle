import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expedition/application/expedition_startup.dart';
import '../../expedition/application/journey_unlock.dart';
import '../../seclusion/presentation/offline_recap_gate.dart';
import '../../sect/application/sect_providers.dart';

/// 主菜单首帧启动工作的稳定生命周期边界。
class MainMenuStartupGate extends ConsumerStatefulWidget {
  const MainMenuStartupGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainMenuStartupGate> createState() =>
      _MainMenuStartupGateState();
}

class _MainMenuStartupGateState extends ConsumerState<MainMenuStartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 四项保持并发，避免 offline recap dialog 阻塞其他启动维护；其中会写
      // SaveData 的离线结算、远行解锁均在各自 writeTxn 内重读当前行，禁止
      // 事务外旧快照 put 覆盖并发字段。
      unawaited(maybeShowOfflineRecap(context: context, ref: ref));
      unawaited(maybeRunSectMonthlyTick(ref));
      unawaited(maybeSettleExpedition(ref));
      unawaited(maybeUnlockJianghuJourney(ref));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
