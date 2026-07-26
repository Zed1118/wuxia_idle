import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/utils/asset_framing.dart';

void main() {
  test('四张离群场景均登记焦点与归一化安全区', () {
    const paths = [
      'assets/scenes/battle_cliffwaterfall.png',
      'assets/scenes/battle_mountain_pass_stage_v2.png',
      'assets/scenes/battle_mountain_pass_stage_cool_v3.png',
      'assets/scenes/sect_hall_main_v1.png',
    ];

    for (final path in paths) {
      final framing = assetFramingForScene(path);
      expect(framing, isNot(same(AssetFraming.centered)), reason: path);
      expect(framing.safeArea.left, inInclusiveRange(0, 1), reason: path);
      expect(framing.safeArea.top, inInclusiveRange(0, 1), reason: path);
      expect(framing.safeArea.right, inInclusiveRange(0, 1), reason: path);
      expect(framing.safeArea.bottom, inInclusiveRange(0, 1), reason: path);
      expect(
        framing.safeArea.contains(framing.focus),
        isTrue,
        reason: '$path 的主体焦点必须位于安全区内',
      );
    }
  });

  test('未登记场景保持居中裁切，不扩散改变既有画面', () {
    expect(
      assetFramingForScene('assets/scenes/battle_citywall.png'),
      same(AssetFraming.centered),
    );
    expect(AssetFraming.centered.alignment, Alignment.center);
  });

  test('生产纵向肖像登记上半身焦点，战斗透明站姿不参与', () {
    final portrait = assetFramingForPortrait(
      'assets/characters/sect_candidate_bamboo.png',
    );
    expect(portrait.focus.dy, lessThan(0.5));
    expect(portrait.alignment.y, lessThan(0));

    expect(
      assetFramingForPortrait('assets/characters/battle_first_disciple.png'),
      same(AssetFraming.centered),
    );
  });
}
