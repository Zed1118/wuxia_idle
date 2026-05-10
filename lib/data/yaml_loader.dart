import 'package:yaml/yaml.dart';

/// 把 yaml package 解析出的 [YamlMap] / [YamlList] 递归转成纯 Dart
/// `Map<String, dynamic>` / `List<dynamic>`。
///
/// 解析后 [Def.fromYaml] 等下游可以直接 `as String` / `as num` 而不必
/// 再处理 `YamlScalar`，也避免 `key` 类型为 `dynamic` 的麻烦。
dynamic deepConvertYaml(dynamic v) {
  if (v is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      v.entries.map(
        (e) => MapEntry(e.key.toString(), deepConvertYaml(e.value)),
      ),
    );
  }
  if (v is YamlList) {
    return v.map(deepConvertYaml).toList();
  }
  return v;
}

/// 解析 yaml 字符串到 `Map<String, dynamic>`。yaml 顶层必须是 map。
Map<String, dynamic> parseYamlMap(String source) {
  final doc = loadYaml(source);
  final converted = deepConvertYaml(doc);
  if (converted is Map<String, dynamic>) return converted;
  throw FormatException(
    'yaml 顶层必须是 map，实际得到 ${converted.runtimeType}',
  );
}

/// 解析 yaml 字符串到 `List<dynamic>`（顶层是 list 的场景）。
List<dynamic> parseYamlList(String source) {
  final doc = loadYaml(source);
  final converted = deepConvertYaml(doc);
  if (converted is List) return converted;
  throw FormatException(
    'yaml 顶层必须是 list，实际得到 ${converted.runtimeType}',
  );
}
