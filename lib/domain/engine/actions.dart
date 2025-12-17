import '../enums/seat.dart';

sealed class GameAction {}

class DealAction extends GameAction {
  final int? seed;
  DealAction({this.seed});
}

class ToggleSelectCardAction extends GameAction {
  final int cardId;
  ToggleSelectCardAction(this.cardId);
}

class ClearSelectionAction extends GameAction {}

class PlaySelectedAction extends GameAction {
  final Seat seat;
  PlaySelectedAction(this.seat);
}

class PassAction extends GameAction {
  final Seat seat;
  PassAction(this.seat);
}
