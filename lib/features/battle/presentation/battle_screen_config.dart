class BattleScreenPlaybackConfig {
  const BattleScreenPlaybackConfig({
    this.autoStart = true,
    this.allowPlayerIntervention = false,
    this.startPaused = false,
    this.startFastForward = false,
    this.readablePacing = false,
    this.autoStartOnMount = false,
    this.firstClearShowcase = false,
  });

  const BattleScreenPlaybackConfig.sweep()
    : autoStart = true,
      allowPlayerIntervention = false,
      startPaused = false,
      startFastForward = true,
      readablePacing = false,
      autoStartOnMount = true,
      firstClearShowcase = false;

  final bool autoStart;
  final bool allowPlayerIntervention;
  final bool startPaused;
  final bool startFastForward;
  final bool readablePacing;
  final bool autoStartOnMount;

  /// 首通脚本化展示帧(玩法评估 §十三 #2):开局亮相/首技慢镜/敌方首次蓄力
  /// 提示/破招题字强化,整场各一次,纯表现层。主线入口与 readablePacing 同
  /// 门控(本场为该 (stageId, cycle) 首通);扫荡等复刷路径恒 false。
  final bool firstClearShowcase;
}
