/// نماذج أدوات التشخيص: نتائج فحص Ping وتتبع المسار Traceroute

/// نتيجة فحص الـ Ping
class PingResult {
  final String address;
  final int sent;
  final int received;
  final int timeouts;
  final double avgMs;
  final double minMs;
  final double maxMs;
  final List<String> replies; // نص كل رد (للعرض)

  PingResult({
    required this.address,
    required this.sent,
    required this.received,
    required this.timeouts,
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.replies,
  });

  int get lossPercent => sent > 0 ? ((timeouts * 100) / sent).round() : 100;

  bool get isHealthy => received > 0 && timeouts < sent;

  factory PingResult.fromRows(String address, List rows, int requested) {
    final List<double> times = [];
    int timeouts = 0;
    final List<String> replies = [];

    for (final r in rows) {
      if (r is! Map) continue;
      final time = (r['time'] ?? '').toString();
      if (time.isNotEmpty) {
        final v = double.tryParse(time.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (v != null) {
          times.add(v);
          replies.add(time);
        }
      } else {
        final status = (r['status'] ?? '').toString().toLowerCase();
        if (status.contains('timeout')) {
          timeouts++;
          replies.add('انتهت المهلة');
        }
      }
    }

    final int sentCount = (times.length + timeouts) > 0
        ? (times.length + timeouts)
        : requested;

    double avg = 0, min = 0, max = 0;
    if (times.isNotEmpty) {
      min = times.reduce((a, b) => a < b ? a : b);
      max = times.reduce((a, b) => a > b ? a : b);
      avg = times.reduce((a, b) => a + b) / times.length;
    }

    return PingResult(
      address: address,
      sent: sentCount,
      received: times.length,
      timeouts: timeouts,
      avgMs: avg,
      minMs: min,
      maxMs: max,
      replies: replies,
    );
  }
}

/// قفزة واحدة في تتبع المسار
class TraceHop {
  final int hop;
  final String host;
  final String time;
  final bool resolved;

  TraceHop({
    required this.hop,
    required this.host,
    required this.time,
    required this.resolved,
  });

  static List<TraceHop> fromRows(List rows) {
    final Map<int, TraceHop> hops = {};
    for (final r in rows) {
      if (r is! Map) continue;
      final hop = int.tryParse((r['hop'] ?? '').toString());
      if (hop == null) continue;
      final host = (r['host'] ?? r['address'] ?? '').toString();
      final time = (r['time'] ?? '').toString();
      final status = (r['status'] ?? '').toString();
      final resolved = host.isNotEmpty;
      final existing = hops[hop];
      if (existing == null || (!existing.resolved && resolved)) {
        hops[hop] = TraceHop(
          hop: hop,
          host: host,
          time: time.isNotEmpty
              ? time
              : (status.isNotEmpty ? status : 'انتهت المهلة'),
          resolved: resolved,
        );
      }
    }
    final list = hops.values.toList()
      ..sort((a, b) => a.hop.compareTo(b.hop));
    return list;
  }
}
