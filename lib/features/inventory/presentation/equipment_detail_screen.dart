import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/lore_loader.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../ui/enhancement/enhance_dialog.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';
import '../../../ui/theme/tier_colors.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            _InfoCard(equipment: widget.equipment, def: widget.def),
            const SizedBox(width: double.infinity, child: Divider(
              color: WuxiaColors.border,
              height: 1,
            )),
            Expanded(child: _LoreSection(future: _loreFuture)),
            _ActionBar(
              tierColor: color,
              onEnhance: () => _openEnhance(0),
              onForge: () => _openEnhance(1),
            ),
          ],
        ),
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
        ],
      ),
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
    required this.enhanceLevel,
    required this.color,
  });

  final int attack;
  final int health;
  final int speed;
  final int enhanceLevel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _stat('攻击', attack),
        _stat('血量', health),
        _stat('速度', speed),
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

  Widget _stat(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoreSection extends StatelessWidget {
  const _LoreSection({required this.future});

  final Future<LoreContent?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoreContent?>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final content = snap.data;
        if (content == null || content.isPlaceholder) {
          return const Center(
            child: Text(
              '典故待补',
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Center(
              child: Text(
                '◇ 典故 ◇',
                style: TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        );
      },
    );
  }
}

class _SegmentDivider extends StatelessWidget {
  const _SegmentDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '· · ·',
          style: TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 14,
            letterSpacing: 6,
          ),
        ),
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
