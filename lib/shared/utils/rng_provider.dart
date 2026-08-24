import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'rng.dart';

part 'rng_provider.g.dart';

/// 全局 [Rng] 注入点（phase2_tasks T29）。
///
/// 生产：返回 [DefaultRng]（无种子，[Random] 默认实现）。
/// 测试：`rngProvider.overrideWithValue(DefaultRng(seed: 42))` 或自定义 stub。
/// AutoDispose 以便跨 dialog 自然重建；同一 dialog 内 ref.read 只取一次。
@riverpod
Rng rng(Ref ref) => DefaultRng();

/// 按持久化 seed 重建确定性 [Rng] 的可覆写工厂。
///
/// 需要跨重启复现的 flow 不能消费全局 [rngProvider] 的可变序列；
/// 测试可 override 本 provider，生产则按已持久化 seed 构造新实例。
typedef SeededRngFactory = Rng Function({int? seed});

final seededRngFactoryProvider = Provider<SeededRngFactory>(
  (ref) => DefaultRng.new,
);
