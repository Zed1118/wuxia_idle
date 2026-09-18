/// 排行榜同步抽象(P0.2 #40 Phase 3)。
///
/// **方案 D 决议**(2026-05-17,详 `docs/handoff/p0_40_local_leaderboard_spec.md` §3):
/// Demo 阶段不接 Supabase backend(0 supabase 包 / 0 network call),
/// 但保留抽象接口 future-proof — 未来升 Pro plan 接入时新建
/// `SupabaseLeaderboardSync implements LeaderboardSyncService` 并替换
/// provider 注入,**0 victory hook 改动**。
///
/// 接口携带 3 项指标(highest_layer / best_clear_time / total_attempts)
/// + 时间锚 clearedAt。原 numbers.yaml `tower.leaderboard` 段 2026-09-18 已删
/// (B2 复核 5A T-A,零读方),指标集以本接口签名为唯一事实源。
abstract class LeaderboardSyncService {
  /// 上报一次首通(victory hook 内调用)。
  ///
  /// 实现端负责节流(节流间隔由实现端自定,当前 Noop 实现无网络请求),
  /// 即便短时间内多次调用也只发 1 次真实请求。
  Future<void> reportClear({
    required int highestFloor,
    required int? bestClearTimeMs,
    required int totalAttempts,
    required DateTime clearedAt,
  });
}

/// Noop 实现(D 方案下默认注入)。
///
/// 0 副作用 / 0 network call,只满足接口契约。Demo 阶段排行榜全本地化
/// (LeaderboardScreen 直接读 TowerProgress 真源),此服务调用纯为
/// future-proof,不影响业务路径。
class NoopLeaderboardSync implements LeaderboardSyncService {
  const NoopLeaderboardSync();

  @override
  Future<void> reportClear({
    required int highestFloor,
    required int? bestClearTimeMs,
    required int totalAttempts,
    required DateTime clearedAt,
  }) async {
    // intentionally noop
  }
}
