import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  test('parseVisualRoute 识别 redline_audit', () {
    expect(parseVisualRoute('redline_audit'), VisualRoute.redlineAudit);
  });
}
