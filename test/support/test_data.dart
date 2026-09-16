import 'dart:io';

import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';

Future<String> loadTestAsset(String path) => File(path).readAsString();

/// 从生产数值表读取完整子段，测试仅覆盖自身需要变化的字段。
Map<String, dynamic> loadTestNumbersSection(List<String> path) {
  var section = parseYamlMap(File('data/numbers.yaml').readAsStringSync());
  for (final key in path) {
    section = Map<String, dynamic>.from(section[key] as Map);
  }
  return section;
}

Future<GameRepository> loadTestGameRepository() async {
  if (GameRepository.isLoaded) return GameRepository.instance;
  return GameRepository.loadAllDefs(loader: loadTestAsset);
}
