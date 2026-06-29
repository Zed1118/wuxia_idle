import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../injury/presentation/injury_status_view.dart';
import '../application/item_use_service.dart';

/// 战后疗伤丹快捷入口。只复用背包道具使用服务，不重算战斗结果。
class PostBattleHealingPanel extends ConsumerStatefulWidget {
  const PostBattleHealingPanel({super.key});

  @override
  ConsumerState<PostBattleHealingPanel> createState() =>
      _PostBattleHealingPanelState();
}

class _PostBattleHealingPanelState
    extends ConsumerState<PostBattleHealingPanel> {
  String? _resultLine;
  bool _busy = false;

  Future<_PostBattleHealingState> _load() async {
    final isar = IsarSetup.instanceOrNull;
    if (isar == null || !GameRepository.isLoaded) {
      return const _PostBattleHealingState.hidden();
    }
    final item = await isar.inventoryItems.getByDefId('item_liaoshangdan');
    final qty = item?.quantity ?? 0;
    if (qty <= 0) return const _PostBattleHealingState.hidden();

    final active = await isar.characters
        .filter()
        .isActiveEqualTo(true)
        .findAll();
    final founder = await isar.characters
        .filter()
        .isFounderEqualTo(true)
        .findFirst();
    final candidates = active.isNotEmpty ? active : [?founder];
    final injuryLines = candidates
        .whereType<Character>()
        .where(
          (c) =>
              c.injuryHoursRemaining > 0 ||
              c.innerDemonResidueHoursRemaining > 0 ||
              c.lightInjuryStacks > 0,
        )
        .map(InjuryStatusFormatter.namedStatusLine)
        .toList(growable: false);
    if (injuryLines.isEmpty) return const _PostBattleHealingState.hidden();
    return _PostBattleHealingState.visible(qty, injuryLines);
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
    ref.invalidate(inventoryQuantityByDefIdProvider('item_liaoshangdan'));
    ref.invalidate(allInventoryItemsProvider);
    setState(() {
      _busy = false;
      _resultLine =
          result.kind == ItemUseKind.recoveryApplied &&
              result.targetName != null
          ? UiStrings.postBattleHealingApplied(result.targetName!)
          : UiStrings.postBattleHealingFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PostBattleHealingState>(
      future: _load(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || !state.visible) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: WuxiaColors.avatarFill,
            border: Border.all(color: WuxiaColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      UiStrings.postBattleHealingTitle,
                      style: TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resultLine ??
                          UiStrings.postBattleHealingAvailable(state.quantity),
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.injuryLines.join('\n'),
                      style: const TextStyle(
                        color: WuxiaColors.hpLow,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _useHealingPill,
                child: const Text(UiStrings.postBattleHealingAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostBattleHealingState {
  final bool visible;
  final int quantity;
  final List<String> injuryLines;

  const _PostBattleHealingState.hidden()
    : visible = false,
      quantity = 0,
      injuryLines = const [];

  const _PostBattleHealingState.visible(this.quantity, this.injuryLines)
    : visible = true;
}
