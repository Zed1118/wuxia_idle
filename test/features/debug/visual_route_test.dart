import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  group('parseVisualRoute', () {
    test('已知 id → 对应枚举', () {
      expect(parseVisualRoute('main_menu'), VisualRoute.mainMenu);
      expect(parseVisualRoute('technique_panel_tier_all'),
          VisualRoute.techniquePanelTierAll);
      expect(parseVisualRoute('technique_panel_hero'),
          VisualRoute.techniquePanelHero);
      expect(parseVisualRoute('character_panel'),
          VisualRoute.characterPanelProfile);
      expect(parseVisualRoute('chapter_list'), VisualRoute.chapterList);
      expect(parseVisualRoute('battle_scene'), VisualRoute.battleScene);
    });

    test('未知 id → null', () {
      expect(parseVisualRoute('nope'), isNull);
    });

    test('空串 → null', () {
      expect(parseVisualRoute(''), isNull);
    });

    test('每个枚举 id 往返一致', () {
      for (final r in VisualRoute.values) {
        expect(parseVisualRoute(r.id), r);
      }
    });

    test('B2 新路由 parse', () {
      expect(parseVisualRoute('battle_ultimate_caption'),
          VisualRoute.battleUltimateCaption);
      expect(parseVisualRoute('battle_boss_frame'),
          VisualRoute.battleBossFrame);
    });
  });
}
