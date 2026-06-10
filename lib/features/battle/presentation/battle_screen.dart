import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_log.dart';
import '../domain/battle_state.dart';
import '../domain/damage_calculator.dart';
import '../domain/enum_localizations.dart';
import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import '../../../core/application/battle_providers.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/effects/screen_shake.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import 'attack_animation.dart';
import 'battle_atmosphere_overlay.dart';
import 'battle_effect_sprite.dart';
import 'battle_scene_background.dart';
import 'character_avatar.dart';
import 'damage_popup.dart';
import 'hit_flash.dart';
import 'projectile_trail.dart';
import 'ultimate_caption_overlay.dart';
import 'victory_overlay.dart';

/// 单个飘字条目（id + 数据）。
class _PopupEntry {
  final int id;
  final DamagePopupData data;
  const _PopupEntry({required this.id, required this.data});
}

/// 单条弹道（攻击者→目标的笔触线，命令式 spawn，纯表现层）。
/// 坐标用战场比例（0..1），由 [_ProjectileLayer] 在 LayoutBuilder 内解析为像素。
class _TrailEntry {
  final int id;
  final AnimationController ctrl;
  final Offset startFrac;
  final Offset endFrac;
  final Color color;
  final double strokeWidth;
  bool disposed = false;
  _TrailEntry({
    required this.id,
    required this.ctrl,
    required this.startFrac,
    required this.endFrac,
    required this.color,
    required this.strokeWidth,
  });
}

/// 单条 MJ 战斗特效贴片。纯表现层，坐标用战场比例，动画完成后移除。
class _EffectEntry {
  final int id;
  final AnimationController ctrl;
  final Offset centerFrac;
  final String assetPath;
  final double size;
  final double opacity;
  final double rotation;
  final bool mirrored;
  bool disposed = false;

  _EffectEntry({
    required this.id,
    required this.ctrl,
    required this.centerFrac,
    required this.assetPath,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.mirrored,
  });
}

/// 3v3 战斗主屏（phase1_tasks T14 静态布局 + T15 动画/飘字 + T16 Riverpod 串接）。
///
/// **T16 起切换到 [ConsumerStatefulWidget]**：状态来源从外部 `state` 参数改为
/// [battleProvider]。Timer 不再播放预算 actionLog，而是驱动
/// [BattleNotifier.advance]，引擎实时 tick 产生新 action 后由 `ref.listen`
/// 触发动画。结构：
/// - `ref.watch(battleProvider)` 提供子组件渲染数据
/// - `ref.listen` 三类边沿：team 从空 → 非空启动 Timer / actionLog 增长触发
///   动画 + 解除大招置灰 / result 翻转弹结算 dialog
///
/// [animConfig] 默认 [AnimationNumbers.defaults]（与 numbers.yaml 同值）；
/// 测试可注入更短时序加速。
class BattleScreen extends ConsumerStatefulWidget {
  final AnimationNumbers animConfig;

  /// 顶部提示文案（T17 测试场景用）；null 则不显示。
  final String? hint;

  /// 战斗结束关闭 dialog 后的通用回调（T17 返回调试菜单用）；null 则无额外动作。
  final VoidCallback? onBattleEnd;

  /// Phase 3 T37：左队胜（玩家胜）回调；null 走 [onBattleEnd] 兼容旧入口。
  final VoidCallback? onVictory;

  /// Phase 3 T37：左队败 / 平局回调；null 走 [onBattleEnd] 兼容旧入口。
  final VoidCallback? onDefeat;

  /// M4 Stage 3 美术(2026-05-21):战斗屏场景背景 png 路径。
  /// caller 从 StageDef.sceneBackgroundPath / TowerFloorDef.sceneBackgroundPath 注入。
  /// null 或 errorBuilder 触发时降级到 [WuxiaColors.background] 兜底。
  final String? sceneBackgroundPath;

  /// 是否自动启动战斗 tick(opt-in,默认 true 现有调用零影响)。
  /// false 时永不启 Timer,画面冻结在 startBattle 后的 seed 态 ——
  /// 用于静态视觉验收(如 battle_charge_break 截蓄力帧,免被 tick 推进掉)。
  final bool autoStart;

