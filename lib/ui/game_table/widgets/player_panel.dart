import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/enums/seat.dart';

class PlayerPanel extends ConsumerWidget {
  final Seat seat;
  const PlayerPanel({super.key, required this.seat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameStateProvider);
    final p = s.player(seat);
    final isTurn = s.currentTurn == seat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text('座位${seat.index}${seat == Seat.s0 ? "(你)" : ""}'),
            const SizedBox(height: 6),
            Text('剩余：${p.hand.length}'),
            const SizedBox(height: 6),
            Text(isTurn ? '→ 轮到他' : ''),
          ],
        ),
      ),
    );
  }
}
