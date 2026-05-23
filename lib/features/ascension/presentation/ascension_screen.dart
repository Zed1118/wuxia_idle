import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../data/narrative_loader.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../character_panel/application/lineage_info_provider.dart';
import '../../inheritance/application/founder_buff_providers.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../application/ascend_service_providers.dart';

/// P2.3 §7.1 飞升 + 遗物 transfer 屏(spec p2_3_ascension_spec_2026-05-24)。
///
/// 三段式:
///   1. 顶部仪式横幅 + ritual hint
///   2. 中部 founder 装备列表(check box 多选 1-2 件)
///   3. 中部下 disciple 分配(每件选中装备显「分配给:[大弟子▼]」)
///   4. 底部「确认飞升」按钮 disable iff 选择数 ∉ [piecesPerGenerationMin/Max]
///
/// 路径:LineagePanel 飞升按钮 enable 时 push 进入。完成后 pop 回 LineagePanel +
/// snackbar「飞升渡劫已成 · 已传 N 件遗物」。
class AscensionScreen extends ConsumerStatefulWidget {
  const AscensionScreen({super.key});

  @override
  ConsumerState<AscensionScreen> createState() => _AscensionScreenState();
}

class _AscensionScreenState extends ConsumerState<AscensionScreen> {
  /// 玩家勾选的 Equipment.id 集合。order 按勾选顺序追加。
  final List<int> _selectedEquipmentIds = [];

  /// 玩家分配 map(equipmentId → discipleId)。默认每件分给大弟子(disciples[0])。
  final Map<int, int> _assignments = {};

