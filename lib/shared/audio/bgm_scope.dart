import 'package:flutter/widgets.dart';
import 'audio_assets.dart';
import 'sound_manager.dart';

/// 声明式 BGM 作用域：挂载即切到 [track]（同轨 no-op）。无中央路由表。
///
/// 内部维护 scope 栈：push 路由时新 scope 入栈顶接管轨道；pop 时栈顶
/// dispose 出栈，自动切回新栈顶 scope 的轨道（战斗页退回主菜单 →
/// 主菜单 BGM 恢复）。
class BgmScope extends StatefulWidget {
  const BgmScope({super.key, required this.track, required this.child});
  final BgmTrack track;
  final Widget child;

  @override
  State<BgmScope> createState() => _BgmScopeState();
}

class _BgmScopeState extends State<BgmScope> {
  /// 活跃 scope 栈（挂载序）。push 路由先 init 新 scope（入栈顶），
  /// pop 时 dispose 出栈并恢复新栈顶轨道。
  static final List<_BgmScopeState> _stack = [];

  @override
  void initState() {
    super.initState();
    _stack.add(this);
    SoundManager.instance.playBgm(widget.track);
  }

  @override
  void didUpdateWidget(BgmScope old) {
    super.didUpdateWidget(old);
    // 仅栈顶 scope 的轨道变更才切歌，背景 scope 改 track 不抢占。
    if (old.track != widget.track && identical(_stack.last, this)) {
      SoundManager.instance.playBgm(widget.track);
    }
  }

  @override
  void dispose() {
    final wasTop = _stack.isNotEmpty && identical(_stack.last, this);
    _stack.remove(this);
    if (wasTop && _stack.isNotEmpty) {
      SoundManager.instance.playBgm(_stack.last.widget.track);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
