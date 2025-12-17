enum Seat { s0, s1, s2, s3 }

extension SeatX on Seat {
  int get index => Seat.values.indexOf(this);

  Seat next() => Seat.values[(index + 1) % 4];
  Seat partner() => Seat.values[(index + 2) % 4];
}
