import '../../domain/cards/card.dart';
import '../../domain/enums/rank.dart';
import '../../domain/enums/suit.dart';

String suitSymbol(Suit suit) {
  switch (suit) {
    case Suit.spade:
      return '♠';
    case Suit.heart:
      return '♥';
    case Suit.club:
      return '♣';
    case Suit.diamond:
      return '♦';
    case Suit.joker:
      return '🃏';
  }
}

String rankLabel(Rank rank) {
  switch (rank) {
    case Rank.two:
      return '2';
    case Rank.three:
      return '3';
    case Rank.four:
      return '4';
    case Rank.five:
      return '5';
    case Rank.six:
      return '6';
    case Rank.seven:
      return '7';
    case Rank.eight:
      return '8';
    case Rank.nine:
      return '9';
    case Rank.ten:
      return '10';
    case Rank.jack:
      return 'J';
    case Rank.queen:
      return 'Q';
    case Rank.king:
      return 'K';
    case Rank.ace:
      return 'A';
    case Rank.smallJoker:
      return '小王';
    case Rank.bigJoker:
      return '大王';
  }
}

String displayText(PlayingCard card, {Rank? levelRank}) {
  if (card.isJoker) {
    return '${suitSymbol(card.suit)}${rankLabel(card.rank)}';
  }

  final label = '${suitSymbol(card.suit)}${rankLabel(card.rank)}';
  final isLevelHeart =
      levelRank != null && card.suit == Suit.heart && card.rank == levelRank;

  return isLevelHeart ? '$label*' : label;
}
