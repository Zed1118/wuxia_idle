import 'package:isar_community/isar.dart';

Future<void>? _initialization;

Future<void> initializeTestIsarCore() =>
    _initialization ??= Isar.initializeIsarCore(download: true);
