import 'dart:math';

/// 随机数源抽象（phase2_tasks T19）。
///
/// 抽出来的唯一目的是**让单测可注入确定性种子**：
///   - 业务代码：依赖 [Rng]，构造时取 [DefaultRng]（包装 [Random]）
///   - 单测：注入 `DefaultRng(seed: 42)`，结果可复现
///
/// 不引入第三方包，依赖 `dart:math.Random`。
abstract class Rng {
  /// 等价 [Random.nextInt]：返回 `[0, max)` 区间整数。`max` 必须 > 0。
  int nextInt(int max);

  /// 等价 [Random.nextDouble]：返回 `[0, 1)` 区间浮点。
  double nextDouble();

  /// 从 [list] 等概率挑一个元素。空列表抛 [ArgumentError]。
  T pick<T>(List<T> list);
}

/// 默认实现：包装 [Random]，可选种子。
class DefaultRng implements Rng {
  final Random _random;

  DefaultRng({int? seed}) : _random = Random(seed);

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  double nextDouble() => _random.nextDouble();

  @override
  T pick<T>(List<T> list) {
    if (list.isEmpty) {
      throw ArgumentError('Cannot pick from an empty list');
    }
    return list[_random.nextInt(list.length)];
  }
}
