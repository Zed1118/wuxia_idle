import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_preview_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 第八阶段 C·悬停预览浮层内容 widget 测。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });
  tearDownAll(GameRepository.resetForTest);

  DropRumorTable emptyTable() => DropRumorTable.fromDropTable(
        const <DropEntry>[],
        gating: FirstClearGating.scrollOnly,
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );
  }

  testWidgets('显推荐境界 + 难度徽章(玩家低 1 阶 → 偏高)', (tester) async {
    await pump(
      tester,
      StagePreviewContent(
        recommendedRealm: RealmTier.erLiu,
        rumorTable: emptyTable(),
        playerRealm: RealmTier.sanLiu,
      ),
    );
    expect(find.textContaining(UiStrings.previewRecommendedRealmLabel),
        findsOneWidget);
    expect(find.text(UiStrings.difficultyRisky), findsOneWidget); // 偏高
  });

  testWidgets('playerRealm=null → 不显难度徽章,仅推荐境界', (tester) async {
    await pump(
      tester,
      StagePreviewContent(
        recommendedRealm: RealmTier.erLiu,
        rumorTable: emptyTable(),
      ),
    );
    expect(find.textContaining(UiStrings.previewRecommendedRealmLabel),
        findsOneWidget);
    expect(find.text(UiStrings.difficultyRisky), findsNothing);
    expect(find.text(UiStrings.difficultySuitable), findsNothing);
  });

  testWidgets('玩家高于推荐 → 碾压徽章', (tester) async {
    await pump(
      tester,
      StagePreviewContent(
        recommendedRealm: RealmTier.sanLiu,
        rumorTable: emptyTable(),
        playerRealm: RealmTier.yiLiu,
      ),
    );
    expect(find.text(UiStrings.difficultyComfortable), findsOneWidget);
  });

  testWidgets('StagePreviewHoverCard:鼠标悬停 → 浮层出现,移出 → 收起', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StagePreviewHoverCard(
              preview: StagePreviewContent(
                recommendedRealm: RealmTier.erLiu,
                rumorTable: emptyTable(),
                playerRealm: RealmTier.sanLiu,
              ),
              child: const SizedBox(width: 80, height: 30, child: Text('关卡')),
            ),
          ),
        ),
      ),
    );
    // 初始不显浮层。
    expect(find.text(UiStrings.difficultyRisky), findsNothing);

    final gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('关卡')));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.difficultyRisky), findsOneWidget); // 浮层出现

    await gesture.moveTo(const Offset(500, 500)); // 移出
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.difficultyRisky), findsNothing); // 收起
  });
}
