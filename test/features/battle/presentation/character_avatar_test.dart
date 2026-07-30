import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/features/battle/presentation/hp_bar.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_image.dart';

const _bossFrameKey = ValueKey<String>('battle.bossAvatarFrame');

const _chargeSkill = SkillDef(
  id: 'test_charge',
  name: '裂石掌',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 1000,
  cooldownTurns: 5,
  requiresManualTrigger: false,
  visualEffect: '',
);

BattleCharacter _char({required bool isBoss}) => BattleCharacter(
  characterId: 1,
  name: '黑风寨主',
  realmTier: RealmTier.yiLiu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 100,
  currentHp: 100,
  maxInternalForce: 100,
  currentInternalForce: 100,
  speed: 100,
  criticalRate: 0.05,
  evasionRate: 0.05,
  defenseRate: 0.1,
  totalEquipmentAttack: 100,
  mainCultivationLayer: CultivationLayer.daCheng,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 1,
  slotIndex: 0,
  isBoss: isBoss,
);

Finder _avatarCoreFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).shape == BoxShape.circle,
);

Border _avatarBorder(WidgetTester tester) {
  final container = tester.widget<Container>(_avatarCoreFinder().first);
  return (container.decoration as BoxDecoration).border as Border;
}

Size _avatarCoreSize(WidgetTester tester) =>
    tester.getSize(_avatarCoreFinder().first);

