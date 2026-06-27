import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_log.dart';
import '../domain/battle_state.dart';
import '../domain/battle_stats.dart';
import '../domain/battle_diagnosis.dart';
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
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import 'attack_animation.dart';
import 'battle_atmosphere_overlay.dart';
import 'battle_effect_sprite.dart';
import 'battle_scene_background.dart';
import 'character_avatar.dart';
import 'damage_popup.dart';
import 'hit_flash.dart';
import 'boss_phase_presentation.dart';
import 'impact_profile.dart';
import 'impact_glyph_overlay.dart';
import 'screen_flash.dart';
import 'projectile_trail.dart';
import 'ultimate_caption_overlay.dart';
import 'victory_overlay.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';

/// 常速播放命中后的顿帧时长：关键帧（暴击/大招/合一/破招/击杀）取
/// `profileHitStopMs` 与 `keyMomentHoldMs` 的大者，否则用 `profileHitStopMs`。
/// 纯函数便于单测（节奏手感本身走真机目检）。
int playbackHoldMs({
  required bool isKey,
  required int profileHitStopMs,
  required int keyMomentHoldMs,
}) => isKey && keyMomentHoldMs > profileHitStopMs
    ? keyMomentHoldMs
    : profileHitStopMs;

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
/// 拖招命中测试(Phase 4 · C3):指针全局坐标落在哪个敌人头像矩形内 → 返回
/// 该 enemyId(无命中返回 null)。敌列纵向排布不重叠,取首个命中即可。纯函数,
/// 与 widget 解耦,便于单测。
int? hitTestEnemyId(Offset pointer, List<({int enemyId, Rect rect})> targets) {
  for (final t in targets) {
    if (t.rect.contains(pointer)) return t.enemyId;
  }
  return null;
}

/// 队列内某槽的竖直比例坐标(0..1),按**实际队伍人数** [teamSize] 均分:
///   1 人 → 0.5(居中);2 人 → 0.25 / 0.75(上下对称);3 人 → 1/6,3/6,5/6(原行为)。
///
/// `_TeamColumn` 的视觉排布与 `_slotFrac` 的弹道坐标共用此式,保证头像位置与
/// 弹道/特效落点一致(分母从旧的硬编码 3 改为 teamSize 是本次「1 怪居中 / 2 怪对称」
/// 的唯一改动点)。teamSize ≤ 0 兜底 0.5 防除零。纯函数,单测直接验证。
double slotVerticalFraction(int slotIndex, int teamSize) {
  if (teamSize <= 0) return 0.5;
  return (slotIndex + 0.5) / teamSize;
}

/// 拖招表现层静态验收预置态(仅 [BattleScreen.debugDragPreview] / battle_drag_preview
/// 路由用)。拖招引导线/蓄势光晕/悬停高亮都靠长按拖手势触发,Codex 鼠标合成无法重现,
/// 故用这个免手势预置态截图验新样式。生产路径不构造。
class BattleDragPreview {
  /// 引导线起手角色 charId(取其流派色画线)。
  final int dragCharId;

  /// 蓄势脉动角色 charId(左队,流派色呼吸光晕)。
  final int rushActorId;

  /// 悬停命中高亮的敌人 charId(浅金静态强光);null 不高亮。
  final int? hoveredEnemyId;

  /// 引导线起点(全局坐标,技能按钮锚点)。
  final Offset origin;

  /// 引导线终点(全局坐标,当前指针/落点)。
  final Offset pointer;

