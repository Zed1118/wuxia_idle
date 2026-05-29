import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../application/seclusion_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'active_retreat_screen.dart';

/// 闭关时长选择屏（Phase 3 T49）。
///
/// 显示地图详情（每小时产出估算 × 境界缩放）+ 三档时长按钮。
/// 点击「开始闭关」：abandon 旧 session（若有）→ startRetreat → push ActiveRetreatScreen。
class SeclusionSetupScreen extends ConsumerStatefulWidget {
  final SeclusionMapDef mapDef;
  final RealmTier charRealmTier;
  final int characterId;
  final RetreatSession? existingActiveSession;

  const SeclusionSetupScreen({
    super.key,
    required this.mapDef,
    required this.charRealmTier,
    required this.characterId,
    this.existingActiveSession,
  });

  @override
  ConsumerState<SeclusionSetupScreen> createState() =>
      _SeclusionSetupScreenState();
}

class _SeclusionSetupScreenState extends ConsumerState<SeclusionSetupScreen> {
  int _selectedHours = 4;
  bool _isStarting = false;

  List<int> get _durations =>
      GameRepository.instance.numbers.retreat.durationHours;

  double get _realmScale =>
      GameRepository.instance.numbers.retreat.realmScaleFor(
        widget.charRealmTier,
      );

  Future<void> _startRetreat() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final svc = ref.read(seclusionServiceProvider);
      if (svc == null) {
        throw StateError('seclusionServiceProvider unavailable (isar null)');
      }
      final session = await svc.startRetreat(
        mapType: widget.mapDef.mapType,
        durationHours: _selectedHours,
        saveDataId: IsarSetup.currentSlotId,
        characterId: widget.characterId,
        charRealmTier: widget.charRealmTier,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );

      if (!mounted) return;
      // setup 用 pushReplacement → active 接管路由槽位。后续 active →
      // pushReplacement(result) → result.pop(true) 经 pushReplacement 链
      // 把 true 传回 list 的 push<bool>(setup) future（Flutter Navigator
      // 旧路由 popped 被 chain 到替换路由的 popped）。setup 不能在此处再
      // pop——会误弹 result 让用户看不到结算页。
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => ActiveRetreatScreen(
            session: session,
            mapDef: widget.mapDef,
            characterId: widget.characterId,
            charRealmTier: widget.charRealmTier,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiStrings.seclusionStartFailed(e))),
      );
      setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.mapDef;
    final scale = _realmScale;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(def.mapName),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 地图产出预览
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WuxiaColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WuxiaColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每小时预估产出（境界加成 ×${scale.toStringAsFixed(2)}）',
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OutputRow(
                      label: UiStrings.seclusionOutputMojianshi,
                      value: (def.mojianshiPerHour * scale).toStringAsFixed(1),
                    ),
                    _OutputRow(
                      label: UiStrings.seclusionOutputExperience,
                      value: (def.experiencePerHour * scale).toStringAsFixed(1),
                    ),
                    if (def.equipmentDropRate > 1.0)
                      const _OutputRow(
                        label: UiStrings.seclusionOutputEquipDrop,
                        value: '+50%',
                      ),
                    if (def.techniqueLearnRate > 1.0)
                      const _OutputRow(
                        label: UiStrings.seclusionOutputTechniqueLearn,
                        value: '+50%',
                      ),
                    if (def.internalForceGrowth > 1.0)
                      const _OutputRow(
                        label: UiStrings.seclusionOutputInternalForce,
                        value: '+50%',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 时长选择
              const Text(
                UiStrings.seclusionSetupTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._durations.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DurationButton(
                    hours: h,
                    selected: _selectedHours == h,
                    scale: scale,
                    mojianshiPerHour: def.mojianshiPerHour,
                    onTap: () => setState(() => _selectedHours = h),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 开始按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _startRetreat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WuxiaColors.gangMeng,
                    foregroundColor: WuxiaColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: WuxiaColors.buttonDisabled,
                  ),
                  child: Text(
                    _isStarting ? '请稍候…' : UiStrings.seclusionSetupStartButton,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  final String label;
  final String value;

  const _OutputRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: WuxiaColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final int hours;
  final bool selected;
  final double scale;
  final double mojianshiPerHour;
  final VoidCallback onTap;

  const _DurationButton({
    required this.hours,
    required this.selected,
    required this.scale,
    required this.mojianshiPerHour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expectedMoji = (mojianshiPerHour * hours * scale).floor();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? WuxiaColors.gangMeng.withValues(alpha: 0.15)
              : WuxiaColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? WuxiaColors.gangMeng : WuxiaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                UiStrings.seclusionDurationLabel(hours),
                style: TextStyle(
                  color: selected
                      ? WuxiaColors.textPrimary
                      : WuxiaColors.textSecondary,
                  fontSize: 15,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '预估磨剑石 ×$expectedMoji',
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
