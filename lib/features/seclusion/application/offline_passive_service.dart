import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';

/// 被动离线挂机一次结算的产量（纯数据）。
typedef PassiveYield = ({int mojianshi, int experience});

/// M2 范围 B 通用被动离线挂机服务。
///
/// [compute] 纯函数算产量（≈闭关 25%，base 走 numbers.yaml passive_idle）。
/// 副作用入库见 [settle]（Task 4）。与闭关互斥：仅在无 active 闭关时由 gate 调用。
class OfflinePassiveService {
  OfflinePassiveService._();

  /// 按离线时长 + 主角境界算被动产量。
  /// [awayHours] 由 caller 传入（gate 已 clamp 下界 0）；内部按 cap 截上界。
  static PassiveYield compute({
    required double awayHours,
    required RealmTier realmTier,
    required PassiveIdleConfig config,
  }) {
    final capped = awayHours.clamp(0, config.capHours.toDouble());
    final scale = config.realmScaleFor(realmTier);
    final mojianshi =
        (config.baseMojianshiPerHour * capped * scale).floor().clamp(0, 999999);
    final experience =
        (config.baseExpPerHour * capped * scale).floor().clamp(0, 999999);
    return (mojianshi: mojianshi, experience: experience);
  }
}
