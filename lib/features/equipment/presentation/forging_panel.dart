import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../application/forging_service.dart';
import '../application/equipment_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 开锋面板（phase2_tasks T30 §449-456）。
///
/// 3 个槽位卡片：
/// - 未解锁：灰色 + `强化到 +N 解锁`
/// - 已解锁未开锋：词条选项 list（attack/speed/lifesteal/pierce[/specialSkill]）
///   点击词条 → AlertDialog 二次确认 → `ForgingService.forge` in-place 改
/// - 已开锋：显示 `<type 中文> +X%` + 灰色不可改
///
/// 槽 2 互斥过滤、specialSkill 候选空兜底全部由 [ForgingService] 处理，
/// 本组件仅渲染 + 触发服务调用 + setState 反馈。
///
/// **specialSkill 二次确认 dialog 仅出现一次**：Phase 2 默认
/// `EquipmentDef.specialSkillCandidates` 为空，UI 显示「该装备无专属技能」
/// 后不会弹二次确认；非空时（未来 yaml 补全）按词条点击路径走二确。
class ForgingPanel extends ConsumerStatefulWidget {
  const ForgingPanel({
    super.key,
    required this.equipment,
    required this.def,
  });

  final Equipment equipment;
  final EquipmentDef def;

  @override
  ConsumerState<ForgingPanel> createState() => _ForgingPanelState();
}

class _ForgingPanelState extends ConsumerState<ForgingPanel> {
  Future<void> _onForgeTap({
    required int slotIndex,
    required ForgingSlotType type,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WuxiaColors.panel,
        title: const Text(
          UiStrings.forgingConfirmTitle,
          style: TextStyle(color: WuxiaColors.textPrimary),
        ),
        content: const Text(
          UiStrings.forgingConfirmBody,
          style: TextStyle(color: WuxiaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(UiStrings.forgingConfirmCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(UiStrings.forgingConfirmOk),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final config = ref.read(numbersConfigProvider).forging;
    final result = ForgingService.forge(
      eq: widget.equipment,
      def: widget.def,
      slotIndex: slotIndex,
      type: type,
      config: config,
    );
    if (result == ForgeResult.success) {
      // T32 #22b（Phase 5 W6-S2 重构）：落地 Isar + invalidate inventory 仓库重读。
      // 测试旁路：未 init Isar 时 service 为 null,短路（替代旧 Isar.getInstance guard）。
      final service = ref.read(forgingServiceProvider);
      if (service != null) {
        await service.persistResult(eq: widget.equipment);
        if (!mounted) return;
        ref.invalidate(allEquipmentsProvider);
      }
      if (!mounted) return;
      setState(() {});
    }
    // 失败分支（slotNotUnlocked/alreadyForged/typeNotAvailable 等）当前
    // UI 已经预先校验拦住，理论上不会到这；保留 service 防御返回。
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(numbersConfigProvider).forging;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 1; i <= 3; i++) ...[
            _SlotCard(
              slotIndex: i,
              equipment: widget.equipment,
              def: widget.def,
              unlockAtEnhanceLevel:
                  config.slotByIndex(i).unlockAtEnhanceLevel,
              availableTypes: ForgingService.availableTypesForSlot(
                eq: widget.equipment,
                slotIndex: i,
                config: config,
              ),
              onForge: (type) => _onForgeTap(slotIndex: i, type: type),
            ),
            if (i < 3) const SizedBox(height: 8),
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
    required this.onForge,
  });

  final int slotIndex;
  final Equipment equipment;
  final EquipmentDef def;
  final int unlockAtEnhanceLevel;
  final List<ForgingSlotType> availableTypes;
  final ValueChanged<ForgingSlotType> onForge;

  @override
  Widget build(BuildContext context) {
    final slot = equipment.forgingSlots[slotIndex - 1];
    final unlocked = equipment.enhanceLevel >= unlockAtEnhanceLevel;
    final forged = slot.unlocked;
    final isSpecialSkillSlot = slotIndex == 3;

    Color borderColor;
    Widget body;
    if (forged) {
      borderColor = WuxiaColors.resultHighlight;
      body = _ForgedBody(slot: slot);
    } else if (!unlocked) {
      borderColor = WuxiaColors.buttonDisabled;
      body = _LockedBody(unlockAtEnhanceLevel: unlockAtEnhanceLevel);
    } else if (isSpecialSkillSlot && def.specialSkillCandidates.isEmpty &&
        availableTypes.length == 1 &&
        availableTypes.first == ForgingSlotType.specialSkill) {
      // 槽 3 仅 specialSkill 可选 + 候选为空 → 空状态
      borderColor = WuxiaColors.buttonDisabled;
      body = const _NoSpecialSkillBody();
    } else {
      borderColor = WuxiaColors.border;
      body = _ChoicesBody(types: availableTypes, onTap: onForge);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                UiStrings.forgingSlotTitle(slotIndex),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                const Text(
                  UiStrings.forgingForged,
                  style: TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
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
    return const Text(
      UiStrings.forgingNoSpecialSkill,
      style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
    );
  }
}

class _ChoicesBody extends StatelessWidget {
  const _ChoicesBody({required this.types, required this.onTap});

  final List<ForgingSlotType> types;
  final ValueChanged<ForgingSlotType> onTap;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const Text(
        UiStrings.forgingNoSpecialSkill,
        style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in types)
          OutlinedButton(
            onPressed: () => onTap(t),
            style: OutlinedButton.styleFrom(
              foregroundColor: WuxiaColors.textPrimary,
              side: const BorderSide(color: WuxiaColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(EnumL10n.forgingSlotType(t)),
          ),
      ],
    );
  }
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
      return Text(
        '${EnumL10n.forgingSlotType(type)}：${slot.specialSkillId ?? UiStrings.dashPlaceholder}',
        style: const TextStyle(color: WuxiaColors.textPrimary, fontSize: 13),
      );
    }
    return Text(
      UiStrings.forgingBonusLabel(
        EnumL10n.forgingSlotType(type),
        slot.bonusValue,
      ),
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
