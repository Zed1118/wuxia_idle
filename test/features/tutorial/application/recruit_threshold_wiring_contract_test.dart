import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_data.dart';

/// 2026-09-18 B2 复核 5A I-A′:「一流可收徒」门禁的唯一真相源是
/// numbers.yaml `inheritance.unlock_rules.can_take_disciple_at`。
///
/// - TutorialService 不得再写死 `RealmTier.yiLiu`(CLAUDE.md §5.6);
/// - 两个生产调用方(闭关升层 / 战斗结算升层)必须把
///   `repository.numbers.canTakeDiscipleAt` 传入 hook;
/// - NumbersConfig 解析值与 yaml 字面一致(改 yaml 即改门禁)。
void main() {
  test('TutorialService 收徒门槛不再写死 yiLiu', () async {
    final source = await File(
      'lib/features/tutorial/application/tutorial_service.dart',
    ).readAsString();
    expect(source, isNot(contains('RealmTier.yiLiu')));
    expect(source, contains('required RealmTier threshold'));
  });

  test('两个生产调用方把 numbers.canTakeDiscipleAt 传入 hook', () async {
    for (final path in [
      'lib/features/seclusion/application/seclusion_service.dart',
      'lib/features/combat_shared/application/combat_progression_settlement_service.dart',
    ]) {
      final source = await File(path).readAsString();
      expect(
        source,
        matches(RegExp(r'threshold:\s*[\w.]*numbers\.canTakeDiscipleAt,')),
        reason: path,
      );
    }
  });

  test('NumbersConfig.canTakeDiscipleAt 与 yaml 字面一致', () async {
    final repo = await loadTestGameRepository();
    final raw = loadTestNumbersSection([
      'inheritance',
      'unlock_rules',
    ])['can_take_disciple_at'];
    expect(repo.numbers.canTakeDiscipleAt.name, raw);
  });
}
