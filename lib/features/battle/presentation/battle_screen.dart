import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_log.dart';
import '../domain/battle_replay.dart';
import '../domain/battle_state.dart';
import '../domain/battle_stats.dart';
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

  /// 时序重排(spec 2026-06-12):flow 路径传 true → 胜利时不弹 VictoryOverlay,
  /// 直接回调让 caller(stage/tower flow)接管,按掉落分档播爆品/简版勝。
  /// 败北不受影响;demo/pvp/debug 等无 flow 路径保持默认 false(仍弹 overlay)。
  final bool deferVictoryToCaller;

  /// 战斗 BGM 轨。调用方按 StageType（+ Boss 关）经 [bgmTrackForStage] 注入，
  /// 区分主线/塔/Boss/心魔/轻功/群战氛围。默认 [BgmTrack.battle] 通用兜底
  /// （demo/debug 零影响）。
  final BgmTrack bgmTrack;

  /// 半手动战斗 P0 步骤3c · 单步模式(opt-in,默认 false 现有调用零影响)。
  /// true 时:① 不启自动 Timer,改靠玩家点底部「下一步」逐步调
  /// [BattleNotifier.step](A 强制停顿:一步一 actor);② tick 边界填队列后顶部
  /// 显「本回合行动顺序」条让玩家看清出手序再布置指令;③ 点单体技立即弹目标
  /// picker 选敌(B),选定走 requestUltimate(targetId)。C 临时入口:由
  /// ScenarioLauncher / 调试路由注入,正式自动/手动开关留步骤5 接落盘判定。
  final bool manualStep;

  /// 半手动战斗 P0 步骤5-E · 自动重放(autoReplay)模式(opt-in,默认 null)。
  /// 非空时:战斗自动驱动(autoStart),但每个 Timer tick 用
  /// [BattleNotifier.step] 推进(每整数 tick 可观测,命中锚点)并在
  /// `state.tick == op.anchor` 注入 [BattleNotifier.requestUltimate],与
  /// [BattleNotifier.replay] 同语义确定性复刻手动通关。seed 由 host 经
  /// `startBattle(seed:)` 注入([replaySeed] 仅作语义标注/未来校验)。
  final List<BattleReplayOp>? replayOps;

  /// 重放 seed(语义标注;实际 seed 由 host startBattle 注入)。
  final int? replaySeed;

  const BattleScreen({
    super.key,
    this.animConfig = AnimationNumbers.defaults,
    this.hint,
    this.onBattleEnd,
    this.onVictory,
    this.onDefeat,
    this.sceneBackgroundPath,
    this.autoStart = true,
    this.deferVictoryToCaller = false,
    this.bgmTrack = BgmTrack.battle,
    this.manualStep = false,
    this.replayOps,
    this.replaySeed,
  });

  /// 是否自动重放模式(有录制操作序列待注入)。
  bool get isReplay => replayOps != null;

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

  // T1 指令台：当前"重点角色"槽位（玩家手动选定的基线）。敌人蓄力时由
  // [_effectiveFocus] 临时覆盖到可破招者，但不改写这个手动基线。
  // 技能"待发"态直接读 [BattleState.pendingUltimates]（domain 单一真相源），
  // 不再维护本地置灰 set——引擎消费后自动清，按钮印随之消失。
  int _focusSlotIndex = 0;

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

  /// 半手动 P0 步骤5-E:autoReplay 模式 Timer 驱动。每个 interval 走一次
  /// 「锚点注入 + step()」(同 `BattleNotifier.replay` 内循环,UI 节奏化)。
  /// 用 step() 而非 advance() 确保每整数 tick 可观测,命中所有 op 锚点。
  int _replayOpIdx = 0;
  void _startReplayTimer() {
    _playTimer?.cancel();
    final interval = _isFastForward
        ? widget.animConfig.fastForwardIntervalMs
        : widget.animConfig.actionIntervalMs;
    final ops = widget.replayOps!;
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      final s = ref.read(battleProvider);
      if (s.isFinished) {
        _playTimer?.cancel();
        return;
      }
      final n = ref.read(battleProvider.notifier);
      final tick = s.tick;
      while (_replayOpIdx < ops.length && ops[_replayOpIdx].anchor == tick) {
        final op = ops[_replayOpIdx];
        final skill = _resolveReplaySkill(s, op.charId, op.skillId);
        if (skill != null) {
          n.requestUltimate(op.charId, skill, targetId: op.targetId);
        }
        _replayOpIdx++;
      }
      n.step();
    });
  }

  /// 重放:按 charId + skillId 在该 actor 当前 availableSkills 解析 SkillDef
  /// (沿 `battle_providers.dart` `_resolveReplaySkill` 体例)。找不到返 null 跳过。
  SkillDef? _resolveReplaySkill(BattleState s, int charId, String skillId) {
    for (final c in [...s.leftTeam, ...s.rightTeam]) {
      if (c.characterId != charId) continue;
      for (final sk in c.availableSkills) {
        if (sk.id == skillId) return sk;
      }
    }
    return null;
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

  // ─── 指令台（T1） ──────────────────────────────────────────────────────────

  /// 玩家点重点角色的任一可用技能 → 走与大招相同的 [requestUltimate] 路径
  /// （[BattleAI._pickSkill] 对任意 pending 技能一视同仁地优先消费，不引入新战斗
  /// 数学）。仅当该技能 ready（存活 + 内力够 + CD 0）才下发。
  ///
  /// 单步模式(manualStep)下立即弹目标 picker(用户拍板 B):选定存活敌人后才
  /// requestUltimate(targetId);取消则不下发。自动模式不弹 picker,targetId=null
  /// 走 AI 默认选目标(现有行为不变)。
  Future<void> _onSkillCommand(int characterId, SkillDef skill) async {
    final s = ref.read(battleProvider);
    BattleCharacter? c;
    for (final ch in s.leftTeam) {
      if (ch.characterId == characterId) {
        c = ch;
        break;
      }
    }
    if (c == null || !_isSkillReady(c, skill)) return;
    if (!widget.manualStep) {
      ref.read(battleProvider.notifier).requestUltimate(characterId, skill);
      return;
    }
    final targetId = await _pickTarget(s);
    if (targetId == null || !mounted) return;
    ref
        .read(battleProvider.notifier)
        .requestUltimate(characterId, skill, targetId: targetId);
  }

  /// 单步模式单体技目标 picker：列出存活敌人(右队)供玩家点选，返回其 charId；
  /// 取消 / 无存活敌人返回 null。
  Future<int?> _pickTarget(BattleState s) {
    final enemies = s.rightTeam.where((e) => e.isAlive).toList();
    if (enemies.isEmpty) return Future.value(null);
    return showDialog<int>(
      context: context,
      builder: (ctx) => _TargetPickerDialog(enemies: enemies),
    );
  }

  /// 单步模式「下一步」：推进最小一步(tick 边界填队列 / 结算一个 actor)。
  void _onNextStep() {
    ref.read(battleProvider.notifier).step();
  }

  void _onSelectFocus(int slotIndex) {
    setState(() => _focusSlotIndex = slotIndex);
  }

  /// 重点角色生效槽位：敌人蓄力时自动落到首个"有 ready 破招技"的我方角色，
  /// 否则用玩家手动选的 [_focusSlotIndex]（越界 / 死亡时回退到 0）。
  int _effectiveFocus(BattleState s) {
    if (s.leftTeam.isEmpty) return 0;
    final enemyCharging = s.rightTeam.any(
      (e) => e.isAlive && e.chargingSkill != null,
    );
    if (enemyCharging) {
      for (var i = 0; i < s.leftTeam.length; i++) {
        final c = s.leftTeam[i];
        final k = _findKeySkillOf(c);
        if (k != null && _isSkillReady(c, k)) return i;
      }
    }
    if (_focusSlotIndex >= 0 && _focusSlotIndex < s.leftTeam.length) {
      return _focusSlotIndex;
    }
    return 0;
  }

  static bool _isSkillReady(BattleCharacter c, SkillDef skill) {
    if (!c.isAlive) return false;
    final cd = c.skillCooldowns[skill.id] ?? 0;
    return c.currentInternalForce >= skill.internalForceCost && cd <= 0;
  }

  static SkillDef? _findKeySkillOf(BattleCharacter c) {
    for (final skill in c.availableSkills) {
      if (skill.canInterrupt) return skill;
    }
    return null;
  }

  // ─── 结算 dialog ─────────────────────────────────────────────────────────

  void _showResultDialog(BattleResult result, BattleState s) {
    if (_resultDialogShown || !mounted) return;
    _resultDialogShown = true;

    // 战斗结束先停 battle BGM，让胜负 jingle 独奏:避免 battle BGM(loop) 与
    // victory/defeat jingle 叠加成一团。pop 战斗页后 BgmScope 自动恢复上层轨。
    SoundManager.instance.stopBgm();

    // 与 [VictoryOverlay] 题字一致:leftWin 显「勝」,其余(rightWin/draw)显「敗」。
    if (result == BattleResult.leftWin) {
      SoundManager.instance.playSfx(SfxId.victory);
    } else {
      SoundManager.instance.playSfx(SfxId.defeat);
    }

    // 时序重排:胜利且 caller 接管表现 → 不弹 VictoryOverlay,直接回调让 flow
    // roll 后按掉落分档播爆品/简版勝(spec 2026-06-12)。败北不走此分支。
    if (result == BattleResult.leftWin && widget.deferVictoryToCaller) {
      widget.onBattleEnd?.call();
      widget.onVictory?.call();
      return;
    }

    final stats = BattleStatsSummary.from(s);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // overlay 自带暗幕
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => VictoryOverlay(
        result: result,
        totalDamage: stats.totalDamage,
        critCount: stats.critCount,
        totalTicks: stats.totalTicks,
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
      chargeMaxTicks = ref
          .read(numbersConfigProvider)
          .combat
          .bossCharge
          .defaultChargeTicks;
    } catch (_) {
      chargeMaxTicks = 3;
    }

    ref.listen<BattleState>(battleProvider, (prev, next) {
      // 1. 启动 Timer：team 从空 → 非空且未结束。
      //    单步模式(manualStep)永不启 Timer——靠玩家点「下一步」逐步推进。
      final wasEmpty = prev == null || prev.leftTeam.isEmpty;
      if (widget.autoStart &&
          !widget.manualStep &&
          wasEmpty &&
          next.leftTeam.isNotEmpty &&
          !next.isFinished) {
        // autoReplay 走 step()+锚点注入 driver;否则普通 advance() 自动战斗。
        widget.isReplay ? _startReplayTimer() : _startTimer();
      }

      // 2. 战斗结束：停 timer + 弹结算 dialog（postFrame 避免 build 期 setState）
      if ((prev?.result == null) && next.result != null) {
        _playTimer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResultDialog(next.result!, next);
        });
      }

      // 3. actionLog 新增：触发动画（待发态自动随 pendingUltimates 消费而清，
      //    无需本地解除置灰）。
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        for (final a in newActions) {
          _playAction(a, next);
        }
      }

      // 4. 破招机制 SFX：状态边沿触发（表现层纯读 state，不入 domain）。
      for (final sfx in chargeTransitionSfx(prev, next)) {
        SoundManager.instance.playSfx(sfx);
      }
    });

    // team 空时（startBattle 还未调用）渲染 placeholder
    if (state.leftTeam.isEmpty && state.rightTeam.isEmpty) {
      return BgmScope(
        track: widget.bgmTrack,
        child: const Scaffold(
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
      track: widget.bgmTrack,
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
                    _DangerBar(state: state),
                    if (widget.manualStep) _ActorOrderBar(state: state),
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
                    _BattleReportStrip(
                      state: state,
                      onTap: () => setState(() => _logOpen = true),
                    ),
                    _BottomBar(
                      state: state,
                      focusSlotIndex: _effectiveFocus(state),
                      onSelectFocus: _onSelectFocus,
                      onSkill: _onSkillCommand,
                      onFastForward: _toggleFastForward,
                      isFastForward: _isFastForward,
                      manualStep: widget.manualStep,
                      onNextStep: _onNextStep,
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

// ─── 蓄力危险条（T2）──────────────────────────────────────────────────────

/// 敌人蓄力大招时的顶部警示条。纯读 [BattleState.rightTeam]：取最临近发动
/// （[chargeTicksRemaining] 最小）的存活蓄力敌人，显示招名 + 剩余回合，提示玩家
/// 看准时机破招。无敌人蓄力时返回 [SizedBox.shrink]（不占高度、不渲染 key）。
class _DangerBar extends StatelessWidget {
  final BattleState state;
  const _DangerBar({required this.state});

  @override
  Widget build(BuildContext context) {
    BattleCharacter? imminent;
    for (final e in state.rightTeam) {
      if (!e.isAlive || e.chargingSkill == null) continue;
      if (imminent == null ||
          e.chargeTicksRemaining < imminent.chargeTicksRemaining) {
        imminent = e;
      }
    }
    if (imminent == null) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('battle_danger_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: WuxiaColors.danger.withValues(alpha: 0.18),
        border: const Border(bottom: BorderSide(color: WuxiaColors.danger)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: WuxiaColors.danger,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              UiStrings.battleDangerCharging(
                imminent.name,
                imminent.chargingSkill!.name,
                imminent.chargeTicksRemaining,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 最近战报条（T3）──────────────────────────────────────────────────────

/// 底部常驻的最近关键战报（大招/破招/暴击/击杀），最多 3 条，最新在上。
/// 纯读 [BattleLog.recentKeyActions]；无关键战报时返回 [SizedBox.shrink]。
/// 点击整条 → [onTap]（打开完整 [_LogDrawer]）。实时反馈仍靠飘字/弹道，
/// 本条只做"刚刚发生了什么大事"的常驻速览。
class _BattleReportStrip extends StatelessWidget {
  final BattleState state;
  final VoidCallback onTap;
  const _BattleReportStrip({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final keys = BattleLog.recentKeyActions(state);
    if (keys.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('battle_report_strip'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            color: WuxiaColors.sidebar,
            border: Border(top: BorderSide(color: WuxiaColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 14, color: WuxiaColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < keys.length; i++)
                      Text(
                        BattleLog.formatActionCompact(keys[i], state),
                        key: ValueKey('battle_report_line_$i'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == 0
                              ? WuxiaColors.textSecondary
                              : WuxiaColors.textMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: WuxiaColors.textMuted,
              ),
            ],
          ),
        ),
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

/// T1 战斗指令台：左侧重点角色选择器 + 该角色全部可用技能的分组指令按钮 + 快进。
///
/// 旧版每角色只暴露大招/破招两按钮；新版聚焦单个"重点角色"，把它的
/// [BattleCharacter.availableSkills]（除普攻）全摊开成 强力/破招/共鸣/大招 分组按钮，
/// 每按钮带内力消耗 / 冷却 / 待发 状态。点头像切重点角色；敌人蓄力时由
/// [_BattleScreenState._effectiveFocus] 自动切到可破招者。点击仍走 [requestUltimate]。
class _BottomBar extends StatelessWidget {
  final BattleState state;
  final int focusSlotIndex;
  final void Function(int slotIndex) onSelectFocus;
  final void Function(int characterId, SkillDef skill) onSkill;
  final VoidCallback onFastForward;
  final bool isFastForward;

  /// 半手动 P0 步骤3c：单步模式 → 右侧「快进」换成「下一步」(玩家驱动 step)。
  final bool manualStep;
  final VoidCallback onNextStep;

  const _BottomBar({
    required this.state,
    required this.focusSlotIndex,
    required this.onSelectFocus,
    required this.onSkill,
    required this.onFastForward,
    required this.isFastForward,
    required this.manualStep,
    required this.onNextStep,
  });

  /// 排序/分组秩：强力 0 → 破招 1 → 共鸣 2 → 大招 3（普攻 4，已被过滤）。
  static int _groupRank(SkillDef s) {
    if (s.canInterrupt) return 1;
    return switch (s.type) {
      SkillType.powerSkill => 0,
      SkillType.jointSkill => 2,
      SkillType.ultimate => 3,
      SkillType.normalAttack => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final enemyCharging = state.rightTeam.any(
      (e) => e.isAlive && e.chargingSkill != null,
    );
    final hasFocus =
        focusSlotIndex >= 0 && focusSlotIndex < state.leftTeam.length;
    final focus = hasFocus ? state.leftTeam[focusSlotIndex] : null;
    final pending = focus == null
        ? null
        : state.pendingUltimates[focus.characterId];

    final skills = <SkillDef>[
      if (focus != null)
        for (final s in focus.availableSkills)
          if (s.type != SkillType.normalAttack) s,
    ]..sort((a, b) => _groupRank(a).compareTo(_groupRank(b)));

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FocusSelector(
            team: state.leftTeam,
            focusSlotIndex: focusSlotIndex,
            onSelectFocus: onSelectFocus,
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 60, color: WuxiaColors.border),
          const SizedBox(width: 10),
          Expanded(
            child: focus == null
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in skills) ...[
                          _SkillCommandButton(
                            character: focus,
                            skill: s,
                            isPending: pending?.id == s.id,
                            queuedAnother:
                                pending != null && pending.id != s.id,
                            highlight: enemyCharging && s.canInterrupt,
                            onPressed: () => onSkill(focus.characterId, s),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          if (manualStep)
            _NextStepButton(onPressed: onNextStep)
          else
            _FastForwardButton(
              onPressed: onFastForward,
              isActive: isFastForward,
            ),
        ],
      ),
    );
  }
}

/// 重点角色选择器：我方 3 槽小头像 chip，点选切重点角色。
class _FocusSelector extends StatelessWidget {
  final List<BattleCharacter> team;
  final int focusSlotIndex;
  final void Function(int slotIndex) onSelectFocus;

  const _FocusSelector({
    required this.team,
    required this.focusSlotIndex,
    required this.onSelectFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < team.length; i++) ...[
          _FocusChip(
            key: ValueKey('focus_chip_$i'),
            character: team[i],
            selected: i == focusSlotIndex,
            onTap: () => onSelectFocus(i),
          ),
          if (i < team.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  final BattleCharacter character;
  final bool selected;
  final VoidCallback onTap;

  const _FocusChip({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(character.school);
    final dim = !character.isAlive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 46,
        height: 60,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.28) : WuxiaColors.sidebar,
          border: Border.all(
            color: selected ? color : WuxiaColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dim ? WuxiaColors.textMuted : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  character.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: dim
                        ? WuxiaColors.textMuted
                        : (selected
                              ? WuxiaColors.textPrimary
                              : WuxiaColors.textSecondary),
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

/// 单个技能指令按钮：分组标签 + 招名 + 状态行（待发 / 冷却 N / 耗 N）。
/// `isPending` 盖"待发"印且禁用；`queuedAnother`（同角色已排别的技能）也禁用；
/// `highlight`（敌人蓄力 + 本技能可破招）换醒目金 + 白边。
class _SkillCommandButton extends StatelessWidget {
  final BattleCharacter character;
  final SkillDef skill;
  final bool isPending;
  final bool queuedAnother;
  final bool highlight;
  final VoidCallback onPressed;

  const _SkillCommandButton({
    required this.character,
    required this.skill,
    required this.isPending,
    required this.queuedAnother,
    required this.highlight,
    required this.onPressed,
  });

  static String _groupLabel(SkillDef s) {
    if (s.canInterrupt) return UiStrings.battleInterruptSkill; // 破招
    return switch (s.type) {
      SkillType.powerSkill => UiStrings.skillGroupPower, // 强力
      SkillType.jointSkill => UiStrings.skillGroupJoint, // 共鸣
      SkillType.ultimate => UiStrings.ultimate, // 大招
      SkillType.normalAttack => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cd = character.skillCooldowns[skill.id] ?? 0;
    final ready = _BattleScreenState._isSkillReady(character, skill);
    final enabled = ready && !isPending && !queuedAnother;

    final Color bgColor;
    final baseSchoolColor = WuxiaColors.schoolColor(character.school);
    if (!ready) {
      bgColor = WuxiaColors.buttonDisabled;
    } else if (highlight) {
      bgColor = Color.lerp(
        WuxiaColors.sidebar,
        WuxiaColors.resultHighlight,
        0.72,
      )!; // 敌人蓄力中：醒目金, 但收敛到战斗面板色系。
    } else {
      bgColor = Color.lerp(WuxiaColors.sidebar, baseSchoolColor, 0.78)!;
    }

    final String statusText;
    if (isPending) {
      statusText = UiStrings.skillPendingStamp; // 待发
    } else if (cd > 0) {
      statusText = UiStrings.skillCooldownShort(cd); // 冷却 N
    } else {
      statusText = UiStrings.skillCostShort(skill.internalForceCost); // 耗 N
    }

    return SizedBox(
      width: 92,
      height: 76,
      child: ElevatedButton(
        key: ValueKey('skill_cmd_${character.characterId}_${skill.id}'),
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor: isPending
              ? WuxiaColors.sidebar
              : WuxiaColors.buttonDisabled,
          foregroundColor: WuxiaColors.textPrimary,
          disabledForegroundColor: WuxiaColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          side: highlight && enabled
              ? const BorderSide(color: WuxiaColors.textPrimary, width: 2)
              : BorderSide(
                  color: baseSchoolColor.withValues(alpha: 0.46),
                  width: 1,
                ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _groupLabel(skill),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                  color: isPending
                      ? WuxiaColors.resultHighlight
                      : (enabled
                            ? WuxiaColors.textPrimary
                            : WuxiaColors.textMuted),
                ),
              ),
            ],
          ),
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

/// 半手动 P0 步骤3c：单步「下一步」按钮。每点一次驱动 [BattleNotifier.step]
/// 一步(A 强制停顿:tick 边界填队列 / 结算一个 actor)。实心醒目区别于快进。
class _NextStepButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NextStepButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('battle_next_step_button'),
      width: 96,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: WuxiaColors.resultHighlight,
          foregroundColor: WuxiaColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          UiStrings.battleNextStep,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// 半手动 P0 步骤3c：本回合行动顺序条(单步模式 + [BattleState.actorQueue]
/// 非空时显)。tick 边界填队列后玩家先看清出手序再布置指令；队首=下一个
/// 行动的 actor 高亮。纯读 state，队列空(tick 边界)返回 [SizedBox.shrink]。
class _ActorOrderBar extends StatelessWidget {
  final BattleState state;
  const _ActorOrderBar({required this.state});

  BattleCharacter? _find(int charId) {
    for (final c in state.leftTeam) {
      if (c.characterId == charId) return c;
    }
    for (final c in state.rightTeam) {
      if (c.characterId == charId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (state.actorQueue.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('battle_actor_order_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            '${UiStrings.battleActorOrder}：',
            style: TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < state.actorQueue.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: WuxiaColors.textMuted,
                        ),
                      ),
                    _ActorOrderChip(
                      name: _find(state.actorQueue[i].charId)?.name ?? '？',
                      isPlayer: state.actorQueue[i].teamSide == 0,
                      isNext: i == 0,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActorOrderChip extends StatelessWidget {
  final String name;
  final bool isPlayer;
  final bool isNext;
  const _ActorOrderChip({
    required this.name,
    required this.isPlayer,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPlayer ? WuxiaColors.textPrimary : WuxiaColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isNext
            ? WuxiaColors.resultHighlight.withValues(alpha: 0.22)
            : Colors.transparent,
        border: Border.all(
          color: isNext ? WuxiaColors.resultHighlight : WuxiaColors.border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// 半手动 P0 步骤3c：单体技目标 picker(用户拍板 B 立即弹)。列存活敌人，
/// 点选返回其 charId(pop 给 [_pickTarget])；点外部 / 取消返回 null。
class _TargetPickerDialog extends StatelessWidget {
  final List<BattleCharacter> enemies;
  const _TargetPickerDialog({required this.enemies});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('battle_target_picker'),
      backgroundColor: WuxiaColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: WuxiaColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                UiStrings.battleTargetPickerTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final e in enemies)
              InkWell(
                key: ValueKey('battle_target_option_${e.characterId}'),
                onTap: () => Navigator.of(context).pop(e.characterId),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: WuxiaColors.schoolColor(e.school),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.name,
                          style: const TextStyle(
                            color: WuxiaColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${e.currentHp}/${e.maxHp}',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
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
