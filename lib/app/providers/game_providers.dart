import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/config/rule_config.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/model/game_state.dart';

final ruleConfigProvider = Provider<RuleConfig>((ref) {
  return RuleConfig.defaultConfig();
});

final gameEngineProvider = Provider<GameEngine>((ref) {
  final cfg = ref.watch(ruleConfigProvider);
  return GameEngine(cfg);
});

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  final engine = ref.watch(gameEngineProvider);
  return GameStateNotifier(engine);
});
