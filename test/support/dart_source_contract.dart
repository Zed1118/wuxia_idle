import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final class DartSourceContract {
  DartSourceContract._(this._probe);

  factory DartSourceContract.parse(String source, {String? path}) {
    final result = parseString(
      content: source,
      path: path,
      throwIfDiagnostics: false,
    );
    if (result.errors.isNotEmpty) {
      throw StateError(
        'Dart source contract could not parse ${path ?? '<snippet>'}: '
        '${result.errors.join(', ')}',
      );
    }
    final probe = _SourceProbe();
    result.unit.accept(probe);
    return DartSourceContract._(probe);
  }

  final _SourceProbe _probe;

  int memberAccessCount(String memberName, {String? receiverSource}) => _probe
      .memberAccesses
      .where(
        (access) =>
            access.memberName == memberName &&
            (receiverSource == null || access.receiverSource == receiverSource),
      )
      .length;

  int identifierCount(String name) =>
      _probe.identifiers.where((identifier) => identifier.name == name).length;

  List<SourceMethodCall> methodCalls({
    required String targetSource,
    required String methodName,
  }) => _probe.methodCalls
      .where(
        (call) =>
            call.targetSource == targetSource && call.methodName == methodName,
      )
      .toList(growable: false);

  String? variableInitializerSource(String variableName) =>
      _probe.variableInitializers[variableName]?.toSource();
}

final class SourceMethodCall {
  const SourceMethodCall({
    required this.targetSource,
    required this.methodName,
    required this.positionalArguments,
    required this.namedArguments,
  });

  final String targetSource;
  final String methodName;
  final List<String> positionalArguments;
  final Map<String, String> namedArguments;
}

final class _MemberAccess {
  const _MemberAccess({required this.receiverSource, required this.memberName});

  final String receiverSource;
  final String memberName;
}

final class _SourceProbe extends RecursiveAstVisitor<void> {
  final memberAccesses = <_MemberAccess>[];
  final identifiers = <SimpleIdentifier>[];
  final methodCalls = <SourceMethodCall>[];
  final variableInitializers = <String, Expression>{};

  @override
  void visitComment(Comment node) {}

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    memberAccesses.add(
      _MemberAccess(
        receiverSource: node.prefix.toSource(),
        memberName: node.identifier.name,
      ),
    );
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    memberAccesses.add(
      _MemberAccess(
        receiverSource: node.realTarget.toSource(),
        memberName: node.propertyName.name,
      ),
    );
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final positionalArguments = <String>[];
    final namedArguments = <String, String>{};
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedExpression) {
        namedArguments[argument.name.label.name] = argument.expression
            .toSource();
      } else {
        positionalArguments.add(argument.toSource());
      }
    }
    methodCalls.add(
      SourceMethodCall(
        targetSource: node.realTarget?.toSource() ?? '',
        methodName: node.methodName.name,
        positionalArguments: List.unmodifiable(positionalArguments),
        namedArguments: Map.unmodifiable(namedArguments),
      ),
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer != null) {
      variableInitializers[node.name.lexeme] = initializer;
    }
    super.visitVariableDeclaration(node);
  }
}
