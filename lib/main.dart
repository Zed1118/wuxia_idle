import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/game_repository.dart';
import 'data/isar_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameRepository.loadAllDefs();
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
