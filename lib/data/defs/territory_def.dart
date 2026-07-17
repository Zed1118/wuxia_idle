/// 山头领地静态定义(P4.1 §12.2 Q4=A · `data/territories.yaml` 解析)。
///
/// 动态 ownership 由 `Sect.territoryIds` 持有(B2 `TerritoryService.claim/release`
/// writeTxn 维护),本 def 仅承载静态字段:[id] / [name] / [description] /
/// [baseDefenseLevel](沿 §5.3 七阶映射)/ [initialOwnerSectId](null = 中立)。
class TerritoryDef {
  final String id;
  final String name;
  final String description;

  /// 防御阶位 · 沿 §5.3 七阶(1 学徒 / 2 三流 / 3 二流 / 4 一流 / 5 绝顶 /
  /// 6 宗师 / 7 武圣)。占领阻力锚点 · 1.1 真 stage_boss 占领 trigger 时
  /// 驱动战斗难度(spec p4_1_sect_management_spec §9 R3)。
  final int baseDefenseLevel;

  /// 初始 owner sectId · null = 中立无主 / int = 写死初始 owner(Demo 测试 / 1.1 用)。
  final int? initialOwnerSectId;

  const TerritoryDef({
    required this.id,
    required this.name,
    required this.description,
    required this.baseDefenseLevel,
    required this.initialOwnerSectId,
  });

  factory TerritoryDef.fromYaml(Map<String, dynamic> y) {
    return TerritoryDef(
      id: y['id'] as String,
      name: y['name'] as String,
      description: y['description'] as String,
      baseDefenseLevel: (y['baseDefenseLevel'] as num).toInt(),
      initialOwnerSectId: (y['initialOwnerSectId'] as num?)?.toInt(),
    );
  }
}
