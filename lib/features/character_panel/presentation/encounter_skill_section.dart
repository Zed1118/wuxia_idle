import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../encounter/domain/encounter_progress.dart';
import '../../../core/domain/enums.dart';
import '../../../core/application/character_providers.dart';
import '../../encounter/application/encounter_service.dart';
import '../../encounter/application/encounter_service_providers.dart';
import '../../../shared/theme/colors.dart';

/// 奇遇招式装备段(C-W14-3-A)。
///
/// 与 [_EquipmentSection] / [_TechniqueSection] 体例并列,展示当前角色装备的
/// 奇遇 skill slot,点击 "选择招式" 打开 bottom sheet 列出已 unlock 招式
/// (来自 [EncounterProgress.unlockedSkillIds]),按 tier 排序;玩家 tap 即装备
/// (走 [EncounterService.equipEncounterSkill] 校验境界锁死)。
///
/// 未 unlock 任何奇遇 skill 时显示占位文案,按钮 disabled。
class EncounterSkillSection extends ConsumerWidget {
  const EncounterSkillSection({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(currentEncounterProgressProvider);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('奇遇招式'),
          const SizedBox(height: 8),
          progressAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow, fontSize: 12),
            ),
            data: (progress) => _Content(
              character: character,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.character, required this.progress});

  final Character character;
  final EncounterProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipped = character.equippedEncounterSkillId;
    final unlocked = progress?.unlockedSkillIds ?? const <String>[];
    final hasUnlocks = unlocked.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SlotDisplay(equippedSkillId: equipped),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: hasUnlocks
                    ? () => _openPicker(context, ref, unlocked)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WuxiaColors.avatarFill,
                  foregroundColor: WuxiaColors.textPrimary,
                  side: const BorderSide(color: WuxiaColors.border),
                ),
                child: Text(
                  hasUnlocks ? '选择招式' : '尚无可装备奇遇招式',
                ),
              ),
            ),
            if (equipped != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _unequip(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WuxiaColors.textSecondary,
                  side: const BorderSide(color: WuxiaColors.border),
                ),
                child: const Text('卸下'),
              ),
            ],
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
    final skills = unlockedIds
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
      ref.invalidate(currentEncounterProgressProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_resultText(result))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('装备失败: $e')));
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
      messenger.showSnackBar(const SnackBar(content: Text('已卸下奇遇招式')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('卸下失败: $e')));
    }
  }

  String _resultText(EquipEncounterSkillResult result) {
    switch (result) {
      case EquipSucceeded():
        return '已装备';
      case EquipNotUnlocked():
        return '该招式尚未 unlock';
      case EquipTierLocked(:final requiredTier, :final currentTier):
        return '境界不足:需 tier $requiredTier,当前 '
            '${EnumL10n.realmTier(currentTier)}';
      case EquipNotFound(:final reason):
        return '装备失败: $reason';
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
            '未装备奇遇招式',
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
          '招式定义缺失: $id',
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
                  'tier ${skill.tier} · 倍率 ${skill.powerMultiplier}',
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            EnumL10n.skillType(skill.type),
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
            ),
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
                '选择奇遇招式',
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
                      '· 倍率 ${s.powerMultiplier}'
                      '${isEquipped ? "  [当前]" : ""}',
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
      height: 64,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
