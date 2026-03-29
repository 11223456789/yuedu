/// 简单的内存缓存实现（替代 Drift 缓存）
class CacheDao {
  final Map<String, _CacheEntry> _cache = {};

  Future<String?> get(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // 检查是否过期
    if (entry.deadline > 0 && DateTime.now().millisecondsSinceEpoch > entry.deadline) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }

  Future<void> put(String key, String value, {Duration? ttl}) async {
    final deadline = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : 0;
    _cache[key] = _CacheEntry(value, deadline);
  }

  Future<int> deleteByKey(String key) async {
    final existed = _cache.containsKey(key);
    _cache.remove(key);
    return existed ? 1 : 0;
  }

  /// 清理过期缓存
  Future<int> clearExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _cache.entries
        .where((e) => e.value.deadline > 0 && e.value.deadline < now)
        .map((e) => e.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    return expiredKeys.length;
  }

  /// 清理所有缓存
  Future<void> clear() async {
    _cache.clear();
  }
}

class _CacheEntry {
  final String value;
  final int deadline;

  _CacheEntry(this.value, this.deadline);
}
