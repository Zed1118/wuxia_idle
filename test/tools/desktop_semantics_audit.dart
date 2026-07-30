// 桌面语义门禁扫描器(CLAUDE §8.2「改交互组件须验 semantics / 键盘激活 / focus /
// mouse cursor」的自动化 sink)。
//
// 为什么只扫 GestureDetector:
//   `InkWell` / Material 按钮(FilledButton/TextButton…)由 Flutter 内建提供
//   Semantics(button) + Focus + ActivateIntent + click 光标,四项天然齐全;
//   **`GestureDetector` 四项全不带**——它是 CLAUDE §8.2 点名的
//   「InkWell→GestureDetector 一类改动易丢桌面语义」的那个风险面。
//
// 判据(满足其一即算已覆盖):
//   ① 祖先链上有 [_affordanceProviders] 之一(FocusableActionDetector /
//      DismissLayer / Focus / InkWell) —— 键盘可达由它提供;
//   ② 在 allowlist 里显式登记,并写明分类与理由。
//
// 用 package:analyzer 走真 AST 而非行级正则:桌面语义包装件与 GestureDetector
// 之间常隔着若干层(Semantics → FocusableActionDetector → MouseRegion → …),
// 行窗口启发式会同时产生漏报与误报(2026-07-30 实测行窗口法把 PauseOverlay 这类
// 「内部另有 FilledButton 故键盘本就可达」的站点误报成缺口)。
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// 提供键盘可达性的包装件:祖先链上出现任一即视为已覆盖。
const affordanceProviders = <String>{
  'FocusableActionDetector',
  'DismissLayer',
  'Focus',
  'InkWell',
};

/// 被扫描的裸手势组件。
const scannedWidget = 'GestureDetector';

class GestureDetectorSite {
  const GestureDetectorSite({
    required this.path,
    required this.line,
    required this.covered,
    required this.coveredBy,
  });

  /// 仓库相对路径,如 `lib/features/....dart`。
  final String path;
  final int line;

  /// 祖先链上是否有 [affordanceProviders] 之一。
  final bool covered;

  /// 命中的包装件名(未命中为 null)。
  final String? coveredBy;

  String get key => '$path:$line';

  @override
  String toString() =>
      '$key  ${covered ? "covered by $coveredBy" : "UNCOVERED"}';
}

/// 扫描 [root]/lib 下全部 .dart(跳过 .g.dart),返回每个 GestureDetector 站点。
List<GestureDetectorSite> collectGestureDetectorSites({String root = '.'}) {
  final libDir = Directory('$root/lib');
  if (!libDir.existsSync()) return const [];

  final sites = <GestureDetectorSite>[];
  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final source = file.readAsStringSync();
    final parsed = parseString(
      content: source,
      path: file.path,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      throw StateError('桌面语义扫描无法解析 ${file.path}: ${parsed.errors.first}');
    }
    final visitor = _GestureDetectorVisitor();
    parsed.unit.accept(visitor);
    for (final node in visitor.nodes) {
      final wrapper = _enclosingAffordance(node);
      sites.add(
        GestureDetectorSite(
          path: _normalize(file.path, root),
          line: parsed.lineInfo.getLocation(node.offset).lineNumber,
          covered: wrapper != null,
          coveredBy: wrapper,
        ),
      );
    }
  }
  return sites;
}

/// 取「构造式调用」的类型名。
///
/// 关键坑:`parseString` 出的是**未解析 AST**,`Foo(...)` 不带 `new`/`const` 时
/// 解析成 [MethodInvocation] 而**不是** [InstanceCreationExpression]
/// (后者要等解析期 ast rewriting 才会转)。项目里 widget 树全是省略 `new` 的写法,
/// 只认 InstanceCreationExpression 会**一个都扫不到**(2026-07-30 实测 TOTAL=0)。
String? _constructedTypeName(AstNode node) {
  if (node is InstanceCreationExpression) {
    return node.constructorName.type.name.lexeme;
  }
  if (node is MethodInvocation && node.realTarget == null) {
    return node.methodName.name;
  }
  return null;
}

/// 沿 AST 父链向上找包装件,走到方法体边界为止(不跨出当前 build/helper)。
String? _enclosingAffordance(AstNode node) {
  AstNode? cur = node.parent;
  while (cur != null) {
    if (cur is MethodDeclaration || cur is FunctionDeclaration) return null;
    final name = _constructedTypeName(cur);
    if (name != null && affordanceProviders.contains(name)) return name;
    cur = cur.parent;
  }
  return null;
}

String _normalize(String path, String root) {
  var p = path.replaceAll(r'\', '/');
  final prefix = root == '.' ? '' : '$root/';
  if (prefix.isNotEmpty && p.startsWith(prefix)) p = p.substring(prefix.length);
  final idx = p.indexOf('lib/');
  return idx <= 0 ? p : p.substring(idx);
}

class _GestureDetectorVisitor extends RecursiveAstVisitor<void> {
  final nodes = <AstNode>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_constructedTypeName(node) == scannedWidget) nodes.add(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_constructedTypeName(node) == scannedWidget) nodes.add(node);
    super.visitMethodInvocation(node);
  }
}
