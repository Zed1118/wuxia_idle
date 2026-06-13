import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';

/// 半手动战斗 P0 步骤5-D:入口决策真相表。
///
/// autoWanted = override ?? globalDefault:
/// - 未通关 → manualFirstClear(强制手动单步,胜利录 seed+ops)
/// - 已通关 + 不想自动 → manualReplay(手动重打,胜利覆盖录制)
/// - 已通关 + 想自动 + 有记录 → autoReplay(seed+ops 确定性重演)
/// - 已通关 + 想自动 + 无记录(迁移豁免)→ autoFallback(现有自动战斗)
void main() {
  test('未通关 → manualFirstClear(无视全局/override)', () {
    expect(
      resolveAutoPlayMode(
          isCleared: false, hasRecord: false, override: null, globalDefault: true),
      AutoPlayMode.manualFirstClear,
    );
    expect(
      resolveAutoPlayMode(
          isCleared: false, hasRecord: false, override: true, globalDefault: false),
      AutoPlayMode.manualFirstClear,
    );
  });

  test('已通关 + 有记录 + 全局自动 + 无 override → autoReplay', () {
    expect(
      resolveAutoPlayMode(
          isCleared: true, hasRecord: true, override: null, globalDefault: true),
      AutoPlayMode.autoReplay,
    );
  });

  test('已通关 + 无记录(迁移豁免)+ 自动 → autoFallback', () {
    expect(
      resolveAutoPlayMode(
          isCleared: true, hasRecord: false, override: null, globalDefault: true),
      AutoPlayMode.autoFallback,
    );
  });

  test('已通关 + override=false → manualReplay(玩家切手动)', () {
    expect(
      resolveAutoPlayMode(
          isCleared: true, hasRecord: true, override: false, globalDefault: true),
      AutoPlayMode.manualReplay,
    );
  });

  test('已通关 + 全局关 + 无 override → manualReplay', () {
    expect(
      resolveAutoPlayMode(
          isCleared: true, hasRecord: true, override: null, globalDefault: false),
      AutoPlayMode.manualReplay,
    );
  });

  test('已通关 + override=true 覆盖全局关 → autoReplay(有记录)', () {
    expect(
      resolveAutoPlayMode(
          isCleared: true, hasRecord: true, override: true, globalDefault: false),
      AutoPlayMode.autoReplay,
    );
  });
}
