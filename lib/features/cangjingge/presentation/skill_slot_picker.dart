import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';

/// 打开换招 bottom sheet。
///
/// [candidates] 由调用方（藏经阁屏）按槽类型过滤好传入
/// （main/ultimate → 主修招、assist → 辅修招、resonance → joint 共鸣招）。
///
/// 返回玩家选中的招（`null` = 取消）。
/// **equipSkill 的实际落库不在此处**——picker 只负责「让玩家选一个招并返回」，
/// 落库由调用方拿到返回值后调 `SkillLoadoutService.equipSkill`。
Future<SkillDef?> openSkillSlotPicker(
  BuildContext context, {
  required List<SkillDef> candidates,
  required RealmTier currentRealmTier,
  required String? equippedId,
}) {
  return showModalBottomSheet<SkillDef>(
    context: context,
    backgroundColor: WuxiaColors.panel,
    builder: (ctx) => _SkillSlotPickerSheet(
      candidates: candidates,
      currentRealmTier: currentRealmTier,
      equippedId: equippedId,
    ),
  );
}

/// 换招候选列表 sheet（纯 UI，不依赖 Isar / service）。
///
/// 境界未达（`!skill.canEquipAtRealm(currentRealmTier)`）的招式灰显且不可点，
/// 显示 [UiStrings.cangjingTierLocked]。当前已装配的招式以标记高亮。
/// 玩家点可装配的项后，sheet 通过 `Navigator.pop(ctx, skill)` 返回所选招式。
class _SkillSlotPickerSheet extends StatelessWidget {
  const _SkillSlotPickerSheet({
    required this.candidates,
    required this.currentRealmTier,
    required this.equippedId,
  });

  final List<SkillDef> candidates;
  final RealmTier currentRealmTier;
  final String? equippedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                UiStrings.cangjingPickerTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1, color: WuxiaColors.border),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: WuxiaColors.border),
                itemBuilder: (ctx, i) {
                  final skill = candidates[i];
                  final canEquip = skill.canEquipAtRealm(currentRealmTier);
                  final isEquipped = skill.id == equippedId;
                  final tierLabel = skill.tier != null
                      ? EnumL10n.techniqueTier(
                          TechniqueTier.values[(skill.tier! - 1).clamp(
                            0,
                            TechniqueTier.values.length - 1,
                          )],
                        )
                      : '';
                  final typeLabel = EnumL10n.skillType(skill.type);

                  return ListTile(
                    enabled: canEquip,
                    title: Text(
                      skill.name,
                      style: TextStyle(
                        color: canEquip
                            ? WuxiaColors.textPrimary
                            : WuxiaColors.textMuted,
                        fontWeight: isEquipped
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _buildSubtitle(
                        tierLabel: tierLabel,
                        typeLabel: typeLabel,
                        power: skill.powerMultiplier,
                        description: skill.description,
                        isEquipped: isEquipped,
                        canEquip: canEquip,
                        canInterrupt: skill.canInterrupt,
                        defenseBreakPct: skill.defenseBreakPct,
                      ),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: canEquip
                        ? Icon(
                            isEquipped ? Icons.check : Icons.add,
                            color: WuxiaColors.textSecondary,
                            size: 18,
                          )
                        : const Icon(
                            Icons.lock_outline,
                            color: WuxiaColors.textMuted,
                            size: 16,
                          ),
                    onTap: canEquip ? () => Navigator.pop(ctx, skill) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle({
    required String tierLabel,
    required String typeLabel,
    required int power,
    required String description,
    required bool isEquipped,
    required bool canEquip,
    required bool canInterrupt,
    required double defenseBreakPct,
  }) {
    final parts = <String>[
      if (tierLabel.isNotEmpty) tierLabel,
      typeLabel,
      UiStrings.cangjingPickerDamage(power),
      if (canInterrupt) UiStrings.cangjingPickerCanInterrupt,
      if (defenseBreakPct > 0) UiStrings.skillTraitDefenseBreak,
    ];
    final base = parts.join(' · ');
    final descPart = description.trim().isNotEmpty
        ? '\n${description.trim()}'
        : '';
    final equippedPart = isEquipped
        ? '  [${UiStrings.cangjingEquippedTag}]'
        : '';
    final lockedPart = !canEquip ? '  ${UiStrings.cangjingTierLocked}' : '';
    return '$base$descPart$equippedPart$lockedPart';
  }
}
