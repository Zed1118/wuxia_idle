import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../cultivation/application/synergy_service.dart';
import '../../inheritance/application/founder_buff_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import 'encounter_skill_section.dart';

/// 角色面板（phase2_tasks.md T28 + Phase 3 Week 4 T56）。
///
/// T28 单角色版面 → T56 顶部 Tab 三角色切换 + 「师承」段。布局：
/// - 顶部：TabBar（祖师 / 大弟子 / 二弟子）从 [activeCharacterIdsProvider] 读 id
/// - 中部：姓名 / 境界 / 流派色条 / 4 项属性 / 5 项派生数值（含师承 +5% 内力上限）
/// - 装备区：3 槽（武器 / 护甲 / 饰品），未装备显示灰色占位
/// - 心法区：主修高亮 + 3 辅修槽 + 修炼度进度条
/// - 师承段：师父 / 徒弟 / 传记占位 / 师承遗物列表
///
/// `initialCharacterId` 构造参数指定首屏 Tab；其他 Tab 切换走内部 state。
/// 不显示装备/心法名字（spec §403/§404 未要求，避免硬编码中文文案风险），
/// 但师承遗物 section 显示装备名（走 GameRepository.getEquipment(defId).name）。
class CharacterPanelScreen extends ConsumerStatefulWidget {
  const CharacterPanelScreen({super.key, required this.characterId});

  /// 首屏展示的角色 id（与既有 main_menu / Phase2SeedService 对齐）。
  final int characterId;

  @override
  ConsumerState<CharacterPanelScreen> createState() =>
      _CharacterPanelScreenState();
}

class _CharacterPanelScreenState extends ConsumerState<CharacterPanelScreen> {
  late int _selectedCharacterId = widget.characterId;

  @override
  Widget build(BuildContext context) {
    final idsAsync = ref.watch(activeCharacterIdsProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text('角色面板'),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: idsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (ids) => _PanelWithTabs(
            ids: ids.isEmpty ? [widget.characterId] : ids,
            selectedId: _selectedCharacterId,
            onSelect: (id) => setState(() => _selectedCharacterId = id),
          ),
        ),
      ),
    );
  }
}

class _PanelWithTabs extends ConsumerWidget {
  const _PanelWithTabs({
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });

  final List<int> ids;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 若构造时传入的 characterId 不在 activeCharacterIds 内（例如老存档），
    // 兜底切到第一位，避免渲染 _Body 时 character 一直 null。
    final effectiveId = ids.contains(selectedId) ? selectedId : ids.first;
    final async = ref.watch(characterByIdProvider(effectiveId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LineageTabBar(
          ids: ids,
          selectedId: effectiveId,
          onSelect: onSelect,
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: SelectableText(
                'load error: $e',
                style: const TextStyle(color: WuxiaColors.hpLow),
              ),
            ),
            data: (c) => c == null
                ? const Center(
                    child: Text(
                      '角色不存在',
                      style: TextStyle(color: WuxiaColors.textMuted),
                    ),
                  )
                : _Body(character: c),
          ),
        ),
      ],
    );
  }
}

class _LineageTabBar extends StatelessWidget {
  const _LineageTabBar({
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });

