import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_state.dart';
import '../domain/battle_stats.dart';
import '../domain/battle_diagnosis.dart';
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
import 'battle_atmosphere_overlay.dart';
import 'battle_scene_background.dart';
import 'guardian_ward_presentation.dart';
import 'impact_glyph_overlay.dart';
import 'screen_flash.dart';
import 'ultimate_caption_overlay.dart';
import 'victory_overlay.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../domain/battle_skill_utils.dart';
import 'battle_playback_controller.dart';
import 'widgets/battle_banners.dart';
import 'widgets/battle_header.dart';
import 'widgets/battle_field.dart';
import 'widgets/battle_bottom_bar.dart';
import 'widgets/battle_vfx_layers.dart';
import 'widgets/battle_target_chips.dart';

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
///
/// 竖直槽位比例坐标 `slotVerticalFraction` 已移到
/// `domain/battle_skill_utils.dart`（纯 Dart 数学，破 controller↔screen 循环 import）。
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

  /// 首通可读节奏:只影响表现层常速播放,不改战斗结算。主线首通打开后会放慢
  /// 行动拍间隔并在胜利交接前留一个短停顿,让 1-3 拍速胜也能看清最后一击。
  final bool readablePacing;

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
    this.readablePacing = false,
    this.autoStartOnMount = false,
    this.previewPendingCharacterId,
    this.previewPendingSkillId,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  static const Duration _readableVictoryHandoffDelay = Duration(
    milliseconds: 1200,
  );

  // VFX 反应原语（飘字/弹道/特效贴片/攻击-受击闪 controller，Task 1）+ 拍钟调度
  // （beat/timer/hit-stop/pause/fast-forward，Task 2）+ overlay 编排/屏震
  // （shake/closeup/overlay keys，Task 3）：均已抽到 BattlePlaybackController，
  // rebuild 用 setState 保持重绘粒度不变。
  late final BattlePlaybackController _playback;

  // T1 指令台：当前"重点角色"槽位（玩家手动选定的基线）。敌人蓄力时由
  // [_effectiveFocus] 临时覆盖到可破招者，但不改写这个手动基线。
  // 技能"待发"态直接读 [BattleState.pendingUltimates]（domain 单一真相源），
  // 不再维护本地置灰 set——引擎消费后自动清，按钮印随之消失。
  int _focusSlotIndex = 0;

  // 日志折叠抽屉开关（P0-2 Task6）：本地 UI state，不污染 BattleState。
  bool _logOpen = false;

  // 战斗结算 dialog 已显示标志，避免 result 字段连续触发多次弹窗
  bool _resultDialogShown = false;

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
    _playback = BattlePlaybackController(
      vsync: this,
      ref: ref,
      rebuild: setState,
      animConfig: widget.animConfig,
      startPaused: widget.startPaused,
      startFastForward: widget.startFastForward,
      readablePacing: widget.readablePacing,
    );
    // _beatCtrl / _isPaused / _isFastForward 初值由 _playback 构造器据
    // startPaused / startFastForward 处理（Task 2）。
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
            _playback.isPaused ||
            _playback.hasTimer) {
          return;
        }
        final s = ref.read(battleProvider);
        if (s.leftTeam.isNotEmpty && !s.isFinished) _playback.startTimer();
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
    _playback.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readablePacing != widget.readablePacing) {
      _playback.setReadablePacing(widget.readablePacing);
    }
  }

  // ─── Timer / advance 驱动 ────────────────────────────────────────────────

  // H3 暂停:停 tick(_playback.startTimer 内 _isPaused gate 兜住所有重启路径);
  // 恢复时若战斗未结束则重启自动播放。拍钟本体在 BattlePlaybackController（Task 2）;
  // 此处只保留「待发态优先取消」的交互分流,其余委托 _playback.pause/resume。
  void _togglePause() {
    if (_pendingSkill != null) {
      _clearPending(); // 待发态下按暂停 = 取消待发(已恢复 tick),不额外进手动暂停
      return;
    }
    if (_playback.isPaused) {
      _playback.resume();
    } else {
      _playback.pause();
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
    });
    _playback.pause(); // 待发软暂停:置暂停 + 停 tick + 冻结读秒环节拍。
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
    });
    _playback.resume(); // 解除软暂停 + 战斗未结束则重启自动播放。
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

  Future<void> _showResultDialogAfterPacing(
    BattleResult result,
    BattleState s,
  ) async {
    if (widget.readablePacing && result == BattleResult.leftWin) {
      await Future<void>.delayed(_readableVictoryDelayFor(s));
    }
    if (!mounted) return;
    _showResultDialog(result, s);
  }

  Duration _readableVictoryDelayFor(BattleState s) {
    final shownMs = s.actionLog.length * _playback.playbackIntervalMsForTest;
    final minVisibleMs = widget.animConfig.readableVictoryMinMs;
    final fillMs = minVisibleMs > shownMs ? minVisibleMs - shownMs : 0;
    final handoffMs = _readableVictoryHandoffDelay.inMilliseconds;
    return Duration(milliseconds: fillMs > handoffMs ? fillMs : handoffMs);
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
        _playback.startTimer();
      }

      // 2. 战斗结束：停 timer + 弹结算 dialog（postFrame 避免 build 期 setState）
      if ((prev?.result == null) && next.result != null) {
        _playback.onBattleFinished(); // 停 timer + 冻结读秒环节拍。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_showResultDialogAfterPacing(next.result!, next));
          }
        });
      }

      // 3. actionLog 新增：触发动画（待发态自动随 pendingUltimates 消费而清，
      //    无需本地解除置灰）。
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        for (final a in newActions) {
          _playback.playAction(a, next);
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
            _playback.playGuardianWardBreak(c);
          }
        }
      }
    });

    ref.listen(gameplaySettingsProvider, (_, _) {
      _playback.onGameplaySettingsChanged();
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
                animation: _playback.closeupCtrl,
                builder: (context, child) {
                  final scale =
                      1.0 +
                      (widget.animConfig.hitTier.closeupScale - 1.0) *
                          _playback.closeupCtrl.value;
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedBuilder(
                  animation: _playback.shakeCtrl,
                  builder: (ctx, child) {
                    return Transform.translate(
                      offset: screenShakeOffset(
                        t: _playback.shakeCtrl.value,
                        amplitude: _playback.impactShakeAmplitude,
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
                            isPaused: _playback.isPaused,
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
                                  attackControllers:
                                      _playback.attackControllers,
                                  popups: _playback.popups,
                                  animConfig: widget.animConfig,
                                  chargeMaxTicks: chargeMaxTicks,
                                  beat: _playback.beatCtrl,
                                  staggerWindowTicks: staggerWindowTicks,
                                  onPopupComplete: _playback.removePopup,
                                  hitFlashControllers:
                                      _playback.hitFlashControllers,
                                  hitFlashColors: _playback.hitFlashColors,
                                  onEnemyTap: _onEnemyTap,
                                  pendingActive: _pendingActive,
                                  hoveredEnemyId: _hoveredPendingEnemyId,
                                  onEnemyHover: _onPendingEnemyHover,
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: ProjectileLayer(
                                      trails: _playback.activeTrails,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: EffectLayer(
                                      effects: _playback.activeEffects,
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
                            onFastForward: _playback.toggleFastForward,
                            isFastForward: _playback.isFastForward,
                            onSkillTap: _onSkillTap,
                            pendingCharacterId:
                                _pendingCharId ??
                                widget.previewPendingCharacterId,
                            pendingSkillId:
                                _pendingSkill?.id ??
                                widget.previewPendingSkillId,
                            beat: _playback.beatCtrl,
                            skillTargetLink: _skillTargetLink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ScreenFlashOverlay(key: _playback.screenFlashKey),
            ),
            Positioned.fill(
              child: UltimateCaptionOverlay(key: _playback.ultimateCaptionKey),
            ),
            Positioned.fill(
              child: ImpactGlyphOverlay(key: _playback.impactGlyphKey),
            ),
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
            if (_playback.isPaused &&
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
