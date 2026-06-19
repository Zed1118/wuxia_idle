import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/defs/master_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng.dart';
import 'master_builder.dart';

/// 首次启动 production seed 路径(2026-05-25 P0-1 release 阻塞修复)。
///
/// audit `1_0_release_audit_2026-05-25.md` 揭示:`StageBattleSetup._buildPlayerTeam`
/// 在 Isar 无 Character 时抛 `StateError('先跑 P1 种子')`,玩家全新启动游戏 →
/// splash → home_feed → main_menu → 任何战斗 → crash。production 路径缺失 seed。
///
/// 本服务在 [SplashScreen._bootstrap] IsarSetup.init 之后调用,**幂等**:
/// 已有 founder(isFounder=true)→ short-circuit 返回 false 不动数据
/// (信源是 Character,与 SaveData.activeCharacterIds 解耦,异常态可重 seed)。
///
/// 沿 [Phase2SeedService.seedMasterDisciple] 主流(soloStart=false 满队语义):
/// - Character × 3:祖师 id=1(LineageRole.founder)+ 大弟子 + 二弟子(autoIncrement)
/// - Equipment × 9(3 角色 × startingEquipmentIds 各 ~3 槽 by masters.yaml)
/// - Technique × 4(founder 2 + 大弟子 1 + 二弟子 1 by masters.yaml)
/// - SaveData.activeCharacterIds = [1,2,3] / founderCharacterId = 1 / sectName='我的门派'
///
/// **生产新游戏路径默认 soloStart=true 单人开局**:只种祖师 id=1,
/// activeCharacterIds=[1],徒弟由后续剧情节点加入;debug/视觉路由传 soloStart=false 保满队。
/// - 基础物料:磨剑石 50 / 心血结晶 0(新玩家试强化锚点,§5.1 反留存不给爆量)
///
/// 不动:GDD / numbers.yaml / masters.yaml / Isar schema 版本 / §5.4 红线 / §6 公式。
class OnboardingService {
  const OnboardingService({required this.isar});

  final Isar isar;

  /// 基础物料:新玩家锚点 — 磨剑石 50(够试 +0→+5)/ 心血结晶 0。
  /// 沿 §5.1 反留存:不给爆量,鼓励玩家通过挂机/掉落获取。
  static const int _starterMojianshi = 50;
  static const int _starterJieJing = 0;

  /// 幂等 production seed:全新 db 写师徒 + 物料 + SaveData wire,
  /// 已有 founder 则跳过。
  ///
  /// [soloStart] 控制开局阵容:
  /// - `true`(默认,**生产新游戏路径**):只种祖师单人,徒弟后续由剧情节点加入。
  ///   `activeCharacterIds=[1]` / `founder.discipleIds=[]`。
  /// - `false`(**debug / 视觉路由**):回归满队 3 师徒(祖师 + 大弟子 + 二弟子),
  ///   `activeCharacterIds=[1,2,3]`。
  ///
  /// 返回 `true` 表示 seed 已执行 / `false` 表示已存在 founder 跳过。
  ///
  /// 调用方:[SplashScreen._bootstrap] IsarSetup.init 之后(splash loading 期间).
  Future<bool> ensureFoundingMasters({bool soloStart = true}) async {
    final existing =
        await isar.characters.filter().isFounderEqualTo(true).count();
    if (existing > 0) return false;

    final repo = GameRepository.instance;
    final masters = repo.masters;
    final rng = DefaultRng();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      // 1. 祖师固定 id=1(与既有 main_menu / character_panel 对齐)。
      final founder = buildMasterCharacter(masters[0], now: now)..id = 1;
      await isar.characters.put(founder);

      // 2. 阵容:soloStart 仅祖师;否则满队(大弟子 / 二弟子 autoIncrement id=2/3)。
      final List<Character> seeded;
      final List<MasterDef> defs;
      if (soloStart) {
        founder.discipleIds = [];
        seeded = [founder];
        defs = [masters[0]];
      } else {
        final firstDisciple = buildMasterCharacter(masters[1], now: now);
        await isar.characters.put(firstDisciple);
        final secondDisciple = buildMasterCharacter(masters[2], now: now);
        await isar.characters.put(secondDisciple);
        // 师徒关系(双向)。
        founder.discipleIds = [firstDisciple.id, secondDisciple.id];
        firstDisciple.masterId = founder.id;
        secondDisciple.masterId = founder.id;
        seeded = [founder, firstDisciple, secondDisciple];
        defs = [masters[0], masters[1], masters[2]];
      }

      // 3. 按 slot 顺序装备 + 学心法(helpers 在 master_builder.dart top-level)。
      for (var i = 0; i < seeded.length; i++) {
        await equipMasterStarting(
          isar,
          character: seeded[i],
          defIds: defs[i].startingEquipmentIds,
          rng: rng,
          now: now,
        );
        await learnMasterStarting(
          isar,
          character: seeded[i],
          techDefIds: defs[i].startingTechniqueIds,
          now: now,
        );
      }
      await isar.characters.putAll(seeded);

      // 4. SaveData.activeCharacterIds 入阵当前阵容。
      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.activeCharacterIds = seeded.map((c) => c.id).toList();
        save.founderCharacterId = founder.id;
        save.sectName ??= UiStrings.defaultSectName;
        await isar.saveDatas.put(save);
      }

      // 5. 基础物料(磨剑石 50 / 心血结晶 0)。
      await seedBasicMaterials(
        isar,
        mojianshi: _starterMojianshi,
        jieJing: _starterJieJing,
        at: now,
      );
    });
    return true;
  }
}
