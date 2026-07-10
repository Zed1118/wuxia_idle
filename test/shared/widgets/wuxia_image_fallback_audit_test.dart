import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  void expectContract(String path, List<String> fragments) {
    final contents = source(path);
    final anchor = fragments.first;
    final anchorIndex = contents.lastIndexOf(anchor);
    expect(anchorIndex, isNonNegative, reason: '$path 缺少关键图片锚点: $anchor');
    final end = (anchorIndex + 1200).clamp(0, contents.length);
    final callSite = contents.substring(anchorIndex, end);
    for (final fragment in fragments.skip(1)) {
      expect(
        callSite,
        contains(fragment),
        reason: '$path 的关键业务图片必须保留稳定且可诊断的 fallback: $fragment',
      );
    }
  }

  test('关键 WuxiaImage 调用均有显式业务 fallback', () {
    const contracts = <String, List<String>>{
      'lib/features/main_menu/presentation/main_menu.dart': [
        'WuxiaUi.mainMenuBg',
        'errorBuilder: wuxiaAssetErrorBuilder(',
      ],
      'lib/features/mainline/presentation/chapter_transition_screen.dart': [
        'chapterCoverPath(chapterIndex)',
        'errorBuilder: wuxiaAssetErrorBuilder(',
      ],
      'lib/features/mainline/presentation/chapter_list_screen.dart': [
        'chapterCoverPath(chapterIndex)',
        'errorBuilder: wuxiaAssetErrorBuilder(',
      ],
      'lib/features/mainline/presentation/stage_list_screen.dart': [
        'chapterCoverPath(chapterIndex)',
        'errorBuilder:',
        'Container(color: WuxiaColors.avatarFill)',
      ],
      'lib/shared/widgets/portrait_frame.dart': [
        'portraitPath!',
        'errorBuilder: wuxiaAssetErrorBuilder(',
      ],
      'lib/shared/widgets/equipment_art_image.dart': [
        'imagePath',
        'errorBuilder: wuxiaAssetErrorBuilder(() => fallback)',
      ],
      'lib/features/shop/presentation/shop_screen.dart': [
        "'assets/images/items/\${def.itemDefId}.png'",
        'errorBuilder: wuxiaAssetErrorBuilder(',
        '_ShopFallbackIcon(def: def)',
      ],
      'lib/features/taohua_island/presentation/taohua_island_screen.dart': [
        '_taohuaIslandMapAsset',
        'errorBuilder:',
        'CustomPaint(painter: _IslandScenePainter())',
      ],
    };

    for (final entry in contracts.entries) {
      expectContract(entry.key, entry.value);
    }
  });
}
