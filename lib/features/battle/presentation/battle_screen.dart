import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_log.dart';
import '../domain/battle_state.dart';
import '../domain/battle_stats.dart';
import '../domain/battle_diagnosis.dart';
import '../domain/damage_calculator.dart';
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
import 'battle_atmosphere_overlay.dart';
import 'battle_scene_background.dart';
import 'damage_popup.dart';
import 'boss_phase_presentation.dart';
import 'guardian_ward_presentation.dart';
import 'impact_profile.dart';
import 'impact_glyph_overlay.dart';
import 'screen_flash.dart';
import 'ultimate_caption_overlay.dart';
import 'victory_overlay.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../../settings/domain/gameplay_settings.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../domain/battle_skill_utils.dart';
import 'battle_vfx_entries.dart';
import 'widgets/battle_banners.dart';
import 'widgets/battle_header.dart';
import 'widgets/battle_field.dart';
import 'widgets/battle_bottom_bar.dart';
import 'widgets/battle_vfx_layers.dart';
import 'widgets/battle_target_chips.dart';

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
/// 队列内某槽的竖直比例坐标(0..1),按**实际队伍人数** [teamSize] 均分:
///   1 人 → 0.5(居中);2 人 → 0.25 / 0.75(上下对称);3 人 → 1/6,3/6,5/6(原行为)。
///
/// `TeamColumn` 的视觉排布与 `_slotFrac` 的弹道坐标共用此式,保证头像位置与
/// 弹道/特效落点一致(分母从旧的硬编码 3 改为 teamSize 是本次「1 怪居中 / 2 怪对称」
/// 的唯一改动点)。teamSize ≤ 0 兜底 0.5 防除零。纯函数,单测直接验证。
double slotVerticalFraction(int slotIndex, int teamSize) {
  if (teamSize <= 0) return 0.5;
  return (slotIndex + 0.5) / teamSize;
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

  /// 战斗交互重做 Phase 3:本场是否允许玩家手动干预(host 由 [resolveAutoPlayMode]
  /// → `AutoPlayMode.interactive` 算出注入)。**Phase 3 暂无可见行为差异**(战斗
  /// 无论如何都自动连续播放);Phase 4 拖招层将以此门控技能栏 GestureDetector /
  /// 引导线 —— `false` = 纯挂机不挂拖招层。
  final bool allowPlayerIntervention;

  /// 仅验收路由用(默认 false → 生产/现有调用零影响):起手即暂停,战斗冻结在
  /// startBattle seed 初态(timer 因 _isPaused 不启,与 [autoStart] 兼容)。
  /// **为 true 时**头栏额外渲染「单步」按钮(逐步推进战斗,供验收者点选技能/看
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

  /// Debug/visual preview only:初始渲染一个纯 presentation 待发态。
  /// 只驱动按钮「待发」印与敌头像可选高亮,不写 [BattleState.pendingUltimates]。
  final int? previewPendingCharacterId;
  final String? previewPendingSkillId;

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
    this.startPaused = false,
    this.startFastForward = false,
    this.autoStartOnMount = false,
    this.previewPendingCharacterId,
    this.previewPendingSkillId,
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

  // 读秒圆环节拍 controller（本拍内 0→1，供 CD/蓄力/破绽环平滑插值）。
  // 随 _playTimer 每拍 forward(from:0) 对齐 remaining 递减，暂停/待发/结束时 stop 冻结。
  late final AnimationController _beatCtrl;

  // 6 个受击闪 controller（slotKey 索引；静止 value=1.0 → 不显，命中 forward(from:0) 淡出）。
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

  // ─── 两段点选 tap 释放 ───────────────────────────────────────────────────
  // 待发态(纯 UI,不写 BattleState):已点选待发的单体技与其角色 charId。
  // null = 无待发。AOE 不进待发态(点按钮直接出手)。
  SkillDef? _pendingSkill;
  int? _pendingCharId;
  int? _hoveredPendingEnemyId;

  // 技能目标选择栏锚点:待发单体技的技能格 ↔ 其上方浮出的敌人快捷选择栏。
  final LayerLink _skillTargetLink = LayerLink();

  bool get _pendingActive =>
      _pendingSkill != null ||
      (widget.previewPendingCharacterId != null &&
          widget.previewPendingSkillId != null);

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
        milliseconds: widget.animConfig.hitTier.closeupPulseMs,
      ),
    );
    _hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        value: 1.0, // 静止满值 → HitFlash alpha=0 不显
        duration: Duration(milliseconds: widget.animConfig.hitFlashMs),
      ),
    );
    _beatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animConfig.actionIntervalMs),
    );
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
        if (!mounted || !widget.autoStart || _isPaused || _playTimer != null) {
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
    _beatCtrl.dispose();
    super.dispose();
  }

  // ─── Timer / advance 驱动 ────────────────────────────────────────────────

  void _startTimer() {
    // 任何显式启动都作废挂起的 hit-stop 复播（避免快进/暂停切换撞 hit-stop 时
    // stale timer 二次 _startTimer 致节拍抖动）。
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
        ? widget.animConfig.fastForwardIntervalMs
        : gameplaySettings.scaledBattleIntervalMs(
            widget.animConfig.actionIntervalMs,
          );
    // 读秒环节拍:与每拍对齐（本拍内 0→1，供环平滑插值）。起手先扫第一拍，
    // 之后每次 advance 回调里 forward(from:0) 重启，使 remaining 递减与环无缝续扫。
    _beatCtrl
      ..duration = Duration(milliseconds: interval)
      ..forward(from: 0);
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      _beatCtrl.forward(from: 0);
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
    if (_pendingSkill != null) {
      _clearPending(); // 待发态下按暂停 = 取消待发(已恢复 tick),不额外进手动暂停
      return;
    }
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _playTimer?.cancel();
      _beatCtrl.stop(); // 手动暂停冻结读秒环节拍。
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
    final actor = findCharacter(action.actorId, s);
    if (actor != null) {
      final key = slotKey(actor.teamSide, actor.slotIndex);
      _attackControllers[key].forward(from: 0.0);
    }
    if (action.attackResult != null && action.targetId != null) {
      final target = findCharacter(action.targetId!, s);
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
              isKey: BattleLog.isKeyAction(action, s),
              profileHitStopMs: profile.hitStopMs,
              keyMomentHoldMs: widget.animConfig.keyMomentHoldMs,
            ),
          );
        }
      }
    }

    // 命中特写：仅峰值（大招暴击/击杀），快进/扫荡抑制（守在线=离线）。
    // 独立于 profile != null 块：普攻击杀无 profile 也须触发特写。
    if (!_isFastForward && hitClimaxFor(action, s) != HitClimax.none) {
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

  /// floor30 护法结界（Task 6）破界演出：结界失效边沿（最后一名护法阵亡）
  /// → 题字 + 闪白。复用 [_playBossPhaseTransition] 同一套题字 / 闪白通道
  /// （[_ultimateCaptionKey] + [_screenFlashKey]），不另起平行系统；不触发
  /// hit-stop / 抖动（非打击命中，护法之死已由其自身死亡动画表现）。
  /// 纯读 [boss] 元数据，不写 BattleState（守 §5.4）。
  void _playGuardianWardBreak(BattleCharacter boss) {
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

  /// 读打击感配置；GameRepository 未初始化（轻量 widget 测）时返 null 跳过。
  ImpactFeedbackConfig? _impactConfigOrNull() {
    try {
      return ref.read(numbersConfigProvider).combat.impactFeedback;
    } catch (_) {
      return null;
    }
  }

  GameplaySettings get _currentGameplaySettings => ref
      .read(gameplaySettingsProvider)
      .maybeWhen(data: (s) => s, orElse: () => const GameplaySettings());

  bool get _reduceFlashing => _currentGameplaySettings.reduceFlashing;

  /// 当前播放拍间隔(ms):快进态走 fastForwardIntervalMs,否则按玩家速度档缩放
  /// actionIntervalMs(与 [_startTimer] 同源口径)。供飘字 spawn 时 clamp 时长,
  /// 防快档(rapid/快进)固定 damagePopupMs 超拍致跨拍重叠。
  int get _currentPlaybackIntervalMs => _isFastForward
      ? widget.animConfig.fastForwardIntervalMs
      : _currentGameplaySettings.scaledBattleIntervalMs(
          widget.animConfig.actionIntervalMs,
        );

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
    if (_reduceFlashing) return;
    final key = slotKey(target.teamSide, target.slotIndex);
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
    final key = slotKey(target.teamSide, target.slotIndex);
    final data = _buildPopupData(result, attacker);
    final entry = PopupEntry(
      id: _nextPopupId++,
      data: data,
      popupDurationMs: widget.animConfig.effectivePopupMs(
        _currentPlaybackIntervalMs,
      ),
    );
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

  /// 玩家点选技能 → 调 [BattleNotifier.interveneNow] 立即插队出手(预支 AP 归零)。
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
    if (c == null || !isSkillReady(c, skill)) return;
    // 主线二 2.3:即放·真插队——立即出手(预支 AP 归零),不再标记 pending+C5 快进。
    ref
        .read(battleProvider.notifier)
        .interveneNow(characterId, skill, targetId: targetId);
    setState(() {}); // 反映出手
  }

  /// 批次 1.3:点击技能方块 → 弹简介浮层(直接读 [SkillDef] 活数据)。
  /// 不下发命令;CD/内力不足态也可点开查看。
  void _showSkillInfo(SkillDef skill) {
    PaperDialog.show<void>(
      context,
      title: skill.name,
      body: SkillInfoBody(skill: skill),
      actions: [
        PlaqueButton(
          label: UiStrings.skillInfoClose,
          onTap: () => Navigator.of(context).pop(),
          primary: true,
        ),
      ],
    );
  }

  // ─── 两段点选 tap 释放 ───────────────────────────────────────────────────

  /// 点技能按钮:single → 进待发态(软暂停);aoe → 直接出手。
  /// 待发态下再点同一技能 = 取消。
  void _onSkillTap(int characterId, SkillDef skill) {
    if (!widget.allowPlayerIntervention) return;
    final s = ref.read(battleProvider);
    BattleCharacter? c;
    for (final ch in s.leftTeam) {
      if (ch.characterId == characterId) {
        c = ch;
        break;
      }
    }
    if (c == null || !isSkillReady(c, skill)) return;
    // 待发态下再点同一技能 = 取消。
    if (skill.targetType != TargetType.aoe &&
        _pendingSkill?.id == skill.id &&
        _pendingCharId == characterId) {
      _clearPending();
      return;
    }
    if (skill.targetType == TargetType.aoe) {
      if (_pendingSkill != null) _clearPending(); // 清掉残留 single 待发态,恢复 tick
      _onSkillCommand(characterId, skill); // 一键即放,AI 选目标
      return;
    }
    // single:按存活敌人数分流。
    final aliveEnemies = s.rightTeam
        .where((e) => e.isAlive)
        .toList(growable: false);
    if (aliveEnemies.isEmpty) return; // 战斗已结束,守卫。
    if (aliveEnemies.length == 1) {
      // 唯一敌人 → 点击即放:不进待发/不暂停/不选目标。
      if (_pendingSkill != null) _clearPending();
      _onSkillCommand(
        characterId,
        skill,
        targetId: aliveEnemies.first.characterId,
      );
      return;
    }
    // ≥2 敌:进待发态 + 软暂停(选择栏在技能格上方冒出,右侧头像亦可点)。
    setState(() {
      _pendingSkill = skill;
      _pendingCharId = characterId;
      _isPaused = true;
    });
    _playTimer?.cancel();
    _beatCtrl.stop(); // 待发软暂停冻结读秒环节拍。
  }

  /// 待发态下点敌头像 → 对该敌出手 + 解除待发态 + 恢复 tick。
  void _onEnemyTap(int enemyId) {
    final skill = _pendingSkill;
    final charId = _pendingCharId;
    if (skill == null || charId == null) return;
    _clearPending();
    _onSkillCommand(charId, skill, targetId: enemyId);
  }

  /// 解除待发态并恢复自动播放(取消 / 出手后共用)。
  void _clearPending() {
    setState(() {
      _pendingSkill = null;
      _pendingCharId = null;
      _hoveredPendingEnemyId = null;
      _isPaused = false;
    });
    if (!ref.read(battleProvider).isFinished) _startTimer();
  }

  void _onPendingEnemyHover(int enemyId, bool hovering) {
    if (!_pendingActive) return;
    setState(() {
      _hoveredPendingEnemyId = hovering ? enemyId : null;
    });
  }

  /// 待发单体技的技能格上方浮出敌人快捷选择栏(仅 ≥2 存活敌人;1 敌走点击即放
  /// 不进待发,不会到这里)。锚定被点技能格,右侧头像选目标通道并存。
  Widget _buildTargetChipOverlay(BattleState state) {
    final aliveEnemies = state.rightTeam
        .where((e) => e.isAlive)
        .toList(growable: false);
    if (aliveEnemies.length < 2) return const SizedBox.shrink();
    return CompositedTransformFollower(
      link: _skillTargetLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.topCenter,
      followerAnchor: Alignment.bottomCenter,
      offset: const Offset(0, -8),
      child: TargetChipStrip(
        enemies: aliveEnemies,
        hoveredEnemyId: _hoveredPendingEnemyId,
        onSelect: _onEnemyTap,
        onHover: _onPendingEnemyHover,
      ),
    );
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
        if (k != null && isSkillReady(c, k)) return i;
      }
    }
    if (_focusSlotIndex >= 0 && _focusSlotIndex < s.leftTeam.length) {
      return _focusSlotIndex;
    }
    return 0;
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
      DiagnosisJumpTarget.roster => CharacterPanelScreen(characterId: playerId),
      DiagnosisJumpTarget.supplies => const InventoryScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────────────

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
    // 破绽窗口时长(供破绽读秒环分母)；GameRepository 未初始化时回落 schema 默认 3。
    int staggerWindowTicks;
    try {
      staggerWindowTicks = ref
          .read(numbersConfigProvider)
          .combat
          .defenseBreak
          .windowTicks;
    } catch (_) {
      staggerWindowTicks = 3;
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
        _beatCtrl.stop(); // 战斗结束冻结读秒环节拍。
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

      // 5. floor30 护法结界（Task 6）破界：结界失效边沿（最后一名护法阵亡）
      //    → 题字 + 闪白。纯读 state 边沿触发，不入 domain（守 §5.4）。
      final wardBreakIds = guardianWardBreakEvents(prev, next);
      if (wardBreakIds.isNotEmpty) {
        for (final c in [...next.leftTeam, ...next.rightTeam]) {
          if (wardBreakIds.contains(c.characterId)) {
            _playGuardianWardBreak(c);
          }
        }
      }
    });

    ref.listen(gameplaySettingsProvider, (_, _) {
      final s = ref.read(battleProvider);
      if (_playTimer != null && !s.isFinished) _startTimer();
    });

    // team 空时（startBattle 还未调用）渲染 placeholder
    if (state.leftTeam.isEmpty && state.rightTeam.isEmpty) {
      return BgmScope(
        track: widget.bgmTrack,
        child: const Scaffold(
          backgroundColor: WuxiaColors.background,
          body: Center(
            child: InkLoadingIndicator(color: WuxiaColors.textMuted),
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
              child: BattleSceneBackground(
                path: widget.sceneBackgroundPath,
                style: _backgroundStyleForTrack(widget.bgmTrack),
              ),
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
                  final scale =
                      1.0 +
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
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape &&
                          _pendingActive) {
                        _clearPending();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_pendingActive) _clearPending();
                      },
                      child: Column(
                        children: [
                          if (widget.hint != null)
                            HintBanner(hint: widget.hint!),
                          if (widget.cycleHint != null)
                            CycleHintBanner(hint: widget.cycleHint!),
                          Header(
                            state: state,
                            onToggleLog: () =>
                                setState(() => _logOpen = !_logOpen),
                            onPause: _togglePause,
                            isPaused: _isPaused,
                            onSurrender: widget.onSurrender == null
                                ? null
                                : _confirmSurrender,
                            // 单步按钮仅验收路由(startPaused)渲染;生产挂机恒 null 不出现。
                            onStepOnce: widget.startPaused ? _stepOnce : null,
                          ),
                          DangerBar(state: state),
                          Expanded(
                            child: Stack(
                              children: [
                                BattleField(
                                  state: state,
                                  attackControllers: _attackControllers,
                                  popups: _popups,
                                  animConfig: widget.animConfig,
                                  chargeMaxTicks: chargeMaxTicks,
                                  beat: _beatCtrl,
                                  staggerWindowTicks: staggerWindowTicks,
                                  onPopupComplete: _removePopup,
                                  hitFlashControllers: _hitFlashControllers,
                                  hitFlashColors: _hitFlashColors,
                                  onEnemyTap: _onEnemyTap,
                                  pendingActive: _pendingActive,
                                  hoveredEnemyId: _hoveredPendingEnemyId,
                                  onEnemyHover: _onPendingEnemyHover,
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: ProjectileLayer(
                                      trails: _activeTrails,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: EffectLayer(
                                      effects: _activeEffects,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BattleReportStrip(
                            state: state,
                            onTap: () => setState(() => _logOpen = true),
                          ),
                          if (widget.allowPlayerIntervention)
                            CoopBurstPromptBar(state: state),
                          BottomBar(
                            state: state,
                            focusSlotIndex: _effectiveFocus(state),
                            allowPlayerIntervention:
                                widget.allowPlayerIntervention,
                            onSelectFocus: _onSelectFocus,
                            onShowSkillInfo: _showSkillInfo,
                            onFastForward: _toggleFastForward,
                            isFastForward: _isFastForward,
                            onSkillTap: _onSkillTap,
                            pendingCharacterId:
                                _pendingCharId ??
                                widget.previewPendingCharacterId,
                            pendingSkillId:
                                _pendingSkill?.id ??
                                widget.previewPendingSkillId,
                            beat: _beatCtrl,
                            skillTargetLink: _skillTargetLink,
                          ),
                        ],
                      ),
                    ),
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
              LogDrawer(
                state: state,
                onClose: () => setState(() => _logOpen = false),
              ),
            // H3 暂停遮罩:战斗未结束且暂停时,轻触任意处或「继续」恢复。
            // 验收路由 startPaused 不挂全屏遮罩——否则会拦截顶栏「单步」点击
            // 并误触发恢复;此模式靠顶栏暂停/继续 + 单步按钮操作。
            // 待发态(_pendingActive)的软暂停不挂遮罩——否则会拦截点敌头像
            // 选目标的 tap;待发态靠再点同一技能 / 空白点击 / ESC 取消。
            if (_isPaused &&
                !_pendingActive &&
                state.result == null &&
                !widget.startPaused)
              Positioned.fill(child: PauseOverlay(onResume: _togglePause)),
            // 单体技待发 + ≥2 存活敌人:技能格正上方浮出快捷选择栏。
            if (_pendingActive) _buildTargetChipOverlay(state),
          ],
        ),
      ),
    );
  }
}

BattleSceneBackgroundStyle _backgroundStyleForTrack(BgmTrack track) {
  switch (track) {
    case BgmTrack.tower:
      return BattleSceneBackgroundStyle.tower;
    case BgmTrack.boss:
      return BattleSceneBackgroundStyle.boss;
    case BgmTrack.innerDemon:
      return BattleSceneBackgroundStyle.innerDemon;
    case BgmTrack.lightFoot:
      return BattleSceneBackgroundStyle.lightFoot;
    case BgmTrack.massBattle:
      return BattleSceneBackgroundStyle.massBattle;
    case BgmTrack.mainline:
      return BattleSceneBackgroundStyle.mainline;
    case BgmTrack.battle:
    case BgmTrack.mainMenu:
    case BgmTrack.seclusion:
    case BgmTrack.lineage:
    case BgmTrack.baike:
      return BattleSceneBackgroundStyle.generic;
  }
}

