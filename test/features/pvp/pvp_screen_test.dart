import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/pvp/application/pvp_providers.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_record.dart';
import 'package:wuxia_idle/features/pvp/presentation/pvp_screen.dart';
import 'package:wuxia_idle/features/pvp/presentation/widgets/rank_badge_widget.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:yaml/yaml.dart';

/// R4/R5 测族(1.0 P3.3 §12.3 Phase 4 · spec §7)。
///
/// 覆盖:
///   1. PvpScreen locked 态(stage_05_05 未通)显锁定文案 + 无 match button
///   2. PvpScreen available 态(stage_05_05 已通)显 RankBadge + match button + history empty
///   3. PvpScreen tap match button → SnackBar 显 placeholder 文案
///   4. RankBadgeWidget ELO 7 阶段位映射边界值正确
///   5. PvpHistoryList 非空 records → 显胜/负标识
///   6. data/lore/pvp/pvp_event_first_blood.yaml schema 合法 + opening 非空 + 黑名单 0

MainlineProgress _progress({List<String> cleared = const []}) {
  return MainlineProgress()
    ..saveDataId = 1
    ..currentChapterIndex = 1
    ..clearedStageIds = List.of(cleared)
    ..clearedAt = List.generate(
      cleared.length,
      (_) => DateTime(2026, 5, 24),
    );
}

Widget _appWith({
  required MainlineProgress progress,
  int currentElo = 1200,
  List<PvpRecord> records = const [],
}) {
  return ProviderScope(
    overrides: [
      mainlineProgressProvider.overrideWith((ref) async => progress),
      currentPvpEloProvider.overrideWithValue(currentElo),
      pvpRecentRecordsProvider.overrideWithValue(records),
    ],
    child: const MaterialApp(home: PvpScreen()),
  );
}

