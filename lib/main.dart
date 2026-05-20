import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/presentation/splash_screen.dart';
import 'shared/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // M4 PoC #46 美术 Stage 2 收官:启动初始化迁入 SplashScreen,
  // 期间显示 landscape_loading.png + 并行跑 GameRepository + IsarSetup。
  runApp(const ProviderScope(child: WuxiaApp()));
}

class WuxiaApp extends StatelessWidget {
  const WuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UiStrings.appTitle,
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
