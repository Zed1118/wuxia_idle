/// Rejects spawn dependency graphs that could never release a pending entry.
/// Callers own the meaning of completion (the director uses removed entries).
void validateSpawnDependencies(Map<String, Iterable<String>> dependencies) {
  final visiting = <String>{};
  final visited = <String>{};
  void visit(String id) {
    if (visited.contains(id)) return;
    if (!visiting.add(id)) {
      throw ArgumentError.value(id, 'spawnDependencies', 'cyclic dependency');
    }
    final seen = <String>{};
    for (final dependency in dependencies[id]!) {
      if (dependency.isEmpty ||
          RegExp(r'\s').hasMatch(dependency) ||
          !seen.add(dependency) ||
          !dependencies.containsKey(dependency) ||
          dependency == id) {
        throw ArgumentError.value(
          dependency,
          'spawnDependencies',
          'dependency must be a unique, known, different entry id',
        );
      }
      visit(dependency);
    }
    visiting.remove(id);
    visited.add(id);
  }

  for (final id in dependencies.keys) {
    visit(id);
  }
}
