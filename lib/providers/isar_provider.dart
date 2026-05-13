import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/game_repository.dart';
import '../data/isar_setup.dart';

part 'isar_provider.g.dart';

/// Isar 实例 provider（Phase 5 W6-S2 引入）。
///
/// 生产路径：`main()` 中 [IsarSetup.init] 跑完后即可 `ref.read(isarProvider)` 读取。
/// 测试路径：`ProviderScope(overrides: [isarProvider.overrideWithValue(testIsar)])`
/// 注入真 Isar（tempDir）或 mock，替代旧的 `Isar.getInstance(...)` guard。
///
/// 与 [gameRepositoryProvider] 一起承担"静态单例 → DI"的过渡，逐步解
/// 挂账 #23（widget test 不接真 Isar 旁路）。
@riverpod
Isar isar(Ref ref) => IsarSetup.instance;

/// GameRepository 单例 provider（Phase 5 W6-S2 引入）。
///
/// 生产路径：`main()` 中 [GameRepository.loadAllDefs] 完成后即可读。
/// 测试路径：`gameRepositoryProvider.overrideWithValue(testRepo)` 注入测试用 repo。
@riverpod
GameRepository gameRepository(Ref ref) => GameRepository.instance;
