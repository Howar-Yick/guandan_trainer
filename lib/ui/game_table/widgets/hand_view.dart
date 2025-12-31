import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/cards/card.dart';
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

        return SizedBox(
          width: constraints.maxWidth,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < hand.length; i++)
                _HandCard(
                  card: hand[i],
                  index: i,
                  layout: layout,
                  selected: s.selectedCardIds.contains(hand[i].id),
                  onTap: () => notifier.dispatch(ToggleSelectCardAction(hand[i].id)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HandLayout {
  final double cardWidth;
  final double cardHeight;
  final double step;
  final double liftOffset;
  final double height;
  final double sidePadding;

  _HandLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.step,
    required this.liftOffset,
    required this.height,
    required this.sidePadding,
  });

  static _HandLayout fromConstraints({
    required int count,
    required double maxWidth,
    required double maxHeight,
  }) {
    const aspectRatio = 80 / 54;
    const minCardWidth = 28.0;
    const maxCardHeight = 140.0;
    const minCardHeight = 68.0;

    if (count == 0) {
      final cardHeight = maxHeight.clamp(minCardHeight, maxCardHeight);
      final cardWidth = (cardHeight / aspectRatio).clamp(minCardWidth, double.infinity);
      return _HandLayout(
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        step: cardWidth,
        liftOffset: cardHeight * 0.12,
        height: cardHeight * 1.08,
        sidePadding: 0,
      );
    }

    var cardHeight = maxHeight.clamp(minCardHeight, maxCardHeight);
    var cardWidth = (cardHeight / aspectRatio).clamp(minCardWidth, double.infinity);

    var step = count > 1 ? (maxWidth - cardWidth) / (count - 1) : cardWidth;
    var minStep = cardWidth * 0.22;
    final maxStep = cardWidth * 0.55;

    if (count > 1 && step < minStep) {
      step = minStep;
      cardWidth = (maxWidth - step * (count - 1)).clamp(minCardWidth, cardWidth);
      cardHeight = cardWidth * aspectRatio;
      minStep = cardWidth * 0.22;
    }
    step = step.clamp(minStep, maxStep);
    final totalWidth = cardWidth + step * (count - 1);
    final sidePadding = ((maxWidth - totalWidth) / 2).clamp(0.0, maxWidth);

    return _HandLayout(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      step: step,
      liftOffset: cardHeight * 0.12,
      height: cardHeight + cardHeight * 0.15,
      sidePadding: sidePadding,
    );
  }
}

class _HandCard extends StatelessWidget {
  final PlayingCard card;
  final int index;
  final _HandLayout layout;
  final bool selected;
  final VoidCallback onTap;

  const _HandCard({
    required this.card,
    required this.index,
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      left: layout.sidePadding + index * layout.step,
      top: selected ? 0 : layout.liftOffset,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: layout.cardWidth,
          height: layout.cardHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(layout.cardWidth * 0.12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: layout.cardWidth * 0.12,
                  offset: Offset(0, layout.cardWidth * 0.06),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(layout.cardWidth * 0.12),
              child: CardFace(card: card),
            ),
          ),
        ),
      ),
    );
  }
}
