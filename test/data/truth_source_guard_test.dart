import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 真相源守卫(2026-07-24 外审 triage 落地)。
///
/// A. GDD 头部「当前状态块」必须与生产真值一致——cap 读 numbers.yaml、
///    章数/关数统计 stages.yaml。加章 reconcile 漏更状态块时此测红,
///    防 GDD 头部快照再漂移(07-21/07-24 两轮外审同病根)。
///    **2026-07-31 扩覆盖到玩家可见文案**:原守卫只钉 GDD.md,
///    `UiStrings` 里同样写死章数的两条不在覆盖内,于是
///    `mainlineRouteMapSubtitle` 一路 drift 到「十六章」而实况已 21 章
///    (既有测试只 `find.text(常量)` 引用常量本身、不钉字面量,拦不住)。
/// B. 已退役配置字段不得复活(v1.34 战败不扣内力,
///    `boss_internal_force_penalty` 2026-07-24 删除)。
/// C. **其余玩法的规模类文案同样从生产真值派生**(2026-08-01 阶段性审查 P1-1)。
///    A 那轮只把主线两条纳入守卫,同类「写死规模数字」的文案还有 13 条在覆盖外
///    (塔 30 层 ×5 / 心魔 7 关 ×2 / 轻功 5 ×2 / 群战 5 ×2 / 断魂庄 3 关 ×2 /
///    闭关 5 图 ×1);当时逐条实测值全部正确,故本组不是修 bug,是**堵住下一次
///    扩内容时的静默 drift**——章数那处正是无守卫地活了 5 个章才被发现。

/// 阿拉伯数字转中文数字(覆盖 1-99,够主线章数用)。
String cnNum(int n) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  if (n < 10) return digits[n];
  if (n < 20) return n == 10 ? '十' : '十${digits[n % 10]}';
  final tens = '${digits[n ~/ 10]}十';
  return n % 10 == 0 ? tens : '$tens${digits[n % 10]}';
}

/// 在**数字边界处**匹配 [token] 的 matcher。
///
/// 纯 `contains` 会被子串反向漏网:规模从 15 缩到 5 时,旧文案「15 关」仍然
/// 含有「5 关」而假绿;中文侧同理(「十五处」含「五处」)。故在数字前加一道
/// 反向断言,要求紧邻位置不是同类数字字符。
Matcher scaleToken(String token, {required bool chinese}) {
  final guard = chinese ? '零一二三四五六七八九十百' : '0-9';
  return matches(RegExp('(?<![$guard])${RegExp.escape(token)}'));
}

