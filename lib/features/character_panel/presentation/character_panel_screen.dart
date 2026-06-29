import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../cultivation/application/skill_proficiency_formatter.dart';
import '../../cultivation/application/synergy_service.dart';
import '../../inheritance/application/founder_buff_providers.dart';
import '../../sect/application/sect_providers.dart';
import '../../inner_demon/application/inner_demon_providers.dart';
import '../../inner_demon/domain/inner_demon_panel.dart';
import '../../inner_demon/presentation/breakthrough_blocker.dart';
import '../../inner_demon/presentation/inner_demon_screen.dart';
import '../../injury/presentation/injury_status_view.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/equipment_glyph.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/widgets/equipment_art_image.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import 'encounter_skill_section.dart';
import 'equip_slot_dialog.dart';

/// 角色面板（phase2_tasks.md T28 + Phase 3 Week 4 T56）。
///
/// T28 单角色版面 → T56 顶部 Tab 三角色切换 + 「师承」段。布局：
/// - 顶部：TabBar（祖师 / 大弟子 / 二弟子）从 [activeCharacterIdsProvider] 读 id
/// - 中部：姓名 / 境界 / 流派色条 / 4 项属性 / 5 项派生数值（含师承 +5% 内力上限）
/// - 装备区：3 槽（武器 / 护甲 / 饰品），未装备显示灰色占位
/// - 心法区：主修高亮 + 3 辅修槽 + 修炼度进度条
/// - 师承段：师父 / 徒弟 / 传记占位 / 师承遗物列表
///
/// `initialCharacterId` 构造参数指定首屏 Tab；其他 Tab 切换走内部 state。
/// 不显示装备/心法名字（spec §403/§404 未要求，避免硬编码中文文案风险），
/// 但师承遗物 section 显示装备名（走 GameRepository.getEquipment(defId).name）。
class CharacterPanelScreen extends ConsumerStatefulWidget {
  const CharacterPanelScreen({super.key, required this.characterId});

  /// 首屏展示的角色 id（与既有 main_menu / Phase2SeedService 对齐）。
  final int characterId;

  @override
  ConsumerState<CharacterPanelScreen> createState() =>
      _CharacterPanelScreenState();
}

class _CharacterPanelScreenState extends ConsumerState<CharacterPanelScreen> {
  late int _selectedCharacterId = widget.characterId;

  @override
  Widget build(BuildContext context) {
    final idsAsync = ref.watch(activeCharacterIdsProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.characterPanelScreenTitle,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
        trailing: const ContextHelpButton(topic: HelpTopic.realm),
      ),
      body: SafeArea(
        child: idsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(activeCharacterIdsProvider),
          ),
          data: (ids) => _PanelWithTabs(
            ids: ids.isEmpty ? [widget.characterId] : ids,
            selectedId: _selectedCharacterId,
            onSelect: (id) => setState(() => _selectedCharacterId = id),
          ),
        ),
      ),
    );
  }
}

class _PanelWithTabs extends ConsumerWidget {
  const _PanelWithTabs({
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });

  final List<int> ids;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 若构造时传入的 characterId 不在 activeCharacterIds 内（例如老存档），
    // 兜底切到第一位，避免渲染 _Body 时 character 一直 null。
    final effectiveId = ids.contains(selectedId) ? selectedId : ids.first;
    final async = ref.watch(characterByIdProvider(effectiveId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LineageTabBar(ids: ids, selectedId: effectiveId, onSelect: onSelect),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(characterByIdProvider(effectiveId)),
            ),
            data: (c) => c == null
                ? const Center(
                    child: Text(
                      UiStrings.characterNotFound,
                      style: TextStyle(color: WuxiaColors.textMuted),
                    ),
                  )
                : _Body(character: c),
          ),
        ),
      ],
    );
  }
}

class _LineageTabBar extends StatelessWidget {
  const _LineageTabBar({
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });

