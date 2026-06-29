import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/dedicated_audio_assets.dart';

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

  test('已接线 SfxId 素材文件齐全（battleDeath 为 YAGNI 留位排除；缺文件运行期静默 no-op，靠本测兜底）', () {
    for (final s in SfxId.values) {
      if (s == SfxId.battleDeath) continue; // YAGNI 留位不接线，无专属素材
      final p = 'assets/${sfxAssetPath(s)}';
      expect(File(p).existsSync(), isTrue, reason: '缺 SFX 素材文件: $p');
    }
  });

  test('battleUlt / battleChargeStart 文件存在不等于专属素材已完成', () {
    expect(
      dedicatedSfxStatusFor(SfxId.battleUlt)!.readiness,
      DedicatedAudioAssetReadiness.temporaryBorrowed,
    );
    expect(
      dedicatedSfxStatusFor(SfxId.battleChargeStart)!.readiness,
      DedicatedAudioAssetReadiness.temporaryBorrowed,
    );
  });

  group('bgmTrackForStage 路由', () {
    test('类型轨：massBattle/innerDemon/lightFoot/tower 用同名轨（含 Boss 层）', () {
      expect(
        bgmTrackForStage(StageType.massBattle, isBoss: false),
        BgmTrack.massBattle,
      );
      expect(
        bgmTrackForStage(StageType.innerDemon, isBoss: true),
        BgmTrack.innerDemon,
      );
      expect(
        bgmTrackForStage(StageType.lightFoot, isBoss: false),
        BgmTrack.lightFoot,
      );
      expect(bgmTrackForStage(StageType.tower, isBoss: true), BgmTrack.tower);
    });

    test('mainline：Boss 关切 boss 轨，普通关用 mainline 轨', () {
      expect(
        bgmTrackForStage(StageType.mainline, isBoss: false),
        BgmTrack.mainline,
      );
      expect(bgmTrackForStage(StageType.mainline, isBoss: true), BgmTrack.boss);
    });

    test('全 StageType 都有映射（无 fallthrough）', () {
      for (final t in StageType.values) {
        expect(bgmTrackForStage(t, isBoss: false), isA<BgmTrack>());
        expect(bgmTrackForStage(t, isBoss: true), isA<BgmTrack>());
      }
    });
  });

  test('BGM 8 轨 + 基础 3 轨素材文件齐全（缺文件运行期 no-op，靠本测兜底）', () {
    for (final t in BgmTrack.values) {
      final p = 'assets/${bgmAssetPath(t)}';
      expect(File(p).existsSync(), isTrue, reason: '缺 BGM 素材文件: $p');
    }
  });
}
