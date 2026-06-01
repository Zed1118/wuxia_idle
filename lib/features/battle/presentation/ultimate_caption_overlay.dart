import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/theme/colors.dart';

/// 出版美术 B2:出招是否该弹大招题字(ultimate 或人剑合一)。纯函数便于单测。
bool isUltimateCaptionSkill(SkillDef? skill) =>
    skill != null &&
    (skill.type == SkillType.ultimate || skill.type == SkillType.jointSkill);
