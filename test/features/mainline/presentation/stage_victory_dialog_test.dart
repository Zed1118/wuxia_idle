import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/image_test_helpers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_factory.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_victory_dialog.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

StageDef _stage() => const StageDef(
  id: 'stage_test_01',
  name: '测试关卡',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 100,
  difficultyMultiplier: 1.0,
);

DropResult _emptyDrops() => const DropResult(equipments: [], items: []);

DropResult _itemDrops() => const DropResult(
  equipments: [],
  items: [ItemDropResult(defId: 'item_mojianshi', quantity: 2)],
);

Character _character({
  String name = '沈青',
  RealmTier realmTier = RealmTier.xueTu,
  double injuryHours = 0,
  int lightStacks = 0,
}) {
  final c = Character.create(
    name: name,
    realmTier: realmTier,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 6, 29),
    internalForce: 100,
    internalForceMax: 500,
  );
  c.injuryHoursRemaining = injuryHours;
  c.lightInjuryStacks = lightStacks;
  return c;
}

/// H1 批3:真装备掉落(需 GameRepository 已加载,defId→名+品阶)。
DropResult _equipDrops(List<String> defIds) => DropResult(
  equipments: [
    for (final id in defIds)
      EquipmentFactory.fromDef(
        GameRepository.instance.getEquipment(id),
        rng: DefaultRng(seed: 1),
        obtainedAt: DateTime(2026, 5, 30),
        obtainedFrom: '掉落',
      ),
  ],
  items: const [],
);

/// 录音 fake 后端(沿 sound_manager_test FakeAudioBackend 体例,只记 sfx)。
class _RecordingBackend implements AudioBackend {
  final List<String> sfxPlays = [];
  @override
  Future<void> playBgm(String assetPath, double volume) async {}
  @override
  Future<void> stopBgm() async {}
  @override
  void setBgmVolume(double volume) {}
  @override
  Future<void> playSfx(String assetPath, double volume) async =>
      sfxPlays.add(assetPath);
  @override
  Future<void> dispose() async {}
}

Finder _assetImage(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      assetNameOf(w.image) == path,
);

AdvancementResult _advanced() => const AdvancementResult(
  layersGained: 1,
  tierBefore: RealmTier.xueTu,
  layerBefore: RealmLayer.qiMeng,
  tierAfter: RealmTier.xueTu,
  layerAfter: RealmLayer.ruMen,
  internalForceMaxBefore: 500,
  internalForceMaxAfter: 600,
);

/// 跨 tier 大境界突破(学徒→三流),realmAdvance jingle 触发条件。
AdvancementResult _crossedTier() => const AdvancementResult(
  layersGained: 1,
  tierBefore: RealmTier.xueTu,
  layerBefore: RealmLayer.dengFeng,
  tierAfter: RealmTier.sanLiu,
  layerAfter: RealmLayer.qiMeng,
  internalForceMaxBefore: 500,
  internalForceMaxAfter: 700,
);

AdvancementResult _flat() => const AdvancementResult(
  layersGained: 0,
  tierBefore: RealmTier.xueTu,
  layerBefore: RealmLayer.qiMeng,
  tierAfter: RealmTier.xueTu,
  layerAfter: RealmLayer.qiMeng,
  internalForceMaxBefore: 500,
  internalForceMaxAfter: 500,
);

