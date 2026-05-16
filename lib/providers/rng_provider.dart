import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../shared/utils/rng.dart';

part 'rng_provider.g.dart';

/// 全局 [Rng] 注入点（phase2_tasks T29）。
///
/// 生产：返回 [DefaultRng]（无种子，[Random] 默认实现）。
/// 测试：`rngProvider.overrideWithValue(DefaultRng(seed: 42))` 或自定义 stub。
/// AutoDispose 以便跨 dialog 自然重建；同一 dialog 内 ref.read 只取一次。
@riverpod
Rng rng(Ref ref) => DefaultRng();
