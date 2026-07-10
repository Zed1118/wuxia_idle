import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';

/// 战斗交互重做 Phase 3:入口决策二元真相表。
///
/// 唯一配置源为全局设置(true = 纯挂机自动 / false = 允许拖招)。
void main() {
  test('全局自动 → auto', () {
    expect(resolveAutoPlayMode(globalDefault: true), AutoPlayMode.auto);
  });

  test('全局关 → interactive', () {
    expect(resolveAutoPlayMode(globalDefault: false), AutoPlayMode.interactive);
  });
}
