import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cangjingge/domain/fragment_source.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../support/test_data.dart';

/// 残页来源派生测试（T7）。
///
/// 用真实 GameRepository defs（不构造 StageDef fixture，避免必填字段繁琐），
/// 断言当前塔层残页能反查出来源，未投放的未来残页与未知残页返 null。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('塔层残页 skill_kai_bei_shou → 爬塔·第5层', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_kai_bei_shou',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      UiStrings.cangjingFragmentSourceTower(5),
    );
  });

  test('未来主线残页 skill_guan_shan_ba_ji 当前未投放 → null', () {
    final repo = GameRepository.instance;
    expect(
      fragmentSourceLabel(
        'skill_guan_shan_ba_ji',
        floors: repo.towerFloors,
        stages: repo.stageDefs.values,
      ),
      isNull,
    );
  });

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