  final List<int> ids;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(
          bottom: BorderSide(color: WuxiaColors.border),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < ids.length && i < UiStrings.lineageTabLabels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == ids.length - 1 ? 0 : 8),
                child: _LineageTab(
                  label: UiStrings.lineageTabLabels[i],
                  selected: ids[i] == selectedId,
                  onTap: () => onSelect(ids[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineageTab extends StatelessWidget {
  const _LineageTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? WuxiaColors.textPrimary : WuxiaColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WuxiaColors.avatarFill : Colors.transparent,
          border: Border.all(
            color: selected ? WuxiaColors.textPrimary : WuxiaColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(character: character),
          const SizedBox(height: 16),
          _AttributesSection(character: character),
          const SizedBox(height: 16),
          _DerivedStatsSection(character: character),
          const SizedBox(height: 16),
          _EquipmentSection(character: character),
          const SizedBox(height: 16),
          _TechniqueSection(character: character),
          const SizedBox(height: 16),
          EncounterSkillSection(character: character),
          const SizedBox(height: 16),
          _LineageSection(character: character),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    return _PanelCard(
      child: Row(
        children: [
          Container(width: 4, height: 36, color: schoolColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  EnumL10n.realm(character.realmTier, character.realmLayer),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributesSection extends StatelessWidget {
  const _AttributesSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final a = character.attributes;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelAttributes),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LabeledValue(
                  label: UiStrings.attrConstitution,
                  value: '${a.constitution}',
                ),
              ),
              Expanded(
                child: _LabeledValue(
                  label: UiStrings.attrEnlightenment,
                  value: '${a.enlightenment}',
                ),
              ),
              Expanded(
                child: _LabeledValue(
                  label: UiStrings.attrAgility,
                  value: '${a.agility}',
                ),
              ),
              Expanded(
                child: _LabeledValue(
                  label: UiStrings.attrFortune,
                  value: '${a.fortune}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 派生数值需要等装备 + 主修 ready 才能算。
///
/// 三件装备 + 主修共 4 个 family AsyncValue 串成同步等待；任一未 ready 显示
/// 占位，避免「半个面板」闪烁。`equippedXxxId` 为 null 的槽直接当作未装备
/// （不 watch 对应 provider），不进入 equipped 列表参与公式。
class _DerivedStatsSection extends ConsumerWidget {
  const _DerivedStatsSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipped = _watchEquipped(ref);
    final mainAsync = character.mainTechniqueId == null
        ? const AsyncData<Technique?>(null)
        : ref.watch(techniqueByIdProvider(character.mainTechniqueId!));

    final ready = equipped.every((a) => a.hasValue) && mainAsync.hasValue;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelDerived),
          const SizedBox(height: 8),
          if (!ready)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _renderStats(
              context,
              ref,
              equipped: equipped
                  .map((a) => a.value)
                  .whereType<Equipment>()
                  .toList(),
              mainTech: mainAsync.value,
            ),
        ],
      ),
    );
  }

  List<AsyncValue<Equipment?>> _watchEquipped(WidgetRef ref) {
    final ids = [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ];
    return ids
        .map(
          (id) => id == null
              ? const AsyncData<Equipment?>(null)
              : ref.watch(equipmentByIdProvider(id)),
        )
        .toList();
  }

  Widget _renderStats(
    BuildContext context,
    WidgetRef ref, {
    required List<Equipment> equipped,
    required Technique? mainTech,
  }) {
    final n = ref.watch(numbersConfigProvider);
    // P1.1 A1 E.5:祖师爷 buff 激活态,loading/error 默认 false 兜底
    final founderBuffActive = ref
        .watch(founderBuffActiveProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);
    final hp = CharacterDerivedStats.maxHp(
      character,
      equipped,
      n,
      founderBuffActive: founderBuffActive,
    );
    final ifMax = CharacterDerivedStats.internalForceMaxWithLineage(
      character,
      equipped,
      n,
      founderBuffActive: founderBuffActive,
    );
    final speedText = mainTech == null
        ? UiStrings.dashPlaceholder
        : '${CharacterDerivedStats.speed(character, equipped, mainTech, n)}';
    final critText = UiStrings.percent(
      CharacterDerivedStats.criticalRate(
        character,
        n,
        founderBuffActive: founderBuffActive,
      ),
    );
    final evadeText = UiStrings.percent(
      CharacterDerivedStats.evasionRate(character, n),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledValue(label: UiStrings.statHp, value: '$hp'),
            ),
            Expanded(
              child: _LabeledValue(
                label: UiStrings.statInternalForce,
                value: UiStrings.internalForceValue(
                  character.internalForce,
                  ifMax,
                ),
              ),
            ),
            Expanded(
              child: _LabeledValue(
                label: UiStrings.statSpeed,
                value: speedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LabeledValue(
                label: UiStrings.statCriticalRate,
                value: critText,
              ),
            ),
            Expanded(
              child: _LabeledValue(
                label: UiStrings.statEvasionRate,
                value: evadeText,
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelEquipment),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EquipmentSlotTile(
                  slot: EquipmentSlot.weapon,
                  equipmentId: character.equippedWeaponId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EquipmentSlotTile(
                  slot: EquipmentSlot.armor,
                  equipmentId: character.equippedArmorId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EquipmentSlotTile(
                  slot: EquipmentSlot.accessory,
                  equipmentId: character.equippedAccessoryId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个装备槽。`equipmentId == null` 时直接渲染未装备占位，**不 watch**
/// family（避免 null id 进 provider）。
class _EquipmentSlotTile extends ConsumerWidget {
  const _EquipmentSlotTile({required this.slot, required this.equipmentId});

  final EquipmentSlot slot;
  final int? equipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotLabel = EnumL10n.equipmentSlot(slot);
    if (equipmentId == null) {
      return _SlotShell(
        borderColor: WuxiaColors.buttonDisabled,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slotLabel,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              UiStrings.slotEmpty,
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    final async = ref.watch(equipmentByIdProvider(equipmentId!));
    final n = ref.watch(numbersConfigProvider);
    return async.when(
      loading: () => const _SlotShell(
        borderColor: WuxiaColors.border,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _SlotShell(
        borderColor: WuxiaColors.hpLow,
        child: Text(
          '$e',
          style: const TextStyle(color: WuxiaColors.hpLow, fontSize: 11),
        ),
      ),
      data: (eq) {
        if (eq == null) {
          return _SlotShell(
            borderColor: WuxiaColors.buttonDisabled,
            child: Center(
              child: Text(
                slotLabel,
                style: const TextStyle(color: WuxiaColors.textMuted),
              ),
            ),
          );
        }
        final tierColor = tierColorForEquipment(eq.tier);
        final resonance = eq.resonanceStage(n);
        return _SlotShell(
          borderColor: tierColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    EnumL10n.equipmentSlot(eq.slot),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    UiStrings.enhanceLevel(eq.enhanceLevel),
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                EnumL10n.equipmentTier(eq.tier),
                style: TextStyle(color: tierColor, fontSize: 13),
              ),
              const SizedBox(height: 4),
              // W12 fix: 视觉验收 debug 字段——battleCount 数字直显
              // 之前只显「生疏/趁手/...」共鸣段 chip，Codex 无法验证 victory 后 ++；
              // 与 resonance 同行节省高度（_SlotShell 固定 88px 不溢出）
              Row(
                children: [
                  Text(
                    EnumL10n.resonanceStage(resonance),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${eq.battleCount}',
                    style: const TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechniqueSection extends StatelessWidget {
  const _TechniqueSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final assistIds = character.assistTechniqueIds;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelTechnique),
          const SizedBox(height: 8),
          _MainTechniqueTile(techniqueId: character.mainTechniqueId),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final id = i < assistIds.length ? assistIds[i] : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                  child: _AssistTechniqueTile(techniqueId: id),
                ),
              );
            }),
          ),
          // W18-A1 心法相生 chip(GDD §4.5):0/1 个,命中即显
          _SynergyChip(character: character),
        ],
      ),
    );
  }
}

/// W18-A1 心法相生 chip(GDD §4.5)。
///
/// watch 主修 + 第 1 辅修两个 [techniqueByIdProvider],都 ready 后调
/// [SynergyService.detectActive] 同步判定;命中即显 name + multiplier 摘要
/// chip,否则隐藏(0/1 个,与服务层语义一致)。
class _SynergyChip extends ConsumerWidget {
  const _SynergyChip({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainId = character.mainTechniqueId;
    if (mainId == null || character.assistTechniqueIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final assistId = character.assistTechniqueIds.first;
    final mainAsync = ref.watch(techniqueByIdProvider(mainId));
    final assistAsync = ref.watch(techniqueByIdProvider(assistId));

    if (!mainAsync.hasValue || !assistAsync.hasValue) {
      return const SizedBox.shrink();
    }
    final mainTech = mainAsync.value;
    final assistTech = assistAsync.value;
    if (mainTech == null || assistTech == null) {
      return const SizedBox.shrink();
    }

    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: [mainTech, assistTech],
      techDefLookup: (defId) =>
          GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    if (synergy == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: WuxiaColors.resultHighlight,
            ),
            const SizedBox(width: 6),
            const Text(
              UiStrings.synergyActiveLabel,
              style: TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${synergy.name} · ${synergy.multipliers.summary()}',
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 12.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainTechniqueTile extends ConsumerWidget {
  const _MainTechniqueTile({required this.techniqueId});

  final int? techniqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (techniqueId == null) {
      return const _TechniqueShell(
        borderColor: WuxiaColors.buttonDisabled,
        child: Row(
          children: [
            Text(
              UiStrings.techniqueRoleMain,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
            ),
            SizedBox(width: 8),
            Text(
              UiStrings.noMainTechnique,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    final async = ref.watch(techniqueByIdProvider(techniqueId!));
    return async.when(
      loading: () => const _TechniqueShell(
        borderColor: WuxiaColors.border,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _TechniqueShell(
        borderColor: WuxiaColors.hpLow,
        child: Text('$e', style: const TextStyle(color: WuxiaColors.hpLow)),
      ),
      data: (t) {
        if (t == null) {
          return const _TechniqueShell(
            borderColor: WuxiaColors.buttonDisabled,
            child: Text(
              UiStrings.noMainTechnique,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          );
        }
        final schoolColor = WuxiaColors.schoolColor(t.school);
        final progress = t.cultivationProgressToNext == 0
            ? 0.0
            : (t.cultivationProgress / t.cultivationProgressToNext)
                  .clamp(0.0, 1.0)
                  .toDouble();
        return _TechniqueShell(
          borderColor: schoolColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    UiStrings.techniqueRoleMain,
                    style: TextStyle(
                      color: schoolColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    EnumL10n.techniqueTier(t.tier),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    EnumL10n.cultivationLayer(t.cultivationLayer),
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: WuxiaColors.barTrack,
                valueColor: AlwaysStoppedAnimation<Color>(schoolColor),
              ),
              const SizedBox(height: 4),
              Text(
                UiStrings.cultivationProgress(
                  t.cultivationProgress,
                  t.cultivationProgressToNext,
                ),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssistTechniqueTile extends ConsumerWidget {
  const _AssistTechniqueTile({required this.techniqueId});

  final int? techniqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (techniqueId == null) {
      return const _SlotShell(
        borderColor: WuxiaColors.buttonDisabled,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              UiStrings.techniqueRoleAssist,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              UiStrings.techniqueEmpty,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    final async = ref.watch(techniqueByIdProvider(techniqueId!));
    return async.when(
      loading: () => const _SlotShell(
        borderColor: WuxiaColors.border,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _SlotShell(
        borderColor: WuxiaColors.hpLow,
        child: Text('$e', style: const TextStyle(color: WuxiaColors.hpLow)),
      ),
      data: (t) {
        if (t == null) {
          return const _SlotShell(
            borderColor: WuxiaColors.buttonDisabled,
            child: Center(
              child: Text(
                UiStrings.techniqueEmpty,
                style: TextStyle(color: WuxiaColors.textMuted),
              ),
            ),
          );
        }
        final schoolColor = WuxiaColors.schoolColor(t.school);
        return _SlotShell(
          borderColor: schoolColor.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                UiStrings.techniqueRoleAssist,
                style: TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                EnumL10n.techniqueTier(t.tier),
                style: TextStyle(color: schoolColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                EnumL10n.cultivationLayer(t.cultivationLayer),
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 师承段（T56，GDD §7.1）
// ─────────────────────────────────────────────────────────────────────────────

class _LineageSection extends ConsumerWidget {
  const _LineageSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelLineage),
          const SizedBox(height: 8),
          _LineageMasterRow(masterId: character.masterId),
          const SizedBox(height: 6),
          _LineageDisciplesRow(discipleIds: character.discipleIds),
          const SizedBox(height: 6),
          const _LineageBiographyRow(),
          const SizedBox(height: 6),
          _LineageHeritageRow(character: character),
        ],
      ),
    );
  }
}

class _LineageMasterRow extends ConsumerWidget {
  const _LineageMasterRow({required this.masterId});

  final int? masterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (masterId == null) {
      return const _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: UiStrings.lineageNoMaster,
      );
    }
    final async = ref.watch(characterByIdProvider(masterId!));
    return async.when(
      loading: () => const _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: UiStrings.dashPlaceholder,
      ),
      error: (e, _) => _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: '$e',
        valueColor: WuxiaColors.hpLow,
      ),
      data: (m) => _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: m == null ? UiStrings.lineageNoMaster : m.name,
      ),
    );
  }
}

class _LineageDisciplesRow extends ConsumerWidget {
  const _LineageDisciplesRow({required this.discipleIds});

  final List<int> discipleIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (discipleIds.isEmpty) {
      return const _LineageRow(
        label: UiStrings.lineageDisciplesLabel,
        value: UiStrings.lineageNoDisciples,
      );
    }
    final asyncs = discipleIds
        .map((id) => ref.watch(characterByIdProvider(id)))
        .toList();
    if (asyncs.any((a) => a.isLoading)) {
      return const _LineageRow(
        label: UiStrings.lineageDisciplesLabel,
        value: UiStrings.dashPlaceholder,
      );
    }
    final names = asyncs
        .map((a) => a.value)
        .whereType<Character>()
        .map((c) => c.name)
        .toList();
    return _LineageRow(
      label: UiStrings.lineageDisciplesLabel,
      value: names.isEmpty ? UiStrings.lineageNoDisciples : names.join(' / '),
    );
  }
}

class _LineageBiographyRow extends StatelessWidget {
  const _LineageBiographyRow();

  @override
  Widget build(BuildContext context) {
    return const _LineageRow(
      label: UiStrings.lineageBiographyLabel,
      value: UiStrings.lineageBiographyPlaceholder,
      valueColor: WuxiaColors.textMuted,
    );
  }
}

class _LineageHeritageRow extends ConsumerWidget {
  const _LineageHeritageRow({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ].whereType<int>().toList();
    if (ids.isEmpty) {
      return const _LineageRow(
        label: UiStrings.lineageHeritageLabel,
        value: UiStrings.lineageNoHeritage,
      );
    }
    final asyncs = ids.map((id) => ref.watch(equipmentByIdProvider(id))).toList();
    if (asyncs.any((a) => a.isLoading)) {
      return const _LineageRow(
        label: UiStrings.lineageHeritageLabel,
        value: UiStrings.dashPlaceholder,
      );
    }
    final heritage = asyncs
        .map((a) => a.value)
        .whereType<Equipment>()
        .where((e) => e.isLineageHeritage)
        .toList();
    final names = heritage.map(_resolveName).toList();
    final mainRow = _LineageRow(
      label: UiStrings.lineageHeritageLabel,
      value: names.isEmpty ? UiStrings.lineageNoHeritage : names.join(' / '),
    );
    if (heritage.isEmpty) return mainRow;
    // P5+ 多代传承 chip:取所装 heritage 件中 prev len 最大值,> 1 时显「{N} 代
    // 传承」副行(N = prevLen + 1 算上当前持有者)。语义:gen2 起 chip 才出现
    // (gen1 prev=[founder] · 玩家眼中只是「师父传的」不需 chip 提醒)。
    final maxPrevLen = heritage.fold<int>(
      0,
      (m, e) => e.previousOwnerCharacterIds.length > m
          ? e.previousOwnerCharacterIds.length
          : m,
    );
    if (maxPrevLen <= 1) return mainRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainRow,
        const SizedBox(height: 2),
        _LineageRow(
          label: '',
          value: UiStrings.ascensionMultiGenChip
              .replaceFirst('{0}', '${maxPrevLen + 1}'),
          valueColor: WuxiaColors.textMuted,
        ),
      ],
    );
  }

  String _resolveName(Equipment eq) {
    if (!GameRepository.isLoaded) return eq.defId;
    return GameRepository.instance.equipmentDefs[eq.defId]?.name ?? eq.defId;
  }
}

class _LineageRow extends StatelessWidget {
  const _LineageRow({
    required this.label,
    required this.value,
    this.valueColor = WuxiaColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 共用组件
// ─────────────────────────────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

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

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SlotShell extends StatelessWidget {
  const _SlotShell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class _TechniqueShell extends StatelessWidget {
  const _TechniqueShell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
