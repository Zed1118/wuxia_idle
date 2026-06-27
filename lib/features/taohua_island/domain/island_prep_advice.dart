enum IslandPrepAdviceKind { equipment, skillFragment, bossCycle }

enum IslandPrepAdvicePriority { normal, high }

class IslandPrepAdvice {
  const IslandPrepAdvice({
    required this.kind,
    required this.title,
    required this.body,
    this.sourceId,
    this.priority = IslandPrepAdvicePriority.normal,
  });

  final IslandPrepAdviceKind kind;
  final String title;
  final String body;
  final String? sourceId;
  final IslandPrepAdvicePriority priority;
}
