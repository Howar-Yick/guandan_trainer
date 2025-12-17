import '../cards/card.dart';
import '../enums/play_type.dart';
import '../enums/rank.dart';
import '../enums/seat.dart';

class ResolvedPlay {
  final PlayType type;
  final List<PlayingCard> finalCards; // 癞子替换后的“解释用”牌面（可先等于原牌）
  final Rank mainRank; // 比较键（比如炸弹点、顺子最大点等）
  final int length; // 牌张数
  final int bombLen; // 炸弹张数，非炸弹为0

  const ResolvedPlay({
    required this.type,
    required this.finalCards,
    required this.mainRank,
    required this.length,
    required this.bombLen,
  });
}

class Play {
  final Seat seat;
  final List<PlayingCard> rawCards;
  final ResolvedPlay resolved;

  const Play({
    required this.seat,
    required this.rawCards,
    required this.resolved,
  });
}
