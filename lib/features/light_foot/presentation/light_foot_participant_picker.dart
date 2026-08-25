import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../application/light_foot_participant_service.dart';

Future<int?> selectLightFootParticipant({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  late final List<LightFootParticipantCandidate> candidates;
  try {
    ref.invalidate(lightFootParticipantCandidatesProvider);
    candidates = await ref.read(lightFootParticipantCandidatesProvider.future);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.lightFootParticipantUnavailable),
        ),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  if (!candidates.any((candidate) => candidate.selectable)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(UiStrings.lightFootParticipantNoneEligible)),
    );
    return null;
  }
  return showLightFootParticipantPicker(
    context: context,
    candidates: candidates,
  );
}

Future<int?> showLightFootParticipantPicker({
  required BuildContext context,
  required List<LightFootParticipantCandidate> candidates,
}) => PaperDialog.show<int>(
  context,
  title: UiStrings.lightFootParticipantTitle,
  body: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(UiStrings.lightFootParticipantBody),
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
                ? UiStrings.lightFootParticipantOccupied
                : candidate.healing
                ? UiStrings.lightFootParticipantHealing
                : candidate.hasMainTechnique
                ? UiStrings.lightFootParticipantAvailable
                : UiStrings.lightFootParticipantNoMainTechnique;
            return OutlinedButton(
              key: ValueKey('light_foot_participant_${candidate.character.id}'),
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
