import '../model/play.dart';

class GameLogEntry {
  final DateTime ts;
  final String text;
  final Play? play;

  GameLogEntry({required this.ts, required this.text, this.play});
}

class GameLog {
  final List<GameLogEntry> entries;

  const GameLog({required this.entries});

  GameLog append(GameLogEntry e) => GameLog(entries: [...entries, e]);

  factory GameLog.empty() => const GameLog(entries: []);
}
