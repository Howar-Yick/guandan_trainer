import '../config/rule_config.dart';
import '../enums/play_type.dart';
import '../enums/rank.dart';
import '../model/play.dart';
import 'rank_order.dart';

class PlayCompare {
  final RuleConfig cfg;
  PlayCompare(this.cfg);

  // 返回：a 是否能压 b
  bool beats(ResolvedPlay a, ResolvedPlay b, Rank levelRank) {
    final pa = _power(a);
    final pb = _power(b);

    if (pa != pb) return pa > pb;

    // 同层比较
    if (a.type == PlayType.bomb && b.type == PlayType.bomb) {
      if (a.bombLen != b.bombLen) return a.bombLen > b.bombLen;
      return RankOrder.strength(a.mainRank, levelRank) > RankOrder.strength(b.mainRank, levelRank);
    }

    if (a.type != b.type) {
      // 同层但不同type：只有“普通层”会发生，按规则必须同牌型才能压
      return false;
    }

    // 同牌型比较：默认用 mainRank
    return RankOrder.strength(a.mainRank, levelRank) > RankOrder.strength(b.mainRank, levelRank);
  }

  int _power(ResolvedPlay p) {
    // 天王炸 > 8 > 7 > 6 > 同花顺 > 5 > 4 > 普通
    if (p.type == PlayType.tianWangZha) return 1000;
    if (p.type == PlayType.bomb) {
      switch (p.bombLen) {
        case 8:
          return 900;
        case 7:
          return 850;
        case 6:
          return 800;
        case 5:
          return 650;
        case 4:
          return 600;
        default:
          return 500; // 理论不会出现>8或<4
      }
    }
    if (p.type == PlayType.straightFlush5) return 700;
    // 其它普通牌型统一放到 100
    return 100;
  }
}
