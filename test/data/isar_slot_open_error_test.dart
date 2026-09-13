import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/slot_summary.dart';

void main() {
  const invalidFileMessage =
      'Cannot open Environment: MdbxError (-30793): '
      'MDBX_INVALID: File is not an MDBX file';

  test('Linux invalid-file probe keeps its native cause and stack', () async {
    final cause = IsarError(invalidFileMessage);
    final nativeStack = StackTrace.fromString('native slot probe open');
    Object? observed;
    StackTrace? observedStack;
    try {
      await IsarSetup.openSlotReadProbe<Isar>(
        () => Future<Isar>.error(cause, nativeStack),
      );
    } catch (error, stackTrace) {
      observed = error;
      observedStack = stackTrace;
    }
    expect(
      observed,
      isA<UnreadableSaveException>()
          .having((error) => error.cause, 'native cause', same(cause))
          .having(
            (error) => error.toString(),
            'diagnostic text',
            contains(cause.toString()),
          ),
    );
    expect(observedStack.toString(), nativeStack.toString());
  });

  test(
    'probe does not label setup, runtime or future-version errors as damage',
    () async {
      final failures = <Object>[
        IsarError('Isar instance has already been closed'),
        IsarError('Duplicate collection SaveData.'),
        IsarError('Could not initialize IsarCore library'),
        IsarError('Cannot open Environment: Permission denied'),
        IsarError('Cannot open Environment: MdbxError (-30792): MDBX_MAP_FULL'),
        IsarError(
          'Diagnostic text mentions MDBX_INVALID without native failure',
        ),
        StateError(invalidFileMessage),
        const UnsupportedSaveVersionException(
          actualVersion: '0.99.0',
          supportedVersion: '0.50.0',
        ),
      ];
      for (final failure in failures) {
        await expectLater(
          IsarSetup.openSlotReadProbe<Isar>(() => Future<Isar>.error(failure)),
          throwsA(same(failure)),
          reason: failure.toString(),
        );
      }
    },
  );

  test('successful native probe keeps the returned instance', () async {
    final value = Object();
    expect(await IsarSetup.openSlotReadProbe(() async => value), same(value));
  });
}
