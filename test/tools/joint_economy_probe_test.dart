// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart'
    show ExpeditionPolicy;

import '../support/joint_economy_model.dart';
import '../support/test_data.dart';

/// 百草岭×断魂庄×装备强化 联合经济与时间吞吐探针（plan
/// `2026-07-15-baicao-duanhun-joint-economy-probe.md` Task 2）。
///
/// 五段吞吐链跑快/中/慢三档 → print 三档 YAML 候选供用户拍板 Lv100→170 目标
/// 天数，反推 `expeditions.yaml` `base_exp_per_battle` 初值。四不变式 ratchet
/// 守经济健康：①命名装备助炼不压倒 ②结晶无自反馈失控 ③三路径真实取舍
/// ④无强制等待。诊断测，非玩法代码。
///
/// **占位口径（Phase C 前）**：`gauntletWinRate` / `namedEquipAidContribution`
/// 见 model 头注；`_assumedCrystalPerDay`（断魂庄命名装备分解产结晶日流入）与
/// herb→补给转化率取保守占位，真值待 Phase C1.3 战斗探针 + 断魂庄产出校准。

const String _outputDir = 'test/tools/output';

/// 代表性稳态挂机深度（中期玩家单趟远征平均推进节点数，depth>30 exp 封顶）。
const int _representativeDepth = 20;

/// 挂机 = 离线（§5.5），按理论满挂 24h/天换算节奏上限。
const int _idleHoursPerDay = 24;

/// 断魂庄每战最多托管补给份数（boss_gauntlets.yaml `supply_cap`）。
const int _gauntletSupplyCapPerEntry = 3;

/// 占位：约 1 件神物阶命名装备分解/天的结晶净流入（神物阶分解 8 颗，
/// numbers.yaml disposal.disassemble_xinxuejiejing[6]=8）。真产率待 Phase C
/// 断魂庄命名装备产出频率校准。
const double _assumedCrystalPerDay = 8.0;

class _EconomyTier {
  const _EconomyTier(this.name, this.baseExpPerBattle);
  final String name;
  final int baseExpPerBattle;
}

/// 三档候选：快/中/慢的 `base_exp_per_battle`（depth20 反推 ~10/18/30 天）。
const List<_EconomyTier> _tiers = [
  _EconomyTier('快', 300),
  _EconomyTier('中', 170),
  _EconomyTier('慢', 100),
];

