import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/lore_loader.dart';
import '../../../data/numbers_config.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../core/domain/lore.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../equipment/application/equipment_source_lookup.dart';
import '../../equipment/application/equipment_disposal_service.dart';
import '../../equipment/application/equipment_service.dart';
import '../../equipment/domain/equipment_disposal.dart';
import '../../equipment/domain/equipment_slot_occupancy.dart';
import '../../equipment/domain/equipment_source.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../../shop/application/shop_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/equipment_art_image.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 装备详情屏(Phase 4 W15 LoreLoader 接入下一步)。
///
/// 展示装备基础信息(数值/共鸣度阶段/战斗次数)+ default_lore 段(W15 #35
/// DeepSeek 交付 75 段,按 tier 差异化:寻常货 1 段 / 像样货~利器 2 段 /
/// 重器~神物 3 段)+ 图片右侧信息卡操作分流 [EnhanceDialog] 强化 / 开锋 Tab。
///
/// **lore 消费路径**:UI 层 `Equipment.defId → EquipmentDef.presetLoreIds.first
/// → LoreLoader.load`,**不写 Equipment.lores Isar 字段**(W15 LoreLoader 接入
/// 纪律:preset 按需读 yaml,Isar 留给"延续典故"动态追加)。
///
/// **测试注入**:[loreLoader] 可选参数允许 widget test 注入 fake loader
/// 旁路 rootBundle。生产路径默认走 [LoreLoader.load]。
class EquipmentDetailScreen extends ConsumerStatefulWidget {
  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
    required this.def,
    this.loreLoader,
  });

  final Equipment equipment;
  final EquipmentDef def;

  /// 测试旁路:widget test 传 fake loader 不接 rootBundle。
  /// 生产 null → 默认 [LoreLoader.load]。
  final Future<LoreContent> Function(String loreId)? loreLoader;

  @override
  ConsumerState<EquipmentDetailScreen> createState() =>
      _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends ConsumerState<EquipmentDetailScreen> {
  late final Future<LoreContent?> _loreFuture;

  @override
  void initState() {
    super.initState();
    _loreFuture = _loadLore();
  }

  Future<LoreContent?> _loadLore() async {
    final ids = widget.def.presetLoreIds;
    if (ids.isEmpty) return null;
    final loader = widget.loreLoader ?? LoreLoader.load;
    return loader(ids.first);
  }

  Future<void> _openEnhance(int initialTab) async {
    await showDialog<void>(
      context: context,
      builder: (_) => EnhanceDialog(
        equipment: widget.equipment,
        def: widget.def,
        initialTab: initialTab,
      ),
    );
    if (!mounted) return;
    ref.invalidate(allEquipmentsProvider);
  }

  /// 出售单件（背包态才可触发，已由调用处守卫确保）。
  Future<void> _onSell() async {
    final eq = widget.equipment;
    final cfg = GameRepository.instance.numbers.disposal;
    final price = equipmentSellPrice(eq.tier, eq.enhanceLevel, cfg);
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.equipmentSell,
      body: Text(
        UiStrings.sellSingleConfirmBody(widget.def.name, price),
        style: const TextStyle(
          color: WuxiaUi.ink,
          fontSize: 14,
          height: 1.8,
          letterSpacing: 1,
        ),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.equipmentSell,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final outcome = await EquipmentDisposalService(
      isar: IsarSetup.instance,
      config: cfg,
    ).sell(eq.id);

    if (!mounted) return;
    if (outcome == DisposalOutcome.sold) {
      ref.invalidate(allEquipmentsProvider);
      ref.invalidate(allInventoryItemsProvider);
      ref.invalidate(silverBalanceProvider);
      Navigator.of(context).pop();
    }
  }

  /// 分解单件（背包态才可触发，已由调用处守卫确保）。
  Future<void> _onDisassemble() async {
    final eq = widget.equipment;
    final cfg = GameRepository.instance.numbers.disposal;
    final rewards = equipmentDisassembleRewards(eq.tier, eq.enhanceLevel, cfg);
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.equipmentDisassemble,
      body: Text(
        UiStrings.disassembleSingleConfirmBody(
          widget.def.name,
          rewards.mojianshi,
          rewards.xinxuejiejing,
        ),
        style: const TextStyle(
          color: WuxiaUi.ink,
          fontSize: 14,
          height: 1.8,
          letterSpacing: 1,
        ),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.equipmentDisassemble,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final outcome = await EquipmentDisposalService(
      isar: IsarSetup.instance,
      config: cfg,
    ).disassemble(eq.id);

    if (!mounted) return;
    if (outcome == DisposalOutcome.disassembled) {
      ref.invalidate(allEquipmentsProvider);
      ref.invalidate(allInventoryItemsProvider);
      ref.invalidate(silverBalanceProvider);
      Navigator.of(context).pop();
    }
  }

  Future<void> _setLocked(bool locked) async {
    final outcome = await EquipmentService(
      isar: IsarSetup.instance,
    ).setLocked(equipmentId: widget.equipment.id, locked: locked);
    if (!mounted || outcome != EquipOutcome.success) return;
    setState(() {
      widget.equipment.isLocked = locked;
    });
    ref.invalidate(allEquipmentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final color = tierColorForEquipment(widget.def.tier);
    final highTreasure = isHighTreasureTier(widget.def.tier);
    final equippedIds = _watchActiveEquippedIds(ref);
    final canDispose = !isEquipmentProtected(
      widget.equipment,
      equippedEquipmentIds: equippedIds,
      activeFormationEquipmentIds: equippedIds,
      policy: defaultEquipmentProtectionPolicy(),
    );
    final repo = GameRepository.instanceOrNull;
    final sources =
        repo == null || !repo.equipmentDefs.containsKey(widget.def.id)
        ? const <EquipmentSource>[]
        : EquipmentSourceLookup(repo).sourcesFor(widget.def.id);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: widget.def.name,
        onBack: () => Navigator.of(context).maybePop(),
        titleStyle: TextStyle(
          color: highTreasure ? color : WuxiaUi.ink,
          fontSize: highTreasure ? 22 : null,
          letterSpacing: highTreasure ? 2 : null,
        ),
        trailing: const ContextHelpButton(topic: HelpTopic.equipmentTier),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: WuxiaImage(
                'assets/ui/paper_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final hero = _DetailHero(
                  def: widget.def,
                  // 窄屏(<900)矮窗下大图压缩高度,给信息卡养成入口留首屏空间(T8)。
                  height: wide ? 520 : 300,
                );
                final info = _InfoCard(
                  equipment: widget.equipment,
                  def: widget.def,
                  onEnhance: () => _openEnhance(0),
                  onForge: () => _openEnhance(1),
                  onLockToggle: () => _setLocked(!widget.equipment.isLocked),
                  onSell: canDispose ? _onSell : null,
                  onDisassemble: canDispose ? _onDisassemble : null,
                );
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: hero),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: info),
                        ],
                      )
                    else ...[
                      hero,
                      const SizedBox(height: 14),
                      info,
                    ],
                    const SizedBox(height: 16),
                    _LoreSection(
                      future: _loreFuture,
                      equipment: widget.equipment,
                      sources: sources,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Set<int> _watchActiveEquippedIds(WidgetRef ref) {
  final ids = ref.watch(activeCharacterIdsProvider).value ?? const <int>[];
  final characters = [
    for (final id in ids) ref.watch(characterByIdProvider(id)).value,
  ].nonNulls;
  return equippedEquipmentIdsForCharacters(characters);
}

String _sourceLabel(EquipmentSource source) {
  return switch (source.kind) {
    EquipmentSourceKind.mainline => UiStrings.equipmentSourceMainline(
      source.chapterIndex ?? 0,
      source.name ?? UiStrings.equipmentSourceUnknown,
      source.isBoss,
    ),
    EquipmentSourceKind.stage => UiStrings.equipmentSourceStage(
      source.name ?? UiStrings.equipmentSourceUnknown,
      source.isBoss,
    ),
    EquipmentSourceKind.tower => UiStrings.equipmentSourceTower(
      source.floorIndex ?? 0,
      source.isBoss,
    ),
    EquipmentSourceKind.seclusion => UiStrings.equipmentSourceSeclusion(
      source.name ?? UiStrings.equipmentSourceUnknown,
    ),
    EquipmentSourceKind.shop => UiStrings.equipmentSourceShop,
    EquipmentSourceKind.tag => UiStrings.equipmentSourceTag(source.tag ?? ''),
  };
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.def, required this.height});

  final EquipmentDef def;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = tierColorForEquipment(def.tier);
    final highTreasure = isHighTreasureTier(def.tier);
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WuxiaUi.panelFill,
          borderRadius: BorderRadius.circular(WuxiaUi.radius),
          border: highTreasure
              ? Border.all(color: color, width: 3)
              : Border(bottom: BorderSide(color: color, width: 2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WuxiaUi.radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.18,
                child: WuxiaImage(
                  WuxiaUi.paperBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              if (def.detailPath != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: EquipmentArtImage(
                    imagePath: def.detailPath!,
                    fallback: const DecoratedBox(
                      decoration: BoxDecoration(color: WuxiaUi.panelFill),
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: WuxiaUi.muted,
                    size: 40,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard({
    required this.equipment,
    required this.def,
    required this.onEnhance,
    required this.onForge,
    required this.onLockToggle,
    this.onSell,
    this.onDisassemble,
  });

  final Equipment equipment;
  final EquipmentDef def;

  /// T8:信息卡首屏强化/开锋入口(复用 detail 屏 _openEnhance(0/1))。
  final VoidCallback onEnhance;
  final VoidCallback onForge;
  final VoidCallback onLockToggle;

  /// null = 不显示出售按钮（已装备、师承遗物或锁定）。
  final VoidCallback? onSell;

  /// null = 不显示分解按钮（已装备、师承遗物或锁定）。
  final VoidCallback? onDisassemble;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(numbersConfigProvider);
    final color = tierColorForEquipment(def.tier);
    final resonance = equipment.resonanceStage(n);
    // M1:境界不足时显「需X境界」锁提示(§5.3 三系锁死)。
    final activeIds =
        ref.watch(activeCharacterIdsProvider).value ?? const <int>[];
    final activeCharacters = [
      for (final id in activeIds) ref.watch(characterByIdProvider(id)).value,
    ].nonNulls.toList();
    final playerRealm = activeCharacters.isEmpty
        ? null
        : activeCharacters.first.realmTier;
    final realmLocked =
        playerRealm != null && !equipment.isEquippableAtRealm(playerRealm);
    return SizedBox(
      width: double.infinity,
      child: PaperPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(text: EnumL10n.equipmentTier(def.tier), color: color),
                _Chip(
                  text: EnumL10n.equipmentSlot(def.slot),
                  color: WuxiaColors.textSecondary,
                ),
                if (def.schoolBias != null)
                  _Chip(
                    text: EnumL10n.school(def.schoolBias!),
                    color: WuxiaColors.textSecondary,
                  ),
                // W15 后波 fix:读 equipment 实例字段而非 def 字段(覆盖 def 自带 /
                // 奇遇临时遗物 override / 师承 inheritFrom 三路,读 def 漏后两路)。
                if (equipment.isLineageHeritage)
                  const _Chip(
                    text: UiStrings.lineageHeritageLabel,
                    color: WuxiaColors.hpLow,
                  ),
                if (equipment.isLocked)
                  const _Chip(
                    text: UiStrings.equipmentLockedLabel,
                    color: WuxiaColors.bossFrame,
                  ),
                // M1:境界不足显「需X境界」(§5.3 装备 tier ↔ 同序境界锁死)。
                if (realmLocked)
                  _Chip(
                    text: UiStrings.inventoryRealmLockBanner(
                      EnumL10n.realmTier(RealmTier.values[def.tier.index]),
                    ),
                    color: WuxiaColors.hpLow,
                  ),
              ],
            ),
            // T8:养成入口前移到信息卡首屏顶部(紧贴品阶行),保证窄屏/矮窗首屏即见。
            // 2026-06-27:锁定/整理动作也收进信息卡,避免底部重复按钮。
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlaqueButton(
                    label: '${UiStrings.tabEnhance} +${equipment.enhanceLevel}',
                    primary: true,
                    onTap: onEnhance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlaqueButton(
                    label: UiStrings.tabForging,
                    onTap: onForge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlaqueButton(
                    label: equipment.isLocked
                        ? UiStrings.equipmentUnlock
                        : UiStrings.equipmentLock,
                    onTap: onLockToggle,
                  ),
                ),
              ],
            ),
            if (onSell != null && onDisassemble != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PlaqueButton(
                      label: UiStrings.equipmentSell,
                      onTap: onSell,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PlaqueButton(
                      label: UiStrings.equipmentDisassemble,
                      onTap: onDisassemble,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _StatRow(
              attack: equipment.baseAttack,
              health: equipment.baseHealth,
              speed: equipment.baseSpeed,
              // H2 E2:实战值 = base × 强化 × 共鸣 × 开锋(derived_stats 乘法链)。
              // 此前 UI 只显裸 base,玩家无从知真实战力 / 无法判优同阶掉落。
              effectiveAttack: CharacterDerivedStats.effectiveEquipmentAttack(
                equipment,
                n,
              ),
              effectiveHealth: CharacterDerivedStats.effectiveEquipmentHp(
                equipment,
                n,
              ),
              effectiveSpeed: CharacterDerivedStats.effectiveEquipmentSpeed(
                equipment,
                n,
              ),
              enhanceLevel: equipment.enhanceLevel,
              color: color,
            ),
            const SizedBox(height: 8),
            // D：共鸣度五要素 Row（StageProgressRow：阶段名 + 进度条 +
            // 当前加成 + 下一阶加成 + 战斗进度）+ 解锁招标记行。
            _ResonanceDetailsSection(
              stage: resonance,
              config: _findStageCfg(n.resonanceStages, resonance),
              nextStageCfg: _findNextStageCfg(n.resonanceStages, resonance),
              battleCount: equipment.battleCount,
            ),
            _ForgingSpecialSkillSection(
              equipment: equipment,
              def: def,
              activeCharacters: activeCharacters,
            ),
          ],
        ),
      ),
    );
  }

  static ResonanceStageConfig _findStageCfg(
    List<ResonanceStageConfig> stages,
    ResonanceStage current,
  ) {
    return stages.firstWhere(
      (c) => c.stage == current,
      orElse: () => const ResonanceStageConfig(
        stage: ResonanceStage.shengShu,
        minBattleCount: 0,
        maxBattleCount: 0,
        bonusMultiplier: 1.0,
      ),
    );
  }

  static ResonanceStageConfig? _findNextStageCfg(
    List<ResonanceStageConfig> stages,
    ResonanceStage current,
  ) {
    final orderedStages = ResonanceStage.values;
    final idx = orderedStages.indexOf(current);
    if (idx < 0 || idx >= orderedStages.length - 1) return null;
    final nextStage = orderedStages[idx + 1];
    final match = stages.where((c) => c.stage == nextStage);
    return match.isEmpty ? null : match.first;
  }
}

/// 共鸣度晋升信息透明 section(P1.1 候选 3-d)。
///
/// 体例:在 _InfoCard resonance chip 下方,纯文字 hint(无 VFX 无 icon 装饰)。
/// 与 3-b joint_skill / 3-c sword_song 形成回路:玩家在此 screen 看到武器
/// 能不能 trigger 这两类解锁招式 + 还差多少战晋阶。
class _ResonanceDetailsSection extends StatelessWidget {
  const _ResonanceDetailsSection({
    required this.stage,
    required this.config,
    required this.nextStageCfg,
    required this.battleCount,
  });

  final ResonanceStage stage;
  final ResonanceStageConfig config;
  final ResonanceStageConfig? nextStageCfg;
  final int battleCount;

  @override
  Widget build(BuildContext context) {
    final bonusPct = ((config.bonusMultiplier - 1.0) * 100).round();
    final next = nextStageCfg;

    // 五要素：阶内战斗进度比值 + 下一阶加成 + 战斗进度文案（最高阶退化）。
    final double ratio;
    final String? nextEffect;
    final String progressText;
    if (next != null) {
      final span = next.minBattleCount - config.minBattleCount;
      ratio = span <= 0
          ? 1.0
          : ((battleCount - config.minBattleCount) / span).clamp(0.0, 1.0);
      final nextPct = ((next.bonusMultiplier - 1.0) * 100).round();
      nextEffect = UiStrings.equipmentResonanceNextBonus(nextPct);
      progressText = UiStrings.equipmentResonanceBattleProgress(
        battleCount,
        next.minBattleCount,
      );
    } else {
      ratio = 1.0;
      nextEffect = null;
      progressText = UiStrings.equipmentBattleCount(battleCount);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡内子段：title 省略不重复装备名，阶段名领头。
          StageProgressRow(
            stageName: EnumL10n.resonanceStage(stage),
            glossaryDefinition: UiStrings.glossaryResonance,
            ratio: ratio,
            currentEffect: UiStrings.equipmentDetailResonanceBonus(bonusPct),
            nextEffect: nextEffect,
            progressText: progressText,
          ),
          // 解锁招标记（人剑合一 / 剑鸣），保留信息性 callout。
          if (config.unlocksJointSkill)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                UiStrings.equipmentDetailResonanceJointSkill,
                style: TextStyle(color: WuxiaUi.ink2, fontSize: 12),
              ),
            ),
          if (config.hasSwordSongEffect)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                UiStrings.equipmentDetailResonanceSwordSong,
                style: TextStyle(color: WuxiaUi.ink2, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ForgingSpecialSkillSection extends StatelessWidget {
  const _ForgingSpecialSkillSection({
    required this.equipment,
    required this.def,
    required this.activeCharacters,
  });

  final Equipment equipment;
  final EquipmentDef def;
  final List<Character> activeCharacters;

  @override
  Widget build(BuildContext context) {
    final slot = _specialSkillSlot(equipment);
    final skillId = slot?.specialSkillId;
    if (skillId == null || skillId.isEmpty) return const SizedBox.shrink();

    final skill = GameRepository.instanceOrNull?.skillDefs[skillId];
    final title = skill?.name ?? skillId;
    final chips = skill == null
        ? [UiStrings.forgingSpecialSkillUnknown]
        : [
            _triggerLabel(skill),
            UiStrings.forgingSpecialSkillSchool(
              skill.style == null
                  ? UiStrings.dashPlaceholder
                  : EnumL10n.school(skill.style!),
            ),
            UiStrings.forgingSpecialSkillTarget(
              EnumL10n.targetType(skill.targetType),
            ),
            UiStrings.forgingSpecialSkillCostCooldown(
              skill.internalForceCost,
              skill.cooldownTurns,
            ),
            _fitLabel(skill, def, activeCharacters),
          ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: 0.26),
          border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      UiStrings.forgingSpecialSkillDetailTitle,
                      style: TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _Chip(
                    text: UiStrings.forgingSlotTitle(3),
                    color: WuxiaColors.internalForce,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                UiStrings.forgingSpecialSkillLabel(title),
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                UiStrings.forgingSpecialSkillDetailSubtitle,
                style: TextStyle(color: WuxiaUi.muted, fontSize: 12),
              ),
              if (skill != null && skill.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  skill.description.trim(),
                  style: const TextStyle(
                    color: WuxiaUi.ink2,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in chips)
                    _Chip(text: chip, color: WuxiaColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ForgingSlot? _specialSkillSlot(Equipment equipment) {
    for (final slot in equipment.forgingSlots) {
      if (slot.slotIndex == 3 &&
          slot.unlocked &&
          slot.type == ForgingSlotType.specialSkill) {
        return slot;
      }
    }
    return null;
  }

  static String _triggerLabel(SkillDef skill) {
    if (skill.requiresManualTrigger) {
      return UiStrings.forgingSpecialSkillTriggerManual;
    }
    if (skill.aiUsePolicy == AiUsePolicy.saveForInterrupt) {
      return UiStrings.forgingSpecialSkillTriggerInterrupt;
    }
    if (skill.internalForceCost > 0 || skill.cooldownTurns > 0) {
      return UiStrings.forgingSpecialSkillTriggerAuto;
    }
    return UiStrings.forgingSpecialSkillTriggerReady;
  }

  static String _fitLabel(
    SkillDef skill,
    EquipmentDef def,
    List<Character> activeCharacters,
  ) {
    final school = skill.style ?? def.schoolBias;
    if (school == null) return UiStrings.forgingSpecialSkillFitFlexible;
    final schoolLabel = EnumL10n.school(school);
    final names = activeCharacters
        .where((character) => character.school == school)
        .map((character) => character.name)
        .take(3)
        .join(' / ');
    if (names.isEmpty) {
      return UiStrings.forgingSpecialSkillFitSchool(schoolLabel);
    }
    return UiStrings.forgingSpecialSkillFitCharacters(schoolLabel, names);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.attack,
    required this.health,
    required this.speed,
    required this.effectiveAttack,
    required this.effectiveHealth,
    required this.effectiveSpeed,
    required this.enhanceLevel,
    required this.color,
  });

  final int attack;
  final int health;
  final int speed;

  /// H2 E2:强化/共鸣/开锋乘法后的实战值。与 base 相等时不显「基 N」副标。
  final int effectiveAttack;
  final int effectiveHealth;
  final int effectiveSpeed;

  final int enhanceLevel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _stat(UiStrings.equipStatAttack, attack, effectiveAttack),
        _stat(UiStrings.equipStatHealth, health, effectiveHealth),
        _stat(UiStrings.equipStatSpeed, speed, effectiveSpeed),
        Text(
          UiStrings.enhanceLevel(enhanceLevel),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, int base, int effective) {
    final boosted = effective != base;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: WuxiaUi.muted, fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$effective',
          style: TextStyle(
            // 实战值高于 base 时高亮,直观传达"已被强化/共鸣加成"。
            color: boosted ? color : WuxiaUi.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (boosted) ...[
          const SizedBox(width: 3),
          Text(
            UiStrings.equipmentStatBaseValue(base),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _LoreSection extends StatefulWidget {
  const _LoreSection({
    required this.future,
    required this.equipment,
    required this.sources,
  });

  final Future<LoreContent?> future;
  final Equipment equipment;
  final List<EquipmentSource> sources;

  @override
  State<_LoreSection> createState() => _LoreSectionState();
}

class _LoreSectionState extends State<_LoreSection> {
  @override
  Widget build(BuildContext context) {
    final continued = widget.equipment.lores.where((l) => !l.isPreset).toList()
      ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    final sourceLabels = widget.sources.map(_sourceLabel).toList();
    return FutureBuilder<LoreContent?>(
      future: widget.future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: InkLoadingIndicator());
        }
        final content = snap.data;
        final hasPreset =
            content != null &&
            !content.isPlaceholder &&
            content.defaultLore.isNotEmpty;
        if (!hasPreset && continued.isEmpty && sourceLabels.isEmpty) {
          return const PaperPanel(
            child: Center(
              child: Text(
                UiStrings.loreEmptyPlaceholder,
                style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
              ),
            ),
          );
        }
        return PaperPanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(UiStrings.loreSectionDivider),
              if (sourceLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  UiStrings.equipmentSourceSectionDivider,
                  style: TextStyle(
                    color: WuxiaUi.ink2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final source in sourceLabels)
                      _Chip(text: source, color: WuxiaUi.ink2),
                  ],
                ),
              ],
              if (hasPreset) ...[
                const SizedBox(height: 14),
                for (int i = 0; i < content.defaultLore.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _LorePresetCard(
                    index: i,
                    text: content.defaultLore[i].text,
                    initiallyExpanded: i == 0,
                  ),
                ],
              ],
              if (continued.isNotEmpty) ...[
                const _SegmentDivider(),
                const Text(
                  UiStrings.loreHolderMemoryTitle,
                  style: TextStyle(
                    color: WuxiaColors.internalForce,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                for (final lore in continued) ...[
                  _LoreMemoryCard(lore: lore),
                  const SizedBox(height: 8),
                ],
              ],
              if (!hasPreset && continued.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  UiStrings.loreEmptyPlaceholder,
                  style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LorePresetCard extends StatelessWidget {
  const _LorePresetCard({
    required this.index,
    required this.text,
    required this.initiallyExpanded,
  });

  final int index;
  final String text;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.24),
        border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: initiallyExpanded,
          iconColor: WuxiaUi.ink2,
          collapsedIconColor: WuxiaUi.muted,
          title: Text(
            UiStrings.lorePresetTitle(index + 1),
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoreMemoryCard extends StatelessWidget {
  const _LoreMemoryCard({required this.lore});

  final Lore lore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.internalForce.withValues(alpha: 0.08),
        border: Border.all(
          color: WuxiaColors.internalForce.withValues(alpha: 0.35),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ContinuedLoreChip(),
            const SizedBox(height: 8),
            Text(
              lore.text,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 14,
                height: 1.8,
              ),
            ),
            if (lore.triggerEventDesc != null &&
                lore.triggerEventDesc!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                lore.triggerEventDesc!.trim(),
                style: const TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 延续典故段落标志 chip(P1 #42 Phase 5)。
class _ContinuedLoreChip extends StatelessWidget {
  const _ContinuedLoreChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: WuxiaColors.internalForce.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: WuxiaColors.internalForce, width: 0.5),
        ),
        child: const Text(
          UiStrings.continuedLoreChipLabel,
          style: TextStyle(
            color: WuxiaColors.internalForce,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _SegmentDivider extends StatelessWidget {
  const _SegmentDivider();

  @override
  Widget build(BuildContext context) {
    // T9:纯 Flutter 绘制(细线 + 中央点线),去 ink_divider.png 依赖
    // (330K 图缩到 height:8 渲染不确定;纯绘制稳定无破图风险)。
    final lineColor = WuxiaColors.border.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '· · ·',
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 14,
                letterSpacing: 6,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
