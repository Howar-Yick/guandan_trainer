import '../cards/card.dart';
import '../enums/seat.dart';

class PlayerState {
  final Seat seat;
  final List<PlayingCard> hand;

  const PlayerState({
    required this.seat,
    required this.hand,
  });

  PlayerState copyWith({List<PlayingCard>? hand}) {
    return PlayerState(seat: seat, hand: hand ?? this.hand);
  }
}