Future<void> _pumpContent(
  WidgetTester tester,
  DropResult drops,
  List<AdvancementEntry> advancements, {
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  List<Character> equipmentHintCharacters = const [],
  EquipmentDropLockHandler? onEquipmentLockToggle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StageVictoryContent(
          drops: drops,
          advancements: advancements,
          resonanceUpgrades: resonanceUpgrades,
          equipmentHintCharacters: equipmentHintCharacters,
          onEquipmentLockToggle: onEquipmentLockToggle,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('StageVictoryContent', () {
    testWidgets('empty drops + 无升层 → 显「本战无固定掉落」 + 不显 banner', (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryExperienceSection), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('firstClearTitle 非空 → 顶部显示首胜封签', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              firstClearTitle: UiStrings.stageVictoryBossFirstClear('风雨渡口'),
              drops: _emptyDrops(),
              advancements: const [],
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.firstClearCeremonySubtitle), findsOneWidget);
      expect(find.text('首胜 · 风雨渡口'), findsOneWidget);
      expect(find.byIcon(Icons.military_tech), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyBossFirstVictory), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyRedSeal), findsOneWidget);
    });

    testWidgets('item drop + 无升层 → 显 drop 条目', (tester) async {
      await _pumpContent(tester, _itemDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('empty drops + 1 角色升层 → noDrop + banner 1 行', (tester) async {
      await _pumpContent(tester, _emptyDrops(), [
        AdvancementEntry(chName: '甲', result: _advanced()),
      ]);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.text(UiStrings.advancementCeremonyTitle), findsOneWidget);
      expect(
        find.text(UiStrings.stageVictoryExperienceSection),
        findsOneWidget,
      );
      expect(_assetImage(WuxiaUi.ceremonyRealmBreakthrough), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
    });

    testWidgets('drops + 升层 mixed → 两段都显', (tester) async {
      await _pumpContent(tester, _itemDrops(), [
        AdvancementEntry(chName: '甲', result: _advanced()),
        AdvancementEntry(chName: '乙', result: _flat()),
      ]);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.text(UiStrings.advancementCeremonyTitle), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyRealmBreakthrough), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('乙'), findsNothing);
    });

    testWidgets('drops + 全员未升层 → drop 显,banner 不显', (tester) async {
      await _pumpContent(tester, _itemDrops(), [
        AdvancementEntry(chName: '甲', result: _flat()),
      ]);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    // P1.1 候选 3-a:共鸣度晋阶 banner
    testWidgets('empty drops + 1 共鸣晋阶 → 显「共鸣晋阶」label + 1 行 notice', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        _emptyDrops(),
        const [],
        resonanceUpgrades: const [
          ResonanceUpgradeNotice(
            equipmentName: '青锋剑',
            newStage: ResonanceStage.moQi,
          ),
        ],
      );
      expect(
        find.text(UiStrings.stageVictoryResonanceCeremonyTitle),
        findsOneWidget,
      );
      expect(find.text(UiStrings.stageVictoryEquipmentSection), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsOneWidget);
      expect(find.textContaining('「青锋剑」共鸣度晋至 默契'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyEquipmentResonance), findsOneWidget);
    });

    testWidgets('多件共鸣晋阶 → 显多行 + 升层 + drop 三段共存', (tester) async {
      await _pumpContent(
        tester,
        _itemDrops(),
        [AdvancementEntry(chName: '甲', result: _advanced())],
        resonanceUpgrades: const [
          ResonanceUpgradeNotice(
            equipmentName: '青锋剑',
            newStage: ResonanceStage.moQi,
          ),
          ResonanceUpgradeNotice(
            equipmentName: '玄铁刀',
            newStage: ResonanceStage.xinJianTongLing,
          ),
        ],
      );
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.text(UiStrings.advancementCeremonyTitle), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyRealmBreakthrough), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(
        find.text(UiStrings.stageVictoryResonanceCeremonyTitle),
        findsOneWidget,
      );
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyEquipmentResonance), findsOneWidget);
      expect(find.textContaining('青锋剑'), findsOneWidget);
      expect(find.textContaining('玄铁刀'), findsOneWidget);
      expect(find.textContaining('默契'), findsOneWidget);
      expect(find.textContaining('心剑通灵'), findsOneWidget);
      // 升层 1 icon + 共鸣晋阶 2 icon = 3 icon
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(3));
    });

    testWidgets('empty 三段全空 → 只显「本战无固定掉落」', (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    // H1 批3:装备掉落仪式感 —— 显中文名 + 品阶标签 + 勋章图标,非 raw defId。
    testWidgets('装备掉落 → 显中文名+品阶标签+勋章图标,不显 raw defId', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops([
          'weapon_shenwu_tian_wen_jian', // 神物 · 天问剑
          'weapon_xunchang_tie_jian', // 寻常货 · 铁剑
        ]),
        const [],
      );
      // 中文名渲染(此前若显 raw defId 即真 bug 类)。
      expect(find.text('天问剑'), findsOneWidget);
      expect(find.text('铁剑'), findsOneWidget);
      expect(find.textContaining('weapon_shenwu'), findsNothing);
      // 品阶标签(神物高亮 / 寻常货暗灰,色差由 tierColorForEquipment 给)。
      expect(find.text('神物'), findsOneWidget);
      expect(find.text('寻常货'), findsOneWidget);
      // 每件装备一枚品阶勋章图标。
      expect(find.byIcon(Icons.workspace_premium), findsNWidgets(2));
    });

    testWidgets('装备掉落动作区 → 显锁定/常用/来源/稍后,且不显出售分解', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
      );
      expect(find.text(UiStrings.equipmentLock), findsOneWidget);
      expect(find.text(UiStrings.equipmentDropActionFavorite), findsOneWidget);
      expect(find.text(UiStrings.equipmentDropActionSource), findsOneWidget);
      expect(find.text(UiStrings.equipmentDropActionLater), findsOneWidget);
      expect(find.text(UiStrings.equipmentSell), findsNothing);
      expect(find.text(UiStrings.equipmentDisassemble), findsNothing);
    });

    testWidgets('装备掉落详情 → 显示门槛、可用角色、适合流派与锁定建议', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
        equipmentHintCharacters: [
          _character(name: '沈青', realmTier: RealmTier.xueTu),
        ],
      );

      expect(find.text(UiStrings.equipmentDropRealmGate('学徒')), findsOneWidget);
      expect(
        find.text(UiStrings.equipmentDropUsableCharacters('沈青')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.equipmentDropSchoolFit('灵巧')), findsOneWidget);
      expect(find.text(UiStrings.equipmentDropLockAdviceFit), findsOneWidget);
    });

    testWidgets('装备掉落详情 → 无达标角色时显示不可用与高阶锁定建议', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops(['weapon_shenwu_tian_wen_jian']),
        const [],
        equipmentHintCharacters: [
          _character(name: '沈青', realmTier: RealmTier.xueTu),
        ],
      );

      expect(find.text(UiStrings.equipmentDropRealmGate('武圣')), findsOneWidget);
      expect(
        find.text(UiStrings.equipmentDropNoUsableCharacters),
        findsOneWidget,
      );
      expect(find.text(UiStrings.equipmentDropLockAdviceRare), findsOneWidget);
    });

    testWidgets('点击锁定 → 调用回调并更新为解锁/已锁定', (tester) async {
      final calls = <bool>[];
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
        onEquipmentLockToggle: (equipment, locked) async {
          calls.add(locked);
          return true;
        },
      );

      await tester.tap(find.text(UiStrings.equipmentLock));
      await tester.pumpAndSettle();

      expect(calls, [true]);
      expect(find.text(UiStrings.equipmentUnlock), findsOneWidget);
      expect(find.text(UiStrings.equipmentLockedLabel), findsOneWidget);
    });

    testWidgets('点击标记常用 → 复用锁定保护', (tester) async {
      final calls = <bool>[];
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
        onEquipmentLockToggle: (equipment, locked) async {
          calls.add(locked);
          return true;
        },
      );

      await tester.tap(find.text(UiStrings.equipmentDropActionFavorite));
      await tester.pumpAndSettle();

      expect(calls, [true]);
      expect(find.text(UiStrings.equipmentDropFavoriteLabel), findsOneWidget);
      expect(find.text(UiStrings.equipmentLockedLabel), findsOneWidget);
    });

    testWidgets('查看来源 → 弹出来源列表', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
      );

      await tester.tap(find.text(UiStrings.equipmentDropActionSource));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.equipmentDropSourceTitle), findsOneWidget);
      expect(find.textContaining('主线'), findsWidgets);
    });

    testWidgets('稍后处理 → 标记已处理但不写库', (tester) async {
      var calls = 0;
      await _pumpContent(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        const [],
        onEquipmentLockToggle: (equipment, locked) async {
          calls += 1;
          return true;
        },
      );

      await tester.tap(find.text(UiStrings.equipmentDropActionLater));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text(UiStrings.equipmentDropActionDone), findsOneWidget);
    });

    // Task 5:战斗统计段
    testWidgets('StageVictoryContent 显示战斗统计段', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: DropResult(equipments: [], items: []),
              advancements: [],
              stats: BattleStatsSummary(
                totalDamage: 1234,
                critCount: 3,
                totalTicks: 9,
              ),
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.battleSummary(1234, 3, 9)), findsOneWidget);
    });

    testWidgets('StageVictoryContent 显示战后伤势摘要', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: _emptyDrops(),
              advancements: const [],
              injurySummaryCharacters: [
                _character(injuryHours: 2, lightStacks: 1),
              ],
            ),
          ),
        ),
      );

      expect(
        find.textContaining(UiStrings.injuryBattleSummaryTitle),
        findsOneWidget,
      );
      expect(find.textContaining('沈青：'), findsOneWidget);
      expect(find.textContaining(UiStrings.injuryHeavyLabel), findsOneWidget);
    });

    testWidgets('stats=null 时不显统计段(向后兼容)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: DropResult(equipments: [], items: []),
              advancements: [],
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
    });

    // 第七阶段批二④:残页轻提示行
    testWidgets('skillFragmentLine 非空 → 渲染残页轻提示行', (tester) async {
      final line = UiStrings.skillFragmentGainedLine('神龙一式', 3, 5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: _emptyDrops(),
              advancements: const [],
              skillFragmentLine: line,
            ),
          ),
        ),
      );
      expect(find.text(line), findsOneWidget);
    });

    testWidgets('skillFragmentLine=null → 不渲染残页行(向后兼容)', (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.textContaining('得残页'), findsNothing);
    });

    testWidgets('卷轴结算按经验、掉落、装备、秘籍、战况、伤势分区', (tester) async {
      final fragmentLine = UiStrings.skillFragmentGainedLine('神龙一式', 3, 5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: DropResult(
                equipments: _equipDrops([
                  'weapon_xunchang_tie_jian',
                ]).equipments,
                items: const [
                  ItemDropResult(defId: 'item_mojianshi', quantity: 2),
                  ItemDropResult(defId: 'item_scroll_test_manual', quantity: 1),
                ],
              ),
              advancements: [
                AdvancementEntry(chName: '甲', result: _advanced()),
              ],
              resonanceUpgrades: const [
                ResonanceUpgradeNotice(
                  equipmentName: '青锋剑',
                  newStage: ResonanceStage.moQi,
                ),
              ],
              stats: const BattleStatsSummary(
                totalDamage: 1234,
                critCount: 3,
                totalTicks: 9,
              ),
              injurySummaryCharacters: [_character(injuryHours: 2)],
              skillFragmentLine: fragmentLine,
            ),
          ),
        ),
      );

      expect(
        find.text(UiStrings.stageVictoryExperienceSection),
        findsOneWidget,
      );
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryEquipmentSection), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryManualSection), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryBattleSection), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryInjurySection), findsOneWidget);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('心法秘籍 ×1'), findsOneWidget);
      expect(find.text(fragmentLine), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('长掉落列表在卷轴层内可滚动且不溢出', (tester) async {
      tester.view.physicalSize = const Size(600, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              drops: DropResult(
                equipments: const [],
                items: [
                  for (var i = 0; i < 32; i++)
                    ItemDropResult(defId: 'item_mojianshi', quantity: i + 1),
                ],
              ),
              advancements: const [],
            ),
          ),
        ),
      );

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('常规桌面视口 smoke：1280x720 / 1440x900 不溢出', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final size in const [Size(1280, 720), Size(1440, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: StageVictoryContent(
                  drops: DropResult(
                    equipments: _equipDrops([
                      'weapon_xunchang_tie_jian',
                      'weapon_shenwu_tian_wen_jian',
                    ]).equipments,
                    items: const [
                      ItemDropResult(defId: 'item_mojianshi', quantity: 2),
                      ItemDropResult(
                        defId: 'item_scroll_test_manual',
                        quantity: 1,
                      ),
                    ],
                  ),
                  advancements: [
                    AdvancementEntry(chName: '甲', result: _advanced()),
                  ],
                  stats: const BattleStatsSummary(
                    totalDamage: 1234,
                    critCount: 3,
                    totalTicks: 9,
                  ),
                  injurySummaryCharacters: [_character(injuryHours: 2)],
                  skillFragmentLine: UiStrings.skillFragmentGainedLine(
                    '神龙一式',
                    3,
                    5,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text(UiStrings.stageVictoryEquipmentSection),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('showStageVictoryDialog', () {
    testWidgets('点确认按钮关闭 dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showStageVictoryDialog(
                  context: ctx,
                  stage: _stage(),
                  drops: _emptyDrops(),
                  advancements: const [],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.stageVictoryConfirm), findsOneWidget);
      expect(find.textContaining(UiStrings.stageVictoryTitle), findsOneWidget);

      await tester.tap(find.text(UiStrings.stageVictoryConfirm));
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.stageVictoryConfirm), findsNothing);
    });
  });

  group('showStageVictoryDialog 掉落 jingle', () {
    late _RecordingBackend rec;

    setUp(() {
      rec = _RecordingBackend();
      SoundManager.instance = SoundManager(rec);
    });

    tearDown(() {
      SoundManager.instance = SoundManager(const SilentAudioBackend());
    });

    Future<void> open(
      WidgetTester tester,
      DropResult drops, {
      List<AdvancementEntry> advancements = const [],
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showStageVictoryDialog(
                  context: ctx,
                  stage: _stage(),
                  drops: drops,
                  advancements: advancements,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // reward sfx 已移到 playTreasureDropIfAny 动画层(门槛化,2026-06-11):
    // showStageVictoryDialog 本身不再播 reward,任何装备掉落在 dialog 层均静默。
    testWidgets('含装备掉落 → dialog 层不播 reward(已移到动画层)', (tester) async {
      await open(tester, _equipDrops(['weapon_xunchang_tie_jian']));
      expect(rec.sfxPlays, isNot(contains(sfxAssetPath(SfxId.reward))));
    });

    testWidgets('纯道具掉落 → 不播 reward', (tester) async {
      await open(tester, _itemDrops());
      expect(rec.sfxPlays, isNot(contains(sfxAssetPath(SfxId.reward))));
    });

    testWidgets('空掉落 → 不播 reward', (tester) async {
      await open(tester, _emptyDrops());
      expect(rec.sfxPlays, isNot(contains(sfxAssetPath(SfxId.reward))));
    });

    testWidgets('跨 tier 大境界突破 → 播 realmAdvance jingle', (tester) async {
      await open(
        tester,
        _emptyDrops(),
        advancements: [AdvancementEntry(chName: '张三', result: _crossedTier())],
      );
      expect(rec.sfxPlays, contains(sfxAssetPath(SfxId.realmAdvance)));
    });

    testWidgets('同 tier 小层升级 → 不播 realmAdvance', (tester) async {
      await open(
        tester,
        _emptyDrops(),
        advancements: [AdvancementEntry(chName: '张三', result: _advanced())],
      );
      expect(rec.sfxPlays, isNot(contains(sfxAssetPath(SfxId.realmAdvance))));
    });

    testWidgets('跨 tier + 装备掉落 → 只播 realmAdvance,reward 让位不叠响', (tester) async {
      await open(
        tester,
        _equipDrops(['weapon_xunchang_tie_jian']),
        advancements: [AdvancementEntry(chName: '张三', result: _crossedTier())],
      );
      expect(rec.sfxPlays, contains(sfxAssetPath(SfxId.realmAdvance)));
      expect(rec.sfxPlays, isNot(contains(sfxAssetPath(SfxId.reward))));
    });
  });
}
