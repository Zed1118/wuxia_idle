import '../domain/sweep_recap.dart';

/// 扫荡终态枚举。
enum SweepStatus {
  /// 连播中。
  running,

  /// 全部关扫完。
  completed,

  /// 用户中途停止（当前关打完后）。
  stoppedByUser,

  /// 某关战败 halt（停在该关）。
  stoppedByDefeat,
}

/// 扫荡驱动状态机（纯逻辑，无 widget 依赖）。
///
/// [SweepScreen] 逐关托管真战斗，每场结束把胜负 + 战果喂进来；本控制器决定
/// 前进 / 收工 / 用户停 / 战败 halt，并累加 [SweepRecap]。
///
/// 用户拍板：可中途停（停在当前关打完）/ 战败停在该关报告 / 恒重打不触首通。
class SweepController {
  /// 本次扫荡总关数（章内关数 / 塔层数）。
  final int totalUnits;

  int _index = 0;
  SweepRecap _recap = const SweepRecap.empty();
  SweepStatus _status = SweepStatus.running;
  bool _stopRequested = false;

  SweepController({required this.totalUnits});

  /// 当前待打关 index（0-based）。战败时即「卡在第 index+1 关」。
  int get currentIndex => _index;

  /// 累计战果总账。
  SweepRecap get recap => _recap;

  SweepStatus get status => _status;

  bool get isRunning => _status == SweepStatus.running;

  /// 用户请求停止（当前关打完后生效，不打断进行中的战斗）。
  void requestStop() => _stopRequested = true;

  /// 一关胜利结算后调用：累加战果 → 前进 → 判收工 / 用户停。
  void recordVictory(SweepBattleOutcome outcome) {
    if (_status != SweepStatus.running) return;
    _recap = _recap.accumulate(outcome);
    _index++;
    if (_index >= totalUnits) {
      _status = SweepStatus.completed;
    } else if (_stopRequested) {
      _status = SweepStatus.stoppedByUser;
    }
  }

  /// 一关战败：halt，停在该关（[currentIndex] 即失败关）。
  void recordDefeat() {
    if (_status != SweepStatus.running) return;
    _status = SweepStatus.stoppedByDefeat;
  }
}
