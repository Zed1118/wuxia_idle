# 多存档槽（选择/新开/删除）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans / subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** 让玩家在 3 个固定存档槽间选择/新开/删除存档。启动先进「存档选择屏」，选中后进主菜单。现有玩家存档=slot1 不迁移。

**Architecture:** 多 db 方案已是既定架构（`IsarSetup.init(slotId)` 开 `wuxia_save_slot{N}.isar`，每槽独立 db，无串档）。本任务实装 3 个 Phase 5 TODO（switchSlot/listSlots/deleteSlot）+ SlotSummary 值对象 + 启动分流到 SaveSelectScreen + 切档 invalidate provider + 设置面板「切换存档」入口。**不动 schema、不加字段、不迁移现有 slot1**。

**Tech Stack:** Flutter Desktop / Riverpod 3.x / Isar(isar_community) / path_provider。验收 `flutter test` + `flutter analyze` 0 issue。

**硬约束（spec §4）：** 切档原子化（flush→close→open→set currentSlotId→invalidate）；listSlots 临时只读实例读完必 close（防句柄泄漏，当前槽用 `Isar.getInstance` 不重开）；删当前档后必回选择屏；切档/删当前档前先 flush（touchOnlineNow 结算离线基准）。

**恢复点（执行中更新）：** 状态=计划定稿，worktree multi-save-slot 环境已预热（55 .g.dart + dylib）。下一步=Task 1 IsarSetup 持久化层。

---

## 关键设计决策

1. **目录记忆**：IsarSetup 加 `static Directory? _directory`，init 时存。switchSlot/listSlots/deleteSlot 用 `directory ?? _directory ?? await getApplicationDocumentsDirectory()`；测试经各方法的可选 `directory` 参数注入。
2. **SlotSummary**（纯只读快照值对象，放 `lib/data/slot_summary.dart`）：`{int slotId, bool isEmpty, String? founderName, String? realmDisplay, int chapterIndex, int clearedStageCount, DateTime? lastPlayed}`。空槽 `SlotSummary.empty(n)`。
3. **空槽判定**：db 文件不存在 OR 存在但无 founder（防御）→ isEmpty=true。新 splash 流程下空槽根本无 db 文件（选中才 init）。
4. **switchSlot 统一开槽入口**：`_instance != null` 时先 touchOnlineNow + close，再 init(n)。首次选档（无打开实例）= 直接 init(n)。
5. **provider 刷新**：switchSlot 是 static（无 ref），invalidate 在 UI 调用点做 `ref.invalidate(isarProvider)`。GameRepository（配置·与槽无关）不重载。

---

## Task 1: SlotSummary 值对象 + IsarSetup 持久化三方法

**Files:**
- Create: `lib/data/slot_summary.dart`
- Modify: `lib/data/isar_setup.dart`（加 `_directory` + switchSlot/slotHasSave/listSlots/deleteSlot，删 3 TODO 注释）
- Test: `test/data/isar_setup_slots_test.dart`（新建）

- [ ] **Step 1: 写 SlotSummary**

`lib/data/slot_summary.dart`：
```dart
/// 存档槽只读摘要快照(给选择屏用,不写库不新增 schema 字段)。
class SlotSummary {
  const SlotSummary({
    required this.slotId,
    required this.isEmpty,
    this.founderName,
    this.realmDisplay,
    this.chapterIndex = 0,
    this.clearedStageCount = 0,
    this.lastPlayed,
  });

  final int slotId;
  final bool isEmpty;
  final String? founderName;
  final String? realmDisplay;
  final int chapterIndex;
  final int clearedStageCount;
  final DateTime? lastPlayed;

  factory SlotSummary.empty(int slotId) =>
      SlotSummary(slotId: slotId, isEmpty: true);
}
```

- [ ] **Step 2: 写失败测试（隔离/列表/删除）**

