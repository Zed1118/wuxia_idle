import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../domain/seclusion_map_def.dart';

class SeclusionMapTrait {
  const SeclusionMapTrait({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class SeclusionMapOutputVisual {
  const SeclusionMapOutputVisual({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class SeclusionMapVisuals {
  const SeclusionMapVisuals._();

  static List<SeclusionMapOutputVisual> outputs(SeclusionMapDef def) {
    return [
      const SeclusionMapOutputVisual(
        icon: Icons.construction,
        label: UiStrings.seclusionOutputMojianshi,
        color: WuxiaUi.woodLight,
      ),
      const SeclusionMapOutputVisual(
        icon: Icons.trending_up,
        label: UiStrings.seclusionOutputExperience,
        color: WuxiaUi.qing,
      ),
      const SeclusionMapOutputVisual(
        icon: Icons.payments,
        label: UiStrings.activeRetreatRewardSilver,
        color: WuxiaUi.gold,
      ),
      if (def.equipmentDropRate > 1.0)
        const SeclusionMapOutputVisual(
          icon: Icons.sports_martial_arts,
          label: UiStrings.seclusionOutputEquipDrop,
          color: WuxiaUi.woodLight,
        ),
      if (def.techniqueLearnRate > 1.0)
        const SeclusionMapOutputVisual(
          icon: Icons.auto_stories,
          label: UiStrings.seclusionOutputTechniqueLearn,
          color: WuxiaUi.qing,
        ),
      if (def.internalForceGrowth > 1.0)
        const SeclusionMapOutputVisual(
          icon: Icons.bolt,
          label: UiStrings.seclusionOutputInternalForce,
          color: WuxiaColors.internalForce,
        ),
    ];
  }

  static List<SeclusionMapTrait> traits(SeclusionMapDef def) {
    final traits = <SeclusionMapTrait>[];
    if (def.equipmentDropRate > 1.0) {
      traits.add(
        const SeclusionMapTrait(
          icon: Icons.sports_martial_arts,
          label: UiStrings.seclusionBonusEquipDrop,
          color: WuxiaUi.woodLight,
        ),
      );
    }
    if (def.techniqueLearnRate > 1.0) {
      traits.add(
        const SeclusionMapTrait(
          icon: Icons.auto_stories,
          label: UiStrings.seclusionBonusTechniqueLearn,
          color: WuxiaUi.qing,
        ),
      );
    }
    if (def.internalForceGrowth > 1.0) {
      traits.add(
        const SeclusionMapTrait(
          icon: Icons.bolt,
          label: UiStrings.seclusionBonusInternalForce,
          color: WuxiaColors.internalForce,
        ),
      );
    }
    if (traits.isEmpty) {
      traits.add(
        const SeclusionMapTrait(
          icon: Icons.terrain,
          label: UiStrings.seclusionBonusBalanced,
          color: WuxiaUi.muted,
        ),
      );
    }
    return traits;
  }

  static Color primaryColor(SeclusionMapDef def) {
    final mapTraits = traits(def);
    return mapTraits.length > 1 ? WuxiaUi.gold : mapTraits.first.color;
  }

  static IconData primaryIcon(SeclusionMapDef def) {
    final mapTraits = traits(def);
    return mapTraits.length > 1 ? Icons.all_inclusive : mapTraits.first.icon;
  }
}

class SeclusionMapOutputStrip extends StatelessWidget {
  const SeclusionMapOutputStrip({
    super.key,
    required this.def,
    this.locked = false,
  });

  final SeclusionMapDef def;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final outputs = SeclusionMapVisuals.outputs(def);
    return Opacity(
      opacity: locked ? 0.56 : 1,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final output in outputs)
            _OutputChip(output: output, locked: locked),
        ],
      ),
    );
  }
}

class SeclusionMapTraitStrip extends StatelessWidget {
  const SeclusionMapTraitStrip({
    super.key,
    required this.def,
    this.locked = false,
    this.compact = false,
    this.maxLines = 1,
  });

  final SeclusionMapDef def;
  final bool locked;
  final bool compact;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final traits = SeclusionMapVisuals.traits(def);
    final opacity = locked ? 0.48 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Wrap(
        spacing: compact ? 6 : 8,
        runSpacing: 6,
        children: [
          for (final trait in traits.take(maxLines == 1 ? traits.length : 6))
            _TraitChip(trait: trait, compact: compact),
        ],
      ),
    );
  }
}

class SeclusionMapTraitIcon extends StatelessWidget {
  const SeclusionMapTraitIcon({
    super.key,
    required this.def,
    this.locked = false,
    this.size = 42,
  });

  final SeclusionMapDef def;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? WuxiaUi.muted
        : SeclusionMapVisuals.primaryColor(def);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: locked ? 0.46 : 0.62),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        SeclusionMapVisuals.primaryIcon(def),
        color: color,
        size: size * 0.52,
      ),
    );
  }
}

class _OutputChip extends StatelessWidget {
  const _OutputChip({required this.output, required this.locked});

  final SeclusionMapOutputVisual output;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? WuxiaUi.muted : output.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: locked ? 0.22 : 0.32),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(output.icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            output.label,
            style: TextStyle(
              color: locked ? WuxiaColors.textMuted : WuxiaUi.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.trait, required this.compact});

  final SeclusionMapTrait trait;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: compact ? 0.22 : 0.34),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: trait.color.withValues(alpha: 0.54)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trait.icon, size: compact ? 13 : 15, color: trait.color),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              trait.label,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
