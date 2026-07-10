import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      unawaited(maybeShowOfflineRecap(context: context, ref: ref));
      unawaited(maybeRunSectMonthlyTick(ref));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