void main() {
  late GameRepository repo;
  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('三档经济探针 + 四不变式 ratchet', () {
    final totalExp = expToTraverseAbsLevels(
      realmByAbs: repo.getRealmByAbsoluteLevel,
      fromAbs: 10,
      toAbs: 17,
    );
    final g30 = guaranteeCrystalCostTo(repo.numbers.enhancement, 30);
    final g40 = guaranteeCrystalCostTo(repo.numbers.enhancement, 40);
    final g49 = guaranteeCrystalCostTo(repo.numbers.enhancement, 49);
    final enhance30Days = enhanceReachDays(
      guaranteeCrystalCost: g30,
      crystalPerDay: _assumedCrystalPerDay,
    );
    final enhance40Days = enhanceReachDays(
      guaranteeCrystalCost: g40,
      crystalPerDay: _assumedCrystalPerDay,
    );
    final enhance49Days = enhanceReachDays(
      guaranteeCrystalCost: g49,
      crystalPerDay: _assumedCrystalPerDay,
    );

    final buf = StringBuffer()
      ..writeln('# 百草岭×断魂庄×装备强化 联合经济探针')
      ..writeln()
      ..writeln('> 诊断探针（plan Task 2）。代表深度=$_representativeDepth，'
          '挂机=离线按 ${_idleHoursPerDay}h/天。占位段（胜率/助炼/结晶日流入/'
          'herb→补给转化）待 Phase C 校准。')
      ..writeln()
      ..writeln('Lv100→170 (abs层10→17) 总经验 = **$totalExp**')
      ..writeln()
      ..writeln('## Lv100→170 节奏三档（供拍板目标天数）')
      ..writeln()
      ..writeln('| 档 | base_exp_per_battle | exp/小时 | Lv100→170 天数 | 断魂帖/天 | 断魂庄入场/天(稳态) |')
      ..writeln('|---|---:|---:|---:|---:|---:|');

    for (final t in _tiers) {
      final y = baicaoHourlyYield(
        policy: ExpeditionPolicy.yiZhanLiXing,
        avgDepth: _representativeDepth,
        baseExpPerBattle: t.baseExpPerBattle,
      );
      final days = daysToTraverse(totalExp: totalExp, expPerHour: y.expPerHour);
      final entries = gauntletEntryRate(
        ticketStock: 0,
        ticketPerHour: y.ticketPerHour,
      );
      buf.writeln(
        '| ${t.name} | ${t.baseExpPerBattle} | ${y.expPerHour.toStringAsFixed(1)} '
        '| ${days.toStringAsFixed(1)} '
        '| ${(y.ticketPerHour * _idleHoursPerDay).toStringAsFixed(2)} '
        '| ${entries.sustainableEntriesPerDay.toStringAsFixed(2)} |',
      );
    }

    buf
      ..writeln()
      ..writeln('## 装备强化到达时间（结晶净流入占位 '
          '$_assumedCrystalPerDay 颗/天）')
      ..writeln()
      ..writeln('| 目标 | 保底结晶消耗 | 预期天数 |')
      ..writeln('|---|---:|---:|')
      ..writeln('| +30 | $g30 | ${enhance30Days.toStringAsFixed(1)} |')
      ..writeln('| +40 | $g40 | ${enhance40Days.toStringAsFixed(1)} |')
      ..writeln('| +49 | $g49 | ${enhance49Days.toStringAsFixed(1)} |')
      ..writeln()
      ..writeln('## 断魂庄三档阵容胜率（占位·C1.3 对齐）')
      ..writeln()
      ..writeln('- 入门 ${gauntletWinRate(GauntletLoadout.ruMen)} / '
          '推荐 ${gauntletWinRate(GauntletLoadout.tuiJian)} / '
          '满配 ${gauntletWinRate(GauntletLoadout.manPei)}')
      ..writeln()
      ..writeln('## 三档 YAML 候选（回填 expeditions.yaml）')
      ..writeln();
    for (final t in _tiers) {
      final days = daysToTraverse(
        totalExp: totalExp,
        expPerHour: baicaoHourlyYield(
          policy: ExpeditionPolicy.yiZhanLiXing,
          avgDepth: _representativeDepth,
          baseExpPerBattle: t.baseExpPerBattle,
        ).expPerHour,
      );
      buf.writeln('# ${t.name}档 → Lv100→170 ~${days.toStringAsFixed(0)}天');
      buf.writeln('base_exp_per_battle: ${t.baseExpPerBattle}');
      buf.writeln();
    }

    // ---- 四不变式 ratchet ----

    // ① 命名装备助炼不压倒（硬断言，纯模型）。
    final aid = namedEquipAidContribution(20);
    buf.writeln('## 四不变式 ratchet');
    buf.writeln('① 命名装备助炼贡献(堆20件) = ${aid.toStringAsFixed(1)}pp ≤ 25pp');
    expect(
      aid,
      lessThanOrEqualTo(25.0),
      reason: '同名命名装备堆叠助炼贡献超 25pp → 收藏/多样性失去意义',
    );

    // ② 结晶无自反馈失控（软断言，日流入不应 <10 天攒够单件 +49）。
    buf.writeln('② 结晶日流入 $_assumedCrystalPerDay ≤ ${(g49 / 10).toStringAsFixed(1)}'
        '(+49需求÷10天下界·占位待Phase C)');
    expect(
      _assumedCrystalPerDay,
      lessThanOrEqualTo(g49 / 10),
      reason: '结晶日净流入过快(<10天攒够单件+49)→自反馈失控；真产率待 Phase C 校准',
    );

    // ④ 无强制等待：采药方针补给产能 ≥ 断魂庄消耗（herb→补给保守 1:1 转化占位）。
    final caiyao = baicaoHourlyYield(
      policy: ExpeditionPolicy.yanJingCaiYao,
      avgDepth: _representativeDepth,
    );
    final herbPerDay = caiyao.herbPerHour * _idleHoursPerDay;
    final gauntletEntriesPerDay = caiyao.ticketPerHour * _idleHoursPerDay;
    final supplyDemandPerDay = gauntletEntriesPerDay * _gauntletSupplyCapPerEntry;
    buf.writeln('④ 采药方针补给产能 ${herbPerDay.toStringAsFixed(1)}/天 ≥ '
        '断魂庄消耗 ${supplyDemandPerDay.toStringAsFixed(1)}/天'
        '(入场${gauntletEntriesPerDay.toStringAsFixed(2)}×$_gauntletSupplyCapPerEntry份·1:1转化占位)');
    expect(
      herbPerDay,
      greaterThanOrEqualTo(supplyDemandPerDay),
      reason: '采药补给产能 < 断魂庄消耗 → 形成强制日课型等待(违 §5.5/§7)；'
          'herb→补给转化率待 Phase C 校准',
    );

    // ③ 三路径真实取舍：助炼/分解/收藏收益未在 Phase C 前实装，仅记录待校准，
    //    不硬断言（避免占位假绿）。
    buf.writeln('③ 助炼/分解/收藏三路径取舍：待 Phase C 断魂庄产出 + 助炼机制'
        '定案后补硬 ratchet（本批不硬断言，防占位假绿）');

    // 存量溢出连跳分布（A2 同源探针结论纳入本报告，§3.1）。
    buf
      ..writeln()
      ..writeln('## 存量溢出连跳分布（§3.1·A2 同源 overflow_layer_jump_probe）')
      ..writeln()
      ..writeln('cap 10→17 一次性兑现：停在 Lv100 封顶的存量经验按层均单位 '
          '1×~12× 实测连跳 1-6 层（worstJump ≤7 ratchet 守），判定**一次性兑现**'
          '（非分段抬升 10→13→17）。详 `test/tools/overflow_layer_jump_probe_test.dart`。')
      ..writeln()
      ..writeln('> 探针留作 ratchet：本探针四不变式 + overflow worstJump ≤7 '
          '一并守后续经济数值改动不破坏 Lv100→170 曲线。');

    Directory(_outputDir).createSync(recursive: true);
    final out = '$_outputDir/joint_economy_probe_2026-07-16.md';
    File(out).writeAsStringSync(buf.toString());
    print(buf.toString());
    print('joint_economy_probe done · summary=$out');
  });
}
