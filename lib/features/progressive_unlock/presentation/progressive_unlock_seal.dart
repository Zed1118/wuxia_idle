import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../application/progressive_unlock_providers.dart';
import '../application/progressive_unlock_service.dart';
import '../domain/progressive_unlock.dart';

Future<void> observeCurrentProgressiveUnlocks({
  required BuildContext context,
  required WidgetRef ref,
  DateTime? now,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  final observation = await ref.read(
    currentProgressiveUnlockObservationProvider.future,
  );
  if (observation == null) return;
  if (!context.mounted) return;
  await maybeShowProgressiveUnlockSeal(
    context: context,
    saveDataId: observation.saveDataId,
    snapshot: observation.snapshot,
    receiptPort: ProgressiveUnlockService(isar),
    now: now ?? DateTime.now(),
  );
}

Future<void> maybeShowProgressiveUnlockSeal({
  required BuildContext context,
  required int saveDataId,
  required ProgressiveUnlockSnapshot snapshot,
  required ProgressiveUnlockReceiptPort receiptPort,
  required DateTime now,
}) async {
  final pending = await receiptPort.observe(
    saveDataId: saveDataId,
    snapshot: snapshot,
    now: now,
  );
  if (pending.isEmpty || !context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PaperDialog(
      title: UiStrings.progressiveUnlockSealTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(UiStrings.progressiveUnlockSealBody),
          const SizedBox(height: 10),
          for (final entry in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(UiStrings.progressiveUnlockName(entry.unlockId.name)),
            ),
        ],
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.progressiveUnlockSealConfirm,
          primary: true,
          autofocus: true,
          onTap: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  if (accepted != true) return;
  await receiptPort.acknowledge(
    saveDataId: saveDataId,
    unlockIds: pending.map((entry) => entry.unlockId),
    now: now,
  );
}
