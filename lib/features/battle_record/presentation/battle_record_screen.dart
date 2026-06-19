import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../application/boss_memory_providers.dart';
import '../domain/boss_catalog_entry.dart';
import '../domain/boss_memory.dart';
import '../domain/boss_memory_source.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import 'boss_memory_detail_screen.dart';

/// 战绩册主屏（T8）。
///
/// 将 [bossCatalogProvider]（27 条应有槽）与 [bossMemoryListProvider]（已存纪念）
/// 做 join 后按 source 分两大组渲染：
///   - 有对应 Memory → [_VictoryTile] 已击败纪念卡
///   - 无对应 Memory → [_ShadowTile] 剩影占位（不显 bossName，不剧透）
///
/// 点击纪念卡：T9 BossMemoryDetailScreen 尚未建立，onTap 留 // T9 wire 注释占位。
class BattleRecordScreen extends ConsumerWidget {
  const BattleRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(bossCatalogProvider);
    final memoriesAsync = ref.watch(bossMemoryListProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.battleRecordTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: memoriesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (memories) => _BattleRecordBody(
            catalog: catalog,
            memories: memories,
          ),
        ),
      ),
    );
  }
}

// ── body ────────────────────────────────────────────────────────────────────

class _BattleRecordBody extends StatelessWidget {
  const _BattleRecordBody({
    required this.catalog,
    required this.memories,
  });

  final List<BossCatalogEntry> catalog;
  final List<BossMemory> memories;

  @override
  Widget build(BuildContext context) {
    // join: bossKey → BossMemory
    final memMap = {for (final m in memories) m.bossKey: m};

    // 分两大组，组内按 groupIndex 升序再按 bossKey 升序
    final mainline = catalog
        .where((e) => e.source == BossMemorySource.mainline)
        .toList()
      ..sort((a, b) {
        final cmp = a.groupIndex.compareTo(b.groupIndex);
        return cmp != 0 ? cmp : a.bossKey.compareTo(b.bossKey);
      });
    final tower = catalog
        .where((e) => e.source == BossMemorySource.tower)
        .toList()
      ..sort((a, b) {
        final cmp = a.groupIndex.compareTo(b.groupIndex);
        return cmp != 0 ? cmp : a.bossKey.compareTo(b.bossKey);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _BossGroup(
          title: EnumL10n.bossMemorySource(BossMemorySource.mainline),
          entries: mainline,
          memMap: memMap,
        ),
        const SizedBox(height: 20),
        _BossGroup(
          title: EnumL10n.bossMemorySource(BossMemorySource.tower),
          entries: tower,
          memMap: memMap,
        ),
      ],
    );
  }
}

// ── 分组 ────────────────────────────────────────────────────────────────────

class _BossGroup extends StatelessWidget {
  const _BossGroup({
    required this.title,
    required this.entries,
    required this.memMap,
  });

  final String title;
  final List<BossCatalogEntry> entries;
  final Map<String, BossMemory> memMap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title),
          const SizedBox(height: 4),
          for (final entry in entries) ...[
            IntrinsicHeight(
              child: memMap.containsKey(entry.bossKey)
                  ? _VictoryTile(memory: memMap[entry.bossKey]!)
                  : const _ShadowTile(),
            ),
            if (entry != entries.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── 已击败纪念卡 ─────────────────────────────────────────────────────────────

class _VictoryTile extends StatelessWidget {
  const _VictoryTile({required this.memory});

  final BossMemory memory;

  /// 从 GameRepository 解析立绘路径：
  ///   - 主线 bossKey = stageId → stageDef.enemyTeam.last.iconPath
  ///   - 爬塔 bossKey = tower_floor_N → towerFloors[N-1].enemyTeam.last.iconPath
  static String? _resolvePortrait(String bossKey) {
    // GameRepository 可能在测试环境未初始化，兜底返回 null（立绘走 errorBuilder 纸调兜底）。
    if (!GameRepository.isLoaded) return null;
    final repo = GameRepository.instance;
    if (bossKey.startsWith('tower_floor_')) {
      final floorStr = bossKey.substring('tower_floor_'.length);
      final floor = int.tryParse(floorStr);
      if (floor == null) return null;
      final floors = repo.towerFloors;
      if (floor < 1 || floor > floors.length) return null;
      final team = floors[floor - 1].enemyTeam;
      return team.isNotEmpty ? team.last.iconPath : null;
    } else {
      final def = repo.stageDefs[bossKey];
      if (def == null) return null;
      final team = def.enemyTeam;
      return team.isNotEmpty ? team.last.iconPath : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portraitPath = _resolvePortrait(memory.bossKey);
    final cleared = memory.firstClearedAt;
    final dateStr = cleared != null
        ? '${cleared.year}.${cleared.month}.${cleared.day}'
        : '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BossMemoryDetailScreen(memory: memory),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          border:
              Border.all(color: WuxiaColors.bossFrame.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // 立绘方块（缺图退化纸调兜底）
            _PortraitBox(imagePath: portraitPath),
            const SizedBox(width: 12),
            // Boss 名 + 日期 + 击败次数
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    memory.bossName,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      UiStrings.battleRecordClearedAt(dateStr),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    UiStrings.battleRecordDefeatCount(memory.defeatCount),
                    style: TextStyle(
                      color: WuxiaColors.bossFrame.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 详情箭头
            const Icon(
              Icons.chevron_right,
              color: WuxiaColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 剩影占位（不剧透，不显 bossName）───────────────────────────────────────

class _ShadowTile extends StatelessWidget {
  const _ShadowTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: WuxiaColors.textMuted.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 剪影色块
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: WuxiaColors.textMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white24,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            UiStrings.battleRecordLockedBoss,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 立绘方块 ─────────────────────────────────────────────────────────────────

class _PortraitBox extends StatelessWidget {
  const _PortraitBox({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        imagePath!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.3)),
      ),
    );
  }
}
