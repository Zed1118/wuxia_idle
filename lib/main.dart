import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/game_repository.dart';
import 'data/isar_setup.dart';

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
  await IsarSetup.init();
  runApp(const ProviderScope(child: WuxiaApp()));
}

class WuxiaApp extends StatelessWidget {
  const WuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '挂机武侠',
      home: Scaffold(
        body: Center(
          child: Text(
            '启动成功',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
