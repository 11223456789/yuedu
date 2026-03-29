/// 替换规则 DAO（内存实现）
class ReplaceRuleDao {
  final List<dynamic> _rules = [];
  
  Future<List<dynamic>> getAllRules() async => List.from(_rules);
  Future<void> insertOrUpdateRule(dynamic rule) async {
    _rules.removeWhere((r) => r.id == rule.id);
    _rules.add(rule);
  }
  Future<void> deleteRule(dynamic rule) async {
    _rules.removeWhere((r) => r.id == rule.id);
  }
}
