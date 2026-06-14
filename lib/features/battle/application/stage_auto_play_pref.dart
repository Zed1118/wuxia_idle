import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 战斗交互重做 Phase 3:per-stage「挂机自动 / 允许拖招」每关记忆。
///
/// 旧 `BattleReplayRecord.autoPlayOverride`(Isar)随录制回放链一并删除;本偏好
/// 本质是「设置」非「存档」(沿 [GameplaySettings] / AudioSettings 体例),迁入
/// SharedPreferences(key 前缀 `gameplay.autoplayOverride.`)。三态:
/// `true` = 纯挂机自动 / `false` = 允许拖招 / 缺省(无 key)= 随全局。

/// 主线关 battleKey:`stage#<stageId>#<cycle>`。cycle 默认 1。
///
/// (原 `BattleReplayRecordService.stageBattleKey`,随 service 删除迁此纯函数。)
String stageBattleKey(String stageId, {int cycle = 1}) =>
    'stage#$stageId#$cycle';

/// 爬塔层 battleKey:`tower#<floor>#<cycle>`。cycle 默认 1。
String towerBattleKey(int floor, {int cycle = 1}) => 'tower#$floor#$cycle';

/// per-stage 自动播放 override 持久化(SharedPreferences)。
class StageAutoPlayPrefService {
  static const _prefix = 'gameplay.autoplayOverride.';

  /// 该关每关记忆。`null` = 随全局;`true` = 纯挂机自动 / `false` = 允许拖招。
  Future<bool?> override(String battleKey) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_prefix$battleKey');
  }

  /// 设该关每关记忆。`null` = 清除(回到随全局)。
  Future<void> setOverride(String battleKey, bool? value) async {
    final p = await SharedPreferences.getInstance();
    final key = '$_prefix$battleKey';
    if (value == null) {
      await p.remove(key);
    } else {
      await p.setBool(key, value);
    }
  }
}

final stageAutoPlayPrefServiceProvider = Provider<StageAutoPlayPrefService>(
  (ref) => StageAutoPlayPrefService(),
);

/// 选关屏 per-stage override 态(战斗交互重做 Phase 3)。`null` = 随全局。
///
/// 写 override 后调用方 `invalidate(stageAutoPlayOverrideProvider(battleKey))`
/// 刷新。
final stageAutoPlayOverrideProvider =
    FutureProvider.family<bool?, String>((ref, battleKey) async {
  return ref.watch(stageAutoPlayPrefServiceProvider).override(battleKey);
});
