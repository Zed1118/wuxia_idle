import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';

/// 显式关卡概率优先；缺省概率只从 numbers 读取，供主线结算与招降 hook 共用。
double resolveStageBossRecruitProbability({
  required BossRecruitConfig config,
  required NumbersConfig numbers,
}) =>
    config.baseProbability ??
    numbers.sectManagement.recruit.stageBossRecruitProb;
