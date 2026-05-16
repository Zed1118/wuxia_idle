import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../providers/rng_provider.dart';
import '../application/enhancement_service.dart';
import '../application/equipment_service_providers.dart';
import '../../../ui/effects/screen_shake.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';
import '../../../ui/theme/tier_colors.dart';
import 'forging_panel.dart';

/// 强化对话框（phase2_tasks T29 §426-430 + T32 #22a writeTxn 补漏）。
///
/// 设计：
/// - **cap 硬顶 49**（Pen 拍板）：仓库视角不携带 character，强化能否 +N
///   由 yaml success_curve + 玩家材料决策决定。
/// - 成功反馈：边框金色 + AnimatedScale 弹一下（200ms）。
/// - 失败反馈：共享 screen shake helper。
/// - **writeTxn 持久化**（T32 #22a 销账）：调 service in-place 后委托给
///   [EnhancementService.persistResult] 包 writeTxn —— eq.put / mojianshi row.put /
///   jieJing row.put 全部落地；末尾本 widget invalidate inventory + allEquipments
///   触发 UI 重读。
/// - **结晶 row fail-fast**：InventoryItem(itemType=xinXueJieJing) 行不存在
///   时直接抛 [StateError]——种子阶段必须创建（Phase2SeedService 在主菜单
///   Phase 2 入口预先 writeTxn 写入 mojianshi/jieJing 两行 quantity=0）。
/// - **测试旁路**：widget test 不 init Isar 时 [_persist] 自动 no-op（用
///   [Isar.getInstance] 探测）；真落地验证由 enhancement_persist_test 覆盖。
class EnhanceDialog extends ConsumerStatefulWidget {
  const EnhanceDialog({
    super.key,
    required this.equipment,
    this.def,
    this.initialTab = 0,
  });

  final Equipment equipment;

  /// 装备 def，仅 [ForgingPanel] 槽 3 specialSkill 校验需要。InventoryScreen
  /// 弹窗前查 [GameRepository.getEquipment]；fixture 测试可传 null（forging
  /// tab 仅退化到 specialSkillCandidates=[] 路径）。
  final EquipmentDef? def;

  /// 初始 Tab(0=强化 / 1=开锋)。EquipmentDetailScreen 按钮分流入口用。
  final int initialTab;

  @override
  ConsumerState<EnhanceDialog> createState() => _EnhanceDialogState();
}

