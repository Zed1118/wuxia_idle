/// 祖师/门派随机取名素材（组件式）。data/founder_names.yaml 加载。
class FounderNamesConfig {
  final List<String> founderSurnames;
  final List<String> founderGiven;
  final List<String> sectPrefixes;
  final List<String> sectSuffixes;

  const FounderNamesConfig({
    required this.founderSurnames,
    required this.founderGiven,
    required this.sectPrefixes,
    required this.sectSuffixes,
  });

  factory FounderNamesConfig.fromYaml(Map<String, dynamic> y) {
    List<String> pool(String key) => List<String>.from(
      (y[key] as List? ?? const []).map((e) => e as String),
    );
    return FounderNamesConfig(
      founderSurnames: pool('founder_surnames'),
      founderGiven: pool('founder_given'),
      sectPrefixes: pool('sect_prefixes'),
      sectSuffixes: pool('sect_suffixes'),
    );
  }

  static const empty = FounderNamesConfig(
    founderSurnames: [],
    founderGiven: [],
    sectPrefixes: [],
    sectSuffixes: [],
  );
}
