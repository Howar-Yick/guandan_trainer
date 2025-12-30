import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/engine/actions.dart';
import '../../../domain/enums/seat.dart';
import 'card_face.dart';

class HandView extends ConsumerWidget {
  final Seat seat;
  const HandView({super.key, required this.seat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final p = s.player(seat);
    final hand = p.hand;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _HandLayout.fromConstraints(
          count: hand.length,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );

        return Center(
          child: Wrap(
            spacing: layout.spacing,
            runSpacing: layout.runSpacing,
            children: hand.map((c) {
              final selected = s.selectedCardIds.contains(c.id);
              return GestureDetector(
                onTap: () => notifier.dispatch(ToggleSelectCardAction(c.id)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: layout.cardWidth,
                  height: layout.cardHeight,
                  transform: Matrix4.translationValues(0, selected ? -layout.liftOffset : 0, 0),
                  transformAlignment: Alignment.center,
                  child: CardFace(card: c),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _HandLayout {
  final double cardWidth;
  final double cardHeight;
  final double spacing;
  final double runSpacing;
  final double liftOffset;

  _HandLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.spacing,
    required this.runSpacing,
    required this.liftOffset,
  });

  static _HandLayout fromConstraints({
    required int count,
    required double maxWidth,
    required double maxHeight,
  }) {
    const aspectRatio = 80 / 54;
    const minCardWidth = 32.0;
    const maxCardWidth = 56.0;
    const spacing = 6.0;
    const runSpacing = 8.0;

    if (count == 0) {
      return _HandLayout(
        cardWidth: maxCardWidth,
        cardHeight: maxCardWidth * aspectRatio,
        spacing: spacing,
        runSpacing: runSpacing,
        liftOffset: maxCardWidth * aspectRatio * 0.12,
      );
    }

    var columns = (maxWidth / (maxCardWidth + spacing)).floor().clamp(1, count);
    var cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
    cardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);

    var rows = (count / columns).ceil();
    var cardHeight = cardWidth * aspectRatio;

    final totalHeight = rows * cardHeight + (rows - 1) * runSpacing;
    if (totalHeight > maxHeight) {
      cardHeight = (maxHeight - (rows - 1) * runSpacing) / rows;
      cardWidth = cardHeight / aspectRatio;
    }

    return _HandLayout(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      spacing: spacing,
      runSpacing: runSpacing,
      liftOffset: cardHeight * 0.12,
    );
  }
}