`test/data/isar_setup_slots_test.dart`（沿 isar_setup_test 体例 tempDir 注入）：
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_slots_test_');
  });

  tearDown(() async {
    for (final n in [1, 2, 3]) {
      final inst = Isar.getInstance('wuxia_save_slot$n');
      if (inst != null) await inst.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('switchSlot 隔离:slot1 写 → slot2 全新 → slot1 不受影响', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    expect(IsarSetup.currentSlotId, 1);
    final s1Founder =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s1Founder, greaterThan(0));

    await IsarSetup.switchSlot(2, directory: tempDir);
    expect(IsarSetup.currentSlotId, 2);
    // slot2 全新:无 founder(未 onboard)
    final s2Chars =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s2Chars, 0, reason: 'slot2 是独立新 db');

    await IsarSetup.switchSlot(1, directory: tempDir);
    final s1Again =
        (await IsarSetup.instance.characters.where().findAll()).length;
    expect(s1Again, s1Founder, reason: 'slot1 数据切回仍在');
  });

  test('slotHasSave / listSlots:混合有档+空槽摘要正确', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.switchSlot(2, directory: tempDir); // 切走以便 list 读 slot1
    await IsarSetup.close();

    expect(await IsarSetup.slotHasSave(1, directory: tempDir), true);
    expect(await IsarSetup.slotHasSave(3, directory: tempDir), false);

    final summaries = await IsarSetup.listSlots(directory: tempDir);
    expect(summaries.length, 3);
    expect(summaries[0].isEmpty, false);
    expect(summaries[0].founderName, isNotNull);
    expect(summaries[2].isEmpty, true);
    // 读完无句柄泄漏:list 后这些槽未保持打开
    expect(Isar.getInstance('wuxia_save_slot1'), isNull);
    expect(Isar.getInstance('wuxia_save_slot3'), isNull);
  });

  test('deleteSlot:删后 slotHasSave=false + 文件移除', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.close();
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), true);

    await IsarSetup.deleteSlot(1, directory: tempDir);
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), false);
    expect(
      await File('${tempDir.path}/wuxia_save_slot1.isar').exists(),
      false,
    );
  });

  test('deleteSlot 当前槽:先 close 再删,实例置空', () async {
    await IsarSetup.switchSlot(1, directory: tempDir);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.deleteSlot(1, directory: tempDir); // 删当前
    expect(IsarSetup.instanceOrNull, isNull, reason: '删当前档后实例置空');
    expect(await IsarSetup.slotHasSave(1, directory: tempDir), false);
  });
}
```

- [ ] **Step 3: 运行确认失败**

Run: `flutter test test/data/isar_setup_slots_test.dart`
Expected: 编译失败（switchSlot/slotHasSave/listSlots/deleteSlot/resetForTest 未定义）。

- [ ] **Step 4: 实装 IsarSetup 方法**

在 `lib/data/isar_setup.dart`：
1. import 顶部加 `import 'slot_summary.dart';` + `import '../core/domain/save_data.dart';`(已有) + Character/MainlineProgress(已有)。
2. 加静态字段：`static Directory? _directory;`
3. `init` 内 `final dir = directory ?? await getApplicationDocumentsDirectory();` 后加 `_directory = dir;`
4. 删除底部 3 行 `// TODO Phase 5:` 注释，替换为：
```dart
  /// 解析存档目录(记忆优先,生产兜底 path_provider)。
  static Future<Directory> _resolveDir(Directory? directory) async =>
      directory ?? _directory ?? await getApplicationDocumentsDirectory();

  /// 原子切档:flush 当前(结算离线基准)→ close → open 新槽 → set currentSlotId。
  /// provider 刷新由调用点 `ref.invalidate(isarProvider)` 负责(本方法无 ref)。
  static Future<void> switchSlot(int n, {Directory? directory}) async {
    assert(n >= 1 && n <= 3, 'slotId 必须 1/2/3');
    if (_instance != null) {
      await touchOnlineNow(); // flush:落最后在线时间,结算离线计时基准
      await close();
    }
    await init(slotId: n, directory: await _resolveDir(directory));
  }

  /// 该槽是否有存档(db 文件存在且含 founder)。
  static Future<bool> slotHasSave(int n, {Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final name = 'wuxia_save_slot$n';
    if (!await File('${dir.path}/$name.isar').exists()) return false;
    final already = Isar.getInstance(name);
    final isar = already ??
        await Isar.open(_allSchemas,
            directory: dir.path, name: name, inspector: false);
    try {
      return await isar.characters.filter().isFounderEqualTo(true).count() > 0;
    } finally {
      if (already == null) await isar.close();
    }
  }

  /// 遍历 1..3 槽读轻量摘要。当前已打开槽直接读不重开;临时只读实例读完即 close。
  static Future<List<SlotSummary>> listSlots({Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final out = <SlotSummary>[];
    for (var n = 1; n <= 3; n++) {
      final name = 'wuxia_save_slot$n';
      if (!await File('${dir.path}/$name.isar').exists()) {
        out.add(SlotSummary.empty(n));
        continue;
      }
      final already = Isar.getInstance(name);
      final isar = already ??
          await Isar.open(_allSchemas,
              directory: dir.path, name: name, inspector: false);
      try {
        out.add(await _readSummary(isar, n));
      } finally {
        if (already == null) await isar.close();
      }
    }
    return out;
  }

  static Future<SlotSummary> _readSummary(Isar isar, int n) async {
    final save = await isar.saveDatas.get(0);
    final founderId = save?.founderCharacterId;
    final founder =
        founderId == null ? null : await isar.characters.get(founderId);
    if (founder == null) return SlotSummary.empty(n);
    final mp = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(n)
        .findFirst();
    return SlotSummary(
      slotId: n,
      isEmpty: false,
      founderName: founder.name,
      realmDisplay: EnumL10n.realm(founder.realmTier, founder.realmLayer),
      chapterIndex: mp?.currentChapterIndex ?? 1,
      clearedStageCount: mp?.clearedStageIds.length ?? 0,
      lastPlayed: save?.lastOnlineAt,
    );
  }

  /// 删除指定槽 db(若为当前槽先 close → 实例置空)+ 删 .isar/.isar.lock 文件。
  static Future<void> deleteSlot(int n, {Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final name = 'wuxia_save_slot$n';
    if (currentSlotId == n && _instance != null) {
      await close();
    } else {
      final open = Isar.getInstance(name);
      if (open != null) await open.close();
    }
    for (final ext in ['.isar', '.isar.lock']) {
      final f = File('${dir.path}/$name$ext');
      if (await f.exists()) await f.delete();
    }
  }

  /// 测试复位:清实例 + 目录记忆 + currentSlotId(各测 setUp 用纯净起点)。
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _directory = null;
    currentSlotId = 1;
  }
```
5. 顶部 import 加 `import '../features/battle/domain/enum_localizations.dart';`（EnumL10n.realm）。
6. 改类头注释：删「Phase 1 简化只支持单槽」「推迟到 Phase 5」，改「多槽切换/列表/删除 1.0 已实装」。

