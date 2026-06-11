import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';

void main() {
  test('bgmAssetPath 拼接正确', () {
    expect(bgmAssetPath(BgmTrack.mainMenu), 'audio/bgm/mainMenu.mp3');
    expect(bgmAssetPath(BgmTrack.battle), 'audio/bgm/battle.mp3');
  });

  test('sfxAssetPath 拼接正确', () {
    expect(sfxAssetPath(SfxId.uiTap), 'audio/sfx/uiTap.mp3');
    expect(sfxAssetPath(SfxId.battleCrit), 'audio/sfx/battleCrit.mp3');
  });

  test('全枚举值都能拼出非空路径', () {
    for (final t in BgmTrack.values) {
      expect(bgmAssetPath(t), startsWith('audio/bgm/'));
    }
    for (final s in SfxId.values) {
      expect(sfxAssetPath(s), startsWith('audio/sfx/'));
    }
  });

  test('battleHit 6 变体素材文件齐全（缺文件运行期静默 no-op，靠本测兜底）', () {
    for (final side in [0, 1]) {
      for (final slot in [0, 1, 2]) {
        final p =
            'assets/${battleHitAssetPath(teamSide: side, slotIndex: slot)}';
        expect(File(p).existsSync(), isTrue, reason: '缺素材文件: $p');
      }
    }
  });
}
