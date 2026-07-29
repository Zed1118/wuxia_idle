import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'desktop_semantics_audit.dart';

/// 桌面语义门禁(CLAUDE §8.2)。
///
/// 守的是「`InkWell`→`GestureDetector` 一类改动易丢桌面语义」这条:
/// `GestureDetector` 不提供 Semantics / 焦点 / 键盘激活 / 鼠标光标中的任何一项,
/// 新写一个裸的进来就等于新开一个键盘不可达的交互点。本测双向棘轮——
/// 既拦新增未覆盖站点,也拦 allowlist 里的条目在修好后忘记销账。
void main() {
  const allowlistPath = 'test/fixtures/desktop_semantics_allowlist.txt';

  Set<String> readAllowlist() {
    final file = File(allowlistPath);
    expect(file.existsSync(), isTrue, reason: '缺 allowlist 文件:$allowlistPath');
    return file
        .readAsLinesSync()
        .map((line) => line.split('#').first.trim())
        .where((line) => line.isNotEmpty)
        .toSet();
  }

  test('lib/ 下每个 GestureDetector 要么键盘可达,要么在 allowlist 里登记了理由', () {
    final sites = collectGestureDetectorSites();
    expect(sites, isNotEmpty, reason: '一个站点都没扫到 = 扫描器坏了,不是代码干净了');

    final allowlist = readAllowlist();
    final offenders = sites
        .where((s) => !s.covered && !allowlist.contains(s.key))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          '新增了键盘不可达的 GestureDetector:\n'
          '${offenders.map((o) => '  ${o.key}').join('\n')}\n'
          '两条出路:① 用 DismissLayer / FocusableActionDetector / InkWell 包起来;'
          '② 若同屏另有键盘可达的真按钮能完成同一操作,把它登记进 $allowlistPath 并写明理由。',
    );
  });

  test('allowlist 里没有已失效条目(修好了要销账 / 行号漂了要更新)', () {
    final sites = collectGestureDetectorSites();
    final uncoveredKeys = sites
        .where((s) => !s.covered)
        .map((s) => s.key)
        .toSet();
    final stale = readAllowlist()
        .where((entry) => !uncoveredKeys.contains(entry))
        .toList();

    expect(
      stale,
      isEmpty,
      reason:
          'allowlist 有失效条目(该站点已键盘可达、已删除,或行号已漂移):\n'
          '${stale.map((s) => '  $s').join('\n')}\n'
          '修好了就从 $allowlistPath 删掉;只是行号漂了就重新定位后更新行号。',
    );
  });

  test('shared/ 下的复用基元一个都不许落在 allowlist 里', () {
    // 基元(PlaqueButton / WuxiaIconButton / PlaqueTab / WuxiaInkButton / GlossaryTip)
    // 一处失守会顺着所有调用点扩散,故不给豁免通道。
    final allowlisted = readAllowlist()
        .where((entry) => entry.startsWith('lib/shared/'))
        .toList();
    expect(
      allowlisted,
      isEmpty,
      reason:
          'shared/ 复用基元不得进 allowlist(一处失守会扩散到全部调用点),'
          '请直接补桌面语义:\n${allowlisted.map((s) => '  $s').join('\n')}',
    );
  });
}
