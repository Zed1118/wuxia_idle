/// 月度 tick 协调器(1.0 P3.4 §12.1 Batch 2.2 引入)。
///
/// **最简 infra**:本 Phase 只接 1 callsite stub(SectEventService.checkAndTrigger),
/// Phase 4 wire 到 Riverpod 系统时间锚时落真触发(每月第 1 天 / 用户进 sect screen
/// 时检查)。
///
/// **不动现有 game loop / battle tick**(那是 in-battle 实时 tick,本协调器是
/// 跨月度长周期 tick,完全独立)。
class MonthlyTickCoordinator {
  /// 注册的 tick callback(Phase 4 加 SectEventService + SectReputationDecay 等)。
  final List<MonthlyTickCallback> _callbacks = [];

  /// 已注册 callback 数量(用于测断言)。
  int get registeredCount => _callbacks.length;

  void register(MonthlyTickCallback cb) => _callbacks.add(cb);

  /// 触发一次月度 tick(caller 决定时机)。
  /// 顺序保证:按 register 顺序串行调,各 cb 异常不阻塞后续。
  Future<void> tick(DateTime now) async {
    for (final cb in _callbacks) {
      try {
        await cb(now);
      } catch (_) {
        // 单 cb 异常吞掉 · log 留 Phase 4 接 logger 时落
      }
    }
  }

  /// 测试用 · 重置 callback 列表
  void clear() => _callbacks.clear();
}

typedef MonthlyTickCallback = Future<void> Function(DateTime now);
