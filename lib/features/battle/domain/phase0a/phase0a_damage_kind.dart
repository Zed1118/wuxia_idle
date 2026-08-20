/// 伤害结算种类(reducer → resolver 的语义入参)。
enum Phase0aDamageKind {
  basic,
  gather,
  clear,
  skill1,
  skill2,
  skill3,
  skill4,
  skill5,
  skill6,
}

int? phase0aSkillHotkeyOf(Phase0aDamageKind kind) => switch (kind) {
  Phase0aDamageKind.skill1 => 1,
  Phase0aDamageKind.skill2 => 2,
  Phase0aDamageKind.skill3 => 3,
  Phase0aDamageKind.skill4 => 4,
  Phase0aDamageKind.skill5 => 5,
  Phase0aDamageKind.skill6 => 6,
  Phase0aDamageKind.basic ||
  Phase0aDamageKind.gather ||
  Phase0aDamageKind.clear => null,
};

Phase0aDamageKind phase0aDamageKindForSkillHotkey(int hotkey) =>
    switch (hotkey) {
      1 => Phase0aDamageKind.skill1,
      2 => Phase0aDamageKind.skill2,
      3 => Phase0aDamageKind.skill3,
      4 => Phase0aDamageKind.skill4,
      5 => Phase0aDamageKind.skill5,
      6 => Phase0aDamageKind.skill6,
      _ => throw RangeError.range(hotkey, 1, 6, 'hotkey'),
    };
