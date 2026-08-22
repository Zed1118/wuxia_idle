import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';

/// `dart:math` Random 注入点接线契约(K1 · 2026-08-06 生产裸 `Random()` 收口)。
///
/// 背景:lib/ 生产代码方法体内裸 `Random()` 绕开注入体系,测试 override 不到
/// (同 PR #75 CI 随机红的失效模式,只是签名是 `dart:math` 而非 Rng 抽象)。
/// 本批立 `math_random.dart` 注入点后,用本契约棘轮防回潮:
///   - **扫描契约**:lib/ 生产代码(剥注释后)不得出现裸 `Random(` 构造,
///     白名单仅注入点定义处(`math_random.dart` / `rng.dart` 的 DefaultRng)
///     与 `lib/features/debug/`(非生产)。
///   - **分层接线**:有 ref 层走 `mathRandomProvider`,无 ref 层兜底走
///     `newMathRandom`(体例沿 2026-07-26 DefaultRng 收口契约测)。
///   - **override 生效**:固定种子注入 provider 后结果可预测(纯函数层断言,
///     不在 widget 层)。
void main() {
  /// 裸构造检测:词边界 `Random(`,兼容 `math.Random(` / 任意 `xxx.Random(` 别名
  /// 前缀(`.` 不在排除集);`newMathRandom(` 因前一个字符是词字符天然不匹配。
  /// 另覆盖 `Random.secure(` / `math.Random.secure(`——`Random\s*\(` 对
  /// `Random.secure(` 零命中(中间隔 `.secure`),须显式钉(K1 :45 自陈缺口)。
  final bareRandom = RegExp(r'(?<![A-Za-z0-9_$])Random\s*(?:\(|\.secure\s*\()');

  /// 别名 import 检测:`import 'dart:math' show Random as Foo;` 把构造名改写成
  /// `Foo(`,词边界正则对改名后的标识符零命中(K1 :45 自陈缺口)——直接钉
  /// import 行本身。hide 无碍(藏起来就不会被构造)。
  final aliasedRandomImport = RegExp(
    r"import\s+'dart:math'[^;\n]*\bshow\b[^;\n]*\bRandom\s+as\s+",
  );

  /// 剥掉注释(块注释 + 行注释),只留可执行代码参与扫描。
  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i >= 0 ? line.substring(0, i) : line;
        })
        .join('\n');
  }

  group('K1 · dart:math Random 注入点接线契约', () {
    test('扫描口径自控:别名/secure/前缀形式必命中,注入点形式必不命中', () {
      // 正则一旦 drift(如有人「优化」掉 lookbehind),扫描测仍绿但已失明——
      // 本测把命中/不命中样本钉死,保证扫描口径本身被守护。
      const hits = {
        'final r = Random();': '裸构造',
        'final r = Random(42);': '带种子裸构造',
        'final r = Random.secure();': 'secure 构造',
        'final r = math.Random.secure();': '前缀 secure 构造',
        'final r = m.Random(1);': '别名前缀构造',
        'final r=Random();': '无空格变体',
      };
      for (final e in hits.entries) {
        expect(
          bareRandom.hasMatch(e.key),
          isTrue,
          reason: '${e.value}: ${e.key}',
        );
      }
      const misses = {
        'final r = newMathRandom();': '注入点兜底',
        'final r = newMathRandom(seed: 1);': '注入点带种子',
      };
      for (final e in misses.entries) {
        expect(
          bareRandom.hasMatch(e.key),
          isFalse,
          reason: '${e.value}: ${e.key}',
        );
      }
      expect(
        aliasedRandomImport.hasMatch(
          "import 'dart:math' show Random as MyRandom;",
        ),
        isTrue,
        reason: 'show Random as X 别名 import 必须命中',
      );
      expect(
        aliasedRandomImport.hasMatch("import 'dart:math' show Random, Point;"),
        isFalse,
        reason: '正常 show 导入不误伤',
      );
      expect(
        aliasedRandomImport.hasMatch("import 'dart:math' as math;"),
        isFalse,
        reason: '库前缀导入由 .Random( 词边界正则覆盖,本正则不误伤',
      );
    });

    test('lib/ 生产代码裸 Random( 构造归 0(白名单:注入点定义处 + debug)', () {
      const whitelist = {
        'lib/shared/utils/math_random.dart', // 注入点定义处本身
        'lib/shared/utils/rng.dart', // Rng 抽象注入点 DefaultRng 定义处
      };
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (path.endsWith('.g.dart')) continue; // 生成代码
        if (whitelist.contains(path)) continue;
        if (path.startsWith('lib/features/debug/')) continue; // 非生产
        final code = stripComments(entity.readAsStringSync());
        if (bareRandom.hasMatch(code) || aliasedRandomImport.hasMatch(code)) {
          offenders.add(path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            '这些文件仍裸构造 Random(/Random.secure(/别名导入 Random,'
            '请走 mathRandomProvider / newMathRandom:\n${offenders.join('\n')}',
      );
    });

    test('有 ref 的 UI/flow/providers 层走 mathRandomProvider', () {
      const paths = [
        'lib/features/mainline/presentation/stage_entry_flow.dart',
        'lib/features/tower/presentation/tower_entry_flow.dart',
        'lib/features/sweep/application/sweep_settlement.dart',
        'lib/features/sect/application/sect_providers.dart',
        'lib/features/sect/presentation/widgets/sect_event_dialog.dart',
      ];
      for (final path in paths) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('mathRandomProvider'),
          reason: '$path 应从 mathRandomProvider 取随机源',
        );
        expect(
          bareRandom.hasMatch(stripComments(source)),
          isFalse,
          reason: '$path 仍有裸 Random( 构造,测试 override 不到',
        );
      }
    });

    test('无 ref 的 domain/service 层兜底走 newMathRandom', () {
      const paths = [
        'lib/features/battle/domain/strategy/default_ground_strategy.dart',
        'lib/features/battle/domain/strategy/mass_battle_strategy.dart',
        'lib/features/battle/domain/damage_calculator.dart',
        'lib/features/battle/application/battle_providers.dart',
        'lib/features/event/application/game_event_service.dart',
        'lib/features/expedition/application/phase0a_expedition_combat_runner.dart',
      ];
      for (final path in paths) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('newMathRandom('),
          reason: '$path 兜底默认值应走 newMathRandom 注入点',
        );
        expect(
          bareRandom.hasMatch(stripComments(source)),
          isFalse,
          reason: '$path 仍有裸 Random( 构造,测试 override 不到',
        );
      }
    });

    test('mathRandomProvider 可被固定种子 override 且结果可预测', () {
      final container = ProviderContainer(
        overrides: [mathRandomProvider.overrideWithValue(Random(42))],
      );
      addTearDown(container.dispose);
      // 与全新 Random(42) 逐值一致 = override 生效且可复现。
      final expected = Random(42);
      final injected = container.read(mathRandomProvider);
      for (var i = 0; i < 8; i++) {
        expect(injected.nextInt(100000), expected.nextInt(100000));
      }
    });

    test('mathRandomProvider 默认路径为无种子随机(行为不变式)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // 不 override 时返回可用 Random 实例(纯接线,不钉具体值)。
      expect(container.read(mathRandomProvider), isA<Random>());
    });
  });
}
