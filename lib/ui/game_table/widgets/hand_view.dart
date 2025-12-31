import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/cards/card.dart';
import '../../../domain/engine/actions.dart';
import '../../../domain/enums/rank.dart';
import '../../../domain/enums/seat.dart';
import '../../../domain/enums/suit.dart';
import '../../../domain/rules/rank_order.dart';
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
    final sorted = [...hand]..sort((a, b) => _compareCards(a, b, s.levelRank));
    final grouped = _groupByRank(sorted);
    final entries = _buildEntries(grouped);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _HandLayout.fromConstraints(
          count: entries.length,
          groupCount: grouped.length,
          maxStack: grouped.isEmpty ? 1 : grouped.map((g) => g.cards.length).reduce((a, b) => a > b ? a : b),
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < entries.length; i++)
                _HandCard(
                  card: entries[i].card,
                  left: layout.sidePadding + entries[i].columnIndex * layout.step,
                  top: entries[i].stackIndex * layout.stackStep,
                  layout: layout,
                  selected: s.selectedCardIds.contains(entries[i].card.id),
                  onTap: () => notifier.dispatch(ToggleSelectCardAction(entries[i].card.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}

int _compareCards(PlayingCard a, PlayingCard b, Rank levelRank) {
  final rankCmp = RankOrder.strength(b.rank, levelRank).compareTo(RankOrder.strength(a.rank, levelRank));
  if (rankCmp != 0) return rankCmp;
  final suitCmp = _suitOrder(a.suit).compareTo(_suitOrder(b.suit));
  if (suitCmp != 0) return suitCmp;
  return a.id.compareTo(b.id);
}

int _suitOrder(Suit suit) {
  switch (suit) {
    case Suit.diamond:
      return 0;
    case Suit.club:
      return 1;
    case Suit.heart:
      return 2;
    case Suit.spade:
      return 3;
    case Suit.joker:
      return 4;
  }
}

List<_RankGroup> _groupByRank(List<PlayingCard> cards) {
  final groups = <_RankGroup>[];
  for (final card in cards) {
    if (groups.isEmpty || groups.last.rank != card.rank) {
      groups.add(_RankGroup(rank: card.rank, cards: [card]));
    } else {
      groups.last.cards.add(card);
    }
  }
  return groups;
}

List<_HandEntry> _buildEntries(List<_RankGroup> groups) {
  final entries = <_HandEntry>[];
  for (var columnIndex = 0; columnIndex < groups.length; columnIndex++) {
    final group = groups[columnIndex];
    final ordered = [...group.cards]..sort((a, b) {
      final suitCmp = _suitOrder(a.suit).compareTo(_suitOrder(b.suit));
      if (suitCmp != 0) return suitCmp;
      return a.id.compareTo(b.id);
    });
    for (var stackIndex = 0; stackIndex < ordered.length; stackIndex++) {
      entries.add(_HandEntry(
        card: ordered[stackIndex],
        columnIndex: columnIndex,
        stackIndex: stackIndex,
      ));
    }
  }
  return entries;
}

class _RankGroup {
  final Rank rank;
  final List<PlayingCard> cards;

  _RankGroup({required this.rank, required this.cards});
}

class _HandEntry {
  final PlayingCard card;
  final int columnIndex;
  final int stackIndex;

  _HandEntry({
    required this.card,
    required this.columnIndex,
    required this.stackIndex,
  });
}

class _HandLayout {
  final double cardWidth;
  final double cardHeight;
  final double step;
  final double stackStep;
  final double liftOffset;
  final double height;
  final double sidePadding;

  _HandLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.step,
    required this.stackStep,
    required this.liftOffset,
    required this.height,
    required this.sidePadding,
  });

  static _HandLayout fromConstraints({
    required int count,
    required int groupCount,
    required int maxStack,
    required double maxWidth,
    required double maxHeight,
  }) {
    const aspectRatio = 80 / 54;
    const minCardWidth = 28.0;
    const maxCardHeight = 140.0;
    const minCardHeight = 68.0;
    const stackRatio = 0.26;
    const liftRatio = 0.12;

    if (count == 0) {
      final cardHeight = maxHeight.clamp(minCardHeight, maxCardHeight);
      final cardWidth = (cardHeight / aspectRatio).clamp(minCardWidth, double.infinity);
      return _HandLayout(
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        step: cardWidth,
        stackStep: cardHeight * stackRatio,
        liftOffset: cardHeight * liftRatio,
        height: cardHeight * (1 + liftRatio),
        sidePadding: 0,
      );
    }

    final verticalFactor = 1 + stackRatio * (maxStack - 1) + liftRatio;
    var cardHeight = (maxHeight / verticalFactor).clamp(minCardHeight, maxCardHeight);
    var cardWidth = (cardHeight / aspectRatio).clamp(minCardWidth, double.infinity);

    var step = groupCount > 1 ? (maxWidth - cardWidth) / (groupCount - 1) : cardWidth;
    var minStep = cardWidth * 0.22;
    final maxStep = cardWidth * 0.55;

    if (groupCount > 1 && step < minStep) {
      step = minStep;
      cardWidth = (maxWidth - step * (groupCount - 1)).clamp(minCardWidth, cardWidth);
      cardHeight = cardWidth * aspectRatio;
      minStep = cardWidth * 0.22;
    }
    step = step.clamp(minStep, maxStep);
    final totalWidth = cardWidth + step * (groupCount - 1);
    final sidePadding = ((maxWidth - totalWidth) / 2).clamp(0.0, maxWidth);

    final stackStep = cardHeight * stackRatio;
    return _HandLayout(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      step: step,
      stackStep: stackStep,
      liftOffset: cardHeight * liftRatio,
      height: cardHeight + stackStep * (maxStack - 1) + cardHeight * liftRatio,
      sidePadding: sidePadding,
    );
  }
}

class _HandCard extends StatelessWidget {
  final PlayingCard card;
  final double left;
  final double top;
  final _HandLayout layout;
  final bool selected;
  final VoidCallback onTap;

  const _HandCard({
    required this.card,
    required this.left,
    required this.top,
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      left: left,
      top: selected ? top - layout.liftOffset : top,
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