  const BattleDragPreview({
    required this.dragCharId,
    required this.rushActorId,
    required this.origin,
    required this.pointer,
    this.hoveredEnemyId,
  });
}

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

  /// H3 投降:玩家主动认输撤退回调(经确认对话框)。null 则不显投降键
  /// (demo/debug 等无 flow 路径)。host 接此回调跳过战败结算直接退出。
  final VoidCallback? onSurrender;

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
  /// 败北不受影响;demo/debug 等无 flow 路径保持默认 false(仍弹 overlay)。
  final bool deferVictoryToCaller;

  /// 战斗 BGM 轨。调用方按 StageType（+ Boss 关）经 [bgmTrackForStage] 注入，
  /// 区分主线/塔/Boss/心魔/轻功/群战氛围。默认 [BgmTrack.battle] 通用兜底
  /// （demo/debug 零影响）。
  final BgmTrack bgmTrack;

  /// P1 周目进化 E2：江湖记招提示（targetCycle ≥ 2 时由 caller 传入 jianghuRememberHint）。
  /// 非空时在 hint 横幅下方额外渲染一条琥珀色提示条，战斗开始后自动常驻（不阻塞）。
  final String? cycleHint;

  /// 战斗交互重做 Phase 3:本场是否允许玩家拖招干预(host 由 [resolveAutoPlayMode]
  /// → `AutoPlayMode.interactive` 算出注入)。**Phase 3 暂无可见行为差异**(战斗
  /// 无论如何都自动连续播放);Phase 4 拖招层将以此门控技能栏 GestureDetector /
  /// 引导线 —— `false` = 纯挂机不挂拖招层。
  final bool allowPlayerIntervention;

  /// 仅调试/验收用:预置拖招表现层静态态(引导线 + 蓄势光晕 + 悬停高亮),供
  /// Codex 截图验新样式 —— 拖招手势靠长按拖,鼠标合成无法触发(见 battle_drag_preview
  /// 路由)。生产路径恒 null,不影响任何真实战斗。配 [autoStart] false 冻结画面。
  final BattleDragPreview? debugDragPreview;

  /// 仅验收路由用(默认 false → 生产/现有调用零影响):起手即暂停,战斗冻结在
  /// startBattle seed 初态(timer 因 _isPaused 不启,与 [autoStart] 兼容)。
  /// **为 true 时**头栏额外渲染「单步」按钮(逐步推进战斗,供验收者拖招/看
  /// 内力不足/debuff hover);生产挂机战斗恒 false,单步按钮严禁出现。
  final bool startPaused;

  /// 一键扫荡用(默认 false → 现有调用零影响):起手即快进态,战斗本体直接以
  /// [AnimationNumbers.fastForwardIntervalMs] 速度连播,免玩家手点快进键。
  final bool startFastForward;

  /// 一键扫荡用(默认 false → 现有调用零影响):**挂载时若 battleProvider 已是非空
  /// 活跃战斗,自动起播**。常规流程(stage/tower host)是「先挂本屏空团、后 postFrame
  /// startBattle」,靠 build 内 `ref.listen` 的 empty→非空边沿起 timer;扫荡是「先注入、
  /// 后挂本屏」,挂载时边沿已过 → 监听捕获不到。本标志为扫荡补一条挂载后兜底自启,
  /// 不影响默认契约(其它调用预填战斗后保持冻结直到显式 advance)。
  final bool autoStartOnMount;

  const BattleScreen({
    super.key,
    this.animConfig = AnimationNumbers.defaults,
    this.hint,
    this.onBattleEnd,
    this.onVictory,
    this.onDefeat,
    this.onSurrender,
    this.sceneBackgroundPath,
    this.autoStart = true,
    this.deferVictoryToCaller = false,
    this.bgmTrack = BgmTrack.battle,
    this.cycleHint,
    this.allowPlayerIntervention = false,
    this.debugDragPreview,
    this.startPaused = false,
    this.startFastForward = false,
    this.autoStartOnMount = false,
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

  // 命中特写 controller（大招暴击/击杀：缩放脉冲；快进/扫荡/拖招时抑制）。
  late final AnimationController _closeupCtrl;

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

  // 实时 tick 定时器（常速: advanceOneAction() / 快进: advance() 驱动）
  Timer? _playTimer;
  bool _isFastForward = false; // initState 据 widget.startFastForward 置初值
  bool _isPaused = false;

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

  // 批次 2.4 打击感 overlay key + hit-stop 计时器（命令式触发，纯表现层）。
  final GlobalKey<ImpactGlyphOverlayState> _impactGlyphKey =
      GlobalKey<ImpactGlyphOverlayState>();
  final GlobalKey<ScreenFlashOverlayState> _screenFlashKey =
      GlobalKey<ScreenFlashOverlayState>();
  Timer? _hitStopTimer;
  // 批次 2.4 当前重击屏震振幅（profile 分档；0=不抖）。复用既有 _shakeCtrl。
  double _impactShakeAmplitude = 0.0;

  // ─── Phase 4 拖招交互 ────────────────────────────────────────────────────
  // 敌方 3 槽头像的 GlobalKey(hitTest 命中判定用;右队按 slotIndex 索引)。
  late final List<GlobalKey> _enemyAvatarKeys;
  // 拖招态(纯 UI,不写 BattleState):拖起的技能与拖招者,引导线起点(技能按钮中心)
  // 与当前指针(均全局坐标),以及当前悬停命中的敌人 charId(高亮用)。
  SkillDef? _dragSkill;
  int? _dragCharId;
  Offset? _dragOrigin;
  Offset? _dragPointer;
  int? _hoveredEnemyId;
  // C5 立即触发:拖/点技能后快进到该角色出手的目标 charId(出手即清,恢复常速)。
  int? _rushToActorId;

  // ─── 生命周期 ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isFastForward = widget.startFastForward;
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
    _closeupCtrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: widget.animConfig.hitTier.closeupPulseMs),
    );
    _hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        value: 1.0, // 静止满值 → HitFlash alpha=0 不显
        duration: Duration(milliseconds: widget.animConfig.hitFlashMs),
      ),
    );
    _enemyAvatarKeys = List.generate(3, (_) => GlobalKey());
    // 调试/验收:预置拖招蓄势者 + 悬停敌(引导线在 build 单独渲染)。autoStart false
    // 冻结画面,蓄势光晕脉动常驻,悬停高亮不被手势清。
    final preview = widget.debugDragPreview;
    if (preview != null) {
      _rushToActorId = preview.rushActorId;
      _hoveredEnemyId = preview.hoveredEnemyId;
    }
    // 验收路由 startPaused:起手即暂停 → _startTimer 内 _isPaused gate 兜住
    // 自动启动路径(autoStart=true 仍会 startBattle,但 timer 不启),战斗冻结
    // 在 seed 初态等手动单步/继续。生产恒 false 不受影响。
    if (widget.startPaused) {
      _isPaused = true;
    }
    // Timer 不在 initState 同步启动:常规流程(stage/tower host)先挂本屏(空团)再在
    // postFrame 调 startBattle,由 build 内 `ref.listen` 的 empty→非空边沿起 timer。
    //
    // 一键扫荡(SweepScreen)反序「先注入战斗、后挂本屏」:本屏挂载时 battleProvider
    // 已是非空活跃态,空→非空边沿早已发生 → 监听捕获不到 → timer 永不启动(黑屏
    // hang)。仅当 caller 显式 opt-in [autoStartOnMount] 时补一条挂载后兜底:挂到一场
    // 已就绪的活跃战斗且尚无 timer → 自启。默认 false 保持现有契约(其它调用预填战斗
    // 后保持冻结,由测试/验收显式推进),零回归。
    if (widget.autoStartOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !widget.autoStart ||
            _isPaused ||
            widget.debugDragPreview != null ||
            _playTimer != null) {
          return;
        }
        final s = ref.read(battleProvider);
        if (s.leftTeam.isNotEmpty && !s.isFinished) _startTimer();
      });
    }
  }

  // 验收路由 startPaused 专用:单步推进战斗 + setState 反映 UI。
  // gating:仅 widget.startPaused 时渲染按钮调用(生产挂机不出现)。
  void _stepOnce() {
    ref.read(battleProvider.notifier).step();
    setState(() {});
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
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
    _closeupCtrl.dispose();
    super.dispose();
  }

  // ─── Timer / advance 驱动 ────────────────────────────────────────────────

  void _startTimer() {
    // 任何显式启动都作废挂起的 hit-stop 复播（避免快进/暂停切换撞 hit-stop 时
    // stale timer 二次 _startTimer 致节拍抖动）。
    _hitStopTimer?.cancel();
    _playTimer?.cancel();
    if (_isPaused) return; // H3 暂停态:任何重启请求都不启动 timer。
    // 快进态:玩家手动开了快进,或拖招立即触发正在「快进到出手」(C5)。
    final rushing = _isFastForward || _rushToActorId != null;
    final interval = rushing
        ? widget.animConfig.fastForwardIntervalMs
        : widget.animConfig.actionIntervalMs;
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      final notifier = ref.read(battleProvider.notifier);
      if (rushing) {
        notifier.advance();
      } else {
        notifier.advanceOneAction();
      }
    });
  }

  void _toggleFastForward() {
    setState(() => _isFastForward = !_isFastForward);
    if (_playTimer != null) _startTimer();
  }

  // H3 暂停:停 tick(_startTimer 内 _isPaused gate 兜住所有重启路径);
  // 恢复时若战斗未结束则重启自动播放。
  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _playTimer?.cancel();
    } else if (!ref.read(battleProvider).isFinished) {
      _startTimer();
    }
  }

  // H3 投降:确认对话框 → onSurrender 回调(host 跳过战败结算直接退出)。
  Future<void> _confirmSurrender() async {
    final ok = await PaperDialog.show<bool>(
      context,
      title: UiStrings.surrenderConfirmTitle,
      body: const Text(
        UiStrings.surrenderConfirmMessage,
        style: TextStyle(color: WuxiaColors.textSecondary, height: 1.5),
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(UiStrings.surrenderCancelAction),
          ),
        ),
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(UiStrings.surrenderConfirmAction),
          ),
        ),
      ],
    );
    if (ok == true) widget.onSurrender?.call();
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
      final climax = hitClimaxFor(action, s);
      final isCrit = action.attackResult?.isCritical ?? false;
      _ultimateCaptionKey.currentState?.show(
        action.skill!.name,
        isEnemy: actor?.teamSide == 1,
        fontSize: climax == HitClimax.ultimateCrit
            ? widget.animConfig.hitTier.captionPeakSize.toDouble()
            : 56,
        glowBlur: isCrit ? widget.animConfig.hitTier.captionGlowBlur : 0,
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
        _screenFlashKey.currentState?.flash(
          profile.flashStrength,
          // profile 非空 ⇒ attackResult 非空（见 impactProfileFor 的 null 契约）。
          color: action.attackResult!.isCritical
              ? WuxiaColors.gangMeng
              : Colors.white,
        );
        // hit-stop + 镜头震：快进/拖招态跳过（守 2.3 时序 + 保快进顺滑）。
        if (!_isFastForward && _rushToActorId == null) {
          _impactShakeAmplitude = profile.shakeMagnitude;
          _shakeCtrl.forward(from: 0.0);
          _applyHitStop(
            playbackHoldMs(
              isKey: BattleLog.isKeyAction(action, s),
              profileHitStopMs: profile.hitStopMs,
              keyMomentHoldMs: widget.animConfig.keyMomentHoldMs,
            ),
          );
        }
      }
    }

    // 命中特写：仅峰值（大招暴击/击杀），快进/扫荡/拖招抑制（守在线=离线）。
    // 独立于 profile != null 块：普攻击杀无 profile 也须触发特写。
    if (!_isFastForward &&
        _rushToActorId == null &&
        hitClimaxFor(action, s) != HitClimax.none) {
      _closeupCtrl.forward(from: 0.0).then((_) {
        if (mounted) _closeupCtrl.reverse();
      });
    }
  }

  /// 第七阶段批二 ① Boss 转阶段表现层：题字（短标题，未知 key 走 EnumL10n
  /// 兜底）+ 全屏闪白 + Boss 立绘抖动。复用 2.4 的 glyph / flash / shake 通道，
  /// 不另起平行系统。纯读 action 元数据，不写 BattleState（守 §5.4）；后台挂机
  /// 不进此屏播放路径（守 §5.5）。
  void _playBossPhaseTransition(BattleAction action, BattleCharacter? actor) {
    if (action.bossPhaseTransitionTo == null) return;
    final bossName = actor?.name ?? '';
    final title = bossPhaseTitleFor(action, bossName);
    if (title == null) return;
    final isEnemy = actor?.teamSide == 1;
    // 题字（多字 caption overlay，承载 4 字转阶段标题；单字 glyph 会裁切多字）。
    // 不触发 hit-stop：转阶段非打击命中，暂停 timer 无意义。
    _ultimateCaptionKey.currentState?.show(title, isEnemy: isEnemy);
    // 闪白 + 立绘抖动复用 2.4 heavy 档参数（转阶段是重场面）。GameRepository 未
    // 初始化（轻量 widget 测）时 cfg==null，仍保证题字触发、闪白/抖动跳过。
    final cfg = _impactConfigOrNull();
    if (cfg != null) {
      _screenFlashKey.currentState?.flash(
        cfg.heavy.flashStrength,
        color: WuxiaColors.gangMeng,
      );
      // 抖动同 2.4：快进 / 拖招态跳过（保顺滑）。
      if (!_isFastForward && _rushToActorId == null) {
        _impactShakeAmplitude = cfg.heavy.shakeMagnitude;
        _shakeCtrl.forward(from: 0.0);
      }
    }
  }

  /// 读打击感配置；GameRepository 未初始化（轻量 widget 测）时返 null 跳过。
  ImpactFeedbackConfig? _impactConfigOrNull() {
    try {
      return ref.read(numbersConfigProvider).combat.impactFeedback;
    } catch (_) {
      return null;
    }
  }

  /// hit-stop：命中瞬间停播放 Timer，延后 [ms] 后复播。只动屏上播放节拍
  /// （advance 结算确定不变，守 §5.5）；_startTimer 内 _isPaused gate 兜住，
  /// 暂停态不会被复活。
  void _applyHitStop(int ms) {
    if (_isPaused) return;
    _playTimer?.cancel();
    _hitStopTimer?.cancel();
    _hitStopTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted && !ref.read(battleProvider).isFinished) _startTimer();
    });
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
    final targetFrac = _slotFrac(
      target.teamSide,
      target.slotIndex,
      _teamSizeOf(target.teamSide),
    );

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

  void _removePopup(int slotKey, int popupId) {
    setState(() {
      _popups[slotKey]?.removeWhere((e) => e.id == popupId);
    });
  }

  // ─── 指令台（T1） ──────────────────────────────────────────────────────────

  /// 玩家拖招松手 → 调 [BattleNotifier.interveneNow] 立即插队出手(预支 AP 归零)。
  /// 仅当该技能 ready（存活 + 内力够 + CD 0）才下发，targetId=null 走 AI 默认选目标。
  ///
  /// 主线二 2.3:即放·真插队——立即出手(预支 AP 归零),不再走 pending+C5 快进路径。
  void _onSkillCommand(int characterId, SkillDef skill, {int? targetId}) {
    if (!widget.allowPlayerIntervention) return; // 门控:群战/纯自动不接受指令
    final s = ref.read(battleProvider);
    BattleCharacter? c;
    for (final ch in s.leftTeam) {
      if (ch.characterId == characterId) {
        c = ch;
        break;
      }
    }
    if (c == null || !_isSkillReady(c, skill)) return;
    // 主线二 2.3:即放·真插队——立即出手(预支 AP 归零),不再标记 pending+C5 快进。
    ref
        .read(battleProvider.notifier)
        .interveneNow(characterId, skill, targetId: targetId);
    setState(() {}); // 清拖招态 + 反映出手
  }

  /// 批次 1.3:点击技能方块 → 弹简介浮层(直接读 [SkillDef] 活数据)。
  /// 不下发命令(下发改走长按拖招);CD/内力不足态也可点开查看。
  void _showSkillInfo(SkillDef skill) {
    PaperDialog.show<void>(
      context,
      title: skill.name,
      body: _SkillInfoBody(skill: skill),
      actions: [
        PlaqueButton(
          label: UiStrings.skillInfoClose,
          onTap: () => Navigator.of(context).pop(),
          primary: true,
        ),
      ],
    );
  }

  // ─── 拖招(Phase 4 · C1-C3) ────────────────────────────────────────────────

  /// 命中测试:指针全局坐标落在哪个敌人头像矩形内 → 返回该 enemyId。
  /// 敌列纵向不重叠,取首个命中即可。纯函数,单测直接验证。
  void _onSkillDragStart(int characterId, SkillDef skill, Offset origin) {
    if (!widget.allowPlayerIntervention) return;
    setState(() {
      _dragSkill = skill;
      _dragCharId = characterId;
      _dragOrigin = origin;
      _dragPointer = origin;
      _hoveredEnemyId = null;
    });
  }

  void _onSkillDragUpdate(Offset pointer) {
    if (_dragSkill == null) return;
    setState(() {
      _dragPointer = pointer;
      // aoe 不需指定目标,不做悬停高亮;single 实时高亮命中敌头像。
      _hoveredEnemyId = _dragSkill!.targetType == TargetType.single
          ? hitTestEnemyId(pointer, _collectEnemyTargets())
          : null;
    });
  }

  void _onSkillDragEnd(Offset pointer) {
    final skill = _dragSkill;
    final charId = _dragCharId;
    _clearDrag();
    if (skill == null || charId == null) return;
    if (skill.targetType == TargetType.aoe) {
      // aoe:忽略落点,直接触发(目标走 AI/全体)。
      _onSkillCommand(charId, skill);
      return;
    }
    // single:必须命中某敌头像才下发,指定该 targetId;未命中则取消。
    final hit = hitTestEnemyId(pointer, _collectEnemyTargets());
    if (hit != null) _onSkillCommand(charId, skill, targetId: hit);
  }

  void _onSkillDragCancel() => _clearDrag();

  void _clearDrag() {
    setState(() {
      _dragSkill = null;
      _dragCharId = null;
      _dragOrigin = null;
      _dragPointer = null;
      _hoveredEnemyId = null;
    });
  }

  /// 收集存活敌人头像的全局矩形(供 hitTest)。死亡 / 未挂载的槽跳过。
  List<({int enemyId, Rect rect})> _collectEnemyTargets() {
    final s = ref.read(battleProvider);
    final targets = <({int enemyId, Rect rect})>[];
    for (
      var i = 0;
      i < s.rightTeam.length && i < _enemyAvatarKeys.length;
      i++
    ) {
      final enemy = s.rightTeam[i];
      if (!enemy.isAlive) continue;
      final ctx = _enemyAvatarKeys[i].currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      targets.add((enemyId: enemy.characterId, rect: topLeft & box.size));
    }
    return targets;
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
    final diagnosis = result == BattleResult.leftWin ? null : _safeDiagnose(s);

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
        diagnosis: diagnosis,
        onJump: (target) => _handleDiagnosisJump(s, target),
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

  /// 算败北诊断；numbersConfig 未就绪（如不加载 GameRepository 的轻量 widget
  /// test）时退化为 null，overlay 仍正常弹出（仅无诊断块）。诊断是非关键 UI。
  BattleDiagnosis? _safeDiagnose(BattleState s) {
    try {
      return BattleDiagnosis.from(
        s,
        ref.read(numbersConfigProvider).battleReport,
      );
    } catch (_) {
      return null;
    }
  }

  /// 诊断建议跳转：叠在胜负 overlay 之上 push 目标 screen，
  /// 返回后玩家仍可按「继续」。characterId 取玩家主控角色（slot 最小）。
  void _handleDiagnosisJump(BattleState s, DiagnosisJumpTarget target) {
    final playerId = s.leftTeam.isEmpty
        ? 0
        : s.leftTeam
              .reduce((a, b) => a.slotIndex <= b.slotIndex ? a : b)
              .characterId;
    final Widget screen = switch (target) {
      DiagnosisJumpTarget.skills => CangJingGeScreen(characterId: playerId),
      DiagnosisJumpTarget.equipment => const InventoryScreen(),
      DiagnosisJumpTarget.cultivation => TechniquePanelScreen(
        characterId: playerId,
      ),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────────────

  static int _slotKey(int teamSide, int slotIndex) => teamSide * 3 + slotIndex;

  /// 战场比例坐标（0..1）：左队 x=0.12 / 右队 x=0.88；竖直按队伍人数 [teamSize]
  /// 均分(见 [slotVerticalFraction]):1 怪居中 / 2 怪对称 / 3 怪 1/6,3/6,5/6。
  /// 弹道层在 LayoutBuilder 内解析为像素，避免依赖 RenderBox（widget test 稳定）。
  static Offset _slotFrac(int teamSide, int slotIndex, int teamSize) {
    final x = teamSide == 0 ? 0.12 : 0.88;
    return Offset(x, slotVerticalFraction(slotIndex, teamSize));
  }

  /// 取某队当前人数(供 [_slotFrac] 竖直均分)。死亡单位保留在队列(灰显)故长度稳定。
  int _teamSizeOf(int teamSide) {
    final s = ref.read(battleProvider);
    return teamSide == 0 ? s.leftTeam.length : s.rightTeam.length;
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
      // 1. 启动 Timer：team 从空 → 非空且未结束 → 自动连续播放(Phase 3:战斗
      //    永远自动流转,advance() 驱动)。
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

      // 3. actionLog 新增：触发动画（待发态自动随 pendingUltimates 消费而清，
      //    无需本地解除置灰）。
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        final wasRushing = _rushToActorId != null;
        for (final a in newActions) {
          _playAction(a, next);
          // C5:拖招者出手 → 快进结束。
          if (_rushToActorId != null && a.actorId == _rushToActorId) {
            _rushToActorId = null;
          }
        }
        // C5 兜底:拖招者在出手前被击杀 → 其 action 永不入 actionLog,清 rush
        // 防卡死快进(纯表现层,advance 结算不受影响)。
        if (_rushToActorId != null) {
          final rushActor = _findCharacter(_rushToActorId!, next);
          if (rushActor == null || !rushActor.isAlive) {
            _rushToActorId = null;
          }
        }
        // 刚结束快进 → 恢复常速 Timer(战斗未结束且仍在自动播放)。
        if (wasRushing &&
            _rushToActorId == null &&
            _playTimer != null &&
            !next.isFinished) {
          _startTimer();
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
                animation: _closeupCtrl,
                builder: (context, child) {
                  final scale = 1.0 +
                      (widget.animConfig.hitTier.closeupScale - 1.0) *
                          _closeupCtrl.value;
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (ctx, child) {
                    return Transform.translate(
                      offset: screenShakeOffset(
                        t: _shakeCtrl.value,
                        amplitude: _impactShakeAmplitude,
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                  children: [
                    if (widget.hint != null) _HintBanner(hint: widget.hint!),
                    if (widget.cycleHint != null)
                      _CycleHintBanner(hint: widget.cycleHint!),
                    _Header(
                      state: state,
                      onToggleLog: () => setState(() => _logOpen = !_logOpen),
                      onPause: _togglePause,
                      isPaused: _isPaused,
                      onSurrender: widget.onSurrender == null
                          ? null
                          : _confirmSurrender,
                      // 单步按钮仅验收路由(startPaused)渲染;生产挂机恒 null 不出现。
                      onStepOnce: widget.startPaused ? _stepOnce : null,
                    ),
                    _DangerBar(state: state),
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
                            enemyAvatarKeys: _enemyAvatarKeys,
                            hoveredEnemyId: _hoveredEnemyId,
                            rushActorId: _rushToActorId,
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
                    if (widget.allowPlayerIntervention)
                      _CoopBurstPromptBar(state: state),
                    _BottomBar(
                      state: state,
                      focusSlotIndex: _effectiveFocus(state),
                      allowPlayerIntervention: widget.allowPlayerIntervention,
                      onSelectFocus: _onSelectFocus,
                      onShowSkillInfo: _showSkillInfo,
                      onFastForward: _toggleFastForward,
                      isFastForward: _isFastForward,
                      onSkillDragStart: _onSkillDragStart,
                      onSkillDragUpdate: _onSkillDragUpdate,
                      onSkillDragEnd: _onSkillDragEnd,
                      onSkillDragCancel: _onSkillDragCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
            // Phase 4 拖招引导线层(技能按钮锚点 → 指针,流派色笔触)。
            if (_dragOrigin != null &&
                _dragPointer != null &&
                _dragSkill != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _DragGuideLayer(
                    start: _dragOrigin!,
                    end: _dragPointer!,
                    color: WuxiaColors.schoolColor(
                      state.leftTeam
                          .firstWhere(
                            (c) => c.characterId == _dragCharId,
                            orElse: () => state.leftTeam.first,
                          )
                          .school,
                    ),
                  ),
                ),
              ),
            // 调试/验收:预置引导线(拖招手势鼠标合成不出,给 Codex 截新样式)。
            if (widget.debugDragPreview != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _DragGuideLayer(
                    start: widget.debugDragPreview!.origin,
                    end: widget.debugDragPreview!.pointer,
                    color: WuxiaColors.schoolColor(
                      state.leftTeam
                          .firstWhere(
                            (c) =>
                                c.characterId ==
                                widget.debugDragPreview!.dragCharId,
                            orElse: () => state.leftTeam.first,
                          )
                          .school,
                    ),
                  ),
                ),
              ),
            Positioned.fill(child: ScreenFlashOverlay(key: _screenFlashKey)),
            Positioned.fill(
              child: UltimateCaptionOverlay(key: _ultimateCaptionKey),
            ),
            Positioned.fill(child: ImpactGlyphOverlay(key: _impactGlyphKey)),
            if (_logOpen)
              _LogDrawer(
                state: state,
                onClose: () => setState(() => _logOpen = false),
              ),
            // H3 暂停遮罩:战斗未结束且暂停时,轻触任意处或「继续」恢复。
            // 验收路由 startPaused 不挂全屏遮罩——否则会拦截顶栏「单步」点击
            // 并误触发恢复;此模式靠顶栏暂停/继续 + 单步按钮操作。
            if (_isPaused && state.result == null && !widget.startPaused)
              Positioned.fill(child: _PauseOverlay(onResume: _togglePause)),
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

// ─── 江湖记招提示横幅（P1 周目进化 E2）───────────────────────────────────────

class _CycleHintBanner extends StatelessWidget {
  final String hint;
  const _CycleHintBanner({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: const Color(0xFF3A2E00),
      child: Text(
        hint,
        style: const TextStyle(color: Color(0xFFD4A800), fontSize: 12),
      ),
    );
  }
}

// ─── 破绽窗口指令栏提示（第六阶段 Task 5）─────────────────────────────────

/// 指令栏上方薄提示条：右队（敌方）有存活角色处于破绽窗口（staggerTicksRemaining > 0）
/// 时显示「破绽 · 该爆发了」，引导玩家拖招释放爆发技。
///
/// **只读 state**：不触碰 interveneNow / AP / 逻辑速度（红线 §5.5）。
/// 窗口关闭（所有敌方 stagger=0）后自然消失（SizedBox.shrink）。
class _CoopBurstPromptBar extends StatelessWidget {
  final BattleState state;
  const _CoopBurstPromptBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasBreakWindow = state.rightTeam.any(
      (e) => e.isAlive && e.staggerTicksRemaining > 0,
    );
    if (!hasBreakWindow) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('coop_burst_prompt_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.12), // 浅金底，水墨克制
        border: const Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 13,
            color: WuxiaColors.resultHighlight,
          ),
          SizedBox(width: 5),
          Text(
            UiStrings.coopBurstPrompt,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
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
  final VoidCallback onPause;
  final bool isPaused;
  final VoidCallback? onSurrender;

  /// 验收路由(startPaused)专用:暂停态逐步推进。null = 生产挂机不渲染单步按钮。
  final VoidCallback? onStepOnce;
  const _Header({
    required this.state,
    required this.onToggleLog,
    required this.onPause,
    required this.isPaused,
    this.onSurrender,
    this.onStepOnce,
  });

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
          if (state.result == null)
            IconButton(
              key: const ValueKey('battle_pause_toggle'),
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: WuxiaColors.textSecondary,
                size: 20,
              ),
              tooltip: isPaused
                  ? UiStrings.battleResume
                  : UiStrings.battlePause,
              onPressed: onPause,
            ),
          // 验收路由(startPaused)专用单步键:仅 onStepOnce 非空时渲染,生产挂机不出现。
          if (state.result == null && onStepOnce != null)
            IconButton(
              key: const ValueKey('battle_step_once'),
              icon: const Icon(
                Icons.skip_next,
                color: WuxiaColors.textSecondary,
                size: 20,
              ),
              tooltip: UiStrings.battleStepOnce,
              onPressed: onStepOnce,
            ),
          if (state.result == null && onSurrender != null)
            IconButton(
              key: const ValueKey('battle_surrender'),
              icon: const Icon(
                Icons.flag_outlined,
                color: WuxiaColors.textSecondary,
                size: 20,
              ),
              tooltip: UiStrings.battleSurrender,
              onPressed: onSurrender,
            ),
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
          const SizedBox(width: 4),
          const ContextHelpButton(topic: HelpTopic.combatAdvanced, size: 20),
        ],
      ),
    );
  }
}

/// H3 暂停遮罩:半透明罩 +「已暂停」+ 继续(轻触任意处或按钮恢复)。
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onResume,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                color: WuxiaColors.textPrimary,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                UiStrings.battlePausedTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onResume,
                child: const Text(UiStrings.battleResume),
              ),
            ],
          ),
        ),
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
  // Phase 4 拖招:敌头像 hitTest key、当前悬停命中敌 id、快进中的拖招者 id。
  final List<GlobalKey> enemyAvatarKeys;
  final int? hoveredEnemyId;
  final int? rushActorId;

  const _BattleField({
    required this.state,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
    required this.enemyAvatarKeys,
    required this.hoveredEnemyId,
    required this.rushActorId,
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
              avatarKeys: const [],
              hoveredEnemyId: null,
              rushActorId: rushActorId,
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
              avatarKeys: enemyAvatarKeys,
              hoveredEnemyId: hoveredEnemyId,
              rushActorId: null,
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
  // Phase 4 拖招:本队各槽头像 hitTest key(空=不挂,如我方队)、悬停命中敌 id、
  // 快进中的拖招者 id(本队命中则其头像「蓄势」高亮)。
  final List<GlobalKey> avatarKeys;
  final int? hoveredEnemyId;
  final int? rushActorId;

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
    required this.avatarKeys,
    required this.hoveredEnemyId,
    required this.rushActorId,
  });

  @override
  Widget build(BuildContext context) {
    final teamSide = isLeftTeam ? 0 : 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: alignment,
      children: [
        // 2026-06-25:只渲染 team.length 个槽(去掉末尾空占位),Column 等分 → 1 怪
        // 居中 / 2 怪上下对称 / 3 怪不变,与 _slotFrac 的 slotVerticalFraction 同步。
        // P0-2 fix(2026-06-04 Codex 报 RenderFlex overflow @1280×720):每槽包
        // Expanded+FittedBox(scaleDown)——大窗保持原尺寸,最小窗自动等比微缩不溢出;
        // alignment 锁外缘,头像维持 0.12/0.88 与 projectile 比例坐标对齐。
        for (var i = 0; i < team.length; i++)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isLeftTeam
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: _CharacterSlot(
                character: team[i],
                isLeftTeam: isLeftTeam,
                attackController: attackControllers[teamSide * 3 + i],
                slotPopups: popups[teamSide * 3 + i] ?? const [],
                animConfig: animConfig,
                chargeMaxTicks: chargeMaxTicks,
                slotKey: teamSide * 3 + i,
                onPopupComplete: onPopupComplete,
                hitFlashController: hitFlashControllers[teamSide * 3 + i],
                flashColor: hitFlashColors[teamSide * 3 + i] ?? Colors.white,
                avatarKey: i < avatarKeys.length ? avatarKeys[i] : null,
                hovered:
                    hoveredEnemyId != null &&
                    team[i].characterId == hoveredEnemyId,
                charging:
                    rushActorId != null && team[i].characterId == rushActorId,
              ),
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
  // Phase 4 拖招:头像 hitTest key(敌方槽挂,我方 null);拖招悬停命中高亮;
  // 拖招者「蓄势」高亮(等待出手)。
  final GlobalKey? avatarKey;
  final bool hovered;
  final bool charging;

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
    this.avatarKey,
    this.hovered = false,
    this.charging = false,
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
            child: _GlowAura(
              hovered: hovered,
              charging: charging,
              // 第六阶段：staggerTicksRemaining>0 → 破绽集火高亮（绛红脉动）。
              // 仅限敌方（isLeftTeam==false）；我方被硬直不显示集火指示。
              staggered: !isLeftTeam && character.staggerTicksRemaining > 0,
              characterId: character.characterId,
              schoolColor: WuxiaColors.schoolColor(character.school),
              child: CharacterAvatar(
                key: avatarKey,
                character: character,
                chargeMaxTicks: chargeMaxTicks,
              ),
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
/// [_BattleScreenState._effectiveFocus] 自动切到可破招者。拖招走 [BattleNotifier.interveneNow]
/// 立即插队出手（主线二 2.3）。
class _BottomBar extends StatelessWidget {
  final BattleState state;
  final int focusSlotIndex;
  final bool allowPlayerIntervention;
  final void Function(int slotIndex) onSelectFocus;
  // 批次 1.3：点击技能方块 = 弹简介浮层(直接读 SkillDef 活数据),不再裸单击下发。
  // 下发改走拖招(onSkillDragStart/End)。
  final void Function(SkillDef skill) onShowSkillInfo;
  final VoidCallback onFastForward;
  final bool isFastForward;
  // Phase 4 拖招回调(单体技长按拖)。
  final void Function(int characterId, SkillDef skill, Offset origin)
  onSkillDragStart;
  final void Function(Offset pointer) onSkillDragUpdate;
  final void Function(Offset pointer) onSkillDragEnd;
  final VoidCallback onSkillDragCancel;

  const _BottomBar({
    required this.state,
    required this.focusSlotIndex,
    required this.allowPlayerIntervention,
    required this.onSelectFocus,
    required this.onShowSkillInfo,
    required this.onFastForward,
    required this.isFastForward,
    required this.onSkillDragStart,
    required this.onSkillDragUpdate,
    required this.onSkillDragEnd,
    required this.onSkillDragCancel,
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
                            allowPlayerIntervention: allowPlayerIntervention,
                            onPressed: () => onShowSkillInfo(s),
                            onDragStart: (origin) =>
                                onSkillDragStart(focus.characterId, s, origin),
                            onDragUpdate: onSkillDragUpdate,
                            onDragEnd: onSkillDragEnd,
                            onDragCancel: onSkillDragCancel,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _FastForwardButton(onPressed: onFastForward, isActive: isFastForward),
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
  final bool allowPlayerIntervention;
  final VoidCallback onPressed;
  // Phase 4 拖招:长按拖起(origin=按钮中心全局坐标)/ 拖动 / 松手 / 取消。
  final void Function(Offset origin) onDragStart;
  final void Function(Offset pointer) onDragUpdate;
  final void Function(Offset pointer) onDragEnd;
  final VoidCallback onDragCancel;

  const _SkillCommandButton({
    required this.character,
    required this.skill,
    required this.isPending,
    required this.queuedAnother,
    required this.highlight,
    required this.allowPlayerIntervention,
    required this.onPressed,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
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
    final enabled =
        ready && !isPending && !queuedAnother && allowPlayerIntervention;

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
    } else if (character.currentInternalForce < skill.internalForceCost) {
      statusText = UiStrings.skillInsufficientForce; // 内力不足
    } else {
      // 耗内 N · CD M
      statusText = UiStrings.skillCostShort(
        skill.internalForceCost,
        skill.cooldownTurns,
      );
    }

    final button = SizedBox(
      width: 92,
      height: 76,
      child: ElevatedButton(
        key: ValueKey('skill_cmd_${character.characterId}_${skill.id}'),
        // 批次 1.3:点击 = 弹简介浮层(始终可读,CD/内力不足/待发态亦可看)。
        // 下发改走长按拖招(见下方 GestureDetector / `enabled` 仅门控拖招)。
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // 批次 1.3:onPressed 恒非空(点击始终可弹简介),故禁用视觉不再靠
          // disabled* 兜底——背景已由 bgColor(!ready→buttonDisabled)表达,
          // 前景按 enabled 手动切 muted/primary 保留「不可下发」灰态观感。
          backgroundColor: bgColor,
          foregroundColor: enabled
              ? WuxiaColors.textPrimary
              : WuxiaColors.textMuted,
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

    // 未到可下发态(门控关 / 内力不足 / CD / 已待发)不挂拖招手势;
    // 但点击弹简介浮层始终可用(button.onPressed 恒非空)。
    if (!enabled) return button;

    // 长按拖起 → 进入拖招态;松手在敌头像上=指定目标(单体)或直接触发(群体)。
    // 用长按手势(非 onPan)规避与底栏横向滚动的手势竞争。
    return GestureDetector(
      onLongPressStart: (details) {
        final box = context.findRenderObject();
        final origin = (box is RenderBox && box.hasSize)
            ? box.localToGlobal(box.size.center(Offset.zero))
            : details.globalPosition;
        onDragStart(origin);
      },
      onLongPressMoveUpdate: (d) => onDragUpdate(d.globalPosition),
      onLongPressEnd: (d) => onDragEnd(d.globalPosition),
      onLongPressCancel: onDragCancel,
      child: button,
    );
  }
}

/// 批次 1.3:技能简介浮层正文(直接读 [SkillDef] 活数据)。
/// 描述 + 字段表(类型/目标/倍率/耗内/冷却/特性)+ 拖招提示。
/// 不走 HelpCatalog/CodexIndex,纯活数据 + [EnumL10n] 枚举显示名。
class _SkillInfoBody extends StatelessWidget {
  final SkillDef skill;
  const _SkillInfoBody({required this.skill});

  static String _traitText(SkillDef s) {
    if (s.canInterrupt) return UiStrings.skillTraitInterrupt; // 破招(可打断蓄力)
    return UiStrings.skillTraitNone; // 无
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (UiStrings.skillInfoType, EnumL10n.skillType(skill.type)),
      (UiStrings.skillInfoTarget, EnumL10n.targetType(skill.targetType)),
      (UiStrings.skillInfoPower, '${skill.powerMultiplier}'),
      (UiStrings.skillInfoCost, '${skill.internalForceCost}'),
      (
        UiStrings.skillInfoCooldown,
        UiStrings.skillInfoCooldownTurns(skill.cooldownTurns),
      ),
      (UiStrings.skillInfoTrait, _traitText(skill)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 描述活文本(SkillDef.description)。
        Text(
          skill.description,
          style: const TextStyle(color: WuxiaUi.ink, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 14),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: WuxiaUi.muted,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          UiStrings.skillInfoDragHint,
          style: TextStyle(color: WuxiaUi.qing, fontSize: 11, letterSpacing: 1),
        ),
      ],
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

/// Phase 4 拖招表现层:角色头像光晕。
/// - [hovered](拖招悬停命中敌头像):静态浅金强光,优先级最高。
/// - [charging](拖招者蓄势待发):流派色呼吸脉动(AnimationController 往返),
///   区分于快进态,让「蓄势」有生命感。
/// - 均不满足:无光晕,直接返回 child(等价旧 boxShadow 为空)。
class _GlowAura extends StatefulWidget {
  final bool hovered;
  final bool charging;
  // 第六阶段：破绽窗口集火指示（staggerTicksRemaining>0）。
  final bool staggered;
  // 用于给破绽高亮 DecoratedBox 挂 Key，供 widget 测查找。
  final int characterId;
  final Color schoolColor;
  final Widget child;
  const _GlowAura({
    required this.hovered,
    required this.charging,
    required this.staggered,
    required this.characterId,
    required this.schoolColor,
    required this.child,
  });

  @override
  State<_GlowAura> createState() => _GlowAuraState();
}

class _GlowAuraState extends State<_GlowAura>
    with SingleTickerProviderStateMixin {
  // eager 初始化(非 late):懒初始化会在非蓄势 slot 的 dispose() 才首次构造,
  // 此时树已 deactivate → createTicker 查 TickerMode 崩溃。
  late final AnimationController _pulse;

  // hovered 优先级最高(静态强光),只有「蓄势且未被悬停」才脉动。
  // 第六阶段：破绽窗口也驱动呼吸（绛红集火），优先级低于 hovered/charging。
  bool get _pulsing => (widget.charging || widget.staggered) && !widget.hovered;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    if (_pulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_GlowAura old) {
    super.didUpdateWidget(old);
    if (_pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_pulsing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 浅金静态强光(hovered) 优先;蓄势流派色呼吸次之;
    // 第六阶段：破绽窗口绛红脉动（集火指示）再次；都无则裸 child。
    if (widget.hovered) {
      return _box(WuxiaColors.resultHighlight, 0.85, 22.0, 4.0, widget.child);
    }
    if (!widget.charging && !widget.staggered) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        if (widget.charging) {
          // 蓄势流派色呼吸脉动（原有逻辑）。
          return _box(
            widget.schoolColor,
            0.45 + 0.4 * t, // alpha 0.45 → 0.85
            13.0 + 9.0 * t, // blur 13 → 22
            1.5 + 2.0 * t, // spread 1.5 → 3.5
            child!,
          );
        }
        // 破绽窗口：绛红呼吸脉动（集火指示），水墨克制——稍弱于蓄势强光。
        return KeyedSubtree(
          key: ValueKey('stagger_highlight_${widget.characterId}'),
          child: _box(
            WuxiaColors.gangMeng, // 绛红 = WuxiaColors.gangMeng（刚猛流派色 / 攻击色）
            0.35 + 0.35 * t, // alpha 0.35 → 0.70（克制，不刺眼）
            10.0 + 8.0 * t, // blur 10 → 18
            1.0 + 1.5 * t, // spread 1.0 → 2.5
            child!,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _box(
    Color color,
    double alpha,
    double blur,
    double spread,
    Widget child,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Phase 4 拖招引导线层:从技能按钮锚点到当前指针的流派色笔触线(实时跟手)。
/// 纯表现层,IgnorePointer 不拦手势(手势由按钮的 LongPress 识别器持有)。
class _DragGuideLayer extends StatelessWidget {
  final Offset start;
  final Offset end;
  final Color color;
  const _DragGuideLayer({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DragGuidePainter(start: start, end: end, color: color),
    );
  }
}

class _DragGuidePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  _DragGuidePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 外发光层(柔和辉光,克制水墨)→ 主线(流派色)→ 末端落点(外环辉光 + 实心点 + 白心)。
    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawLine(start, end, glow);
    final line = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, line);
    // 末端落点:外环辉光提亮 + 实心点 + 白色高光心(强化指引落点可读性)。
    final endGlow = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(end, 11.0, endGlow);
    final dot = Paint()..color = color.withValues(alpha: 0.95);
    canvas.drawCircle(end, 7.0, dot);
    final core = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(end, 2.5, core);
  }

  @override
  bool shouldRepaint(_DragGuidePainter old) =>
      old.start != start || old.end != end || old.color != color;
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
