import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/skill_unlock_entry.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/technique_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../cultivation/application/loadout_slot_candidates.dart';
import '../../cultivation/application/skill_loadout_resolver.dart';
import '../../cultivation/application/skill_loadout_service.dart';
import '../../encounter/application/encounter_service.dart';
import '../../encounter/application/encounter_service_providers.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../domain/fragment_source.dart';
import 'fragment_progress_row.dart';
import 'skill_proficiency_row.dart';
import 'skill_slot_picker.dart';

/// 藏经阁主屏（P1b Task9 · brainstorm「A 角色武学手册」mockup）。
///
/// 集成 4 大区：
/// 1. 出战配置栏（6 槽：main1/main2/assist/resonance/ultimate/encounter），点槽换招；
/// 2. 武学库（按主修/辅修心法分组，每招一行 [SkillProficiencyRow]）；
/// 3. 残页收集区（[SaveData.skillUnlockProgress] 中未解锁但有残页的条目）。
///
/// 进入时（首帧）对当前角色调 [SkillLoadoutService.applyAutoFill] 补满空装配槽，
/// 解析逻辑复用 [SkillLoadoutResolver]（与进战斗前 autoFill 同源）。
class CangJingGeScreen extends ConsumerStatefulWidget {
  const CangJingGeScreen({super.key, required this.characterId});

  final int characterId;

  @override
  ConsumerState<CangJingGeScreen> createState() => _CangJingGeScreenState();
}

class _CangJingGeScreenState extends ConsumerState<CangJingGeScreen> {
  late int _selectedCharacterId = widget.characterId;

  /// 已对哪些角色跑过进入 autoFill（避免重复 / setState 后重跑）。
  final Set<int> _autoFilledIds = {};

