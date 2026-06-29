import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/application/character_providers.dart';
import '../../encounter/application/encounter_service.dart';
import '../../encounter/application/encounter_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 奇遇招式装备段(C-W14-3-A)。
///
/// 与 [_EquipmentSection] / [_TechniqueSection] 体例并列,展示当前角色装备的
/// 奇遇 skill slot,点击 "选择招式" 打开 bottom sheet 列出已 unlock 招式
/// (来自 SaveData.skillUnlockProgress 单一真相源 · 波A A4),按 tier 排序;玩家 tap 即装备
/// (走 [EncounterService.equipEncounterSkill] 校验境界锁死)。
///
/// 未 unlock 任何奇遇 skill 时显示占位文案,按钮 disabled。
class EncounterSkillSection extends ConsumerWidget {
  const EncounterSkillSection({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 波A A4 来源统一:读 SaveData.skillUnlockProgress 单一真相源
    // (只取奇遇招,真解/残页解锁的心法招不入此面板)。
    final unlockedAsync = ref.watch(unlockedSkillIdSetProvider);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.encounterSkillSectionTitle),
          unlockedAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: InkLoadingIndicator()),
            ),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(unlockedSkillIdSetProvider),
            ),
            data: (unlockedSet) => _Content(
              character: character,
              unlocked: [
                if (GameRepository.isLoaded)
                  for (final id in unlockedSet)
                    if (GameRepository.instance.encounterSkillIds.contains(id))
                      id,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.character, required this.unlocked});

  final Character character;
  final List<String> unlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipped = character.equippedEncounterSkillId;
    final hasUnlocks = unlocked.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SlotDisplay(equippedSkillId: equipped),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PlaqueButton(
              label: hasUnlocks
                  ? UiStrings.encounterSkillPickButton
                  : UiStrings.encounterSkillNoneAvailable,
              primary: hasUnlocks,
              disabled: !hasUnlocks,
              onTap: hasUnlocks
                  ? () => _openPicker(context, ref, unlocked)
                  : null,
            ),
            if (equipped != null)
              PlaqueButton(
                label: UiStrings.encounterSkillUnequipButton,
                onTap: () => _unequip(context, ref),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    List<String> unlockedIds,
  ) async {
    if (!GameRepository.isLoaded) return;
    final repo = GameRepository.instance;
    final skills =
        unlockedIds
            .map((id) => repo.skillDefs[id])
            .whereType<SkillDef>()
            .toList()
          ..sort((a, b) {
            final t = (a.tier ?? 0).compareTo(b.tier ?? 0);
            if (t != 0) return t;
            return a.id.compareTo(b.id);
          });

    final picked = await showModalBottomSheet<SkillDef>(
      context: context,
      backgroundColor: WuxiaColors.panel,
      builder: (ctx) => _PickerSheet(
        skills: skills,
        currentRealmTier: character.realmTier,
        equippedId: character.equippedEncounterSkillId,
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await _equip(context, ref, picked);
  }

  Future<void> _equip(
    BuildContext context,
    WidgetRef ref,
    SkillDef skill,
  ) async {
    final svc = ref.read(encounterServiceProvider);
    if (svc == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await svc.equipEncounterSkill(
        characterId: character.id,
        skillDef: skill,
        saveDataId: 1,
      );
      ref.invalidate(characterByIdProvider(character.id));
      ref.invalidate(unlockedSkillIdSetProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_resultText(result))));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(UiStrings.encounterSkillEquipFailed(e))),
      );
    }
  }

  Future<void> _unequip(BuildContext context, WidgetRef ref) async {
    final svc = ref.read(encounterServiceProvider);
    if (svc == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await svc.unequipEncounterSkill(characterId: character.id);
      ref.invalidate(characterByIdProvider(character.id));
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(UiStrings.encounterSkillUnequipSuccess)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(UiStrings.encounterSkillUnequipFailed(e))),
      );
    }
  }

  String _resultText(EquipEncounterSkillResult result) {
    switch (result) {
      case EquipSucceeded():
        return UiStrings.encounterSkillEquipped;
      case EquipNotUnlocked():
        return UiStrings.encounterSkillNotUnlocked;
      case EquipTierLocked(:final requiredTier, :final currentTier):
        return UiStrings.encounterSkillTierLocked(
          requiredTier,
          EnumL10n.realmTier(currentTier),
        );
      case EquipNotFound(:final reason):
        return UiStrings.encounterSkillEquipFailedReason(reason);
    }
  }
}

class _SlotDisplay extends StatelessWidget {
  const _SlotDisplay({required this.equippedSkillId});

  final String? equippedSkillId;

  @override
  Widget build(BuildContext context) {
    final id = equippedSkillId;
    if (id == null || !GameRepository.isLoaded) {
      return const _Shell(
        borderColor: WuxiaColors.buttonDisabled,
        child: Center(
          child: Text(
            UiStrings.encounterSkillSlotEmpty,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    final skill = GameRepository.instance.skillDefs[id];
    if (skill == null) {
      return _Shell(
        borderColor: WuxiaColors.hpLow,
        child: Text(
          UiStrings.encounterSkillDefMissing(id),
          style: const TextStyle(color: WuxiaColors.hpLow, fontSize: 12),
        ),
      );
    }
    return _Shell(
      borderColor: WuxiaColors.textPrimary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'tier ${skill.tier} · ${UiStrings.skillInfoPower} ${skill.powerMultiplier}',
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (skill.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    skill.description,
                    style: const TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            EnumL10n.skillType(skill.type),
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.skills,
    required this.currentRealmTier,
    required this.equippedId,
  });

  final List<SkillDef> skills;
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
                UiStrings.encounterSkillPickerTitle,
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
                itemCount: skills.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: WuxiaColors.border),
                itemBuilder: (ctx, i) {
                  final s = skills[i];
                  final tier = s.tier ?? 0;
                  final canEquip =
                      EncounterService.canEquipEncounterSkillByTier(
                        realmTier: currentRealmTier,
                        skillTier: tier,
                      );
                  final isEquipped = s.id == equippedId;
                  return ListTile(
                    enabled: canEquip,
                    title: Text(
                      s.name,
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
                      'tier $tier · ${EnumL10n.skillType(s.type)} '
                      '· ${UiStrings.skillInfoPower} ${s.powerMultiplier}'
                      '${s.description.trim().isEmpty ? "" : "\n${s.description}"}'
                      '${isEquipped ? "  ${UiStrings.currentEquippedBadge}" : ""}',
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
                    onTap: canEquip ? () => Navigator.pop(ctx, s) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(padding: const EdgeInsets.all(14), child: child);
  }
}
