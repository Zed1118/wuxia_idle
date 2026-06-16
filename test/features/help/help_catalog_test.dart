import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/codex/domain/codex_index.dart';
import 'package:wuxia_idle/features/help/domain/help_topic.dart';

/// 上下文帮助系统 · HelpCatalog 红线契约（2026-06-16）。
///
/// 核心防 drift 测：每个 [HelpBinding.codexEntryId] 必须命中 `CodexIndex`，
/// 杜绝「帮助系统与百科登记表脱节」的双真相源漂移。
void main() {
  group('HelpCatalog', () {
    test('每个 HelpTopic 都有 binding（全覆盖，of() 不会抛）', () {
      for (final topic in HelpTopic.values) {
        expect(
          HelpCatalog.bindings.containsKey(topic),
          isTrue,
          reason: '缺 binding: $topic',
        );
      }
    });

    test('每个非空 codexEntryId 必命中 CodexIndex（防双真相源 drift）', () {
      for (final entry in HelpCatalog.bindings.entries) {
        final id = entry.value.codexEntryId;
        if (id != null) {
          expect(
            CodexIndex.byId(id),
            isNotNull,
            reason: '${entry.key} → 未登记 codex id "$id"',
          );
        }
      }
    });

    test('label / shortText 均非空', () {
      for (final binding in HelpCatalog.bindings.values) {
        expect(binding.label.trim(), isNotEmpty);
        expect(binding.shortText.trim(), isNotEmpty);
      }
    });
  });

  group('helpEntryUnlocked', () {
    test('md 未加载 → 永远 locked', () {
      expect(
        helpEntryUnlocked(requiredStep: 1, isLoaded: false, currentStep: 8),
        isFalse,
      );
    });

    test('已加载 + step 达标 → unlocked', () {
      expect(
        helpEntryUnlocked(requiredStep: 5, isLoaded: true, currentStep: 5),
        isTrue,
      );
    });

    test('已加载 + step 未达 → locked', () {
      expect(
        helpEntryUnlocked(requiredStep: 6, isLoaded: true, currentStep: 5),
        isFalse,
      );
    });

    test('requiredStep null（lore）→ 视为 0，已加载即 unlocked', () {
      expect(
        helpEntryUnlocked(requiredStep: null, isLoaded: true, currentStep: 0),
        isTrue,
      );
    });
  });
}
