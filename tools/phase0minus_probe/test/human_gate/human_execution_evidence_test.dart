import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/human_gate/human_execution_evidence.dart';

void main() {
  test(
    'accepts complete frozen AB evidence and rejects interrupted state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'phase0a-evidence-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final state = File('${directory.path}/session.state');
      final events = File('${directory.path}/execution.events');
      await state.writeAsString(
        'session_id=session-p01\nparticipant_id=P01\nassignment=AB\nstatus=COMPLETE\n',
      );
      await events.writeAsString(
        'comparison_complete\ngameplay_complete\nreadability_complete\n',
      );

      expect(
        await validateHumanExecutionEvidence(
          sessionState: state,
          executionEvents: events,
          participantId: 'P01',
          participantSessionId: 'session-p01',
          order: 'AB',
        ),
        isEmpty,
      );

      await state.writeAsString(
        'session_id=session-p01\nparticipant_id=P01\nassignment=AB\nstatus=IN_PROGRESS\n',
      );
      await events.writeAsString('comparison_complete\n');
      final errors = await validateHumanExecutionEvidence(
        sessionState: state,
        executionEvents: events,
        participantId: 'P01',
        participantSessionId: 'session-p01',
        order: 'AB',
      );
      expect(errors, hasLength(2));
    },
  );
}
