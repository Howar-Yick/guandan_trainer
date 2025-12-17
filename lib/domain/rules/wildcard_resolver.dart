import 'package:collection/collection.dart';

import '../cards/card.dart';
import '../config/rule_config.dart';
import '../enums/play_type.dart';
import '../enums/rank.dart';
import '../enums/suit.dart';
import '../model/play.dart';
import 'rank_order.dart';

class WildcardResolver {
  final RuleConfig cfg;
  WildcardResolver(this.cfg);

  ResolvedPlay? resolve(List<PlayingCard> raw, Rank levelRank) {
    final wilds = raw.where((c) => c.suit == cfg.wildcardSuit && c.rank == levelRank).toList();
    if (wilds.isEmpty) return null;

    final base = raw.where((c) => !(c.suit == cfg.wildcardSuit && c.rank == levelRank)).toList();
    final wc = wilds.length;

    // 天王炸不能由癞子补
    final tian = _tryTianWangZha(raw);
    if (tian != null) return tian;

    final totalLen = raw.length;
    final candidates = <ResolvedPlay>[];

    // 炸弹（4~8）
    final bomb = _tryBomb(base, wc, levelRank, totalLen);
    if (bomb != null) candidates.add(bomb);

    // 按长度限定枚举其它可能牌型
    if (totalLen == 1) {
      candidates.add(_resolveSingle(base, wc, levelRank));
    } else if (totalLen == 2) {
      final p = _tryPair(base, wc, levelRank);
      if (p != null) candidates.add(p);
    } else if (totalLen == 3) {
      final t = _tryTriple(base, wc, levelRank);
      if (t != null) candidates.add(t);
    } else if (totalLen == 5) {
      final twp = _tryTripleWithPair(base, wc, levelRank);
      if (twp != null) candidates.add(twp);

      final st = _tryStraight5(base, wc, levelRank);
      if (st != null) candidates.add(st);

      final sf = _tryStraightFlush5(base, wc, levelRank);
      if (sf != null) candidates.add(sf);
    } else if (totalLen == 6) {
      final tcp = _tryThreeConsecutivePairs(base, wc, levelRank);
      if (tcp != null) candidates.add(tcp);

      final sp = _trySteelPlate(base, wc, levelRank);
      if (sp != null) candidates.add(sp);

      // 注意：你规则里“除炸弹外不超过6”，且6张只有这两类（钢板/三连对）
    }

    if (candidates.isEmpty) return null;

    // 选择最强候选：先比牌型优先级，再比 mainRank（同层）
    candidates.sort((a, b) {
      final pa = _power(a);
      final pb = _power(b);
      if (pa != pb) return pb.compareTo(pa);
      return RankOrder.strength(b.mainRank, levelRank).compareTo(RankOrder.strength(a.mainRank, levelRank));
    });

    return candidates.first;
  }

