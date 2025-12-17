import '../enums/seat.dart';
import 'play.dart';

class TrickState {
  final Seat leader;
  final Play? lastPlay; // 当前轮最后一个有效出牌

  const TrickState({
    required this.leader,
    required this.lastPlay,
  });

  TrickState copyWith({Seat? leader, Play? lastPlay}) {
    return TrickState(
      leader: leader ?? this.leader,
      lastPlay: lastPlay ?? this.lastPlay,
    );
  }

  factory TrickState.newTrick(Seat leader) => TrickState(leader: leader, lastPlay: null);
}