  /// P5+ 真传位 disciple id(spec p5_lineage_full_spec §Q1 player_pick 体例)。
  /// null = 不传位(P2.3 一代飞升兼容路径 · founder 退江湖但门派无人接管)。
  /// 默认值在 build() 内 disciplesAsync 数据到达后设为 disciples.first.id(大弟子)。
  int? _promotedDiscipleId;

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final lineageAsync = ref.watch(lineageInfoProvider);
    final disciplesAsync = ref.watch(ascensionDiscipleTargetsProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.ascensionTitle),
      ),
      body: SafeArea(
        child: lineageAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (info) {
            final founder = info.founder;
            if (founder == null) {
              return const Center(
                child: Text(
                  UiStrings.lineagePanelNoFounder,
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            return disciplesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: SelectableText(
                  'load error: $e',
                  style: const TextStyle(color: WuxiaColors.hpLow),
                ),
              ),
              data: (disciples) {
                if (disciples.isEmpty) {
                  return const Center(
                    child: Text(
                      UiStrings.ascensionNoDisciples,
                      style: TextStyle(color: WuxiaColors.textMuted),
                    ),
                  );
                }
                // P5+ 默认大弟子接任(disciples.first · activeCharacterIds 顺序)
                final promotedId = _promotedDiscipleId ?? disciples.first.id;
                return _Body(
                  founder: founder,
                  disciples: disciples,
                  selectedIds: _selectedEquipmentIds,
                  assignments: _assignments,
                  promotedDiscipleId: promotedId,
                  isSubmitting: _isSubmitting,
                  onToggle: _toggleSelection,
                  onAssign: _setAssignment,
                  onPromote: _setPromotedDisciple,
                  onConfirm: () => _showConfirmDialog(promotedId),
                  defaultDiscipleId: disciples.first.id,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleSelection(int equipmentId, int defaultDiscipleId) {
    setState(() {
      if (_selectedEquipmentIds.contains(equipmentId)) {
        _selectedEquipmentIds.remove(equipmentId);
        _assignments.remove(equipmentId);
      } else {
        _selectedEquipmentIds.add(equipmentId);
        _assignments[equipmentId] = defaultDiscipleId;
      }
    });
  }

  void _setAssignment(int equipmentId, int discipleId) {
    setState(() {
      _assignments[equipmentId] = discipleId;
    });
  }

  void _setPromotedDisciple(int? id) {
    setState(() {
      _promotedDiscipleId = id;
    });
  }

  Future<void> _showConfirmDialog(int promotedDiscipleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WuxiaColors.panel,
        title: const Text(
          UiStrings.ascensionConfirmDialogTitle,
          style: TextStyle(color: WuxiaColors.textPrimary),
        ),
        content: const Text(
          UiStrings.ascensionConfirmDialogBody,
          style: TextStyle(color: WuxiaColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(UiStrings.ascensionConfirmDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(UiStrings.ascensionConfirmDialogOk),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _performAscend(promotedDiscipleId: promotedDiscipleId);
  }

  Future<void> _performAscend({required int promotedDiscipleId}) async {
    setState(() => _isSubmitting = true);
    try {
      final svc = ref.read(ascendServiceProvider);
      final isar = ref.read(isarProvider);
      if (svc == null || isar == null) {
        throw StateError('AscendService 或 Isar 未就绪');
      }
      final result = await isar.writeTxn(
        () => svc.performAscend(
          Map.of(_assignments),
          promotedDiscipleId: promotedDiscipleId,
        ),
      );

      // invalidate 链:eligibility / candidates / disciples / founderBuff /
      // lineageInfo(后者 LineagePanel watch 显新 heritage chip)
      ref.invalidate(ascensionEligibilityProvider);
      ref.invalidate(ascensionDiscipleTargetsProvider);
      ref.invalidate(founderBuffActiveProvider);
      ref.invalidate(lineageInfoProvider);

      if (!mounted) return;
      // 先 push 完成 narrative(ascension_complete · 师父别山 + 化境门开)→
      // 再 snackbar 摘要 → 最后 pop 回 LineagePanel。
      final completeNarrative =
          await NarrativeLoader.load('ascension_complete');
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (innerCtx) => NarrativeReaderScreen(
            content: completeNarrative,
            fallbackTitle: UiStrings.ascensionTitle,
            onFinish: () => Navigator.of(innerCtx).pop(),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UiStrings.ascensionCompleteSnackbar.replaceFirst(
              '{0}',
              '${result.transferredCount}',
            ),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('飞升失败:$e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.founder,
    required this.disciples,
    required this.selectedIds,
    required this.assignments,
    required this.promotedDiscipleId,
    required this.isSubmitting,
    required this.onToggle,
    required this.onAssign,
    required this.onPromote,
    required this.onConfirm,
    required this.defaultDiscipleId,
  });

  final Character founder;
  final List<Character> disciples;
  final List<int> selectedIds;
  final Map<int, int> assignments;
  final int promotedDiscipleId;
  final bool isSubmitting;
  final void Function(int equipmentId, int defaultDiscipleId) onToggle;
  final void Function(int equipmentId, int discipleId) onAssign;
  final void Function(int? id) onPromote;
  final VoidCallback onConfirm;
  final int defaultDiscipleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync =
        ref.watch(heritageCandidatesProvider(founder.id));
    final n = GameRepository.isLoaded
        ? GameRepository.instance.numbers.heritageItems
        : null;
    final pickMin = n?.piecesPerGenerationMin ?? 1;
    final pickMax = n?.piecesPerGenerationMax ?? 2;
    final selectedCount = selectedIds.length;
    final canConfirm = !isSubmitting &&
        selectedCount >= pickMin &&
        selectedCount <= pickMax;

    return candidatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: SelectableText(
          'load error: $e',
          style: const TextStyle(color: WuxiaColors.hpLow),
        ),
      ),
      data: (equipments) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RitualBanner(founderName: founder.name),
            const SizedBox(height: 16),
            _SectionTitle(
              '${UiStrings.ascensionPickEquipment} '
              '(${UiStrings.ascensionSelectionStatus.replaceFirst('{0}', '$selectedCount').replaceFirst('{1}', '$pickMax')})',
            ),
            const SizedBox(height: 8),
            if (equipments.isEmpty)
              const Text(
                UiStrings.ascensionNoEquipments,
                style: TextStyle(color: WuxiaColors.textMuted),
              )
            else
              ...equipments.map(
                (eq) => _EquipmentRow(
                  equipment: eq,
                  isSelected: selectedIds.contains(eq.id),
                  canSelectMore:
                      selectedIds.length < pickMax || selectedIds.contains(eq.id),
                  disciples: disciples,
                  assignedTo: assignments[eq.id],
                  onToggle: () => onToggle(eq.id, defaultDiscipleId),
                  onAssign: (id) => onAssign(eq.id, id),
                ),
              ),
            const SizedBox(height: 20),
            _PromotedDiscipleRow(
              disciples: disciples,
              promotedDiscipleId: promotedDiscipleId,
              onPromote: onPromote,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: canConfirm ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WuxiaColors.resultHighlight,
                  disabledBackgroundColor:
                      WuxiaColors.panel.withValues(alpha: 0.5),
                ),
                child: Text(
                  isSubmitting ? '飞升中…' : UiStrings.ascensionConfirmButton,
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
    );
  }
}

/// 仪式横幅 · 异步加载 `ascension_intro` narrative(占 2 段)+ fallback
/// `UiStrings.ascensionRitualHint`(yaml 缺/解析失败时)。
class _RitualBanner extends StatelessWidget {
  const _RitualBanner({required this.founderName});

  final String founderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$founderName · ${UiStrings.ascensionTitle}',
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<NarrativeContent>(
            future: NarrativeLoader.load('ascension_intro'),
            builder: (context, snapshot) {
              final content = snapshot.data;
              if (content == null || content.isPlaceholder) {
                return const Text(
                  UiStrings.ascensionRitualHint,
                  style: TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                );
              }
              final intro = content.paragraphs.take(2).join('\n\n').trim();
              return Text(
                intro.isEmpty ? UiStrings.ascensionRitualHint : intro,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.equipment,
    required this.isSelected,
    required this.canSelectMore,
    required this.disciples,
    required this.assignedTo,
    required this.onToggle,
    required this.onAssign,
  });

  final Equipment equipment;
  final bool isSelected;
  final bool canSelectMore;
  final List<Character> disciples;
  final int? assignedTo;
  final VoidCallback onToggle;
  final void Function(int discipleId) onAssign;

  String _resolveName() {
    if (!GameRepository.isLoaded) return equipment.defId;
    return GameRepository.instance.equipmentDefs[equipment.defId]?.name ??
        equipment.defId;
  }

  @override
  Widget build(BuildContext context) {
    final name = _resolveName();
    final tierName = EnumL10n.equipmentTier(equipment.tier);
    final color = tierColorForEquipment(equipment.tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? WuxiaColors.panel.withValues(alpha: 0.9)
            : WuxiaColors.panel.withValues(alpha: 0.4),
        border: Border.all(
          color: isSelected ? color : WuxiaColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged:
                    (canSelectMore || isSelected) ? (_) => onToggle() : null,
                fillColor: WidgetStateProperty.all(color),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                tierName,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
          if (isSelected && disciples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(
                children: [
                  const Text(
                    UiStrings.ascensionAssignTo,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: assignedTo ?? disciples.first.id,
                    dropdownColor: WuxiaColors.panel,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: [
                      for (final d in disciples)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) onAssign(id);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
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

/// P5+ 真传位下拉(spec p5_lineage_full_spec §Q1 player_pick · ④+⑤ 合并 batch)。
///
/// 玩家选 1 个 disciple 接任 founder 身份。默认 = activeCharacterIds 顺序第 1
/// disciple(大弟子)。接任后 `disciple.isFounder=true` · founder_buff_service
/// 自然接管(active 中找到 isFounder=true → buff 激活 · §Q5 service 0 改)。
class _PromotedDiscipleRow extends StatelessWidget {
  const _PromotedDiscipleRow({
    required this.disciples,
    required this.promotedDiscipleId,
    required this.onPromote,
  });

  final List<Character> disciples;
  final int promotedDiscipleId;
  final void Function(int? id) onPromote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.panel.withValues(alpha: 0.6),
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(UiStrings.ascensionPromotedSection),
          const SizedBox(height: 4),
          const Text(
            UiStrings.ascensionPromotedHint,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: promotedDiscipleId,
            dropdownColor: WuxiaColors.panel,
            isExpanded: true,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 13,
            ),
            items: [
              for (final d in disciples)
                DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                ),
            ],
            onChanged: (id) {
              if (id != null) onPromote(id);
            },
          ),
        ],
      ),
    );
  }
}
