import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/rule_config.dart';
import '../model/game_state.dart';
import 'actions.dart';
import 'game_reducer.dart';

class GameEngine {
  final RuleConfig cfg;
  final GameReducer reducer;

  GameEngine(this.cfg) : reducer = GameReducer(cfg);

  GameState dispatch(GameState s, GameAction a) => reducer.reduce(s, a);
}

class GameStateNotifier extends StateNotifier<GameState> {
  final GameEngine engine;

  GameStateNotifier(this.engine) : super(GameState.initial(engine.cfg));

  void dispatch(GameAction a) {
    state = engine.dispatch(state, a);
  }
}
