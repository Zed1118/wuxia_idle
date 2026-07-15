import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/lineup_invalidation.dart';
import '../application/lineup_providers.dart';
import '../application/lineup_service.dart';

/// 出战编成屏(玩法评估 §十三 #4 · spec `2026-07-14-team-lineup-screen-design.md`)。
///
/// 上半 3 出战槽(槽序=站位序,slot 0 前排更易被集火),下半替补池
/// (全部 inactive 门人);**点选交换,不做拖拽**。角色卡如实展示差距
/// (境界/流派/AI 倾向/装备攻击),弱势替补只提示不拦截(§5.7 不写教程)。
///
/// 写路径唯一经 [LineupService.apply](祖师必在/1-3 人/闭关锁在服务层硬校验),
/// 本屏零直接 Isar 写;成功后 `invalidateAfterLineupChange` 刷新依赖面,
/// 下场战斗 `stage_battle_setup` 按新列表自动组队(战斗侧零改动)。
class TeamLineupScreen extends ConsumerWidget {
  const TeamLineupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeCharacterIdsProvider);
    final reserveAsync = ref.watch(lineupReserveProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.lineupTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(child: _buildBody(ref, activeAsync, reserveAsync)),
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    AsyncValue<List<int>> activeAsync,
    AsyncValue<List<Character>> reserveAsync,
  ) {
    final error = activeAsync.hasError
        ? activeAsync.error
        : (reserveAsync.hasError ? reserveAsync.error : null);
    if (error != null) {
      return ErrorFallback(
        error: error,
        onRetry: () {
          ref.invalidate(activeCharacterIdsProvider);
          ref.invalidate(lineupReserveProvider);
        },
      );
    }
    final activeIds = activeAsync.value;
    final reserve = reserveAsync.value;
    if (activeIds == null || reserve == null) {
      return const Center(child: InkLoadingIndicator());
    }
    return _Body(activeIds: activeIds, reserve: reserve);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.activeIds, required this.reserve});

  final List<int> activeIds;
  final List<Character> reserve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 槽位角色按 activeCharacterIds 原序解析(列表序=站位序)。
    final actives = <Character?>[
      for (final id in activeIds) ref.watch(characterByIdProvider(id)).value,
    ];
    final loaded = actives.whereType<Character>().toList();
    final int? minActiveLevel = loaded.isEmpty
        ? null
        : loaded
              .map((c) => RealmUtils.absoluteLevelOf(c.realmTier, c.realmLayer))
              .reduce(math.min);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineupActiveSection),
          const SizedBox(height: 2),
          const Text(
            UiStrings.lineupFrontRowHint,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 252,
            child: _FormationStage(activeIds: activeIds, actives: actives),
          ),
          const SizedBox(height: 16),
          _SectionTitle(UiStrings.lineupReserveSection(reserve.length)),
          const SizedBox(height: 8),
          Expanded(
            child: reserve.isEmpty
                ? const Center(
                    child: Text(
                      UiStrings.lineupReserveEmptyGuide,
                      style: TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: reserve.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _ReserveTile(
                      character: reserve[index],
                      isWeak:
                          minActiveLevel != null &&
                          RealmUtils.absoluteLevelOf(
                                reserve[index].realmTier,
                                reserve[index].realmLayer,
                              ) <
                              minActiveLevel,
                      activeIds: activeIds,
                      actives: actives,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 把编成顺序直接投影成战场站位预览。锦标位置与标准战场的
/// 我方三席同构：首席靠近中场，二/三席向左后方展开。
/// 这里仍是点选交换，不引入拖放。
class _FormationStage extends StatelessWidget {
  const _FormationStage({required this.activeIds, required this.actives});

  final List<int> activeIds;
  final List<Character?> actives;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lineup.formationStage'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF29251F),
        image: DecorationImage(
          image: const AssetImage(WuxiaUi.battleMountainPassStage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.28),
            BlendMode.darken,
          ),
        ),
        border: Border.all(color: const Color(0xFF6D5940)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1000;
          final rearWidth = compact ? 186.0 : 214.0;
          final frontWidth = compact ? 224.0 : 252.0;
          final rearHeight = compact ? 172.0 : 180.0;
          final frontHeight = compact ? 202.0 : 216.0;

          Widget slot(int index) {
            final isFront = index == 0;
            final width = isFront ? frontWidth : rearWidth;
            final height = isFront ? frontHeight : rearHeight;
            // 卡片按「三席 → 二席 → 首席」向交锋方向递进，
            // 与战场的斜向阵列同语义；保留间距使每张卡的整个
            // 点选面都可命中，不用重叠卡片牺牲操作性。
            final left = switch (index) {
              0 => rearWidth * 2 + 48,
              1 => rearWidth + 28,
              _ => 8.0,
            }.clamp(8.0, constraints.maxWidth - width - 8);
            final top = switch (index) {
              0 => 18.0,
              1 => 56.0,
              _ => 12.0,
            }.clamp(8.0, constraints.maxHeight - height - 8);
            return Positioned(
              key: ValueKey('lineup.formationSlot.$index'),
              left: left,
              top: top,
              width: width,
              height: height,
              child: index < actives.length && actives[index] != null
                  ? _ActiveSlotCard(
                      character: actives[index]!,
                      slotIndex: index,
                      activeIds: activeIds,
                      actives: actives,
                    )
                  : const _EmptySlotCard(),
            );
          }

          return Stack(
            children: [
              Positioned(
                right: constraints.maxWidth * 0.11,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.east,
                    size: compact ? 58 : 72,
                    color: WuxiaUi.gold.withValues(alpha: 0.42),
                  ),
                ),
              ),
              slot(2),
              slot(1),
              slot(0),
            ],
          );
        },
      ),
    );
  }
}

