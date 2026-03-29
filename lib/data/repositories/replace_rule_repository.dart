import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/replace_rules_table.dart';

final replaceRuleRepositoryProvider = Provider<ReplaceRuleRepository>((ref) {
  return ReplaceRuleRepository(ref.watch(appDatabaseProvider));
});

class ReplaceRuleRepository {
  final AppDatabase _db;
  ReplaceRuleRepository(this._db);

  Future<List<ReplaceRule>> getAllRules() => _db.replaceRuleDao.getAllRules();
  Future<List<ReplaceRule>> getEnabledRules() => _db.replaceRuleDao.getEnabledRules();

  Future<void> saveRule(ReplaceRule rule) =>
      _db.replaceRuleDao.insertOrUpdateRule(
        ReplaceRulesCompanion(
          id: Value(rule.id),
          name: Value(rule.name),
          pattern: Value(rule.pattern),
          replacement: Value(rule.replacement),
          isRegex: Value(rule.isRegex),
          scope: Value(rule.scope),
          isEnabled: Value(rule.isEnabled),
          order: Value(rule.order),
          group: Value(rule.group),
        ),
      );

  Future<int> importFromJson(String jsonStr) async {
    final List<dynamic> list = jsonDecode(jsonStr) as List;
    final companions = list.map((e) {
      final m = e as Map<String, dynamic>;
      return ReplaceRulesCompanion(
        name: Value(m['name'] as String? ?? ''),
        pattern: Value(m['pattern'] as String? ?? ''),
        replacement: Value(m['replacement'] as String? ?? ''),
        isRegex: Value(m['isRegex'] as bool? ?? false),
        scope: Value(m['scope'] as String?),
        isEnabled: Value(m['isEnabled'] as bool? ?? true),
        order: Value(m['order'] as int? ?? 0),
        group: Value(m['group'] as String?),
      );
    }).toList();
    await _db.replaceRuleDao.insertOrUpdateRules(companions);
    return companions.length;
  }

  Future<void> deleteRule(int id) => _db.replaceRuleDao.deleteRule(id);
  Future<void> toggleEnabled(int id, bool enabled) =>
      _db.replaceRuleDao.toggleEnabled(id, enabled);
}
