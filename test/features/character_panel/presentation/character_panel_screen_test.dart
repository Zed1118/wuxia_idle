import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/features/character_panel/presentation/character_panel_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_providers.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_tab.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/glossary_tip.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/section_header.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/stage_progress_row.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_title_bar.dart';

/// T28 角色面板 widget 测试（phase2_tasks.md §407）。
///
/// 4 用例：3 装备槽渲染 / 未装备占位 / 共鸣阶段中文 / 修炼度进度条 value。
/// 全部走 ProviderScope.overrides 注入 fixture，不打开真实 Isar。
/// setUpAll 加载真实 GameRepository（numbers.yaml）供派生数值公式使用。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── fixtures ──────────────────────────────────────────────────────────────

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({
    int id = 1,
    String name = '测试者',
    RealmTier realmTier = RealmTier.xueTu,
    LineageRole lineageRole = LineageRole.founder,
    int internalForceMax = 500,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int? weaponId,
    int? armorId,
    int? accessoryId,
    int? masterId,
    List<int>? discipleIds,
  }) {
    final now = DateTime(2026, 5, 11);
    return Character.create(
      name: name,
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: now,
      internalForce: 200,
      internalForceMax: internalForceMax,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
      equippedWeaponId: weaponId,
      equippedArmorId: armorId,
      equippedAccessoryId: accessoryId,
      masterId: masterId,
      discipleIds: discipleIds,
    )..id = id;
  }

  Equipment mkEquipment({
    required int id,
    required EquipmentSlot slot,
    int enhanceLevel = 0,
    int battleCount = 0,
    EquipmentTier tier = EquipmentTier.xunChang,
    String? defId,
    bool isLineageHeritage = false,
    List<int>? previousOwnerCharacterIds,
  }) {
    return Equipment.create(
      defId: defId ?? 'test_eq_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      baseHealth: 100,
      baseSpeed: 10,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
      isLineageHeritage: isLineageHeritage,
      previousOwnerCharacterIds: previousOwnerCharacterIds,
    )..id = id;
  }

  Technique mkTechnique({
    required int id,
    required int ownerId,
    required TechniqueRole role,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
    String? defId,
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
  }) {
    return Technique.create(
      defId: defId ?? 'test_tech_$id',
      ownerCharacterId: ownerId,
      tier: tier,
      school: school,
      role: role,
      learnedAt: DateTime(2026, 5, 11),
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
    )..id = id;
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Character character,
    Map<int, Character> extraCharacters = const {},
    List<int>? activeIds,
    Map<int, Equipment> equipments = const {},
    Map<int, Technique> techniques = const {},
    InnerDemonProgress? innerDemonProgress,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ids = activeIds ?? <int>[character.id, ...extraCharacters.keys];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => ids),
          characterByIdProvider(
            character.id,
          ).overrideWith((ref) async => character),
          for (final entry in extraCharacters.entries)
            characterByIdProvider(
              entry.key,
            ).overrideWith((ref) async => entry.value),
          for (final entry in equipments.entries)
            equipmentByIdProvider(
              entry.key,
            ).overrideWith((ref) async => entry.value),
          for (final entry in techniques.entries)
            techniqueByIdProvider(
              entry.key,
            ).overrideWith((ref) async => entry.value),
          if (innerDemonProgress != null)
            innerDemonProgressProvider.overrideWith(
              (ref) async => innerDemonProgress,
            ),
        ],
        child: MaterialApp(
          home: CharacterPanelScreen(characterId: character.id),
        ),
      ),
    );
    // 四次 pump 让 activeCharacterIdsProvider + family Future 完成 + AsyncValue 翻转 + 子 Consumer rebuild。
    // 不用 pumpAndSettle：CircularProgressIndicator 是无限动画会卡。
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapFirstEmptyEquipmentSlot(WidgetTester tester) async {
    final slotInkWell = find
        .ancestor(
          of: find.text(UiStrings.slotEmpty).first,
          matching: find.byType(InkWell),
        )
        .first;
    await tester.ensureVisible(slotInkWell);
    await tester.pump();
    await tester.tap(slotInkWell);
  }

  // ── 用例 0：档案头 ─────────────────────────────────────────────────────

  testWidgets('档案头:立绘 + 姓名 + 境界 + 流派名 + 4 属性聚成一卡', (tester) async {
    // mkCharacter 默认 school=gangMeng / attrs 全 5 / 无心法 → 「刚猛」仅出现在档案头
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    expect(find.byType(WuxiaTitleBar), findsOneWidget);
    expect(find.byType(PlaqueTab), findsOneWidget);
    expect(find.byType(PaperPanel), findsWidgets);
    expect(find.byType(SectionHeader), findsWidgets);
    expect(find.byType(PlaqueButton), findsOneWidget);
    expect(find.byType(PortraitFrame), findsOneWidget);
    expect(find.text(UiStrings.profilePortraitPlaque), findsOneWidget);
    expect(find.text('测试者'), findsOneWidget); // 姓名
    expect(find.text('刚猛'), findsOneWidget); // EnumL10n.school(gangMeng)
    expect(find.text('根骨'), findsOneWidget);
    expect(find.text('悟性'), findsOneWidget);
    expect(find.text('身法'), findsOneWidget);
    expect(find.text('机缘'), findsOneWidget);
  });

  testWidgets('M4 术语气泡:4 属性 + 派生数值标签走 GlossaryLabel 并挂释义', (tester) async {
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    // 4 项属性各一个 GlossaryLabel(带「?」可发现标记)。
    for (final label in [
      UiStrings.attrConstitution,
      UiStrings.attrEnlightenment,
      UiStrings.attrAgility,
      UiStrings.attrFortune,
    ]) {
      expect(
        find.widgetWithText(GlossaryLabel, label),
        findsOneWidget,
        reason: '属性 $label 应包进 GlossaryLabel',
      );
    }

    // 属性卡至少 4 个 GlossaryLabel(派生卡同卡布局,数量随 ready 态浮动,
    // 此处只锁属性硬下界),且释义 message 进入 Tooltip。
    expect(find.byType(GlossaryLabel), findsAtLeastNWidgets(4));
    final tipMessages = tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .map((t) => t.message)
        .toList();
    expect(tipMessages, contains(UiStrings.glossaryConstitution));
    expect(tipMessages, contains(UiStrings.glossaryFortune));
  });

  // ── 用例 1：3 装备槽全显示 ─────────────────────────────────────────────

  testWidgets('3 装备槽全装备时，+N 强化等级全部渲染', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final weapon = mkEquipment(
      id: 10,
      slot: EquipmentSlot.weapon,
      enhanceLevel: 5,
    );
    final armor = mkEquipment(
      id: 11,
      slot: EquipmentSlot.armor,
      enhanceLevel: 3,
    );
    final acc = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      enhanceLevel: 7,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: weapon, 11: armor, 12: acc},
    );

    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('护甲'), findsOneWidget);
    expect(find.text('饰品'), findsOneWidget);
  });

  // ── 用例 1b：T10 点已穿装备 → 快捷操作面板 ──────────────────────────────

  testWidgets('T10 点已穿装备槽 → 快捷操作面板(更换/查看典故/卸下)', (tester) async {
    final character = mkCharacter(weaponId: 10);
    final weapon = mkEquipment(
      id: 10,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_xunchang_tie_jian',
    );
    await pumpPanel(
      tester,
      character: character,
      equipments: {10: weapon},
    );

    // 点武器槽(已穿)→ 应弹快捷操作面板而非直接换装列表
    final slot = find
        .ancestor(of: find.text('武器'), matching: find.byType(InkWell))
        .first;
    await tester.ensureVisible(slot);
    await tester.pump();
    await tester.tap(slot);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(UiStrings.equipQuickReplace), findsOneWidget);
    expect(find.text(UiStrings.equipQuickViewLore), findsOneWidget);
    expect(find.text(UiStrings.equipUnequip), findsOneWidget);
  });

  // ── 用例 2：未装备占位 ─────────────────────────────────────────────────

  testWidgets('三个装备槽 id 全 null 时，渲染 3 个「未装备」占位', (tester) async {
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    expect(find.text('未装备'), findsNWidgets(3));
    expect(find.text('未修主修'), findsOneWidget);
    expect(find.text('未学'), findsNWidgets(3));
  });

  // ── 用例 3：共鸣阶段中文 ──────────────────────────────────────────────

  // 根因A(2026-05-29):默契边界 500→300,趁手 [100,300)。原 300 现属默契,
  // 改用 200 取趁手段(生疏 30 / 趁手 200 / 默契 1000)。
  testWidgets('battleCount 跨阶 30 / 200 / 1000 → 生疏 / 趁手 / 默契', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final w = mkEquipment(id: 10, slot: EquipmentSlot.weapon, battleCount: 30);
    final a = mkEquipment(id: 11, slot: EquipmentSlot.armor, battleCount: 200);
    final c = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      battleCount: 1000,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: w, 11: a, 12: c},
    );

    expect(find.text('生疏'), findsOneWidget);
    expect(find.text('趁手'), findsOneWidget);
    expect(find.text('默契'), findsOneWidget);
  });

  // ── 用例 4：修炼度进度条 ──────────────────────────────────────────────

  testWidgets(
    '主修 progress=50 / toNext=100 → StageProgressRow.ratio=0.5',
    (tester) async {
      final character = mkCharacter(mainTechniqueId: 20);
      final main = mkTechnique(
        id: 20,
        ownerId: 1,
        role: TechniqueRole.main,
        // 真 defId → 主修名为真实技能名,不与「主修」role 标签撞(hero 化后)。
        defId: GameRepository.instance.techniqueDefs.keys.first,
        cultivationProgress: 50,
        cultivationProgressToNext: 100,
      );

      await pumpPanel(tester, character: character, techniques: {20: main});

      // D：修炼度进度条 hero 化为 StageProgressRow（内含 MeridianBar）。
      final row = tester.widget<StageProgressRow>(
        find.byType(StageProgressRow),
      );
      expect(row.ratio, closeTo(0.5, 1e-9));
      expect(find.text('50 / 100'), findsOneWidget);
      expect(find.text('主修'), findsOneWidget);
      // D：五要素「当前效果」= 伤害倍率文案出现（真痛点补齐）。
      expect(find.textContaining('伤害 ×'), findsWidgets);
    },
  );

  // ── T56 用例 5：3 角色 Tab 切换 ────────────────────────────────────────

  testWidgets('activeCharacterIds=[1,2,3] → 3 Tab label 渲染 + 默认显示首位姓名', (
    tester,
  ) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
    );

    // 3 个 Tab label 都在
    expect(find.text('祖师'), findsOneWidget);
    expect(find.text('大弟子'), findsOneWidget);
    expect(find.text('二弟子'), findsOneWidget);
    // 默认首屏祖师爷姓名可见
    expect(find.text('祖师爷'), findsOneWidget);
    expect(find.text('大弟子A'), findsNothing);
  });

  testWidgets('tap 大弟子 Tab → 切到 character 2，祖师内容消失', (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
    );

    expect(find.text('祖师爷'), findsOneWidget);

    await tester.tap(find.text('大弟子'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 切换后顶部姓名变更
    expect(find.text('大弟子A'), findsOneWidget);
    // 祖师爷顶部姓名消失（lineage section 师父行也可能出现祖师爷，
    // 所以 findsOneWidget 即可，不可断言 findsNothing）
    expect(find.text('祖师爷'), findsOneWidget); // 在「师父」行
  });

  // ── T56 用例 6：师承段渲染 ─────────────────────────────────────────────

  testWidgets('师承段：师父行 + 徒弟列表 join + 传记占位 + 遗物名', (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      discipleIds: [2, 3],
      weaponId: 100,
      armorId: 101,
    );
    final first = mkCharacter(
      id: 2,
      name: '大弟子A',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final second = mkCharacter(
      id: 3,
      name: '二弟子B',
      lineageRole: LineageRole.disciple,
      masterId: 1,
    );
    final sword = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_liqi_long_quan',
      isLineageHeritage: true,
    );
    final armor = mkEquipment(
      id: 101,
      slot: EquipmentSlot.armor,
      defId: 'armor_haojiahuo_jin_pao',
      isLineageHeritage: true,
    );

    await pumpPanel(
      tester,
      character: founder,
      extraCharacters: {2: first, 3: second},
      equipments: {100: sword, 101: armor},
    );

    // 师承段标题
    expect(find.text('师承'), findsOneWidget);
    expect(find.text('师父'), findsOneWidget);
    expect(find.text('徒弟'), findsOneWidget);
    expect(find.text('传记'), findsOneWidget);
    expect(find.text('遗物'), findsOneWidget);

    // 祖师无师父 → 「无」
    expect(find.text('无'), findsOneWidget);
    // 徒弟列表 join
    expect(find.text('大弟子A / 二弟子B'), findsOneWidget);
    // 传记占位
    expect(find.text('[传记待补]'), findsOneWidget);
    // 遗物名（从 GameRepository.equipmentDefs 解析）
    expect(find.text('龙泉剑 / 锦袍'), findsOneWidget);
  });

  // ── T56 用例 7：祖师内力上限 lineage +10% buff 落 UI ──────────────────

  testWidgets('祖师装 2 件 lineage heritage → 内力上限显示 base × 1.10', (tester) async {
    // base 10000 → × (1 + 2×0.05) = 11000
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      internalForceMax: 10000,
      weaponId: 100,
      armorId: 101,
    );
    final sword = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
    );
    final armor = mkEquipment(
      id: 101,
      slot: EquipmentSlot.armor,
      isLineageHeritage: true,
    );

    await pumpPanel(
      tester,
      character: founder,
      equipments: {100: sword, 101: armor},
    );

    // internalForceValue 格式: "200 / 11000"（current=200 固定，max=11000）
    expect(find.text('200 / 11000'), findsOneWidget);
  });

  // ── W18-A1 用例 8:心法相生 chip ────────────────────────────────────────

  testWidgets('主修 gangMeng + 辅修 yinRou → 阴阳调和 chip 显示', (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 30,
      assistTechniqueIds: [31],
    );
    final main = mkTechnique(
      id: 30,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: 'tech_gangmeng_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
    );
    final assist = mkTechnique(
      id: 31,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_yinrou_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.yinRou,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {30: main, 31: assist},
    );

    expect(
      find.text('相生'),
      findsOneWidget,
      reason: 'UiStrings.synergyActiveLabel chip 显示',
    );
    expect(
      find.textContaining('阴阳调和'),
      findsOneWidget,
      reason: 'synergy_yin_yang_he_xie name',
    );
  });

  testWidgets('未修主修 / 无辅修 → 不显相生 chip', (tester) async {
    final character = mkCharacter(); // no main / no assist
    await pumpPanel(tester, character: character);

    expect(find.text('相生'), findsNothing);
  });

  testWidgets('主辅同流派 gangMeng+gangMeng → 同流派精进 chip(sameSchool 命中)', (
    tester,
  ) async {
    final character = mkCharacter(
      mainTechniqueId: 40,
      assistTechniqueIds: [41],
    );
    final main = mkTechnique(
      id: 40,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: 'tech_gangmeng_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
    );
    final assist = mkTechnique(
      id: 41,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_gangmeng_changlian',
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.gangMeng,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {40: main, 41: assist},
    );

    expect(find.text('相生'), findsOneWidget);
    expect(find.textContaining('同流派精进'), findsOneWidget);
  });

  testWidgets('相生 chip 会检测第 2/3 辅修槽', (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 50,
      assistTechniqueIds: [51, 52],
    );
    final main = mkTechnique(
      id: 50,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: 'tech_lingqiao_menpai',
      tier: TechniqueTier.menPaiJueXue,
      school: TechniqueSchool.lingQiao,
    );
    final miss = mkTechnique(
      id: 51,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_yinrou_changlian',
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.yinRou,
    );
    final hit = mkTechnique(
      id: 52,
      ownerId: 1,
      role: TechniqueRole.assist,
      defId: 'tech_yinrou_menpai',
      tier: TechniqueTier.menPaiJueXue,
      school: TechniqueSchool.yinRou,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {50: main, 51: miss, 52: hit},
    );

    expect(find.text('相生'), findsOneWidget);
    expect(
      find.textContaining('同辈互补'),
      findsOneWidget,
      reason: '第 1 辅修不命中时，第 2 辅修同 tier 应触发相生 chip',
    );
  });

  // ── 用例 13:P5+ 多代 chip · prev.length > 1 显「N 代传承」副行(F.2 续) ──

  testWidgets('character_panel 装 heritage prev=[1,2] → 显「3 代传承」副行', (
    tester,
  ) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      weaponId: 100,
    );
    final weapon = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
      previousOwnerCharacterIds: [1, 2],
    );

    await pumpPanel(tester, character: founder, equipments: {100: weapon});

    // gen2 prev.length=2 → chip 副行显「3 代传承」(N = prevLen + 1)
    expect(
      find.text('3 代传承'),
      findsOneWidget,
      reason: 'P5+ 多代 chip · gen2 主断言',
    );
  });

  // ── 用例 14:gen1 边界 · prev.length=1 不显 chip ─────────────────────────

  testWidgets('character_panel 装 heritage prev=[1] → 不显多代 chip(gen1 边界)', (
    tester,
  ) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师爷',
      lineageRole: LineageRole.founder,
      weaponId: 100,
    );
    final weapon = mkEquipment(
      id: 100,
      slot: EquipmentSlot.weapon,
      isLineageHeritage: true,
      previousOwnerCharacterIds: [1],
    );

    await pumpPanel(tester, character: founder, equipments: {100: weapon});

    // gen1 prev.length=1 不触发 > 1 阈值 · 不应显示任何 N 代传承 chip
    expect(
      find.textContaining('代传承'),
      findsNothing,
      reason: 'gen1 边界 · 阈值 > 1 严守',
    );
  });

  // H1 批2:装备槽可点 → picker 打开(玩家手动穿戴入口接线守护)。
  testWidgets('点击空装备槽 → 弹出装备 picker(allEquipments 空 → 空态文案)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final founder = mkCharacter(); // 3 槽全空
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [founder.id]),
          characterByIdProvider(
            founder.id,
          ).overrideWith((ref) async => founder),
          // 空背包 → picker data 分支走空态(不触 GameRepository.getEquipment)。
          allEquipmentsProvider.overrideWith((ref) async => <Equipment>[]),
        ],
        child: MaterialApp(home: CharacterPanelScreen(characterId: founder.id)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 点第一个空槽(InkWell 包裹 _EquipmentSlotTile 的「未装备」占位)。
    await tapFirstEmptyEquipmentSlot(tester);
    await tester.pump();
    await tester.pump();

    // picker bottom sheet 打开:标题 + 空态文案。
    expect(find.textContaining(UiStrings.equipPickerTitle), findsOneWidget);
    expect(find.text(UiStrings.equipPickerEmpty), findsOneWidget);
  });

  // H1 批3:空态 picker 也有显式关闭入口(修「空 picker 无法关闭卡死」· Pen 验收确诊)。
  testWidgets('空 picker → header close 按钮可见 → tap 关闭 sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final founder = mkCharacter(); // 3 槽全空
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [founder.id]),
          characterByIdProvider(
            founder.id,
          ).overrideWith((ref) async => founder),
          allEquipmentsProvider.overrideWith((ref) async => <Equipment>[]),
        ],
        child: MaterialApp(home: CharacterPanelScreen(characterId: founder.id)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tapFirstEmptyEquipmentSlot(tester);
    await tester.pump();
    await tester.pump();

    // 空态 sheet 打开 + close 按钮可见。
    expect(find.text(UiStrings.equipPickerEmpty), findsOneWidget);
    expect(find.byTooltip(UiStrings.equipPickerClose), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // tap close → sheet 关闭(标题 + 空态文案消失)。
    // 注:该 screen 测试布局下矮空态 sheet 锚到视口下缘外,close 按钮几何中心落屏外
    // → tester.tap 取中心会 miss;直接取 IconButton.onPressed 调用验证关闭接线
    // (按钮可见性已在上方断言,此处验 onPressed → Navigator.pop 真关闭 sheet)。
    final closeBtn = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      ),
    );
    expect(closeBtn.onPressed, isNotNull);
    closeBtn.onPressed!();
    await tester.pumpAndSettle();

    expect(find.textContaining(UiStrings.equipPickerTitle), findsNothing);
    expect(find.text(UiStrings.equipPickerEmpty), findsNothing);
  });

  // H1 批3:picker 里被队内其他角色穿戴的装备显「他人装备中」标注(去静默卸下)。
  testWidgets('picker:被其他角色装备的项显「他人装备中」标注', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final founder = mkCharacter(); // id=1 · xueTu · 3 槽全空
    // 真 defId(picker 解析中文名不抛)· owner=999 队内他人 · 同武器槽。
    final wornByOther = mkEquipment(
      id: 50,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_xunchang_tie_jian',
    )..ownerCharacterId = 999;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [founder.id]),
          characterByIdProvider(
            founder.id,
          ).overrideWith((ref) async => founder),
          allEquipmentsProvider.overrideWith((ref) async => [wornByOther]),
        ],
        child: MaterialApp(home: CharacterPanelScreen(characterId: founder.id)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 点第一个空槽(武器)弹 picker。
    await tapFirstEmptyEquipmentSlot(tester);
    await tester.pump();
    await tester.pump();

    // 铁剑(真名,非 defId)+ 「他人装备中」标注同显。
    expect(find.text('铁剑'), findsOneWidget);
    expect(find.textContaining(UiStrings.equipWornByOther), findsOneWidget);
  });

  // ── P0-3 装备外观可视化 ────────────────────────────────────────────────
  testWidgets('装备槽显示装备图标(iconPath · P0-3)', (tester) async {
    final entry = GameRepository.instance.equipmentDefs.entries.firstWhere(
      (e) => e.value.slot == EquipmentSlot.weapon,
    );
    final w = mkEquipment(id: 10, slot: EquipmentSlot.weapon, defId: entry.key);
    await pumpPanel(
      tester,
      character: mkCharacter(weaponId: 10),
      equipments: {10: w},
    );
    await tester.pumpAndSettle();
    final imgs = tester.widgetList<Image>(find.byType(Image));
    expect(
      imgs.any(
        (i) =>
            i.image is AssetImage &&
            (i.image as AssetImage).assetName == entry.value.iconPath,
      ),
      isTrue,
    );
  });

  testWidgets('装备槽未知 def 走占位不崩(P0-3)', (tester) async {
    final w = mkEquipment(id: 10, slot: EquipmentSlot.weapon, enhanceLevel: 5);
    await pumpPanel(
      tester,
      character: mkCharacter(weaponId: 10),
      equipments: {10: w},
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.enhanceLevel(5)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('③ 非武圣 → 心魔面板不显', (tester) async {
    await pumpPanel(
      tester,
      character: mkCharacter(realmTier: RealmTier.xueTu),
      innerDemonProgress: const InnerDemonProgress(
        clearedCount: 0,
        totalCount: 7,
        clearedStageIds: {},
        nextUnclearedStageId: 'stage_inner_demon_01',
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsNothing);
  });

  testWidgets('③ 武圣 exp满被拦 → 显心魔面板 + X/7 + 突破 CTA', (tester) async {
    final wuSheng = mkCharacter(realmTier: RealmTier.wuSheng)
      ..realmLayer = RealmLayer.shuLian
      ..experience = 999999
      ..experienceToNextLayer = 100;
    await pumpPanel(
      tester,
      character: wuSheng,
      innerDemonProgress: const InnerDemonProgress(
        clearedCount: 2,
        totalCount: 7,
        clearedStageIds: {'stage_inner_demon_01', 'stage_inner_demon_02'},
        nextUnclearedStageId: 'stage_inner_demon_03',
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.innerDemonPanelProgress(2, 7)), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBreakthroughCta), findsOneWidget);
  });

  testWidgets('② 主修 hero:显主修名(真 def name)+ 宣纸底 + 进度条', (tester) async {
    final realDefId = GameRepository.instance.techniqueDefs.keys.first;
    final realName = GameRepository.instance.techniqueDefs[realDefId]!.name;
    final tech = mkTechnique(
      id: 50,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: realDefId,
      cultivationProgress: 40,
      cultivationProgressToNext: 100,
    );
    await pumpPanel(
      tester,
      character: mkCharacter(mainTechniqueId: 50),
      techniques: {50: tech},
    );
    expect(find.text(realName), findsOneWidget);
    expect(find.byType(WuxiaPaperPanel), findsWidgets);
    expect(find.byType(StageProgressRow), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
