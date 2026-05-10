import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/ui/battle/battle_demo.dart';
import 'package:wuxia_idle/ui/battle/battle_screen.dart';
import 'package:wuxia_idle/ui/battle/character_avatar.dart';

/// T14 静态布局 smoke test：BattleScreen 用 BattleDemo mock 状态渲染不崩，
/// 6 个角色全部出现，标题反映存活人数（左 3 / 右 2，因 demo 右队 #2 已死）。
///
/// 窗口锁 1280×720（phase1_tasks T14 §791 16:9 验收基线，desktop 默认尺寸）。
/// flutter_test 默认 800×600 太窄会触发 Column overflow，与生产环境无关。
void main() {
  Future<void> pumpBattle(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: BattleScreen(state: BattleDemo.build()),
      ),
    );
  }

  testWidgets('BattleScreen 渲染 3v3 + 顶栏 + 6 个 CharacterAvatar',
      (WidgetTester tester) async {
    await pumpBattle(tester);

    // 顶栏标题：左 3 活 / 右 2 活
    expect(find.text('战斗 3 v 2'), findsOneWidget);

    // 6 个 CharacterAvatar
    expect(find.byType(CharacterAvatar), findsNWidgets(6));

    // 角色名字渲染（左队角色名同时出现在头像下方与底栏大招按钮里 = 2 次；
    // 右队仅在头像下方 = 1 次）。
    expect(find.text('萧夜寒'), findsNWidgets(2));
    expect(find.text('黑风寨主'), findsOneWidget);
    expect(find.text('毒娘子'), findsOneWidget);
  });

  testWidgets('死亡角色 opacity = 0.3', (WidgetTester tester) async {
    await pumpBattle(tester);

    // demo 右队 #2「毒娘子」isAlive=false，CharacterAvatar 内层 Opacity=0.3
    final avatars = tester.widgetList<CharacterAvatar>(
      find.byType(CharacterAvatar),
    );
    final dead = avatars.where((a) => !a.character.isAlive).toList();
    expect(dead.length, 1);

    // 找该角色 subtree 里的 Opacity，验 opacity 值
    final deadAvatarFinder = find.byWidgetPredicate(
      (w) => w is CharacterAvatar && !w.character.isAlive,
    );
    final opacity = tester
        .widgetList<Opacity>(
          find.descendant(of: deadAvatarFinder, matching: find.byType(Opacity)),
        )
        .first;
    expect(opacity.opacity, 0.3);
  });
}
