import 'package:flutter/foundation.dart' show FlutterError, debugPrint;

/// Loader fallback paths are valid for optional narrative/lore assets.
/// Keep parse errors visible in debug output, but do not spam stack traces for
/// expected missing assets or rootBundle access before a Flutter binding exists.
void debugLoaderFallback(String source, Object error) {
  if (_isExpectedAssetFallback(error)) return;
  debugPrint('$source fallback: $error');
}

void debugLoaderSkip(String source, Object error) {
  if (_isExpectedAssetFallback(error)) return;
  debugPrint('$source skip: $error');
}

bool _isExpectedAssetFallback(Object error) {
  if (error is! FlutterError) return false;
  final message = error.message;
  return message.contains('Unable to load asset') ||
      message.contains('Binding has not yet been initialized');
}
