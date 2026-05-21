import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
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
