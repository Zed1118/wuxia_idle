import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_archive_chrome.dart';

void main() {
  testWidgets('深色档案页共享题头、分区题签和卡面保持克制水墨层级', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              InkPageHeader(title: 'Title', subtitle: 'Subtitle'),
              InkSectionLabel('Section'),
              InkListCard(selected: true, child: Text('Card content')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(InkPageHeader), findsOneWidget);
    expect(find.byType(InkSectionLabel), findsOneWidget);
    expect(find.byType(InkListCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inkArchive.sectionDryBrush')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inkArchive.selectedMark')),
      findsOneWidget,
    );
  });
}
