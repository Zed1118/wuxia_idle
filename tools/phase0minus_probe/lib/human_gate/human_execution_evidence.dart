import 'dart:io';

Future<List<String>> validateHumanExecutionEvidence({
  required File sessionState,
  required File executionEvents,
  required String participantId,
  required String participantSessionId,
  required String order,
}) async {
  final errors = <String>[];
  if (!await sessionState.exists()) {
    return ['$participantId missing session.state'];
  }
  if (!await executionEvents.exists()) {
    return ['$participantId missing execution.events'];
  }
  final state = <String, String>{};
  for (final line in await sessionState.readAsLines()) {
    final separator = line.indexOf('=');
    if (separator > 0) {
      state[line.substring(0, separator)] = line.substring(separator + 1);
    }
  }
  if (state['status'] != 'COMPLETE') {
    errors.add('$participantId session status is not COMPLETE');
  }
  if (state['participant_id'] != participantId ||
      state['session_id'] != participantSessionId ||
      state['assignment'] != order) {
    errors.add('$participantId session.state identity mismatch');
  }
  final actual = await executionEvents.readAsLines();
  final expected = order == 'AB'
      ? const [
          'comparison_complete',
          'gameplay_complete',
          'readability_complete',
        ]
      : const [
          'gameplay_complete',
          'comparison_complete',
          'readability_complete',
        ];
  if (!_sameStrings(actual, expected)) {
    errors.add('$participantId execution order/integrity mismatch');
  }
  return errors;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
