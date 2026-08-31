/// 奖励的三个语义层。数值与掉落规则仍由各内容现有配置和结算器拥有；
/// 本合同只描述领取身份与防重边界。
enum RewardLayer { firstClear, repeat, personalGrowth }

/// 奖励领取作用域。
///
/// [personal] 归实际参战角色；[sectShared] 归当前存档/宗门，换角色不可重领。
enum RewardScope { personal, sectShared }