class _EnhanceDialogState extends ConsumerState<EnhanceDialog>
    with TickerProviderStateMixin {
  static const int _capHardLimit = 49;

  late final AnimationController _shakeCtrl;
  late final AnimationController _scaleCtrl;
  late final TabController _tabCtrl;
  EnhanceResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _scaleCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _runFeedback(EnhanceResult result) {
    setState(() => _lastResult = result);
    if (result.outcome == EnhanceOutcome.success) {
      _scaleCtrl
        ..reset()
        ..forward();
    } else if (result.outcome == EnhanceOutcome.failure) {
      _shakeCtrl
        ..reset()
        ..forward();
    }
  }

  Future<void> _onEnhance(int mojianshiQty) async {
    final config = ref.read(numbersConfigProvider).enhancement;
    final rng = ref.read(rngProvider);
    final result = EnhancementService.tryEnhance(
      eq: widget.equipment,
      characterAbsoluteLevel: _capHardLimit,
      rng: rng,
      currentMojianshi: mojianshiQty,
      config: config,
    );
    if (result.outcome == EnhanceOutcome.success ||
        result.outcome == EnhanceOutcome.failure) {
      await _persist(result);
    }
    if (!mounted) return;
    _runFeedback(result);
  }

  Future<void> _onGuarantee(int crystalQty) async {
    final config = ref.read(numbersConfigProvider).enhancement;
    final result = EnhancementService.useCrystalToGuarantee(
      eq: widget.equipment,
      characterAbsoluteLevel: _capHardLimit,
      currentCrystals: crystalQty,
      config: config,
    );
    if (result.outcome == EnhanceOutcome.success) {
      await _persist(result);
    }
    if (!mounted) return;
    _runFeedback(result);
  }

  /// T32 #22a：副作用落地 — 委托给 [EnhancementService.persistResult] 做
  /// writeTxn，本方法只负责拿 service + invalidate riverpod provider。
  ///
  /// **测试旁路（Phase 5 W6-S2 重构）**：testWidgets 在 FakeAsync 下不兼容
  /// 真 Isar 异步 IO，widget 测试默认不 init Isar；此处通过
  /// [enhancementServiceProvider] 读 service,Isar 未 init 时 service 为 null,
  /// 短路返回（替代旧的 `Isar.getInstance` 探测）。生产路径永远非空。
  /// Isar 真落地验证由 service 层 test 覆盖
  /// （`test/services/enhancement_persist_test.dart`）。
  Future<void> _persist(EnhanceResult result) async {
    final service = ref.read(enhancementServiceProvider);
    if (service == null) return;
    await service.persistResult(eq: widget.equipment, result: result);
    if (!mounted) return;
    ref.invalidate(inventoryQuantityByTypeProvider(ItemType.moJianShi));
    ref.invalidate(inventoryQuantityByTypeProvider(ItemType.xinXueJieJing));
    ref.invalidate(allEquipmentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final mojianshiAsync = ref.watch(
      inventoryQuantityByTypeProvider(ItemType.moJianShi),
    );
    final crystalAsync = ref.watch(
      inventoryQuantityByTypeProvider(ItemType.xinXueJieJing),
    );

    return Dialog(
      backgroundColor: WuxiaColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: (mojianshiAsync.hasValue && crystalAsync.hasValue)
            ? _buildTabs(
                mojianshiQty: mojianshiAsync.value!,
                crystalQty: crystalAsync.value!,
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }

  Widget _buildTabs({required int mojianshiQty, required int crystalQty}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: WuxiaColors.textPrimary,
          unselectedLabelColor: WuxiaColors.textMuted,
          indicatorColor: WuxiaColors.resultHighlight,
          tabs: const [
            Tab(text: UiStrings.tabEnhance),
            Tab(text: UiStrings.tabForging),
          ],
        ),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildBody(
                  mojianshiQty: mojianshiQty,
                  crystalQty: crystalQty,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: widget.def == null
                    ? const Center(
                        child: Text(
                          UiStrings.dashPlaceholder,
                          style: TextStyle(color: WuxiaColors.textMuted),
                        ),
                      )
                    : ForgingPanel(
                        equipment: widget.equipment,
                        def: widget.def!,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody({required int mojianshiQty, required int crystalQty}) {
    final eq = widget.equipment;
    final config = ref.watch(numbersConfigProvider).enhancement;
    final atCap = eq.enhanceLevel >= _capHardLimit;
    final targetLevel = atCap ? eq.enhanceLevel : eq.enhanceLevel + 1;
    final successRate = atCap ? 0.0 : config.successRateFor(targetLevel);
    final mojianshiCost = atCap ? 0 : config.mojianshiCostFor(targetLevel);
    final crystalCost = atCap
        ? null
        : config.crystalCostToGuarantee(targetLevel);

    final canEnhance = !atCap && mojianshiQty >= mojianshiCost;
    final canGuarantee =
        !atCap && crystalCost != null && crystalQty >= crystalCost;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (ctx, child) {
        return Transform.translate(
          offset: screenShakeOffset(t: _shakeCtrl.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            equipment: eq,
            def: widget.def,
            targetLevel: targetLevel,
            scale: _scaleCtrl,
          ),
          const SizedBox(height: 16),
          _MetricsRow(
            successRate: atCap ? null : successRate,
            mojianshiQty: mojianshiQty,
            mojianshiCost: mojianshiCost,
            crystalQty: crystalQty,
            crystalCost: crystalCost,
          ),
          const SizedBox(height: 12),
          _ResultBanner(result: _lastResult),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (atCap)
                const Text(
                  UiStrings.enhanceCapped,
                  style: TextStyle(color: WuxiaColors.textMuted),
                )
              else ...[
                if (crystalCost != null)
                  TextButton(
                    onPressed: canGuarantee
                        ? () {
                            _onGuarantee(crystalQty);
                          }
                        : null,
                    child: Text(
                      '${UiStrings.guaranteeButton}（${UiStrings.guaranteeCost(crystalCost)}）',
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canEnhance
                      ? () {
                          _onEnhance(mojianshiQty);
                        }
                      : null,
                  child: const Text(UiStrings.enhanceButton),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.equipment,
    required this.targetLevel,
    required this.scale,
    this.def,
  });

  final Equipment equipment;
  final int targetLevel;
  final AnimationController scale;
  final EquipmentDef? def;

  @override
  Widget build(BuildContext context) {
    final tierColor = tierColorForEquipment(equipment.tier);
    return AnimatedBuilder(
      animation: scale,
      builder: (ctx, child) {
        // 弹一下：0 → 1.15 → 1.0（用 Curves 模拟，避免引第三方）
        final t = scale.value;
        final s = 1.0 + math.sin(t * math.pi) * 0.15;
        // 边框 active 时切金色，否则用 tierColor
        final activeBorder = t > 0
            ? Color.lerp(tierColor, WuxiaColors.resultHighlight, t) ?? tierColor
            : tierColor;
        return Transform.scale(
          scale: s,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WuxiaColors.avatarFill,
              border: Border.all(color: activeBorder, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (def != null) ...[
                  Text(
                    def!.name,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  EnumL10n.equipmentSlot(equipment.slot),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EnumL10n.equipmentTier(equipment.tier),
                  style: TextStyle(
                    color: tierColorForEquipment(equipment.tier),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            UiStrings.enhancePreview(equipment.enhanceLevel, targetLevel),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.successRate,
    required this.mojianshiQty,
    required this.mojianshiCost,
    required this.crystalQty,
    required this.crystalCost,
  });

  final double? successRate;
  final int mojianshiQty;
  final int mojianshiCost;
  final int crystalQty;
  final int? crystalCost;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (successRate != null)
          _StatLine(
            label: UiStrings.metricSuccessRate,
            value: UiStrings.percent(successRate!),
          ),
        const SizedBox(height: 4),
        _StatLine(
          label: UiStrings.metricMaterial,
          value: UiStrings.mojianshiUsage(mojianshiQty, mojianshiCost),
          valueColor: mojianshiQty < mojianshiCost ? WuxiaColors.hpLow : null,
        ),
        const SizedBox(height: 4),
        _StatLine(
          label: UiStrings.metricCrystal,
          value: UiStrings.crystalAvailable(crystalQty),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? WuxiaColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final EnhanceResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox(height: 24);
    final r = result!;
    final isSuccess = r.outcome == EnhanceOutcome.success;
    final isFailure = r.outcome == EnhanceOutcome.failure;
    if (!isSuccess && !isFailure) return const SizedBox(height: 24);
    final color = isSuccess ? WuxiaColors.resultHighlight : WuxiaColors.hpLow;
    final label = isSuccess ? UiStrings.successLabel : UiStrings.failureLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (isFailure && r.crystalsGained > 0)
            Text(
              UiStrings.crystalGained(r.crystalsGained),
              style: TextStyle(color: color, fontSize: 13),
            ),
          if (isSuccess)
            Text(
              UiStrings.enhanceLevel(r.newLevel),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
