import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/features/battle/presentation/hp_bar.dart';
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

    expect(
      find.byKey(const ValueKey('battle.stageStandeeGrounding')),
      findsOneWidget,
    );
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

    expect(founder.$1, closeTo(1.055, 0.001));
    expect(firstDisciple.$2, greaterThan(0));
    expect(banditBlade.$1, closeTo(1.18, 0.001));
    expect(banditBlade.$3, greaterThan(0));
    expect(banditArcher.$1, closeTo(1.045, 0.001));
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
      ('assets/enemies/bandit_b.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/bandit_c.png', WuxiaUi.battleThugStandee),
      ('assets/enemies/bandit_head.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/qingshan.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/qingshan_main.png', WuxiaUi.battleHiddenElderStandee),
      ('assets/enemies/black_killer.png', WuxiaUi.battleBlackKillerStandee),
      ('assets/enemies/killer_a.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/killer_b.png', WuxiaUi.battleBanditArcherStandee),
      ('assets/enemies/umbrella.png', WuxiaUi.battleUmbrellaStandee),
      ('assets/enemies/tower_boss_05.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/tower_boss_10.png', WuxiaUi.battleJianghuSeniorStandee),
      ('assets/enemies/tower_boss_15.png', WuxiaUi.battleNightSwordsmanStandee),
      ('assets/enemies/tower_boss_20.png', WuxiaUi.battleTowerBoss20Standee),
      ('assets/enemies/tower_boss_25.png', WuxiaUi.battleBanditBladeStandee),
      ('assets/enemies/zuo_hufa.png', WuxiaUi.battleLeftGuardianStandee),
      ('assets/enemies/you_hufa.png', WuxiaUi.battleRightGuardianStandee),
      ('assets/enemies/tower_boss_30.png', WuxiaUi.battleTowerBoss30Standee),
      (
        'assets/enemies/jianghu_qianbei.png',
        WuxiaUi.battleJianghuSeniorStandee,
      ),
      ('assets/enemies/jianghu_a.png', WuxiaUi.battleJianghuSeniorStandee),
      ('assets/enemies/jianghu_b.png', WuxiaUi.battleAdviserStandee),
      ('assets/enemies/wulin_bazhu.png', WuxiaUi.battleWulinOverlordStandee),
      ('assets/enemies/mingmen_a.png', WuxiaUi.battleWulinOverlordStandee),
      ('assets/enemies/liukou_a.png', WuxiaUi.battleFuChiefStandee),
      ('assets/enemies/guard_a.png', WuxiaUi.battleWulinOverlordStandee),
      ('assets/enemies/shafei_a.png', WuxiaUi.battleBanditArcherStandee),
      ('assets/enemies/xiliangboss.png', WuxiaUi.battleAdviserStandee),
      ('assets/enemies/xiliangbazhu.png', WuxiaUi.battleWulinOverlordStandee),
      (
        'assets/enemies/tongguan_shoujiang.png',
        WuxiaUi.battleTowerBoss20Standee,
      ),
      (
        'assets/enemies/songshan_daozong_dizi.png',
        WuxiaUi.battleUmbrellaStandee,
      ),
      ('assets/enemies/caobang_duozhu.png', WuxiaUi.battleJianghuSeniorStandee),
      (
        'assets/enemies/zhongzhou_lunjian_xianfeng.png',
        WuxiaUi.battleLeftGuardianStandee,
      ),
      (
        'assets/enemies/xiliang_sandizi.png',
        WuxiaUi.battleRightGuardianStandee,
      ),
      (
        'assets/enemies/lunjian_sanchang_xunluo.png',
        WuxiaUi.battleBlackKillerStandee,
      ),
      (
        'assets/enemies/songshan_shouguan.png',
        WuxiaUi.battleHiddenElderStandee,
      ),
      (
        'assets/enemies/huanghe_yuantou_yufu.png',
        WuxiaUi.battleJianghuSeniorStandee,
      ),
      (
        'assets/enemies/kunlun_waimen_shouguan.png',
        WuxiaUi.battleTowerBoss20Standee,
      ),
      ('assets/enemies/xiliang_bazhu.png', WuxiaUi.battleWulinOverlordStandee),
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

  testWidgets('未配套透明图的旧敌人原画保持遮罩降级路径', (tester) async {
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

    final image = tester.widget<WuxiaImage>(find.byType(WuxiaImage));
    expect(image.assetPath, 'assets/enemies/unmapped.png');
    expect(image.fit, BoxFit.cover);
    expect(find.byType(ShaderMask), findsOneWidget);
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