// ── 编成动作(点选交换,写路径统一走 LineupService)────────────────────────

/// 编成写入 + 结果反馈。成功后统一失效依赖 provider 面。
Future<void> _applyLineup(
  BuildContext context,
  WidgetRef ref,
  List<int> newActiveIds,
) async {
  final service = ref.read(lineupServiceProvider);
  if (service == null) return; // 测试旁路:未 init Isar
  final result = await service.apply(newActiveIds: newActiveIds);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (result.isSuccess) {
    invalidateAfterLineupChange(ref.invalidate);
    messenger.showSnackBar(
      const SnackBar(content: Text(UiStrings.lineupApplySuccess)),
    );
    return;
  }
  final message = switch (result.status) {
    LineupApplyStatus.retreatLocked => UiStrings.lineupRetreatLockedSnack,
    LineupApplyStatus.noMainTechnique => UiStrings.lineupNoMainSnack,
    LineupApplyStatus.founderMissing ||
    LineupApplyStatus.ascendedFounder => UiStrings.lineupFounderMustStay,
    _ => UiStrings.lineupApplyFailed,
  };
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// 点替补卡:择一出战席换防(或补空席)。闭关中替补入口即拦。
Future<void> _onReserveTap(
  BuildContext context,
  WidgetRef ref, {
  required Character candidate,
  required List<int> activeIds,
  required List<Character?> actives,
}) async {
  if (candidate.currentRetreatSessionId != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(UiStrings.lineupRetreatLockedSnack)),
    );
    return;
  }
  // 未修主修入口即拦(服务层同规校验兜底,含主修行悬空边缘;
  // §5.7 引导:研习立为主修后自然可上场,不写教程弹窗)。
  if (candidate.mainTechniqueId == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(UiStrings.lineupNoMainSnack)));
    return;
  }
  final slotIndex = await PaperDialog.show<int>(
    context,
    title: UiStrings.lineupSwapInTitle(candidate.name),
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          UiStrings.lineupChooseSlotBody,
          style: TextStyle(
            color: WuxiaUi.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < activeIds.length; i++)
          if (actives[i] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlaqueButton(
                label: UiStrings.lineupReplaceSlot(
                  UiStrings.lineupSlotLabel(i),
                  actives[i]!.name,
                ),
                onTap: () => Navigator.of(context).pop(i),
              ),
            ),
        if (activeIds.length < 3)
          PlaqueButton(
            label: UiStrings.lineupTakeEmptySlot(
              UiStrings.lineupSlotLabel(activeIds.length),
            ),
            primary: true,
            onTap: () => Navigator.of(context).pop(activeIds.length),
          ),
      ],
    ),
    actions: [
      PlaqueButton(
        label: UiStrings.commonCancel,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
  if (slotIndex == null || !context.mounted) return;
  final newIds = List<int>.of(activeIds);
  if (slotIndex < newIds.length) {
    newIds[slotIndex] = candidate.id;
  } else {
    newIds.add(candidate.id);
  }
  await _applyLineup(context, ref, newIds);
}

/// 点出战卡:下场(祖师/闭关中/独守时不提供)或与他席互换(纯重排,闭关不拦)。
/// pop 值:-1 = 下场,>=0 = 与该槽互换,null = 取消。
Future<void> _onActiveTap(
  BuildContext context,
  WidgetRef ref, {
  required Character character,
  required int slotIndex,
  required List<int> activeIds,
  required List<Character?> actives,
}) async {
  final canRetire =
      !character.isFounder &&
      activeIds.length > 1 &&
      character.currentRetreatSessionId == null;
  final action = await PaperDialog.show<int>(
    context,
    title: UiStrings.lineupActiveActionTitle(character.name),
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          canRetire
              ? UiStrings.lineupActiveActionBody
              : UiStrings.lineupActiveActionBodySwapOnly,
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (canRetire)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PlaqueButton(
              label: UiStrings.lineupActionRetire,
              onTap: () => Navigator.of(context).pop(-1),
            ),
          ),
        for (var j = 0; j < activeIds.length; j++)
          if (j != slotIndex && actives[j] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlaqueButton(
                label: UiStrings.lineupActionSwapWith(
                  UiStrings.lineupSlotLabel(j),
                  actives[j]!.name,
                ),
                onTap: () => Navigator.of(context).pop(j),
              ),
            ),
      ],
    ),
    actions: [
      PlaqueButton(
        label: UiStrings.commonCancel,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
  if (action == null || !context.mounted) return;
  final newIds = List<int>.of(activeIds);
  if (action == -1) {
    newIds.remove(character.id);
  } else {
    final tmp = newIds[slotIndex];
    newIds[slotIndex] = newIds[action];
    newIds[action] = tmp;
  }
  await _applyLineup(context, ref, newIds);
}

// ── 展示组件 ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaUi.gold,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _schoolColor(TechniqueSchool? school) => switch (school) {
  TechniqueSchool.gangMeng => WuxiaColors.gangMeng,
  TechniqueSchool.lingQiao => WuxiaColors.lingQiao,
  TechniqueSchool.yinRou => WuxiaColors.yinRou,
  null => WuxiaColors.textMuted,
};