void main() {
  group('PvpScreen 三态 + match button', () {
    testWidgets('locked: stage_05_05 未通 → 显锁定文案,无 match button',
        (tester) async {
      await tester.pumpWidget(_appWith(progress: _progress()));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.pvpLockedHint), findsOneWidget);
      expect(find.text(UiStrings.pvpMatchButton), findsNothing);
      expect(find.byType(RankBadgeWidget), findsNothing);
    });

    testWidgets(
        'available: stage_05_05 已通 → 显 RankBadge + match button + history empty',
        (tester) async {
      await tester.pumpWidget(_appWith(
        progress: _progress(cleared: const ['stage_05_05']),
      ));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.pvpLockedHint), findsNothing);
      expect(find.byType(RankBadgeWidget), findsOneWidget);
      expect(find.text(UiStrings.pvpMatchButton), findsOneWidget);
      expect(find.text(UiStrings.pvpHistoryEmpty), findsOneWidget);
      expect(find.text(UiStrings.pvpEloLabel(1200)), findsOneWidget);
    });

    testWidgets('tap match button → SnackBar 显 placeholder 文案', (tester) async {
      await tester.pumpWidget(_appWith(
        progress: _progress(cleared: const ['stage_05_05']),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(UiStrings.pvpMatchButton));
      await tester.pump();

      expect(find.text(UiStrings.pvpMatchPlaceholder), findsOneWidget);
    });
  });

  group('RankBadgeWidget ELO 7 阶段位映射', () {
    test('rankInfo 7 阶边界值正确(段窗 200)', () {
      expect(RankBadgeWidget.rankInfo(0).name, UiStrings.pvpRankXueTu);
      expect(RankBadgeWidget.rankInfo(999).name, UiStrings.pvpRankXueTu);
      expect(RankBadgeWidget.rankInfo(1000).name, UiStrings.pvpRankSanLiu);
      expect(RankBadgeWidget.rankInfo(1199).name, UiStrings.pvpRankSanLiu);
      expect(RankBadgeWidget.rankInfo(1200).name, UiStrings.pvpRankErLiu);
      expect(RankBadgeWidget.rankInfo(1399).name, UiStrings.pvpRankErLiu);
      expect(RankBadgeWidget.rankInfo(1400).name, UiStrings.pvpRankYiLiu);
      expect(RankBadgeWidget.rankInfo(1599).name, UiStrings.pvpRankYiLiu);
      expect(RankBadgeWidget.rankInfo(1600).name, UiStrings.pvpRankJueDing);
      expect(RankBadgeWidget.rankInfo(1799).name, UiStrings.pvpRankJueDing);
      expect(RankBadgeWidget.rankInfo(1800).name, UiStrings.pvpRankZongShi);
      expect(RankBadgeWidget.rankInfo(1999).name, UiStrings.pvpRankZongShi);
      expect(RankBadgeWidget.rankInfo(2000).name, UiStrings.pvpRankWuSheng);
      expect(RankBadgeWidget.rankInfo(2500).name, UiStrings.pvpRankWuSheng);
    });

    test('nextRankName: 武圣段返 null,其余返下一段名', () {
      expect(RankBadgeWidget.nextRankName(500), UiStrings.pvpRankSanLiu);
      expect(RankBadgeWidget.nextRankName(1200), UiStrings.pvpRankYiLiu);
      expect(RankBadgeWidget.nextRankName(1999), UiStrings.pvpRankWuSheng);
      expect(RankBadgeWidget.nextRankName(2000), isNull);
      expect(RankBadgeWidget.nextRankName(3000), isNull);
    });

    testWidgets('widget 渲染:武圣段显「已至段位之巅」,非武圣段显 pvpRankNext', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: RankBadgeWidget(currentElo: 2100)),
      ));
      expect(find.text(UiStrings.pvpRankWuSheng), findsOneWidget);
      expect(find.text(UiStrings.pvpRankTopHint), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: RankBadgeWidget(currentElo: 1250)),
      ));
      expect(find.text(UiStrings.pvpRankErLiu), findsOneWidget);
      expect(
        find.text(UiStrings.pvpRankNext(150, UiStrings.pvpRankYiLiu)),
        findsOneWidget,
      );
    });
  });

  group('PvpHistoryList 渲染胜负标识', () {
    testWidgets('records 非空 + winnerId == playerId → 显「胜」 + 正 ELO delta',
        (tester) async {
      final win = PvpRecord()
        ..matchId = 'test-1'
        ..playerId = 1
        ..opponentSnapshotId = 0
        ..leftSnapshotId = 0
        ..winnerId = 1
        ..playerEloBefore = 1200
        ..playerEloAfter = 1216
        ..eloDelta = 16
        ..timestamp = DateTime(2026, 5, 24, 10, 30);
      final loss = PvpRecord()
        ..matchId = 'test-2'
        ..playerId = 1
        ..opponentSnapshotId = 0
        ..leftSnapshotId = 0
        ..winnerId = -10001
        ..playerEloBefore = 1216
        ..playerEloAfter = 1200
        ..eloDelta = -16
        ..timestamp = DateTime(2026, 5, 24, 11, 0);

      await tester.pumpWidget(_appWith(
        progress: _progress(cleared: const ['stage_05_05']),
        records: [win, loss],
      ));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.pvpHistoryWin), findsOneWidget);
      expect(find.text(UiStrings.pvpHistoryLoss), findsOneWidget);
      expect(find.text(UiStrings.pvpHistoryEloDelta(16)), findsOneWidget);
      expect(find.text(UiStrings.pvpHistoryEloDelta(-16)), findsOneWidget);
      expect(find.text(UiStrings.pvpHistoryEmpty), findsNothing);
    });
  });

  group('narrative yaml schema(R4)', () {
    test('pvp_event_first_blood.yaml schema 合法 + opening 非空 + 黑名单 0',
        () async {
      final file = File('data/lore/pvp/pvp_event_first_blood.yaml');
      expect(file.existsSync(), isTrue,
          reason: 'Phase 4 stub yaml 必须存在(spec §6)');
      final raw = await file.readAsString();
      final y = loadYaml(raw) as YamlMap;

      expect(y['id'], 'pvp_event_first_blood', reason: 'id 与文件名严格相等');
      final trigger = y['trigger'] as YamlMap;
      expect(trigger['kind'], 'first_match_won',
          reason: 'Phase 5 narrative trigger enum 起点');
      expect((y['title'] as String).trim().isNotEmpty, isTrue);
      final opening = (y['opening'] as String).trim();
      expect(opening.isNotEmpty, isTrue, reason: 'opening 非空');
      expect((y['text_on_rank_up'] as String).trim().isNotEmpty, isTrue);

      // 文风黑名单沿 Ch4-6 narrative 体例(无网游词)
      const blacklist = ['霸气', '逆天', '史诗', '神级', '吊打'];
      for (final w in blacklist) {
        expect(opening.contains(w), isFalse, reason: '黑名单词「$w」不应出现');
      }
    });
  });
}
