import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

/// seedVisualCheckShenwuDrop 战力红线：满配 wuSheng 出阵队必须打赢 stage_06_04，
/// 否则 Codex 进不去胜利掉落弹窗（V3 神物金验收）会 BLOCKED——首版 seed 只 boost
/// 境界标签未拉满内力/装备/心法，实机打输，本测即为防回退。
///
/// 红线语义（memory feedback_red_line_test_semantics）：断言「玩家胜」约束关系，
/// 不写具体 tick/血量。多个 rng seed 全胜 → 战力裕度足够稳。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_shenwu_drop_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance)
        .seedVisualCheckShenwuDrop();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  for (final seed in [1, 42, 99, 2026]) {
    test('满配出阵队打赢 stage_06_04（rng=$seed）→ 触发胜利掉落', () async {
      final stage = GameRepository.instance.getStage('stage_06_04');
      final (left, right) =
          await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
      final numbers = GameRepository.instance.numbers;
      final finalState = BattleEngine.runToEnd(
        BattleState.initial(leftTeam: left, rightTeam: right),
        numbers,
        rng: Random(seed),
      );
      expect(finalState.result, BattleResult.leftWin,
          reason: '满配 wuSheng 队须碾压 stage_06_04 的 zongShi 3 敌人；'
              '失败=seed 战力不足，Codex 验收会卡在战斗');
    });
  }
}
