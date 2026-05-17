import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/tower/application/leaderboard_sync_service.dart';

/// P0.2 #40 Phase 3:LeaderboardSyncService 抽象接口 + NoopLeaderboardSync 契约。
///
/// 方案 D 决议 placeholder:Demo 阶段 0 backend / 0 network call,Noop 仅满足契约。
/// 接 Supabase 时新建 SupabaseLeaderboardSync 实现并替换 leaderboardSyncProvider 注入。
///
/// 红线 test 锚约束语义不锚瞬时事实(memory feedback_red_line_test_semantics 实践):
/// ① reportClear 不抛 ② 0 副作用(此处用「连调 100 次仍不抛」断言) ③ 接口签名 4 字段稳定。
void main() {
  group('NoopLeaderboardSync', () {
    test('reportClear 调用不抛(满足 LeaderboardSyncService 契约)', () async {
      const sync = NoopLeaderboardSync();
      await expectLater(
        sync.reportClear(
          highestFloor: 15,
          bestClearTimeMs: 30000,
          totalAttempts: 25,
          clearedAt: DateTime(2026, 5, 17, 14, 30),
        ),
        completes,
        reason: 'Noop 实现必须 Future complete 不抛,否则破 victory hook unawaited 路径',
      );
    });

    test('reportClear 接受边界值(highestFloor=0 / bestClearTimeMs=null / totalAttempts=0)',
        () async {
      const sync = NoopLeaderboardSync();
      // 全新存档边界:0 通关 / null 最佳耗时(Noop 不报错)
      await expectLater(
        sync.reportClear(
          highestFloor: 0,
          bestClearTimeMs: null,
          totalAttempts: 0,
          clearedAt: DateTime(2026, 5, 17),
        ),
        completes,
        reason: '边界值不应抛 — LeaderboardSyncService 契约要求接受所有合法字段',
      );
    });

    test('连调 100 次仍不抛(0 副作用约束)', () async {
      const sync = NoopLeaderboardSync();
      for (var i = 1; i <= 100; i++) {
        await sync.reportClear(
          highestFloor: i % 30 + 1,
          bestClearTimeMs: i * 100,
          totalAttempts: i,
          clearedAt: DateTime(2026, 5, 17).add(Duration(seconds: i)),
        );
      }
      // 无 expect 抛即为通过(0 副作用 = 没有任何状态在 Noop 内累积可观察)
    });
  });

  group('LeaderboardSyncService 接口契约', () {
    test('可被 fake 实现覆写(为 widget test 注入 backend 替身预留)', () async {
      // 验证抽象接口是可实现的(future-proof:接 Supabase 时同套路新建 class implements)
      final fake = _RecordingLeaderboardSync();
      await fake.reportClear(
        highestFloor: 5,
        bestClearTimeMs: 12000,
        totalAttempts: 8,
        clearedAt: DateTime(2026, 5, 17),
      );
      expect(fake.reportedClears, hasLength(1));
      expect(fake.reportedClears.first.highestFloor, 5);
      expect(fake.reportedClears.first.bestClearTimeMs, 12000);
      expect(fake.reportedClears.first.totalAttempts, 8);
    });
  });
}

/// 测试用 fake(LeaderboardSyncService 替身),记录每次 reportClear 参数。
/// 类比未来 SupabaseLeaderboardSync 的实装套路(implements LeaderboardSyncService)。
class _RecordingLeaderboardSync implements LeaderboardSyncService {
  final List<({int highestFloor, int? bestClearTimeMs, int totalAttempts, DateTime clearedAt})>
      reportedClears = [];

  @override
  Future<void> reportClear({
    required int highestFloor,
    required int? bestClearTimeMs,
    required int totalAttempts,
    required DateTime clearedAt,
  }) async {
    reportedClears.add((
      highestFloor: highestFloor,
      bestClearTimeMs: bestClearTimeMs,
      totalAttempts: totalAttempts,
      clearedAt: clearedAt,
    ));
  }
}
