// 中文散写门禁扫描器(CLAUDE §5.6「Dart 代码里不写中文文案」的自动化 sink)。
//
// 口径 A(2026-07-25 用户拍板)——门禁只管**玩家可见的 UI 文案散写**,以下四类豁免:
//   ① 注释(走 AST 天然豁免:注释不进语法树)
//   ② 诊断异常串(throw / assert / Error·Exception 构造参数——异常信息应贴近抛出点)
//   ③ debug 域(lib/features/debug/ 下的调试脚手架,玩家不可见)
//   ④ 集中式文案 sink(CLAUDE §5.6 正名:单一文件集中维护 ≠ 散写)
//
// 用 package:analyzer 走真 AST 而非行级正则:诊断串大量是**多行拼接**,行级扫描会把
// 续行误判成散写(2026-07-25 实测 312 行误报)。
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// 集中式文案 sink(口径 A ④):单一文件集中维护的中文,不算散写。
const centralStringSinks = <String>{
  'lib/shared/strings.dart',
  'lib/features/battle/domain/enum_localizations.dart',
  'lib/features/battle/domain/battle_log.dart',
};

/// 豁免目录(口径 A ③)。
const exemptDirPrefixes = <String>{'lib/features/debug/'};

/// 诊断异常类型名后缀:构造参数里的中文按「诊断串」豁免(口径 A ②)。
const _diagnosticTypeSuffixes = <String>['Error', 'Exception'];

/// 开发者日志调用:参数里的中文玩家不可见(口径 A ②同族)。
const _logCallNames = <String>{'debugPrint', 'print', 'log'};

final _chinese = RegExp(r'[一-龥]');

class ChineseLiteralIssue {
  const ChineseLiteralIssue({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;

  @override
  String toString() => '$path:$line  $snippet';
}

/// 扫描 [root] 下 lib/ 的全部 .dart(跳过 .g.dart),返回口径 A 下**未豁免**的中文字面量。
List<ChineseLiteralIssue> collectChineseLiteralIssues({String root = '.'}) {
  final libDir = Directory('$root/lib');
  if (!libDir.existsSync()) return const [];

  final issues = <ChineseLiteralIssue>[];
  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relative = _normalize(file.path, root);
    if (centralStringSinks.contains(relative)) continue;
    if (exemptDirPrefixes.any(relative.startsWith)) continue;

    final source = file.readAsStringSync();
    if (!_chinese.hasMatch(source)) continue;

    final parsed = parseString(content: source, throwIfDiagnostics: false);
    final visitor = _ChineseLiteralVisitor();
    parsed.unit.accept(visitor);

    for (final node in visitor.hits) {
      final location = parsed.lineInfo.getLocation(node.offset);
      issues.add(
        ChineseLiteralIssue(
          path: relative,
          line: location.lineNumber,
          snippet: _snippet(node.toSource()),
        ),
      );
    }
  }
  return issues;
}

String _normalize(String path, String root) {
  var p = path.replaceAll('\\', '/');
  final prefix = root == '.' ? './' : '$root/';
  if (p.startsWith(prefix)) p = p.substring(prefix.length);
  if (p.startsWith('./')) p = p.substring(2);
  return p;
}

String _snippet(String source) {
  final flat = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 80 ? flat : '${flat.substring(0, 77)}...';
}

class _ChineseLiteralVisitor extends RecursiveAstVisitor<void> {
  final List<AstNode> hits = [];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _check(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final literalText = node.elements
        .whereType<InterpolationString>()
        .map((e) => e.value)
        .join();
    _check(node, literalText);
    super.visitStringInterpolation(node);
  }

  void _check(AstNode node, String text) {
    if (!_chinese.hasMatch(text)) return;
    if (_isDiagnostic(node)) return;
    hits.add(node);
  }

  /// 口径 A ②:处在 throw / assert / Error·Exception 构造 / 弃用注解 / 开发者日志
  /// 调用里的字面量 = 诊断串,不是玩家可见文案。
  bool _isDiagnostic(AstNode node) {
    for (AstNode? cur = node; cur != null; cur = cur.parent) {
      if (cur is ThrowExpression) return true;
      if (cur is AssertStatement || cur is AssertInitializer) return true;
      // `@Deprecated('请使用 qiDelta')` 等注解:面向开发者的迁移提示。
      if (cur is Annotation) return true;
      // debugPrint / print / developer.log:开发者日志,玩家不可见。
      if (cur is MethodInvocation &&
          _logCallNames.contains(cur.methodName.name)) {
        return true;
      }
      if (cur is InstanceCreationExpression &&
          _isDiagnosticTypeName(cur.constructorName.type.name.lexeme)) {
        return true;
      }
      // 无 new/const 关键字的 `StateError('…')` 会解析成 MethodInvocation。
      if (cur is MethodInvocation &&
          _isDiagnosticTypeName(cur.methodName.name)) {
        return true;
      }
    }
    return false;
  }

  bool _isDiagnosticTypeName(String name) =>
      _diagnosticTypeSuffixes.any(name.endsWith);
}
