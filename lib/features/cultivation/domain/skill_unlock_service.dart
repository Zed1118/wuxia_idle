import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_drop_result.dart';

/// 技能解锁进度服务(可玩性 P1a · spec §一)。账号级,操作
/// `SaveData.skillUnlockProgress`(单例 id=0,由 IsarSetup._ensureSaveData 保证存在)。
///
/// - 真解(主线 Boss 首通):`grantManual` 直接 markUnlocked,幂等。
/// - 残页(爬塔 Boss 概率掉):`addFragment` 累加,达 [fragmentThreshold] 自动解锁;
///   已解锁后短路不再累加。
class SkillUnlockService {
  final Isar _isar;
  final int fragmentThreshold;

  SkillUnlockService(this._isar, {this.fragmentThreshold = 5});

  /// 取单例 SaveData(id=0)。IsarSetup.init 必经 _ensureSaveData 建行,故恒非空;
  /// 若为空说明未初始化单例 → fail-fast(不在此半建 late 字段)。
  Future<SaveData> _save() async {
    final s = await _isar.saveDatas.get(0);
    if (s == null) {
      throw StateError(
        'SkillUnlockService: SaveData(id=0) 不存在,应先 IsarSetup.init 初始化单例',
      );
    }
    return s;
  }

  /// 真解首通授招。
  ///
  /// 返回 `true` 表示本次**新授**（之前未解锁）；`false` 表示已解锁，幂等不重复信号。
  /// 写库仍仅在首次执行；已解锁时写库也幂等（调用仍安全，只是不触发 markUnlocked）。
  Future<bool> grantManual(String skillId) async {
    bool newlyGranted = false;
    await _isar.writeTxn(() async {
      final s = await _save();
      // Isar @embedded list 取出为 fixed-length,转 growable 再 mutate(防 add 抛)。
      s.skillUnlockProgress = List.of(s.skillUnlockProgress);
      if (!s.skillUnlockProgress.isUnlocked(skillId)) {
        s.skillUnlockProgress.markUnlocked(skillId);
        newlyGranted = true;
      }
      await _isar.saveDatas.put(s);
    });
    return newlyGranted;
  }

  /// 累加残页。
  ///
  /// 返回本次掉落结果（[SkillDropResult]），含：
  /// - [SkillDropResult.fragmentSkillId]：本次掉的招 id。
  /// - [SkillDropResult.fragmentCount]：累计页数（本次加后）。
  /// - [SkillDropResult.fragmentThreshold]：集齐阈值。
  /// - [SkillDropResult.fragmentJustUnlocked]：`true` 当且仅当本次 add 导致集齐（调用前未解锁 + 加后 >= 阈值）。
  ///
  /// 若调用前已解锁（短路），返回 `fragmentJustUnlocked: false`，`fragmentCount` 为已有值（通常 0，若之前走残页路径则为当时累计）。
  Future<SkillDropResult> addFragment(String skillId, [int n = 1]) async {
    int countAfter = 0;
    bool justUnlocked = false;
    await _isar.writeTxn(() async {
      final s = await _save();
      s.skillUnlockProgress = List.of(s.skillUnlockProgress);
      if (!s.skillUnlockProgress.isUnlocked(skillId)) {
        s.skillUnlockProgress.addFragment(skillId, n);
        countAfter = s.skillUnlockProgress.fragmentCountOf(skillId);
        if (countAfter >= fragmentThreshold) {
          s.skillUnlockProgress.markUnlocked(skillId);
          justUnlocked = true;
        }
      } else {
        // 已解锁短路：保留已有累计数（真解路径通常为 0）。
        countAfter = s.skillUnlockProgress.fragmentCountOf(skillId);
      }
      await _isar.saveDatas.put(s);
    });
    return SkillDropResult(
      fragmentSkillId: skillId,
      fragmentCount: countAfter,
      fragmentThreshold: fragmentThreshold,
      fragmentJustUnlocked: justUnlocked,
    );
  }

  Future<bool> isUnlocked(String skillId) async =>
      (await _save()).skillUnlockProgress.isUnlocked(skillId);

  /// 返回 (当前残页数, 阈值)。已解锁的招残页可能为 0(真解未走残页路径)。
  Future<(int, int)> fragmentProgress(String skillId) async {
    final s = await _save();
    return (s.skillUnlockProgress.fragmentCountOf(skillId), fragmentThreshold);
  }
}
