import 'dart:math';

class TowerLayer {
  final double left, width;
  final int player;
  const TowerLayer(this.left, this.width, this.player);
}

class TowerBoard {
  final layers = <TowerLayer>[const TowerLayer(.09, .82, -1)];

  /// Returns overlap accuracy; zero means the new block fell off the stack.
  int drop(double left, int player) {
    final top = layers.last,
        l = max(top.left, left),
        r = min(top.left + top.width, left + top.width),
        overlap = r - l;
    if (overlap <= .018) return 0;
    layers.add(TowerLayer(l, overlap, player));
    return (overlap / top.width * 100).round();
  }
}

class TrafficCar {
  final int player, axis;
  double progress;
  TrafficCar(this.player, this.axis, [this.progress = -.08]);
}

bool trafficCollision(Iterable<TrafficCar> cars, int player) {
  final crossing =
      cars
          .where((c) => c.player == player && (c.progress - .5).abs() < .075)
          .toList();
  return crossing.any((a) => crossing.any((b) => a.axis != b.axis));
}
