import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/lore_loader.dart';
import '../../../data/numbers_config.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';

/// 装备详情屏(Phase 4 W15 LoreLoader 接入下一步)。
///
/// 展示装备基础信息(数值/共鸣度阶段/战斗次数)+ default_lore 段(W15 #35
/// DeepSeek 交付 75 段,按 tier 差异化:寻常货 1 段 / 像样货~利器 2 段 /
/// 重器~神物 3 段)+ 底部操作按钮分流 [EnhanceDialog] 强化 / 开锋 Tab。
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

class _EquipmentDetailScreenState
    extends ConsumerState<EquipmentDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    final color = tierColorForEquipment(widget.def.tier);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(
          widget.def.name,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        iconTheme: const IconThemeData(color: WuxiaColors.textPrimary),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/ui/paper_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (widget.def.detailPath != null)
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: WuxiaColors.panel,
                      border: Border(
                        bottom: BorderSide(color: color, width: 2),
                      ),
                    ),
                    child: Image.asset(
                      widget.def.detailPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: WuxiaColors.panel),
                    ),
                  ),
                _InfoCard(equipment: widget.equipment, def: widget.def),
                const SizedBox(width: double.infinity, child: Divider(
                  color: WuxiaColors.border,
                  height: 1,
                )),
                Expanded(
                  child: _LoreSection(
                    future: _loreFuture,
                    equipment: widget.equipment,
                  ),
                ),
                _ActionBar(
                  tierColor: color,
                  onEnhance: () => _openEnhance(0),
                  onForge: () => _openEnhance(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.equipment, required this.def});

  final Equipment equipment;
  final EquipmentDef def;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(numbersConfigProvider);
    final color = tierColorForEquipment(def.tier);
    final resonance = equipment.resonanceStage(n);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(text: EnumL10n.equipmentTier(def.tier), color: color),
              const SizedBox(width: 8),
              _Chip(
                text: EnumL10n.equipmentSlot(def.slot),
                color: WuxiaColors.textSecondary,
              ),
              if (def.schoolBias != null) ...[
                const SizedBox(width: 8),
                _Chip(
                  text: EnumL10n.school(def.schoolBias!),
                  color: WuxiaColors.textSecondary,
                ),
              ],
              // W15 后波 fix:读 equipment 实例字段而非 def 字段。
              // 实例 isLineageHeritage 覆盖 3 条路径:① def 自带(初始化时
              // EquipmentFactory.fromDef 将 def→实例 propagate)② 奇遇赠送
              // 临时遗物 override(EquipmentFactory 参数通道,T55 注释)
              // ③ 师承传承时 inheritFrom() 标记。读 def 漏掉 ②③。
              if (equipment.isLineageHeritage) ...[
                const SizedBox(width: 8),
                const _Chip(
                  text: UiStrings.lineageHeritageLabel,
                  color: WuxiaColors.hpLow,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _StatRow(
            attack: equipment.baseAttack,
            health: equipment.baseHealth,
            speed: equipment.baseSpeed,
            // H2 E2:实战值 = base × 强化 × 共鸣 × 开锋(derived_stats 乘法链)。
            // 此前 UI 只显裸 base,玩家无从知真实战力 / 无法判优同阶掉落。
            effectiveAttack:
                CharacterDerivedStats.effectiveEquipmentAttack(equipment, n),
            effectiveHealth:
                CharacterDerivedStats.effectiveEquipmentHp(equipment, n),
            effectiveSpeed:
                CharacterDerivedStats.effectiveEquipmentSpeed(equipment, n),
            enhanceLevel: equipment.enhanceLevel,
            color: color,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                EnumL10n.resonanceStage(resonance),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '战斗 ${equipment.battleCount} 次',
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // P1.1 候选 3-d:共鸣度晋升信息透明 section。
          // 体例对齐 _Chip 风格,无 VFX,纯文字 hint 显:
          // ① bonus_multiplier 「攻击 +X%」② unlocks_joint_skill → 已解锁人剑合一
          // ③ has_sword_song_effect → 暴击附带剑鸣 ④ 距下一阶 N 战 hint
          _ResonanceDetailsSection(
            stage: resonance,
            config: _findStageCfg(n.resonanceStages, resonance),
            nextStageCfg: _findNextStageCfg(n.resonanceStages, resonance),
            battleCount: equipment.battleCount,
          ),
        ],
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
    final lines = <String>[
      UiStrings.equipmentDetailResonanceBonus(bonusPct),
      if (config.unlocksJointSkill) UiStrings.equipmentDetailResonanceJointSkill,
      if (config.hasSwordSongEffect) UiStrings.equipmentDetailResonanceSwordSong,
    ];
    final nextHint = _nextStageHint();
    if (nextHint != null) lines.add(nextHint);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                line,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _nextStageHint() {
    final next = nextStageCfg;
    if (next == null) return null;
    final remaining = next.minBattleCount - battleCount;
    if (remaining <= 0) return null;
    return UiStrings.equipmentDetailResonanceNextHint(
      remaining,
      EnumL10n.resonanceStage(next.stage),
    );
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
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
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
        Text(
          label,
          style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          '$effective',
          style: TextStyle(
            // 实战值高于 base 时高亮,直观传达"已被强化/共鸣加成"。
            color: boosted ? color : WuxiaColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (boosted) ...[
          const SizedBox(width: 3),
          Text(
            '(基 $base)',
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoreSection extends StatelessWidget {
  const _LoreSection({required this.future, required this.equipment});

  final Future<LoreContent?> future;
  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final continued = equipment.lores.where((l) => !l.isPreset).toList()
      ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    return FutureBuilder<LoreContent?>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final content = snap.data;
        final hasPreset = content != null && !content.isPlaceholder;
        if (!hasPreset && continued.isEmpty) {
          return const Center(
            child: Text(
              UiStrings.loreEmptyPlaceholder,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Center(
              child: Text(
                UiStrings.loreSectionDivider,
                style: TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (hasPreset)
              for (int i = 0; i < content.defaultLore.length; i++) ...[
                if (i > 0) const _SegmentDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    content.defaultLore[i].text,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            for (final lore in continued) ...[
              const _SegmentDivider(),
              const _ContinuedLoreChip(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  lore.text,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ],
        );
      },
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
          border: Border.all(
            color: WuxiaColors.internalForce,
            width: 0.5,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/ui/ink_divider.png',
            height: 8,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 2),
          const Center(
            child: Text(
              '· · ·',
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 14,
                letterSpacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.tierColor,
    required this.onEnhance,
    required this.onForge,
  });

  final Color tierColor;
  final VoidCallback onEnhance;
  final VoidCallback onForge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _Btn(
                label: UiStrings.tabEnhance,
                color: tierColor,
                onTap: onEnhance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Btn(
                label: UiStrings.tabForging,
                color: tierColor,
                onTap: onForge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
