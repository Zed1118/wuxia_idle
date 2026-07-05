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
import 'battle_screen.dart' show slotVerticalFraction;
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
    bool startPaused = false,
    bool startFastForward = false,
  }) : _vsync = vsync,
       _ref = ref,
       _rebuild = rebuild,
       _animConfig = animConfig {
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

  // 临时副本:Task 4 全移完后 State 侧副本删除
  GameplaySettings get _currentGameplaySettings => _ref
      .read(gameplaySettingsProvider)
      .maybeWhen(data: (s) => s, orElse: () => const GameplaySettings());

  // 临时副本:Task 4 全移完后 State 侧副本删除
  bool get _reduceFlashing => _currentGameplaySettings.reduceFlashing;

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

  /// 飘字：命中目标 slot spawn 一条飘字（伤害数字/闪避/暴击样式）。
  ///
  /// [playbackIntervalMs]：relocation 必需的签名扩展——原 `_spawnPopup` 读
  /// State 独有的 `_currentPlaybackIntervalMs`（依赖 `_isFastForward`，该字段
  /// 要到 Task 2 才移交控制器，本任务不提前搬）。取值/公式不变，只是由调用方
  /// （State 的 `_playAction`）算好当前播放拍间隔后传入，而非控制器自行读取。
  void spawnPopup(
    BattleCharacter target,
    AttackResult result,
    BattleCharacter? attacker, {
    required int playbackIntervalMs,
  }) {
    final key = slotKey(target.teamSide, target.slotIndex);
    final data = _buildPopupData(result, attacker);
    final entry = PopupEntry(
      id: _nextPopupId++,
      data: data,
      popupDurationMs: _animConfig.effectivePopupMs(playbackIntervalMs),
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

  void dispose() {
    _disposed = true;
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
