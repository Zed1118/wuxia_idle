/// 稳定随机 seed 派生（§4.3/§4.7）。**显式整数混合**，跨重启/跨平台稳定；
/// 不使用可能受运行时影响的 `Object.hashCode` 作为跨重启协议。
class ExpeditionSeed {
  const ExpeditionSeed._();

  static const int _prime1 = 0x9E3779B1; // 黄金比例散列常数
  static const int _prime2 = 0x85EBCA77;
  static const int _prime3 = 0xC2B2AE3D;
  static const int _mask32 = 0xFFFFFFFF;

  /// 节点级稳定 seed = mix(存档标识, 远征序号, 节点编号)。
  static int forNode({
    required int saveId,
    required int runSerial,
    required int node,
  }) {
    var h = 0x811C9DC5; // FNV offset basis
    h = ((h ^ (saveId & _mask32)) * _prime1) & _mask32;
    h = ((h ^ (runSerial & _mask32)) * _prime2) & _mask32;
    h = ((h ^ (node & _mask32)) * _prime3) & _mask32;
    // 末尾雪崩混合
    h ^= h >> 15;
    h = (h * _prime2) & _mask32;
    h ^= h >> 13;
    return h & _mask32;
  }
}
