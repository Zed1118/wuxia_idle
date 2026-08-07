import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/application/master_builder.dart';

/// 稀有度档位派生红线(GDD §4.1:六档 = 四项属性总点数的标签)。
///
/// 背景:2026-08-07 前三处角色创建点把 rarity 写死成 biaoZhun,导致全仓 18 个
/// 角色定义中 16 个标签与实际总点数不符(如 24 点的 bamboo_swordsman 应为「绝世」、
/// 17 点的 second_disciple 应为「庸才」,全被标成「标准」)。本测锁住两件事:
///   ① 档位必须由总点数经 numbers.yaml `character.rarity_distribution` 派生
///   ② 全部角色 def 的实际总点数与其派生档位自洽,且不越 GDD §4.1 的 16-24
///
/// 读**生产 yaml**(非合成 fixture):改坏 data/numbers.yaml 的区间表本测必红。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group(
    'rarityForTotalPoints 读 numbers.yaml character.rarity_distribution',
    () {
      test('六档边界逐点对齐 yaml total_points_range', () async {
        final repo = await GameRepository.loadAllDefs(loader: fileLoader);
        const cases = <int, RarityTier>{
          16: RarityTier.yongCai,
          17: RarityTier.yongCai,
          18: RarityTier.xunChang,
          19: RarityTier.xunChang,
          20: RarityTier.biaoZhun,
          21: RarityTier.ziYou,
          22: RarityTier.ziYou,
          23: RarityTier.tianCai,
          24: RarityTier.jueShi,
        };
        for (final e in cases.entries) {
          expect(
            repo.numbers.rarityForTotalPoints(e.key),
            e.value,
            reason: '总点数 ${e.key} 应派生为 ${e.value.name}',
          );
        }
      });

      test('超出上界向最高档钳制(奇遇生涯 +5 可使 founder 达 27)', () async {
        final repo = await GameRepository.loadAllDefs(loader: fileLoader);
        // founder 起始 22 分 + 生涯 cap 5(numbers.yaml
        // character.adventure_attribute_bonus.lifetime_cap_per_character)= 27,
        // 超出 rarity_distribution 表的 24 上界,必须钳到最高档而非抛/返 null。
        expect(repo.numbers.rarityForTotalPoints(25), RarityTier.jueShi);
        expect(repo.numbers.rarityForTotalPoints(27), RarityTier.jueShi);
      });

      test('低于下界向最低档钳制', () async {
        final repo = await GameRepository.loadAllDefs(loader: fileLoader);
        expect(repo.numbers.rarityForTotalPoints(15), RarityTier.yongCai);
        expect(repo.numbers.rarityForTotalPoints(4), RarityTier.yongCai);
      });

      test('16-24 全区间无空洞且单调不降', () async {
        final repo = await GameRepository.loadAllDefs(loader: fileLoader);
        var prev = -1;
        for (var t = 16; t <= 24; t++) {
          final idx = repo.numbers.rarityForTotalPoints(t).index;
          expect(
            idx,
            greaterThanOrEqualTo(prev),
            reason: '总点数 $t 的档位低于 ${t - 1} 的,rarity_distribution 区间表非单调',
          );
          prev = idx;
        }
      });
    },
  );

  group('生产创建路径产出的 rarity 必须是派生值(不得写死)', () {
    test('buildMasterCharacter:祖师/大弟子/二弟子档位各不相同', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final now = DateTime(2026, 8, 7);

      final produced = <String, RarityTier>{};
      for (final def in repo.masters) {
        final c = buildMasterCharacter(def, now: now);
        produced[def.id] = c.rarity;
        expect(
          c.rarity,
          repo.numbers.rarityForTotalPoints(c.attributes.total),
          reason:
              '${def.id} 的 rarity 与其 attributes.total(${c.attributes.total})不符,'
              '说明创建点又写死了档位',
        );
      }

      // 反「全部写死成同一档」:三位开局角色总点数 22/19/17,档位必须分化。
      // 若哪天有人把 rarity 改回常量,这条会红。
      expect(
        produced.values.toSet().length,
        greaterThan(1),
        reason: '三位开局角色档位全同,疑似 rarity 被写死:$produced',
      );
    });
  });

  group('角色 def 的总点数与派生档位自洽', () {
    test('recruit_candidates / sect_candidates 全部落在 16-24 且可派生', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      final totals = <String, int>{
        for (final e in repo.recruitCandidates.entries)
          'recruit:${e.key}': e.value.attributeProfile.total,
        for (final e in repo.sectCandidates.entries)
          'sect:${e.key}': e.value.attributeProfile.total,
      };

      expect(totals, isNotEmpty, reason: '候选 def 未加载,本测无效');
      for (final e in totals.entries) {
        expect(
          e.value,
          inInclusiveRange(16, 24),
          reason: '${e.key} 总点数 ${e.value} 越出 GDD §4.1 的 16-24',
        );
        expect(
          () => repo.numbers.rarityForTotalPoints(e.value),
          returnsNormally,
          reason: '${e.key} 总点数 ${e.value} 无对应档位',
        );
      }
    });
  });
}