  final List<int> ids;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (
            var i = 0;
            i < ids.length && i < UiStrings.lineageTabLabels.length;
            i++
          )
            Padding(
              padding: EdgeInsets.only(right: i == ids.length - 1 ? 0 : 10),
              child: PlaqueTab(
                label: UiStrings.lineageTabLabels[i],
                selected: ids[i] == selectedId,
                onTap: () => onSelect(ids[i]),
              ),
            ),
        ],
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
          _ProfileHeaderCard(character: character),
          _BreakthroughBlockerSection(character: character),
          const SizedBox(height: 16),
          _DerivedStatsSection(character: character),
          const SizedBox(height: 16),
          _EquipmentSection(character: character),
          const SizedBox(height: 16),
          _TechniqueSection(character: character),
          const SizedBox(height: 16),
          EncounterSkillSection(character: character),
          const SizedBox(height: 16),
          _LineageSection(character: character),
        ],
      ),
    );
  }
}

/// 角色档案头:立绘 + 姓名 + 境界·层 + 流派名 + 4 基础属性,聚成一张武侠档案卡。
/// 立绘走 [PortraitFrame](portraitPath 为 null 时优雅退占位)。
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaUi.muted
        : WuxiaColors.schoolColor(character.school!);
    final a = character.attributes;
    return _PanelCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfilePortraitPlaque(
            character: character,
            borderColor: schoolColor,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (character.school != null)
                      _SchoolBadge(
                        label: EnumL10n.school(character.school!),
                        color: schoolColor,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x2EF3E6C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: WuxiaUi.ink.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        UiStrings.profileRealmLabel,
                        style: TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        EnumL10n.realm(
                          character.realmTier,
                          character.realmLayer,
                        ),
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 第八阶段·角色等级 Lv:等级 chip + 经验条(config 读用 instanceOrNull
                // 守,缺 GameRepository 时退化为纯 Lv 数字不崩轻量测)。
                _LevelChip(character: character),
                const SizedBox(height: 8),
                InjuryStatusPanel(
                  character: character,
                  alwaysShow: true,
                  showRecoveryAction: true,
                ),
                const SizedBox(height: 12),
                _AttributeStrip(
                  attributes: [
                    _AttributeView(
                      UiStrings.attrConstitution,
                      a.constitution,
                      UiStrings.glossaryConstitution,
                    ),
                    _AttributeView(
                      UiStrings.attrEnlightenment,
                      a.enlightenment,
                      UiStrings.glossaryEnlightenment,
                    ),
                    _AttributeView(
                      UiStrings.attrAgility,
                      a.agility,
                      UiStrings.glossaryAgility,
                    ),
                    _AttributeView(
                      UiStrings.attrFortune,
                      a.fortune,
                      UiStrings.glossaryFortune,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 第八阶段·角色等级 Lv chip:「等级 Lv N」+ 经验条(满级显「巅峰」)。
///
/// config 读用 [GameRepository.instanceOrNull] 守:缺 GameRepository(轻量 widget
/// 测无 game data)时退化为纯 Lv 数字、不渲染经验条,不崩(沿 home_feed 防御体例)。
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final lvCfg = GameRepository.instanceOrNull?.numbers.level;
    // 防御:旧档 Isar 哨兵 level(负)漏过启动 repair 时仍显 Lv 1 不崩(双保险)。
    final lv = character.level < 1 ? 1 : character.level;
    final lvExp = character.levelExp < 0 ? 0 : character.levelExp;
    final atMax = lvCfg != null && lv >= lvCfg.maxLevel;
    final toNext = (lvCfg != null && !atMax) ? lvCfg.expToNext(lv) : 0;
    final frac = toNext > 0 ? (lvExp / toNext).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x2EF3E6C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                UiStrings.profileLevelLabel,
                style: TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv $lv',
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                atMax ? '巅峰' : '$lvExp / $toNext',
                style: const TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (lvCfg != null) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 4,
                backgroundColor: WuxiaUi.ink.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(
                  WuxiaUi.gold.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilePortraitPlaque extends StatelessWidget {
  const _ProfilePortraitPlaque({
    required this.character,
    required this.borderColor,
  });

  final Character character;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: WuxiaUi.ink.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: WuxiaUi.ink.withValues(alpha: 0.22),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  UiStrings.profilePortraitPlaque,
                  style: TextStyle(
                    color: WuxiaUi.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: WuxiaUi.ink.withValues(alpha: 0.22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7D8B8),
                  border: Border.all(
                    color: WuxiaUi.ink.withValues(alpha: 0.58),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 4,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  width: 102,
                  height: 102,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 0.9,
                        child: PortraitFrame(
                          portraitPath: character.portraitPath,
                          size: 102,
                          borderColor: Colors.transparent,
                          placeholderText: character.name,
                          fit: BoxFit.contain,
                        ),
                      ),
                      ColoredBox(color: WuxiaUi.paper.withValues(alpha: 0.12)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              WuxiaUi.ink.withValues(alpha: 0.18),
                              Colors.transparent,
                              WuxiaUi.ink.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 3,
                bottom: 2,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    WuxiaUi.sealRed,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: WuxiaUi.ink.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _lineageRoleLabel(character.lineageRole),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.paper,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _lineageRoleLabel(LineageRole role) {
    return switch (role) {
      LineageRole.founder => UiStrings.lineageRoleFounder,
      LineageRole.disciple => UiStrings.lineageRoleDisciple,
      LineageRole.senior => UiStrings.lineageRoleSenior,
      LineageRole.junior => UiStrings.lineageRoleJunior,
      LineageRole.grandDisciple => UiStrings.lineageRoleGrandDisciple,
    };
  }
}

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AttributeView {
  const _AttributeView(this.label, this.value, this.definition);

  final String label;
  final int value;

  /// M4 术语释义（GlossaryLabel 气泡）。
  final String definition;
}

class _AttributeStrip extends StatelessWidget {
  const _AttributeStrip({required this.attributes});

  final List<_AttributeView> attributes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < attributes.length; i++) ...[
          Expanded(child: _AttributeChip(attribute: attributes[i])),
          if (i != attributes.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _AttributeChip extends StatelessWidget {
  const _AttributeChip({required this.attribute});

  final _AttributeView attribute;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0x3AF3E6C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlossaryLabel(
            label: attribute.label,
            definition: attribute.definition,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${attribute.value}',
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// wuSheng 阶心魔关未通 + 满经验时,在 _TopBar 下方插入拦截提示。
///
/// P0-3 ③:武圣常驻心魔成长瓶颈面板。非武圣 → shrink;否则 watch
/// [innerDemonProgressProvider] + [resolveInnerDemonPanel] 决定 cleared /
/// blocked / inProgress 三态,渲染 [InnerDemonProgressPanel]。进阶仍自动,
/// 「突破」CTA 仅导航至 [InnerDemonScreen]。
class _BreakthroughBlockerSection extends ConsumerWidget {
  const _BreakthroughBlockerSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (character.realmTier != RealmTier.wuSheng) {
      return const SizedBox.shrink();
    }
    final progressAsync = ref.watch(innerDemonProgressProvider);
    final progress = progressAsync.asData?.value;
    if (progress == null) return const SizedBox.shrink(); // loading/err 不闪

    final innerDemonDef = GameRepository.instance.numbers.innerDemon;
    final data = resolveInnerDemonPanel(
      character: character,
      progress: progress,
      innerDemonDef: innerDemonDef,
    );
    if (data == null) return const SizedBox.shrink();

    String? nameFor(String? id) =>
        id == null ? null : (GameRepository.instance.stageDefs[id]?.name ?? id);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InnerDemonProgressPanel(
        state: data.state,
        clearedCount: data.clearedCount,
        totalCount: data.totalCount,
        blockingStageName: nameFor(data.blockingStageId),
        nextStageName: nameFor(data.nextStageId),
        onNavigate: data.state == InnerDemonPanelState.cleared
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InnerDemonScreen()),
              ),
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
              equipped: equipped
                  .map((a) => a.value)
                  .whereType<Equipment>()
                  .toList(),
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
        .map(
          (id) => id == null
              ? const AsyncData<Equipment?>(null)
              : ref.watch(equipmentByIdProvider(id)),
        )
        .toList();
  }

  Widget _renderStats(
    BuildContext context,
    WidgetRef ref, {
    required List<Equipment> equipped,
    required Technique? mainTech,
  }) {
    final n = ref.watch(numbersConfigProvider);
    // P1.1 A1 E.5:祖师爷 buff 激活态,loading/error 默认 false 兜底
    final founderBuffActive = ref
        .watch(founderBuffActiveProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);
    final hp = CharacterDerivedStats.maxHp(
      character,
      equipped,
      n,
      founderBuffActive: founderBuffActive,
    );
    final ifMax = CharacterDerivedStats.internalForceMaxWithLineage(
      character,
      equipped,
      n,
      founderBuffActive: founderBuffActive,
    );
    final speedText = mainTech == null
        ? UiStrings.dashPlaceholder
        : '${CharacterDerivedStats.speed(character, equipped, mainTech, n)}';
    final critText = UiStrings.percent(
      CharacterDerivedStats.criticalRate(
        character,
        n,
        founderBuffActive: founderBuffActive,
      ),
    );
    final evadeText = UiStrings.percent(
      CharacterDerivedStats.evasionRate(character, n),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DerivedStatCard(
                label: UiStrings.statHp,
                value: '$hp',
                glossary: UiStrings.glossaryHp,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DerivedStatCard(
                label: UiStrings.statInternalForce,
                value: UiStrings.internalForceValue(
                  character.internalForce,
                  ifMax,
                ),
                glossary: UiStrings.glossaryInternalForce,
                valueFontSize: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DerivedStatCard(
                label: UiStrings.statSpeed,
                value: speedText,
                glossary: UiStrings.glossarySpeed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DerivedStatCard(
                label: UiStrings.statCriticalRate,
                value: critText,
                glossary: UiStrings.glossaryCriticalRate,
                accentColor: WuxiaUi.jiang,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DerivedStatCard(
                label: UiStrings.statEvasionRate,
                value: evadeText,
                glossary: UiStrings.glossaryEvasionRate,
                accentColor: WuxiaUi.woodDark,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _EquipmentSection extends ConsumerWidget {
  const _EquipmentSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelEquipment),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tappableSlot(
                  context,
                  ref,
                  EquipmentSlot.weapon,
                  character.equippedWeaponId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tappableSlot(
                  context,
                  ref,
                  EquipmentSlot.armor,
                  character.equippedArmorId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tappableSlot(
                  context,
                  ref,
                  EquipmentSlot.accessory,
                  character.equippedAccessoryId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // H1 批2:槽位可点 → 装备 picker(玩家手动穿戴入口 · 修核心循环断裂)。
  Widget _tappableSlot(
    BuildContext context,
    WidgetRef ref,
    EquipmentSlot slot,
    int? equipmentId,
  ) {
    return InkWell(
      // 2026-06-26:点槽一步到位进居中两栏对话框(候选mini-diff + 全量对比)。
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => EquipSlotDialog(
          character: character,
          slot: slot,
          currentId: equipmentId,
        ),
      ),
      child: _EquipmentSlotTile(slot: slot, equipmentId: equipmentId),
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
      return _EquipmentSlotShell(
        borderColor: WuxiaUi.woodDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slotLabel,
              style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              UiStrings.slotEmpty,
              style: TextStyle(
                color: WuxiaUi.ink,
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
      loading: () => const _EquipmentSlotShell(
        borderColor: WuxiaColors.border,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _EquipmentSlotShell(
        borderColor: WuxiaColors.hpLow,
        child: Text(
          '$e',
          style: const TextStyle(color: WuxiaColors.hpLow, fontSize: 11),
        ),
      ),
      data: (eq) {
        if (eq == null) {
          return _EquipmentSlotShell(
            borderColor: WuxiaUi.woodDark,
            child: Center(
              child: Text(
                slotLabel,
                style: const TextStyle(color: WuxiaUi.muted),
              ),
            ),
          );
        }
        final tierColor = tierColorForEquipment(eq.tier);
        final resonance = eq.resonanceStage(n);
        final iconPath =
            GameRepository.instance.equipmentDefs[eq.defId]?.iconPath;
        return _EquipmentSlotShell(
          borderColor: tierColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    EnumL10n.equipmentSlot(eq.slot),
                    style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
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
              Expanded(
                child: Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE3C7),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.7),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: iconPath == null
                        ? EquipGlyph(tierColor: tierColor, slot: eq.slot)
                        : Transform.scale(
                            scale: 1.2,
                            child: EquipmentArtImage(
                              imagePath: iconPath,
                              fallback: EquipGlyph(
                                tierColor: tierColor,
                                slot: eq.slot,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if ((GameRepository.instance.equipmentDefs[eq.defId]?.name ??
                          '')
                      .isNotEmpty) ...[
                    Text(
                      GameRepository.instance.equipmentDefs[eq.defId]!.name,
                      style: const TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    EnumL10n.equipmentTier(eq.tier),
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // W12 fix: 视觉验收 debug 字段——battleCount 数字直显。
                  Text(
                    EnumL10n.resonanceStage(resonance),
                    style: const TextStyle(color: WuxiaUi.ink, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#${eq.battleCount}',
                    style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
                  ),
                ],
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
          // W18-A1 心法相生 chip(GDD §4.5):0/1 个,命中即显
          _SynergyChip(character: character),
        ],
      ),
    );
  }
}

/// W18-A1 心法相生 chip(GDD §4.5)。
///
/// watch 主修 + 全部辅修 [techniqueByIdProvider],都 ready 后调
/// [SynergyService.detectActive] 同步判定;命中即显 name + multiplier 摘要
/// chip,否则隐藏(0/1 个,与服务层语义一致)。
class _SynergyChip extends ConsumerWidget {
  const _SynergyChip({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainId = character.mainTechniqueId;
    if (mainId == null || character.assistTechniqueIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final mainAsync = ref.watch(techniqueByIdProvider(mainId));
    final assistAsyncs = [
      for (final assistId in character.assistTechniqueIds)
        ref.watch(techniqueByIdProvider(assistId)),
    ];

    if (!mainAsync.hasValue ||
        assistAsyncs.any((assistAsync) => !assistAsync.hasValue)) {
      return const SizedBox.shrink();
    }
    final mainTech = mainAsync.value;
    if (mainTech == null) return const SizedBox.shrink();
    final ownedTechniques = [
      mainTech,
      for (final assistAsync in assistAsyncs)
        if (assistAsync.value != null) assistAsync.value!,
    ];

    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: ownedTechniques,
      techDefLookup: (defId) => GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    if (synergy == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: WuxiaColors.resultHighlight,
            ),
            const SizedBox(width: 6),
            const Text(
              UiStrings.synergyActiveLabel,
              style: TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${synergy.name} · ${synergy.multipliers.summary()}',
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 12.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
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
        final techName =
            GameRepository.instance.techniqueDefs[t.defId]?.name ??
            UiStrings.techniqueRoleMain;
        final progress = t.cultivationProgressToNext == 0
            ? 0.0
            : (t.cultivationProgress / t.cultivationProgressToNext)
                  .clamp(0.0, 1.0)
                  .toDouble();
        // D：修炼度五要素「当前/下一阶效果」= 当前层 / 下一层伤害倍率。
        final n = ref.watch(numbersConfigProvider);
        final layer = t.cultivationLayer;
        final curMult = n.cultivationMultiplier[layer] ?? 1.0;
        final layers = CultivationLayer.values;
        final layerIdx = layers.indexOf(layer);
        final isMaxLayer = layerIdx >= layers.length - 1;
        final nextMultText = isMaxLayer
            ? UiStrings.cultivationMaxLayer
            : UiStrings.cultivationNextDamageMult(
                n.cultivationMultiplier[layers[layerIdx + 1]] ?? curMult,
              );
        final techDef = GameRepository.instance.techniqueDefs[t.defId];
        final skillUsage = {
          for (final entry in t.skillUsageCount) entry.skillId: entry.count,
        };
        final skillSummary =
            SkillProficiencyFormatter.bestSkillSummaryForTechnique(
              skills: [
                for (final id in techDef?.skillIds ?? const <String>[])
                  if (GameRepository.instance.skillDefs.containsKey(id))
                    GameRepository.instance.getSkill(id),
              ],
              usage: skillUsage,
              cfg: n.skillProficiency,
            );
        return IntrinsicHeight(
          child: WuxiaPaperPanel(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
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
                      const Spacer(),
                      Text(
                        EnumL10n.techniqueTier(t.tier),
                        style: const TextStyle(
                          color: WuxiaColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    techName,
                    style: TextStyle(
                      color: schoolColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // D：修炼度五要素 Row（卡内子段，title 省略不重复心法名）。
                  StageProgressRow(
                    stageName: EnumL10n.cultivationLayer(t.cultivationLayer),
                    glossaryDefinition: UiStrings.glossaryCultivation,
                    ratio: progress,
                    currentEffect: UiStrings.cultivationDamageMult(curMult),
                    nextEffect: nextMultText,
                    progressText: UiStrings.cultivationProgress(
                      t.cultivationProgress,
                      t.cultivationProgressToNext,
                    ),
                  ),
                  if (skillSummary != null) ...[
                    const SizedBox(height: 8),
                    StageProgressRow(
                      title: UiStrings.skillProficiencyBestSkillTitle(
                        skillSummary.skill.name,
                      ),
                      stageName: skillSummary.stageName,
                      ratio: skillSummary.ratio,
                      currentEffect: skillSummary.currentEffect,
                      nextEffect: skillSummary.nextEffect,
                      progressText: skillSummary.progressText,
                    ),
                  ],
                ],
              ),
            ),
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
        borderColor: WuxiaUi.woodDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              UiStrings.techniqueRoleAssist,
              style: TextStyle(color: WuxiaUi.muted, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              UiStrings.techniqueEmpty,
              style: TextStyle(color: WuxiaUi.ink, fontSize: 13),
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
            borderColor: WuxiaUi.woodDark,
            child: Center(
              child: Text(
                UiStrings.techniqueEmpty,
                style: TextStyle(color: WuxiaUi.muted),
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
                style: TextStyle(color: WuxiaUi.muted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                EnumL10n.techniqueTier(t.tier),
                style: TextStyle(color: schoolColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                EnumL10n.cultivationLayer(t.cultivationLayer),
                style: const TextStyle(color: WuxiaUi.ink, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 师承段（T56，GDD §7.1）
// ─────────────────────────────────────────────────────────────────────────────

class _LineageSection extends ConsumerWidget {
  const _LineageSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.panelLineage),
          const SizedBox(height: 8),
          _LineageMasterRow(masterId: character.masterId),
          const SizedBox(height: 6),
          _LineageDisciplesRow(discipleIds: character.discipleIds),
          const SizedBox(height: 6),
          const _LineageBiographyRow(),
          const SizedBox(height: 6),
          _LineageHeritageRow(character: character),
          const SizedBox(height: 6),
          _SectMembershipRow(character: character),
        ],
      ),
    );
  }
}

class _LineageMasterRow extends ConsumerWidget {
  const _LineageMasterRow({required this.masterId});

  final int? masterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (masterId == null) {
      return const _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: UiStrings.lineageNoMaster,
      );
    }
    final async = ref.watch(characterByIdProvider(masterId!));
    return async.when(
      loading: () => const _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: UiStrings.dashPlaceholder,
      ),
      error: (e, _) => _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: '$e',
        valueColor: WuxiaColors.hpLow,
      ),
      data: (m) => _LineageRow(
        label: UiStrings.lineageMasterLabel,
        value: m == null ? UiStrings.lineageNoMaster : m.name,
      ),
    );
  }
}

/// P4.1 1.1 polish · 门派同道行(character_panel sect NPC 集成 · Q6A/Q6B closeout
/// deviation 续 · sect_screen listMembers 已 ship,本批 character_panel 集成)。
///
/// 数据源:`playerSectIdProvider`(int?)+ `sectMembersProvider(sectId)` future
/// list。过滤:排 founder(玩家自己 / 前代祖师)+ 排当前 character active(避免显
/// 自己)。空状态显「门派人少」(sect.id null 或 0 NPC 同样语义)。
class _SectMembershipRow extends ConsumerWidget {
  const _SectMembershipRow({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerSectId = ref.watch(playerSectIdProvider);
    if (playerSectId == null) {
      return const _LineageRow(
        label: UiStrings.panelSectMembersLabel,
        value: UiStrings.panelSectMembersEmpty,
      );
    }
    final membersAsync = ref.watch(sectMembersProvider(playerSectId));
    return membersAsync.when(
      loading: () => const _LineageRow(
        label: UiStrings.panelSectMembersLabel,
        value: UiStrings.dashPlaceholder,
      ),
      error: (e, _) => _LineageRow(
        label: UiStrings.panelSectMembersLabel,
        value: '$e',
        valueColor: WuxiaColors.hpLow,
      ),
      data: (members) {
        // 排 founder(玩家自己 / 前代祖师)+ 排当前 character active 自己
        final others = members
            .where((m) => !m.isFounder && m.id != character.id)
            .toList();
        if (others.isEmpty) {
          return const _LineageRow(
            label: UiStrings.panelSectMembersLabel,
            value: UiStrings.panelSectMembersEmpty,
          );
        }
        return _LineageRow(
          label: UiStrings.panelSectMembersLabel,
          value: others.map((m) => m.name).join(' / '),
        );
      },
    );
  }
}

class _LineageDisciplesRow extends ConsumerWidget {
  const _LineageDisciplesRow({required this.discipleIds});

  final List<int> discipleIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (discipleIds.isEmpty) {
      return const _LineageRow(
        label: UiStrings.lineageDisciplesLabel,
        value: UiStrings.lineageNoDisciples,
      );
    }
    final asyncs = discipleIds
        .map((id) => ref.watch(characterByIdProvider(id)))
        .toList();
    if (asyncs.any((a) => a.isLoading)) {
      return const _LineageRow(
        label: UiStrings.lineageDisciplesLabel,
        value: UiStrings.dashPlaceholder,
      );
    }
    final names = asyncs
        .map((a) => a.value)
        .whereType<Character>()
        .map((c) => c.name)
        .toList();
    return _LineageRow(
      label: UiStrings.lineageDisciplesLabel,
      value: names.isEmpty ? UiStrings.lineageNoDisciples : names.join(' / '),
    );
  }
}

class _LineageBiographyRow extends StatelessWidget {
  const _LineageBiographyRow();

  @override
  Widget build(BuildContext context) {
    return const _LineageRow(
      label: UiStrings.lineageBiographyLabel,
      value: UiStrings.lineageBiographyPlaceholder,
      valueColor: WuxiaUi.muted,
    );
  }
}

class _LineageHeritageRow extends ConsumerWidget {
  const _LineageHeritageRow({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ].whereType<int>().toList();
    if (ids.isEmpty) {
      return const _LineageRow(
        label: UiStrings.lineageHeritageLabel,
        value: UiStrings.lineageNoHeritage,
      );
    }
    final asyncs = ids
        .map((id) => ref.watch(equipmentByIdProvider(id)))
        .toList();
    if (asyncs.any((a) => a.isLoading)) {
      return const _LineageRow(
        label: UiStrings.lineageHeritageLabel,
        value: UiStrings.dashPlaceholder,
      );
    }
    final heritage = asyncs
        .map((a) => a.value)
        .whereType<Equipment>()
        .where((e) => e.isLineageHeritage)
        .toList();
    final names = heritage.map(_resolveName).toList();
    final mainRow = _LineageRow(
      label: UiStrings.lineageHeritageLabel,
      value: names.isEmpty ? UiStrings.lineageNoHeritage : names.join(' / '),
    );
    if (heritage.isEmpty) return mainRow;
    // P5+ 多代传承 chip:取所装 heritage 件中 prev len 最大值,> 1 时显「{N} 代
    // 传承」副行(N = prevLen + 1 算上当前持有者)。语义:gen2 起 chip 才出现
    // (gen1 prev=[founder] · 玩家眼中只是「师父传的」不需 chip 提醒)。
    final maxPrevLen = heritage.fold<int>(
      0,
      (m, e) => e.previousOwnerCharacterIds.length > m
          ? e.previousOwnerCharacterIds.length
          : m,
    );
    if (maxPrevLen <= 1) return mainRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainRow,
        const SizedBox(height: 2),
        _LineageRow(
          label: '',
          value: UiStrings.ascensionMultiGenChip.replaceFirst(
            '{0}',
            '${maxPrevLen + 1}',
          ),
          valueColor: WuxiaUi.muted,
        ),
      ],
    );
  }

  String _resolveName(Equipment eq) {
    if (!GameRepository.isLoaded) return eq.defId;
    return GameRepository.instance.equipmentDefs[eq.defId]?.name ?? eq.defId;
  }
}

class _LineageRow extends StatelessWidget {
  const _LineageRow({
    required this.label,
    required this.value,
    this.valueColor = WuxiaUi.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
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
    return PaperPanel(padding: const EdgeInsets.all(14), child: child);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(text, dividerMaxWidth: 520, dividerOpacity: 0.62);
  }
}

class _DerivedStatCard extends StatelessWidget {
  const _DerivedStatCard({
    required this.label,
    required this.value,
    this.glossary,
    this.valueFontSize = 25,
    this.accentColor = WuxiaUi.ink,
  });

  final String label;
  final String value;

  /// M4 术语释义；非空时标签包进 [GlossaryLabel]（带「?」+ 气泡）。
  final String? glossary;
  final double valueFontSize;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: const Color(0x3AF3E6C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.34)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: accentColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                glossary == null
                    ? Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : GlossaryLabel(
                        label: label,
                        definition: glossary!,
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
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

class _SlotShell extends StatelessWidget {
  const _SlotShell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  WuxiaUi.paperBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SizedBox(
              height: 88,
              child: Padding(padding: const EdgeInsets.all(8), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// 装备槽外壳(P0-3):比 [_SlotShell] 高(128),容纳装备图标 + 文字行。
/// 不动 88px [_SlotShell](辅修槽复用),3 装备槽用本壳对齐。
class _EquipmentSlotShell extends StatelessWidget {
  const _EquipmentSlotShell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  WuxiaUi.paperBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SizedBox(
              height: 198,
              child: Padding(padding: const EdgeInsets.all(8), child: child),
            ),
          ],
        ),
      ),
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
