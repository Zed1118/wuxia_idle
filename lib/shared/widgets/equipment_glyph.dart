import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../features/battle/domain/enum_localizations.dart';

/// 装备缺图占位:tier 色描边内显部位首字(兵/护/饰…)。
///
/// P0-3 角色面板装备槽 + P0-4b 仓库格子化共用(从 character_panel 私有
/// `_EquipGlyph` 抽出,2026-06-04)。`Image.asset` errorBuilder 触发或
/// `iconPath` 缺失时降级到此,守 asset_audit + widget test 不破布局。
class EquipGlyph extends StatelessWidget {
  const EquipGlyph({super.key, required this.tierColor, required this.slot});

  final Color tierColor;
  final EquipmentSlot slot;

  @override
  Widget build(BuildContext context) {
    final label = EnumL10n.equipmentSlot(slot);
    final glyph = label.characters.isEmpty ? '器' : label.characters.first;
    return Center(
      child: Text(
        glyph,
        style: TextStyle(
          color: tierColor,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
