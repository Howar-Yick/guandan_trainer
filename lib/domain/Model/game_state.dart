import '../config/rule_config.dart';
import '../enums/phase.dart';
import '../enums/rank.dart';
import '../enums/seat.dart';
import '../log/game_log.dart';
import 'player_state.dart';
import 'trick_state.dart';

class GameState {
  final Phase phase;
  final RuleConfig config;

  final Rank levelRank;
  final List<PlayerState> players;

  final Seat currentTurn;
  final TrickState trick;

  // 本轮已pass的座位
  final Set<Seat> passed;

  final GameLog log;

  // UI状态：当前玩家（默认 s0）选中的牌 id 集合
  final Set<int> selectedCardIds;

  const GameState({
    required this.phase,
    required this.config,
    required this.levelRank,
    required this.players,
    required this.currentTurn,
    required this.trick,
    required this.passed,
    required this.log,
    required this.selectedCardIds,
  });

  PlayerState player(Seat seat) => players[seat.index];

  GameState copyWith({
    Phase? phase,
    Rank? levelRank,
    List<PlayerState>? players,
    Seat? currentTurn,
    TrickState? trick,
    Set<Seat>? passed,
    GameLog? log,
    Set<int>? selectedCardIds,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      config: config,
      levelRank: levelRank ?? this.levelRank,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      trick: trick ?? this.trick,
      passed: passed ?? this.passed,
      log: log ?? this.log,
      selectedCardIds: selectedCardIds ?? this.selectedCardIds,
    );
  }

  factory GameState.initial(RuleConfig cfg) {
    final players = Seat.values
        .map((s) => PlayerState(seat: s, hand: const []))
        .toList(growable: false);

    return GameState(
      phase: Phase.init,
      config: cfg,
      levelRank: cfg.initialLevel,
      players: players,
      currentTurn: Seat.s0,
      trick: TrickState.newTrick(Seat.s0),
      passed: <Seat>{},
      log: GameLog.empty(),
      selectedCardIds: <int>{},
    );
  }
}
