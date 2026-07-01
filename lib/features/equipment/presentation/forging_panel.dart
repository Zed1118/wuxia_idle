import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../inventory/presentation/material_source_note.dart';
import '../application/forging_service.dart';
import '../application/equipment_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

/// 开锋面板（phase2_tasks T30 §449-456）。
///
/// 3 个槽位卡片：
/// - 未解锁：灰色 + `强化到 +N 解锁`
/// - 已解锁未开锋：词条选项 list（attack/speed/lifesteal/pierce[/specialSkill]）
///   点击词条 → PaperDialog 二次确认 → `ForgingService.forge` in-place 改
/// - 已开锋：显示 `<type 中文> +X%` + 灰色不可改
///
/// 槽 2 互斥过滤、specialSkill 候选空兜底全部由 [ForgingService] 处理，
/// 本组件仅渲染 + 触发服务调用 + setState 反馈。
///
/// **specialSkill 二次确认 dialog 仅出现一次**：Phase 2 默认
/// `EquipmentDef.specialSkillCandidates` 为空，UI 显示「该装备无专属技能」
/// 后不会弹二次确认；非空时（未来 yaml 补全）按词条点击路径走二确。
class ForgingPanel extends ConsumerStatefulWidget {
  const ForgingPanel({super.key, required this.equipment, required this.def});

  final Equipment equipment;
  final EquipmentDef def;

  @override
  ConsumerState<ForgingPanel> createState() => _ForgingPanelState();
}