  const BattleScreen({
    super.key,
    this.animConfig = AnimationNumbers.defaults,
    this.hint,
    this.onBattleEnd,
    this.onVictory,
    this.onDefeat,
    this.sceneBackgroundPath,
    this.autoStart = true,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  // 6 个攻击动画 controller（slotKey = teamSide*3 + slotIndex）
  late final List<AnimationController> _attackControllers;

  // 屏震 controller（暴击时触发）
  late final AnimationController _shakeCtrl;

  // 6 个受击闪 controller（slotKey 索引；静止 value=1.0 → 不显，命中 forward(from:0) 淡出）。
  late final List<AnimationController> _hitFlashControllers;
  // 受击闪颜色（slotKey→暴击绛红/普攻白），spawn 时写入，纯 UI state。
  final Map<int, Color> _hitFlashColors = {};

  // 活跃弹道（命令式 spawn，完成后移除）。本地 state，不污染 BattleState。
  final List<_TrailEntry> _activeTrails = [];
  int _nextTrailId = 0;

  // 活跃 MJ 特效贴片（命中/暴击/闪避/流派招式）。
  final List<_EffectEntry> _activeEffects = [];
  int _nextEffectId = 0;

  // 飘字状态：slotKey → 活跃飘字列表
  final Map<int, List<_PopupEntry>> _popups = {};
  int _nextPopupId = 0;

  // 实时 tick 定时器（advance() 驱动）
  Timer? _playTimer;
  bool _isFastForward = false;

  // 大招按钮按下后置灰：char.id ∈ set 时按钮 disabled，下次该角色行动后解除。
  // **本地 state，不污染 BattleState**（spec §16.2 注：UI 状态属于 UI 层）。
  final Set<int> _disabledUltimateChars = {};

  // 日志折叠抽屉开关（P0-2 Task6）：本地 UI state，不污染 BattleState。
  bool _logOpen = false;

  // 战斗结算 dialog 已显示标志，避免 result 字段连续触发多次弹窗
  bool _resultDialogShown = false;

  // B2 大招题字 overlay 的 key(命令式 show)
  final GlobalKey<UltimateCaptionOverlayState> _ultimateCaptionKey =
      GlobalKey<UltimateCaptionOverlayState>();

  // ─── 生命周期 ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _attackControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animConfig.attackTotalMs),
      ),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animConfig.shakeDurationMs),
    );
    _hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        value: 1.0, // 静止满值 → HitFlash alpha=0 不显
        duration: Duration(milliseconds: widget.animConfig.hitFlashMs),
      ),
    );
    // Timer 不在 initState 启动，等 ref.listen 看到 startBattle 完成后再启动。
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    for (final c in _attackControllers) {
      c.dispose();
    }
    for (final c in _hitFlashControllers) {
      c.dispose();
    }
    for (final e in _activeTrails) {
      if (!e.disposed) e.ctrl.dispose();
    }
    for (final e in _activeEffects) {
      if (!e.disposed) e.ctrl.dispose();
    }
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─── Timer / advance 驱动 ────────────────────────────────────────────────

  void _startTimer() {
    _playTimer?.cancel();
    final interval = _isFastForward
        ? widget.animConfig.fastForwardIntervalMs
        : widget.animConfig.actionIntervalMs;
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      ref.read(battleProvider.notifier).advance();
    });
  }

  void _toggleFastForward() {
    setState(() => _isFastForward = !_isFastForward);
    if (_playTimer != null) _startTimer();
  }

  // ─── 动画 / 飘字 ─────────────────────────────────────────────────────────

  void _playAction(BattleAction action, BattleState s) {
    final actor = _findCharacter(action.actorId, s);
    if (actor != null) {
      final key = _slotKey(actor.teamSide, actor.slotIndex);
      _attackControllers[key].forward(from: 0.0);
    }
    if (action.attackResult != null && action.targetId != null) {
      final target = _findCharacter(action.targetId!, s);
      if (target != null) {
        _spawnPopup(target, action.attackResult!, actor);
        if (actor != null) _spawnTrail(actor, target, action);
        _spawnBattleEffects(actor, target, action);
        if (!action.attackResult!.isDodged) {
          _triggerHitFlash(target, action.attackResult!.isCritical);
        }
      }
    }
    if (isUltimateCaptionSkill(action.skill)) {
      _ultimateCaptionKey.currentState?.show(
        action.skill!.name,
        isEnemy: actor?.teamSide == 1,
      );
    }
    // B3 破招:打断蓄力 → 弹「破！」题字(破招方暖金/敌方绛红,纯读 state)。
    if (action.interrupted) {
      _ultimateCaptionKey.currentState?.show(
        UiStrings.interruptCaption,
        isEnemy: actor?.teamSide == 1,
      );
    }
    final sfx = sfxForAction(
      action: action,
      isUltimate: isUltimateCaptionSkill(action.skill),
    );
    if (sfx != null) {
      SoundManager.instance.playSfx(sfx);
    }
  }

  /// 受击闪：命中目标 slot 触发淡出（暴击绛红/普攻白）。纯 UI，不写 state。
  void _triggerHitFlash(BattleCharacter target, bool isCritical) {
    final key = _slotKey(target.teamSide, target.slotIndex);
    setState(() {
      _hitFlashColors[key] = isCritical ? WuxiaColors.gangMeng : Colors.white;
    });
    _hitFlashControllers[key].forward(from: 0.0);
  }

  /// 弹道：攻击者 slot → 目标 slot 的笔触线（流派色；大招更粗）。命令式 spawn。
  void _spawnTrail(
    BattleCharacter actor,
    BattleCharacter target,
    BattleAction action,
  ) {
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animConfig.projectileMs),
    );
    final entry = _TrailEntry(
      id: _nextTrailId++,
      ctrl: ctrl,
      startFrac: _slotFrac(actor.teamSide, actor.slotIndex),
      endFrac: _slotFrac(target.teamSide, target.slotIndex),
      color: WuxiaColors.schoolColor(actor.school),
      strokeWidth: isUltimateCaptionSkill(action.skill) ? 5.0 : 3.0,
    );
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !entry.disposed) {
        entry.disposed = true;
        if (mounted) {
          setState(() => _activeTrails.remove(entry));
        } else {
          _activeTrails.remove(entry);
        }
        // 推迟到当帧末释放，等 AnimatedBuilder 解除监听后再 dispose。
        WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
      }
    });
    setState(() => _activeTrails.add(entry));
    ctrl.forward(from: 0.0);
  }

  void _spawnBattleEffects(
    BattleCharacter? actor,
    BattleCharacter target,
    BattleAction action,
  ) {
    final result = action.attackResult;
    if (result == null) return;
    final targetFrac = _slotFrac(target.teamSide, target.slotIndex);

    if (result.isDodged) {
      _spawnEffect(
        assetPath: WuxiaUi.fxDodgeShadow,
        centerFrac: targetFrac,
        size: 230,
        opacity: 0.64,
        mirrored: target.teamSide == 1,
      );
      return;
    }

    if (actor != null) {
      final isUltimate = isUltimateCaptionSkill(action.skill);
      _spawnEffect(
        assetPath: _schoolFx(actor.school, isUltimate: isUltimate),
        centerFrac: targetFrac,
        size: isUltimate ? 360 : 250,
        opacity: isUltimate ? 0.76 : 0.64,
        rotation: actor.teamSide == 0 ? -0.08 : 0.08,
        mirrored: actor.teamSide == 1,
      );
    }

    if (result.isCritical) {
      _spawnEffect(
        assetPath: WuxiaUi.fxCriticalHit,
        centerFrac: targetFrac,
        size: 220,
        opacity: 0.7,
      );
    }
    if (result.defenseRate >= 0.22) {
      _spawnEffect(
        assetPath: WuxiaUi.fxArmorBreak,
        centerFrac: targetFrac,
        size: 210,
        opacity: 0.58,
      );
    }
    if (result.appliedEffects.contains('internal_injury')) {
      _spawnEffect(
        assetPath: WuxiaUi.fxInternalInjury,
        centerFrac: targetFrac,
        size: 230,
        opacity: 0.62,
      );
    }
  }

  static String _schoolFx(TechniqueSchool school, {required bool isUltimate}) {
    return switch (school) {
      TechniqueSchool.gangMeng =>
        isUltimate ? WuxiaUi.fxGangmengUltimate : WuxiaUi.fxGangmengStrike,
      TechniqueSchool.lingQiao =>
        isUltimate ? WuxiaUi.fxLingqiaoUltimate : WuxiaUi.fxLingqiaoSlash,
      TechniqueSchool.yinRou =>
        isUltimate ? WuxiaUi.fxYinrouUltimate : WuxiaUi.fxYinrouPalm,
    };
  }

  void _spawnEffect({
    required String assetPath,
    required Offset centerFrac,
    required double size,
    required double opacity,
    double rotation = 0,
    bool mirrored = false,
  }) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final entry = _EffectEntry(
      id: _nextEffectId++,
      ctrl: ctrl,
      centerFrac: centerFrac,
      assetPath: assetPath,
      size: size,
      opacity: opacity,
      rotation: rotation,
      mirrored: mirrored,
    );
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !entry.disposed) {
        entry.disposed = true;
        if (mounted) {
          setState(() => _activeEffects.remove(entry));
        } else {
          _activeEffects.remove(entry);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
      }
    });
    setState(() => _activeEffects.add(entry));
    ctrl.forward(from: 0.0);
  }

  void _spawnPopup(
    BattleCharacter target,
    AttackResult result,
    BattleCharacter? attacker,
  ) {
    final key = _slotKey(target.teamSide, target.slotIndex);
    final data = _buildPopupData(result, attacker);
    final entry = _PopupEntry(id: _nextPopupId++, data: data);
    setState(() {
      (_popups[key] ??= []).add(entry);
    });
    if (result.isCritical) {
      _shakeCtrl.forward(from: 0.0);
    }
  }

  DamagePopupData _buildPopupData(
    AttackResult result,
    BattleCharacter? attacker,
  ) {
    if (result.isDodged) {
      return DamagePopupData(
        id: _nextPopupId,
        text: UiStrings.dodge,
        type: PopupType.dodge,
      );
    }
    // P1.1 候选 3-c:仅暴击 + attacker 主修武器 xinJianTongLing → 剑鸣浮字
    final hasSwordSong =
        result.isCritical && (attacker?.swordSongResonanceActive ?? false);
    return DamagePopupData(
      id: _nextPopupId,
      text: result.finalDamage.toString(),
      type: result.isCritical ? PopupType.critical : PopupType.normal,
      hasCounterUp: result.schoolCounterMultiplier > 1.0,
      hasCounterDown: result.schoolCounterMultiplier < 1.0,
      hasSwordSong: hasSwordSong,
    );
  }

  void _removePopup(int slotKey, int popupId) {
    setState(() {
      _popups[slotKey]?.removeWhere((e) => e.id == popupId);
    });
  }

  // ─── 大招 ────────────────────────────────────────────────────────────────

  void _onUltimatePressed(int slotIndex) {
    final s = ref.read(battleProvider);
    if (slotIndex >= s.leftTeam.length) return;
    final c = s.leftTeam[slotIndex];
    final ultimate = _findUltimateOf(c);
    if (!_isUltimateReady(c, ultimate)) return;
    if (_disabledUltimateChars.contains(c.characterId)) return;

    ref.read(battleProvider.notifier).requestUltimate(c.characterId, ultimate!);
    setState(() => _disabledUltimateChars.add(c.characterId));
  }

  static SkillDef? _findUltimateOf(BattleCharacter c) {
    for (final skill in c.availableSkills) {
      if (skill.type == SkillType.ultimate) return skill;
    }
    return null;
  }

  static bool _isUltimateReady(BattleCharacter c, SkillDef? ultimate) {
    if (!c.isAlive || ultimate == null) return false;
    final cd = c.skillCooldowns[ultimate.id] ?? 0;
    return c.currentInternalForce >= ultimate.internalForceCost && cd <= 0;
  }

  // ─── 关键技（破招） ────────────────────────────────────────────────────────

  void _onKeySkillPressed(int slotIndex) {
    final s = ref.read(battleProvider);
    if (slotIndex >= s.leftTeam.length) return;
    final c = s.leftTeam[slotIndex];
    final keySkill = _findKeySkillOf(c);
    if (!_isKeySkillReady(c, keySkill)) return;

    ref.read(battleProvider.notifier).requestUltimate(c.characterId, keySkill!);
  }

  static SkillDef? _findKeySkillOf(BattleCharacter c) {
    for (final skill in c.availableSkills) {
      if (skill.canInterrupt) return skill;
    }
    return null;
  }

  static bool _isKeySkillReady(BattleCharacter c, SkillDef? keySkill) {
    if (!c.isAlive || keySkill == null) return false;
    final cd = c.skillCooldowns[keySkill.id] ?? 0;
    return c.currentInternalForce >= keySkill.internalForceCost && cd <= 0;
  }

  // ─── 结算 dialog ─────────────────────────────────────────────────────────

  void _showResultDialog(BattleResult result, BattleState s) {
    if (_resultDialogShown || !mounted) return;
    _resultDialogShown = true;

    if (result == BattleResult.leftWin) {
      SoundManager.instance.playSfx(SfxId.victory);
    }

    final totalDamage = s.actionLog
        .map((a) => a.attackResult?.finalDamage ?? 0)
        .fold<int>(0, (sum, d) => sum + d);
    final critCount = s.actionLog
        .where((a) => a.attackResult?.isCritical ?? false)
        .length;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // overlay 自带暗幕
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => VictoryOverlay(
        result: result,
        totalDamage: totalDamage,
        critCount: critCount,
        totalTicks: s.tick,
        onContinue: () {
          Navigator.of(ctx).pop();
          widget.onBattleEnd?.call();
          if (result == BattleResult.leftWin) {
            widget.onVictory?.call();
          } else {
            widget.onDefeat?.call();
          }
        },
      ),
      transitionBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────────────

  static int _slotKey(int teamSide, int slotIndex) => teamSide * 3 + slotIndex;

  /// 战场比例坐标（0..1）：左队 x=0.12 / 右队 x=0.88；三行 y=1/6,3/6,5/6。
  /// 弹道层在 LayoutBuilder 内解析为像素，避免依赖 RenderBox（widget test 稳定）。
  static Offset _slotFrac(int teamSide, int slotIndex) {
    final x = teamSide == 0 ? 0.12 : 0.88;
    final y = (slotIndex + 0.5) / 3.0;
    return Offset(x, y);
  }

  BattleCharacter? _findCharacter(int characterId, BattleState s) {
    for (final c in s.leftTeam) {
      if (c.characterId == characterId) return c;
    }
    for (final c in s.rightTeam) {
      if (c.characterId == characterId) return c;
    }
    return null;
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleProvider);
    // 蓄力满值：默认走 numbers.combat.bossCharge.defaultChargeTicks；
    // 若 GameRepository 未初始化（widget test 路径）则回落到 schema 默认 3。
    int chargeMaxTicks;
    try {
      chargeMaxTicks =
          ref.read(numbersConfigProvider).combat.bossCharge.defaultChargeTicks;
    } catch (_) {
      chargeMaxTicks = 3;
    }

    ref.listen<BattleState>(battleProvider, (prev, next) {
      // 1. 启动 Timer：team 从空 → 非空且未结束
      final wasEmpty = prev == null || prev.leftTeam.isEmpty;
      if (widget.autoStart &&
          wasEmpty &&
          next.leftTeam.isNotEmpty &&
          !next.isFinished) {
        _startTimer();
      }

      // 2. 战斗结束：停 timer + 弹结算 dialog（postFrame 避免 build 期 setState）
      if ((prev?.result == null) && next.result != null) {
        _playTimer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResultDialog(next.result!, next);
        });
      }

      // 3. actionLog 新增：触发动画 + 解除大招按钮置灰
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        for (final a in newActions) {
          _playAction(a, next);
        }
        if (_disabledUltimateChars.isNotEmpty) {
          setState(() {
            for (final a in newActions) {
              _disabledUltimateChars.remove(a.actorId);
            }
          });
        }
      }

      // 4. 破招机制 SFX：状态边沿触发（表现层纯读 state，不入 domain）。
      for (final sfx in chargeTransitionSfx(prev, next)) {
        SoundManager.instance.playSfx(sfx);
      }
    });

    // team 空时（startBattle 还未调用）渲染 placeholder
    if (state.leftTeam.isEmpty && state.rightTeam.isEmpty) {
      return const BgmScope(
        track: BgmTrack.battle,
        child: Scaffold(
          backgroundColor: WuxiaColors.background,
          body: Center(
            child: CircularProgressIndicator(color: WuxiaColors.textMuted),
          ),
        ),
      );
    }

    final showLowHealthOverlay = state.rightTeam.any(
      (c) => c.isAlive && c.maxHp > 0 && c.currentHp / c.maxHp <= 0.3,
    );
    final showBossInkCloud = state.rightTeam.any((c) => c.isBoss);

    return BgmScope(
      track: BgmTrack.battle,
      child: Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: BattleSceneBackground(path: widget.sceneBackgroundPath),
          ),
          Positioned.fill(
            child: BattleAtmosphereOverlay(
              showLowHealth: showLowHealthOverlay,
              showInkCloud: showBossInkCloud,
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (ctx, child) {
                return Transform.translate(
                  offset: screenShakeOffset(
                    t: _shakeCtrl.value,
                    amplitude: widget.animConfig.shakeOffsetPx,
                  ),
                  child: child,
                );
              },
              child: Column(
                children: [
                  if (widget.hint != null) _HintBanner(hint: widget.hint!),
                  _Header(
                    state: state,
                    onToggleLog: () => setState(() => _logOpen = !_logOpen),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        _BattleField(
                          state: state,
                          attackControllers: _attackControllers,
                          popups: _popups,
                          animConfig: widget.animConfig,
                          chargeMaxTicks: chargeMaxTicks,
                          onPopupComplete: _removePopup,
                          hitFlashControllers: _hitFlashControllers,
                          hitFlashColors: _hitFlashColors,
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _ProjectileLayer(trails: _activeTrails),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _EffectLayer(effects: _activeEffects),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    state: state,
                    disabledUltimateChars: _disabledUltimateChars,
                    onUltimate: _onUltimatePressed,
                    onKeySkill: _onKeySkillPressed,
                    onFastForward: _toggleFastForward,
                    isFastForward: _isFastForward,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: UltimateCaptionOverlay(key: _ultimateCaptionKey),
          ),
          if (_logOpen)
            _LogDrawer(
              state: state,
              onClose: () => setState(() => _logOpen = false),
            ),
        ],
      ),
      ),
    );
  }
}

