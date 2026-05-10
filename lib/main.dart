import 'package:flutter/material.dart';

void main() {
  runApp(const WuxiaApp());
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
