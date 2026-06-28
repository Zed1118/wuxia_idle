import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/material_source_lookup_service.dart';

class MaterialSourceNote extends StatelessWidget {
  const MaterialSourceNote({super.key, required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    final repo = GameRepository.instanceOrNull;
    if (repo == null || itemIds.isEmpty) return const SizedBox.shrink();

    final service = MaterialSourceLookupService(repo);
    final sources = [
      for (final itemId in itemIds) ...service.sourcesFor(itemId),
    ];
    final summary = UiStrings.materialSourceSummary(sources);
    if (summary.isEmpty) return const SizedBox.shrink();

    return Text(
      summary,
      style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
    );
  }
}
