import 'package:collection/collection.dart';

import '../cards/deck.dart';
import '../config/rule_config.dart';
import '../enums/phase.dart';
import '../enums/seat.dart';
import '../log/game_log.dart';
import '../model/game_state.dart';
import '../model/play.dart';
import '../model/trick_state.dart';
import '../rules/hand_analyzer.dart';
import '../rules/legal_move.dart';
import 'actions.dart';

class GameReducer {
  final RuleConfig cfg;
  GameReducer(this.cfg);

  GameState reduce(GameState s, GameAction a) {
    return switch (a) {
      DealAction da => _deal(s, da.seed),
      ToggleSelectCardAction ta => _toggleSelect(s, ta.cardId),
      ClearSelectionAction() => s.copyWith(selectedCardIds: <int>{}),
      PlaySelectedAction pa => _playSelected(s, pa.seat),
      PassAction pa => _pass(s, pa.seat),
    };
  }

  GameState _deal(GameState s, int? seed) {
    final deck = Deck(deckCount: cfg.deckCount, seed: seed).buildShuffled();

    // 2副牌=108张，4人=27张/人
    final hands = <Seat, List<dynamic>>{};
    for (final seat in Seat.values) {
      hands[seat] = <dynamic>[];
    }

    for (var i = 0; i < deck.length; i++) {
      final seat = Seat.values[i % 4];
      (hands[seat] as List).add(deck[i]);
    }

    final players = Seat.values.map((seat) {
      final list = (hands[seat] as List).cast();
      // 简单排序：按 id 排，后续你可改成按 RankOrder 排
      list.sort((a, b) => a.id.compareTo(b.id));
      return s.player(seat).copyWith(hand: list.cast());
    }).toList(growable: false);

    return s.copyWith(
      phase: Phase.playing,
      players: players,
      currentTurn: Seat.s0,
      trick: TrickState.newTrick(Seat.s0),
      passed: <Seat>{},
      selectedCardIds: <int>{},
      log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '发牌完成：每人${players.first.hand.length}张')),
    );
  }

  GameState _toggleSelect(GameState s, int cardId) {
    if (s.phase != Phase.playing) return s;
    final selected = {...s.selectedCardIds};
    if (selected.contains(cardId)) {
      selected.remove(cardId);
    } else {
      selected.add(cardId);
    }
    return s.copyWith(selectedCardIds: selected);
  }

  GameState _playSelected(GameState s, Seat seat) {
    if (s.phase != Phase.playing) return s;
    if (s.currentTurn != seat) return s;

    final me = s.player(seat);
    final chosen = me.hand.where((c) => s.selectedCardIds.contains(c.id)).toList();
    if (chosen.isEmpty) {
      return s.copyWith(
        log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '未选择牌，无法出牌')),
      );
    }

    final analyzer = HandAnalyzer(cfg);
    ResolvedPlay resolved;
    try {
      resolved = analyzer.analyze(chosen, s.levelRank);
    } catch (e) {
      return s.copyWith(
        log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '判型失败：$e')),
      );
    }

    final err = LegalMove.validatePlay(
      state: s,
      candidate: resolved,
      lastPlay: s.trick.lastPlay,
    );
    if (err != null) {
      return s.copyWith(
        log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '出牌不合法：$err')),
      );
    }

    final newHand = [...me.hand]..removeWhere((c) => s.selectedCardIds.contains(c.id));
    final newPlayers = [...s.players];
    newPlayers[seat.index] = me.copyWith(hand: newHand);

    final play = Play(seat: seat, rawCards: chosen, resolved: resolved);
    var next = s.copyWith(
      players: newPlayers,
      trick: s.trick.copyWith(lastPlay: play),
      currentTurn: seat.next(),
      passed: <Seat>{}, // 一旦有人出牌，pass重置
      selectedCardIds: <int>{},
      log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '座位${seat.index} 出牌：${resolved.type}(${resolved.length})', play: play)),
    );

    // 若出完牌：简单结束（V1你可以接入“头游/接风/结算”）
    if (newHand.isEmpty) {
      next = next.copyWith(
        phase: Phase.finished,
        log: next.log.append(GameLogEntry(ts: DateTime.now(), text: '座位${seat.index} 牌出完，本局结束（V1接入头游/接风/结算）')),
      );
    }

    return next;
  }

  GameState _pass(GameState s, Seat seat) {
    if (s.phase != Phase.playing) return s;
    if (s.currentTurn != seat) return s;

    // 若无人领出，不能pass（通常规则：领出必须出牌）
    if (s.trick.lastPlay == null && s.trick.leader == seat) {
      return s.copyWith(
        log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '领出不能过牌')),
      );
    }

    final passed = {...s.passed, seat};
    var next = s.copyWith(
      passed: passed,
      currentTurn: seat.next(),
      selectedCardIds: <int>{},
      log: s.log.append(GameLogEntry(ts: DateTime.now(), text: '座位${seat.index} 过牌')),
    );

    // 本轮结束条件：除最后出牌者外，其余3人都pass
    final last = s.trick.lastPlay;
    if (last != null) {
      final othersPassed = Seat.values.where((x) => x != last.seat).every(passed.contains);
      if (othersPassed) {
        // 你的规则：对家接风
        final nextLeader = last.seat.partner();
        next = next.copyWith(
          trick: TrickState.newTrick(nextLeader),
          currentTurn: nextLeader,
          passed: <Seat>{},
          log: next.log.append(GameLogEntry(ts: DateTime.now(), text: '本轮结束：对家接风 => 座位${nextLeader.index} 领出')),
        );
      }
    }

    return next;
  }
}
