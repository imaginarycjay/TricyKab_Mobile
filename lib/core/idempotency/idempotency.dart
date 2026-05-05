import 'dart:math' as math;

/// Generates a web-safe, unique-per-request idempotency key.
///
/// PRD §5 / §22 require an `Idempotency-Key` header on every mutating
/// driver request (accept, decline, cancel, arrive, start, end, payment,
/// add-passengers).  We keep the integer bound at `1 << 30` so JS bitops
/// on Flutter Web never collapse the upper bits.
String newIdempotencyKey([String? prefix]) {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = math.Random().nextInt(1 << 30);
  final base = '$ts-$rand';
  return prefix == null || prefix.isEmpty ? base : '$prefix-$base';
}
