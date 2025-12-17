import '../enums/rank.dart';

class RankOrder {
  // 大王 > 小王 > 级牌 > A > K > ... > 2
  static int strength(Rank r, Rank level) {
    if (r == Rank.bigJoker) return 100;
    if (r == Rank.smallJoker) return 90;
    if (r == level) return 80;

    switch (r) {
      case Rank.ace:
        return 70;
      case Rank.king:
        return 69;
      case Rank.queen:
        return 68;
      case Rank.jack:
        return 67;
      case Rank.ten:
        return 66;
      case Rank.nine:
        return 65;
      case Rank.eight:
        return 64;
      case Rank.seven:
        return 63;
      case Rank.six:
        return 62;
      case Rank.five:
        return 61;
      case Rank.four:
        return 60;
      case Rank.three:
        return 59;
      case Rank.two:
        return 58;
      case Rank.smallJoker:
      case Rank.bigJoker:
        // 已处理
        return 0;
    }
  }
}
