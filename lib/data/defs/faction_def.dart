class FactionDef {
  final String id;
  final String name;
  final String alignment;
  final List<String> npcIds;

  const FactionDef({
    required this.id,
    required this.name,
    required this.alignment,
    required this.npcIds,
  });

  factory FactionDef.fromYaml(Map<String, dynamic> yaml) {
    final id = (yaml['id'] as String? ?? '').trim();
    final name = (yaml['name'] as String? ?? '').trim();
    if (id.isEmpty) throw StateError('faction id 不可为空');
    if (name.isEmpty) throw StateError('faction $id name 不可为空');
    return FactionDef(
      id: id,
      name: name,
      alignment: yaml['alignment'] as String,
      npcIds: List<String>.unmodifiable(
        ((yaml['npc_ids'] as List?) ?? const []).cast<String>(),
      ),
    );
  }
}
