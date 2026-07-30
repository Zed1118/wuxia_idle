class BattlePouchPreviewItem {
  const BattlePouchPreviewItem({required this.assetPath, required this.count});

  final String assetPath;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is BattlePouchPreviewItem &&
      other.assetPath == assetPath &&
      other.count == count;

  @override
  int get hashCode => Object.hash(assetPath, count);
}

class BattleScreenPlaybackConfig {
  const BattleScreenPlaybackConfig({
    this.autoStart = true,
    this.allowPlayerIntervention = false,
    this.startPaused = false,
    this.startFastForward = false,
    this.readablePacing = false,
    this.autoStartOnMount = false,
    this.firstClearShowcase = false,
    this.previewPouchItems = const [],
    this.previewHeaderControls = false,
  });

  const BattleScreenPlaybackConfig.sweep()
    : autoStart = true,
      allowPlayerIntervention = false,
      startPaused = false,
      startFastForward = true,
      readablePacing = false,
      autoStartOnMount = true,
      firstClearShowcase = false,
      previewPouchItems = const [],
      previewHeaderControls = false;

  final bool autoStart;
  final bool allowPlayerIntervention;
  final bool startPaused;
  final bool startFastForward;
  final bool readablePacing;
  final bool autoStartOnMount;

  /// Debug/visual preview only. Empty by default so production battles never
  /// imply that an item is equipped before the pouch has real domain wiring.
  final List<BattlePouchPreviewItem> previewPouchItems;

  /// Debug golden-frame only: keep playback frozen while presenting the
  /// production "暂停 / 撤退" control set instead of "继续 / 单步".
  final bool previewHeaderControls;

  /// 首通脚本化展示帧(玩法评估 §十三 #2):开局亮相/首技慢镜/敌方首次蓄力
  /// 提示/破招题字强化,整场各一次,纯表现层。主线入口与 readablePacing 同
  /// 门控(本场为该 (stageId, cycle) 首通);扫荡等复刷路径恒 false。
  final bool firstClearShowcase;
}
