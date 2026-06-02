// ignore_for_file: avoid_print
//
// D 性能稳定性压测 · stress_test(2026-06-02)
//
// "8h+ 无 crash / 内存有界 / Isar IO 无 ANR" 的可自动化代理。挂机本身是闭关
// session 的 now-startedAt 时间差一次性结算(无后台 tick),故 8h 稳定性的真实
// 场景 = 长时间在线累积(GameEvent 堆积 / 极端时长结算)。
//
// 覆盖边界(Phase 0 侦察 + 亲验后收窄,只补真空白,不重复现有覆盖):
//   A · GameEvent 累积压测 —— 唯一真新覆盖(top 隐患:表无界增长)
//   B · 极端时长结算双防线(capHours 截断 + 产出 clamp)回归锚点
//   C · 连续战斗稳定性 —— 已由 balance_simulator_test(1000 场 runToEnd)覆盖,不重写
//   leak(资源 dispose)/ ANR(零同步 IO)—— 已由架构 + battle_screen 测覆盖
//
// 跑法:flutter test test/tools/stress_test.dart
// 输出:test/tools/output/stress_2026-06-02.md
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

const String _outputDir = 'test/tools/output';
final StringBuffer _report = StringBuffer();

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
    Directory(_outputDir).createSync(recursive: true);
    _report.writeln('# D 性能稳定性压测报告 · 2026-06-02\n');
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_stress_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  tearDownAll(() {
    File('$_outputDir/stress_2026-06-02.md')
        .writeAsStringSync(_report.toString());
    print(_report.toString());
  });

  // ───────────────────────────────────────────────────────────────────────
  // A · GameEvent 累积压测(top 隐患:表无界增长)
  //   验证 (1) 显示 feed limit20+occurredAt index 不退化
  //        (2) markAllFeedRead 大量未读时一次性 findAll+putAll 峰值
  // ───────────────────────────────────────────────────────────────────────
  test('A · GameEvent 累积 · 显示 feed 不退化 + markAllFeedRead 峰值量化',
      () async {
    final isar = IsarSetup.instance;
    _report.writeln('## A · GameEvent 累积压测\n');
    _report.writeln(
        '| N(未读) | 写入putAll | 显示feed(limit20) | markAllFeedRead | count |');
    _report.writeln('|---|---|---|---|---|');

    GameEvent mk(int i) => GameEvent()
      ..eventType = GameEventType.adventureTriggered
      ..title = '奇遇 #$i'
      ..summary = '压测事件 $i'
      ..relatedCharacterId = 1
      ..occurredAt = DateTime(2026, 1, 1).add(Duration(seconds: i))
      ..isRead = false;

    int feedLenAt10k = 0;
    for (final n in [100, 1000, 10000]) {
      await isar.writeTxn(() => isar.gameEvents.clear());

      final swWrite = Stopwatch()..start();
      await isar.writeTxn(
        () => isar.gameEvents.putAll([for (var i = 0; i < n; i++) mk(i)]),
      );
      swWrite.stop();

      // 显示 feed:home 屏高频路径(sortByOccurredAtDesc + limit 20 走 index)
      final swFeed = Stopwatch()..start();
      final feed = await isar.gameEvents
          .where()
          .sortByOccurredAtDesc()
          .limit(20)
          .findAll();
      swFeed.stop();

      // markAllFeedRead:快速领取按钮(filter 未读 findAll + putAll,低频)
      final swMark = Stopwatch()..start();
      final unread =
          await isar.gameEvents.filter().isReadEqualTo(false).findAll();
      for (final e in unread) {
        e.isRead = true;
      }
      await isar.writeTxn(() => isar.gameEvents.putAll(unread));
      swMark.stop();

      final total = await isar.gameEvents.count();
      _report.writeln(
          '| $n | ${swWrite.elapsedMilliseconds}ms | ${swFeed.elapsedMicroseconds}µs(${feed.length}条) | ${swMark.elapsedMilliseconds}ms | $total |');

      if (n == 10000) feedLenAt10k = feed.length;
      expect(feed.length, 20, reason: 'feed 应恒取满 20 条(N≥20)');
    }
    _report.writeln('');

    // 核心断言:显示 feed 在 10000 条下仍取满 20(index range 扫,不退化)
    expect(feedLenAt10k, 20);
  });

  // ───────────────────────────────────────────────────────────────────────
  // B · 极端时长结算双防线(回归锚点)
  //   防线1:actualHours = min(elapsed, planned, capHours) → 超长离线被截到 cap
  //   防线2:产出 .clamp(0, 999999) → 不溢出 int / 不负
  //   隔离法:固定 startedAt(solar/ziShi 同),变 now → 仅 actualHours 变量
  // ───────────────────────────────────────────────────────────────────────
  test('B · 极端时长 · capHours 截断 + 产出 clamp 双防线', () {
    final config = GameRepository.instance.numbers.retreat;
    final maps = GameRepository.instance.seclusionMaps;
    final cap = config.capHours; // 72

    // 固定起手时刻(普通日/非子时),planned 远超 cap
    final startedAt = DateTime(2026, 3, 15, 14, 0);
    RetreatSession session() => RetreatSession()
      ..saveDataId = 1
      ..mapType = RetreatMapType.duanYaJueBi // 武圣图(产出最高,最易触 clamp)
      ..durationHours = 999999
      ..startedAt = startedAt
      ..status = RetreatStatus.active;

    // 武圣满阶 scale 最大
    const tier = RealmTier.wuSheng;
    final atCap = SeclusionService.computeOutputs(
      session: session(),
      charRealmTier: tier,
      config: config,
      maps: maps,
      now: startedAt.add(Duration(hours: cap)), // elapsed = cap
    );
    final huge = SeclusionService.computeOutputs(
      session: session(),
      charRealmTier: tier,
      config: config,
      maps: maps,
      now: startedAt.add(const Duration(hours: 100000)), // elapsed >> cap
    );

    _report.writeln('## B · 极端时长结算双防线\n');
    _report.writeln('- capHours = $cap, 武圣阶, 断崖绝壁图');
    _report.writeln(
        '- elapsed=cap:   mojianshi=${atCap.mojianshi} exp=${atCap.experiencePoints} learn=${atCap.techniqueLearnPoints} 内力=${atCap.internalForcePoints}');
    _report.writeln(
        '- elapsed=100000h: mojianshi=${huge.mojianshi} exp=${huge.experiencePoints} learn=${huge.techniqueLearnPoints} 内力=${huge.internalForcePoints}\n');

    // 防线1:超长 elapsed 被 capHours 截断 → 与 elapsed=cap 产出完全相同
    expect(huge.mojianshi, atCap.mojianshi, reason: 'capHours 应截断超长离线');
    expect(huge.experiencePoints, atCap.experiencePoints);
    expect(huge.techniqueLearnPoints, atCap.techniqueLearnPoints);
    expect(huge.internalForcePoints, atCap.internalForcePoints);

    // 防线2:产出全部 ∈ [0, 999999](clamp 兜底,不溢出/不负)
    for (final v in [
      huge.mojianshi,
      huge.experiencePoints,
      huge.techniqueLearnPoints,
      huge.internalForcePoints,
    ]) {
      expect(v, inInclusiveRange(0, 999999));
    }
  });
}