- [ ] **Step 5: 运行测试到绿**

Run: `flutter test test/data/isar_setup_slots_test.dart`
Expected: All tests passed!（4 个用例全绿）

- [ ] **Step 6: Commit**

```bash
git add lib/data/slot_summary.dart lib/data/isar_setup.dart test/data/isar_setup_slots_test.dart
git commit -m "多存档槽:IsarSetup switchSlot/listSlots/deleteSlot+SlotSummary"
```

---

## Task 2: SaveSelectScreen + provider + 启动分流

**Files:**
- Create: `lib/features/save_slot/application/slot_list_provider.dart`（listSlots future provider）
- Create: `lib/features/save_slot/presentation/save_select_screen.dart`
- Modify: `lib/features/splash/presentation/splash_screen.dart`（不再 auto-init→push SaveSelectScreen）
- Modify: `lib/shared/strings.dart`（新增槽位文案）
- Test: `test/features/save_slot/save_select_screen_test.dart`

- [ ] **Step 1: UiStrings 新增文案**

`lib/shared/strings.dart` 存档管理段附近加：
```dart
  static const String slotSelectTitle = '选择江湖';
  static const String slotEmpty = '空 · 新开江湖';
  static const String slotNewGameConfirm = '在此开启新的江湖路？';
  static const String slotDelete = '删除存档';
  static const String slotDeleteConfirm = '删除此存档？此举不可挽回。';
  static const String slotSwitch = '切换存档';
  static String slotChapterProgress(int chapter, int cleared) =>
      '第 $chapter 章 · 已通关 $cleared 关';
  static String slotCardTitle(int n) => '第 $n 卷';
```

- [ ] **Step 2: slotListProvider（FutureProvider 读 listSlots）**

`lib/features/save_slot/application/slot_list_provider.dart`：
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/isar_setup.dart';
import '../../../data/slot_summary.dart';

part 'slot_list_provider.g.dart';

