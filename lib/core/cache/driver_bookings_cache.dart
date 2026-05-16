import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/driver_flow/domain/driver_flow_models.dart';

/// Persisted display cache for driver booking lists and details.
class CachedBookingsList {
  const CachedBookingsList({required this.rows, required this.fetchedAt});

  final List<DriverHistoryBooking> rows;
  final DateTime fetchedAt;
}

class DriverBookingsCache {
  DriverBookingsCache({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsFuture async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Scope cache per driver account (e.g. `driver_42`).
  String scopeKey = 'default';

  String get _listKey => 'driver_bookings_v1_$scopeKey';
  String get _fetchedAtKey => 'driver_bookings_fetched_at_v1_$scopeKey';
  String _detailKey(int id) => 'driver_booking_detail_${id}_v1_$scopeKey';

  Future<CachedBookingsList?> readList() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_listKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final rows = decoded
          .whereType<Map>()
          .map((e) => DriverHistoryBooking.fromJson(e.cast<String, dynamic>()))
          .toList();
      final fetchedRaw = prefs.getString(_fetchedAtKey);
      final fetchedAt = fetchedRaw != null ? DateTime.tryParse(fetchedRaw) : null;
      return CachedBookingsList(
        rows: rows,
        fetchedAt: fetchedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeList(List<DriverHistoryBooking> rows) async {
    final prefs = await _prefsFuture;
    final encoded = jsonEncode(rows.map((r) => r.toJson()).toList());
    await prefs.setString(_listKey, encoded);
    await prefs.setString(_fetchedAtKey, DateTime.now().toIso8601String());
  }

  Future<DriverHistoryBooking?> readDetail(int bookingId) async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_detailKey(bookingId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DriverHistoryBooking.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeDetail(DriverHistoryBooking booking) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_detailKey(booking.id), jsonEncode(booking.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _prefsFuture;
    final keys = prefs.getKeys().where(
      (k) =>
          k == _listKey ||
          k == _fetchedAtKey ||
          k.startsWith('driver_booking_detail_') && k.endsWith('_v1_$scopeKey'),
    );
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