void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  group('A · GDD 当前状态块 ↔ 生产真值一致', () {
    test('发布上限/章数/关数与 numbers.yaml + stages.yaml 一致', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final gdd = File('GDD.md').readAsStringSync();

      final cap = repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel;
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();
      final chapterCount = mainlines.map((s) => s.chapterIndex).toSet().length;

      expect(
        gdd,
        contains('绝对境界层 **$cap**'),
        reason:
            'GDD 头部当前状态块发布上限与 numbers.yaml '
            'progression.release_cap.max_absolute_realm_level=$cap 漂移,'
            '加章 reconcile 须同步状态块',
      );
      expect(
        gdd,
        contains('**$chapterCount 章 ${mainlines.length} 关**'),
        reason:
            'GDD 头部当前状态块主线规模与 stages.yaml 实况'
            '($chapterCount 章 ${mainlines.length} 关)漂移,'
            '加章 reconcile 须同步状态块',
      );
    });

    test('玩家可见主线规模文案与 stages.yaml 一致', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();
      final chapterCount = mainlines.map((s) => s.chapterIndex).toSet().length;

      expect(
        UiStrings.mainMenuMainlineHint,
        contains('$chapterCount 章 ${mainlines.length} 关'),
        reason:
            '主菜单主线副标题与 stages.yaml 实况'
            '($chapterCount 章 ${mainlines.length} 关)漂移,加章 reconcile 须同步',
      );
      expect(
        UiStrings.mainlineRouteMapSubtitle,
        startsWith('${cnNum(chapterCount)}章'),
        reason:
            '江湖路引副标题章数与 stages.yaml 实况($chapterCount 章)漂移;'
            '该处用中文数字体例,期望以「${cnNum(chapterCount)}章」开头',
      );

      // 同一条副标题还写着「每章五关」,是第二个独立的规模断言(2026-08-01 补)。
      final perChapter = mainlines
          .map((s) => s.chapterIndex)
          .toSet()
          .map((c) => mainlines.where((s) => s.chapterIndex == c).length)
          .toSet();
      expect(
        perChapter,
        hasLength(1),
        reason:
            '江湖路引副标题声称「每章 N 关」,前提是各章关数一致;'
            'stages.yaml 实况各章关数为 $perChapter 已不统一,'
            '该副标题须改写(不能再作统一声明)',
      );
      expect(
        UiStrings.mainlineRouteMapSubtitle,
        scaleToken('每章${cnNum(perChapter.single)}关', chinese: true),
        reason:
            '江湖路引副标题每章关数与 stages.yaml 实况'
            '(每章 ${perChapter.single} 关)漂移',
      );
    });
  });

  group('B · 退役配置防复活', () {
    test('boss_internal_force_penalty 不得重回 numbers.yaml', () {
      final yaml = File('data/numbers.yaml').readAsStringSync();
      expect(
        yaml.contains('boss_internal_force_penalty:'),
        isFalse,
        reason:
            'v1.34 起战败不扣永久内力(只施加内息紊乱),该配置键 '
            '2026-07-24 已退役删除;如需恢复须先回 GDD §4.3 讨论',
      );
    });
  });

  group('C · 各玩法规模文案 ↔ 生产真值一致', () {
    late GameRepository repo;

    setUpAll(() async {
      repo = await GameRepository.loadAllDefs(loader: fileLoader);
    });

    int stageCountOf(StageType type) =>
        repo.stageDefs.values.where((s) => s.stageType == type).length;

    /// 规模文案共用的失败说明:告诉撞红的人「改哪边」。
    String why(String where, String source, int n) =>
        '$where 写死的规模数字与生产真值($source = $n)漂移。'
        '扩内容时请同步该文案,不要只改 yaml——玩家看到的是这行字';

    test('爬塔 30 层五条文案与 towers.yaml 一致', () {
      final floors = repo.towerFloors.length;
      expect(floors, greaterThan(0), reason: 'towers.yaml 未加载,后续断言无意义');

      // 阿拉伯数字体例三条
      for (final entry in {
        'mainMenuTowerHint': UiStrings.mainMenuTowerHint,
        'towerCycleReadyHint': UiStrings.towerCycleReadyHint,
        'sweepTowerButton': UiStrings.sweepTowerButton,
      }.entries) {
        expect(
          entry.value,
          scaleToken('$floors 层', chinese: false),
          reason: why('UiStrings.${entry.key}', 'towerFloors.length', floors),
        );
      }

      // 中文数字体例两条
      for (final entry in {
        'mainMenuTowerCompleteStatus': UiStrings.mainMenuTowerCompleteStatus,
        'towerNextMilestoneComplete': UiStrings.towerNextMilestoneComplete,
      }.entries) {
        expect(
          entry.value,
          scaleToken('${cnNum(floors)}层', chinese: true),
          reason: why('UiStrings.${entry.key}', 'towerFloors.length', floors),
        );
      }
    });

    test('心魔 7 关两条文案与 stages.yaml 一致', () {
      final n = stageCountOf(StageType.innerDemon);
      expect(n, greaterThan(0), reason: '心魔关未加载,后续断言无意义');

      expect(
        UiStrings.mainMenuInnerDemonHint,
        scaleToken('$n 关', chinese: false),
        reason: why('UiStrings.mainMenuInnerDemonHint', 'innerDemon 关数', n),
      );
      expect(
        UiStrings.innerDemonEmpty,
        scaleToken('${cnNum(n)}关', chinese: true),
        reason: why('UiStrings.innerDemonEmpty', 'innerDemon 关数', n),
      );
    });

    test('轻功 5 关两条文案与 stages.yaml 一致', () {
      final n = stageCountOf(StageType.lightFoot);
      expect(n, greaterThan(0), reason: '轻功关未加载,后续断言无意义');

      expect(
        UiStrings.mainMenuLightFootHint,
        scaleToken('$n 关', chinese: false),
        reason: why('UiStrings.mainMenuLightFootHint', 'lightFoot 关数', n),
      );
      // 空态文案量词用「处」不用「关」,体例不同但同源
      expect(
        UiStrings.lightFootEmpty,
        scaleToken('${cnNum(n)}处', chinese: true),
        reason: why('UiStrings.lightFootEmpty', 'lightFoot 关数', n),
      );
    });

    test('群战 5 关两条文案与 stages.yaml 一致', () {
      final n = stageCountOf(StageType.massBattle);
      expect(n, greaterThan(0), reason: '群战关未加载,后续断言无意义');

      expect(
        UiStrings.mainMenuMassBattleHint,
        scaleToken('$n 关', chinese: false),
        reason: why('UiStrings.mainMenuMassBattleHint', 'massBattle 关数', n),
      );
      expect(
        UiStrings.massBattleEmpty,
        scaleToken('${cnNum(n)}处', chinese: true),
        reason: why('UiStrings.massBattleEmpty', 'massBattle 关数', n),
      );
    });

    test('断魂庄 3 关两条文案与 boss_gauntlets.yaml 一致', () {
      final config = repo.bossGauntletConfig;
      expect(config, isNotNull, reason: 'boss_gauntlets.yaml 未加载,后续断言无意义');
      // 真相源取 stages.length 而非 supply_cap——两者当前恰好都是 3,
      // 但 supply_cap 是补给上限、与关次数无因果,不可拿来当规模真相源。
      final n = config!.stages.length;
      expect(n, greaterThan(0), reason: '断魂庄关次为空,后续断言无意义');

      expect(
        UiStrings.gauntletSubtitle,
        scaleToken('${cnNum(n)}关', chinese: true),
        reason: why(
          'UiStrings.gauntletSubtitle',
          'bossGauntletConfig.stages.length',
          n,
        ),
      );
      expect(
        UiStrings.gauntletEnemiesSection,
        scaleToken('${cnNum(n)}关', chinese: true),
        reason: why(
          'UiStrings.gauntletEnemiesSection',
          'bossGauntletConfig.stages.length',
          n,
        ),
      );
    });

    test('闭关 5 张地图文案与 seclusion 配置一致', () {
      final n = repo.seclusionMaps.length;
      expect(n, greaterThan(0), reason: '闭关地图未加载,后续断言无意义');

      expect(
        UiStrings.mainMenuSeclusionHint,
        scaleToken('$n 张地图', chinese: false),
        reason: why(
          'UiStrings.mainMenuSeclusionHint',
          'seclusionMaps.length',
          n,
        ),
      );
    });
  });
}
