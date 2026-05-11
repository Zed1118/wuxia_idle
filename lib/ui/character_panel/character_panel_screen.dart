import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/derived_stats.dart';
import '../../combat/enum_localizations.dart';
import '../../data/models/character.dart';
import '../../data/models/enums.dart';
import '../../data/models/equipment.dart';
import '../../data/models/technique.dart';
import '../../providers/battle_providers.dart';
import '../../providers/character_providers.dart';
import '../strings.dart';
import '../theme/colors.dart';

/// 角色面板（phase2_tasks.md T28 §392-414）。
///
/// 单角色版面，按 characterId 取数。布局：
/// - 顶部：姓名 / 境界 / 流派色条
/// - 中部：4 项属性 + 5 项派生数值
/// - 装备区：3 槽（武器 / 护甲 / 饰品），未装备显示灰色占位
/// - 心法区：主修高亮 + 3 辅修槽 + 修炼度进度条
///
/// 不显示装备/心法名字（spec §403/§404 未要求，避免硬编码中文文案风险）。
/// 速度无主修时显示 [UiStrings.dashPlaceholder]；其他派生数值始终可算。
class CharacterPanelScreen extends ConsumerWidget {
  const CharacterPanelScreen({super.key, required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(characterByIdProvider(characterId));
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
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
              equipped: equipped.map((a) => a.value).whereType<Equipment>().toList(),
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
        .map((id) => id == null
            ? const AsyncData<Equipment?>(null)
            : ref.watch(equipmentByIdProvider(id)))
        .toList();
  }

  Widget _renderStats(
    BuildContext context,
    WidgetRef ref, {
    required List<Equipment> equipped,
    required Technique? mainTech,
  }) {
    final n = ref.watch(numbersConfigProvider);
    final hp = CharacterDerivedStats.maxHp(character, equipped, n);
    final ifMax = CharacterDerivedStats.internalForceMaxWithLineage(
      character,
      equipped,
      n,
    );
    final speedText = mainTech == null
        ? UiStrings.dashPlaceholder
        : '${CharacterDerivedStats.speed(character, equipped, mainTech, n)}';
    final critText = UiStrings.percent(
      CharacterDerivedStats.criticalRate(character, n),
    );
    final evadeText = UiStrings.percent(
      CharacterDerivedStats.evasionRate(character, n),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledValue(
                label: UiStrings.statHp,
                value: '$hp',
              ),
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
        final tierColor = _tierColor(eq.tier);
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
              Text(
                EnumL10n.resonanceStage(resonance),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
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
        ],
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
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
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
          style: const TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 11,
          ),
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

/// 装备阶颜色（与战斗 UI 风格延续，从 [WuxiaColors] 派生）。
///
/// Phase 2 简化：寻常/像样/好家伙 → 灰 / 普 / 蓝调；利器以上 → 暖色。
/// 全部色值已存在 [WuxiaColors]；此处仅做映射，不引入新颜色定义。
Color _tierColor(EquipmentTier t) {
  return switch (t) {
    EquipmentTier.xunChang => WuxiaColors.textMuted,
    EquipmentTier.xiangYang => WuxiaColors.textSecondary,
    EquipmentTier.haoJiaHuo => WuxiaColors.internalForce,
    EquipmentTier.liQi => WuxiaColors.lingQiao,
    EquipmentTier.zhongQi => WuxiaColors.gangMeng,
    EquipmentTier.baoWu => WuxiaColors.yinRou,
    EquipmentTier.shenWu => WuxiaColors.resultHighlight,
  };
}
