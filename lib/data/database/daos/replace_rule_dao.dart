import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/replace_rules_table.dart';

part 'replace_rule_dao.g.dart';

@DriftAccessor(tables: [ReplaceRules])
class ReplaceRuleDao extends DatabaseAccessor<AppDatabase>
    with _$ReplaceRuleDaoMixin {
  ReplaceRuleDao(super.db);

  Future<List<ReplaceRule>> getAllRules() {
    return (select(replaceRules)..orderBy([(r) => OrderingTerm.asc(r.order)])).get();
  }

  Future<List<ReplaceRule>> getEnabledRules() {
    return (select(replaceRules)
          ..where((r) => r.isEnabled.equals(true))
          ..orderBy([(r) => OrderingTerm.asc(r.order)]))
        .get();
  }

  Future<void> insertOrUpdateRule(ReplaceRulesCompanion rule) =>
      into(replaceRules).insertOnConflictUpdate(rule);

  Future<void> insertOrUpdateRules(List<ReplaceRulesCompanion> rules) =>
      batch((b) => b.insertAllOnConflictUpdate(replaceRules, rules));

  Future<int> deleteRule(int id) {
    return (delete(replaceRules)..where((r) => r.id.equals(id))).go();
  }

  Future<void> toggleEnabled(int id, bool enabled) {
    return (update(replaceRules)..where((r) => r.id.equals(id)))
        .write(ReplaceRulesCompanion(isEnabled: Value(enabled)));
  }
}
