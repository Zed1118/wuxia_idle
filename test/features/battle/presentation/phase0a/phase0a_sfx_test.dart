import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_sfx.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';
import '../../../../support/test_data.dart';
import 'phase0a_terminal_test_driver.dart';

/// Phase 0A Batch 9A 音效接线红测(plan §验收):
/// - 纯映射:普攻双边变体/暴击/大招/Q/R/死亡静默/波次终局静默;
/// - 接线:真 fixture 整屏,事件流逐条对应录制后端,终局后零音效。
///
/// 只用磁盘已有资产的既有槽位;death 静默是冻结决策(资产不存在),
/// 若将来接 battleDeath 资产,本文件静默断言需同步翻转。
void main() {
  group('phase0aSfxAssetForEvent 纯映射', () {
    Phase0aHitLanded hit({
      String actor = 'player',
      bool isCritical = false,
      bool isUltimate = false,
    }) => Phase0aHitLanded(
      seq: 1,
      tick: 1,
      actor: actor,
      target: 'wave1_blade',
      moveKind: Phase0aMoveKind.light,
      isCritical: isCritical,
      isUltimate: isUltimate,
      resolvedDamage: 100,
      remainingHealth: 900,
    );

    test('普攻命中按出手方选边:玩家 0 / 敌方 1', () {
      expect(
        phase0aSfxAssetForEvent(hit(actor: 'player'), playerId: 'player'),
        'audio/sfx/battleHit_0_0.mp3',
      );
      expect(
        phase0aSfxAssetForEvent(hit(actor: 'wave1_blade'), playerId: 'player'),
        'audio/sfx/battleHit_1_0.mp3',
      );
    });

    test('暴击/大招优先级高于普通命中(对齐 sfxForAction)', () {
      expect(
        phase0aSfxAssetForEvent(hit(isCritical: true), playerId: 'player'),
        'audio/sfx/battleCrit.mp3',
      );
      expect(
        phase0aSfxAssetForEvent(hit(isUltimate: true), playerId: 'player'),
        'audio/sfx/battleUlt.mp3',
      );
      expect(
        phase0aSfxAssetForEvent(
          hit(isCritical: true, isUltimate: true),
          playerId: 'player',
        ),
        'audio/sfx/battleUlt.mp3',
      );
    });

    test('Q 聚怪起手 = battleChargeStart;R 清场起手 = battleUlt', () {
      expect(
        phase0aSfxAssetForEvent(
          const Phase0aGatherStarted(seq: 1, tick: 1, actor: 'player'),
          playerId: 'player',
        ),
        'audio/sfx/battleChargeStart.mp3',
      );
      expect(
        phase0aSfxAssetForEvent(
          const Phase0aClearStarted(seq: 1, tick: 1, actor: 'player'),
          playerId: 'player',
        ),
        'audio/sfx/battleUlt.mp3',
      );
    });

    test('终局 jingle:victory → victory / defeat → defeat(9B 落地)', () {
      expect(
        phase0aSfxAssetForEvent(
          const Phase0aBattleVictory(seq: 5, tick: 1),
          playerId: 'player',
        ),
        'audio/sfx/victory.mp3',
      );
      expect(
        phase0aSfxAssetForEvent(
          const Phase0aBattleDefeat(seq: 6, tick: 1),
          playerId: 'player',
        ),
        'audio/sfx/defeat.mp3',
      );
    });

    test('死亡/波次事件静默(battleDeath 无资产)', () {
      const silent = <Phase0aEvent>[
        Phase0aEnemyDefeated(
          seq: 1,
          tick: 1,
          target: 'wave1_blade',
          defeatKind: Phase0aDefeatKind.normal,
        ),
        Phase0aEnemyDefeated(
          seq: 2,
          tick: 1,
          target: 'wave2_elite',
          defeatKind: Phase0aDefeatKind.elite,
        ),
        Phase0aWaveStarted(seq: 3, tick: 1, waveIndex: 0, waveTotal: 2),
        Phase0aWaveCleared(seq: 4, tick: 1, waveIndex: 0),
      ];
      for (final event in silent) {
        expect(
          phase0aSfxAssetForEvent(event, playerId: 'player'),
          isNull,
          reason: '$event 不应映射音效',
        );
      }
    });
  });

  group('Phase0aBattleScreen 音效接线', () {
    late Phase0aDebugBattleFixture fixture;
    late Phase0aBattleController controller;
    late _RecordingAudioBackend backend;
    late SoundManager previous;

    setUp(() async {
      await loadTestGameRepository();
      fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
      );
      controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
      backend = _RecordingAudioBackend();
      previous = SoundManager.instance;
      SoundManager.instance = SoundManager(backend);
    });

    tearDown(() {
      SoundManager.instance = previous;
      GameRepository.resetForTest();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: Phase0aBattleScreen(controller: controller)),
      );
      await tester.pump();
    }

    /// 每次手动 step 后,录制路径必须与该步事件流的映射逐值相等
    /// (不依赖具体伤害/暴击结果,只依赖事件本身)。
    Future<void> stepAndExpectSfx(
      WidgetTester tester, [
      Phase0aPlayerCommand? command,
    ]) async {
      final before = backend.sfxPaths.length;
      final events = controller.step(command);
      await tester.pump();
      final expected = phase0aSfxAssetsForFrame(
        events,
        playerId: controller.state.player.id,
      );
      expect(
        backend.sfxPaths.sublist(before),
        expected,
        reason: 'step 事件音效须与映射逐值对应',
      );
    }

    testWidgets('普攻/Q/R 各触发映射资产恰好一次,死亡静默', (tester) async {
      await pumpScreen(tester);

      // 逼近并普攻至首次玩家命中,期间每步校验映射。
      var sawPlayerHit = false;
      for (var i = 0; i < 200 && !sawPlayerHit; i++) {
        await stepAndExpectSfx(
          tester,
          const Phase0aPlayerCommand(attack: true, right: true),
        );
        sawPlayerHit = controller.lastEvents.any(
          (e) => e is Phase0aHitLanded && e.actor == controller.state.player.id,
        );
      }
      expect(sawPlayerHit, isTrue, reason: '200 拍内玩家应至少命中一次');
      // 玩家命中的音效须与事件本身映射一致(暴击则 battleCrit,不假设普通命中)。
      final playerHit = controller.lastEvents
          .whereType<Phase0aHitLanded>()
          .first;
      expect(
        backend.sfxPaths,
        contains(
          phase0aSfxAssetForEvent(
            playerHit,
            playerId: controller.state.player.id,
          ),
        ),
      );

      await stepAndExpectSfx(tester, const Phase0aPlayerCommand(gather: true));
      expect(backend.sfxPaths, contains('audio/sfx/battleChargeStart.mp3'));

      await stepAndExpectSfx(tester, const Phase0aPlayerCommand(clear: true));
      expect(backend.sfxPaths, contains('audio/sfx/battleUlt.mp3'));

      // 死亡静默:整局打到 victory,录制里不得出现 battleDeath。
      for (var i = 0; i < 2000; i++) {
        if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
        await stepAndExpectSfx(
          tester,
          phase0aVictoryTerminalCommand(controller),
        );
      }
      expect(controller.outcome, Phase0aBattleOutcome.victory);
      expect(backend.sfxPaths.where((p) => p.contains('battleDeath')), isEmpty);
      expect(
        backend.sfxPaths.where((p) => p == 'audio/sfx/victory.mp3').length,
        1,
        reason: '胜利 jingle 应恰好播放一次(9B)',
      );

      // 终局后 step 零事件零音效。
      final total = backend.sfxPaths.length;
      await stepAndExpectSfx(tester, const Phase0aPlayerCommand(attack: true));
      expect(backend.sfxPaths.length, total);
    });
  });
}

class _RecordingAudioBackend implements AudioBackend {
  final List<String> sfxPaths = <String>[];

  @override
  Future<void> playBgm(String assetPath, double volume) async {}

  @override
  Future<void> stopBgm() async {}

  @override
  void setBgmVolume(double volume) {}

  @override
  Future<void> playSfx(String assetPath, double volume) async {
    sfxPaths.add(assetPath);
  }

  @override
  Future<void> dispose() async {}
}
