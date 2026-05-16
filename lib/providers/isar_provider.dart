import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/game_repository.dart';
import '../data/isar_setup.dart';

part 'isar_provider.g.dart';

// =========================================================================
// 真基础设施 providers(Phase 5 W6-S2 引入 nullable propagation 主干)
//
// 历史:本文件曾装 11 个 provider(2 基础设施 + 9 service)。Phase 5 #3
// 第 5 批 C/I 任务整体拆分完成:
// - 装备系 2 provider → features/equipment/application/equipment_service_providers.dart(C)
// - dispel / seclusion / encounter 4 个有 consumer 的 provider →
//   各 features/<X>/application/<X>_service_providers.dart(I)
// - phase2SeedService / mainlineProgressService / towerProgressService /
//   stageBattleSetup 4 个 0-consumer 死 provider 删除(I,widget 端直接
//   `Service(isar: IsarSetup.instance)` 老路,nullable propagation 链未接入)
//
// 最终态:基础设施层只装 isar + gameRepository 2 个真基础设施 provider,
// 不反向 import features/。
// =========================================================================

/// Isar 实例 provider(Phase 5 W6-S2 引入,nullable propagation 主干)。
///
/// 生产路径:`main()` 中 [IsarSetup.init] 跑完后非 null,直接读用。
/// 测试路径:widget test 不 init Isar 时返回 null,由 service provider
/// 进一步传递 nullable —— 替代旧的 widget 端 `Isar.getInstance` guard。
///
/// 实现:走 [IsarSetup.instanceOrNull](探测式 getter,未 init 不抛)。
@riverpod
Isar? isar(Ref ref) => IsarSetup.instanceOrNull;

/// GameRepository 单例 provider。生产代码 main() 中 [GameRepository.loadAllDefs]
/// 完成后即可读。widget test setUpAll 通常预先 load。
///
/// 不 nullable:GameRepository 是项目启动必备,即使测试也通过 setUpAll
/// 加载,不存在"不 load 跑测试"的合理场景。
@riverpod
GameRepository gameRepository(Ref ref) => GameRepository.instance;
