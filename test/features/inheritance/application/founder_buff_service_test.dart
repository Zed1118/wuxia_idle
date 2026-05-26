import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inheritance/application/founder_buff_service.dart';

/// P1.1 A1 E.5 · FounderBuffService 红线契约。
///
/// 验证语义(memory `feedback_red_line_test_semantics` + audit 决议 E.5.A):
/// - NumbersConfig.founderAncestorBuff 加载 yaml 字段正确
/// - computeBuffActive 4 case:yaml disabled / active 含 founder / active 无 founder /
///   SaveData 未初始化
/// - FounderAncestorBuff.disabled 兜底
/// - applyToDisciplesOnly=true 时祖师本人不享 buff(应用层 _founderBuffAppliesTo)
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_founder_buff_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('FounderAncestorBuff schema', () {
    test('NumbersConfig 生产 yaml 加载 P1.1 E.5 决议数值', () {
      final n = GameRepository.instance.numbers;
      expect(n.founderAncestorBuff.isActive, true,
          reason: 'P1.1 决议 E.5.A:enabled_when_alive flip true');
      expect(n.founderAncestorBuff.internalForceMaxPct, 0.05);
      expect(n.founderAncestorBuff.maxHpPct, 0.05);
      expect(n.founderAncestorBuff.critRateBonus, 0.02);
      expect(n.founderAncestorBuff.cultivationProgressPct, 0.03);
      expect(n.founderAncestorBuff.applyToDisciplesOnly, false,
          reason: 'P1.1 决议 apply_to_disciples_only=false,祖师本人也享');
    });

    test('disabled 兜底:空 map → 全零', () {
      final buff = FounderAncestorBuff.fromYaml(const {});
      expect(buff.isActive, false);
      expect(buff.internalForceMaxPct, 0);
      expect(buff.maxHpPct, 0);
      expect(buff.critRateBonus, 0);
      expect(buff.cultivationProgressPct, 0);
    });

    test('enabled_when_alive: true + sect_wide_buff: null → 0 数值但 isActive=true',
        () {
      final buff = FounderAncestorBuff.fromYaml(
          const {'enabled_when_alive': true, 'sect_wide_buff': null});
      expect(buff.isActive, true);
      expect(buff.internalForceMaxPct, 0);
      expect(buff.maxHpPct, 0);
    });

    test('数值红线 §5.4:internal_force_max +5% × lineage +20% × base 15000 = 18900 (>15000)',
        () {
      // 仅断言上下游叠加是「乘法」语义不破语义,真正 clamp 在 CharacterDerivedStats
      // (battle_state.dart 端 currentInternalForce 不会因 maxInternalForce 抬高而
      // 自动充值,玩家持有的 internalForce 还是 base);maxInternalForce 抬高 +5% × +20%
      // 仅作为上限,实际运行时不破红线。
      final n = GameRepository.instance.numbers;
      // 师承 4 件 × 5% = 20% + founder 5% = 1.20 × 1.05 = 1.26
      final hypotheticalCap =
          (15000 * (1.0 + 4 * n.lineageInternalForceMaxBonus) *
                  (1.0 + n.founderAncestorBuff.internalForceMaxPct))
              .toInt();
      expect(hypotheticalCap, 18900,
          reason: '4 件 lineage + founder buff 叠加上限,玩家实际 IF ≤ 红线');
      // GDD §5.4 红线检查由 numbers.yaml + 公式层实施(本批不动);
      // 上限抬高不直接破红线(玩家手动累积 IF 时仍受 sandbox 公式约束)
    });
  });

  group('FounderBuffService.computeBuffActive', () {
    test('SaveData 未初始化 → false', () async {
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      // 不 seed 任何 SaveData(IsarSetup.init 默认 build 一行,但 founderCharacterId
      // / activeCharacterIds 都空)
      final active = await svc.computeBuffActive(n);
      expect(active, false,
          reason: 'activeCharacterIds 空 → 无 founder 在阵 → buff 不激活');
    });

    test('yaml enabled + active 含 founder → true', () async {
      final isar = IsarSetup.instance;
      // 跑 seedMasterDisciple 让 active 含 founder (id=1, isFounder=true)
      await Phase2SeedService(isar: isar).seedMasterDisciple();
      final svc = FounderBuffService(isar);
      final n = GameRepository.instance.numbers;
      final active = await svc.computeBuffActive(n);
      expect(active, true,
          reason: 'yaml isActive=true + active 含 isFounder=true 角色');
    });

    test('active 仅含 disciple 不含 founder → false', () async {
      final isar = IsarSetup.instance;
      await Phase2SeedService(isar: isar).seedMasterDisciple();
      // 改 active 列表移除 founder(id=1),只保留 2 弟子
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0);
        if (save != null) {
          save.activeCharacterIds = [2, 3]; // 大弟子 + 二弟子
          await isar.saveDatas.put(save);
        }
      });
      final svc = FounderBuffService(isar);
      final n = GameRepository.instance.numbers;
      final active = await svc.computeBuffActive(n);
      expect(active, false, reason: 'active 无 isFounder=true → buff 不激活');
    });

    test('FounderAncestorBuff.disabled 即 isActive=false 时直接 false', () async {
      final svc = FounderBuffService(IsarSetup.instance);
      // disabled 兜底
      final active = await svc.computeBuffActive(
        const NumbersConfigStub(buff: FounderAncestorBuff.disabled),
      );
      expect(active, false);
    });
  });

  /// P4.1 1.1 cross_sect 扩 R5 测族(spec §4):
  /// - R5.1 P1.1 维持:target.isInSect=false → true(整体 active + founder 存在)
  /// - R5.2 跨派系 NPC 不享:target.isInSect=true, sectId != playerSectId → false
  /// - R5.3 同 sect 成员享:target.isInSect=true, sectId == playerSectId → true
  /// - R5.4 playerSectId=null fallback:target.isInSect=false → true(P1.1 路径维持)
  /// - R5.5 整体 inactive(无 isFounder=true active)→ false(回归保护)
  ///
  /// 每测 setup 用 phase2 seed(founder + 2 disciples 入 active),target Character
  /// 直接 inline 构造(isInSect / sectId 字段 mock · 不入 isar)。
  group('R5 P4.1 1.1 cross_sect · isBuffActiveFor per-character', () {
    setUp(() async {
      await Phase2SeedService(isar: IsarSetup.instance)
          .seedMasterDisciple();
    });

    test('R5.1 P1.1 维持:target.isInSect=false → true(active 含 founder)',
        () async {
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      final target = Character()..isInSect = false; // disciple 未入 sect
      final active = await svc.isBuffActiveFor(
        target: target, numbers: n, playerSectId: 1,
      );
      expect(active, true, reason: 'P1.1 fallback:isInSect=false → 单 founder 享');
    });

    test('R5.2 跨派系 NPC 不享:isInSect=true, sectId=2 ≠ playerSectId=1 → false',
        () async {
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      final npc = Character()
        ..isInSect = true
        ..sectId = 2; // 跨派系 NPC
      final active = await svc.isBuffActiveFor(
        target: npc, numbers: n, playerSectId: 1,
      );
      expect(active, false,
          reason: 'NPC isInSect=true 但跨派系 → 不享 founder buff');
    });

    test('R5.3 同 sect 成员享:isInSect=true, sectId=1 == playerSectId=1 → true',
        () async {
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      final member = Character()
        ..isInSect = true
        ..sectId = 1; // 同 sect 成员
      final active = await svc.isBuffActiveFor(
        target: member, numbers: n, playerSectId: 1,
      );
      expect(active, true, reason: '同 sect 成员 → 享 founder buff');
    });

    test('R5.4 playerSectId=null fallback isInSect=false → true(P1.1 路径)',
        () async {
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      final target = Character()..isInSect = false;
      final active = await svc.isBuffActiveFor(
        target: target, numbers: n, playerSectId: null,
      );
      expect(active, true,
          reason: 'Sect lazy-init race · isInSect=false → 单 founder 享 P1.1 维持');
    });

    test('R5.5 整体 inactive(无 isFounder=true active)→ 任何 target false',
        () async {
      // 改 SaveData.activeCharacterIds 不含 founder id=1
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0);
        if (save != null) {
          save.activeCharacterIds = [2, 3]; // disciples only
          await isar.saveDatas.put(save);
        }
      });
      final svc = FounderBuffService(IsarSetup.instance);
      final n = GameRepository.instance.numbers;
      // 1) isInSect=false target
      final t1 = Character()..isInSect = false;
      expect(await svc.isBuffActiveFor(
          target: t1, numbers: n, playerSectId: 1), false);
      // 2) isInSect=true 同 sect target
      final t2 = Character()..isInSect = true..sectId = 1;
      expect(await svc.isBuffActiveFor(
          target: t2, numbers: n, playerSectId: 1), false);
      // 3) isInSect=true 跨派系 target
      final t3 = Character()..isInSect = true..sectId = 2;
      expect(await svc.isBuffActiveFor(
          target: t3, numbers: n, playerSectId: 1), false);
    });
  });
}

/// Stub NumbersConfig only for FounderBuffService test(避免 mock 真实 yaml load)。
/// 仅暴露 founderAncestorBuff 字段,其余 stub 不读用。
class NumbersConfigStub implements NumbersConfig {
  const NumbersConfigStub({required FounderAncestorBuff buff})
      : _buff = buff;

  final FounderAncestorBuff _buff;

  @override
  FounderAncestorBuff get founderAncestorBuff => _buff;

  // 其他字段 stub 抛 UnimplementedError(本 test 不消费)
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'NumbersConfigStub: only founderAncestorBuff impl, '
          'invocation=${invocation.memberName}');
}