  @override
  Widget build(BuildContext context) {
    final idsAsync = ref.watch(activeCharacterIdsProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.cangjingLoadoutTitle,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
        trailing: const ContextHelpButton(topic: HelpTopic.mainTechnique),
      ),
      body: SafeArea(
        child: idsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(activeCharacterIdsProvider),
          ),
          data: (ids) {
            final list = ids.isEmpty ? [widget.characterId] : ids;
            final effectiveId = list.contains(_selectedCharacterId)
                ? _selectedCharacterId
                : list.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (list.length > 1)
                  _CharacterTabBar(
                    ids: list,
                    selectedId: effectiveId,
                    onSelect: (id) => setState(() => _selectedCharacterId = id),
                  ),
                Expanded(child: _bodyFor(effectiveId)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bodyFor(int characterId) {
    final async = ref.watch(characterByIdProvider(characterId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorFallback(
        error: e,
        onRetry: () => ref.invalidate(characterByIdProvider(characterId)),
      ),
      data: (c) {
        if (c == null) {
          return const Center(
            child: Text(
              UiStrings.characterNotFound,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          );
        }
        // 进入时 autoFill（每角色一次，首帧后触发）。
        if (!_autoFilledIds.contains(c.id)) {
          _autoFilledIds.add(c.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyAutoFill(c);
          });
        }
        return _CangJingGeBody(character: c, onChanged: _refresh);
      },
    );
  }

  Future<void> _applyAutoFill(Character character) async {
    final isar = ref.read(isarProvider);
    if (isar == null) return; // 测试旁路 / 未 init
    final repo = GameRepository.instance;
    final numbers = ref.read(numbersConfigProvider);
    final resolver = SkillLoadoutResolver(isar: isar);
    final sources = await resolver.resolve(
      character,
      repository: repo,
      numbers: numbers,
    );
    // 第六阶段 Task 6 — 职责软引导：传入角色 lineage 身份，autoFill 按角色倾向填槽。
    await SkillLoadoutService(isar).applyAutoFill(
      characterId: character.id,
      mainTechniqueSkills: sources.mainTechniqueSkills,
      assistTechniqueSkills: sources.assistTechniqueSkills,
      jointSkill: sources.jointSkill,
      ultimatePowerThreshold: numbers.loadoutUltimatePowerThreshold,
      interruptSkills: sources.interruptSkills,
      lineageRole: character.lineageRole,
      isFounder: character.isFounder,
    );
    if (!mounted) return;
    _refresh(character.id);
  }

  void _refresh(int characterId) {
    ref.invalidate(characterByIdProvider(characterId));
    ref.invalidate(characterAllTechniquesProvider(characterId));
    ref.invalidate(unlockedSkillIdSetProvider);
  }
}

/// 角色切换 tab（多角色时显示，单角色省略）。
class _CharacterTabBar extends ConsumerWidget {
  const _CharacterTabBar({
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });

  final List<int> ids;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < ids.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == ids.length - 1 ? 0 : 10),
              child: _CharacterPlaqueTab(
                characterId: ids[i],
                fallbackLabel: i < UiStrings.lineageTabLabels.length
                    ? UiStrings.lineageTabLabels[i]
                    : '#${ids[i]}',
                selected: ids[i] == selectedId,
                onTap: () => onSelect(ids[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _CharacterPlaqueTab extends ConsumerWidget {
  const _CharacterPlaqueTab({
    required this.characterId,
    required this.fallbackLabel,
    required this.selected,
    required this.onTap,
  });

  final int characterId;
  final String fallbackLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(characterByIdProvider(characterId));
    final label = async.asData?.value?.name ?? fallbackLabel;
    return PlaqueTab(label: label, selected: selected, onTap: onTap);
  }
}

/// 主屏 body：出战配置栏 + 武学库 + 残页收集区。
class _CangJingGeBody extends ConsumerWidget {
  const _CangJingGeBody({required this.character, required this.onChanged});

  final Character character;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoadoutSection(character: character, onChanged: onChanged),
          const SizedBox(height: 16),
          _LibrarySection(character: character, onChanged: onChanged),
          const SizedBox(height: 16),
          const _FragmentSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. 出战配置栏
// ─────────────────────────────────────────────────────────────────────────────

/// 装配槽类型（5 心法槽 + 1 破招槽 + 1 奇遇槽）。
enum _SlotKind { main1, main2, assist, resonance, ultimate, key, encounter }

class _LoadoutSection extends ConsumerWidget {
  const _LoadoutSection({required this.character, required this.onChanged});

  final Character character;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const kinds = _SlotKind.values;
    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.cangjingLoadoutTitle),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              UiStrings.cangjingLoadoutHint,
              style: TextStyle(color: WuxiaUi.muted, fontSize: 12),
            ),
          ),
          // 7 槽按行排,每行 3 列,尾行不足补空位(波A 加破招槽 6→7)。
          for (var start = 0; start < kinds.length; start += 3) ...[
            if (start > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: start + col < kinds.length
                        ? _SlotTile(
                            character: character,
                            kind: kinds[start + col],
                            onChanged: onChanged,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotTile extends ConsumerWidget {
  const _SlotTile({
    required this.character,
    required this.kind,
    required this.onChanged,
  });

  final Character character;
  final _SlotKind kind;
  final ValueChanged<int> onChanged;

  String get _label => switch (kind) {
    _SlotKind.main1 => UiStrings.cangjingSlotMain(1),
    _SlotKind.main2 => UiStrings.cangjingSlotMain(2),
    _SlotKind.assist => UiStrings.cangjingSlotAssist,
    _SlotKind.resonance => UiStrings.cangjingSlotResonance,
    _SlotKind.ultimate => UiStrings.cangjingSlotUltimate,
    _SlotKind.key => UiStrings.cangjingSlotKey,
    _SlotKind.encounter => UiStrings.cangjingSlotEncounter,
  };

  String get _hint => switch (kind) {
    _SlotKind.main1 => UiStrings.cangjingSlotHintMain1,
    _SlotKind.main2 => UiStrings.cangjingSlotHintMain2,
    _SlotKind.assist => UiStrings.cangjingSlotHintAssist,
    _SlotKind.resonance => UiStrings.cangjingSlotHintResonance,
    _SlotKind.ultimate => UiStrings.cangjingSlotHintUltimate,
    _SlotKind.key => UiStrings.cangjingSlotHintKey,
    _SlotKind.encounter => UiStrings.cangjingSlotHintEncounter,
  };

  String? get _equippedId => switch (kind) {
    _SlotKind.main1 => character.mainSkillId1,
    _SlotKind.main2 => character.mainSkillId2,
    _SlotKind.assist => character.assistSkillId,
    _SlotKind.resonance => character.resonanceSkillId,
    _SlotKind.ultimate => character.ultimateSkillId,
    _SlotKind.key => character.keySkillId,
    _SlotKind.encounter => character.equippedEncounterSkillId,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = _equippedId;
    final skillName = (id != null && GameRepository.isLoaded)
        ? GameRepository.instance.skillDefs[id]?.name
        : null;
    return InkWell(
      onTap: () => _onTap(context, ref),
      borderRadius: BorderRadius.circular(WuxiaUi.radius),
      child: IntrinsicHeight(
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: WuxiaUi.panelFill,
            borderRadius: BorderRadius.circular(WuxiaUi.radius),
            border: Border.all(
              color: id == null
                  ? WuxiaUi.muted.withValues(alpha: 0.5)
                  : WuxiaUi.qing,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label,
                style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                skillName ?? UiStrings.cangjingSlotEmpty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skillName != null ? WuxiaUi.ink : WuxiaUi.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: WuxiaUi.muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final isar = ref.read(isarProvider);
    if (isar == null || !GameRepository.isLoaded) return;
    final repo = GameRepository.instance;
    final numbers = ref.read(numbersConfigProvider);

    if (kind == _SlotKind.encounter) {
      await _pickEncounter(context, ref);
      return;
    }

    final candidates = await _candidatesFor(isar, repo, numbers);
    if (!context.mounted) return;
    final picked = await openSkillSlotPicker(
      context,
      candidates: candidates,
      currentRealmTier: character.realmTier,
      equippedId: _equippedId,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final result = await SkillLoadoutService(isar).equipSkill(
      characterId: character.id,
      slot: _toSkillSlot(kind),
      skillId: picked.id,
    );
    if (!context.mounted) return;
    if (result is SlotEquipTierLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingTierLocked)),
      );
      return;
    }
    if (result is SlotEquipStyleLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingStyleLocked)),
      );
      return;
    }
    if (result is SlotEquipNotUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingNotUnlocked)),
      );
      return;
    }
    onChanged(character.id);
  }

  /// 按槽类型过滤候选招式：
  /// - main1/main2/ultimate → 主修心法招
  /// - assist → 辅修心法招
  /// - resonance → joint 共鸣招（解锁则单元素列表，否则空）
  Future<List<SkillDef>> _candidatesFor(
    Isar isar,
    GameRepository repo,
    NumbersConfig numbers,
  ) async {
    final resolver = SkillLoadoutResolver(isar: isar);
    final sources = await resolver.resolve(
      character,
      repository: repo,
      numbers: numbers,
    );
    // 单一真相源:槽→候选招走 candidatesForSlot(与武学库直接装配 T6 反查对称)。
    return candidatesForSlot(_toSkillSlot(kind), sources, character.school);
  }

  /// 奇遇槽走 [EncounterService.equipEncounterSkill]，候选 = 已解锁奇遇招
  /// (波A A4:读 SaveData.skillUnlockProgress 单一真相源,只取奇遇招)。
  Future<void> _pickEncounter(BuildContext context, WidgetRef ref) async {
    final repo = GameRepository.instance;
    final unlockedSet = await ref.read(unlockedSkillIdSetProvider.future);
    final unlocked = unlockedSet
        .where(repo.encounterSkillIds.contains)
        .toList();
    final candidates =
        unlocked.map((id) => repo.skillDefs[id]).whereType<SkillDef>().toList()
          ..sort((a, b) {
            final t = (a.tier ?? 0).compareTo(b.tier ?? 0);
            return t != 0 ? t : a.id.compareTo(b.id);
          });
    if (!context.mounted) return;
    final picked = await openSkillSlotPicker(
      context,
      candidates: candidates,
      currentRealmTier: character.realmTier,
      equippedId: character.equippedEncounterSkillId,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final svc = ref.read(encounterServiceProvider);
    if (svc == null) return;
    final result = await svc.equipEncounterSkill(
      characterId: character.id,
      skillDef: picked,
      saveDataId: IsarSetup.currentSlotId,
    );
    if (!context.mounted) return;
    if (result is EquipTierLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingTierLocked)),
      );
      return;
    }
    onChanged(character.id);
  }

  SkillSlot _toSkillSlot(_SlotKind k) => switch (k) {
    _SlotKind.main1 => SkillSlot.main1,
    _SlotKind.main2 => SkillSlot.main2,
    _SlotKind.assist => SkillSlot.assist,
    _SlotKind.resonance => SkillSlot.resonance,
    _SlotKind.ultimate => SkillSlot.ultimate,
    _SlotKind.key => SkillSlot.key,
    _SlotKind.encounter => throw StateError(
      'encounter 槽不走 SkillLoadoutService',
    ),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. 武学库
// ─────────────────────────────────────────────────────────────────────────────

/// 武学库：按主修/辅修心法分组，每招一行 [SkillProficiencyRow]。
///
/// uses 从对应 [Technique.skillUsageCount] 取；equipped = 该招 id 在某装配槽。
class _LibrarySection extends ConsumerWidget {
  const _LibrarySection({required this.character, required this.onChanged});

  final Character character;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techsAsync = ref.watch(characterAllTechniquesProvider(character.id));
    final numbers = ref.watch(numbersConfigProvider);
    final unlockedAsync = ref.watch(unlockedSkillIdSetProvider);
    final equippedIds = <String>{
      ?character.mainSkillId1,
      ?character.mainSkillId2,
      ?character.assistSkillId,
      ?character.resonanceSkillId,
      ?character.ultimateSkillId,
      ?character.keySkillId,
      ?character.equippedEncounterSkillId,
    };

    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.cangjingLibraryTitle),
          techsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () =>
                  ref.invalidate(characterAllTechniquesProvider(character.id)),
            ),
            data: (techs) => _buildGroups(
              context,
              ref,
              techs,
              numbers,
              equippedIds,
              unlockedAsync.value ?? const <String>{},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroups(
    BuildContext context,
    WidgetRef ref,
    List<Technique> techs,
    NumbersConfig numbers,
    Set<String> equippedIds,
    Set<String> unlockedIds,
  ) {
    if (!GameRepository.isLoaded) return const SizedBox.shrink();
    final repo = GameRepository.instance;
    // 主修优先，其余按学得顺序。
    final sorted = [...techs]
      ..sort((a, b) {
        if (a.role == b.role) return 0;
        return a.role == TechniqueRole.main ? -1 : 1;
      });

    final groups = <Widget>[];
    for (final tech in sorted) {
      final TechniqueDef? techDef = repo.techniqueDefs[tech.defId];
      if (techDef == null) continue;
      final rows = <Widget>[];
      for (final skillId in techDef.skillIds) {
        final skill = repo.skillDefs[skillId];
        if (skill == null) continue;
        rows.add(
          SkillProficiencyRow(
            skill: skill,
            uses: tech.skillUsageCount.countOf(skillId),
            cfg: numbers.skillProficiency,
            equipped: equippedIds.contains(skillId),
            onTap: () => _equipFromLibrary(context, ref, skill),
          ),
        );
      }
      if (rows.isEmpty) continue;
      groups.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tech.role == TechniqueRole.main
                    ? '${techDef.name} · ${UiStrings.techniqueRoleMain}'
                    : '${techDef.name} · ${UiStrings.techniqueRoleAssist}',
                style: const TextStyle(
                  color: WuxiaUi.qing,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              ...rows,
            ],
          ),
        ),
      );
    }

