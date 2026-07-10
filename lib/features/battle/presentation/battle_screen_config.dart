class BattleScreenPlaybackConfig {
  const BattleScreenPlaybackConfig({
    this.autoStart = true,
    this.allowPlayerIntervention = false,
    this.startPaused = false,
    this.startFastForward = false,
    this.readablePacing = false,
    this.autoStartOnMount = false,
  });

  const BattleScreenPlaybackConfig.sweep()
    : autoStart = true,
      allowPlayerIntervention = false,
      startPaused = false,
      startFastForward = true,
      readablePacing = false,
      autoStartOnMount = true;

  final bool autoStart;
  final bool allowPlayerIntervention;
  final bool startPaused;
  final bool startFastForward;
  final bool readablePacing;
  final bool autoStartOnMount;
}
