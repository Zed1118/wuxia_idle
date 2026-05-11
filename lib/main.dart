import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/game_repository.dart';
import 'data/isar_setup.dart';
import 'ui/main_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await GameRepository.loadAllDefs();
  if (kDebugMode) {
    debugPrint(
      '[GameRepository] 已加载 ${repo.realms.length} 行境界 / '
      '${repo.equipmentDefs.length} 件装备 / '
      '${repo.techniqueDefs.length} 本心法 / '
      '${repo.skillDefs.length} 招招式 / '
      '${repo.stageDefs.length} 个关卡 '
      '(numbers v${repo.numbers.version})',
    );
  }
  // Isar 不支持 web，T14 web 目测时跳过；desktop 仍走持久化初始化。
  if (!kIsWeb) {
    await IsarSetup.init();
  }
  runApp(const ProviderScope(child: WuxiaApp()));
}

class WuxiaApp extends StatelessWidget {
  const WuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '挂机武侠',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const MainMenu(),
    );
  }
}
