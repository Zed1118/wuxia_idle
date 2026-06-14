import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';

/// 战斗交互重做 Phase 3:入口决策二元真相表。
///
/// `autoWanted = override ?? globalDefault`(true = 纯挂机自动 / false = 允许拖招):
/// - override=null → 随全局
/// - override 非空 → 覆盖全局
void main() {
  test('override=null → 随全局:全局自动 → auto', () {
    expect(
      resolveAutoPlayMode(override: null, globalDefault: true),
      AutoPlayMode.auto,
    );
  });

  test('override=null → 随全局:全局关 → interactive', () {
    expect(
      resolveAutoPlayMode(override: null, globalDefault: false),
      AutoPlayMode.interactive,
    );
  });

  test('override=true 覆盖全局关 → auto', () {
    expect(
      resolveAutoPlayMode(override: true, globalDefault: false),
      AutoPlayMode.auto,
    );
  });

  test('override=false 覆盖全局自动 → interactive', () {
    expect(
      resolveAutoPlayMode(override: false, globalDefault: true),
      AutoPlayMode.interactive,
    );
  });
}