class _ForgingPanelState extends ConsumerState<ForgingPanel> {
  Future<void> _onForgeTap({
    required int slotIndex,
    required ForgingSlotType type,
    required int fucaiQty,
  }) async {
    String? specialSkillId;
    if (type == ForgingSlotType.specialSkill) {
      specialSkillId = await _pickSpecialSkill();
      if (specialSkillId == null) return;
      if (!mounted) return;
    }

    final config = ref.read(numbersConfigProvider).forging;
    final fucaiCost = config.slotByIndex(slotIndex).fucaiCost;
    if (fucaiQty < fucaiCost) return;

    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.forgingConfirmTitle,
      body: Text(
        UiStrings.forgingConfirmBodyWithCost(fucaiCost),
        style: const TextStyle(color: WuxiaColors.textSecondary, height: 1.5),
      ),
      actions: [
        SizedBox(
          width: 104,
          child: PlaqueButton(
            label: UiStrings.forgingConfirmCancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
        SizedBox(
          width: 104,
          child: PlaqueButton(
            label: UiStrings.forgingConfirmOk,
            destructive: true,
            autofocus: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (confirmed != true) return;

    final result = ForgingService.forge(
      eq: widget.equipment,
      def: widget.def,
      slotIndex: slotIndex,
      type: type,
      specialSkillId: specialSkillId,
      config: config,
    );
    if (result == ForgeResult.success) {
      // T32 #22b（Phase 5 W6-S2 重构）：落地 Isar + invalidate inventory 仓库重读。
      // 测试旁路：未 init Isar 时 service 为 null,短路（替代旧 Isar.getInstance guard）。
      final service = ref.read(forgingServiceProvider);
      if (service != null) {
        await service.persistResult(
          eq: widget.equipment,
          slotIndex: slotIndex,
          config: config,
        );
        if (!mounted) return;
        ref.invalidate(inventoryQuantityByDefIdProvider('item_kaifeng_fucai'));
        ref.invalidate(allEquipmentsProvider);
      }
      if (!mounted) return;
      setState(() {});
    }
    // 失败分支（slotNotUnlocked/alreadyForged/typeNotAvailable 等）当前
    // UI 已经预先校验拦住，理论上不会到这；保留 service 防御返回。
  }

  Future<String?> _pickSpecialSkill() async {
    final candidates = widget.def.specialSkillCandidates;
    if (candidates.isEmpty) return null;
    return PaperDialog.show<String>(
      context,
      title: UiStrings.forgingSpecialSkillPickerTitle,
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _skillName(id),
                  style: const TextStyle(color: WuxiaColors.textPrimary),
                ),
                subtitle: Text(
                  _skillSummary(id),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(id),
              ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: 104,
          child: PlaqueButton(
            label: UiStrings.forgingConfirmCancel,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  static String _skillName(String id) =>
      GameRepository.instanceOrNull?.skillDefs[id]?.name ?? id;

  static String _skillSummary(String id) {
    final skill = GameRepository.instanceOrNull?.skillDefs[id];
    if (skill == null) return id;
    final styleLabel = skill.style == null
        ? UiStrings.dashPlaceholder
        : EnumL10n.school(skill.style!);
    return UiStrings.forgingSpecialSkillSummary(
      styleLabel,
      skill.tier,
      skill.powerMultiplier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(numbersConfigProvider).forging;
    final fucaiAsync = ref.watch(
      inventoryQuantityByDefIdProvider('item_kaifeng_fucai'),
    );
    final fucaiQty = fucaiAsync.value ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MaterialSourceNote(itemIds: ['item_kaifeng_fucai']),
          const SizedBox(height: 12),
          for (int i = 1; i <= 3; i++) ...[
            _SlotCard(
              slotIndex: i,
              equipment: widget.equipment,
              def: widget.def,
              unlockAtEnhanceLevel: config.slotByIndex(i).unlockAtEnhanceLevel,
              availableTypes: ForgingService.availableTypesForSlot(
                eq: widget.equipment,
                slotIndex: i,
                config: config,
              ),
              fucaiQty: fucaiQty,
              fucaiCost: config.slotByIndex(i).fucaiCost,
              onForge: (type) =>
                  _onForgeTap(slotIndex: i, type: type, fucaiQty: fucaiQty),
            ),
            if (i < 3) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slotIndex,
    required this.equipment,
    required this.def,
    required this.unlockAtEnhanceLevel,
    required this.availableTypes,
    required this.fucaiQty,
    required this.fucaiCost,
    required this.onForge,
  });

  final int slotIndex;
  final Equipment equipment;
  final EquipmentDef def;
  final int unlockAtEnhanceLevel;
  final List<ForgingSlotType> availableTypes;
  final int fucaiQty;
  final int fucaiCost;
  final ValueChanged<ForgingSlotType> onForge;

  @override
  Widget build(BuildContext context) {
    final slot = equipment.forgingSlots[slotIndex - 1];
    final unlocked = equipment.enhanceLevel >= unlockAtEnhanceLevel;
    final forged = slot.unlocked;
    final isSpecialSkillSlot = slotIndex == 3;
    final lacksMaterial = unlocked && !forged && fucaiQty < fucaiCost;

    Color borderColor;
    Color accentColor;
    Widget body;
    if (forged) {
      borderColor = WuxiaColors.resultHighlight;
      accentColor = WuxiaColors.resultHighlight;
      body = _ForgedBody(slot: slot);
    } else if (!unlocked) {
      borderColor = WuxiaColors.buttonDisabled;
      accentColor = WuxiaColors.textMuted;
      body = _LockedBody(unlockAtEnhanceLevel: unlockAtEnhanceLevel);
    } else if (isSpecialSkillSlot &&
        def.specialSkillCandidates.isEmpty &&
        availableTypes.length == 1 &&
        availableTypes.first == ForgingSlotType.specialSkill) {
      // 槽 3 仅 specialSkill 可选 + 候选为空 → 空状态
      borderColor = WuxiaColors.buttonDisabled;
      accentColor = WuxiaColors.textMuted;
      body = const _NoSpecialSkillBody();
    } else {
      borderColor = lacksMaterial ? WuxiaColors.hpLow : WuxiaColors.border;
      accentColor = lacksMaterial
          ? WuxiaColors.hpLow
          : WuxiaColors.resultHighlight;
      body = _ChoicesBody(
        types: availableTypes,
        fucaiQty: fucaiQty,
        fucaiCost: fucaiCost,
        onTap: onForge,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WuxiaColors.avatarFill.withValues(alpha: forged ? 0.96 : 0.84),
            WuxiaColors.inkPanelBottom.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: forged
            ? [
                BoxShadow(
                  color: WuxiaColors.resultHighlight.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                UiStrings.forgingSlotTitle(slotIndex),
                style: TextStyle(
                  color: forged
                      ? WuxiaColors.resultHighlight
                      : WuxiaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(+$unlockAtEnhanceLevel)',
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (forged) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: WuxiaColors.resultHighlight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: WuxiaColors.resultHighlight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    UiStrings.forgingForged,
                    style: TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (!forged && unlocked) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (lacksMaterial
                              ? WuxiaColors.hpLow
                              : WuxiaColors.resultHighlight)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        (lacksMaterial
                                ? WuxiaColors.hpLow
                                : WuxiaColors.resultHighlight)
                            .withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  UiStrings.forgingFucaiUsage(fucaiQty, fucaiCost),
                  style: TextStyle(
                    color: lacksMaterial
                        ? WuxiaColors.hpLow
                        : WuxiaColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          body,
        ],
      ),
    );
  }
}

class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.unlockAtEnhanceLevel});

  final int unlockAtEnhanceLevel;

  @override
  Widget build(BuildContext context) {
    return Text(
      UiStrings.forgingUnlockHint(unlockAtEnhanceLevel),
      style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
    );
  }
}

class _NoSpecialSkillBody extends StatelessWidget {
  const _NoSpecialSkillBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UiStrings.forgingNoSpecialSkill,
          style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          UiStrings.forgingNoSpecialSkillHint,
          style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ChoicesBody extends StatelessWidget {
  const _ChoicesBody({
    required this.types,
    required this.fucaiQty,
    required this.fucaiCost,
    required this.onTap,
  });

  final List<ForgingSlotType> types;
  final int fucaiQty;
  final int fucaiCost;
  final ValueChanged<ForgingSlotType> onTap;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const Text(
        UiStrings.forgingNoSpecialSkill,
        style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
      );
    }
    final enabled = fucaiQty >= fucaiCost;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in types)
          OutlinedButton.icon(
            onPressed: enabled ? () => onTap(t) : null,
            icon: Icon(_iconFor(t), size: 15),
            style: OutlinedButton.styleFrom(
              foregroundColor: WuxiaColors.textPrimary,
              disabledForegroundColor: WuxiaColors.textMuted,
              backgroundColor:
                  (enabled
                          ? WuxiaColors.resultHighlight
                          : WuxiaColors.buttonDisabled)
                      .withValues(alpha: 0.08),
              side: BorderSide(
                color:
                    (enabled ? WuxiaColors.resultHighlight : WuxiaColors.border)
                        .withValues(alpha: enabled ? 0.5 : 0.9),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            label: Text(EnumL10n.forgingSlotType(t)),
          ),
      ],
    );
  }

  static IconData _iconFor(ForgingSlotType type) => switch (type) {
    ForgingSlotType.attack => Icons.flash_on_outlined,
    ForgingSlotType.speed => Icons.speed_outlined,
    ForgingSlotType.lifesteal => Icons.bloodtype_outlined,
    ForgingSlotType.pierce => Icons.gps_fixed_outlined,
    ForgingSlotType.specialSkill => Icons.auto_awesome_outlined,
  };
}

class _ForgedBody extends StatelessWidget {
  const _ForgedBody({required this.slot});

  final ForgingSlot slot;

  @override
  Widget build(BuildContext context) {
    final type = slot.type;
    if (type == null) {
      return const Text(
        UiStrings.dashPlaceholder,
        style: TextStyle(color: WuxiaColors.textMuted),
      );
    }
    if (type == ForgingSlotType.specialSkill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: WuxiaColors.resultHighlight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.32),
          ),
        ),
        child: Text(
          UiStrings.forgingSpecialSkillLabel(
            slot.specialSkillId == null
                ? UiStrings.dashPlaceholder
                : _skillName(slot.specialSkillId!),
          ),
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: WuxiaColors.resultHighlight.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        UiStrings.forgingBonusLabel(
          EnumL10n.forgingSlotType(type),
          slot.bonusValue,
        ),
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String _skillName(String id) =>
      GameRepository.instanceOrNull?.skillDefs[id]?.name ?? id;
}
