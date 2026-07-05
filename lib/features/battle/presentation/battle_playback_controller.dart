import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_state.dart';
import '../domain/battle_skill_utils.dart';
import '../domain/damage_calculator.dart';
import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import '../../../core/application/battle_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../../settings/domain/gameplay_settings.dart';
import 'battle_vfx_entries.dart';
import 'damage_popup.dart';
import 'ultimate_caption_overlay.dart';

/// BattleScreen 拆分批一（Task 1）：VFX 反应原语——命中后的飘字 / 弹道 / MJ 特效
/// 贴片 / 受击闪。从 `_BattleScreenState` 近似原样搬迁，机制不变：
/// - 不用 `ChangeNotifier`，由 [rebuild]（State 的 `setState`）驱动重绘粒度，
///   与搬迁前完全一致的重绘粒度。
/// - `_disposed` 替代 State 的 `mounted` 判断（AnimationController 状态回调场景）。
///
/// Task 2（拍/计时器）、Task 3（overlay 编排）、Task 4（`_playAction` 本体）
/// 陆续接管更多职责；本任务只搬「反应原语」，不动 beat/timer/hitstop/overlay-keys/
/// shake/closeup/`_playAction`。
class BattlePlaybackController {
  BattlePlaybackController({
    required TickerProvider vsync,
    required WidgetRef ref,
    required void Function(VoidCallback fn) rebuild,
    required AnimationNumbers animConfig,
    // 拍钟调度初值(Task 2):startPaused 起手即暂停;startFastForward 起手即快进。
    bool startPaused = false,
    bool startFastForward = false,
  }) : _vsync = vsync,
       _ref = ref,
       _rebuild = rebuild,
       _animConfig = animConfig {
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
  }

  final TickerProvider _vsync;
  final WidgetRef _ref;
  final void Function(VoidCallback) _rebuild;
  final AnimationNumbers _animConfig;
  bool _disposed = false;

  // ─── 拍钟调度（Task 2：beat/timer/hit-stop/pause/fast-forward） ──────────────
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

  // 活跃弹道（命令式 spawn，完成后移除）。本地 state，不污染 BattleState。
  final List<TrailEntry> _activeTrails = [];
  int _nextTrailId = 0;

  // 活跃 MJ 特效贴片（命中/暴击/闪避/流派招式）。
  final List<EffectEntry> _activeEffects = [];
  int _nextEffectId = 0;

  // 飘字状态：slotKey → 活跃飘字列表
  final Map<int, List<PopupEntry>> _popups = {};
  int _nextPopupId = 0;

  // ─── 公开只读 getter（供 build 读取，State 侧props 透传） ──────────────────
  List<AnimationController> get attackControllers => _attackControllers;
  List<AnimationController> get hitFlashControllers => _hitFlashControllers;
  Map<int, Color> get hitFlashColors => _hitFlashColors;
  List<TrailEntry> get activeTrails => _activeTrails;
  List<EffectEntry> get activeEffects => _activeEffects;
  Map<int, List<PopupEntry>> get popups => _popups;

  // 拍钟调度只读 getter（供 build props / 交互条件读取）。
  AnimationController get beatCtrl => _beatCtrl;
  bool get isPaused => _isPaused;
  bool get isFastForward => _isFastForward;
  bool get hasTimer => _playTimer != null;

  // 临时副本:Task 4 全移完后 State 侧副本删除
  GameplaySettings get _currentGameplaySettings => _ref
      .read(gameplaySettingsProvider)
      .maybeWhen(data: (s) => s, orElse: () => const GameplaySettings());

  // 临时副本:Task 4 全移完后 State 侧副本删除
  bool get _reduceFlashing => _currentGameplaySettings.reduceFlashing;

  /// 当前播放拍间隔(ms):快进态走 fastForwardIntervalMs,否则按玩家速度档缩放
  /// actionIntervalMs(与 [startTimer] 同源口径)。供飘字 spawn 时 clamp 时长,
  /// 防快档(rapid/快进)固定 damagePopupMs 超拍致跨拍重叠。
  int get _currentPlaybackIntervalMs => _isFastForward
      ? _animConfig.fastForwardIntervalMs
      : _currentGameplaySettings.scaledBattleIntervalMs(
          _animConfig.actionIntervalMs,
        );

  /// 受击闪：命中目标 slot 触发淡出（暴击绛红/普攻白）。纯 UI，不写 state。
  void triggerHitFlash(BattleCharacter target, bool isCritical) {
    if (_reduceFlashing) return;
    final key = slotKey(target.teamSide, target.slotIndex);
    _rebuild(() {
      _hitFlashColors[key] = isCritical ? WuxiaColors.gangMeng : Colors.white;
    });
    _hitFlashControllers[key].forward(from: 0.0);
  }

  /// 弹道：攻击者 slot → 目标 slot 的笔触线（流派色；大招更粗）。命令式 spawn。
  void spawnTrail(
    BattleCharacter actor,
    BattleCharacter target,
    BattleAction action,
  ) {
    final ctrl = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: _animConfig.projectileMs),
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
      strokeWidth: isUltimateCaptionSkill(action.skill) ? 5.0 : 3.0,
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

