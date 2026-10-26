// Tiny in-memory cache with a time-to-live. Used to avoid re-hitting the
// catalog for the same home-feed query while the user keeps the app open
// (PRD 9.10: minimise network usage). Entries expire lazily on read.

/// Generic TTL cache.
final class TtlCache<K, V> {
  /// Creates a cache whose entries live for [ttl]. [clock] is injectable for
  /// tests.
  TtlCache({required this.ttl, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Entry lifetime.
  final Duration ttl;

  final DateTime Function() _clock;
  final Map<K, _Entry<V>> _entries = {};

  /// Returns the cached value for [key], or null when missing / expired.
  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (_clock().difference(entry.storedAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Stores [value] under [key].
  void set(K key, V value) => _entries[key] = _Entry(value, _clock());

  /// Drops every entry.
  void clear() => _entries.clear();

  /// Number of live entries (expired ones are not counted).
  int get length {
    final now = _clock();
    _entries.removeWhere((_, entry) => now.difference(entry.storedAt) > ttl);
    return _entries.length;
  }
}

final class _Entry<V> {
  const _Entry(this.value, this.storedAt);

  final V value;
  final DateTime storedAt;
}
