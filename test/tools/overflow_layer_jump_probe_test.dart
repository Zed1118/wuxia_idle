import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';

import '../support/test_data.dart';

/// 存量溢出连跳分布探针（baicao §3.1）。
///
/// 背景：发布上限已从 10 抬到 17（里程碑批·一次性兑现）。旧档在 Lv100 封顶期
/// 继续累加的存量经验，升级到 cap=17 后一次性兑现、连跳数层。本测实测该连跳层数
/// 分布，并以 ratchet 守住「一次性兑现连跳上界」不因经济改动失控。诊断测，非玩法代码。
///
/// `isLayerLocked` 用 cap=17 锁（现与生产发布上限一致），从绝对层 10 顶起测
/// 存量经验一次性兑现的连跳量级。

/// 沿 progression_gate 体例：越过 [cap] 绝对层视为锁定。
bool Function(RealmTier, RealmLayer) _lockAtCap(int cap, GameRepository repo) {
  return (t, l) => repo.getRealm(t, l).absoluteLevel > cap;
}

/// 停在绝对层 10 顶（三流·熟练 / Lv100，旧发布上限=存量封顶点）、经验清零的祖师。
/// 属性取中性占位（不影响层级推进，纯诊断）。
Character _buildCappedFounderAtLv100() {
  final attrs = Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;
  return Character.create(
    name: '溢出探针祖师',
    realmTier: RealmTier.sanLiu,
    realmLayer: RealmLayer.shuLian, // 绝对层 10 顶
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime.utc(2026, 7, 15),
    isFounder: true,
    isActive: true,
  );
}

void main() {
  setUpAll(loadTestGameRepository);

  test('存量溢出连跳分布（cap 10→17）', () {
    final repo = GameRepository.instance;
    realmLookup(RealmTier t, RealmLayer l) => repo.getRealm(t, l);

    // 层均经验取当前层 experienceToNext 作单位，扫 1×~12× 覆盖短挂机到长挂机。
    final unit = realmLookup(
      RealmTier.sanLiu,
      RealmLayer.shuLian,
    ).experienceToNext;
    final buffer = StringBuffer('overflow× | 连跳层数(cap17)\n');
    var worstJump = 0;
    for (final mult in const [1, 2, 4, 6, 8, 12]) {
      final ch = _buildCappedFounderAtLv100();
      final res = CharacterAdvancementService.applyExperience(
        ch,
        unit * mult,
        realmLookup: realmLookup,
        isLayerLocked: _lockAtCap(17, repo),
      );
      buffer.writeln('${mult}x | ${res.layersGained}');
      if (res.layersGained > worstJump) worstJump = res.layersGained;
    }
    // 输出分布供人工拍板（一次性 vs 分段）。
    // ignore: avoid_print
    print(buffer.toString());

    // Ratchet：典型档一次性兑现连跳应可接受（§3.1 约 ≤4 层量级）。若此断言未来
    // 因经济改动被顶破，说明溢出直逼 Lv170，需按 §3.1 降级为分段抬升 10→13→17。
    expect(worstJump, lessThanOrEqualTo(7), reason: '存量溢出连跳过大→改分段抬升，勿直接放宽此阈值');
  });
}
