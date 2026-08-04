import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cangjingge/domain/fragment_source.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../support/test_data.dart';

/// 残页来源派生测试（T7）。
///
/// 用真实 GameRepository defs（不构造 StageDef fixture，避免必填字段繁琐），
/// 断言当前塔层/主线残页能反查出来源，未知残页返 null。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('塔层残页 skill_kai_bei_shou → 爬塔·第4层(批 A 重排随 Boss 迁移)', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_kai_bei_shou',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      UiStrings.cangjingFragmentSourceTower(4),
    );
  });

  test(
    '塔层残页 skill_guan_shan_ba_ji → 爬塔·第11层(批 A 重排随 Boss 迁移)',
    () {
      final repo = GameRepository.instance;
      expect(
        fragmentSourceLabel(
          'skill_guan_shan_ba_ji',
          floors: repo.towerFloors,
          stages: repo.stageDefs.values,
        ),
        UiStrings.cangjingFragmentSourceTower(11),
      );
    },
  );

  test('塔层残页 skill_jin_gang_fu_mo → 爬塔·第14层(批 A 重排随 Boss 迁移)', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_jin_gang_fu_mo',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      UiStrings.cangjingFragmentSourceTower(14),
    );
  });

  test('塔层残页 skill_ma_ta_fei_yan → 爬塔·第32层(批 A 重排随绝顶剑魔迁移)', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_ma_ta_fei_yan',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      UiStrings.cangjingFragmentSourceTower(32),
    );
  });

  test(
    '主线残页 skill_jing_hong_zhao_ying → 主线·第13章重打(2026-07-22 Ch13 章末残页挂载)',
    () {
      final repo = GameRepository.instance;
      expect(
        fragmentSourceLabel(
          'skill_jing_hong_zhao_ying',
          floors: repo.towerFloors,
          stages: repo.stageDefs.values,
        ),
        UiStrings.cangjingFragmentSourceMainline(13),
      );
    },
  );

  test('未知残页 → null（来源未明，不臆造）', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_does_not_exist',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      isNull,
    );
  });
}