String _aiTendency(Character c) => c.lineageRole == LineageRole.junior
    ? UiStrings.lineupAiControl
    : UiStrings.lineupAiFocus;

/// 实战装备攻击合计(沿 character_panel 口径:
/// Σ effectiveEquipmentAttack(强化×共鸣×开锋后)。装备未加载帧显 0,加载后刷新)。
class _EquipAttackText extends ConsumerWidget {
  const _EquipAttackText({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(numbersConfigProvider);
    var sum = 0;
    for (final id in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (id == null) continue;
      final eq = ref.watch(equipmentByIdProvider(id)).value;
      if (eq != null) {
        sum += CharacterDerivedStats.effectiveEquipmentAttack(eq, n);
      }
    }
    return Text(
      UiStrings.lineupEquipAttack(sum),
      style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
    );
  }
}

class _ActiveSlotCard extends ConsumerWidget {
  const _ActiveSlotCard({
    required this.character,
    required this.slotIndex,
    required this.activeIds,
    required this.actives,
  });

  final Character character;
  final int slotIndex;
  final List<int> activeIds;
  final List<Character?> actives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inRetreat = character.currentRetreatSessionId != null;
    return InkWell(
      onTap: () => _onActiveTap(
        context,
        ref,
        character: character,
        slotIndex: slotIndex,
        activeIds: activeIds,
        actives: actives,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: 0.94),
          image: const DecorationImage(
            image: AssetImage(WuxiaUi.paperBg),
            fit: BoxFit.cover,
            opacity: 0.12,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: slotIndex == 0
                ? WuxiaUi.gold
                : _schoolColor(character.school).withValues(alpha: 0.58),
            width: slotIndex == 0 ? 1.6 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 9)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  UiStrings.lineupSlotLabel(slotIndex),
                  style: const TextStyle(color: WuxiaUi.muted, fontSize: 10),
                ),
                const SizedBox(width: 6),
                if (slotIndex == 0)
                  const _Tag(UiStrings.lineupFrontRowTag, color: WuxiaUi.gold),
                if (inRetreat) ...[
                  const SizedBox(width: 4),
                  const _Tag(
                    UiStrings.lineupRetreatLockedTag,
                    color: WuxiaColors.internalForce,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PortraitFrame(
                  portraitPath: character.portraitPath,
                  size: 44,
                  borderColor: _schoolColor(character.school),
                  placeholderText: character.name,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoLine(
              EnumL10n.realm(character.realmTier, character.realmLayer),
            ),
            if (character.school != null)
              _InfoLine(
                EnumL10n.school(character.school!),
                color: _schoolColor(character.school),
              ),
            _InfoLine(_aiTendency(character)),
            const Spacer(),
            _EquipAttackText(character: character),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.text, {this.color = WuxiaUi.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              UiStrings.lineupEmptySlotLabel,
              style: TextStyle(color: WuxiaUi.ink, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              UiStrings.lineupEmptySlotHint,
              style: TextStyle(
                color: WuxiaUi.muted.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReserveTile extends ConsumerWidget {
  const _ReserveTile({
    required this.character,
    required this.isWeak,
    required this.activeIds,
    required this.actives,
  });

  final Character character;
  final bool isWeak;
  final List<int> activeIds;
  final List<Character?> actives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inRetreat = character.currentRetreatSessionId != null;
    final noMain = character.mainTechniqueId == null;
    return InkWell(
      onTap: () => _onReserveTap(
        context,
        ref,
        candidate: character,
        activeIds: activeIds,
        actives: actives,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: inRetreat ? 0.56 : 0.92),
          image: const DecorationImage(
            image: AssetImage(WuxiaUi.paperBg),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isWeak
                ? WuxiaColors.statDecrease.withValues(alpha: 0.55)
                : WuxiaColors.border,
          ),
        ),
        child: Row(
          children: [
            PortraitFrame(
              portraitPath: character.portraitPath,
              size: 36,
              borderColor: _schoolColor(character.school),
              placeholderText: character.name,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inRetreat ? WuxiaUi.muted : WuxiaUi.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    character.school == null
                        ? EnumL10n.realm(
                            character.realmTier,
                            character.realmLayer,
                          )
                        : '${EnumL10n.realm(character.realmTier, character.realmLayer)} · ${EnumL10n.school(character.school!)}',
                    style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _aiTendency(character),
                  style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                _EquipAttackText(character: character),
              ],
            ),
            if (isWeak || inRetreat || noMain) const SizedBox(width: 8),
            if (isWeak)
              const _Tag(
                UiStrings.lineupWeakTag,
                color: WuxiaColors.statDecrease,
              ),
            if (noMain) ...[
              if (isWeak) const SizedBox(width: 4),
              const _Tag(
                UiStrings.lineupNoMainTag,
                color: WuxiaColors.textMuted,
              ),
            ],
            if (inRetreat) ...[
              if (isWeak || noMain) const SizedBox(width: 4),
              const _Tag(
                UiStrings.lineupRetreatLockedTag,
                color: WuxiaColors.internalForce,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
