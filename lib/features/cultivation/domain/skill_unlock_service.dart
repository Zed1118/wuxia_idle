import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';

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

  Future<void> grantManual(String skillId) async {
    await _isar.writeTxn(() async {
      final s = await _save();
      // Isar @embedded list 取出为 fixed-length,转 growable 再 mutate(防 add 抛)。
      s.skillUnlockProgress = List.of(s.skillUnlockProgress);
      s.skillUnlockProgress.markUnlocked(skillId);
      await _isar.saveDatas.put(s);
    });
  }

  Future<void> addFragment(String skillId, [int n = 1]) async {
    await _isar.writeTxn(() async {
      final s = await _save();
      s.skillUnlockProgress = List.of(s.skillUnlockProgress);
      if (!s.skillUnlockProgress.isUnlocked(skillId)) {
        s.skillUnlockProgress.addFragment(skillId, n);
        if (s.skillUnlockProgress.fragmentCountOf(skillId) >= fragmentThreshold) {
          s.skillUnlockProgress.markUnlocked(skillId);
        }
      }
      await _isar.saveDatas.put(s);
    });
  }

  Future<bool> isUnlocked(String skillId) async =>
      (await _save()).skillUnlockProgress.isUnlocked(skillId);

  /// 返回 (当前残页数, 阈值)。已解锁的招残页可能为 0(真解未走残页路径)。
  Future<(int, int)> fragmentProgress(String skillId) async {
    final s = await _save();
    return (s.skillUnlockProgress.fragmentCountOf(skillId), fragmentThreshold);
  }
}
