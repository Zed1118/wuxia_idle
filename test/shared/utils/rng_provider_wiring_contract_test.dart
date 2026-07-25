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
  group('BACKLOG §一#8 · 生产随机源可注入契约', () {
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
