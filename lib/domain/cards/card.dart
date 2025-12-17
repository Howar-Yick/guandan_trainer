import '../enums/rank.dart';
import '../enums/suit.dart';

class PlayingCard {
  final Suit suit;
  final Rank rank;

  // 两副牌需要区分同一张：用 id 唯一化
  final int id;

  const PlayingCard({
    required this.suit,
    required this.rank,
    required this.id,
  });

  bool get isJoker => suit == Suit.joker;

  @override
  String toString() => 'Card($rank,$suit,#$id)';
}