Size _avatarFootprintSize(WidgetTester tester) =>
    tester.getSize(find.byType(Opacity).first);

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: CharacterAvatar(character: c)),
        ),
      ),
    );
  }

  testWidgets('普通敌人:流派色 4px 边框', (tester) async {
    await pump(tester, _char(isBoss: false));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.gangMeng); // 刚猛流派色
    expect(b.top.width, 4.0);
  });

  testWidgets('Boss:金色 6px 边框', (tester) async {
    await pump(tester, _char(isBoss: true));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.bossFrame);
    expect(b.top.width, 6.0);
  });

  testWidgets('普通头像布局尺寸保持默认 110（P0-2 放大·适配 720p）', (tester) async {
    await pump(tester, _char(isBoss: false));
    expect(find.byKey(_bossFrameKey), findsNothing);
    expect(_avatarCoreSize(tester), const Size(110, 110));
  });

  testWidgets('Boss 外框参与布局且头像核心保持 110', (tester) async {
    await pump(tester, _char(isBoss: true));

    const avatarSize = 110.0;
    const expectedFrameSize = avatarSize * 1.42;

    expect(_avatarCoreSize(tester), const Size(avatarSize, avatarSize));

    final frameSize = tester.getSize(find.byKey(_bossFrameKey));
    expect(frameSize.width, greaterThan(avatarSize));
    expect(frameSize.height, greaterThan(avatarSize));
    expect(frameSize.width, closeTo(expectedFrameSize, 0.01));
    expect(frameSize.height, closeTo(expectedFrameSize, 0.01));
  });

  testWidgets('死亡单位叠 grayscale ColorFiltered（P0-2）', (tester) async {
    final dead = _char(isBoss: false).copyWith(isAlive: false);
    await pump(tester, dead);
    expect(find.byType(ColorFiltered), findsWidgets);
  });

  testWidgets('存活单位不灰（无 grayscale ColorFiltered）', (tester) async {
    await pump(tester, _char(isBoss: false)); // isAlive 默认 true
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('真气条带「气 X / Y」标签与数值', (tester) async {
    // 内力 80/120，HP 100/100，避免内力与 HP 数值相同导致歧义。
    final c = _char(isBoss: false).copyWith(
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 120,
      currentInternalForce: 80,
    );
    await pump(tester, c);

    // 内力条标签：内 80 / 120
    expect(find.text('气 80 / 120'), findsOneWidget);
    // HP 条仍是裸数值，不带「内 」前缀（现状不破坏）。
    expect(find.text('100 / 100'), findsOneWidget);
  });

  testWidgets('状态环与蓄力环预留稳定高度，避免同队槽位独立缩放', (tester) async {
    await pump(tester, _char(isBoss: false));
    final plainSize = _avatarFootprintSize(tester);

    final dense = _char(isBoss: false).copyWith(
      internalInjury: const InternalInjurySlot(
        remainingTurns: 2,
        damagePerTick: 200,
      ),
      staggerTicksRemaining: 2,
      swordSongResonanceActive: true,
      chargingSkill: _chargeSkill,
      chargeTicksRemaining: 1,
    );
    await pump(tester, dense);
    final denseSize = _avatarFootprintSize(tester);

    expect(denseSize, plainSize);
    expect(find.byType(BeatCountdownRing), findsNWidgets(2));
    expect(find.byIcon(Icons.flash_on), findsOneWidget);
  });

  testWidgets('战场三名我方降级位使用透明全身立绘且保持完整头脚', (tester) async {
    const expectedPaths = [
      WuxiaUi.battleFounderFallback,
      WuxiaUi.battleFirstDiscipleFallback,
      WuxiaUi.battleSecondDiscipleFallback,
    ];

    for (var slot = 0; slot < expectedPaths.length; slot++) {
      final character = _char(
        isBoss: false,
      ).copyWith(teamSide: 0, slotIndex: slot);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterAvatar(
              character: character,
              displayMode: CharacterDisplayMode.stageStandee,
              standeeWidth: 160,
              standeeHeight: 230,
            ),
          ),
        ),
      );

      final standeeImage = tester.widget<WuxiaImage>(
        find.byWidgetPredicate(
          (widget) =>
              widget is WuxiaImage && widget.assetPath == expectedPaths[slot],
        ),
      );
      expect(standeeImage.fit, BoxFit.contain);
    }
  });

  testWidgets('战场全身立绘具有独立脚底接触墨影', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: _char(isBoss: false),
            displayMode: CharacterDisplayMode.stageStandee,
            standeeWidth: 160,
            standeeHeight: 230,
          ),
        ),
      ),
    );

    final groundingFinder = find.byKey(
      const ValueKey('battle.stageStandeeGrounding'),
    );
    expect(groundingFinder, findsOneWidget);

    final grounding = tester.widget<Positioned>(groundingFinder);
    expect(grounding.left, lessThan(160 * 0.17));
    expect(grounding.right, lessThan(160 * 0.17));
    expect(grounding.height, greaterThan(230 * 0.065));
  });

  testWidgets('战场人物信息板使用低透明贴脚窄条而非厚重卡片', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: Stack(
              children: [
                StageCharacterStatusOverlay(
                  character: _char(isBoss: false),
                  battleState: null,
                  width: 180,
                  height: 260,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final rubbing = tester.widget<Container>(
      find.byKey(const ValueKey('battle.stageStatusInkRubbing')),
    );
    final decoration = rubbing.decoration! as BoxDecoration;
    final colors = (decoration.gradient! as LinearGradient).colors;
    expect(colors, everyElement(isNot(Colors.black)));
    expect(colors, everyElement(predicate<Color>((color) => color.a < 0.50)));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('battle.stageStatusInkRubbing')))
          .height,
      lessThanOrEqualTo(34),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('battle.stageStatusInkRubbing')))
          .width,
      lessThanOrEqualTo(120),
    );
    final name = tester.widget<Text>(find.text('黑风寨主'));
    expect(name.style?.color, WuxiaUi.paper);
    expect(name.style?.shadows?.single.blurRadius, lessThanOrEqualTo(1));
    expect(
      find.byKey(const ValueKey('battle.stageStatusAnchor')),
      findsOneWidget,
    );
  });

  testWidgets('战场人物信息条显示样板式完整数值且真气条无额外前缀', (tester) async {
    final character = _char(
      isBoss: false,
    ).copyWith(currentHp: 37810, maxHp: 37810, currentQi: 50, maxQi: 100);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 300,
            child: Stack(
              children: [
                StageCharacterStatusOverlay(
                  character: character,
                  battleState: null,
                  width: 240,
                  height: 300,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('37810/37810'), findsOneWidget);
    expect(find.text('50/100'), findsOneWidget);
    expect(find.textContaining('37.8K'), findsNothing);
    expect(
      find.textContaining(UiStrings.internalForceShortLabel),
      findsNothing,
    );
  });

  testWidgets('战场立绘使用固定暖灰色级与亚像素边缘柔化层', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: _char(isBoss: false),
            displayMode: CharacterDisplayMode.stageStandee,
            standeeWidth: 160,
            standeeHeight: 230,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('battle.stageStandeeFusionGrade')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle.stageStandeeEdgeSoftening')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle.stageStandeeFusionOpacity')),
      findsOneWidget,
    );
  });

  testWidgets('阵亡站姿灰化下沉并遵守 P0-2 opacity 0.45', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: _char(isBoss: false).copyWith(isAlive: false),
            displayMode: CharacterDisplayMode.stageStandee,
            standeeWidth: 160,
            standeeHeight: 230,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('battle.stageStandeeDefeatedSink')),
      findsOneWidget,
    );
    final fade = tester.widget<Opacity>(
      find.byKey(const ValueKey('battle.stageStandeeDefeatedFade')),
    );
    expect(fade.opacity, 0.45);
  });

  testWidgets('Boss全身立绘不再绘制矩形金色黄底', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: _char(isBoss: true),
            displayMode: CharacterDisplayMode.stageStandee,
            standeeWidth: 160,
            standeeHeight: 230,
          ),
        ),
      ),
    );

    final frame = tester.widget(find.byKey(_bossFrameKey));
    expect(frame, isA<KeyedSubtree>());
    expect(frame, isNot(isA<Container>()));
  });

  testWidgets('战场立绘按有效人物边界校准尺度与视觉重心', (tester) async {
    Future<(double scale, double shiftX, double shiftY)> opticalTransformFor(
      String iconPath,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterAvatar(
              character: _char(isBoss: false).copyWith(iconPath: iconPath),
              displayMode: CharacterDisplayMode.stageStandee,
              standeeWidth: 160,
              standeeHeight: 230,
            ),
          ),
        ),
      );

      final scaleTransform = tester.widget<Transform>(
        find.byKey(const ValueKey('battle.stageStandeeOpticalScale')),
      );
      final shiftTransform = tester.widget<Transform>(
        find.byKey(const ValueKey('battle.stageStandeeOpticalShift')),
      );
      return (
        scaleTransform.transform.storage[0],
        shiftTransform.transform.storage[12],
        shiftTransform.transform.storage[13],
      );
    }

    final founder = await opticalTransformFor('assets/characters/founder.png');
    final firstDisciple = await opticalTransformFor(
      'assets/characters/first_disciple.png',
    );
    final banditBlade = await opticalTransformFor(
      'assets/enemies/killer_a.png',
    );
    final banditArcher = await opticalTransformFor(
      'assets/enemies/killer_b.png',
    );
    final umbrellaBoss = await opticalTransformFor(
      'assets/enemies/umbrella.png',
    );

    expect(founder.$1, closeTo(1.055, 0.001));
    expect(firstDisciple.$2, greaterThan(0));
    expect(banditBlade.$1, closeTo(1.18, 0.001));
    expect(banditBlade.$3, greaterThan(0));
    expect(banditArcher.$1, closeTo(1.045, 0.001));
    expect(umbrellaBoss.$1, closeTo(0.81, 0.001));
  });

  testWidgets('战场将已配套的旧原画映射到对应透明立绘', (tester) async {
    expect(
      WuxiaUi.battleTowerBoss30Standee,
      'assets/enemies/battle_tower_boss_30_v2.png',
    );
    expect(
      WuxiaUi.battleTowerBoss30Standee,
      isNot(WuxiaUi.battleFounderFallback),
    );

    const cases = [
      ('assets/characters/founder.png', WuxiaUi.battleFounderFallback),
      ('assets/enemies/thug_a.png', WuxiaUi.battleThugStandee),
      ('assets/enemies/thug_b.png', WuxiaUi.battleYoungRuffianStandee),
      ('assets/enemies/thug_c.png', WuxiaUi.battleGauntCutpurseStandee),
      ('assets/enemies/ruffian_a.png', WuxiaUi.battleVillageRuffianStandee),
      ('assets/enemies/bandit_b.png', WuxiaUi.battleLowRankSaberFighterStandee),
      ('assets/enemies/bandit_c.png', WuxiaUi.battleBlackWindUnderlingStandee),
      ('assets/enemies/bandit_head.png', WuxiaUi.battleBanditHeadStandee),
      ('assets/enemies/qingshan.png', WuxiaUi.battleQingshanStandee),
      ('assets/enemies/qingshan_main.png', WuxiaUi.battleHiddenElderStandee),
      ('assets/enemies/elder_grey.png', WuxiaUi.battleGreyElderStandee),
      ('assets/enemies/shaonian.png', WuxiaUi.battleSpringHallYouthStandee),
      ('assets/enemies/guntou.png', WuxiaUi.battleBaldStaffFighterStandee),
      ('assets/enemies/guntou_zhu.png', WuxiaUi.battleArenaChampionStandee),
      ('assets/enemies/seng_huiyi.png', WuxiaUi.battleGreyMonkStandee),
      ('assets/enemies/balian.png', WuxiaUi.battleScarredBossStandee),
      ('assets/enemies/huiyi.png', WuxiaUi.battleGreySwordsmanStandee),
      (
        'assets/enemies/lightfoot_shuikou_a.png',
        WuxiaUi.battleFerryBanditStandee,
      ),
      (
        'assets/enemies/lightfoot_shuikou_b.png',
        WuxiaUi.battleFerryBoatmanStandee,
      ),
      (
        'assets/enemies/lightfoot_shuikou_c.png',
        WuxiaUi.battleFerrySaberStandee,
      ),
      (
        'assets/enemies/lightfoot_yexun_a.png',
        WuxiaUi.battleNightPatrolStandee,
      ),
      (
        'assets/enemies/lightfoot_yexun_b.png',
        WuxiaUi.battleRooftopConstableStandee,
      ),
      (
        'assets/enemies/lightfoot_yexun_c.png',
        WuxiaUi.battleRooftopAssassinStandee,
      ),
      (
        'assets/enemies/lightfoot_zhuke_a.png',
        WuxiaUi.battleJiangnanSwordsmanStandee,
      ),
      (
        'assets/enemies/lightfoot_zhuke_b.png',
        WuxiaUi.battleBambooSaberStandee,
      ),
      (
        'assets/enemies/lightfoot_zhuke_c.png',
        WuxiaUi.battleBambooWandererStandee,
      ),
      (
        'assets/enemies/lightfoot_pubu_a.png',
        WuxiaUi.battleMountainStreamSwordStandee,
      ),
      (
        'assets/enemies/lightfoot_pubu_b.png',
        WuxiaUi.battleWaterfallSaberStandee,
      ),
      (
        'assets/enemies/lightfoot_pubu_c.png',
        WuxiaUi.battleCliffWandererStandee,
      ),
      (
        'assets/enemies/lightfoot_changfeng_a.png',
        WuxiaUi.battleGateCommanderStandee,
      ),
      (
        'assets/enemies/lightfoot_changfeng_b.png',
        WuxiaUi.battleLongWindSwordStandee,
      ),
      (
        'assets/enemies/lightfoot_changfeng_c.png',
        WuxiaUi.battleLongRoadSaberStandee,
      ),
      (
        'assets/enemies/massbattle_cunfei_a.png',
        WuxiaUi.battleVillageBanditLeaderStandee,
      ),
      (
        'assets/enemies/massbattle_cunfei_b.png',
        WuxiaUi.battleVillageBanditArcherStandee,
      ),
      (
        'assets/enemies/massbattle_cunfei_c.png',
        WuxiaUi.battleVillageBanditSaberStandee,
      ),
      (
        'assets/enemies/massbattle_zhenkou_a.png',
        WuxiaUi.battleTownBanditLeaderStandee,
      ),
      (
        'assets/enemies/massbattle_zhenkou_b.png',
        WuxiaUi.battleTownBanditWandererStandee,
      ),
      (
        'assets/enemies/massbattle_zhenkou_c.png',
        WuxiaUi.battleTownBanditAssassinStandee,
      ),
      (
        'assets/enemies/massbattle_xianjie_a.png',
        WuxiaUi.battleRivalSectMasterStandee,
      ),
      (
        'assets/enemies/massbattle_xianjie_b.png',
        WuxiaUi.battleRivalSectProtectorStandee,
      ),
      (
        'assets/enemies/massbattle_xianjie_c.png',
        WuxiaUi.battleRivalSectDiscipleStandee,
      ),
      (
        'assets/enemies/massbattle_guanqi_a.png',
        WuxiaUi.battleFrontierCommanderStandee,
      ),
      (
        'assets/enemies/massbattle_guanqi_b.png',
        WuxiaUi.battleFrontierOutriderStandee,
      ),
      (
        'assets/enemies/massbattle_guanqi_c.png',
        WuxiaUi.battleFrontierIronGuardStandee,
      ),
      (
        'assets/enemies/massbattle_canbu_a.png',
        WuxiaUi.battleWesternRemnantGeneralStandee,
      ),
      (
        'assets/enemies/massbattle_canbu_b.png',
        WuxiaUi.battleWesternFrenziedRiderStandee,
      ),
      (
        'assets/enemies/massbattle_canbu_c.png',
        WuxiaUi.battleWesternRemnantAssassinStandee,
      ),
      ('assets/enemies/black_killer.png', WuxiaUi.battleBlackKillerStandee),
      ('assets/enemies/killer_a.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/killer_b.png', WuxiaUi.battleBanditArcherStandee),
      ('assets/enemies/umbrella.png', WuxiaUi.battleUmbrellaStandee),
      (
        'assets/enemies/tower_boss_05.png',
        WuxiaUi.battleSwordStoneElderStandee,
      ),
      ('assets/enemies/tower_boss_10.png', WuxiaUi.battleBlackWindChiefStandee),
      (
        'assets/enemies/tower_boss_15.png',
        WuxiaUi.battleNightPavilionMasterStandee,
      ),
      ('assets/enemies/tower_boss_20.png', WuxiaUi.battleTowerBoss20Standee),
      (
        'assets/enemies/tower_boss_25.png',
        WuxiaUi.battleSummitSwordDemonStandee,
      ),
      ('assets/enemies/zuo_hufa.png', WuxiaUi.battleLeftGuardianStandee),
      ('assets/enemies/you_hufa.png', WuxiaUi.battleRightGuardianStandee),
      ('assets/enemies/tower_boss_30.png', WuxiaUi.battleTowerBoss30Standee),
      (
        'assets/enemies/jianghu_qianbei.png',
        WuxiaUi.battleJianghuSeniorStandee,
      ),
      (
        'assets/enemies/jianghu_a.png',
        WuxiaUi.battleWanderingPalmFighterStandee,
      ),
      (
        'assets/enemies/jianghu_b.png',
        WuxiaUi.battleIndependentWandererStandee,
      ),
      ('assets/enemies/wulin_bazhu.png', WuxiaUi.battleWulinOverlordStandee),
      (
        'assets/enemies/mingmen_a.png',
        WuxiaUi.battleEstablishedSectDiscipleStandee,
      ),
      ('assets/enemies/liukou_a.png', WuxiaUi.battleRaiderLeaderStandee),
      ('assets/enemies/guard_a.png', WuxiaUi.battleYumenGarrisonOfficerStandee),
      ('assets/enemies/shafei_a.png', WuxiaUi.battleDesertBanditLeaderStandee),
      (
        'assets/enemies/xiliangboss.png',
        WuxiaUi.battleWesternMartialSeniorStandee,
      ),
      ('assets/enemies/xiliangbazhu.png', WuxiaUi.battleWesternOverlordStandee),
      (
        'assets/enemies/tongguan_shoujiang.png',
        WuxiaUi.battleTongguanDefenderStandee,
      ),
      (
        'assets/enemies/songshan_daozong_dizi.png',
        WuxiaUi.battleSongshanDaoistDiscipleStandee,
      ),
      (
        'assets/enemies/caobang_duozhu.png',
        WuxiaUi.battleCanalGangHelmsmanStandee,
      ),
      (
        'assets/enemies/zhongzhou_lunjian_xianfeng.png',
        WuxiaUi.battleCentralPlainsVanguardStandee,
      ),
      (
        'assets/enemies/xiliang_sandizi.png',
        WuxiaUi.battleWesternThirdDiscipleStandee,
      ),
      (
        'assets/enemies/lunjian_sanchang_xunluo.png',
        WuxiaUi.battleArenaPatrolStandee,
      ),
      (
        'assets/enemies/songshan_shouguan.png',
        WuxiaUi.battleSongshanGatekeeperStandee,
      ),
      (
        'assets/enemies/huanghe_yuantou_yufu.png',
        WuxiaUi.battleYellowRiverFisherStandee,
      ),
      (
        'assets/enemies/kunlun_waimen_shouguan.png',
        WuxiaUi.battleKunlunGateGuardianStandee,
      ),
      (
        'assets/enemies/xiliang_bazhu.png',
        WuxiaUi.battleWesternOverlordSaintStandee,
      ),
      ('assets/enemies/anye.png', WuxiaUi.battleNightSwordsmanStandee),
      ('assets/enemies/shiye.png', WuxiaUi.battleAdviserStandee),
      ('assets/enemies/fu_zhaizhu.png', WuxiaUi.battleFuChiefStandee),
    ];

    for (final (sourcePath, standeePath) in cases) {
      final character = _char(
        isBoss: sourcePath.contains('boss'),
      ).copyWith(iconPath: sourcePath);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterAvatar(
              character: character,
              displayMode: CharacterDisplayMode.stageStandee,
            ),
          ),
        ),
      );

      final image = tester.widget<WuxiaImage>(
        find.byWidgetPredicate(
          (widget) => widget is WuxiaImage && widget.assetPath == standeePath,
        ),
      );
      expect(image.fit, BoxFit.contain);
    }
  });

  testWidgets('未登记敌人 portrait 不进入战场，改用透明身份剪影', (tester) async {
    final character = _char(
      isBoss: false,
    ).copyWith(iconPath: 'assets/enemies/unmapped.png');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: character,
            displayMode: CharacterDisplayMode.stageStandee,
          ),
        ),
      ),
    );

    expect(find.byType(WuxiaImage), findsNothing);
    expect(
      find.byKey(const ValueKey('battle.stageStandeeIdentitySilhouette')),
      findsOneWidget,
    );
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('未配专用站姿的玩家以透明站姿 alpha 绘制纯墨身份影', (tester) async {
    final character = _char(isBoss: false).copyWith(
      teamSide: 0,
      slotIndex: 4,
      name: '竹影',
      iconPath: 'assets/characters/sect_candidate_bamboo.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: character,
            displayMode: CharacterDisplayMode.stageStandee,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('battle.stageStandeeIdentitySilhouette')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is WuxiaImage &&
            widget.assetPath == 'assets/characters/sect_candidate_bamboo.png',
      ),
      findsNothing,
    );
    final inkShape = tester.widget<WuxiaImage>(find.byType(WuxiaImage));
    expect(inkShape.assetPath, WuxiaUi.battleFirstDiscipleFallback);
    expect(inkShape.fit, BoxFit.contain);
    expect(inkShape.colorBlendMode, BlendMode.srcIn);
    expect(inkShape.color, isNotNull);
    expect(find.text('竹'), findsOneWidget);
  });

  testWidgets('心魔镜像只给人物图施加反相墨色层', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterAvatar(
            character: _char(isBoss: false),
            displayMode: CharacterDisplayMode.stageStandee,
            inkMirror: true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('battle.innerDemonInkMirror')),
      findsOneWidget,
    );
    expect(find.byType(HpBar), findsNWidgets(2));
  });
}