  void spawnBattleEffects(
    BattleCharacter? actor,
    BattleCharacter target,
    BattleAction action,
  ) {
    final result = action.attackResult;
    if (result == null) return;
    final targetFrac = _slotFrac(
      target.teamSide,
      target.slotIndex,
      _teamSizeOf(target.teamSide),
    );

    if (result.isDodged) {
      spawnEffect(
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
      spawnEffect(
        assetPath: _schoolFx(actor.school, isUltimate: isUltimate),
        centerFrac: targetFrac,
        size: isUltimate ? 360 : 250,
        opacity: isUltimate ? 0.76 : 0.64,
        rotation: actor.teamSide == 0 ? -0.08 : 0.08,
        mirrored: actor.teamSide == 1,
      );
    }

    if (result.isCritical) {
      spawnEffect(
        assetPath: WuxiaUi.fxCriticalHit,
        centerFrac: targetFrac,
        size: 220,
        opacity: 0.7,
      );
    }
    if (result.defenseRate >= 0.22) {
      spawnEffect(
        assetPath: WuxiaUi.fxArmorBreak,
        centerFrac: targetFrac,
        size: 210,
        opacity: 0.58,
      );
    }
    if (result.appliedEffects.contains('internal_injury')) {
      spawnEffect(
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

  void spawnEffect({
    required String assetPath,
    required Offset centerFrac,
    required double size,
    required double opacity,
    double rotation = 0,
    bool mirrored = false,
  }) {
    final ctrl = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 520),
    );
    final entry = EffectEntry(
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
  void spawnPopup(
    BattleCharacter target,
    AttackResult result,
    BattleCharacter? attacker,
  ) {
    final key = slotKey(target.teamSide, target.slotIndex);
    final data = _buildPopupData(result, attacker);
    final entry = PopupEntry(
      id: _nextPopupId++,
      data: data,
      popupDurationMs: _animConfig.effectivePopupMs(_currentPlaybackIntervalMs),
    );
    _rebuild(() {
      (_popups[key] ??= []).add(entry);
    });
    // 屏震触发已上移至 _playAction（批次 2.4 分档屏震集中触发）。
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

  void removePopup(int slotKey, int popupId) {
    _rebuild(() {
      _popups[slotKey]?.removeWhere((e) => e.id == popupId);
    });
  }

  /// 战场比例坐标（0..1）：左队 x=0.12 / 右队 x=0.88；竖直按队伍人数 [teamSize]
  /// 均分(见 [slotVerticalFraction]):1 怪居中 / 2 怪对称 / 3 怪 1/6,3/6,5/6。
  /// 弹道层在 LayoutBuilder 内解析为像素，避免依赖 RenderBox（widget test 稳定）。
  static Offset _slotFrac(int teamSide, int slotIndex, int teamSize) {
    final x = teamSide == 0 ? 0.12 : 0.88;
    return Offset(x, slotVerticalFraction(slotIndex, teamSize));
  }

  /// 取某队当前人数(供 [_slotFrac] 竖直均分)。死亡单位保留在队列(灰显)故长度稳定。
  int _teamSizeOf(int teamSide) {
    final s = _ref.read(battleProvider);
    return teamSide == 0 ? s.leftTeam.length : s.rightTeam.length;
  }

  // ─── 拍钟调度（Task 2） ─────────────────────────────────────────────────────

  void startTimer() {
    // 任何显式启动都作废挂起的 hit-stop 复播（避免快进/暂停切换撞 hit-stop 时
    // stale timer 二次 startTimer 致节拍抖动）。
    _hitStopTimer?.cancel();
    _playTimer?.cancel();
    if (_isPaused) {
      _beatCtrl.stop(); // 暂停态冻结读秒环节拍在当前扫位。
      return; // H3 暂停态:任何重启请求都不启动 timer。
    }
    // 快进态:玩家手动开了快进。
    final rushing = _isFastForward;
    final gameplaySettings = _currentGameplaySettings;
    final interval = rushing
        ? _animConfig.fastForwardIntervalMs
        : gameplaySettings.scaledBattleIntervalMs(
            _animConfig.actionIntervalMs,
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

  /// 玩法设置变更边沿:若 timer 在跑且战斗未结束 → 重启以应用新速度。
  void onGameplaySettingsChanged() {
    if (_playTimer != null && !_ref.read(battleProvider).isFinished) {
      startTimer();
    }
  }

  /// hit-stop：命中瞬间停播放 Timer，延后 [ms] 后复播。只动屏上播放节拍
  /// （advance 结算确定不变，守 §5.5）；startTimer 内 _isPaused gate 兜住，
  /// 暂停态不会被复活。
  void applyHitStop(int ms) {
    if (_isPaused) return;
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _hitStopTimer = Timer(Duration(milliseconds: ms), () {
      if (!_disposed && !_ref.read(battleProvider).isFinished) startTimer();
    });
  }

  void dispose() {
    _disposed = true;
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _beatCtrl.dispose();
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
