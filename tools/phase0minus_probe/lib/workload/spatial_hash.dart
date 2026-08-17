import 'package:flame/components.dart';

final class SpatialHash<T extends PositionComponent> {
  SpatialHash(this.cellSize);

  final double cellSize;
  final Map<(int, int), List<T>> _cells = {};

  void rebuild(Iterable<T> components) {
    _cells.clear();
    for (final component in components) {
      final key = _key(component.position);
      (_cells[key] ??= []).add(component);
    }
  }

  List<T> query(Vector2 position, double radius) {
    final range = (radius / cellSize).ceil();
    final center = _key(position);
    final result = <T>[];
    for (var x = center.$1 - range; x <= center.$1 + range; x++) {
      for (var y = center.$2 - range; y <= center.$2 + range; y++) {
        final cell = _cells[(x, y)];
        if (cell != null) result.addAll(cell);
      }
    }
    return result;
  }

  (int, int) _key(Vector2 position) =>
      ((position.x / cellSize).floor(), (position.y / cellSize).floor());
}
