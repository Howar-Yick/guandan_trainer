import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/game_table/game_table_page.dart';

void main() {
  runApp(const ProviderScope(child: GuandanTrainerApp()));
}

class GuandanTrainerApp extends StatelessWidget {
  const GuandanTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'guandan_trainer',
      theme: ThemeData(useMaterial3: true),
      home: const GameTablePage(),
    );
  }
}
