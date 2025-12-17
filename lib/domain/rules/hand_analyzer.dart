import 'package:collection/collection.dart';

import '../cards/card.dart';
import '../config/rule_config.dart';
import '../enums/play_type.dart';
import '../enums/rank.dart';
import '../enums/suit.dart';
import '../model/play.dart';
import 'rank_order.dart';
import 'wildcard_resolver.dart';

class HandAnalyzer {
  final RuleConfig cfg;

  HandAnalyzer(this.cfg);

  ResolvedPlay analyze(List<PlayingCard> cards, Rank levelRank) {
    if (cards.isEmpty) {
      throw ArgumentError('cards empty');
    }

    // 先处理癞子：红桃级牌（可当任意非王）
    if (cfg.enableWildcard) {
      final resolved = WildcardResolver(cfg).resolve(cards, levelRank);
      if (resolved != null) return resolved;
    }

    // 无癞子路径
    final base = _analyzeNoWildcard(cards, levelRank);
    if (base == null) {
      throw StateError('无法识别牌型：${cards.map((e) => e.toString()).join(",")}');
    }
    return base;
  }

  // -------------------- rank seq helpers --------------------
  static const List<Rank> _seqRanks = [
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
  ];

  int _seqIndex(Rank r) => _seqRanks.indexOf(r);

  bool _isConsecutive5(List<Rank> ranks) {
    if (ranks.length != 5) return false;
    final idx = ranks.map(_seqIndex).toList();
    if (idx.any((i) => i < 0)) return false;
    idx.sort();
    // 必须是 5 个不同点
    if (idx.toSet().length != 5) return false;
    for (var i = 1; i < 5; i++) {
      if (idx[i] != idx[i - 1] + 1) return false;
    }
    return true;
  }

  ResolvedPlay? _analyzeNoWildcard(List<PlayingCard> cards, Rank levelRank) {
    final sorted = [...cards]
      ..sort((a, b) => RankOrder.strength(b.rank, levelRank).compareTo(RankOrder.strength(a.rank, levelRank)));

    // 天王炸：必须 2大王+2小王
    if (sorted.length == 4 && _isTianWangZha(sorted)) {
      return ResolvedPlay(
        type: PlayType.tianWangZha,
        finalCards: sorted,
        mainRank: Rank.bigJoker,
        length: 4,
        bombLen: 0,
      );
    }

    final byRank = groupBy(sorted, (c) => c.rank);

    // 炸弹：4~8同点（王不参与，天王炸已提前处理）
    if (sorted.length >= 4 && sorted.length <= 8 && byRank.length == 1 && sorted.every((c) => c.suit != Suit.joker)) {
      final r = byRank.keys.first;
      return ResolvedPlay(
        type: PlayType.bomb,
        finalCards: sorted,
        mainRank: r,
        length: sorted.length,
        bombLen: sorted.length,
      );
    }

    // 单/对/三
    if (sorted.length == 1) {
      return ResolvedPlay(
        type: PlayType.single,
        finalCards: sorted,
        mainRank: sorted.first.rank,
        length: 1,
        bombLen: 0,
      );
    }
    if (sorted.length == 2 && byRank.length == 1) {
      return ResolvedPlay(
        type: PlayType.pair,
        finalCards: sorted,
        mainRank: sorted.first.rank,
        length: 2,
        bombLen: 0,
      );
    }
    if (sorted.length == 3 && byRank.length == 1) {
      return ResolvedPlay(
        type: PlayType.triple,
        finalCards: sorted,
        mainRank: sorted.first.rank,
        length: 3,
        bombLen: 0,
      );
    }

    // 三带二（5张：3+2）
    if (sorted.length == 5 && byRank.length == 2) {
      final groups = byRank.entries.map((e) => e.value.length).sorted((a, b) => a.compareTo(b));
      if (groups[0] == 2 && groups[1] == 3) {
        final tripleRank = byRank.entries.firstWhere((e) => e.value.length == 3).key;
        return ResolvedPlay(
          type: PlayType.tripleWithPair,
          finalCards: sorted,
          mainRank: tripleRank,
          length: 5,
          bombLen: 0,
        );
      }
    }

    // 顺子(5张)：不能含王，5个不同点，且连续
    if (sorted.length == 5 && sorted.every((c) => c.suit != Suit.joker)) {
      final ranks = sorted.map((c) => c.rank).toList();
      if (_isConsecutive5(ranks)) {
        final maxRank = ranks.sorted((a, b) => _seqIndex(a).compareTo(_seqIndex(b))).last;
        return ResolvedPlay(
          type: PlayType.straight5,
          finalCards: sorted,
          mainRank: maxRank,
          length: 5,
          bombLen: 0,
        );
      }
    }

    // 同花顺(5张)：同花色 + 连续（不能含王）
    if (sorted.length == 5 && sorted.every((c) => c.suit != Suit.joker)) {
      final suit = sorted.first.suit;
      if (sorted.every((c) => c.suit == suit)) {
        final ranks = sorted.map((c) => c.rank).toList();
        if (_isConsecutive5(ranks)) {
          final maxRank = ranks.sorted((a, b) => _seqIndex(a).compareTo(_seqIndex(b))).last;
          return ResolvedPlay(
            type: PlayType.straightFlush5,
            finalCards: sorted,
            mainRank: maxRank,
            length: 5,
            bombLen: 0,
          );
        }
      }
    }

    // 三连对(6张)：3组连续对子
    if (sorted.length == 6 && sorted.every((c) => c.suit != Suit.joker) && byRank.length == 3) {
      final ok = byRank.values.every((v) => v.length == 2);
      if (ok) {
        final rs = byRank.keys.toList();
        rs.sort((a, b) => _seqIndex(a).compareTo(_seqIndex(b)));
        final idx = rs.map(_seqIndex).toList();
        if (idx.every((i) => i >= 0) && idx[1] == idx[0] + 1 && idx[2] == idx[1] + 1) {
          return ResolvedPlay(
            type: PlayType.threeConsecutivePairs,
            finalCards: sorted,
            mainRank: rs.last, // 最高对子点
            length: 6,
            bombLen: 0,
          );
        }
      }
    }

    // 钢板(6张)：两连三（x x x + x+1 x+1 x+1）
    if (sorted.length == 6 && sorted.every((c) => c.suit != Suit.joker) && byRank.length == 2) {
      final ok = byRank.values.every((v) => v.length == 3);
      if (ok) {
        final rs = byRank.keys.toList();
        rs.sort((a, b) => _seqIndex(a).compareTo(_seqIndex(b)));
        final i0 = _seqIndex(rs[0]);
        final i1 = _seqIndex(rs[1]);
        if (i0 >= 0 && i1 == i0 + 1) {
          return ResolvedPlay(
            type: PlayType.steelPlate,
            finalCards: sorted,
            mainRank: rs[1], // 高三张点
            length: 6,
            bombLen: 0,
          );
        }
      }
    }

    return null;
  }

  bool _isTianWangZha(List<PlayingCard> cards) {
    if (cards.length != 4) return false;
    final jokers = cards.where((c) => c.suit == Suit.joker).toList();
    if (jokers.length != 4) return false;
    final big = jokers.where((c) => c.rank == Rank.bigJoker).length;
    final small = jokers.where((c) => c.rank == Rank.smallJoker).length;
    return big == 2 && small == 2;
  }
}
