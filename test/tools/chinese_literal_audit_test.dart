// 中文散写门禁 guard(口径 A·2026-07-25 用户拍板)。扫描器见 chinese_literal_audit.dart。
//
// 两条 guard 沿 asset_audit_test 体例:
//   guard 1 = 无 allowlist 外的中文散写(**挡新增**);
//   guard 2 = allowlist 无已清理残留(清一条销一条,不留虚账)。
//
// 存量 31 条进 allowlist 而非一次清完:门禁的价值在于「今天就能挡住新增」,存量清理
// 是独立的小批(BACKLOG 登记)。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'chinese_literal_audit.dart';

const _allowlistPath = 'test/fixtures/chinese_literal_allowlist.txt';

/// allowlist 行格式:`<相对路径> :: <字面量片段>`。**不含行号**——行号随无关编辑漂移,
/// 用「路径+片段」作 key 才稳。
Set<String> _loadAllowlist() {
  final file = File(_allowlistPath);
  if (!file.existsSync()) return const {};
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

String _key(ChineseLiteralIssue issue) => '${issue.path} :: ${issue.snippet}';

void main() {
  test('guard 1: 无 allowlist 外的中文散写(防新增玩家可见文案硬编码)', () {
    final issues = collectChineseLiteralIssues();
    final allow = _loadAllowlist();
    final offenders = issues.where((i) => !allow.contains(_key(i))).toList()
      ..sort((a, b) => _key(a).compareTo(_key(b)));
    expect(
      offenders.map((i) => '${i.path}:${i.line}  ${i.snippet}').toList(),
      isEmpty,
      reason:
          '以下中文字面量在玩家可见路径上散写(CLAUDE §5.6):\n'
          'UI 文案请进 lib/shared/strings.dart(UiStrings);叙事文案进 data/narratives|lore|events。\n'
          '若确属诊断串/开发者日志,请让它处在 throw/assert/Error·Exception/@Deprecated/debugPrint 里,\n'
          '扫描器会自动豁免(见 chinese_literal_audit.dart 口径 A)。',
    );
  });

  test('guard 2: allowlist 无已清理残留(清一条销一条)', () {
    final issues = collectChineseLiteralIssues();
    final live = issues.map(_key).toSet();
    final stale = _loadAllowlist().difference(live).toList()..sort();
    expect(
      stale,
      isEmpty,
      reason:
          '以下 allowlist 条目已不存在(已清理或已改写),请从 $_allowlistPath 删除:\n'
          '${stale.join('\n')}',
    );
  });
}
