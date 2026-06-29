import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../inventory/application/item_use_service.dart';

class InjuryStatusFormatter {
  const InjuryStatusFormatter._();

  static bool hasInjury(Character character) =>
      character.injuryHoursRemaining > 0 || character.lightInjuryStacks > 0;

  static String primaryStatus(Character character) {
    final config = GameRepository.instanceOrNull?.numbers.injury;
    final lines = statusParts(
      character,
      lightSpeedPenaltyPerStack: config?.lightSpeedPenaltyPerStack ?? 3,
      heavyAttackOutputMultiplier: config?.heavyAttackOutputMultiplier ?? 0.85,
      heavyInternalForceMaxPenaltyPct:
          config?.heavyInternalForceMaxPenaltyPct ?? 0.15,
    );
    return lines.isEmpty ? UiStrings.injuryStatusHealthy : lines.join('；');
  }

  static String namedStatusLine(Character character) =>
      UiStrings.injuryStatusLine(character.name, primaryStatus(character));

  static List<String> statusParts(
    Character character, {
    required int lightSpeedPenaltyPerStack,
    required double heavyAttackOutputMultiplier,
    required double heavyInternalForceMaxPenaltyPct,
  }) {
    final parts = <String>[];
    if (character.innerDemonResidueHoursRemaining > 0) {
      parts.add(
        '${UiStrings.conditionInnerDemonResidueLabel} · '
        '${UiStrings.conditionInnerDemonResidueRecovery(character.innerDemonResidueHoursRemaining)}',
      );
    }
    if (character.injuryHoursRemaining > 0) {
      parts.add(
        UiStrings.injuryStatusHeavy(
          hours: character.injuryHoursRemaining,
          attackPenaltyPct: _penaltyPct(heavyAttackOutputMultiplier),
          internalForcePenaltyPct: (heavyInternalForceMaxPenaltyPct * 100)
              .round(),
        ),
      );
    }
    if (character.lightInjuryStacks > 0) {
      parts.add(
        UiStrings.injuryStatusLight(
          character.lightInjuryStacks,
          character.lightInjuryStacks * lightSpeedPenaltyPerStack,
        ),
      );
    }
    return parts;
  }

  static int _penaltyPct(double multiplier) =>
      ((1.0 - multiplier) * 100).round();
}

class InjuryStatusPanel extends ConsumerStatefulWidget {
  const InjuryStatusPanel({
    super.key,
    required this.character,
    this.alwaysShow = false,
    this.showRecoveryAction = false,
  });

  final Character character;
  final bool alwaysShow;
  final bool showRecoveryAction;

  @override
  ConsumerState<InjuryStatusPanel> createState() => _InjuryStatusPanelState();
}

class _InjuryStatusPanelState extends ConsumerState<InjuryStatusPanel> {
  String? _resultLine;
  bool _busy = false;

  Future<int> _healingPillQuantity() async {
    final isar = IsarSetup.instanceOrNull;
    if (isar == null) return 0;
    final item = await isar.inventoryItems.getByDefId('item_liaoshangdan');
    return item?.quantity ?? 0;
  }

  Future<void> _useHealingPill() async {
    if (_busy) return;
    final isar = IsarSetup.instanceOrNull;
    final def = GameRepository.instanceOrNull?.itemDefs['item_liaoshangdan'];
    if (isar == null || def == null) return;

    setState(() => _busy = true);
    final result = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: GameRepository.instance.getRealm,
    );
    if (!mounted) return;
    ref.invalidate(characterByIdProvider(widget.character.id));
    ref.invalidate(activeCharacterIdsProvider);
    ref.invalidate(inventoryQuantityByDefIdProvider('item_liaoshangdan'));
    ref.invalidate(allInventoryItemsProvider);
    setState(() {
      _busy = false;
      _resultLine =
          result.kind == ItemUseKind.recoveryApplied &&
              result.targetName != null
          ? UiStrings.injuryStatusRecoveryApplied(result.targetName!)
          : UiStrings.injuryStatusRecoveryFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final injured = InjuryStatusFormatter.hasInjury(widget.character);
    if (!widget.alwaysShow && !injured) return const SizedBox.shrink();
    final status = InjuryStatusFormatter.primaryStatus(widget.character);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: injured
            ? WuxiaColors.hpLow.withValues(alpha: 0.10)
            : WuxiaUi.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: injured
              ? WuxiaColors.hpLow.withValues(alpha: 0.38)
              : WuxiaUi.ink.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                UiStrings.injuryStatusTitle,
                style: TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: injured ? WuxiaColors.hpLow : WuxiaUi.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (injured) ...[
            const SizedBox(height: 4),
            Text(
              _resultLine ?? UiStrings.injuryStatusRecoveryHint,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
          if (injured && widget.showRecoveryAction) ...[
            const SizedBox(height: 6),
            FutureBuilder<int>(
              future: _healingPillQuantity(),
              builder: (context, snapshot) {
                final quantity = snapshot.data ?? 0;
                if (quantity <= 0) {
                  return const Text(
                    UiStrings.injuryStatusRecoveryUnavailable,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                  );
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _useHealingPill,
                    child: const Text(UiStrings.injuryStatusRecoveryAction),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