// ─── 场景 hint 横幅（T17）─────────────────────────────────────────────────

class _HintBanner extends StatelessWidget {
  final String hint;
  const _HintBanner({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF2A3A2A),
      child: Text(
        hint,
        style: const TextStyle(color: Color(0xFF8BC28B), fontSize: 13),
      ),
    );
  }
}

// ─── 顶栏 ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final BattleState state;
  final VoidCallback onToggleLog;
  const _Header({required this.state, required this.onToggleLog});

  @override
  Widget build(BuildContext context) {
    final aliveLeft = state.leftTeam.where((c) => c.isAlive).length;
    final aliveRight = state.rightTeam.where((c) => c.isAlive).length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        children: [
          Text(
            UiStrings.battleTitle(aliveLeft, aliveRight),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (state.result != null) ...[
            Text(
              EnumL10n.battleResult(state.result!),
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '${UiStrings.tickPrefix} ${state.tick}',
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('battle_log_toggle'),
            icon: const Icon(
              Icons.list_alt,
              color: WuxiaColors.textSecondary,
              size: 20,
            ),
            tooltip: UiStrings.battleLog,
            onPressed: onToggleLog,
          ),
        ],
      ),
    );
  }
}

// ─── 日志折叠抽屉（P0-2 Task6）─────────────────────────────────────────────

