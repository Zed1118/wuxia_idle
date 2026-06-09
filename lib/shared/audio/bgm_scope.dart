import 'package:flutter/widgets.dart';
import 'audio_assets.dart';
import 'sound_manager.dart';

/// 声明式 BGM 作用域：挂载即切到 [track]（同轨 no-op）。无中央路由表。
class BgmScope extends StatefulWidget {
  const BgmScope({super.key, required this.track, required this.child});
  final BgmTrack track;
  final Widget child;

  @override
  State<BgmScope> createState() => _BgmScopeState();
}

class _BgmScopeState extends State<BgmScope> {
  @override
  void initState() {
    super.initState();
    SoundManager.instance.playBgm(widget.track);
  }

  @override
  void didUpdateWidget(BgmScope old) {
    super.didUpdateWidget(old);
    if (old.track != widget.track) {
      SoundManager.instance.playBgm(widget.track);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
