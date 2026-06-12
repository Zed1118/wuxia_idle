import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../ascension/application/ascend_service_providers.dart';
import '../../ascension/presentation/ascension_screen.dart';
import '../application/lineage_info_provider.dart';

/// 师徒名单（W17 候选 E，独立 sub-screen）。
///
/// 主菜单「师徒名单」按钮进入；与 [CharacterPanelScreen] 角色级 Tab 视图
/// 互补，提供「全局关系视图」：祖师 chip / 弟子 chip / 师承遗物列表。
///
/// 预研：`docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md`。
class LineagePanelScreen extends ConsumerWidget {
  const LineagePanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lineageInfoProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.lineagePanelTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (info) => _Body(info: info),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.info});

  final LineageInfo info;

  /// 按 slotIndex 0/1/2 解析 masters[i].portraitPath。
  /// GameRepository 未加载 / 越界 / 缺字段时 null,_CharacterChip 走 4×28 竖条 fallback。
  String? _portraitForSlot(int slotIndex) {
    if (!GameRepository.isLoaded) return null;
    final masters = GameRepository.instance.masters;
    if (slotIndex < 0 || slotIndex >= masters.length) return null;
    return masters[slotIndex].portraitPath;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Image.asset(
              'assets/ui/scroll_vertical.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          _FounderSection(
            founder: info.founder,
            portraitPath: _portraitForSlot(0),
          ),
          const SizedBox(height: 16),
          if (GameRepository.isLoaded &&
              GameRepository.instance.numbers.founderAncestorBuff.isActive)
            _FounderBuffSection(
              buff: GameRepository.instance.numbers.founderAncestorBuff,
            ),
          if (GameRepository.isLoaded &&
              GameRepository.instance.numbers.founderAncestorBuff.isActive)
            const SizedBox(height: 16),
          _DisciplesSection(
            disciples: info.disciples,
            portraitPaths: List.generate(
              info.disciples.length,
              (i) => _portraitForSlot(i + 1),
            ),
          ),
          if (info.inactiveDisciples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InactiveDisciplesSection(disciples: info.inactiveDisciples),
          ],
          const SizedBox(height: 16),
          _HeritageSection(equipments: info.heritageEquipments),
          const SizedBox(height: 16),
          const _AscensionSection(),
        ],
      ),
    );
  }
}

/// 飞升渡劫入口段(P2.3 §7.1 · spec p2_3_ascension_spec_2026-05-24)。
///
/// 5 子条件聚合判定(`ascensionEligibilityProvider`):
///   - 全 true → 「步入飞升」按钮 enable · 点击 push [AscensionScreen]
///   - 任一 false → disable · tooltip 显未达条件清单
class _AscensionSection extends ConsumerWidget {
  const _AscensionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ascensionEligibilityProvider);
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.ascensionPanelSection),
          const SizedBox(height: 4),
          const Text(
            UiStrings.ascensionPanelHint,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow, fontSize: 12),
            ),
            data: (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!e.canAscend && e.missingReasons.isNotEmpty) ...[
                  for (final r in e.missingReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '· $r',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: e.canAscend
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AscensionScreen(),
                            ),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WuxiaColors.resultHighlight,
                      disabledBackgroundColor: WuxiaColors.buttonDisabled,
                    ),
                    child: Text(
                      e.canAscend
                          ? UiStrings.ascensionPanelButton
                          : UiStrings.ascensionPanelLocked,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _FounderSection extends StatelessWidget {
  const _FounderSection({required this.founder, this.portraitPath});

  final Character? founder;
  final String? portraitPath;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(UiStrings.lineageTabLabels[0]),
          const SizedBox(height: 8),
          if (founder == null)
            const _EmptyText(UiStrings.lineagePanelNoFounder)
          else
            _CharacterChip(character: founder!, portraitPath: portraitPath),
        ],
      ),
    );
  }
}

class _DisciplesSection extends StatelessWidget {
  const _DisciplesSection({
    required this.disciples,
    this.portraitPaths = const [],
  });