/// 战斗日志抽屉：默认收起，点顶栏按钮命令式叠在最外层 Stack 右侧。
/// 实时反馈靠单位飘字/弹道/受击，日志只做事后查阅，不抢第一视觉。
class _LogDrawer extends StatelessWidget {
  final BattleState state;
  final VoidCallback onClose;
  const _LogDrawer({required this.state, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('battle_log_drawer'),
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0x99000000),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // 抽屉内点击不关闭
              child: Container(
                width: 280,
                color: WuxiaColors.sidebar.withValues(alpha: 0.96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: WuxiaColors.panel,
                        border: Border(
                          bottom: BorderSide(color: WuxiaColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            UiStrings.battleLog,
                            style: TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: WuxiaColors.textSecondary,
                              size: 18,
                            ),
                            tooltip: UiStrings.close,
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.actionLog.isEmpty
                          ? const Center(
                              child: Text(
                                UiStrings.emptyLog,
                                style: TextStyle(
                                  color: WuxiaColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              reverse: true,
                              itemCount: state.actionLog.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (_, idx) {
                                final i = state.actionLog.length - 1 - idx;
                                final action = state.actionLog[i];
                                return Text(
                                  BattleLog.formatAction(action, state),
                                  style: const TextStyle(
                                    color: WuxiaColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 战场区域 ──────────────────────────────────────────────────────────────

class _BattleField extends StatelessWidget {
  final BattleState state;
  final List<AnimationController> attackControllers;
  final Map<int, List<_PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final List<AnimationController> hitFlashControllers;
  final Map<int, Color> hitFlashColors;

  const _BattleField({
    required this.state,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _TeamColumn(
              team: state.leftTeam,
              isLeftTeam: true,
              alignment: CrossAxisAlignment.start,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              chargeMaxTicks: chargeMaxTicks,
              onPopupComplete: onPopupComplete,
              hitFlashControllers: hitFlashControllers,
              hitFlashColors: hitFlashColors,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _TeamColumn(
              team: state.rightTeam,
              isLeftTeam: false,
              alignment: CrossAxisAlignment.end,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              chargeMaxTicks: chargeMaxTicks,
              onPopupComplete: onPopupComplete,
              hitFlashControllers: hitFlashControllers,
              hitFlashColors: hitFlashColors,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final List<BattleCharacter> team;
  final bool isLeftTeam;
  final CrossAxisAlignment alignment;
  final List<AnimationController> attackControllers;
  final Map<int, List<_PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final List<AnimationController> hitFlashControllers;
  final Map<int, Color> hitFlashColors;

  const _TeamColumn({
    required this.team,
    required this.isLeftTeam,
    required this.alignment,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
  });

  @override
  Widget build(BuildContext context) {
    final teamSide = isLeftTeam ? 0 : 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: alignment,
      children: [
        for (var i = 0; i < 3; i++)
          // P0-2 fix(2026-06-04 Codex 验收报 RenderFlex overflow 47px @1280×720):
          // 每槽包 Expanded+FittedBox(scaleDown)——大窗保持原尺寸,最小窗自动等比
          // 微缩不再溢出;alignment 锁外缘,头像维持 0.12/0.88 与 projectile 比例坐标对齐。
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isLeftTeam
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: i < team.length
                  ? _CharacterSlot(
                      character: team[i],
                      isLeftTeam: isLeftTeam,
                      attackController: attackControllers[teamSide * 3 + i],
                      slotPopups: popups[teamSide * 3 + i] ?? const [],
                      animConfig: animConfig,
                      chargeMaxTicks: chargeMaxTicks,
                      slotKey: teamSide * 3 + i,
                      onPopupComplete: onPopupComplete,
                      hitFlashController: hitFlashControllers[teamSide * 3 + i],
                      flashColor:
                          hitFlashColors[teamSide * 3 + i] ?? Colors.white,
                    )
                  : const SizedBox(width: 160, height: 80),
            ),
          ),
      ],
    );
  }
}

/// 单个角色槽：攻击动画包 + 头像 + 飘字（Stack 叠加，clipBehavior: none 允许溢出）。
class _CharacterSlot extends StatelessWidget {
  final BattleCharacter character;
  final bool isLeftTeam;
  final AnimationController attackController;
  final List<_PopupEntry> slotPopups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  final int slotKey;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final AnimationController hitFlashController;
  final Color flashColor;

  const _CharacterSlot({
    required this.character,
    required this.isLeftTeam,
    required this.attackController,
    required this.slotPopups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.slotKey,
    required this.onPopupComplete,
    required this.hitFlashController,
    required this.flashColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AttackAnimationWidget(
          animation: attackController,
          isLeftTeam: isLeftTeam,
          config: animConfig,
          child: HitFlash(
            animation: hitFlashController,
            color: flashColor,
            child: CharacterAvatar(
              character: character,
              chargeMaxTicks: chargeMaxTicks,
            ),
          ),
        ),
        for (var i = 0; i < slotPopups.length; i++)
          _buildPopupPositioned(
            i,
            slotPopups[i],
            animConfig,
            slotKey,
            onPopupComplete,
          ),
      ],
    );
  }

  static Widget _buildPopupPositioned(
    int index,
    _PopupEntry entry,
    AnimationNumbers config,
    int slotKey,
    void Function(int, int) onComplete,
  ) {
    return Positioned(
      top: -36.0 - index * 28.0,
      left: 0,
      right: 0,
      child: Center(
        child: DamagePopup(
          key: ValueKey(entry.id),
          data: entry.data,
          config: config,
          onComplete: () => onComplete(slotKey, entry.id),
        ),
      ),
    );
  }
}

// ─── 底栏 ──────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final BattleState state;
  final Set<int> disabledUltimateChars;
  final void Function(int slotIndex) onUltimate;
  final void Function(int slotIndex) onKeySkill;
  final VoidCallback onFastForward;
  final bool isFastForward;

  const _BottomBar({
    required this.state,
    required this.disabledUltimateChars,
    required this.onUltimate,
    required this.onKeySkill,
    required this.onFastForward,
    required this.isFastForward,
  });

  @override
  Widget build(BuildContext context) {
    // 纯读 state：任一存活敌人(rightTeam)正在蓄力 → 全队破招按钮高亮提示。
    final enemyCharging = state.rightTeam.any(
      (e) => e.isAlive && e.chargingSkill != null,
    );
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _UltimateButton(
              character: i < state.leftTeam.length ? state.leftTeam[i] : null,
              disabledByPress:
                  i < state.leftTeam.length &&
                  disabledUltimateChars.contains(state.leftTeam[i].characterId),
              onPressed: () => onUltimate(i),
            ),
            const SizedBox(width: 4),
            _KeySkillButton(
              character: i < state.leftTeam.length ? state.leftTeam[i] : null,
              highlight: enemyCharging,
              onPressed: () => onKeySkill(i),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
          const Spacer(),
          _FastForwardButton(onPressed: onFastForward, isActive: isFastForward),
        ],
      ),
    );
  }
}

/// 关键技（破招）按钮。沿 [_UltimateButton] 体例：取角色 availableSkills 里
/// 首个 canInterrupt 技，ready 判定 = isAlive + 内力够 + CD0。
/// `highlight=true`（任一敌人蓄力中）时换醒目色 + 边框，提示玩家破招时机。
class _KeySkillButton extends StatelessWidget {
  final BattleCharacter? character;
  final bool highlight;
  final VoidCallback onPressed;

  const _KeySkillButton({
    required this.character,
    required this.highlight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = character;
    final keySkill = c == null ? null : _BattleScreenState._findKeySkillOf(c);
    final hasKeySkill = keySkill != null;
    final ready =
        c != null && _BattleScreenState._isKeySkillReady(c, keySkill);

    final Color bgColor;
    if (!hasKeySkill || c == null) {
      bgColor = WuxiaColors.buttonDisabled;
    } else if (highlight) {
      bgColor = WuxiaColors.resultHighlight; // 敌人蓄力中：醒目金
    } else {
      bgColor = WuxiaColors.schoolColor(c.school);
    }

    return SizedBox(
      width: 72,
      height: 52,
      child: ElevatedButton(
        onPressed: ready ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor: WuxiaColors.buttonDisabled,
          foregroundColor: WuxiaColors.textPrimary,
          disabledForegroundColor: WuxiaColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          side: highlight && ready
              ? const BorderSide(color: WuxiaColors.textPrimary, width: 2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (highlight)
              const Icon(Icons.flash_on, size: 16)
            else
              const SizedBox(height: 16),
            const Text(
              UiStrings.battleInterruptSkill,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltimateButton extends StatelessWidget {
  final BattleCharacter? character;
  final bool disabledByPress;
  final VoidCallback onPressed;

  const _UltimateButton({
    required this.character,
    required this.disabledByPress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = character;
    final ultimate = c == null ? null : _BattleScreenState._findUltimateOf(c);
    final ready =
        c != null &&
        _BattleScreenState._isUltimateReady(c, ultimate) &&
        !disabledByPress;

    final activeColor = c == null
        ? WuxiaColors.buttonDisabled
        : WuxiaColors.schoolColor(c.school);

    return SizedBox(
      width: 96,
      height: 52,
      child: ElevatedButton(
        onPressed: ready ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          disabledBackgroundColor: WuxiaColors.buttonDisabled,
          foregroundColor: WuxiaColors.textPrimary,
          disabledForegroundColor: WuxiaColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              UiStrings.ultimate,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (c != null)
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.2),
              ),
          ],
        ),
      ),
    );
  }
}

class _FastForwardButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  const _FastForwardButton({required this.onPressed, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isActive
              ? WuxiaColors.resultHighlight
              : WuxiaColors.textPrimary,
          side: BorderSide(
            color: isActive
                ? WuxiaColors.resultHighlight
                : WuxiaColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          UiStrings.fastForward,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── 弹道层（P0-2 Task7）────────────────────────────────────────────────────

/// 把活跃弹道的战场比例坐标解析为像素并渲染（叠在 _BattleField 上方）。
/// 纯表现层：只读 [_TrailEntry] 几何，由 AnimationController 驱动。
class _ProjectileLayer extends StatelessWidget {
  final List<_TrailEntry> trails;
  const _ProjectileLayer({required this.trails});

  @override
  Widget build(BuildContext context) {
    if (trails.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final t in trails)
              ProjectileTrail(
                key: ValueKey(t.id),
                animation: t.ctrl,
                color: t.color,
                strokeWidth: t.strokeWidth,
                start: Offset(t.startFrac.dx * w, t.startFrac.dy * h),
                end: Offset(t.endFrac.dx * w, t.endFrac.dy * h),
              ),
          ],
        );
      },
    );
  }
}

class _EffectLayer extends StatelessWidget {
  final List<_EffectEntry> effects;
  const _EffectLayer({required this.effects});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final e in effects)
              Positioned(
                left: e.centerFrac.dx * w - e.size / 2,
                top: e.centerFrac.dy * h - e.size / 2,
                width: e.size,
                height: e.size,
                child: BattleEffectSprite(
                  key: ValueKey(e.id),
                  assetPath: e.assetPath,
                  animation: e.ctrl,
                  size: e.size,
                  opacity: e.opacity,
                  rotation: e.rotation,
                  mirrored: e.mirrored,
                ),
              ),
          ],
        );
      },
    );
  }
}
