import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/online_presence_controller.dart';

/// App 生命周期 → [OnlinePresenceController] 接线(体检 P0-3)。
/// 原 main.dart `_recordOnline`(只 touch 不结算)由此取代:
/// 失焦停心跳+终 touch,聚焦结算失焦窗口+恢复心跳。
class OnlinePresenceLifecycleHook extends ConsumerStatefulWidget {
  const OnlinePresenceLifecycleHook({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnlinePresenceLifecycleHook> createState() =>
      _OnlinePresenceLifecycleHookState();
}

class _OnlinePresenceLifecycleHookState
    extends ConsumerState<OnlinePresenceLifecycleHook> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onShow: _onFocused,
      onResume: _onFocused,
      onHide: _onBlurred,
      onInactive: _onBlurred,
      onDetach: _onBlurred,
    );
  }

  void _onFocused() =>
      ref.read(onlinePresenceControllerProvider).onAppFocused();

  void _onBlurred() =>
      ref.read(onlinePresenceControllerProvider).onAppBlurred();

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
