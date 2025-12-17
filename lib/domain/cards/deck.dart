import 'dart:math';

import '../enums/rank.dart';
import '../enums/suit.dart';
import 'card.dart';

class Deck {
  final int deckCount;
  final Random _rng;

  Deck({required this.deckCount, int? seed}) : _rng = Random(seed);

  List<PlayingCard> buildShuffled() {
    final cards = <PlayingCard>[];
    var id = 0;

    for (var d = 0; d < deckCount; d++) {
      for (final suit in [Suit.spade, Suit.heart, Suit.club, Suit.diamond]) {
        for (final rank in [
          Rank.two,
          Rank.three,
          Rank.four,
          Rank.five,
          Rank.six,
          Rank.seven,
          Rank.eight,
          Rank.nine,
          Rank.ten,
          Rank.jack,
          Rank.queen,
          Rank.king,
          Rank.ace,
        ]) {
          cards.add(PlayingCard(suit: suit, rank: rank, id: id++));
        }
      }
      // 每副牌 1 大王 + 1 小王
      cards.add(PlayingCard(suit: Suit.joker, rank: Rank.smallJoker, id: id++));
      cards.add(PlayingCard(suit: Suit.joker, rank: Rank.bigJoker, id: id++));
    }

    cards.shuffle(_rng);
    return cards;
  }
}