    // 波B 秘传组:已解锁 + 本流派的真解/残页招(与装配池同一过滤语义)。
    // uses 计入主修 skillUsageCount(battle_resolution standalone 落账)。
    final school = character.school;
    if (school != null) {
      final mainTech = sorted
          .where((t) => t.role == TechniqueRole.main)
          .toList();
      final secretRows = <Widget>[];
      final drops =
          repo.skillDefs.values
              .where(
                (s) =>
                    (s.source == SkillSource.mainlineDrop ||
                        s.source == SkillSource.fragment) &&
                    s.style == school &&
                    unlockedIds.contains(s.id),
              )
              .toList()
            ..sort((a, b) {
              final t = (a.tier ?? 0).compareTo(b.tier ?? 0);
              return t != 0 ? t : a.id.compareTo(b.id);
            });
      for (final skill in drops) {
        secretRows.add(
          SkillProficiencyRow(
            skill: skill,
            uses: mainTech.isEmpty
                ? 0
                : mainTech.first.skillUsageCount.countOf(skill.id),
            cfg: numbers.skillProficiency,
            equipped: equippedIds.contains(skill.id),
            onTap: () => _equipFromLibrary(context, ref, skill),
          ),
        );
      }
      if (secretRows.isNotEmpty) {
        groups.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  UiStrings.cangjingSecretGroupTitle,
                  style: TextStyle(
                    color: WuxiaUi.qing,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                ...secretRows,
              ],
            ),
          ),
        );
      }
    }

    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          UiStrings.techniquePanelEmpty,
          style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups,
    );
  }

  /// T6 武学库直接装配:点招式行 → 算合法槽 → 选槽面板 → 走 service 落库 → 刷新。
  /// 合法性(境界/流派/解锁)仍由 [SkillLoadoutService.equipSkill] sealed result 守。
  Future<void> _equipFromLibrary(
    BuildContext context,
    WidgetRef ref,
    SkillDef skill,
  ) async {
    final isar = ref.read(isarProvider);
    if (isar == null || !GameRepository.isLoaded) return;
    final repo = GameRepository.instance;
    final numbers = ref.read(numbersConfigProvider);
    final resolver = SkillLoadoutResolver(isar: isar);
    final sources = await resolver.resolve(
      character,
      repository: repo,
      numbers: numbers,
    );
    final legal = legalSlotsForSkill(skill.id, sources, character.school);
    if (!context.mounted) return;
    if (legal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingNoLegalSlot)),
      );
      return;
    }
    final slot = await _pickSlot(context, legal);
    if (slot == null) return;
    if (!context.mounted) return;

    final result = await SkillLoadoutService(
      isar,
    ).equipSkill(characterId: character.id, slot: slot, skillId: skill.id);
    if (!context.mounted) return;
    if (result is SlotEquipTierLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingTierLocked)),
      );
      return;
    }
    if (result is SlotEquipStyleLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingStyleLocked)),
      );
      return;
    }
    if (result is SlotEquipNotUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.cangjingNotUnlocked)),
      );
      return;
    }
    onChanged(character.id);
  }

  /// 选槽 bottom sheet:列出该招的合法槽,玩家点选返回(null = 取消)。
  Future<SkillSlot?> _pickSlot(BuildContext context, List<SkillSlot> slots) {
    return showModalBottomSheet<SkillSlot>(
      context: context,
      backgroundColor: WuxiaColors.panel,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                UiStrings.cangjingEquipToSlotTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1, color: WuxiaColors.border),
            for (final s in slots)
              ListTile(
                title: Text(
                  _slotLabel(s),
                  style: const TextStyle(color: WuxiaColors.textPrimary),
                ),
                trailing: const Icon(
                  Icons.add,
                  color: WuxiaColors.textSecondary,
                  size: 18,
                ),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
  }

  String _slotLabel(SkillSlot slot) => switch (slot) {
    SkillSlot.main1 => UiStrings.cangjingSlotMain(1),
    SkillSlot.main2 => UiStrings.cangjingSlotMain(2),
    SkillSlot.assist => UiStrings.cangjingSlotAssist,
    SkillSlot.resonance => UiStrings.cangjingSlotResonance,
    SkillSlot.ultimate => UiStrings.cangjingSlotUltimate,
    SkillSlot.key => UiStrings.cangjingSlotKey,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 残页收集区
// ─────────────────────────────────────────────────────────────────────────────

/// 残页收集区：遍历 [SaveData.skillUnlockProgress] 中
/// `fragmentCount > 0 && !unlocked` 的条目，每条 [FragmentProgressRow]。
class _FragmentSection extends ConsumerWidget {
  const _FragmentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(_fragmentEntriesProvider);
    return PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.cangjingFragmentTitle),
          entriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(_fragmentEntriesProvider),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    UiStrings.cangjingFragmentEmpty,
                    style: TextStyle(color: WuxiaUi.muted, fontSize: 12),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in entries)
                    FragmentProgressRow(
                      name: e.name,
                      has: e.has,
                      total: e.total,
                      source: e.source,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FragmentEntry {
  const _FragmentEntry({
    required this.name,
    required this.has,
    required this.total,
    this.source,
  });
  final String name;
  final int has;
  final int total;
  final String? source;
}

/// 残页进度条目（收集中 = 有残页未解锁）。fragmentThreshold 默认 5（与
/// [SkillUnlockService] 一致）。Isar 未 init 返空列表（测试旁路）。
final _fragmentEntriesProvider = FutureProvider<List<_FragmentEntry>>((
  ref,
) async {
  final isar = ref.watch(isarProvider);
  if (isar == null || !GameRepository.isLoaded) return const [];
  final SaveData? save = await isar.saveDatas.get(0);
  if (save == null) return const [];
  final repo = GameRepository.instance;
  const threshold = 5;
  final result = <_FragmentEntry>[];
  for (final SkillUnlockEntry e in save.skillUnlockProgress) {
    if (e.unlocked || e.fragmentCount <= 0) continue;
    final name = repo.skillDefs[e.skillId]?.name ?? e.skillId;
    final source = fragmentSourceLabel(
      e.skillId,
      floors: repo.towerFloors,
      stages: repo.stageDefs.values,
    );
    result.add(
      _FragmentEntry(
        name: name,
        has: e.fragmentCount,
        total: threshold,
        source: source,
      ),
    );
  }
  return result;
});
