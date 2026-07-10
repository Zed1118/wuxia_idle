import 'dart:io';

import 'package:wuxia_idle/data/game_repository.dart';

Future<String> loadTestAsset(String path) => File(path).readAsString();

Future<GameRepository> loadTestGameRepository() async {
  if (GameRepository.isLoaded) return GameRepository.instance;
  return GameRepository.loadAllDefs(loader: loadTestAsset);
}
