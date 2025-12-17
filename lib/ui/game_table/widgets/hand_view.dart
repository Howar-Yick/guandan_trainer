import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/engine/actions.dart';
import '../../../domain/enums/seat.dart';
import '../../../domain/enums/suit.dart';
import '../../common/card_display.dart';

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
                width: 58,
                height: 86,
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.only(top: selected ? 0 : 14),
                child: Center(
                  child: Text(
                    displayText(c, levelRank: s.levelRank),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: c.suit == Suit.heart || c.suit == Suit.diamond
                          ? Colors.red
                          : Colors.black,
                    ),
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
