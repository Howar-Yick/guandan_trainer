import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';

class TableTrickView extends ConsumerWidget {
  const TableTrickView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameStateProvider);
    final last = s.trick.lastPlay;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('本轮领出：座位${s.trick.leader.index}  |  已过：${s.passed.map((e) => e.index).join(",")}'),
            const SizedBox(height: 8),
            if (last == null)
              const Text('桌面：暂无出牌')
            else
              Text('桌面：座位${last.seat.index} -> ${last.resolved.type} (${last.resolved.length}张)'),
          ],
        ),
      ),
    );
  }
}