  final List<Character> disciples;
  final List<String?> portraitPaths;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineagePanelDisciplesSection),
          const SizedBox(height: 8),
          if (disciples.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoDisciples)
          else
            for (var i = 0; i < disciples.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _CharacterChip(
                character: disciples[i],
                portraitPath: i < portraitPaths.length
                    ? portraitPaths[i]
                    : null,
              ),
            ],
        ],
      ),
    );
  }
}

class _FounderBuffSection extends StatelessWidget {
  const _FounderBuffSection({required this.buff});

  final FounderAncestorBuff buff;

  String _pctLabel(double v) {
    if (v == 0) return '—';
    return '+${(v * 100).toStringAsFixed(0)}%';
  }

  String _absLabel(double v) {
    if (v == 0) return '—';
    return '+${(v * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineagePanelFounderBuffSection),
          const SizedBox(height: 8),
          const Text(
            UiStrings.lineagePanelFounderBuffSubtitle,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffInternalForce,
            value: _pctLabel(buff.internalForceMaxPct),
          ),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffMaxHp,
            value: _pctLabel(buff.maxHpPct),
          ),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffCritRate,
            value: _absLabel(buff.critRateBonus),
          ),
          // H2 audit S3:cultivationProgressPct 未接修炼度公式(全 lib/ 0 消费),
          // 移除误导性「+3% 修炼度」行,避免向玩家展示不生效的 buff。
          // Phase 5+ 接公式后恢复(UiString lineagePanelFounderBuffCultivation 保留待用)。
        ],
      ),
    );
  }
}

class _BuffRow extends StatelessWidget {
  const _BuffRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveDisciplesSection extends StatelessWidget {
  const _InactiveDisciplesSection({required this.disciples});

  final List<Character> disciples;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineagePanelInactiveSection),
          const SizedBox(height: 8),
          if (disciples.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoInactive)
          else
            for (var i = 0; i < disciples.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _CharacterChip(character: disciples[i]),
            ],
        ],
      ),
    );
  }
}

class _HeritageSection extends StatelessWidget {
  const _HeritageSection({required this.equipments});

  final List<Equipment> equipments;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(UiStrings.lineagePanelHeritageSection),
              if (equipments.isNotEmpty)
                Text(
                  UiStrings.lineagePanelHeritageCount(equipments.length),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (equipments.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoHeritage)
          else
            for (var i = 0; i < equipments.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _HeritageRow(equipment: equipments[i]),
            ],
        ],
      ),
    );
  }
}

class _CharacterChip extends StatelessWidget {
  const _CharacterChip({required this.character, this.portraitPath});

  final Character character;
  final String? portraitPath;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (portraitPath == null)
            Container(width: 4, height: 28, color: schoolColor)
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: schoolColor, width: 1),
                color: WuxiaColors.avatarFill,
              ),
              child: Image.asset(
                portraitPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: WuxiaColors.avatarFill),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EnumL10n.realm(character.realmTier, character.realmLayer),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
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

class _HeritageRow extends StatelessWidget {
  const _HeritageRow({required this.equipment});

  final Equipment equipment;

  String _resolveName() {
    if (!GameRepository.isLoaded) return equipment.defId;
    final def = GameRepository.instance.equipmentDefs[equipment.defId];
    return def?.name ?? equipment.defId;
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = tierColorForEquipment(equipment.tier);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _resolveName(),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (equipment.enhanceLevel > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+${equipment.enhanceLevel}',
            style: TextStyle(
              color: tierColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        // P5+ 多代传承 chip:prev len > 1 时显「{N} 代传承」(N = prev len + 1)。
        // 沿 character_panel _LineageHeritageRow 同语义 · gen2 起才显。
        if (equipment.previousOwnerCharacterIds.length > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: WuxiaColors.panel,
              border: Border.all(color: WuxiaColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              UiStrings.ascensionMultiGenChip.replaceFirst(
                '{0}',
                '${equipment.previousOwnerCharacterIds.length + 1}',
              ),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

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
        color: WuxiaColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
    );
  }
}
