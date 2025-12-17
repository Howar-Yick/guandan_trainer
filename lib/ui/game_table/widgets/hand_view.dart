import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/engine/actions.dart';
import '../../../domain/enums/seat.dart';

class HandView extends ConsumerWidget {
  final Seat seat;
  const HandView({super.key, required this.seat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final p = s.player(seat);
    final hand = p.hand;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hand.map((c) {
          final selected = s.selectedCardIds.contains(c.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => notifier.dispatch(ToggleSelectCardAction(c.id)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 54,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.only(top: selected ? 0 : 14),
                child: Center(
                  child: Text(
                    '${c.suit.name[0].toUpperCase()}-${c.rank.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
