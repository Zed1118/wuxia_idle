import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/founder_creation_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/rng.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../application/onboarding_service.dart';
import '../domain/founder_creation_selection.dart';

class FounderCreationScreen extends ConsumerStatefulWidget {
  const FounderCreationScreen({super.key});

  @override
  ConsumerState<FounderCreationScreen> createState() =>
      _FounderCreationScreenState();
}

class _FounderCreationScreenState extends ConsumerState<FounderCreationScreen> {
  late final FounderCreationConfig _config;
  late final List<FounderFateOption> _fates;
  int _schoolIndex = 0;
  int _originIndex = 0;
  int _fateIndex = 0;
  bool _submitting = false;
  final _founderNameController = TextEditingController();
  final _sectNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = GameRepository.instance.founderCreation;
    _fates = generateFounderFateChoices(config: _config, rng: DefaultRng());
  }

  @override
  void dispose() {
    _founderNameController.dispose();
    _sectNameController.dispose();
    super.dispose();
  }

  void _rollFounderName() {
    final name = generateFounderName(
      GameRepository.instance.founderNames,
      ref.read(rngProvider),
    );
    if (name.isNotEmpty) _founderNameController.text = name;
  }

  void _rollSectName() {
    final name = generateSectName(
      GameRepository.instance.founderNames,
      ref.read(rngProvider),
    );
    if (name.isNotEmpty) _sectNameController.text = name;
  }

  FounderSchoolOption get _school => _config.schools[_schoolIndex];
  FounderOriginOption get _origin => _config.origins[_originIndex];
  FounderFateOption get _fate => _fates[_fateIndex];

  bool get _hasConfig =>
      _config.schools.isNotEmpty &&
      _config.origins.isNotEmpty &&
      _fates.isNotEmpty;

  Future<void> _confirm() async {
    if (_submitting || !_hasConfig) return;
    setState(() => _submitting = true);
    final founderName = _founderNameController.text.trim();
    final sectName = _sectNameController.text.trim();
    final didSeed = await OnboardingService(isar: IsarSetup.instance)
        .createFoundingMaster(
          selection: FounderCreationSelection(
            school: _school,
            origin: _origin,
            fate: _fate,
            founderName: founderName.isEmpty ? null : founderName,
            sectName: sectName.isEmpty ? null : sectName,
          ),
        );
    ref.invalidate(isarProvider);
    if (!mounted) return;
    if (didSeed) {
      await showFounderStarterGearDialog(context, _school);
      if (!mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainMenu()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.founderCreateTitle),
        leading: IconButton(
          tooltip: UiStrings.founderCreateBack,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: !_hasConfig
            ? const Center(
                child: Text(
                  UiStrings.founderCreateNoConfig,
                  style: TextStyle(color: WuxiaColors.textSecondary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 20),
                        _Section(
                          title: UiStrings.founderCreateSchoolSection,
                          child: _ChoiceWrap(
                            count: _config.schools.length,
                            itemBuilder: (i) {
                              final option = _config.schools[i];
                              return _ChoiceCard(
                                selected: i == _schoolIndex,
                                title: option.label,
                                subtitle: option.temperament,
                                body: option.summary,
                                footer: option.attributeHint,
                                color: WuxiaColors.schoolColor(option.school),
                                onTap: () => setState(() => _schoolIndex = i),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: UiStrings.founderCreateOriginSection,
                          child: _ChoiceWrap(
                            count: _config.origins.length,
                            itemBuilder: (i) {
                              final option = _config.origins[i];
                              return _ChoiceCard(
                                selected: i == _originIndex,
                                title: option.label,
                                subtitle:
                                    UiStrings.founderCreateStartingResource,
                                body: option.summary,
                                footer: option.resourceSummary,
                                color: WuxiaColors.resultHighlight,
                                onTap: () => setState(() => _originIndex = i),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: UiStrings.founderCreateFateSection,
                          child: _ChoiceWrap(
                            count: _fates.length,
                            itemBuilder: (i) {
                              final option = _fates[i];
                              return _ChoiceCard(
                                selected: i == _fateIndex,
                                title: option.label,
                                subtitle: UiStrings.founderCreateAttributeTotal(
                                  option.attributeProfile.total,
                                ),
                                body: option.verse,
                                footer: option.focus,
                                color: WuxiaColors.resultHighlight,
                                onTap: () => setState(() => _fateIndex = i),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PreviewPanel(
                          school: _school,
                          origin: _origin,
                          fate: _fate,
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: UiStrings.founderCreateNameSection,
                          child: _NameFields(
                            founderController: _founderNameController,
                            sectController: _sectNameController,
                            onRollFounder: _rollFounderName,
                            onRollSect: _rollSectName,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _submitting ? null : _confirm,
                            child: Text(
                              _submitting
                                  ? UiStrings.splashLoadingHint
                                  : UiStrings.founderCreateConfirm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        UiStrings.founderCreateTitle,
        style: TextStyle(
          color: WuxiaColors.resultHighlight,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: 4,
        ),
      ),
      SizedBox(height: 6),
      Text(
        UiStrings.founderCreateSubtitle,
        style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 14),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({required this.count, required this.itemBuilder});

  final int count;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 760
          ? (constraints.maxWidth - 20) / 3
          : constraints.maxWidth;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(width: width, child: itemBuilder(i)),
        ],
      );
    },
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String body;
  final String footer;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.13) : WuxiaColors.panel,
        border: Border.all(
          color: selected ? color : WuxiaColors.border,
          width: selected ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : WuxiaColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Text(
                  UiStrings.founderCreateSelected,
                  style: TextStyle(color: color, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          // _ChoiceWrap 用 Wrap 排列(不等高),卡片拿到无界高度 → Spacer(flex)
          // 在此崩 debug RenderFlex 断言、release 中塌成 0(no-op)。移除:卡片按
          // 内容 shrink-wrap(AnimatedContainer minHeight:154 兜最小高),footer 紧随。
          const SizedBox(height: 8),
          Text(
            footer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12, height: 1.25),
          ),
        ],
      ),
    ),
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.school,
    required this.origin,
    required this.fate,
  });

  final FounderSchoolOption school;
  final FounderOriginOption origin;
  final FounderFateOption fate;

  @override
  Widget build(BuildContext context) {
    final attrs = fate.attributeProfile;
    final techniqueName = _techniqueName(school);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            UiStrings.founderCreatePreviewSection,
            style: TextStyle(
              color: WuxiaColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewPill(
                label: UiStrings.attrConstitution,
                value: '${attrs.constitution}',
                hint: UiStrings.founderCreateAttrConstitutionHint,
              ),
              _PreviewPill(
                label: UiStrings.attrEnlightenment,
                value: '${attrs.enlightenment}',
                hint: UiStrings.founderCreateAttrEnlightenmentHint,
              ),
              _PreviewPill(
                label: UiStrings.attrAgility,
                value: '${attrs.agility}',
                hint: UiStrings.founderCreateAttrAgilityHint,
              ),
              _PreviewPill(
                label: UiStrings.attrFortune,
                value: '${attrs.fortune}',
                hint: UiStrings.founderCreateAttrFortuneHint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PreviewLine(
            label: UiStrings.founderCreateStartingTechnique,
            value: techniqueName == null
                ? school.label
                : UiStrings.founderCreateTechniqueName(techniqueName),
          ),
          _PreviewLine(
            label: UiStrings.founderCreateStartingEquipment,
            value: UiStrings.founderCreateEquipmentNames(
              _equipmentNames(school),
            ),
          ),
          _PreviewLine(
            label: UiStrings.founderCreateStartingResource,
            value: origin.resourceSummary,
          ),
          _PreviewLine(
            label: UiStrings.founderCreateGoalHint,
            value: school.goalHint,
          ),
          _PreviewLine(
            label: UiStrings.founderCreateFateFocus,
            value: fate.focus,
          ),
          const SizedBox(height: 8),
          Text(
            UiStrings.founderCreateConfirmLine(
              school.label,
              origin.label,
              fate.label,
            ),
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.founderCreateReversibleHint,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String? _techniqueName(FounderSchoolOption school) {
    if (!GameRepository.isLoaded || school.startingTechniqueIds.isEmpty) {
      return null;
    }
    return GameRepository
        .instance
        .techniqueDefs[school.startingTechniqueIds.first]
        ?.name;
  }

  List<String> _equipmentNames(FounderSchoolOption school) {
    return _startingEquipmentDefs(school).map((e) => e.name).toList();
  }
}

Future<void> showFounderStarterGearDialog(
  BuildContext context,
  FounderSchoolOption school,
) async {
  await PaperDialog.show<void>(
    context,
    title: UiStrings.founderStarterGearDialogTitle,
    barrierDismissible: false,
    body: FounderStarterGearDialogBody(
      equipment: _startingEquipmentDefs(school),
    ),
    actions: [
      Builder(
        builder: (ctx) => PlaqueButton(
          label: UiStrings.founderStarterGearConfirm,
          primary: true,
          autofocus: true,
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ),
    ],
  );
}

class FounderStarterGearDialogBody extends StatelessWidget {
  const FounderStarterGearDialogBody({super.key, required this.equipment});

  final List<EquipmentDef> equipment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        UiStrings.founderStarterGearDialogIntro,
        style: TextStyle(
          color: WuxiaUi.ink,
          fontSize: 14,
          height: 1.7,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 10),
      DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper2.withValues(alpha: 0.44),
          border: Border.all(color: WuxiaUi.woodDark.withValues(alpha: 0.52)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            for (var i = 0; i < equipment.length; i++)
              _StarterEquipmentRow(
                equipment: equipment[i],
                showDivider: i != equipment.length - 1,
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        UiStrings.founderStarterGearEquippedHint,
        style: TextStyle(
          color: WuxiaUi.muted,
          fontSize: 12,
          height: 1.5,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

class _StarterEquipmentRow extends StatelessWidget {
  const _StarterEquipmentRow({
    required this.equipment,
    required this.showDivider,
  });

  final EquipmentDef equipment;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: showDivider
            ? BorderSide(color: WuxiaUi.ink.withValues(alpha: 0.12))
            : BorderSide.none,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              EnumL10n.equipmentSlot(equipment.slot),
              style: const TextStyle(
                color: WuxiaUi.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              equipment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

List<EquipmentDef> _startingEquipmentDefs(FounderSchoolOption school) {
  if (!GameRepository.isLoaded || school.startingEquipmentIds.isEmpty) {
    return const [];
  }
  final repo = GameRepository.instance;
  final defs = school.startingEquipmentIds
      .map((id) => repo.equipmentDefs[id])
      .whereType<EquipmentDef>()
      .toList();
  const slotOrder = [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ];
  defs.sort(
    (a, b) => slotOrder.indexOf(a.slot).compareTo(slotOrder.indexOf(b.slot)),
  );
  return defs;
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: WuxiaColors.background,
      border: Border.all(color: WuxiaColors.border),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $value',
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NameFields extends StatelessWidget {
  const _NameFields({
    required this.founderController,
    required this.sectController,
    required this.onRollFounder,
    required this.onRollSect,
  });

  final TextEditingController founderController;
  final TextEditingController sectController;
  final VoidCallback onRollFounder;
  final VoidCallback onRollSect;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _NameRow(
        label: UiStrings.founderCreateFounderNameLabel,
        hint: UiStrings.founderCreateFounderNameHint,
        controller: founderController,
        maxLength: 8,
        onRoll: onRollFounder,
      ),
      const SizedBox(height: 12),
      _NameRow(
        label: UiStrings.founderCreateSectNameLabel,
        hint: UiStrings.founderCreateSectNameHint,
        controller: sectController,
        maxLength: 12,
        onRoll: onRollSect,
      ),
    ],
  );
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxLength,
    required this.onRoll,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLength;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 64,
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
      Expanded(
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          style: const TextStyle(color: WuxiaColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: WuxiaColors.textMuted),
            counterText: '',
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: onRoll,
        icon: const Icon(Icons.casino_outlined, size: 18),
        label: const Text(UiStrings.founderCreateRollName),
      ),
    ],
  );
}
