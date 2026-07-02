/// floor30 护法结界（Task 6）表现层验收：护罩标签（结界生效中）+ 破界题字。
///
/// 纯展示层——不跑真实战斗结算，直接构造 [BattleState] 快照驱动渲染，验证：
/// - [isGuardianWardActive] / [guardianWardBreakEvents] 纯函数派生正确
/// - 护法存活时 Boss 头像旁渲染护罩标签（[UiStrings.guardianWardActiveLabel]）
/// - 护法全灭后标签消失
/// - 结界 + 内伤 + 破绽三态同挂时，固定状态行不溢出（FIX 2 fit 守卫）
/// - [isGuardianWardActive] 与承伤管线 wardMultOf<1.0 口径一致（FIX 3 drift 守卫）
/// - 破界瞬间复用 [UltimateCaptionOverlay] 题字通道展示 [UiStrings.guardianWardBroken]
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/battle/presentation/avatar_status_tags.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/guardian_ward_presentation.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

// ── Fixture builder（镜像 guardian_ward_damage_test.dart 口径）──────────────
BattleCharacter _mkChar({
  required int id,
  int teamSide = 1,
  bool isAlive = true,
  bool isBoss = false,
  String? enemyDefId,
  double? guardianWardMult,
  List<String> guardianDefIds = const [],
  InternalInjurySlot? internalInjury,
  int staggerTicksRemaining = 0,
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
  realmTier: RealmTier.sanLiu,
  realmLayer: RealmLayer.yuanShu,
  school: TechniqueSchool.gangMeng,
  maxHp: 1000,
  currentHp: isAlive ? 1000 : 0,
  maxInternalForce: 500,
  currentInternalForce: 500,
  speed: 100,
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0,
  totalEquipmentAttack: 0,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: isAlive,
  teamSide: teamSide,
  slotIndex: id,
  isBoss: isBoss,
  enemyDefId: enemyDefId,
  guardianWardMult: guardianWardMult,
  guardianDefIds: guardianDefIds,
  internalInjury: internalInjury,
  staggerTicksRemaining: staggerTicksRemaining,
);

void main() {
  final boss = _mkChar(
    id: 1,
    isBoss: true,
    enemyDefId: 'enemy_tower_boss_30',
    guardianWardMult: 0.15,
    guardianDefIds: const [
      'enemy_tower_30_cultist_a',
      'enemy_tower_30_cultist_b',
    ],
  );

  group('isGuardianWardActive 纯函数', () {
    test('护法存活 → true', () {
      final guardian = _mkChar(id: 2, enemyDefId: 'enemy_tower_30_cultist_a');
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardian],
      );
      expect(isGuardianWardActive(boss, state), isTrue);
    });

    test('护法全灭 → false', () {
      final guardianDead = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
        isAlive: false,
      );
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianDead],
      );
      expect(isGuardianWardActive(boss, state), isFalse);
    });

    test('非结界单位(guardianWardMult null) → false', () {
      final plain = _mkChar(id: 3, enemyDefId: 'x');
      final state = BattleState.initial(leftTeam: const [], rightTeam: [plain]);
      expect(isGuardianWardActive(plain, state), isFalse);
    });
  });

  group('guardianWardBreakEvents 边沿检测（镜像 chargeTransitionSfx 写法）', () {
    test('护法存活→全灭 → 返回 boss characterId', () {
      final guardianAlive = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
      );
      final guardianDead = guardianAlive.copyWith(isAlive: false, currentHp: 0);
      final prev = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianAlive],
      );
      final next = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianDead],
      );
      expect(guardianWardBreakEvents(prev, next), [boss.characterId]);
    });

    test('两帧均存活 → 无边沿', () {
      final guardianAlive = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
      );
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianAlive],
      );
      expect(guardianWardBreakEvents(state, state), isEmpty);
    });

    test('prev==null(战斗刚开始) → 无边沿', () {
      final guardianAlive = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
      );
      final next = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianAlive],
      );
      expect(guardianWardBreakEvents(null, next), isEmpty);
    });
  });

  group('CharacterAvatar 护罩标签渲染', () {
    Future<void> pump(WidgetTester tester, BattleState? state) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CharacterAvatar(character: boss, battleState: state),
            ),
          ),
        ),
      );
    }

    testWidgets('护法存活 → 护罩标签渲染在 Boss 头像旁', (tester) async {
      final guardian = _mkChar(id: 2, enemyDefId: 'enemy_tower_30_cultist_a');
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardian],
      );
      await pump(tester, state);
      expect(find.text(UiStrings.guardianWardActiveLabel), findsOneWidget);
      expect(find.byType(AvatarStatusTag), findsOneWidget);
    });

    testWidgets('护法全灭 → 护罩标签消失', (tester) async {
      final guardianDead = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
        isAlive: false,
      );
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [boss, guardianDead],
      );
      await pump(tester, state);
      expect(find.text(UiStrings.guardianWardActiveLabel), findsNothing);
      expect(find.byType(AvatarStatusTag), findsNothing);
    });

    testWidgets('battleState 未传(null,零回归) → 不判定 · 不渲染护罩标签', (tester) async {
      await pump(tester, null);
      expect(find.text(UiStrings.guardianWardActiveLabel), findsNothing);
    });

    // FIX 2：结界 + 内伤 + 破绽三态同挂时，固定状态行(38px 高)不溢出。
    // 拆 label 前 8 字长标签 + 内伤环 + 破绽环挤在 140px 药丸行仅 ~16px 余量；
    // 拆成 4 字「护法结界」后余量 ~66px。本测锁死「无 overflow + ward 标签仍渲染」。
    testWidgets('结界+内伤+破绽三态同挂 → 固定状态行不溢出', (tester) async {
      final wardedBoss = _mkChar(
        id: 1,
        isBoss: true,
        enemyDefId: 'enemy_tower_boss_30',
        guardianWardMult: 0.15,
        guardianDefIds: const ['enemy_tower_30_cultist_a'],
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
        staggerTicksRemaining: 2,
      );
      final guardian = _mkChar(id: 2, enemyDefId: 'enemy_tower_30_cultist_a');
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [wardedBoss, guardian],
      );
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              // 用战屏实际尺寸(avatarSize 92 / barWidth 140)复现真实约束。
              child: CharacterAvatar(
                character: wardedBoss,
                battleState: state,
                avatarSize: 92,
                barWidth: 140,
              ),
            ),
          ),
        ),
      );
      // 三态标签全渲染 + 无 RenderFlex/Wrap overflow 异常。
      expect(find.text(UiStrings.guardianWardActiveLabel), findsOneWidget);
      expect(find.byType(AvatarStatusTag), findsOneWidget); // 结界药丸
      expect(tester.takeException(), isNull);
    });
  });

  // FIX 3：drift 守卫——表现层 isGuardianWardActive 与承伤管线 wardMultOf 是
  // 有意的逻辑重复(见 guardian_ward_presentation.dart 头注)。两者口径必须一致：
  // ward 生效 ⟺ wardMultOf < 1.0。本测在生效/破界/非结界三 fixture 上锁死。
  group('drift 守卫：isGuardianWardActive ⟺ wardMultOf<1.0', () {
    final wardBoss = _mkChar(
      id: 1,
      enemyDefId: 'enemy_tower_boss_30',
      guardianWardMult: 0.15,
      guardianDefIds: const ['enemy_tower_30_cultist_a'],
    );

    void expectAgree(BattleCharacter defender, BattleState state) {
      final presentationActive = isGuardianWardActive(defender, state);
      final strategyActive =
          DefaultGroundStrategy.wardMultOf(defender, state) < 1.0;
      expect(presentationActive, strategyActive);
    }

    test('护法存活 → 两者都判生效', () {
      final guardian = _mkChar(id: 2, enemyDefId: 'enemy_tower_30_cultist_a');
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [wardBoss, guardian],
      );
      expect(isGuardianWardActive(wardBoss, state), isTrue);
      expectAgree(wardBoss, state);
    });

    test('护法全灭 → 两者都判失效', () {
      final guardianDead = _mkChar(
        id: 2,
        enemyDefId: 'enemy_tower_30_cultist_a',
        isAlive: false,
      );
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [wardBoss, guardianDead],
      );
      expect(isGuardianWardActive(wardBoss, state), isFalse);
      expectAgree(wardBoss, state);
    });

    test('非结界单位 → 两者都判失效', () {
      final plain = _mkChar(id: 3, enemyDefId: 'x');
      final state = BattleState.initial(leftTeam: const [], rightTeam: [plain]);
      expect(isGuardianWardActive(plain, state), isFalse);
      expectAgree(plain, state);
    });
  });

  group('破界题字（复用 UltimateCaptionOverlay 转阶段题字通道，不另起平行系统）', () {
    testWidgets('show(guardianWardBroken) 渲染题字且不抛异常', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final key = GlobalKey<UltimateCaptionOverlayState>();
      await tester.pumpWidget(
        MaterialApp(home: UltimateCaptionOverlay(key: key)),
      );
      key.currentState!.show(UiStrings.guardianWardBroken, isEnemy: true);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text(UiStrings.guardianWardBroken), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });
}
