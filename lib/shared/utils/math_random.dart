import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `dart:math` [Random] 注入点（K1 · 2026-08-06 生产裸 `Random()` 收口）。
///
/// 与 [Rng] / `rngProvider`（`rng.dart` 的三方法抽象接口）并存——此处收口的
/// 是直接使用 `dart:math` 签名的位点（战斗策略 / 伤害计算 / 掉落 hook /
/// 事件池抽取等，迁移到 [Rng] 抽象属行为风险，故只接线不改签名）。
///
/// 分两层（体例沿 2026-07-26 DefaultRng 收口，契约测见
/// `test/shared/utils/math_random_wiring_contract_test.dart`）：
///   - **有 ref 的 UI / flow / providers 层**：`ref.read(mathRandomProvider)`；
///   - **无 ref 的 domain / service 层**：构造或参数注入 [Random]，
///     兜底默认值一律走 [newMathRandom]（全 lib/ 唯一 `Random(...)` 构造点；
///     `rng.dart` 的 `DefaultRng` 是 [Rng] 抽象注入点定义，同属白名单）。
///
/// 测试 override：
///   - provider 层：`mathRandomProvider.overrideWithValue(Random(seed))`；
///   - domain / service 层：直接传 `Random(seed)`。
final mathRandomProvider = Provider<Random>((ref) => newMathRandom());

/// 无 ref 调用点的兜底构造入口（默认无种子随机，与裸 `Random()` 行为一致；
/// 传 [seed] 等价 `Random(seed)`，供远征节点战等按 seed 复现的路径使用）。
Random newMathRandom({int? seed}) => Random(seed);