/// 存档槽摘要列表(选择屏用)。invalidate 触发重读 1..3 槽。
@riverpod
Future<List<SlotSummary>> slotList(Ref ref) => IsarSetup.listSlots();
```

- [ ] **Step 3: SaveSelectScreen widget**

`lib/features/save_slot/presentation/save_select_screen.dart`：3 槽卡片列；有档显摘要 + 删除按钮（确认弹窗），空槽显「空 · 新开江湖」。点有档→switchSlot+ensureFoundingMasters+invalidate(isarProvider)→pushReplacement MainMenu；点空槽→确认「新开江湖」→同流程。删除→确认→deleteSlot+invalidate(slotListProvider)。用 WuxiaPaperPanel/纸调主题（参考现有 settings_panel 体例）。
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/isar_provider.dart';
import '../../../data/isar_setup.dart';
import '../../../data/slot_summary.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../application/slot_list_provider.dart';

class SaveSelectScreen extends ConsumerWidget {
  const SaveSelectScreen({super.key});

  Future<void> _enterSlot(BuildContext context, WidgetRef ref, int n) async {
    await IsarSetup.switchSlot(n);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    ref.invalidate(isarProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenu()),
    );
  }

  Future<void> _deleteSlot(BuildContext context, WidgetRef ref, int n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WuxiaColors.background,
        content: const Text(UiStrings.slotDeleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text(UiStrings.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text(UiStrings.slotDelete)),
        ],
      ),
    );
    if (ok != true) return;
    await IsarSetup.deleteSlot(n);
    ref.invalidate(slotListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotListProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        child: Center(
          child: slotsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (slots) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(UiStrings.slotSelectTitle,
                      style: TextStyle(
                          fontSize: 28,
                          color: WuxiaColors.resultHighlight,
                          letterSpacing: 6)),
                ),
                for (final s in slots)
                  _SlotCard(
                    summary: s,
                    onEnter: () => _enterSlot(context, ref, s.slotId),
                    onDelete:
                        s.isEmpty ? null : () => _deleteSlot(context, ref, s.slotId),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard(
      {required this.summary, required this.onEnter, this.onDelete});
  final SlotSummary summary;
  final VoidCallback onEnter;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: WuxiaColors.inkBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        title: Text(UiStrings.slotCardTitle(summary.slotId),
            style: const TextStyle(color: WuxiaColors.resultHighlight)),
        subtitle: Text(
          summary.isEmpty
              ? UiStrings.slotEmpty
              : '${summary.founderName} · ${summary.realmDisplay}\n'
                  '${UiStrings.slotChapterProgress(summary.chapterIndex, summary.clearedStageCount)}',
          style: const TextStyle(color: WuxiaColors.textSecondary),
        ),
        isThreeLine: !summary.isEmpty,
        onTap: onEnter,
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: WuxiaColors.textSecondary),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
```
（注：`WuxiaColors.inkBorder`/`commonCancel` 等若不存在,Step 实装时 grep 替换为真实 token；不硬编码颜色/中文。）

- [ ] **Step 4: splash 改分流**

`splash_screen.dart` `_bootstrap`：删 `IsarSetup.init()` + `ensureFoundingMasters()`（移到选择屏）；`_go()` 的 `MainMenu()` 改 `SaveSelectScreen()`。保留 GameRepository.loadAllDefs。

- [ ] **Step 5: widget 测试**

`test/features/save_slot/save_select_screen_test.dart`：pump SaveSelectScreen（override slotListProvider 返回 mixed fixtures），断言：3 槽渲染、有档显祖师名/进度、空槽显「空·新开江湖」、删除按钮仅有档槽出现、点删除弹确认。用 ProviderScope overrides 注入假 slotList 避免真 Isar。

- [ ] **Step 6: 运行 + Commit**

Run: `flutter test test/features/save_slot/` → 绿
```bash
git add lib/features/save_slot/ lib/features/splash/ lib/shared/strings.dart test/features/save_slot/
git commit -m "多存档槽:SaveSelectScreen+slotList provider+启动分流"
```

---

## Task 3: 设置面板「切换存档」入口

**Files:**
- Modify: `lib/features/settings/presentation/settings_panel.dart`（加 _SaveSlotSwitchTile）

- [ ] **Step 1:** 设置面板存档管理段后加「切换存档」tile：点击确认后 popback 到 SaveSelectScreen（经 switchSlot 流程——实际只需 pushAndRemoveUntil 到 SaveSelectScreen，让用户重选；切档前 touchOnlineNow flush）。文案 `UiStrings.slotSwitch`。
- [ ] **Step 2:** widget test 或手动验证入口渲染（settings_panel 既有测若有则补一条入口存在断言）。
- [ ] **Step 3: Commit** `多存档槽:设置面板加切换存档入口`

---

## Task 4: 全量验收

- [ ] **Step 1:** `flutter analyze` → No issues found!
- [ ] **Step 2:** `flutter test` 全量 → All tests passed!（重点 slot 族 + splash 不再直达 MainMenu 不破其他测）
- [ ] **Step 3:** PROGRESS.md 记一行（净增长 ≤0）+ commit

---

## Self-Review（写完后核对 spec B）

- §3.1 IsarSetup 三 TODO + SlotSummary → Task 1 ✓
- §3.2 启动流程（splash→选择屏，有档/空槽/删档分支）→ Task 2 ✓
- §3.3 切档 invalidate isarProvider + GameRepository 不重载 + 切档前 flush → Task 1(flush in switchSlot) + Task 2(invalidate) ✓
- §3.4 摘要卡内容（不新增 schema 字段）→ SlotSummary 全用现成字段 ✓
- §3.5 旧档兼容（slot1 不迁移，currentSlotId 运行时可变）→ Task 1 ✓
- §3.6 游戏内返回选择屏 → Task 3 ✓
- §4 风险（多实例 close / 原子性 / 挂机结算 / 删当前回选择屏）→ Task 1 设计已覆盖 ✓
- §5 测试全覆盖 → Task 1+2 测试 ✓

**YAGNI（§6）**：不做云存档/重命名/复制/导入导出/手动存档点/无限槽/清理冗余 saveDataId 字段。
