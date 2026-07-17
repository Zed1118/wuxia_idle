import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_log.dart';
import '../domain/battle_state.dart';
import '../domain/battle_skill_utils.dart';
import '../domain/damage_calculator.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../core/application/battle_providers.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/effects/screen_shake.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../../settings/domain/gameplay_settings.dart';
import 'battle_vfx_entries.dart';
import 'battle_action_template.dart';
import 'battle_stage_geometry.dart';
import 'boss_phase_presentation.dart';
import 'damage_popup.dart';
import 'first_clear_showcase.dart';
import 'impact_glyph_overlay.dart';
import 'impact_profile.dart';
import 'projectile_trail_style.dart';
import 'screen_flash.dart';
import 'ultimate_caption_overlay.dart';
import 'widgets/battle_field.dart';
import 'widgets/battle_vfx_layers.dart';

part 'battle_playback_view.dart';

/// BattleScreen 表现层播放控制器：从 `_BattleScreenState` 抽离的战斗屏动画/播放
/// 编排全体。持有并驱动 —— VFX 反应原语（飘字 / 弹道 / MJ 特效贴片 / 受击闪）、
/// 拍钟调度（beat/timer/hit-stop/pause/fast-forward）、overlay 编排 / 屏震
/// （shake/closeup/overlay keys）、以及 actionLog 边沿的 [playAction] 本体。机制不变：
/// - 不用 `ChangeNotifier`，由 [rebuild]（State 的 `setState`）驱动重绘粒度，
///   与抽离前完全一致的重绘粒度。
/// - `_disposed` 替代 State 的 `mounted` 判断（AnimationController 状态回调场景）。
///
/// State 侧仅保留 build props 透传（读公开 getter）+ 交互分流（暂停/待发/单步）+
/// 生命周期（构造 / dispose）+ 结算 dialog。
class BattlePlaybackController {
  BattlePlaybackController({
    required TickerProvider vsync,
    required WidgetRef ref,
    required void Function(VoidCallback fn) rebuild,
    required AnimationNumbers animConfig,
    // 拍钟调度初值:startPaused 起手即暂停;startFastForward 起手即快进。
    bool startPaused = false,
    bool startFastForward = false,
    bool readablePacing = false,
    bool firstClearShowcase = false,
  }) : _vsync = vsync,
       _ref = ref,
       _rebuild = rebuild,
       _animConfig = animConfig,
       _readablePacing = readablePacing,
       _showcase = firstClearShowcase ? FirstClearShowcaseDirector() : null {
    // 读秒圆环节拍 controller（本拍内 0→1，供 CD/蓄力/破绽环平滑插值）。
    // 随 _playTimer 每拍 forward(from:0) 对齐 remaining 递减，暂停/待发/结束时 stop 冻结。
    _beatCtrl = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: _animConfig.actionIntervalMs),
    );
    // 验收路由 startPaused:起手即暂停 → startTimer 内 _isPaused gate 兜住自动启动。
    if (startPaused) _isPaused = true;
    // 一键扫荡 startFastForward:起手即快进态。
    _isFastForward = startFastForward;
    // 6 个攻击动画 controller（slotKey = teamSide*3 + slotIndex）
    _attackControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: _vsync,
        duration: Duration(milliseconds: _animConfig.attackTotalMs),
      ),
    );
    // 6 个受击闪 controller（slotKey 索引；静止 value=1.0 → 不显，命中 forward(from:0) 淡出）。
    _hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: _vsync,
        value: 1.0, // 静止满值 → HitFlash alpha=0 不显
        duration: Duration(milliseconds: _animConfig.hitFlashMs),
      ),
    );
    // 屏震 controller（暴击时触发）
    _shakeCtrl = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: _animConfig.shakeDurationMs),
    );
    // 命中特写 controller（大招暴击/击杀：缩放脉冲；快进/扫荡/拖招时抑制）。
    _closeupCtrl = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: _animConfig.hitTier.closeupPulseMs),
    );
  }

  final TickerProvider _vsync;
  final WidgetRef _ref;
  final void Function(VoidCallback) _rebuild;
  final AnimationNumbers _animConfig;
  bool _readablePacing;

  /// 首通展示帧导演(null=非首通,整套展示帧不参与)。生产入口(StageEntryFlow)
  /// 的首通判定在 postFrame 异步落定,首帧构造本控制器时恒 false,判定完成后
  /// 经 didUpdateWidget → [setFirstClearShowcase] 补挂,故非 final。
  FirstClearShowcaseDirector? _showcase;
  bool _disposed = false;

  // ─── 拍钟调度字段（beat/timer/hit-stop/pause/fast-forward） ──────────────────
  // 读秒圆环节拍 controller（构造体内据 _animConfig 初始化）。
  late final AnimationController _beatCtrl;
  // 实时 tick 定时器（常速: advanceOneAction() / 快进: advance() 驱动）。
  Timer? _playTimer;
  // hit-stop 复播计时器（命中顿帧后延时重启 timer）。
  Timer? _hitStopTimer;
  bool _isPaused = false;
  bool _isFastForward = false; // 构造时据 startFastForward 置初值

  late final List<AnimationController> _attackControllers;
  late final List<AnimationController> _hitFlashControllers;
  // 受击闪颜色（slotKey→暴击绛红/普攻白），spawn 时写入，纯 UI state。
  final Map<int, Color> _hitFlashColors = {};

  // ─── overlay 编排 / 屏震字段 ────────────────────────────────────────────────
  // 屏震 controller（暴击时触发）
  late final AnimationController _shakeCtrl;

  // 命中特写 controller（大招暴击/击杀：缩放脉冲；快进/扫荡/拖招时抑制）。
  late final AnimationController _closeupCtrl;

  // 批次 2.4 当前重击屏震振幅（profile 分档；0=不抖）。复用既有 _shakeCtrl。
  double _impactShakeAmplitude = 0.0;

  // B2 大招题字 overlay 的 key(命令式 show)
  final GlobalKey<UltimateCaptionOverlayState> _ultimateCaptionKey =
      GlobalKey<UltimateCaptionOverlayState>();

  // 批次 2.4 打击感 overlay key + hit-stop 计时器（命令式触发，纯表现层）。
  final GlobalKey<ImpactGlyphOverlayState> _impactGlyphKey =
      GlobalKey<ImpactGlyphOverlayState>();
  final GlobalKey<ScreenFlashOverlayState> _screenFlashKey =
      GlobalKey<ScreenFlashOverlayState>();

  // 活跃弹道（命令式 spawn，完成后移除）。本地 state，不污染 BattleState。
  final List<TrailEntry> _activeTrails = [];
  int _nextTrailId = 0;

  // 活跃 MJ 特效贴片（命中/暴击/闪避/流派招式）。
  final List<EffectEntry> _activeEffects = [];
  int _nextEffectId = 0;

  // 每个角色槽最近一次动作模板，仅驱动表现层位移。
  final List<BattleActionTemplate> _actionTemplates = List.filled(
    6,
    BattleActionTemplate.melee,
  );

  // 飘字状态：slotKey → 活跃飘字列表
  final Map<int, List<PopupEntry>> _popups = {};
  int _nextPopupId = 0;

  // 拍钟调度只读 getter（供 build props / 交互条件读取）。
  Animation<double> get beat => _beatCtrl;
  bool get isPaused => _isPaused;
  bool get isFastForward => _isFastForward;
  bool get hasTimer => _playTimer?.isActive ?? false;

  @visibleForTesting
  int get playbackIntervalMsForTest => _currentPlaybackIntervalMs;

  @visibleForTesting
  List<PopupEntry> debugPopupsForSlot(int slotKey) =>
      List.unmodifiable(_popups[slotKey] ?? const <PopupEntry>[]);

  @visibleForTesting
  int get debugActiveTrailCount => _activeTrails.length;

  @visibleForTesting
  int get debugActiveEffectCount => _activeEffects.length;

  @visibleForTesting
  bool get debugBeatIsAnimating => _beatCtrl.isAnimating;

  @visibleForTesting
  bool get debugCloseupIsAnimating => _closeupCtrl.isAnimating;

  @visibleForTesting
  void debugApplyHitStop(int ms) => _applyHitStop(ms);

  @visibleForTesting
  BattleActionTemplate debugActionTemplateForSlot(int slotKey) =>
      _actionTemplates[slotKey];

  GameplaySettings get _currentGameplaySettings => _ref
      .read(gameplaySettingsProvider)
      .maybeWhen(data: (s) => s, orElse: () => const GameplaySettings());

  bool get _reduceFlashing => _currentGameplaySettings.reduceFlashing;

  /// 读打击感配置；GameRepository 未初始化（轻量 widget 测）时返 null 跳过。
  ImpactFeedbackConfig? _impactConfigOrNull() {
    if (!GameRepository.isLoaded) return null;
    try {
      return _ref.read(numbersConfigProvider).combat.impactFeedback;
    } catch (e, st) {
      debugPrint(
        'BattlePlaybackController impact config fallback failed: $e\n$st',
      );
      return null;
    }
  }

  /// 当前播放拍间隔(ms):快进态走 fastForwardIntervalMs,否则按玩家速度档缩放
  /// actionIntervalMs(与 [startTimer] 同源口径)。供飘字 spawn 时 clamp 时长,
  /// 防快档(rapid/快进)固定 damagePopupMs 超拍致跨拍重叠。
  int get _currentPlaybackIntervalMs => _isFastForward
      ? _animConfig.fastForwardIntervalMs
      : _readableIntervalMs(
          _currentGameplaySettings.scaledBattleIntervalMs(
            _animConfig.actionIntervalMs,
          ),
        );

  int _readableIntervalMs(int baseMs) {
    if (!_readablePacing) return baseMs;
    return baseMs < _animConfig.readableActionIntervalMs
        ? _animConfig.readableActionIntervalMs
        : baseMs;
  }

  /// 受击闪：命中目标 slot 触发淡出（暴击绛红/普攻白）。纯 UI，不写 state。
  void _triggerHitFlash(BattleCharacter target, bool isCritical) {
    if (_reduceFlashing) return;
    final key = _visualSlotKey(target);
    _rebuild(() {
      _hitFlashColors[key] = isCritical ? WuxiaColors.gangMeng : Colors.white;
    });
    _hitFlashControllers[key].forward(from: 0.0);
  }

  /// 远程弹道：攻击者 slot → 目标 slot 的水墨笔触；近战不生成此层。
  void _spawnTrail(
    BattleCharacter actor,
    BattleCharacter target,
    BattleAction action,
  ) {
    final ctrl = AnimationController(
      vsync: _vsync,
      duration: Duration(
        milliseconds: _isFastForward
            ? math.min(_animConfig.projectileMs, _currentPlaybackIntervalMs)
            : _animConfig.projectileMs,
      ),
    );
    final entry = TrailEntry(
      id: _nextTrailId++,
      ctrl: ctrl,
      startFrac: _slotFrac(
        actor.teamSide,
        actor.slotIndex,
        _teamSizeOf(actor.teamSide),
      ),
      endFrac: _slotFrac(
        target.teamSide,
        target.slotIndex,
        _teamSizeOf(target.teamSide),
      ),
      color: WuxiaColors.schoolColor(actor.school),
      strokeWidth: _trailStrokeWidth(action),
      style: _trailStyle(action),
    );
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !entry.disposed) {
        entry.disposed = true;
        if (!_disposed) {
          _rebuild(() => _activeTrails.remove(entry));
        } else {
          _activeTrails.remove(entry);
        }
        // 推迟到当帧末释放，等 AnimatedBuilder 解除监听后再 dispose。
        WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
      }
    });
    _rebuild(() => _activeTrails.add(entry));
    ctrl.forward(from: 0.0);
  }

  ProjectileTrailStyle _trailStyle(BattleAction action) {
    final skill = action.skill;
    if (skill == null || skill.type == SkillType.normalAttack) {
      return ProjectileTrailStyle.normal;
    }
    return ProjectileTrailStyle.skill;
  }

  double _trailStrokeWidth(BattleAction action) {
    if (isUltimateCaptionSkill(action.skill)) return 16.0;
    return _trailStyle(action) == ProjectileTrailStyle.skill ? 12.8 : 9.2;
  }

  void _spawnBattleEffects(
    BattleCharacter? actor,
    BattleCharacter target,
    BattleAction action,
    BattleActionTemplate actionTemplate, {
    bool includeSchoolEffect = true,
  }) {
    final result = action.attackResult;
    if (result == null) return;
    final targetFrac = _slotFrac(
      target.teamSide,
      target.slotIndex,
      _teamSizeOf(target.teamSide),
    );
    final effectFrac = actionTemplate == BattleActionTemplate.area
        ? Offset(target.teamSide == 0 ? 0.28 : 0.72, 0.5)
        : targetFrac;
    final coalesceGroup = (
      tick: action.tick,
      actorId: action.actorId,
      skillId: action.skill?.id,
    );

    if (result.isDodged) {
      _spawnEffect(
        coalesceGroup: coalesceGroup,
        assetPath: WuxiaUi.fxDodgeShadow,
        centerFrac: effectFrac,
        size: 230,
        opacity: 0.64,
        mirrored: target.teamSide == 1,
      );
      return;
    }

    if (actor != null && includeSchoolEffect) {
      final isUltimate = isUltimateCaptionSkill(action.skill);
      _spawnEffect(
        coalesceGroup: coalesceGroup,
        assetPath: _schoolFx(actor.school, isUltimate: isUltimate),
        centerFrac: effectFrac,
        size: isUltimate ? 330 : 220,
        opacity: isUltimate ? 0.68 : 0.52,
        rotation: actor.teamSide == 0 ? -0.08 : 0.08,
        mirrored: actor.teamSide == 1,
      );
    }

    if (result.isCritical) {
      _spawnEffect(
        coalesceGroup: coalesceGroup,
        assetPath: WuxiaUi.fxCriticalHit,
        centerFrac: targetFrac,
        size: 220,
        opacity: 0.7,
      );
    }
    if (result.defenseRate >= 0.22) {
      _spawnEffect(
        coalesceGroup: coalesceGroup,
        assetPath: WuxiaUi.fxArmorBreak,
        centerFrac: targetFrac,
        size: 210,
        opacity: 0.58,
      );
    }
    if (result.appliedEffects.contains('internal_injury')) {
      _spawnEffect(
        coalesceGroup: coalesceGroup,
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
    required Object coalesceGroup,
    required String assetPath,
    required Offset centerFrac,
    required double size,
    required double opacity,
    double rotation = 0,
    bool mirrored = false,
  }) {
    for (final active in _activeEffects) {
      if (!active.disposed &&
          active.coalesceGroup == coalesceGroup &&
          active.assetPath == assetPath &&
          active.centerFrac == centerFrac &&
          active.size == size &&
          active.opacity == opacity &&
          active.rotation == rotation &&
          active.mirrored == mirrored) {
        active.ctrl.forward(from: 0.0);
        return;
      }
    }
    final ctrl = AnimationController(
      vsync: _vsync,
      duration: Duration(
        milliseconds: _isFastForward
            ? math.min(520, _currentPlaybackIntervalMs)
            : 520,
      ),
    );
    final entry = EffectEntry(
      id: _nextEffectId++,
      ctrl: ctrl,
      coalesceGroup: coalesceGroup,
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
        if (!_disposed) {
          _rebuild(() => _activeEffects.remove(entry));
        } else {
          _activeEffects.remove(entry);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
      }
    });
    _rebuild(() => _activeEffects.add(entry));
    ctrl.forward(from: 0.0);
  }

  /// 飘字：命中目标 slot spawn 一条飘字（伤害数字/闪避/暴击样式）。飘字时长按
  /// [_currentPlaybackIntervalMs] clamp，防快档（rapid/快进）固定 damagePopupMs
  /// 超拍致跨拍重叠。
  void _spawnPopup(
    BattleCharacter target,
    AttackResult result,
    BattleCharacter? attacker,
  ) {
    final key = _visualSlotKey(target);
    final data = _buildPopupData(result, attacker);
    final anchor = _nextPopupAnchor(key, data.type);
    final entry = PopupEntry(
      id: _nextPopupId++,
      data: data,
      anchor: anchor,
      popupDurationMs: _animConfig.effectivePopupMs(_currentPlaybackIntervalMs),
    );
    _rebuild(() {
      (_popups[key] ??= []).add(entry);
    });
    // 屏震触发已上移至 [playAction]（批次 2.4 分档屏震集中触发）。
  }

  DamagePopupAnchor _nextPopupAnchor(int slotKey, PopupType type) {
    final existing = _popups[slotKey] ?? const <PopupEntry>[];
    if (type == PopupType.critical &&
        !existing.any(
          (entry) => entry.anchor == DamagePopupAnchor.centerBurst,
        )) {
      return DamagePopupAnchor.centerBurst;
    }
    const spread = [
      DamagePopupAnchor.upperRight,
      DamagePopupAnchor.upperLeft,
      DamagePopupAnchor.lowerRight,
      DamagePopupAnchor.lowerLeft,
    ];
    final spreadCount = existing
        .where((entry) => entry.anchor != DamagePopupAnchor.centerBurst)
        .length;
    return spread[spreadCount % spread.length];
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
      text: result.isCritical
          ? UiStrings.criticalDamagePopup(result.finalDamage)
          : result.finalDamage.toString(),
      type: result.isCritical ? PopupType.critical : PopupType.normal,
      hasCounterUp: result.schoolCounterMultiplier > 1.0,
      hasCounterDown: result.schoolCounterMultiplier < 1.0,
      hasSwordSong: hasSwordSong,
    );
  }

  void removePopup(int slotKey, int popupId) {
    _rebuild(() {
      _popups[slotKey]?.removeWhere((e) => e.id == popupId);
    });
  }

  /// 战场比例坐标（0..1）：与人物舞台共用斜向阵列锚点。
  /// 弹道层在 LayoutBuilder 内解析为像素，避免依赖 RenderBox（widget test 稳定）。
  static Offset _slotFrac(int teamSide, int slotIndex, int teamSize) {
    return battleStageAnchor(teamSide, slotIndex, teamSize);
  }

  /// 取某队当前人数(供 [_slotFrac] 竖直均分)。死亡单位保留在队列(灰显)故长度稳定。
  int _teamSizeOf(int teamSide) {
    final s = _ref.read(battleProvider);
    return teamSide == 0 ? s.leftTeam.length : s.rightTeam.length;
  }

  // ─── 拍钟调度 ───────────────────────────────────────────────────────────────

  void startTimer() {
    // 任何显式启动都作废挂起的 hit-stop 复播（避免快进/暂停切换撞 hit-stop 时
    // stale timer 二次 startTimer 致节拍抖动）。
    _hitStopTimer?.cancel();
    _playTimer?.cancel();
    if (_isPaused) {
      _beatCtrl.stop(); // 暂停态冻结读秒环节拍在当前扫位。
      return; // H3 暂停态:任何重启请求都不启动 timer。
    }
    // 首通展示帧·开局亮相:首次起手先题字+停顿,停顿结束再真正起拍。快进态
    // 消费不呈现(复刷/扫荡不叠慢镜);停顿只延迟第一拍,拖招层已在场不阻塞
    // 出手;只动播放节拍不碰结算(守 §5.5)。复用 _hitStopTimer 槽位(顶部已
    // 统一 cancel,与 hit-stop 复播互斥无叠加)。
    if ((_showcase?.consumeOpening() ?? false) && !_isFastForward) {
      _showOpeningCaption();
      _hitStopTimer = Timer(
        Duration(milliseconds: _animConfig.firstClearOpeningHoldMs),
        () {
          if (!_disposed && !_ref.read(battleProvider).isFinished) {
            startTimer();
          }
        },
      );
      return;
    }
    // 快进态:玩家手动开了快进。
    final rushing = _isFastForward;
    final gameplaySettings = _currentGameplaySettings;
    final interval = rushing
        ? _animConfig.fastForwardIntervalMs
        : _readableIntervalMs(
            gameplaySettings.scaledBattleIntervalMs(
              _animConfig.actionIntervalMs,
            ),
          );
    // 读秒环节拍:与每拍对齐（本拍内 0→1，供环平滑插值）。起手先扫第一拍，
    // 之后每次 advance 回调里 forward(from:0) 重启，使 remaining 递减与环无缝续扫。
    _beatCtrl
      ..duration = Duration(milliseconds: interval)
      ..forward(from: 0);
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (_disposed) return;
      _beatCtrl.forward(from: 0);
      final notifier = _ref.read(battleProvider.notifier);
      if (rushing) {
        notifier.advance();
      } else {
        notifier.advanceOneAction();
      }
    });
  }

  void toggleFastForward() {
    _rebuild(() => _isFastForward = !_isFastForward);
    if (_playTimer != null) startTimer();
  }

  void setReadablePacing(bool value) {
    if (_readablePacing == value) return;
    _readablePacing = value;
    if (_playTimer != null) startTimer();
  }

  /// 首通展示帧开关(与 [setReadablePacing] 同源:生产入口异步首通判定的透传口)。
  /// 只允许在起拍前武装——拍钟与开局停顿计时器都未启动;开播后翻 true 忽略,
  /// 防止中途补挂令「开局亮相」迟到错拍。翻 false 随时生效(卸下导演即不再呈现)。
  void setFirstClearShowcase(bool value) {
    if (value == (_showcase != null)) return;
    if (!value) {
      _showcase = null;
      return;
    }
    if (_playTimer != null || _hitStopTimer != null) return;
    _showcase = FirstClearShowcaseDirector();
  }

  /// H3 暂停:停 tick(startTimer 内 _isPaused gate 兜住所有重启路径)、冻结读秒环。
  void pause() {
    _rebuild(() => _isPaused = true);
    _playTimer?.cancel();
    _beatCtrl.stop();
  }

  /// 恢复:解除暂停,战斗未结束则重启自动播放。
  void resume() {
    _rebuild(() => _isPaused = false);
    if (!_ref.read(battleProvider).isFinished) startTimer();
  }

  /// 战斗结束边沿:停 timer + 冻结读秒环节拍（结算 dialog 由 State 侧 postFrame 弹）。
  void onBattleFinished() {
    _playTimer?.cancel();
    _beatCtrl.stop();
  }

  /// 同一个 BattleScreen 承接下一场时清理上一场全部瞬时表现。
  /// 保留暂停/快进/可读节奏等玩家偏好，不触碰 BattleState。
  void onBattleRestarted() {
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _beatCtrl.stop();

    for (final entry in _activeTrails) {
      if (!entry.disposed) {
        entry.disposed = true;
        entry.ctrl.stop();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => entry.ctrl.dispose(),
        );
      }
    }
    for (final entry in _activeEffects) {
      if (!entry.disposed) {
        entry.disposed = true;
        entry.ctrl.stop();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => entry.ctrl.dispose(),
        );
      }
    }
    _rebuild(() {
      _activeTrails.clear();
      _activeEffects.clear();
      _popups.clear();
      for (var i = 0; i < _actionTemplates.length; i++) {
        _actionTemplates[i] = BattleActionTemplate.melee;
      }
      _impactShakeAmplitude = 0.0;
    });
    _nextTrailId = 0;
    _nextEffectId = 0;
    _nextPopupId = 0;

    for (final controller in _attackControllers) {
      controller.reset();
    }
    for (final controller in _hitFlashControllers) {
      controller.value = 1.0;
    }
    _shakeCtrl.reset();
    _closeupCtrl.reset();
    _impactGlyphKey.currentState?.clear();
    _ultimateCaptionKey.currentState?.clear();
    _screenFlashKey.currentState?.clear();

    if (_showcase != null) _showcase = FirstClearShowcaseDirector();
  }

  /// 玩法设置变更边沿:若 timer 在跑且战斗未结束 → 重启以应用新速度。
  void onGameplaySettingsChanged() {
    if (_playTimer != null && !_ref.read(battleProvider).isFinished) {
      startTimer();
    }
  }

  /// hit-stop：命中瞬间停播放 Timer，延后 [ms] 后复播。只动屏上播放节拍
  /// （advance 结算确定不变，守 §5.5）；startTimer 内 _isPaused gate 兜住，
  /// 暂停态不会被复活。
  void _applyHitStop(int ms) {
    if (_isPaused) return;
    _playTimer?.cancel();
    _beatCtrl.stop();
    _hitStopTimer?.cancel();
    _hitStopTimer = Timer(Duration(milliseconds: ms), () {
      if (!_disposed && !_ref.read(battleProvider).isFinished) startTimer();
    });
  }

  /// 第七阶段批二 ① Boss 转阶段表现层：题字（短标题，未知 key 走 EnumL10n
  /// 兜底）+ 全屏闪白 + Boss 立绘抖动。复用 2.4 的 glyph / flash / shake 通道，
  /// 不另起平行系统。纯读 action 元数据，不写 BattleState（守 §5.4）；后台挂机
  /// 不进此屏播放路径（守 §5.5）。
  ///
  void _playBossPhaseTransition(BattleAction action, BattleCharacter? actor) {
    if (action.bossPhaseTransitionTo == null) return;
    final bossName = actor?.name ?? '';
    final title = bossPhaseTitleFor(action, bossName);
    if (title == null) return;
    final isEnemy = actor?.teamSide == 1;
    // 题字（多字 caption overlay，承载 4 字转阶段标题；单字 glyph 会裁切多字）。
    // 不触发 hit-stop：转阶段非打击命中，暂停 timer 无意义。
    // 抢占中央焦点:触发转阶段的那一击若同 tick 弹了击杀「斩」字形,两套居中题字会
    // 叠字(同破界 WARN 的同类现象);先清掉 in-flight 击杀字形,让转阶段题字独占中央。
    _impactGlyphKey.currentState?.clear();
    _ultimateCaptionKey.currentState?.show(title, isEnemy: isEnemy);
    // 闪白 + 立绘抖动复用 2.4 heavy 档参数（转阶段是重场面）。GameRepository 未
    // 初始化（轻量 widget 测）时 cfg==null，仍保证题字触发、闪白/抖动跳过。
    final cfg = _impactConfigOrNull();
    if (cfg != null) {
      if (!_reduceFlashing) {
        _screenFlashKey.currentState?.flash(
          cfg.heavy.flashStrength,
          color: WuxiaColors.gangMeng,
        );
      }
      // 抖动同 2.4：快进态跳过（保顺滑）。
      if (!_isFastForward) {
        _impactShakeAmplitude = cfg.heavy.shakeMagnitude;
        _shakeCtrl.forward(from: 0.0);
      }
    }
  }

  /// 首通展示帧·开局亮相题字。empty→非空边沿的同帧,战斗 body(含题字
  /// overlay)可能尚未挂载 → currentState 为 null 时推迟一帧兜底。
  void _showOpeningCaption() {
    final st = _ultimateCaptionKey.currentState;
    if (st != null) {
      st.show(UiStrings.firstClearOpening, isEnemy: false);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _ultimateCaptionKey.currentState?.show(
          UiStrings.firstClearOpening,
          isEnemy: false,
        );
      }
    });
  }

  /// 首通展示帧·敌方首次蓄力提示:state 边沿(敌方 chargingSkill null→非null)
  /// 整场一次 → 教学题字+停顿(让玩家看清「可拖技能破招」时机)。PUBLIC:由
  /// build 内 `ref.listen` 逐 state 转发;非首通 no-op;快进态消费不呈现。
  /// 纯读 state,不写 BattleState(守 §5.4)。
  void onShowcaseStateTransition(BattleState? prev, BattleState next) {
    final d = _showcase;
    if (d == null) return;
    if (!d.consumeEnemyChargeCue(prev, next)) return;
    if (_isFastForward) return;
    _impactGlyphKey.currentState?.clear();
    _ultimateCaptionKey.currentState?.show(
      UiStrings.firstClearChargeCue,
      isEnemy: true,
    );
    _applyHitStop(_animConfig.firstClearBossChargeHoldMs);
  }

  /// floor30 护法结界（Task 6）破界演出：结界失效边沿（最后一名护法阵亡）
  /// → 题字 + 闪白。复用 [playBossPhaseTransition] 同一套题字 / 闪白通道
  /// （[_ultimateCaptionKey] + [_screenFlashKey]），不另起平行系统；不触发
  /// hit-stop / 抖动（非打击命中，护法之死已由其自身死亡动画表现）。
  /// 纯读 [boss] 元数据，不写 BattleState（守 §5.4）。
  ///
  /// PUBLIC：由 build 内 `ref.listen` 的护法结界破界边沿调用。
  void playGuardianWardBreak(BattleCharacter boss) {
    final isEnemy = boss.teamSide == 1;
    // 破界题字抢占中央焦点:最后一击击杀护法的「斩」字形与「结界破!」同 tick 触发,
    // 两套居中题字会叠字(2026-07-02 目检 WARN)。先清掉 in-flight 击杀字形,
    // 让「结界破!」独占中央,直达干净帧。
    _impactGlyphKey.currentState?.clear();
    _ultimateCaptionKey.currentState?.show(
      UiStrings.guardianWardBroken,
      isEnemy: isEnemy,
    );
    if (_reduceFlashing) return;
    final cfg = _impactConfigOrNull();
    if (cfg == null) return;
    _screenFlashKey.currentState?.flash(
      cfg.heavy.flashStrength,
      color: WuxiaColors.internalForce,
    );
  }

  /// actionLog 新增边沿:批量触发本屏表现层反应。同 tick/施放者/
  /// 招式的连续 AOE 动作共享一次人物动画、流派特效、题字与 SFX；伤害飘字、
  /// 受击闪及目标状态特效仍逐条保留。纯读 [actions] + [s] 元数据，不写
  /// BattleState（守 §5.4）。State 侧 build 内 `ref.listen` 批量转发。
  void playActions(List<BattleAction> actions, BattleState s) {
    var index = 0;
    while (index < actions.length) {
      final first = actions[index];
      if (!_isAoeHit(first)) {
        playAction(first, s);
        index++;
        continue;
      }

      var end = index + 1;
      while (end < actions.length && _sameAoeCast(first, actions[end])) {
        end++;
      }
      final cast = actions.sublist(index, end);
      final representative = _representativeAoeAction(cast);
      final castDefeatedTarget = cast.any((action) => action.defeatedTarget);
      for (final action in cast) {
        final isRepresentative = identical(action, representative);
        _playAction(
          action,
          s,
          playSharedFeedback: isRepresentative,
          sharedCastDefeatedTarget: isRepresentative && castDefeatedTarget,
        );
      }
      index = end;
    }
  }

  bool _isAoeHit(BattleAction action) =>
      action.skill?.targetType == TargetType.aoe &&
      action.attackResult != null &&
      action.targetId != null;

  bool _sameAoeCast(BattleAction first, BattleAction candidate) =>
      _isAoeHit(candidate) &&
      candidate.tick == first.tick &&
      candidate.actorId == first.actorId &&
      candidate.skill?.id == first.skill?.id;

  BattleAction _representativeAoeAction(List<BattleAction> cast) {
    var representative = cast.first;
    var bestScore = _sharedFeedbackScore(representative);
    for (final action in cast.skip(1)) {
      final score = _sharedFeedbackScore(action);
      if (score > bestScore) {
        representative = action;
        bestScore = score;
      }
    }
    return representative;
  }

  int _sharedFeedbackScore(BattleAction action) {
    var score = action.attackResult?.isDodged == false ? 10 : 0;
    if (action.attackResult?.isCritical ?? false) score += 20;
    if (action.openedBreakWindow) score += 40;
    if (action.weaknessHit) score += 60;
    if (action.interrupted) score += 80;
    return score;
  }

  void playAction(BattleAction action, BattleState s) =>
      _playAction(action, s, playSharedFeedback: true);

  void _playAction(
    BattleAction action,
    BattleState s, {
    required bool playSharedFeedback,
    bool sharedCastDefeatedTarget = false,
  }) {
    final actor = findCharacter(action.actorId, s);
    final actionTemplate = battleActionTemplateFor(action.skill);
    // 首通展示帧:本动作触发的节拍(null=无);「首次」判定在 director 内消费,
    // 快进态消费不呈现(下方各触发点带 !_isFastForward gate)。
    final showcaseBeat = playSharedFeedback
        ? _showcase?.onAction(action, s)
        : null;
    if (actor != null && playSharedFeedback) {
      final key = _visualSlotKey(actor);
      _actionTemplates[key] = actionTemplate;
      _attackControllers[key].forward(from: 0.0);
    }
    if (action.attackResult != null && action.targetId != null) {
      final target = findCharacter(action.targetId!, s);
      if (target != null) {
        _spawnPopup(target, action.attackResult!, actor);
        if (playSharedFeedback &&
            actor != null &&
            templateUsesProjectile(actionTemplate)) {
          _spawnTrail(actor, target, action);
        }
        _spawnBattleEffects(
          actor,
          target,
          action,
          actionTemplate,
          includeSchoolEffect: playSharedFeedback,
        );
        if (!action.attackResult!.isDodged) {
          _triggerHitFlash(target, action.attackResult!.isCritical);
        }
      }
    }
    if (!playSharedFeedback) return;
    if (isUltimateCaptionSkill(action.skill)) {
      final climax = hitClimaxFor(action);
      final isCrit = action.attackResult?.isCritical ?? false;
      _ultimateCaptionKey.currentState?.show(
        action.skill!.name,
        isEnemy: actor?.teamSide == 1,
        fontSize: climax == HitClimax.ultimateCrit
            ? _animConfig.hitTier.captionPeakSize.toDouble()
            : 56,
        glowBlur: isCrit ? _animConfig.hitTier.captionGlowBlur : 0,
      );
    }
    // B3 破招:打断蓄力 → 弹「破！」题字(破招方暖金/敌方绛红,纯读 state)。
    // 首通首次破招(interruptFlourish)升峰值字号+辉光+闪白,强化教学仪式感。
    if (action.interrupted) {
      final flourish = showcaseBeat == ShowcaseBeat.interruptFlourish;
      _ultimateCaptionKey.currentState?.show(
        UiStrings.interruptCaption,
        isEnemy: actor?.teamSide == 1,
        fontSize: flourish
            ? _animConfig.hitTier.captionPeakSize.toDouble()
            : 56,
        glowBlur: flourish ? _animConfig.hitTier.captionGlowBlur : 0,
      );
      if (flourish && !_isFastForward && !_reduceFlashing) {
        final flourishCfg = _impactConfigOrNull();
        if (flourishCfg != null) {
          _screenFlashKey.currentState?.flash(
            flourishCfg.heavy.flashStrength,
            color: WuxiaColors.internalForce,
          );
        }
      }
    }
    final sfx = sfxForAction(
      action: action,
      isUltimate: isUltimateCaptionSkill(action.skill),
    );
    if (sfx != null && !_isFastForward) {
      // 平A 按出手单位放固定变体音色（我方轻击系/敌方重击系）；其余槽位单文件。
      if (sfx == SfxId.battleHit && actor != null) {
        SoundManager.instance.playSfxPath(
          battleHitAssetPath(
            teamSide: actor.teamSide,
            slotIndex: actor.slotIndex,
          ),
        );
      } else {
        SoundManager.instance.playSfx(sfx);
      }
    }
    // ── 第七阶段批二 ① Boss 转阶段表现层（题字 + 闪白 + 立绘抖动）。 ──
    // 转阶段动作无 attackResult，上面 2.4 重击路径对其天然 no-op；此处独立触发。
    // 纯读 action 元数据，不写 BattleState、不参与结算（守 §5.4）。
    _playBossPhaseTransition(action, actor);

    // ── 第七阶段批二 ② 会心题字（命中守方弱点流派）。纯读 action 元数据，不写
    //    BattleState、不参与结算（守 §5.4）。「会心」2 字适配单字 glyph overlay。
    //    优先级：本帧若同时有 profile 单字（斩/震/断）也只弹会心一字，避免两 glyph
    //    同帧叠播（会心更能传达「打中弱点」语义）；flash/shake 仍由下方 profile 路径
    //    照常触发。无 profile 的普攻弱点命中也能弹（下方块 no-op，此处兜底）。
    final weaknessGlyphShown = action.weaknessHit;
    if (weaknessGlyphShown) {
      _impactGlyphKey.currentState?.show(
        UiStrings.weaknessHitGlyph,
        isEnemy: actor?.teamSide == 1,
      );
    }

    // ── 批次 2.4 打击感表现层（重击分级）。纯表现层，不写 state。 ──
    final cfg = _impactConfigOrNull();
    if (cfg != null) {
      final profile = impactProfileFor(action, cfg);
      if (profile != null) {
        final isEnemy = actor?.teamSide == 1;
        // 会心已占用本帧 glyph 通道 → profile 单字跳过，不双弹（flash/shake 照常）。
        if (profile.glyph != null && !weaknessGlyphShown) {
          _impactGlyphKey.currentState?.show(profile.glyph!, isEnemy: isEnemy);
        }
        if (!_reduceFlashing) {
          _screenFlashKey.currentState?.flash(
            profile.flashStrength,
            // profile 非空 ⇒ attackResult 非空（见 impactProfileFor 的 null 契约）。
            color: action.attackResult!.isCritical
                ? WuxiaColors.gangMeng
                : Colors.white,
          );
        }
        // hit-stop + 镜头震：快进态跳过（守 2.3 时序 + 保快进顺滑）。
        if (!_isFastForward) {
          _impactShakeAmplitude = profile.shakeMagnitude;
          _shakeCtrl.forward(from: 0.0);
          _applyHitStop(
            playbackHoldMs(
              isKey:
                  sharedCastDefeatedTarget || BattleLog.isKeyAction(action, s),
              profileHitStopMs: profile.hitStopMs,
              keyMomentHoldMs: _animConfig.keyMomentHoldMs,
            ),
          );
        }
      }
    }

    // 命中特写：仅峰值（大招暴击/击杀），快进/扫荡抑制（守在线=离线）。
    // 独立于 profile != null 块：普攻击杀无 profile 也须触发特写。
    if (!_isFastForward &&
        (sharedCastDefeatedTarget || hitClimaxFor(action) != HitClimax.none)) {
      _closeupCtrl.forward(from: 0.0).then((_) {
        if (!_disposed) _closeupCtrl.reverse();
      });
    }

    // 首通展示帧·首技慢镜:玩家首个非普攻真命中 → 额外顿帧+命中特写。顿帧
    // 走既有 hit-stop 通道只延后下一拍(守 §5.5);快进态消费不呈现。
    if (showcaseBeat == ShowcaseBeat.firstSkill && !_isFastForward) {
      _closeupCtrl.forward(from: 0.0).then((_) {
        if (!_disposed) _closeupCtrl.reverse();
      });
      _applyHitStop(_animConfig.firstClearFirstSkillHoldMs);
    }
  }

  int _visualSlotKey(BattleCharacter character) =>
      slotKey(character.teamSide, character.slotIndex.clamp(0, 2));

  void dispose() {
    _disposed = true;
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _beatCtrl.dispose();
    _shakeCtrl.dispose();
    _closeupCtrl.dispose();
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
  }
}
