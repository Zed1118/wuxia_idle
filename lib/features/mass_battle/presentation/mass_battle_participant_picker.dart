import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../application/mass_battle_participant_service.dart';

Future<int?> selectMassBattleParticipant({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  late final List<MassBattleParticipantCandidate> candidates;
  try {
    ref.invalidate(massBattleParticipantCandidatesProvider);
    candidates = await ref.read(massBattleParticipantCandidatesProvider.future);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.massBattleParticipantUnavailable),
        ),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  if (!candidates.any((candidate) => candidate.selectable)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(UiStrings.massBattleParticipantNoneEligible),
      ),
    );
    return null;
  }
  return showMassBattleParticipantPicker(
    context: context,
    candidates: candidates,
  );
}

Future<int?> showMassBattleParticipantPicker({
  required BuildContext context,
  required List<MassBattleParticipantCandidate> candidates,
}) => PaperDialog.show<int>(
  context,
  title: UiStrings.massBattleParticipantTitle,
  body: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(UiStrings.massBattleParticipantBody),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: candidates.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, index) {
            final candidate = candidates[index];
            final status = candidate.occupied
                ? UiStrings.massBattleParticipantOccupied
                : candidate.healing
                ? UiStrings.massBattleParticipantHealing
                : candidate.hasMainTechnique
                ? UiStrings.massBattleParticipantAvailable
                : UiStrings.massBattleParticipantNoMainTechnique;
            return OutlinedButton(
              key: ValueKey(
                'mass_battle_participant_${candidate.character.id}',
              ),
              onPressed: candidate.selectable
                  ? () => Navigator.of(context).pop(candidate.character.id)
                  : null,
              child: Row(
                children: [
                  Expanded(child: Text(candidate.character.name)),
                  Text(status),
                ],
              ),
            );
          },
        ),
      ),
    ],
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(UiStrings.commonCancel),
    ),
  ],
);
