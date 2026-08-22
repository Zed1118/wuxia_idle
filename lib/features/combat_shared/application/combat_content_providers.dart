import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../equipment/application/drop_service.dart';

/// 战斗消费面共享的只读数值配置，不属于任何具体战斗引擎。
final numbersConfigProvider = Provider<NumbersConfig>(
  (ref) => GameRepository.instance.numbers,
  name: 'numbersConfigProvider',
);

/// 战斗结算共享的掉落服务，不依赖旧 3v3 状态或 notifier。
final dropServiceProvider = Provider<DropService>(
  (ref) =>
      DropService(equipmentDefLookup: GameRepository.instance.getEquipment),
  name: 'dropServiceProvider',
);
