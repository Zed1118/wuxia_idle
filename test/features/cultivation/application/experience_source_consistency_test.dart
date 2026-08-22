import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../support/dart_source_contract.dart';

void main() {
  test('all production experience gates include the release cap', () async {
    const gatePaths = {
      'combat':
          'lib/features/combat_shared/application/combat_progression_settlement_service.dart',
      'retreat': 'lib/features/seclusion/application/seclusion_service.dart',
      'offline':
          'lib/features/seclusion/application/offline_passive_service.dart',
      'item': 'lib/features/inventory/presentation/inventory_screen.dart',
    };

    for (final entry in gatePaths.entries) {
      final contract = DartSourceContract.parse(
        await File(entry.value).readAsString(),
        path: entry.value,
      );
      expect(
        contract.methodCalls(
          targetSource: 'ProgressionGateService',
          methodName: 'isLayerLocked',
        ),
        hasLength(1),
        reason: '${entry.key} 必须经过统一发布上限门禁',
      );
      expect(
        contract.methodCalls(
          targetSource: 'InnerDemonService',
          methodName: 'isLayerLocked',
        ),
        isEmpty,
        reason: '${entry.key} 不得绕过发布上限直接接心魔锁',
      );
    }
  });

  test(
    'five production wiring points cover seven experience scenarios',
    () async {
      const combatPaths = {
        'mainline': 'lib/features/mainline/presentation/stage_entry_flow.dart',
        'tower': 'lib/features/tower/presentation/tower_entry_flow.dart',
      };
      for (final entry in combatPaths.entries) {
        final contract = DartSourceContract.parse(
          await File(entry.value).readAsString(),
          path: entry.value,
        );
        expect(
          contract.variableInitializerSource('settlement'),
          'CombatProgressionSettlementService(GameRepository.instance)',
          reason: '${entry.key} settlement 必须是真实共享结算服务实例',
        );
        final calls = contract.methodCalls(
          targetSource: 'settlement',
          methodName: 'applyExperience',
        );
        expect(calls, hasLength(1), reason: '${entry.key} 必须有且仅有一个真实经验结算调用');
      }

      const directPaths = {
        'retreat': 'lib/features/seclusion/application/seclusion_service.dart',
        'offline':
            'lib/features/seclusion/application/offline_passive_service.dart',
        'item': 'lib/features/inventory/application/item_use_service.dart',
      };
      for (final entry in directPaths.entries) {
        final contract = DartSourceContract.parse(
          await File(entry.value).readAsString(),
          path: entry.value,
        );
        expect(
          contract.methodCalls(
            targetSource: 'CharacterAdvancementService',
            methodName: 'applyExperience',
          ),
          hasLength(1),
          reason: '${entry.key} 未委托唯一成长服务',
        );
      }
    },
  );

  test(
    'mainline replay and tower first-clear policies are real call arguments',
    () async {
      const mainlinePath =
          'lib/features/mainline/presentation/stage_entry_flow.dart';
      const towerPath = 'lib/features/tower/presentation/tower_entry_flow.dart';
      final mainline = DartSourceContract.parse(
        await File(mainlinePath).readAsString(),
        path: mainlinePath,
      );
      final tower = DartSourceContract.parse(
        await File(towerPath).readAsString(),
        path: towerPath,
      );
      final mainlineCall = mainline
          .methodCalls(
            targetSource: 'settlement',
            methodName: 'applyExperience',
          )
          .single;
      final towerCall = tower
          .methodCalls(
            targetSource: 'settlement',
            methodName: 'applyExperience',
          )
          .single;

      expect(
        mainlineCall.namedArguments['experienceReward'],
        'stage.baseExpReward',
        reason: '主线首通与重打都发放经验',
      );
      expect(
        towerCall.namedArguments['experienceReward'],
        'isFirstClear ? floor.baseExpReward : 0',
        reason: '爬塔仅首通发放经验',
      );
    },
  );

  test(
    'retreat and passive sources combine before the only advancement call',
    () async {
      const path = 'lib/features/seclusion/application/seclusion_service.dart';
      final contract = DartSourceContract.parse(
        await File(path).readAsString(),
        path: path,
      );
      final calls = contract.methodCalls(
        targetSource: 'CharacterAdvancementService',
        methodName: 'applyExperience',
      );

      expect(calls, hasLength(1), reason: '合并经验只能结算一次');
      expect(
        contract.variableInitializerSource('totalExperience'),
        'outputs.experiencePoints + settlement.passive.experience',
        reason: '唯一入账值必须合并闭关与溢出普通挂机经验',
      );
      expect(calls.single.positionalArguments, ['ch', 'totalExperience']);
    },
  );

  test('AST call contracts ignore comments and string literals', () {
    final contract = DartSourceContract.parse(r'''
void probe() {
  // settlement.applyExperience(experienceReward: stage.baseExpReward);
  const fake = 'CharacterAdvancementService.applyExperience(character, 1)';
}
''');

    expect(
      contract.methodCalls(
        targetSource: 'settlement',
        methodName: 'applyExperience',
      ),
      isEmpty,
    );
    expect(
      contract.methodCalls(
        targetSource: 'CharacterAdvancementService',
        methodName: 'applyExperience',
      ),
      isEmpty,
    );
  });
}