  // -------------------- power --------------------
  int _power(ResolvedPlay p) {
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
          return 500;
      }
    }
    if (p.type == PlayType.straightFlush5) return 700;
    return 100;
  }

  // -------------------- helpers: ranks & sequence --------------------
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

  List<List<Rank>> _allStraight5() {
    // 2..10 共 9 组
    final res = <List<Rank>>[];
    for (var start = 0; start <= _seqRanks.length - 5; start++) {
      res.add(_seqRanks.sublist(start, start + 5));
    }
    return res;
  }

  bool _isNonJokerRank(Rank r) => r != Rank.bigJoker && r != Rank.smallJoker;

  // -------------------- TianWangZha --------------------
  ResolvedPlay? _tryTianWangZha(List<PlayingCard> raw) {
    if (raw.length != 4) return null;
    final jokers = raw.where((c) => c.suit == Suit.joker).toList();
    if (jokers.length != 4) return null;
    final big = jokers.where((c) => c.rank == Rank.bigJoker).length;
    final small = jokers.where((c) => c.rank == Rank.smallJoker).length;
    if (big == 2 && small == 2) {
      return ResolvedPlay(
        type: PlayType.tianWangZha,
        finalCards: raw,
        mainRank: Rank.bigJoker,
        length: 4,
        bombLen: 0,
      );
    }
    return null;
  }

  // -------------------- Bomb --------------------
  ResolvedPlay? _tryBomb(List<PlayingCard> base, int wc, Rank levelRank, int totalLen) {
    if (totalLen < 4 || totalLen > 8) return null;

    // base 里不能含王（含王只能是天王炸，已处理），且炸弹必须同点
    if (base.any((c) => c.suit == Suit.joker)) return null;

    final byRank = groupBy(base, (c) => c.rank);
    if (byRank.isEmpty) {
      // 全是癞子：你可以当成任意炸弹点（非王），为了最大压制，取“级牌点”
      return ResolvedPlay(
        type: PlayType.bomb,
        finalCards: _fakeCards(totalLen, Suit.spade, levelRank),
        mainRank: levelRank,
        length: totalLen,
        bombLen: totalLen,
      );
    }

    if (byRank.length != 1) return null;
    final r = byRank.keys.first;
    if (!_isNonJokerRank(r)) return null;

    final need = totalLen - base.length;
    if (need < 0 || need > wc) return null;

    final filled = <PlayingCard>[
      ...base,
      ..._fakeCards(need, Suit.spade, r),
    ];

    return ResolvedPlay(
      type: PlayType.bomb,
      finalCards: filled,
      mainRank: r,
      length: totalLen,
      bombLen: totalLen,
    );
  }

  // -------------------- Single/Pair/Triple/3+2 --------------------
  ResolvedPlay _resolveSingle(List<PlayingCard> base, int wc, Rank levelRank) {
    // 单张：能达到的最高非王点就是“级牌点”（因为级牌 > A）
    final best = base.isNotEmpty ? base.first.rank : levelRank;
    final mr = _bestNonJokerRank(best, levelRank);
    final filled = <PlayingCard>[...base];
    if (filled.isEmpty) {
      filled.addAll(_fakeCards(1, Suit.spade, mr));
    }
    return ResolvedPlay(
      type: PlayType.single,
      finalCards: filled,
      mainRank: mr,
      length: 1,
      bombLen: 0,
    );
  }

  Rank _bestNonJokerRank(Rank r, Rank levelRank) {
    // 若 base 给的是普通牌，则仍然可以用癞子“变成级牌”来更大
    // 但如果 base 里已经是王（不该出现在这里），就返回 base
    if (r == Rank.bigJoker || r == Rank.smallJoker) return r;
    // 级牌在排序中高于 A：所以单张最优就是 levelRank
    return levelRank;
  }

  ResolvedPlay? _tryPair(List<PlayingCard> base, int wc, Rank levelRank) {
    if (base.any((c) => c.suit == Suit.joker)) return null;
    final byRank = groupBy(base, (c) => c.rank);
    if (byRank.length > 1) return null;

    final r = byRank.isEmpty ? levelRank : byRank.keys.first;
    if (!_isNonJokerRank(r)) return null;

    final need = 2 - base.length;
    if (need < 0 || need > wc) return null;

    return ResolvedPlay(
      type: PlayType.pair,
      finalCards: [...base, ..._fakeCards(need, Suit.spade, r)],
      mainRank: r,
      length: 2,
      bombLen: 0,
    );
  }

  ResolvedPlay? _tryTriple(List<PlayingCard> base, int wc, Rank levelRank) {
    if (base.any((c) => c.suit == Suit.joker)) return null;
    final byRank = groupBy(base, (c) => c.rank);
    if (byRank.length > 1) return null;

    final r = byRank.isEmpty ? levelRank : byRank.keys.first;
    if (!_isNonJokerRank(r)) return null;

    final need = 3 - base.length;
    if (need < 0 || need > wc) return null;

    return ResolvedPlay(
      type: PlayType.triple,
      finalCards: [...base, ..._fakeCards(need, Suit.spade, r)],
      mainRank: r,
      length: 3,
      bombLen: 0,
    );
  }

  ResolvedPlay? _tryTripleWithPair(List<PlayingCard> base, int wc, Rank levelRank) {
    if (base.any((c) => c.suit == Suit.joker)) return null;

    // 枚举 tripleRank + pairRank（均非王）
    final ranks = _seqRanks; // 2..A
    ResolvedPlay? best;

    for (final tr in ranks) {
      for (final pr in ranks) {
        if (pr == tr) continue;

        // base 必须只包含 tr 或 pr，且不超量
        final trCount = base.where((c) => c.rank == tr).length;
        final prCount = base.where((c) => c.rank == pr).length;
        if (trCount + prCount != base.length) continue;
        if (trCount > 3 || prCount > 2) continue;

        final need = (3 - trCount) + (2 - prCount);
        if (need < 0 || need > wc) continue;

        final filled = <PlayingCard>[
          ...base,
          ..._fakeCards(3 - trCount, Suit.spade, tr),
          ..._fakeCards(2 - prCount, Suit.club, pr),
        ];

        final cand = ResolvedPlay(
          type: PlayType.tripleWithPair,
          finalCards: filled,
          mainRank: tr, // 三带二比较三张点
          length: 5,
          bombLen: 0,
        );

        best = _pickBetter(best, cand, levelRank);
      }
    }

    return best;
  }

  // -------------------- Straight 5 & StraightFlush 5 --------------------
  ResolvedPlay? _tryStraight5(List<PlayingCard> base, int wc, Rank levelRank) {
    // 顺子不能含王；且必须 5 张、5 个不同点
    if (base.any((c) => c.suit == Suit.joker)) return null;
    if (base.map((c) => c.rank).toSet().length != base.length) return null;

    ResolvedPlay? best;

    for (final seq in _allStraight5()) {
      // base ranks 必须都是 seq 子集
      if (!base.every((c) => seq.contains(c.rank))) continue;

      final need = 5 - base.length;
      if (need < 0 || need > wc) continue;

      final missing = seq.where((r) => base.every((c) => c.rank != r)).toList();
      if (missing.length != need) continue;

      final filled = <PlayingCard>[
        ...base,
        for (final r in missing) ..._fakeCards(1, Suit.spade, r),
      ];

      final cand = ResolvedPlay(
        type: PlayType.straight5,
        finalCards: filled,
        mainRank: seq.last, // 顺子比最大点
        length: 5,
        bombLen: 0,
      );

      best = _pickBetter(best, cand, levelRank);
    }

    return best;
  }

  ResolvedPlay? _tryStraightFlush5(List<PlayingCard> base, int wc, Rank levelRank) {
    // 同花顺：5张同花色 + 连续；癞子可补花色与点，但不能当王
    if (base.any((c) => c.suit == Suit.joker)) return null;
    if (base.isEmpty) {
      // 全癞子：可以形成任意同花顺，为最大压制选“最大顺子”：10-J-Q-K-A
      final seq = [Rank.ten, Rank.jack, Rank.queen, Rank.king, Rank.ace];
      return ResolvedPlay(
        type: PlayType.straightFlush5,
        finalCards: _fakeCardsFromSeq(seq, Suit.spade),
        mainRank: seq.last,
        length: 5,
        bombLen: 0,
      );
    }

    final suit = base.first.suit;
    if (base.any((c) => c.suit != suit)) return null;
    if (base.map((c) => c.rank).toSet().length != base.length) return null;

    ResolvedPlay? best;

    for (final seq in _allStraight5()) {
      if (!base.every((c) => seq.contains(c.rank))) continue;

      final need = 5 - base.length;
      if (need < 0 || need > wc) continue;

      final missing = seq.where((r) => base.every((c) => c.rank != r)).toList();
      if (missing.length != need) continue;

      final filled = <PlayingCard>[
        ...base,
        for (final r in missing) ..._fakeCards(1, suit, r),
      ];

      final cand = ResolvedPlay(
        type: PlayType.straightFlush5,
        finalCards: filled,
        mainRank: seq.last,
        length: 5,
        bombLen: 0,
      );

      best = _pickBetter(best, cand, levelRank);
    }

    return best;
  }

  // -------------------- Three consecutive pairs (6) --------------------
  ResolvedPlay? _tryThreeConsecutivePairs(List<PlayingCard> base, int wc, Rank levelRank) {
    if (base.any((c) => c.suit == Suit.joker)) return null;
    if (base.length > 6) return null;

    // 枚举起点：2..Q（因为需要3个连续点：start,start+1,start+2）
    ResolvedPlay? best;
    for (var start = 0; start <= _seqRanks.length - 3; start++) {
      final r1 = _seqRanks[start];
      final r2 = _seqRanks[start + 1];
      final r3 = _seqRanks[start + 2];
      final allowed = {r1, r2, r3};

      if (!base.every((c) => allowed.contains(c.rank))) continue;

      final c1 = base.where((c) => c.rank == r1).length;
      final c2 = base.where((c) => c.rank == r2).length;
      final c3 = base.where((c) => c.rank == r3).length;

      if (c1 > 2 || c2 > 2 || c3 > 2) continue;

      final need = (2 - c1) + (2 - c2) + (2 - c3);
      if (need < 0 || need > wc) continue;

      final filled = <PlayingCard>[
        ...base,
        ..._fakeCards(2 - c1, Suit.spade, r1),
        ..._fakeCards(2 - c2, Suit.heart, r2),
        ..._fakeCards(2 - c3, Suit.club, r3),
      ];

      final cand = ResolvedPlay(
        type: PlayType.threeConsecutivePairs,
        finalCards: filled,
        mainRank: r3, // 三连对比最高对子点
        length: 6,
        bombLen: 0,
      );

      best = _pickBetter(best, cand, levelRank);
    }

    return best;
  }

  // -------------------- Steel plate (two consecutive triples, 6) --------------------
  ResolvedPlay? _trySteelPlate(List<PlayingCard> base, int wc, Rank levelRank) {
    if (base.any((c) => c.suit == Suit.joker)) return null;
    if (base.length > 6) return null;

    ResolvedPlay? best;
    // 枚举起点：2..K（需要两连：start,start+1）
    for (var start = 0; start <= _seqRanks.length - 2; start++) {
      final r1 = _seqRanks[start];
      final r2 = _seqRanks[start + 1];
      final allowed = {r1, r2};

      if (!base.every((c) => allowed.contains(c.rank))) continue;

      final c1 = base.where((c) => c.rank == r1).length;
      final c2 = base.where((c) => c.rank == r2).length;

      if (c1 > 3 || c2 > 3) continue;

      final need = (3 - c1) + (3 - c2);
      if (need < 0 || need > wc) continue;

      final filled = <PlayingCard>[
        ...base,
        ..._fakeCards(3 - c1, Suit.spade, r1),
        ..._fakeCards(3 - c2, Suit.heart, r2),
      ];

      final cand = ResolvedPlay(
        type: PlayType.steelPlate,
        finalCards: filled,
        mainRank: r2, // 钢板比高三张点（第二组的点）
        length: 6,
        bombLen: 0,
      );

      best = _pickBetter(best, cand, levelRank);
    }

    return best;
  }

  // -------------------- pick better --------------------
  ResolvedPlay? _pickBetter(ResolvedPlay? a, ResolvedPlay b, Rank levelRank) {
    if (a == null) return b;
    final pa = _power(a);
    final pb = _power(b);
    if (pb != pa) return pb > pa ? b : a;

    // 同层：同type比 mainRank
    if (RankOrder.strength(b.mainRank, levelRank) > RankOrder.strength(a.mainRank, levelRank)) {
      return b;
    }
    return a;
  }

  // -------------------- fake card builders for explanation --------------------
  List<PlayingCard> _fakeCards(int n, Suit suit, Rank rank) {
    if (n <= 0) return const [];
    // id 用负数避免与真实牌冲突（仅用于解释牌面）
    return List.generate(n, (i) => PlayingCard(suit: suit, rank: rank, id: -1000000 - i));
  }

  List<PlayingCard> _fakeCardsFromSeq(List<Rank> seq, Suit suit) {
    var idx = 0;
    return [
      for (final r in seq) PlayingCard(suit: suit, rank: r, id: -2000000 - (idx++)),
    ];
  }
}
