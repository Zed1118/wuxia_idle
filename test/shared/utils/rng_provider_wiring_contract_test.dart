import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 生产随机源可注入契约(BACKLOG §一#8 收口)。
///
/// 背景:方法体内 inline `DefaultRng()` 的随机源**测试 override 不到**——
/// PR #75 已证这正是 CI 随机红的根因(稀有彩头在固定掉落外额外发装备,
/// 把 `sweep_settlement_test` 的精确掉落数断言打成随机红,三次白烧 CI)。
///
/// 契约分两层,按调用点能否拿到 `ref` 划分:
///   - **UI / flow 层**(有 `WidgetRef`/`Ref`):随机源走 `ref.read(rngProvider)`,
///     测试用 `rngProvider.overrideWithValue(...)` 注入。
///   - **service 层**(纯类无 ref):随机源走构造注入 `Rng`,
///     测试直接 `Service(rng: stub)`;有 ref 的构造点传 `ref.read(rngProvider)`。
///
/// 两层都禁方法体内 `final rng = DefaultRng();` / `rng: DefaultRng()` 这种
/// 不可注入的写法。构造函数默认值位置的 `rng ?? DefaultRng()` 是允许的
/// (保留无 ref 调用点的兜底,同时让测试能注入)。
void main() {
  /// 剥掉注释(块注释 + 行注释),只留可执行代码参与扫描(与
  /// math_random_wiring_contract_test 同体例)。
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

  /// 别名 import 检测:`show DefaultRng as Foo` 后 `Foo()` 绕开
  /// `contains('DefaultRng()')` 文本口径——直接钉 import 行本身。
  final aliasedDefaultRngImport = RegExp(
    r"\bshow\b[^;\n]*\bDefaultRng\s+as\s+",
  );

  group('BACKLOG §一#8 · 生产随机源可注入契约', () {
    test('lib/ 全仓扫描:inline DefaultRng 构造归 0(白名单:定义处/?? 兜底/debug)', () {
      // 硬编码路径清单只守既有调用点,新文件 inline DefaultRng() 不在清单内
      // 照样绿(K1 :45 自陈「白名单硬编码」缺口)——本测全仓棘轮:
      //   - 剥注释后凡 `DefaultRng(` 行即违规;
      //   - 例外:构造函数默认值 `rng ?? DefaultRng()` 兜底(契约明示允许,
      //     测试仍可注入)、rng_provider.dart 定义处、debug/(非生产)。
      const whitelist = {
        'lib/shared/utils/rng.dart', // DefaultRng 类定义处(构造器声明行含 DefaultRng()
        'lib/shared/utils/rng_provider.dart', // rngProvider 定义处本身
        // ── K2(2026-08-07)扫描新逮到的存量 seeded 构造,冻结待派单方拍板 ──
        // 两处均为 DefaultRng(seed: 稳定种子)(save/run/node 派生),确定性可复现,
        // 非 PR #75 那种无种子 inline 随机的失效模式;是否算合规体例(还是应迁
        // 注入点)涉契约语义拍板,执行端不擅自裁决。详
        // docs/dispatch/reports/2026-08-07_K2_false_green.md [BLOCKED] 节。
        'lib/features/expedition/domain/expedition_rules.dart',
        'lib/features/seclusion/application/retreat_settlement_calculator.dart',
      };
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (path.endsWith('.g.dart')) continue; // 生成代码
        if (whitelist.contains(path)) continue;
        if (path.startsWith('lib/features/debug/')) continue; // 非生产
        final code = stripComments(entity.readAsStringSync());
        if (aliasedDefaultRngImport.hasMatch(code)) {
          offenders.add('$path (别名导入 DefaultRng)');
          continue;
        }
        for (final line in code.split('\n')) {
          if (line.contains('DefaultRng(') && !line.contains('??')) {
            offenders.add('$path: ${line.trim()}');
            break; // 每文件报一处足够定位
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            '这些文件方法体内 inline DefaultRng()(或别名导入),测试 override 不到;'
            '随机源请走 rngProvider / 构造注入 Rng:\n${offenders.join('\n')}',
      );
    });

    test('扫描口径自控:别名/inline 形式必命中,?? 兜底必放行', () {
      expect(
        aliasedDefaultRngImport.hasMatch(
          "import 'package:wuxia_idle/shared/utils/rng.dart' show DefaultRng as DR;",
        ),
        isTrue,
        reason: 'show DefaultRng as X 别名 import 必须命中',
      );
      expect(
        aliasedDefaultRngImport.hasMatch(
          "import 'package:wuxia_idle/shared/utils/rng.dart' show DefaultRng, Rng;",
        ),
        isFalse,
        reason: '正常 show 导入不误伤',
      );
      // 行级判例:inline 命中;?? 兜底放行。
      const inlineHit = 'final rng = DefaultRng();';
      const fallbackPass = ': rng = rng ?? DefaultRng();';
      expect(
        inlineHit.contains('DefaultRng(') && !inlineHit.contains('??'),
        isTrue,
        reason: '方法体内 inline 必须被判违规',
      );
      expect(
        fallbackPass.contains('DefaultRng(') && !fallbackPass.contains('??'),
        isFalse,
        reason: '构造函数 ?? 兜底是契约明示允许的体例,必须放行',
      );
    });

    test('UI/flow 层随机源走 rngProvider,不 inline DefaultRng', () async {
      const paths = [
        'lib/features/boss_gauntlet/presentation/gauntlet_reward_screen.dart',
        'lib/features/tower/presentation/tower_entry_flow.dart',
        'lib/features/onboarding/presentation/founder_creation_screen.dart',
      ];
      for (final path in paths) {
        final source = await File(path).readAsString();
        expect(
          source,
          contains('rngProvider'),
          reason: '$path 应从 rngProvider 取随机源',
        );
        expect(
          source,
          isNot(contains('DefaultRng()')),
          reason: '$path 仍 inline new DefaultRng(),测试 override 不到',
        );
      }
    });

    test('service 层随机源走构造注入,不在方法体内 new', () async {
      const paths = [
        'lib/features/recruitment/application/recruitment_service.dart',
        'lib/features/lineage/application/disciple_join_service.dart',
        'lib/features/equipment/application/milestone_equipment_grant_service.dart',
        'lib/features/onboarding/application/onboarding_service.dart',
      ];
      for (final path in paths) {
        final source = await File(path).readAsString();
        expect(
          source,
          isNot(contains('final rng = DefaultRng();')),
          reason: '$path 方法体内 new 随机源,测试注入不进去',
        );
        expect(source, contains('Rng'), reason: '$path 应接受注入的 Rng');
      }
    });

    test('有 ref 的 service 构造点传 rngProvider 的随机源', () async {
      const paths = [
        'lib/features/boss_gauntlet/application/gauntlet_providers.dart',
        'lib/features/recruitment/application/recruitment_providers.dart',
        'lib/features/recruitment/presentation/recruitment_dialog.dart',
        'lib/features/lineage/presentation/disciple_join_hook.dart',
        'lib/features/save_slot/presentation/save_select_screen.dart',
      ];
      for (final path in paths) {
        final source = await File(path).readAsString();
        expect(
          source,
          contains('ref.read(rngProvider)'),
          reason: '$path 构造 service 时应传 rngProvider 的随机源',
        );
      }
    });
  });
}
